import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../data/remote/waline_client.dart';
import '../../data/repositories/board_cache.dart';
import '../../providers/app_providers.dart';

/// Message board backed by the project's Waline deployment.
///
/// The list owns the full page; composing happens in a modal bottom sheet
/// opened from the FAB (or from a comment's reply action), so the form never
/// covers the content. Guests post with just a nickname, remembered between
/// posts. Reply threads are collapsed by default behind a compact toggle.
class CommunityPage extends ConsumerStatefulWidget {
  const CommunityPage({super.key});

  @override
  ConsumerState<CommunityPage> createState() => _CommunityPageState();
}

class _CommunityPageState extends ConsumerState<CommunityPage> {
  final _scrollController = ScrollController();
  final _contentController = TextEditingController();
  final _nickController = TextEditingController();

  List<WalineComment> _comments = [];
  int _page = 1;
  int _totalPages = 1;
  bool _loading = false;
  String? _error;

  /// Reply target while the composer sheet is open; null means a new
  /// top-level post.
  String? _replyTo;

  /// Guards the one-time bootstrap (seed nickname + cache load + silent
  /// refresh), which must run after the first frame — mutating controllers
  /// or calling setState during build trips framework assertions.
  bool _bootstrapped = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _contentController.dispose();
    _nickController.dispose();
    super.dispose();
  }

  /// Loads the cached list (instant, offline-friendly), then awaits the
  /// app-startup prefetch — the same shared future, so opening the board
  /// never issues a duplicate first-page request.
  Future<void> _bootstrap() async {
    final nick = await ref.read(boardNickProvider.future);
    if (!mounted) return;
    if (nick.isNotEmpty && _nickController.text.isEmpty) {
      _nickController.text = nick;
    }

    final db = ref.read(appDatabaseProvider);
    final cached = await readCachedComments(db);
    if (!mounted) return;
    if (cached.isNotEmpty) {
      setState(() => _comments = cached);
    } else {
      setState(() => _loading = true);
    }

    // If the startup prefetch already failed (e.g. offline at launch), drop
    // the cached error and retry now instead of showing a stale failure.
    if (ref.read(boardPrefetchProvider) is AsyncError) {
      ref.invalidate(boardPrefetchProvider);
    }

    // Reuse the startup prefetch (already running or completed). Silent
    // when the cache gave us something to show.
    await _applyPrefetch(silent: cached.isNotEmpty);
  }

  /// Awaits the shared first-page prefetch and applies its result.
  Future<void> _applyPrefetch({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final result = await ref.read(boardPrefetchProvider.future);
      if (!mounted) return;
      setState(() {
        _comments = result.comments;
        _page = result.page;
        _totalPages = result.totalPages;
        _loading = false;
        _error = null;
      });
    } on WalineException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        // Keep showing the cache; surface the failure quietly.
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  /// Manual refresh: drop the shared prefetch so a genuinely new request
  /// is made, then apply it.
  Future<void> _manualRefresh() async {
    ref.invalidate(boardPrefetchProvider);
    await _applyPrefetch();
  }

  Future<void> _loadMore() async {
    final client = ref.read(walineClientProvider);
    setState(() => _loading = true);
    try {
      final result = await client.fetchComments(page: _page + 1);
      if (!mounted) return;
      setState(() {
        _comments = [..._comments, ...result.comments];
        _page = result.page;
        _totalPages = result.totalPages;
        _loading = false;
        _error = null;
      });
    } on WalineException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  /// Posts the current composer content. Returns true on success so the
  /// sheet can close itself.
  Future<bool> _submit() async {
    final content = _contentController.text.trim();
    final nick = _nickController.text.trim();
    if (content.isEmpty || nick.isEmpty) return false;

    final client = ref.read(walineClientProvider);
    try {
      await client.postComment(content: content, nick: nick, rid: _replyTo);
      await ref.read(settingsRepositoryProvider).setBoardNick(nick);
      ref.invalidate(boardNickProvider);
      if (!mounted) return true;
      _contentController.clear();
      setState(() => _replyTo = null);
      // The new comment must appear: drop the shared prefetch and refetch.
      ref.invalidate(boardPrefetchProvider);
      await _applyPrefetch(silent: true);
      return true;
    } on WalineException catch (e) {
      if (mounted) setState(() => _error = e.message);
      return false;
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
      return false;
    }
  }

  Future<void> _openComposer({WalineComment? replyTo}) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _replyTo = replyTo?.objectId);
    // Seed the remembered nickname before the sheet opens.
    if (_nickController.text.isEmpty) {
      final nick = await ref.read(boardNickProvider.future);
      if (nick.isNotEmpty) _nickController.text = nick;
    }
    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => Padding(
        // Keep the fields above the soft keyboard on touch platforms.
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(sheetContext).bottom),
        child: _ComposerSheet(
          title: replyTo == null
              ? l10n.communitySheetTitle
              : l10n.communityReplyTo(replyTo.nick),
          nickController: _nickController,
          contentController: _contentController,
          nickHint: l10n.communityNickHint,
          contentHint: l10n.communityContentHint,
          submitLabel:
              replyTo == null ? l10n.communityPost : l10n.communityReply,
          onSubmit: _submit,
        ),
      ),
    );

    if (mounted) {
      setState(() => _replyTo = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_bootstrapped) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _bootstrap();
      });
    }

    final profile = context.platformProfile;

    return MediaryScaffold(
      title: l10n.community,
      subtitle: l10n.communitySubtitle,
      maxWidth: Breakpoints.contentForm,
      // Desktop has no comfortable pull gesture: refresh via a button.
      actions: profile.isDesktop
          ? [
              IconButton(
                onPressed: _loading ? null : _manualRefresh,
                // Desktop has no pull gesture; the button itself shows the
                // in-flight state.
                icon: _loading
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                tooltip: l10n.communityRefresh,
              ),
            ]
          : const [],
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openComposer,
        icon: const Icon(Icons.edit_rounded, size: 18),
        label: Text(l10n.communityPost),
      ),
      child: _buildBoard(l10n),
    );
  }

  Widget _buildBoard(AppLocalizations l10n) {
    final profile = context.platformProfile;
    return Column(
      children: [
        // Desktop has no pull-to-refresh indicator, and the small in-button
        // spinner is easy to miss — especially on a slow link where the
        // request takes seconds. Show a slim top progress bar while a manual
        // refresh / load-more is in flight so the action is visibly working.
        if (profile.isDesktop && _loading && _comments.isNotEmpty)
          const LinearProgressIndicator(minHeight: 2),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: Spacing.md),
            child: _ErrorRetry(
              message: _error!,
              onRetry: _manualRefresh,
            ),
          ),
        Expanded(
          child: _buildList(l10n, profile),
        ),
      ],
    );
  }

  Widget _buildList(AppLocalizations l10n, PlatformProfile profile) {
    final scheme = Theme.of(context).colorScheme;
    final list = ListView(
      controller: _scrollController,
      // Mobile: allow overscroll even when content is shorter than the
      // viewport, otherwise RefreshIndicator can never trigger.
      physics: profile.isDesktop
          ? null
          : const AlwaysScrollableScrollPhysics(),
      // Extra bottom room so the FAB never covers the last card.
      padding: const EdgeInsets.only(top: Spacing.lg, bottom: Spacing.xxl * 2.5),
      children: [
        const _BoardWarning(),
        const SizedBox(height: Spacing.md),
        if (_comments.isEmpty && _loading)
          const Padding(
            padding: EdgeInsets.only(top: Spacing.xxl),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_comments.isEmpty)
          EmptyState(
            icon: Icons.chat_bubble_outline_rounded,
            title: l10n.communityEmpty,
            message: l10n.communityEmptyHint,
            action: FilledButton.icon(
              onPressed: _openComposer,
              icon: const Icon(Icons.edit_rounded, size: 17),
              label: Text(l10n.communityPost),
            ),
          )
        else ...[
          for (final c in _topLevel)
            _CommentThread(
              comment: c,
              replies: _descendantsOf(c.objectId),
              nickOf: _nickOf,
              onReply: (parent) => _openComposer(replyTo: parent),
              replyLabel: l10n.communityReplyAction,
            ),
          if (_page < _totalPages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.lg),
              child: Column(
                children: [
                  Text(
                    l10n.communityPageInfo(_page, _totalPages),
                    style: Theme.of(context)
                        .textTheme
                        .labelSmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: Spacing.xs),
                  OutlinedButton.icon(
                    onPressed: _loading ? null : _loadMore,
                    // Feedback for appending a page lives in the button
                    // itself; no separate global spinner.
                    icon: _loading
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.expand_more_rounded, size: 16),
                    label: Text(l10n.communityLoadMore),
                  ),
                ],
              ),
            ),
        ],
      ],
    );

    // Pull-to-refresh is a touch-platform affordance; desktop refreshes via
    // the header button instead.
    return profile.isDesktop
        ? list
        : RefreshIndicator(onRefresh: _manualRefresh, child: list);
  }

  List<WalineComment> get _topLevel =>
      _comments.where((c) => !c.isReply).toList();

  /// All descendants of a top-level comment, depth-first. Replies-to-replies
  /// stay in the same thread and are flattened one indent level deep, with
  /// an @mention marking their direct parent (Valine convention).
  List<WalineComment> _descendantsOf(String objectId) {
    final result = <WalineComment>[];
    void walk(String id) {
      for (final c in _comments) {
        if (c.rid == id) {
          result.add(c);
          walk(c.objectId);
        }
      }
    }
    walk(objectId);
    return result;
  }

  /// Nickname of the comment a reply targets, for the @mention prefix.
  String? _nickOf(String? objectId) {
    if (objectId == null) return null;
    for (final c in _comments) {
      if (c.objectId == objectId) return c.nick;
    }
    return null;
  }
}

