/// Streaming TS segment merger.
///
/// Concatenates downloaded segment files in sequence order into a single
/// playable `.ts` file using a fixed-size buffer, so memory usage stays
/// constant regardless of total size.
///
/// Self-healing: a segment that disappears or becomes unreadable mid-merge
/// is skipped (reported via [MergeOptions.onSegmentSkipped]) instead of
/// aborting the whole merge. TS is a streamable container, so the output
/// stays playable with a small gap where the corrupt segment was.
library;

import 'dart:io';

import '../disk_space.dart';

/// Progress callback: [writtenBytes] of [totalBytes].
typedef MergeProgressCallback = void Function(
    int writtenBytes, int totalBytes);

/// Called with the path of each segment skipped by the self-healing merge.
typedef SegmentSkippedCallback = void Function(String path);

class TsMerger {
  const TsMerger({this.bufferSize = 1024 * 1024});

  /// Copy buffer size (default 1 MB).
  final int bufferSize;

  /// Merges [segmentFiles] (in order) into [outputFile].
  ///
  /// Segments missing at the pre-flight check abort the merge with a
  /// [FileSystemException]. Segments that fail *while being read* (deleted
  /// or corrupted mid-merge) are skipped and reported through
  /// [onSegmentSkipped]; the merge only throws when the output itself
  /// cannot be written.
  Future<File> merge(
    List<File> segmentFiles, {
    required File outputFile,
    MergeProgressCallback? onProgress,
    SegmentSkippedCallback? onSegmentSkipped,
  }) async {
    final totalBytes = segmentFiles.fold<int>(
        0, (sum, f) => sum + (f.existsSync() ? f.lengthSync() : 0));

    for (final f in segmentFiles) {
      if (!f.existsSync()) {
        throw FileSystemException('Segment file missing', f.path);
      }
    }

    await outputFile.parent.create(recursive: true);
    final sink = outputFile.openWrite();
    var written = 0;

    try {
      for (final segment in segmentFiles) {
        try {
          final input = segment.openRead();
          await for (final chunk in input) {
            sink.add(chunk);
            written += chunk.length;
            onProgress?.call(written, totalBytes);
          }
        } on FileSystemException catch (e) {
          // A full disk must abort the merge, not be mistaken for a vanished
          // segment: skipping it would silently truncate the output.
          if (isDiskFull(e)) rethrow;
          // Unreadable/vanished mid-merge: skip it and keep going. The
          // partially written bytes of this segment stay in the output —
          // for TS this is at worst a small glitch, far better than losing
          // the whole merge.
          onSegmentSkipped?.call(segment.path);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    return outputFile;
  }
}
