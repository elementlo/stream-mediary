import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../core/widgets/status_badge.dart';
import '../../engine/download_engine.dart';
import '../../engine/failure_diagnostics.dart';
import '../../engine/task/task_state.dart';
import '../../providers/app_providers.dart';
import '../downloads/recover_source_dialog.dart';

class HistoryPage extends ConsumerStatefulWidget {
  const HistoryPage({super.key});

  @override
  ConsumerState<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends ConsumerState<HistoryPage> {
  String _search = '';
  String _filter = 'all';
  String _sort = 'newest';

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(taskListProvider);

    final terminal =
        tasks.values
            .where((t) => t.state.isTerminal)
            .where((t) => t.title.toLowerCase().contains(_search.toLowerCase()))
            .where(
              (t) =>
                  _filter == 'all' ||
                  (_filter == 'completed' && t.state == TaskState.completed) ||
                  (_filter == 'failed' && t.state != TaskState.completed),
            )
            .toList()
          ..sort(
            (a, b) => switch (_sort) {
              'oldest' => a.createdAt.compareTo(b.createdAt),
              'size' => b.downloadedBytes.compareTo(a.downloadedBytes),
              'title' => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
              _ => b.createdAt.compareTo(a.createdAt),
            },
          );

    final completedCount = terminal
        .where((t) => t.state == TaskState.completed)
        .length;

    return MediaryScaffold(
      title: l10n.history,
      subtitle: terminal.isEmpty ? null : l10n.historySummary(terminal.length),
      maxWidth: Breakpoints.contentList,
      actions: [
        if (completedCount > 0)
          _ClearCompletedButton(
            count: completedCount,
            onPressed: () =>
                _confirmClearCompleted(context, ref, completedCount),
          ),
      ],
      child: Column(
        children: [
          TextField(
            onChanged: (value) => setState(() => _search = value),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded),
              hintText: l10n.searchHistory,
            ),
          ),
          const SizedBox(height: Spacing.sm),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _filter,
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(l10n.filterAll)),
                    DropdownMenuItem(
                      value: 'completed',
                      child: Text(l10n.statusCompleted),
                    ),
                    DropdownMenuItem(
                      value: 'failed',
                      child: Text(l10n.filterIncomplete),
                    ),
                  ],
                  onChanged: (v) => setState(() => _filter = v ?? 'all'),
                ),
              ),
              const SizedBox(width: Spacing.sm),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _sort,
                  items: [
                    DropdownMenuItem(
                      value: 'newest',
                      child: Text(l10n.sortNewest),
                    ),
                    DropdownMenuItem(
                      value: 'oldest',
                      child: Text(l10n.sortOldest),
                    ),
                    DropdownMenuItem(value: 'size', child: Text(l10n.sortSize)),
                    DropdownMenuItem(
                      value: 'title',
                      child: Text(l10n.sortTitle),
                    ),
                  ],
                  onChanged: (v) => setState(() => _sort = v ?? 'newest'),
                ),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          Expanded(
            child: terminal.isEmpty
                ? EmptyState(
                    icon: Icons.history_rounded,
                    title: l10n.emptyHistoryTitle,
                    message: l10n.emptyHistoryHint,
                  )
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemCount: terminal.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: Spacing.sm + 2),
                    itemBuilder: (context, i) => _HistoryRow(task: terminal[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClearCompleted(
    BuildContext context,
    WidgetRef ref,
    int completedCount,
  ) async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final engine = ref.read(downloadEngineProvider);
    final tasks = ref.read(taskListProvider);

    final deleteFiles = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(
        title: l10n.confirmClearCompletedTitle,
        message: l10n.confirmClearCompletedMessage,
      ),
    );
    if (deleteFiles == null) return;

    final completedIds = tasks.values
        .where((t) => t.state == TaskState.completed)
        .map((t) => t.id)
        .toList();
    for (final id in completedIds) {
      await engine.removeTask(id, deleteFiles: deleteFiles);
    }
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.clearedCompleted(completedIds.length))),
    );
  }
}

class _ClearCompletedButton extends StatelessWidget {
  const _ClearCompletedButton({required this.count, required this.onPressed});

  final int count;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final profile = context.platformProfile;