/// Modal compose form shown in a bottom sheet.
///
/// Lives in a sheet rather than pinned above the list so the board keeps the
/// full page height; the same sheet serves new posts and replies.
class _ComposerSheet extends StatefulWidget {
  const _ComposerSheet({
    required this.title,
    required this.nickController,
    required this.contentController,
    required this.nickHint,
    required this.contentHint,
    required this.submitLabel,
    required this.onSubmit,
  });

  final String title;
  final TextEditingController nickController;
  final TextEditingController contentController;
  final String nickHint;
  final String contentHint;
  final String submitLabel;

  /// Returns true when the post succeeded and the sheet should close.
  final Future<bool> Function() onSubmit;

  @override
  State<_ComposerSheet> createState() => _ComposerSheetState();
}

class _ComposerSheetState extends State<_ComposerSheet> {
  bool _posting = false;
  String? _error;

  Future<void> _submit() async {
    if (_posting) return;
    setState(() {
      _posting = true;
      _error = null;
    });
    final ok = await widget.onSubmit();
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context);
    } else {
      setState(() => _posting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          Spacing.xl, Spacing.md, Spacing.xl, Spacing.xl),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: text.titleMedium),
          const SizedBox(height: Spacing.md),
          TextField(
            controller: widget.nickController,
            maxLength: 24,
            decoration: InputDecoration(
              hintText: widget.nickHint,
              counterText: '',
              isDense: true,
              prefixIcon: const Icon(Icons.person_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: widget.contentController,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            autofocus: true,
            decoration: InputDecoration(
              hintText: widget.contentHint,
              alignLabelWithHint: true,
            ),
          ),
          if (_error != null)
            Padding(
              padding: const EdgeInsets.only(top: Spacing.xs),
              child: Text(
                _error!,
                style: text.bodySmall
                    ?.copyWith(color: context.mediaryColors.danger),
              ),
            ),
          const SizedBox(height: Spacing.md),
          FilledButton.icon(
            onPressed: _posting ? null : _submit,
            icon: _posting
                ? const SizedBox(
                    width: 15,
                    height: 15,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, size: 17),
            label: Text(widget.submitLabel),
          ),
        ],
      ),
    );
  }
}

