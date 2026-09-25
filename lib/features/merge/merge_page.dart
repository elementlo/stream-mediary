import 'dart:io';

import 'package:file_selector/file_selector.dart' as file_selector;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path/path.dart' as p;

import '../../core/l10n/app_localizations.dart';
import '../../core/platform/platform_profile.dart';
import '../../core/theme/design_tokens.dart';
import '../../core/theme/mediary_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/user_error.dart';
import '../../core/utils/storage_access.dart';
import '../../core/widgets/mediary_card.dart';
import '../../core/widgets/mediary_scaffold.dart';
import '../../core/widgets/section_header.dart';
import '../../core/widgets/stat_tile.dart';
import '../../engine/merge/folder_merger.dart';
import '../../providers/app_providers.dart';

/// Folder merger used by this page. Overridable in tests.
final folderMergerProvider = Provider<FolderMerger>(
  (ref) => const FolderMerger(),
);

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
      messenger.showSnackBar(SnackBar(content: Text(l10n.mergeNoTsFiles)));
    }
  }

  Future<void> _startMerge() async {
    final folderPath = _folderPath;
    if (folderPath == null) return;

    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final ffmpegPath = await ref.read(settingsRepositoryProvider).ffmpegPath();
    if (!mounted) return;

    setState(() {
      _merging = true;
      _progress = 0;
      _written = 0;
      _total = 0;
      _result = null;
      _phase = FolderMergePhase.concatenating;
    });

    final result = await ref
        .read(folderMergerProvider)
        .mergeFolder(
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

    if (result.error != null) {
      logUserError(
        'Merge video folder',
        StateError('${result.error}: ${result.errorMessage ?? ''}'),
        StackTrace.current,
      );
    }

    if (!mounted) return;
    setState(() {
      _merging = false;
      _result = result;
      _progress = 1;
    });
    messenger.showSnackBar(SnackBar(content: Text(_messageFor(result, l10n))));
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
      FolderMergeError.segmentMissing => l10n.errorMergeSegmentMissing,
      FolderMergeError.writeFailed || null => l10n.errorMergeFailed,
    };
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final scan = _scan;
    final canMerge =
        _folderPath != null &&
        scan != null &&
        !scan.isEmpty &&
        scan.error == null &&
        !_merging;

    return MediaryScaffold(
      title: l10n.navMerge,
      maxWidth: Breakpoints.contentForm,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          SectionHeader(l10n.mergeFolderSection),
          MediaryCard(
            padding: EdgeInsets.zero,
            onTap: _merging ? null : _chooseFolder,
            child: _FolderRow(path: _folderPath, label: l10n.mergeChooseFolder),
          ),
          if (_scanning) ...[
            const SizedBox(height: Spacing.md),
            const ClipRRect(
              borderRadius: Radii.smAll,
              child: LinearProgressIndicator(),
            ),
          ],
          if (scan != null && !_scanning && scan.error == null) ...[
            SectionHeader(l10n.mergePreview),
            MediaryCard(child: _ScanSummary(scan: scan)),
          ],
          SectionHeader(l10n.mergePreference),
          MediaryCard(
            child: SegmentedButton<bool>(
              segments: [
                ButtonSegment(value: false, label: Text(l10n.mergeTsOnly)),
                ButtonSegment(value: true, label: Text(l10n.mergePreferMp4)),
              ],
              selected: {_preferMp4},
              showSelectedIcon: false,
              onSelectionChanged: _merging
                  ? null
                  : (sel) => setState(() => _preferMp4 = sel.first),
            ),
          ),
          const SizedBox(height: Spacing.xl),
          FilledButton.icon(
            onPressed: canMerge ? _startMerge : null,
            icon: _merging
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.call_merge_rounded, size: 18),
            label: Text(_merging ? l10n.mergeInProgress : l10n.mergeStart),
          ),
          if (_merging) ...[
            const SizedBox(height: Spacing.lg),
            _MergeProgress(
              phase: _phase,
              progress: _progress,
              written: _written,
              total: _total,
              label: l10n.mergeRemuxing,
            ),
          ],
          if (_result != null) ...[
            const SizedBox(height: Spacing.lg),
            _ResultCard(result: _result!),
          ],
        ],
      ),
    );
  }
}

class _FolderRow extends StatelessWidget {
  const _FolderRow({required this.path, required this.label});

