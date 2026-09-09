import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../../core/l10n/app_localizations.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/storage_access.dart';
import '../../engine/merge/folder_merger.dart';
import '../../providers/app_providers.dart';

/// Folder merger used by this page. Overridable in tests.
final folderMergerProvider = Provider<FolderMerger>((ref) => const FolderMerger());

/// Standalone tool: merge the TS segments inside a user-chosen folder into a
/// single video file (MP4 on desktop via ffmpeg, TS on mobile).
class MergePage extends ConsumerStatefulWidget {
  const MergePage({super.key});

  @override
  ConsumerState<MergePage> createState() => _MergePageState();
}

class _MergePageState extends ConsumerState<MergePage> {
  String? _folderPath;
  FolderScanResult? _scan;
  bool _scanning = false;
  bool _merging = false;
  double _progress = 0;
  int _written = 0;
  int _total = 0;
  FolderMergePhase _phase = FolderMergePhase.concatenating;
  FolderMergeResult? _result;
  bool _preferMp4 = true;

  @override
  void initState() {
    super.initState();
    _loadPreference();
  }

  Future<void> _loadPreference() async {
    final settings = ref.read(settingsRepositoryProvider);
    final merge = await settings.mergePreference();
    if (mounted) setState(() => _preferMp4 = merge == 'prefer_mp4');
  }

  Future<void> _chooseFolder() async {
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);