/// A top-level comment with its (collapsible) reply thread underneath.
class _CommentThread extends StatefulWidget {
  const _CommentThread({
    required this.comment,
    required this.replies,
    required this.nickOf,
    required this.onReply,
    required this.replyLabel,
  });

  final WalineComment comment;
  final List<WalineComment> replies;
  final String? Function(String?) nickOf;
  final ValueChanged<WalineComment> onReply;
  final String replyLabel;

  @override
  State<_CommentThread> createState() => _CommentThreadState();
}

class _CommentThreadState extends State<_CommentThread> {
  /// Threads start collapsed; a single tap reveals the whole chain.
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _CommentTile(
          comment: widget.comment,
          onReply: widget.onReply,
          replyLabel: widget.replyLabel,
        ),
        if (widget.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(
                left: Spacing.xl, top: 2, bottom: Spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact inline toggle: a quiet text chip on the thread
                // line, no card or icon button chrome.
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: Radii.smAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: Spacing.sm, vertical: 3),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _expanded
                              ? l10n.communityCollapseReplies
                              : l10n.communityExpandReplies(
                                  widget.replies.length),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        Icon(
                          _expanded
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded)
                  // Hairline thread line ties replies to their parent
                  // without heavy indentation or extra cards.
                  Container(
                    margin: const EdgeInsets.only(
                        left: Spacing.md, top: 2, bottom: 2),
                    padding: const EdgeInsets.only(left: Spacing.md),
                    decoration: BoxDecoration(
                      border: Border(
                        left: BorderSide(color: colors.hairline, width: 2),
                      ),
                    ),
                    child: Column(
                      children: [
                        for (final r in widget.replies)
                          _ReplyTile(
                            comment: r,
                            mentionNick: widget.nickOf(r.rid),
                            onReply: widget.onReply,
                            replyLabel: widget.replyLabel,
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

/// Small pill badge for a registered user's role/label, shown after the
/// nickname. Anonymous comments have no label and render nothing.
class _UserBadge extends StatelessWidget {
  const _UserBadge({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(left: Spacing.xs + 2),
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs + 2, vertical: 1),
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.12),
        borderRadius: Radii.smAll,
      ),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .labelSmall
            ?.copyWith(color: scheme.primary, fontSize: 10),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.replyLabel,
  });

  final WalineComment comment;
  final ValueChanged<WalineComment> onReply;
  final String replyLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = context.mediaryColors;

    return MediaryCard(
      hoverable: false,
      padding: const EdgeInsets.all(Spacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.12),
                  borderRadius: Radii.smAll,
                ),
                child: Center(
                  child: Text(
                    comment.nick.isEmpty ? '?' : comment.nick[0].toUpperCase(),
                    style: text.labelLarge?.copyWith(color: scheme.primary),
                  ),
                ),
              ),
              const SizedBox(width: Spacing.sm + 2),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.nick,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: text.titleSmall,
                          ),
                        ),
                        if (comment.label != null)
                          _UserBadge(text: comment.label!),
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _relativeTime(context, comment.insertedAt),
                          style: text.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (comment.addr != null) ...[
                          Text(
                            ' · ',
                            style: text.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Flexible(
                            child: Text(
                              comment.addr!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onReply(comment),
                style: TextButton.styleFrom(
                  foregroundColor: colors.accent,
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
                ),
                child: Text(replyLabel),
              ),
            ],
          ),
          const SizedBox(height: Spacing.sm + 2),
          SelectableText(comment.comment, style: text.bodyMedium),
        ],
      ),
    );
  }
}

