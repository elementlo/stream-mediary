import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../engine/download_engine.dart';
import '../../engine/task/task_state.dart';
import '../../providers/app_providers.dart';

class HistoryPage extends ConsumerWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tasks = ref.watch(taskListProvider);

    final terminal = tasks.values
        .where((t) => t.state.isTerminal)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final completedCount =
        terminal.where((t) => t.state == TaskState.completed).length;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.history),
        actions: [
          if (completedCount > 0)
            IconButton(
              tooltip: l10n.clearCompleted,
              icon: const Icon(Icons.cleaning_services_rounded),
              onPressed: () =>
                  _confirmClearCompleted(context, ref, completedCount),
            ),
        ],
      ),
      body: terminal.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.history_rounded,
                      size: 72,
                      color: Theme.of(context).colorScheme.outline),
                  const SizedBox(height: 16),
                  Text(l10n.emptyHistory,
                      style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: terminal.length,
              itemBuilder: (context, i) =>
                  _HistoryTile(task: terminal[i]),
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
        children: [
          Text(widget.message),
          const SizedBox(height: 12),
          CheckboxListTile(
            value: _deleteFiles,
            onChanged: (v) => setState(() => _deleteFiles = v ?? false),
            title: Text(l10n.deleteLocalFiles),
            controlAffinity: ListTileControlAffinity.leading,
            contentPadding: EdgeInsets.zero,
            dense: true,
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

class _HistoryTile extends ConsumerWidget {
  const _HistoryTile({required this.task});

  final TaskViewModel task;

  IconData get _icon => switch (task.state) {
        TaskState.completed => Icons.check_circle_rounded,
        TaskState.failed => Icons.error_rounded,
        _ => Icons.cancel_rounded,
      };

  Color _color(BuildContext context) => switch (task.state) {
        TaskState.completed => Colors.green,
        TaskState.failed => Theme.of(context).colorScheme.error,
        _ => Theme.of(context).colorScheme.outline,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final engine = ref.read(downloadEngineProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: Icon(_icon, color: _color(context)),
        title: Text(
          task.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${DateTime.fromMillisecondsSinceEpoch(task.createdAt)}'
          '${task.downloadedBytes > 0 ? ' · ${formatBytes(task.downloadedBytes)}' : ''}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            switch (value) {
              case 'play':
                context.push('/player/${task.id}');
              case 'redownload':
                await engine.retryTask(task.id);
                if (context.mounted) context.go('/downloads');
              case 'open':
                await _openFolder();
              case 'delete':
                await _confirmDelete(context, engine);
            }
          },
          itemBuilder: (context) => [
            if (task.state == TaskState.completed &&
                task.outputPath != null)
              PopupMenuItem(
                value: 'play',
                child: ListTile(
                  leading: const Icon(Icons.play_arrow_rounded),
                  title: Text(l10n.play),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            PopupMenuItem(
              value: 'redownload',
              child: ListTile(
                leading: const Icon(Icons.refresh_rounded),
                title: Text(l10n.redownload),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            if (task.outputPath != null && _isDesktop)
              PopupMenuItem(
                value: 'open',
                child: ListTile(
                  leading: const Icon(Icons.folder_open_rounded),
                  title: Text(l10n.openFolder),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete_rounded),
                title: Text(l10n.delete),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _isDesktop =>
      Platform.isMacOS || Platform.isWindows || Platform.isLinux;

  Future<void> _openFolder() async {
    final path = task.outputPath;
    if (path == null) return;
    if (Platform.isMacOS) {
      await Process.run('open', ['-R', path]);
    } else if (Platform.isWindows) {
      await Process.run('explorer', ['/select,', path]);
    } else {
      await Process.run('xdg-open', [File(path).parent.path]);
    }
  }

  Future<void> _confirmDelete(BuildContext context, DownloadEngine engine) async {
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
