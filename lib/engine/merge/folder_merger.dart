/// Standalone folder-based TS segment merger.
///
/// Scans a user-chosen folder for `.ts` segment files, concatenates them in
/// natural order into a single video file, and (on desktop platforms where
/// ffmpeg is available) remuxes the result into `.mp4`. Mobile platforms
/// without ffmpeg keep the merged `.ts` output and report a downgrade.
library;

import 'dart:io';

import 'package:path/path.dart' as p;

import 'ffmpeg_remuxer.dart';
import 'ts_merger.dart';

/// Failure categories surfaced to the UI.
enum FolderMergeError {
  /// Folder does not exist or cannot be listed.
  folderUnreadable,

  /// Folder contains no `.ts` files.
  noTsFiles,

  /// A segment file disappeared mid-merge.
  segmentMissing,

  /// The output file could not be written (permissions, disk full).
  writeFailed,
}

/// Merge stages, so the UI can switch progress indicator styles.
enum FolderMergePhase { concatenating, remuxing }

/// Result of scanning a folder for segments.
class FolderScanResult {
  const FolderScanResult({
    required this.segments,
    required this.totalBytes,
    this.error,
  });

  /// `.ts` files in natural order.
  final List<File> segments;

  final int totalBytes;

  /// Non-null when the folder could not be read.
  final FolderMergeError? error;

  bool get isEmpty => segments.isEmpty;
}

/// Result of a folder merge operation.
class FolderMergeResult {
  const FolderMergeResult({
    this.outputFile,
    this.downgradedToTs = false,
    this.segmentCount = 0,
    this.totalBytes = 0,
    this.error,
    this.errorMessage,
  });

  /// Merged output file on success.
  final File? outputFile;

  /// True when MP4 was requested but a `.ts` was produced instead
  /// (mobile platform, or ffmpeg missing/remux failed on desktop).
  final bool downgradedToTs;

  final int segmentCount;
  final int totalBytes;

  /// Non-null on failure.
  final FolderMergeError? error;

  /// Underlying exception message, for inclusion in user-facing errors.
  final String? errorMessage;

  bool get success => error == null && outputFile != null;
}

/// Orchestrates scan -> concatenate -> (optional) remux for a folder of
/// TS segments.
class FolderMerger {
  const FolderMerger({
    this.tsMerger = const TsMerger(),
    this.remuxer = const FfmpegRemuxer(),
  });

  final TsMerger tsMerger;
  final FfmpegRemuxer remuxer;

  /// Scans the top level of [folder] (no recursion) for `.ts` files.
  ///
  /// Files are returned in natural order (1, 2, 10 — not 1, 10, 2).
  ///
  /// A file named `<folder>.ts` or `<folder>_merged.ts` is treated as the
  /// output of a previous merge — and excluded — when its size equals the
  /// sum of the other segments (concatenation is byte-exact, so this is a
  /// reliable signal). A genuine segment that happens to share the folder
  /// name is kept when the sizes differ.
  Future<FolderScanResult> scan(Directory folder) async {
    if (!folder.existsSync()) {
      return const FolderScanResult(
        segments: [],
        totalBytes: 0,
        error: FolderMergeError.folderUnreadable,
      );
    }

    final folderBase = p.basename(folder.path);
    final List<FileSystemEntity> entries;
    try {
      entries = await folder.list().toList();
    } on FileSystemException {
      return const FolderScanResult(
        segments: [],
        totalBytes: 0,
        error: FolderMergeError.folderUnreadable,
      );
    }

    final tsFiles = entries
        .whereType<File>()
        .where((f) => f.path.toLowerCase().endsWith('.ts'))
        .toList();

    final segments = _excludePreviousOutputs(tsFiles, folderBase);
    segments.sort((a, b) {
      final r = naturalCompare(
        p.basenameWithoutExtension(a.path),
        p.basenameWithoutExtension(b.path),
      );
      return r != 0 ? r : a.path.compareTo(b.path);
    });

    var totalBytes = 0;
    for (final f in segments) {
      totalBytes += _sizeOf(f);
    }

    return FolderScanResult(segments: segments, totalBytes: totalBytes);
  }

  /// Filters out files that look like a previous merge output: named after
  /// the folder (with or without the `_merged` suffix) and exactly as large
  /// as the sum of all other segments.
  List<File> _excludePreviousOutputs(List<File> tsFiles, String folderBase) {
    final outputNames = {folderBase, '${folderBase}_merged'};
    bool isOutputName(File f) =>
        outputNames.contains(p.basenameWithoutExtension(f.path));

    final candidates = tsFiles.where(isOutputName).toList();
    if (candidates.isEmpty) return List.of(tsFiles);

    final othersSize = tsFiles
        .where((f) => !isOutputName(f))
        .fold<int>(0, (sum, f) => sum + _sizeOf(f));

    final excluded = <String>{
      for (final c in candidates)
        if (_sizeOf(c) == othersSize) c.path,
    };
    return tsFiles.where((f) => !excluded.contains(f.path)).toList();
  }