/// A reply inside an expanded thread: lighter than a top-level card — no
/// card chrome, just avatar initial, meta line and body.
class _ReplyTile extends StatelessWidget {
  const _ReplyTile({
    required this.comment,
    required this.onReply,
    required this.replyLabel,
    this.mentionNick,
  });

  final WalineComment comment;
  final ValueChanged<WalineComment> onReply;
  final String replyLabel;

  /// Nickname of the comment this reply answers; rendered inline as
  /// "@nick" before the author (Valine convention).
  final String? mentionNick;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final colors = context.mediaryColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            comment.nick,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style:
                                text.labelLarge?.copyWith(color: scheme.primary),
                          ),
                        ),
                        if (comment.label != null)
                          _UserBadge(text: comment.label!),
                        if (mentionNick != null) ...[
                          const SizedBox(width: Spacing.xs),
                          Flexible(
                            child: Text(
                              '@$mentionNick',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  text.labelSmall?.copyWith(color: colors.accent),
                            ),
                          ),
                        ],
                      ],
                    ),
                    Row(
                      children: [
                        Text(
                          _relativeTime(context, comment.insertedAt),
                          style: text.labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                        if (comment.addr != null) ...[
                          Text(
                            ' · ',
                            style: text.labelSmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                          Flexible(
                            child: Text(
                              comment.addr!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.labelSmall
                                  ?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              InkWell(
                onTap: () => onReply(comment),
                borderRadius: Radii.smAll,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.xs, vertical: 2),
                  child: Text(
                    replyLabel,
                    style: text.labelSmall?.copyWith(color: colors.accent),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          SelectableText(comment.comment, style: text.bodyMedium),
        ],
      ),
    );
  }
}

/// Compliance notice pinned at the top of the board: posting illegal or
/// rule-breaking content is prohibited and carries personal liability.
class _BoardWarning extends StatelessWidget {
  const _BoardWarning();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.mediaryColors;
    final text = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md, vertical: Spacing.sm + 2),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.10),
        borderRadius: Radii.mdAll,
        border: Border.all(color: colors.warning.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.gavel_rounded, size: 16, color: colors.warning),
          const SizedBox(width: Spacing.sm),
          Expanded(
            child: Text(
              l10n.communityWarning,
              style: text.labelSmall?.copyWith(
                color: colors.warning,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorRetry extends StatelessWidget {
  const _ErrorRetry({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.mediaryColors;
    return Row(
      children: [
        Icon(Icons.cloud_off_rounded, size: 17, color: colors.danger),
        const SizedBox(width: Spacing.sm),
        Expanded(
          child: Text(
            message,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.danger),
          ),
        ),
        TextButton(
            onPressed: onRetry,
            child: Text(
              AppLocalizations.of(context).retry,
            )),
      ],
    );
  }
}

String _relativeTime(BuildContext context, DateTime time) {
  final l10n = AppLocalizations.of(context);
  final diff = DateTime.now().difference(time.toLocal());
  if (diff.inMinutes < 1) return l10n.timeJustNow;
  if (diff.inMinutes < 60) return l10n.timeMinutesAgo(diff.inMinutes);
  if (diff.inHours < 24) return l10n.timeHoursAgo(diff.inHours);
  if (diff.inDays < 30) return l10n.timeDaysAgo(diff.inDays);
  final local = time.toLocal();
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-'
      '${local.day.toString().padLeft(2, '0')}';
}
