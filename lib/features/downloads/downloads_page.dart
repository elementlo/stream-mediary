import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/empty_state.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../core/widgets/segment_progress_bar.dart';
import '../../core/widgets/status_badge.dart';
import '../../engine/download_engine.dart';
import '../../engine/failure_diagnostics.dart';
import '../../engine/task/task_state.dart';
import '../../providers/app_providers.dart';
import 'recover_source_dialog.dart';

class DownloadsPage extends ConsumerWidget {
  const DownloadsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(taskListProvider);

    final active = tasks.values.where((t) => !t.state.isTerminal).toList()
      ..sort(
        (a, b) => a.state == TaskState.queued && b.state == TaskState.queued
            ? a.queueOrder.compareTo(b.queueOrder)
            : b.createdAt.compareTo(a.createdAt),
      );

    final downloading = active
        .where((t) => t.state == TaskState.downloading)
        .length;
    final paused = active.where((t) => t.state == TaskState.paused).length;

    return MediaryScaffold(
      title: l10n.downloads,
      subtitle: active.isEmpty
          ? l10n.downloadsSummaryEmpty
          : l10n.downloadsSummary(downloading, paused),
      maxWidth: Breakpoints.contentList,
      actions: [
        IconButton(
          tooltip: l10n.batchImport,
          onPressed: () => context.push('/batch'),
          icon: const Icon(Icons.playlist_add_rounded),
        ),
        if (downloading > 0) _PauseAllButton(count: downloading),
      ],
      child: active.isEmpty
          ? EmptyState(
              icon: Icons.download_done_rounded,
              title: l10n.emptyDownloadsTitle,
              message: l10n.emptyDownloadsHint,
              action: FilledButton.icon(
                onPressed: () => context.push('/new'),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: Text(l10n.emptyDownloadsAction),
              ),
            )
          : ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: active.length,
              separatorBuilder: (_, _) => const SizedBox(height: Spacing.md),
              itemBuilder: (context, i) => TaskCard(task: active[i]),
            ),
    );
  }
}

class _PauseAllButton extends ConsumerWidget {
  const _PauseAllButton({required this.count});

  final int count;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(downloadEngineProvider);
    final profile = context.platformProfile;

    if (!profile.isDesktop) {
      return IconButton(
        tooltip: l10n.pauseAll,
        onPressed: () => _pauseAll(ref, engine),
        icon: const Icon(Icons.pause_circle_outline_rounded),
      );
    }

    return OutlinedButton.icon(
      onPressed: () => _pauseAll(ref, engine),
      icon: const Icon(Icons.pause_rounded, size: 15),
      label: Text(l10n.pauseAll),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 32),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
        textStyle: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  void _pauseAll(WidgetRef ref, DownloadEngine engine) {
    final tasks = ref.read(taskListProvider);
    for (final task in tasks.values) {
      if (task.state == TaskState.downloading) {
        engine.pauseTask(task.id);
      }
    }
  }
}

/// A single download task.
///
/// Layout: title + status badge, the segment progress bar, then a metrics row.
/// Metrics use tabular figures so the speed and size columns do not jitter as
/// values tick.
class TaskCard extends ConsumerWidget {
  const TaskCard({super.key, required this.task});