    if (!profile.isDesktop) {
      return IconButton(
        tooltip: l10n.clearCompleted,
        onPressed: onPressed,
        icon: const Icon(Icons.cleaning_services_rounded),
      );
    }

    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.cleaning_services_rounded, size: 15),
      label: Text(l10n.clearCompleted),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        textStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

/// Confirm dialog with an "also delete local files" checkbox.
///
/// Pops `true` (delete files), `false` (keep files) or null (canceled).
class _DeleteConfirmDialog extends StatefulWidget {
  const _DeleteConfirmDialog({required this.title, required this.message});

  final String title;
  final String message;

  @override
  State<_DeleteConfirmDialog> createState() => _DeleteConfirmDialogState();
}

class _DeleteConfirmDialogState extends State<_DeleteConfirmDialog> {
  bool _deleteFiles = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.message),
          const SizedBox(height: Spacing.md),
          InkWell(
            onTap: () => setState(() => _deleteFiles = !_deleteFiles),
            borderRadius: Radii.smAll,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: Spacing.sm - 2),
              child: Row(
                children: [
                  _Checkbox(checked: _deleteFiles),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Text(
                      l10n.deleteLocalFiles,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context, _deleteFiles),
          child: Text(l10n.confirm),
        ),
      ],
    );
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.checked});

  final bool checked;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: Motion.fast,
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        color: checked ? scheme.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: checked ? scheme.primary : context.mediaryHairline,
          width: 1.5,
        ),
      ),
      child: checked
          ? Icon(Icons.check_rounded, size: 13, color: scheme.onPrimary)
          : null,
    );
  }
}