  /// Merges all `.ts` files in [folder] into a single video file placed
  /// inside the same folder, named after the folder.
  ///
  /// When [preferMp4] is true, desktop platforms remux the concatenated
  /// `.ts` into `.mp4` via ffmpeg; a failed remux degrades to keeping the
  /// `.ts` (never an error). Mobile platforms always degrade because no
  /// ffmpeg binary is available there.
  Future<FolderMergeResult> mergeFolder(
    Directory folder, {
    required bool preferMp4,
    String? ffmpegPath,
    MergeProgressCallback? onProgress,
    void Function(FolderMergePhase phase)? onPhaseChanged,
  }) async {
    final scan = await this.scan(folder);
    if (scan.error != null) {
      return FolderMergeResult(
        error: scan.error,
        segmentCount: scan.segments.length,
        totalBytes: scan.totalBytes,
      );
    }
    if (scan.isEmpty) {
      return const FolderMergeResult(error: FolderMergeError.noTsFiles);
    }

    final base = outputBaseName(folder, scan.segments);
    final tsOutput = File(p.join(folder.path, '$base.ts'));

    onPhaseChanged?.call(FolderMergePhase.concatenating);
    try {
      await tsMerger.merge(
        scan.segments,
        outputFile: tsOutput,
        onProgress: onProgress,
      );
    } on FileSystemException catch (e) {
      await _deleteQuietly(tsOutput);
      final missing = e.path != null && e.path != tsOutput.path;
      return FolderMergeResult(
        error: missing
            ? FolderMergeError.segmentMissing
            : FolderMergeError.writeFailed,
        errorMessage: e.message,
        segmentCount: scan.segments.length,
        totalBytes: scan.totalBytes,
      );
    }

    var output = tsOutput;
    var downgraded = false;

    if (preferMp4) {
      if (Platform.isAndroid || Platform.isIOS) {
        // No ffmpeg CLI on mobile; the merged .ts is the final output.
        downgraded = true;
      } else {
        onPhaseChanged?.call(FolderMergePhase.remuxing);
        final mp4 =
            await remuxer.remuxToMp4(tsOutput, ffmpegPath: ffmpegPath);
        if (mp4 != null) {
          output = mp4;
          await _deleteQuietly(tsOutput);
        } else {
          // ffmpeg missing or remux failed: keep the .ts, same policy as
          // the download engine.
          downgraded = true;
        }
      }
    }

    return FolderMergeResult(
      outputFile: output,
      downgradedToTs: downgraded,
      segmentCount: scan.segments.length,
      totalBytes: scan.totalBytes,
    );
  }

  /// Output base name: the folder name, with a `_merged` suffix (then a
  /// counter) when segment files already occupy those names.
  static String outputBaseName(Directory folder, List<File> segments) {
    final base = p.basename(folder.path);
    final taken = segments
        .map((f) => p.basenameWithoutExtension(f.path))
        .toSet();
    if (!taken.contains(base)) return base;
    var candidate = '${base}_merged';
    var i = 2;
    while (taken.contains(candidate)) {
      candidate = '${base}_merged$i';
      i++;
    }
    return candidate;
  }

  /// Natural-order comparison: embedded digit runs compare numerically
  /// (so `2` < `10`), other characters compare case-insensitively, and
  /// digits sort before letters.
  static int naturalCompare(String a, String b) {
    var ia = 0;
    var ib = 0;
    while (ia < a.length && ib < b.length) {
      final ca = a.codeUnitAt(ia);
      final cb = b.codeUnitAt(ib);
      final aDigit = _isDigit(ca);
      final bDigit = _isDigit(cb);

      if (aDigit && bDigit) {
        // Extract full digit runs.
        var ea = ia;
        while (ea < a.length && _isDigit(a.codeUnitAt(ea))) {
          ea++;
        }
        var eb = ib;
        while (eb < b.length && _isDigit(b.codeUnitAt(eb))) {
          eb++;
        }
        // Strip leading zeros, then compare by length and digits. This
        // avoids int overflow for arbitrarily long numbers.
        var sa = ia;
        while (sa < ea - 1 && a.codeUnitAt(sa) == 0x30) {
          sa++;
        }
        var sb = ib;
        while (sb < eb - 1 && b.codeUnitAt(sb) == 0x30) {
          sb++;
        }
        final la = ea - sa;
        final lb = eb - sb;
        if (la != lb) return la - lb;
        for (var k = 0; k < la; k++) {
          final d = a.codeUnitAt(sa + k).compareTo(b.codeUnitAt(sb + k));
          if (d != 0) return d;
        }
        // Same value (e.g. `01` vs `1`): fewer leading zeros first, so
        // the ordering stays deterministic.
        final za = sa - ia;
        final zb = sb - ib;
        if (za != zb) return za - zb;
        ia = ea;
        ib = eb;
      } else {
        if (aDigit != bDigit) return aDigit ? -1 : 1;
        final la = _lower(ca);
        final lb = _lower(cb);
        if (la != lb) return la - lb;
        ia++;
        ib++;
      }
    }
    // Shorter remaining input sorts first (prefix rule).
    return (a.length - ia) - (b.length - ib);
  }

  static bool _isDigit(int c) => c >= 0x30 && c <= 0x39;

  static int _lower(int c) => (c >= 0x41 && c <= 0x5A) ? c + 32 : c;

  static int _sizeOf(File f) {
    try {
      return f.lengthSync();
    } on FileSystemException {
      return 0;
    }
  }

  static Future<void> _deleteQuietly(File file) async {
    try {
      if (file.existsSync()) await file.delete();
    } on FileSystemException {
      // Ignore cleanup failures.
    }
  }
}
