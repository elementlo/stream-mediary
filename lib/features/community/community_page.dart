import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../data/remote/waline_client.dart';
import '../../providers/app_providers.dart';

/// Community message board backed by a self-hosted Waline instance.
///
/// Guests post with just a nickname (remembered between posts); replies are
/// threaded one level deep, matching Waline's own model. When no server is
/// configured the page explains how to set one up instead of failing.
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
  bool _posting = false;
  String? _error;

  /// objectId of the comment being replied to; null closes the reply box.
  String? _replyTo;
  String? _replyToNick;

  /// Guards the one-time bootstrap (seed nickname + first page load), which
  /// must run after the first frame — mutating controllers or calling
  /// setState during build trips framework assertions.
  bool _bootstrapped = false;

  @override
  void dispose() {
    _scrollController.dispose();
    _contentController.dispose();
    _nickController.dispose();
    super.dispose();
  }

  Future<void> _load({int page = 1, bool refresh = false}) async {
    final client = ref.read(walineClientProvider);
    setState(() {
      _loading = true;
      if (refresh) _error = null;
    });
    try {
      final result = await client.fetchComments(page: page);
      if (!mounted) return;
      setState(() {
        _comments = page == 1
            ? result.comments
            : [..._comments, ...result.comments];
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
      // Any unexpected failure (parse error, etc.) must still release the
      // loading state so the page never spins forever.
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = '$e';
      });
    }
  }

  Future<void> _submit() async {
    final content = _contentController.text.trim();
    final nick = _nickController.text.trim();
    if (content.isEmpty || nick.isEmpty || _posting) return;

    final client = ref.read(walineClientProvider);

    setState(() => _posting = true);
    try {
      await client.postComment(content: content, nick: nick, rid: _replyTo);
      await ref.read(settingsRepositoryProvider).setBoardNick(nick);
      ref.invalidate(boardNickProvider);
      if (!mounted) return;
      _contentController.clear();
      setState(() {
        _posting = false;
        _replyTo = null;
        _replyToNick = null;
      });
      await _load(refresh: true);
    } on WalineException catch (e) {
      if (!mounted) return;
      setState(() {
        _posting = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _posting = false;
        _error = '$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_bootstrapped) {
      _bootstrapped = true;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        final nick = await ref.read(boardNickProvider.future);
        if (mounted && nick.isNotEmpty && _nickController.text.isEmpty) {
          _nickController.text = nick;
        }
        await _load();
      });
    }

    return MediaryScaffold(
      title: l10n.community,
      subtitle: l10n.communitySubtitle,
      maxWidth: Breakpoints.contentForm,
      child: _buildBoard(l10n),
    );
  }

  Widget _buildBoard(AppLocalizations l10n) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        _Composer(
          nickController: _nickController,
          contentController: _contentController,
          posting: _posting,
          replyToNick: _replyToNick,
          onCancelReply: _replyTo == null
              ? null
              : () => setState(() {
                    _replyTo = null;
                    _replyToNick = null;
                  }),
          onSubmit: _submit,
          nickHint: l10n.communityNickHint,
          contentHint: _replyToNick == null
              ? l10n.communityContentHint
              : l10n.communityReplyTo(_replyToNick!),
          submitLabel:
              _replyTo == null ? l10n.communityPost : l10n.communityReply,
        ),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(top: Spacing.md),
            child: _ErrorRetry(
              message: _error!,
              onRetry: () => _load(refresh: true),
            ),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () => _load(refresh: true),
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.only(top: Spacing.lg),
              children: [
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
                  )
                else ...[
                  for (final c in _topLevel)
                    _CommentThread(
                      comment: c,
                      replies: _descendantsOf(c.objectId),
                      nickOf: _nickOf,
                      onReply: (parent) => setState(() {
                        _replyTo = parent.objectId;
                        _replyToNick = parent.nick;
                      }),
                      replyLabel: l10n.communityReplyAction,
                    ),
                  if (_loading && _comments.isNotEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: Spacing.lg),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (_page < _totalPages)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: Spacing.lg),
                      child: Column(
                        children: [
                          Text(
                            l10n.communityPageInfo(_page, _totalPages),
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                    color: scheme.onSurfaceVariant),
                          ),
                          const SizedBox(height: Spacing.xs),
                          OutlinedButton.icon(
                            onPressed:
                                _loading ? null : () => _load(page: _page + 1),
                            icon: const Icon(Icons.expand_more_rounded,
                                size: 16),
                            label: Text(l10n.communityLoadMore),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
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

/// Nickname + content input with a submit button.
class _Composer extends StatelessWidget {
  const _Composer({
    required this.nickController,
    required this.contentController,
    required this.posting,
    required this.onSubmit,
    required this.nickHint,
    required this.contentHint,
    required this.submitLabel,
    this.replyToNick,
    this.onCancelReply,
  });

  final TextEditingController nickController;
  final TextEditingController contentController;
  final bool posting;
  final VoidCallback onSubmit;
  final String nickHint;
  final String contentHint;
  final String submitLabel;
  final String? replyToNick;
  final VoidCallback? onCancelReply;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return MediaryCard(
      hoverable: false,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (replyToNick != null)
            Padding(
              padding: const EdgeInsets.only(bottom: Spacing.sm),
              child: Row(
                children: [
                  Icon(Icons.reply_rounded,
                      size: 15, color: scheme.onSurfaceVariant),
                  const SizedBox(width: Spacing.xs),
                  Expanded(
                    child: Text(
                      replyToNick!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context)
                          .textTheme
                          .labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ),
                  if (onCancelReply != null)
                    IconButton(
                      onPressed: onCancelReply,
                      icon: const Icon(Icons.close_rounded, size: 16),
                      visualDensity: VisualDensity.compact,
                      tooltip: AppLocalizations.of(context).cancel,
                    ),
                ],
              ),
            ),
          TextField(
            controller: nickController,
            maxLength: 24,
            decoration: InputDecoration(
              hintText: nickHint,
              counterText: '',
              isDense: true,
              prefixIcon:
                  const Icon(Icons.person_outline_rounded, size: 18),
            ),
          ),
          const SizedBox(height: Spacing.sm),
          TextField(
            controller: contentController,
            minLines: 3,
            maxLines: 6,
            maxLength: 1000,
            decoration: InputDecoration(
              hintText: contentHint,
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton.icon(
              onPressed: posting ? null : onSubmit,
              icon: posting
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded, size: 17),
              label: Text(submitLabel),
            ),
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

    return Column(
      children: [
        _CommentTile(
          comment: widget.comment,
          onReply: widget.onReply,
          replyLabel: widget.replyLabel,
        ),
        if (widget.replies.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: Spacing.xxl),
            child: Column(
              children: [
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: Radii.smAll,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: Spacing.sm,
                      vertical: Spacing.xs + 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _expanded
                              ? Icons.expand_less_rounded
                              : Icons.expand_more_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: Spacing.xs),
                        Text(
                          _expanded
                              ? l10n.communityCollapseReplies(
                                  widget.replies.length)
                              : l10n.communityExpandReplies(
                                  widget.replies.length),
                          style: Theme.of(context)
                              .textTheme
                              .labelSmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expanded)
                  for (final r in widget.replies)
                    _CommentTile(
                      comment: r,
                      mentionNick: widget.nickOf(r.rid),
                      onReply: widget.onReply,
                      replyLabel: widget.replyLabel,
                    ),
              ],
            ),
          ),
      ],
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.replyLabel,
    this.mentionNick,
  });

  final WalineComment comment;
  final ValueChanged<WalineComment> onReply;
  final String replyLabel;

  /// When this tile is a reply, the nickname of the comment it answers;
  /// rendered as an "@nick" prefix on the body (Valine convention).
  final String? mentionNick;

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
                    Text(comment.nick, style: text.titleSmall),
                    Text(
                      _relativeTime(context, comment.insertedAt),
                      style: text.labelSmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
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
          if (mentionNick != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Text(
                '@$mentionNick',
                style: text.bodyMedium?.copyWith(color: colors.accent),
              ),
            ),
          SelectableText(comment.comment, style: text.bodyMedium),
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
        TextButton(onPressed: onRetry, child: Text(
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