/// A finished / failed / canceled record.
///
/// Uses a status-tinted icon tile as the leading element, which gives the list
/// a scannable rhythm of outcome colors down the left edge.
class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.task});

  final TaskViewModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(downloadEngineProvider);
    final style = TaskStateStyle.of(context, task.state);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    final isPlayable =
        task.state == TaskState.completed &&
        task.outputPath != null &&
        File(task.outputPath!).existsSync();

    return MediaryCard(
      onTap: isPlayable ? () => context.push('/player/${task.id}') : null,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: style.color.withValues(alpha: 0.12),
              borderRadius:
                  Radii.smAll + const BorderRadius.all(Radius.circular(2)),
            ),
            child: Icon(style.icon, size: 18, color: style.color),
          ),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: text.titleMedium,
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(
                      formatTimestamp(task.createdAt),
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    if (task.downloadedBytes > 0) ...[
                      Text(
                        '  ·  ',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      Text(
                        formatBytes(task.downloadedBytes),
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                    if (task.state == TaskState.failed) ...[
                      const SizedBox(width: Spacing.sm),
                      Flexible(
                        child: Text(
                          l10n.statusFailed,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: context.mediaryColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (task.state == TaskState.completed && !isPlayable)
                  Text(
                    l10n.fileMissing,
                    style: text.bodySmall?.copyWith(color: scheme.error),
                  ),
                if (isPlayable &&
                    task.durationMs > 0 &&
                    task.playbackMs > 0) ...[
                  const SizedBox(height: Spacing.xs),
                  LinearProgressIndicator(
                    value: (task.playbackMs / task.durationMs)
                        .clamp(0, 1)
                        .toDouble(),
                    minHeight: 3,
                  ),
                  Text(
                    l10n.continueAt(
                      Duration(milliseconds: task.playbackMs)
                          .toString()
                          .split('.')
                          .first,
                    ),
                    style: text.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: Spacing.sm),
          _RowMenu(
            task: task,
            isPlayable: isPlayable,
            onPlay: () => context.push('/player/${task.id}'),
            onRedownload: () async {
              if (task.state == TaskState.completed) {
                await engine.redownloadTask(task.id, const Uuid().v4());
              } else {
                await engine.retryTask(task.id);
              }
              if (context.mounted) context.go('/downloads');
            },
            onOpenFolder: () => _openFolder(task.outputPath!),
            onShare: () async {
              final box = context.findRenderObject() as RenderBox?;
              await SharePlus.instance.share(
                ShareParams(
                  files: [XFile(task.outputPath!)],
                  sharePositionOrigin: box == null
                      ? null
                      : box.localToGlobal(Offset.zero) & box.size,
                ),
              );
            },
            onDelete: () => _confirmDelete(context, engine),
            onRename: () => _rename(context, engine),
            onRecover: () async {
              final recovered = await showRecoverSourceDialog(
                context,
                engine,
                ref.read(engineTaskStoreProvider),
                task.id,
              );
              if (recovered && context.mounted) context.go('/downloads');
            },
            onCopyDiagnostic: () async {
              final diagnosis = FailureDiagnosis.fromError(task.errorMsg);
              await Clipboard.setData(
                ClipboardData(
                  text: diagnosis.report(taskId: task.id, url: task.url),
                ),
              );
              if (context.mounted) {
                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text(l10n.diagnosticCopied)));
              }
            },
          ),
        ],
      ),
    );
  }

  Future<void> _rename(BuildContext context, DownloadEngine engine) async {
    final controller = TextEditingController(text: task.title);
    final title = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocalizations.of(context).rename),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null) await engine.renameTask(task.id, title);
  }

  Future<void> _openFolder(String path) async {
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', path]);
    } else {
      await Process.run('xdg-open', [File(path).parent.path]);
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    DownloadEngine engine,
  ) async {
    final l10n = AppLocalizations.of(context);
    final deleteFiles = await showDialog<bool>(
      context: context,
      builder: (context) => _DeleteConfirmDialog(
        title: l10n.confirmDeleteTitle,
        message: l10n.confirmDeleteMessage,
      ),
    );
    if (deleteFiles == null) return;
    await engine.removeTask(task.id, deleteFiles: deleteFiles);
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.task,
    required this.isPlayable,
    required this.onPlay,
    required this.onRedownload,
    required this.onOpenFolder,
    required this.onShare,
    required this.onDelete,
    required this.onRename,
    required this.onRecover,
    required this.onCopyDiagnostic,
  });

  final TaskViewModel task;
  final bool isPlayable;
  final VoidCallback onPlay;
  final VoidCallback onRedownload;
  final VoidCallback onOpenFolder;
  final VoidCallback onShare;
  final VoidCallback onDelete;
  final VoidCallback onRename;
  final VoidCallback onRecover;
  final VoidCallback onCopyDiagnostic;

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    return PopupMenuButton<String>(
      icon: Icon(Icons.more_horiz_rounded, color: scheme.onSurfaceVariant),
      tooltip: l10n.settings,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(borderRadius: Radii.mdAll),
      onSelected: (value) {
        switch (value) {
          case 'play':
            onPlay();
          case 'redownload':
            onRedownload();
          case 'open':
            onOpenFolder();
          case 'share':
            onShare();
          case 'delete':
            onDelete();
          case 'rename':
            onRename();
          case 'recover':
            onRecover();
          case 'diagnostic':
            onCopyDiagnostic();
        }
      },
      itemBuilder: (context) => [
        if (isPlayable)
          PopupMenuItem(
            value: 'play',
            child: _MenuItem(icon: Icons.play_arrow_rounded, label: l10n.play),
          ),
        PopupMenuItem(
          value: 'redownload',
          child: _MenuItem(icon: Icons.refresh_rounded, label: l10n.redownload),
        ),
        if (task.state == TaskState.failed) ...[
          PopupMenuItem(
            value: 'recover',
            child: _MenuItem(
              icon: Icons.link_rounded,
              label: l10n.replaceSource,
            ),
          ),
          PopupMenuItem(
            value: 'diagnostic',
            child: _MenuItem(
              icon: Icons.copy_rounded,
              label: l10n.copyDiagnostic,
            ),
          ),
        ],
        if (task.outputPath != null && _isDesktop)
          PopupMenuItem(
            value: 'open',
            child: _MenuItem(
              icon: Icons.folder_open_rounded,
              label: l10n.openFolder,
            ),
          ),
        if (isPlayable)
          PopupMenuItem(
            value: 'share',
            child: _MenuItem(icon: Icons.share_rounded, label: l10n.shareFile),
          ),
        PopupMenuItem(
          value: 'rename',
          child: _MenuItem(icon: Icons.edit_rounded, label: l10n.rename),
        ),
        PopupMenuItem(
          value: 'delete',
          child: _MenuItem(
            icon: Icons.delete_rounded,
            label: l10n.delete,
            danger: true,
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  const _MenuItem({
    required this.icon,
    required this.label,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = danger ? context.mediaryColors.danger : scheme.onSurface;

    return Row(
      children: [
        Icon(icon, size: 17, color: color),
        const SizedBox(width: Spacing.md),
        Text(label, style: TextStyle(color: color)),
      ],
    );
  }
}