  final String? path;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final profile = context.platformProfile;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: profile.isDesktop ? Spacing.xl : Spacing.lg,
        vertical: Spacing.md + 2,
      ),
      child: Row(
        children: [
          Icon(Icons.folder_rounded, size: 19, color: scheme.onSurfaceVariant),
          const SizedBox(width: Spacing.md),
          Expanded(
            child: Text(
              path ?? label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: path == null
                  ? text.bodyLarge?.copyWith(color: scheme.onSurfaceVariant)
                  : text.bodyLarge,
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            size: 18,
            color: scheme.onSurfaceVariant,
          ),
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
    final text = Theme.of(context).textTheme;
    final first = p.basename(scan.segments.first.path);
    final last = p.basename(scan.segments.last.path);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        StatGrid(
          maxColumns: 2,
          children: [
            StatTile(
              label: l10n.segmentsCountLabel,
              value: '${scan.segments.length}',
              icon: Icons.view_module_rounded,
            ),
            StatTile(
              label: l10n.totalSizeLabel,
              value: formatBytes(scan.totalBytes),
              icon: Icons.data_usage_rounded,
            ),
          ],
        ),
        const SizedBox(height: Spacing.md),
        Row(
          children: [
            Icon(
              Icons.playlist_play_rounded,
              size: 14,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: Spacing.xs + 2),
            Expanded(
              child: Text(
                scan.segments.length > 1 ? '$first … $last' : first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// Merge progress. Concatenation reports byte progress; the remux phase is
/// indeterminate because ffmpeg does not emit parseable progress here.
class _MergeProgress extends StatelessWidget {
  const _MergeProgress({
    required this.phase,
    required this.progress,
    required this.written,
    required this.total,
    required this.label,
  });

  final FolderMergePhase phase;
  final double progress;
  final int written;
  final int total;
  final String label;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;

    if (phase != FolderMergePhase.concatenating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ClipRRect(
            borderRadius: Radii.smAll,
            child: LinearProgressIndicator(),
          ),
          const SizedBox(height: Spacing.sm),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: Radii.smAll,
          child: LinearProgressIndicator(
            value: progress,
            color: colors.doneSegment,
          ),
        ),
        const SizedBox(height: Spacing.sm),
        Row(
          children: [
            Text(
              '${(progress * 100).toStringAsFixed(0)}%',
              style: text.bodySmall?.copyWith(
                color: colors.doneSegment,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Text(
              '${formatBytes(written)} / ${formatBytes(total)}',
              style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({required this.result});

  final FolderMergeResult result;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;
    final colors = context.mediaryColors;

    if (!result.success) {
      return MediaryCard(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.danger.withValues(alpha: 0.12),
                borderRadius: Radii.smAll,
              ),
              child: Icon(
                Icons.error_outline_rounded,
                size: 17,
                color: colors.danger,
              ),
            ),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Text(
                _errorText(result, l10n),
                style: text.bodyMedium?.copyWith(color: colors.danger),
              ),
            ),
          ],
        ),
      );
    }

    final output = result.outputFile!;
    return MediaryCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.success.withValues(alpha: 0.12),
                  borderRadius: Radii.smAll,
                ),
                child: Icon(
                  Icons.check_rounded,
                  size: 17,
                  color: colors.success,
                ),
              ),
              const SizedBox(width: Spacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      output.uri.pathSegments.last,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleMedium,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      output.path,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontFamily: 'monospace',
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (result.downgradedToTs) ...[
            const SizedBox(height: Spacing.md),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 15,
                  color: colors.warning,
                ),
                const SizedBox(width: Spacing.sm - 2),
                Expanded(
                  child: Text(
                    l10n.mergeMobileTsHint,
                    style: text.bodySmall?.copyWith(color: colors.warning),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: Spacing.md),
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => OpenFilex.open(output.path),
                icon: const Icon(Icons.open_in_new_rounded, size: 16),
                label: Text(l10n.mergeOpenOutput),
                style: OutlinedButton.styleFrom(minimumSize: const Size(0, 36)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _errorText(FolderMergeResult result, AppLocalizations l10n) =>
      switch (result.error) {
        FolderMergeError.noTsFiles => l10n.mergeNoTsFiles,
        FolderMergeError.folderUnreadable => l10n.mergeFolderUnreadable,
        FolderMergeError.segmentMissing => l10n.errorMergeSegmentMissing,
        FolderMergeError.writeFailed || null => l10n.errorMergeFailed,
      };
}