    if (!await StorageAccess.hasAccess()) {
      final granted = await StorageAccess.requestAccess();
      if (!granted) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(l10n.storagePermissionHint)),
          );
        }
        return;
      }
    }

    String? dir;
    try {
      dir = await file_selector.getDirectoryPath(
        confirmButtonText: l10n.mergeChooseFolder,
      );
    } catch (_) {
      // Platform without a directory picker.
      return;
    }
    if (dir == null || !mounted) return;

    setState(() {
      _folderPath = dir;
      _scan = null;
      _result = null;
      _scanning = true;
      _progress = 0;
    });

    final scan = await ref.read(folderMergerProvider).scan(Directory(dir));
    if (!mounted) return;
    setState(() {
      _scan = scan;
      _scanning = false;
    });

    if (scan.error != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.mergeFolderUnreadable)),
      );
    } else if (scan.isEmpty) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.mergeNoTsFiles)),
      );
    }
  }

  Future<void> _startMerge() async {
    final folderPath = _folderPath;
    if (folderPath == null) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ffmpegPath =
        await ref.read(settingsRepositoryProvider).ffmpegPath();
    if (!mounted) return;

    setState(() {
      _merging = true;
      _progress = 0;
      _written = 0;
      _total = 0;
      _result = null;
      _phase = FolderMergePhase.concatenating;
    });

    final result = await ref.read(folderMergerProvider).mergeFolder(
      Directory(folderPath),
      preferMp4: _preferMp4,
      ffmpegPath: ffmpegPath,
      onProgress: (written, total) {
        if (!mounted) return;
        final v = total == 0 ? 1.0 : written / total;
        // Throttle rebuilds: ignore sub-0.5% changes until completion.
        if ((v - _progress).abs() < 0.005 && v < 1.0) return;
        setState(() {
          _progress = v;
          _written = written;
          _total = total;
        });
      },
      onPhaseChanged: (phase) {
        if (mounted) setState(() => _phase = phase);
      },
    );

    if (!mounted) return;
    setState(() {
      _merging = false;
      _result = result;
      _progress = 1;
    });
    messenger.showSnackBar(
      SnackBar(content: Text(_messageFor(result, l10n))),
    );
  }

  String _messageFor(FolderMergeResult result, AppLocalizations l10n) {
    if (result.success) {
      if (result.downgradedToTs) {
        return l10n.mergeMobileTsHint;
      }
      return l10n.mergeSuccess(result.outputFile!.path);
    }
    return switch (result.error) {
      FolderMergeError.noTsFiles => l10n.mergeNoTsFiles,
      FolderMergeError.folderUnreadable => l10n.mergeFolderUnreadable,
      FolderMergeError.segmentMissing =>
        l10n.mergeSegmentMissing(result.errorMessage ?? ''),
      FolderMergeError.writeFailed || null =>
        l10n.mergeFailed(result.errorMessage ?? ''),
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scan = _scan;
    final canMerge = _folderPath != null &&
        scan != null &&
        !scan.isEmpty &&
        scan.error == null &&
        !_merging;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.navMerge)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _SectionTitle(l10n.mergeFolderSection),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_rounded),
              title: Text(
                _folderPath ?? l10n.mergeChooseFolder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: _merging ? null : _chooseFolder,
            ),
          ),
          if (_scanning) ...[
            const SizedBox(height: 16),
            const LinearProgressIndicator(),
          ],
          if (scan != null && !_scanning && scan.error == null) ...[
            const SizedBox(height: 16),
            _SectionTitle(l10n.mergePreview),
            Card(child: _ScanSummary(scan: scan)),
          ],
          const SizedBox(height: 16),
          _SectionTitle(l10n.mergePreference),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SegmentedButton<bool>(
                segments: [
                  ButtonSegment(
                    value: false,
                    label: Text(l10n.mergeTsOnly),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text(l10n.mergePreferMp4),
                  ),
                ],
                selected: {_preferMp4},
                onSelectionChanged: _merging
                    ? null
                    : (sel) => setState(() => _preferMp4 = sel.first),
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: canMerge ? _startMerge : null,
            icon: _merging
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.call_merge_rounded),
            label: Text(_merging ? l10n.mergeInProgress : l10n.mergeStart),
          ),
          if (_merging) ...[
            const SizedBox(height: 16),
            _phase == FolderMergePhase.concatenating
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      LinearProgressIndicator(value: _progress),
                      const SizedBox(height: 8),
                      Text(
                        '${(_progress * 100).toStringAsFixed(0)}%  ·  '
                        '${formatBytes(_written)} / ${formatBytes(_total)}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const LinearProgressIndicator(),
                      const SizedBox(height: 8),
                      Text(
                        l10n.mergeRemuxing,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
          ],
          if (_result != null) ...[
            const SizedBox(height: 16),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _ScanSummary extends StatelessWidget {
  const _ScanSummary({required this.scan});

  final FolderScanResult scan;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;
    final first = p.basename(scan.segments.first.path);
    final last = p.basename(scan.segments.last.path);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InfoRow(
            icon: Icons.movie_filter_rounded,
            label: l10n.mergeSegmentsFound(scan.segments.length),
          ),
          _InfoRow(
            icon: Icons.data_usage_rounded,
            label: l10n.mergeTotalSize(formatBytes(scan.totalBytes)),
          ),
          const SizedBox(height: 4),
          Text(
            scan.segments.length > 1 ? '$first … $last' : first,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.outline),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.outline),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final FolderMergeResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scheme = Theme.of(context).colorScheme;

    if (!result.success) {
      return Card(
        color: scheme.errorContainer,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.error_outline_rounded, color: scheme.error),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorText(result, l10n),
                  style: TextStyle(color: scheme.onErrorContainer),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final output = result.outputFile!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.green),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    output.path,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            if (result.downgradedToTs) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      size: 18, color: scheme.tertiary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.mergeMobileTsHint,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.tertiary),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => OpenFilex.open(output.path),
                icon: const Icon(Icons.open_in_new_rounded, size: 18),
                label: Text(l10n.mergeOpenOutput),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _errorText(FolderMergeResult result, AppLocalizations l10n) =>
      switch (result.error) {
        FolderMergeError.noTsFiles => l10n.mergeNoTsFiles,
        FolderMergeError.folderUnreadable => l10n.mergeFolderUnreadable,
        FolderMergeError.segmentMissing =>
          l10n.mergeSegmentMissing(result.errorMessage ?? ''),
        FolderMergeError.writeFailed || null =>
          l10n.mergeFailed(result.errorMessage ?? ''),
      };
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 4),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
