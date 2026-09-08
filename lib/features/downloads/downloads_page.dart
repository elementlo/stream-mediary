import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../engine/download_engine.dart';
import '../../engine/task/task_state.dart';
import '../../providers/app_providers.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(taskListProvider);

    final active = tasks.values
        .where((t) => !t.state.isTerminal)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloads)),
      body: active.isEmpty
          ? _EmptyState(onAdd: () => context.push('/new'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: active.length,
              itemBuilder: (context, i) =>
                  TaskCard(task: active[i]),
            ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.download_done_rounded,
                size: 72, color: scheme.outline),
            const SizedBox(height: 16),
            Text(l10n.emptyDownloads,
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.emptyDownloadsHint,
              textAlign: TextAlign.center,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.newDownload),
            ),
          ],
        ),
      ),
    );
  }
}

class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});

  final TaskViewModel task;

  String _statusLabel(BuildContext context, TaskState state) {
    final l10n = AppLocalizations.of(context);
    return switch (state) {
      TaskState.created => l10n.statusCreated,
      TaskState.parsing => l10n.statusParsing,
      TaskState.previewReady => l10n.statusPreviewReady,
      TaskState.queued => l10n.statusQueued,
      TaskState.downloading => l10n.statusDownloading,
      TaskState.paused => l10n.statusPaused,
      TaskState.merging => l10n.statusMerging,
      TaskState.completed => l10n.statusCompleted,
      TaskState.failed => l10n.statusFailed,
      TaskState.canceled => l10n.statusCanceled,
    };
  }

  Color _statusColor(BuildContext context, TaskState state) {
    final scheme = Theme.of(context).colorScheme;
    return switch (state) {
      TaskState.downloading || TaskState.merging => scheme.primary,
      TaskState.completed => Colors.green,
      TaskState.failed => scheme.error,
      TaskState.paused || TaskState.queued => scheme.outline,
      _ => scheme.outline,
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(downloadEngineProvider);
    final scheme = Theme.of(context).colorScheme;

    final isMerging = task.state == TaskState.merging;
    final progress = isMerging ? task.mergeFraction : task.downloadFraction;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(_statusLabel(context, task.state)),
                  labelStyle: TextStyle(
                    color: _statusColor(context, task.state),
                    fontSize: 12,
                  ),
                  side: BorderSide.none,
                  backgroundColor: _statusColor(context, task.state)
                      .withValues(alpha: 0.12),
                  padding: EdgeInsets.zero,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text(
                  '${task.doneSegments}/${task.totalSegments}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(width: 12),
                Text(
                  formatBytes(task.downloadedBytes),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const Spacer(),
                if (task.state == TaskState.downloading) ...[
                  Text(
                    l10n.speed(formatSpeed(task.bytesPerSecond)),
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.primary),
                  ),
                ],
              ],
            ),
            if (task.errorMsg != null && task.state == TaskState.failed) ...[
              const SizedBox(height: 8),
              Text(
                task.errorMsg!,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.error),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: _buildActions(context, ref, engine),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildActions(
      BuildContext context, WidgetRef ref, DownloadEngine engine) {
    final l10n = AppLocalizations.of(context);
    final actions = <Widget>[];

    switch (task.state) {
      case TaskState.downloading:
        actions.add(TextButton.icon(
          onPressed: () => engine.pauseTask(task.id),
          icon: const Icon(Icons.pause_rounded, size: 18),
          label: Text(l10n.pause),
        ));
        actions.add(TextButton.icon(
          onPressed: () => _confirmCancel(context, ref, engine),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: Text(l10n.cancel),
        ));
      case TaskState.paused:
        actions.add(TextButton.icon(
          onPressed: () => engine.resumeTask(task.id),
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: Text(l10n.resume),
        ));
        actions.add(TextButton.icon(
          onPressed: () => _confirmCancel(context, ref, engine),
          icon: const Icon(Icons.close_rounded, size: 18),
          label: Text(l10n.cancel),
        ));
      case TaskState.failed:
      case TaskState.canceled:
        actions.add(TextButton.icon(
          onPressed: () => engine.retryTask(task.id),
          icon: const Icon(Icons.refresh_rounded, size: 18),
          label: Text(l10n.retry),
        ));
      default:
        break;
    }
    return actions;
  }

  Future<void> _confirmCancel(
      BuildContext context, WidgetRef ref, DownloadEngine engine) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmCancelTitle),
        content: Text(l10n.confirmCancelMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await engine.cancelTask(task.id);
    }
  }
}
