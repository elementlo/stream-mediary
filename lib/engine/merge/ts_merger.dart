/// Streaming TS segment merger.
///
/// Concatenates downloaded segment files in sequence order into a single
/// playable `.ts` file using a fixed-size buffer, so memory usage stays
/// constant regardless of total size.
library;

import 'dart:io';

/// Progress callback: [writtenBytes] of [totalBytes].
typedef MergeProgressCallback = void Function(
    int writtenBytes, int totalBytes);

class TsMerger {
  const TsMerger({this.bufferSize = 1024 * 1024});

  /// Copy buffer size (default 1 MB).
  final int bufferSize;

  /// Merges [segmentFiles] (in order) into [outputFile].
  ///
  /// Returns the output file. Throws [FileSystemException] when a segment
  /// file is missing.
  Future<File> merge(
    List<File> segmentFiles, {
    required File outputFile,
    MergeProgressCallback? onProgress,
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
        final input = segment.openRead();
        await for (final chunk in input) {
          sink.add(chunk);
          written += chunk.length;
          onProgress?.call(written, totalBytes);
        }
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    return outputFile;
  }
}
