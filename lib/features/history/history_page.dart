import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../data/db/app_database.dart';
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

    return Scaffold(
      appBar: AppBar(title: Text(l10n.history)),
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
    final db = ref.read(appDatabaseProvider);
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
                await _confirmDelete(context, db);
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

  Future<void> _confirmDelete(BuildContext context, AppDatabase db) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.confirmDeleteTitle),
        content: Text(l10n.confirmDeleteMessage),
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
      await db.deleteTask(task.id);
    }
  }
}