  final TaskViewModel task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(downloadEngineProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;
    final diagnosis = FailureDiagnosis.fromError(task.errorMsg);

    final style = TaskStateStyle.of(context, task.state);
    final isMerging = task.state == TaskState.merging;
    final isDownloading = task.state == TaskState.downloading;
    final isLive = TaskStateStyle.isLive(task.state);

    final percent = isMerging
        ? task.mergeFraction
        : task.downloadFraction.clamp(0.0, 1.0);

    return MediaryCard(
      accent: isLive ? style.color : null,
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
                  style: text.titleMedium,
                ),
              ),
              const SizedBox(width: Spacing.sm),
              StatusBadge(
                state: task.state,
                label: _statusLabel(l10n, task.state),
              ),
            ],
          ),
          const SizedBox(height: Spacing.md),
          SegmentProgressBar(
            totalSegments: task.totalSegments,
            doneSegments: task.doneSegments,
            active: isDownloading,
            merging: isMerging,
            mergeFraction: task.mergeFraction,
            semanticLabel: task.totalSegments > 0
                ? l10n.segmentsProgressLabel(
                    (percent * 100).round(),
                    task.doneSegments,
                    task.totalSegments,
                  )
                : null,
          ),
          const SizedBox(height: Spacing.sm + 2),
          _MetricsRow(
            task: task,
            isMerging: isMerging,
            isDownloading: isDownloading,
            percent: percent,
            hintColor: scheme.onSurfaceVariant,
            accentColor: style.color,
          ),
          if (task.errorMsg != null && task.state == TaskState.failed) ...[
            const SizedBox(height: Spacing.md),
            Container(
              padding: const EdgeInsets.all(Spacing.md - 2),
              decoration: BoxDecoration(
                color: colors.dangerContainer.withValues(alpha: 0.5),
                borderRadius: Radii.smAll,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline_rounded,
                    size: 15,
                    color: colors.danger,
                  ),
                  const SizedBox(width: Spacing.sm - 2),
                  Expanded(
                    child: Text(
                      '${diagnosis.reason}。${diagnosis.action}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(color: colors.danger),
                    ),
                  ),
                ],
              ),
            ),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => showRecoverSourceDialog(
                    context,
                    engine,
                    ref.read(engineTaskStoreProvider),
                    task.id,
                  ),
                  icon: const Icon(Icons.link_rounded, size: 16),
                  label: Text(l10n.replaceSource),
                ),
                TextButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(
                      ClipboardData(
                        text: diagnosis.report(taskId: task.id, url: task.url),
                      ),
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.diagnosticCopied)),
                      );
                    }
                  },
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(l10n.copyDiagnostic),
                ),
              ],
            ),
          ],
          if (_hasActions(task.state)) ...[
            const SizedBox(height: Spacing.md),
            _ActionRow(
              state: task.state,
              onPause: () => engine.pauseTask(task.id),
              onResume: () => engine.resumeTask(task.id),
              onCancel: () => _confirmCancel(context, ref, engine, task),
              onRetry: () => engine.retryTask(task.id),
            ),
          ],
          if (task.state == TaskState.queued) ...[
            const SizedBox(height: Spacing.sm),
            Wrap(
              alignment: WrapAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: () => engine.moveQueuedTask(task.id, first: true),
                  icon: const Icon(Icons.vertical_align_top_rounded, size: 16),
                  label: Text(l10n.moveFirst),
                ),
                TextButton.icon(
                  onPressed: () => engine.moveQueuedTask(task.id, first: false),
                  icon: const Icon(
                    Icons.vertical_align_bottom_rounded,
                    size: 16,
                  ),
                  label: Text(l10n.moveLast),
                ),
                TextButton.icon(
                  onPressed: () => _confirmCancel(context, ref, engine, task),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: Text(l10n.cancel),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  bool _hasActions(TaskState state) => switch (state) {
    TaskState.downloading ||
    TaskState.paused ||
    TaskState.failed ||
    TaskState.canceled => true,
    _ => false,
  };

  String _statusLabel(AppLocalizations l10n, TaskState state) =>
      switch (state) {
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

  Future<void> _confirmCancel(
    BuildContext context,
    WidgetRef ref,
    DownloadEngine engine,
    TaskViewModel task,
  ) async {
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

/// Metrics line: segment count, size, ETA on the left; speed and percent right.
class _MetricsRow extends StatelessWidget {
  const _MetricsRow({
    required this.task,
    required this.isMerging,
    required this.isDownloading,
    required this.percent,
    required this.hintColor,
    required this.accentColor,
  });

  final TaskViewModel task;
  final bool isMerging;
  final bool isDownloading;
  final double percent;
  final Color hintColor;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final style = Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: hintColor);

    if (isMerging) {
      return Row(
        children: [
          Expanded(
            child: Text(
              l10n.mergeReadyHint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          const SizedBox(width: Spacing.sm),
          Text(
            '${(percent * 100).round()}%',
            style: style?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    }

    final remainingBytes = task.totalBytes - task.downloadedBytes;
    final showEta =
        isDownloading && task.bytesPerSecond > 0 && remainingBytes > 0;

    return Row(
      children: [
        if (task.totalSegments > 0)
          Text(
            l10n.segmentsProgress(task.doneSegments, task.totalSegments),
            style: style,
          ),
        if (task.totalSegments > 0) const SizedBox(width: Spacing.md),
        Text(formatBytes(task.downloadedBytes), style: style),
        if (showEta) ...[
          const SizedBox(width: Spacing.md),
          Flexible(
            child: Text(
              l10n.remaining(formatEta(task.bytesPerSecond, remainingBytes)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
        ],
        const Spacer(),
        if (isDownloading)
          Text(
            l10n.speed(formatSpeed(task.bytesPerSecond)),
            style: style?.copyWith(
              color: accentColor,
              fontWeight: FontWeight.w600,
            ),
          ),
      ],
    );
  }
}

/// Contextual actions for the task's current state.
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.state,
    required this.onPause,
    required this.onResume,
    required this.onCancel,
    required this.onRetry,
  });

  final TaskState state;
  final VoidCallback onPause;
  final VoidCallback onResume;
  final VoidCallback onCancel;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children:
          switch (state) {
                TaskState.downloading => [
                  _Action(l10n.pause, Icons.pause_rounded, onPause),
                  _Action(
                    l10n.cancel,
                    Icons.close_rounded,
                    onCancel,
                    muted: true,
                  ),
                ],
                TaskState.paused => [
                  _Action(l10n.resume, Icons.play_arrow_rounded, onResume),
                  _Action(
                    l10n.cancel,
                    Icons.close_rounded,
                    onCancel,
                    muted: true,
                  ),
                ],
                TaskState.failed || TaskState.canceled => [
                  _Action(l10n.retry, Icons.refresh_rounded, onRetry),
                ],
                _ => const <Widget>[],
              }
              .map(
                (w) => Padding(
                  padding: const EdgeInsets.only(left: Spacing.sm),
                  child: DefaultTextStyle.merge(
                    style: text.bodyMedium!,
                    child: w,
                  ),
                ),
              )
              .toList(),
    );
  }
}

class _Action extends StatelessWidget {
  const _Action(this.label, this.icon, this.onPressed, {this.muted = false});

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = muted ? scheme.onSurfaceVariant : scheme.primary;

    return TextButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 16, color: color),
      label: Text(label, style: text.bodyMedium?.copyWith(color: color)),
      style: TextButton.styleFrom(
        minimumSize: const Size(0, 34),
        padding: const EdgeInsets.symmetric(horizontal: Spacing.md - 2),
      ),
    );
  }
}
