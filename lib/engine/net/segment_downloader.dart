/// Segment downloader built on dio streaming responses.
///
/// Downloads a single segment to a `.part` temp file and atomically renames
/// it on completion. Supports custom headers, cancellation and exponential
/// backoff retries.
library;

import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../m3u8/playlist.dart';

final Logger _log = Logger('SegmentDownloader');

/// Result of a segment download attempt.
class SegmentDownloadResult {
  const SegmentDownloadResult({
    required this.success,
    this.bytes = 0,
    this.error,
  });

  final bool success;
  final int bytes;
  final String? error;
}

class SegmentDownloader {
  SegmentDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const int maxRetries = 3;
  static const List<Duration> _backoffs = [
    Duration(seconds: 1),
    Duration(seconds: 3),
    Duration(seconds: 9),
  ];

  /// Downloads [url] to [targetFile] (writing to a `.part` file first).
  ///
  /// [headers] are attached to the request. [cancelToken] aborts the
  /// transfer. Returns a [SegmentDownloadResult]; never throws for network
  /// errors (they are captured in the result).
  Future<SegmentDownloadResult> download(
    String url, {
    required File targetFile,
    Map<String, String> headers = const {},
    CancelToken? cancelToken,
    ByteRange? byteRange,
  }) async {
    final partFile = File('${targetFile.path}.part');
    await targetFile.parent.create(recursive: true);

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              ...headers,
              if (byteRange != null)
                'Range': 'bytes=${byteRange.offset}-${byteRange.end}',
            },
            followRedirects: true,
            receiveTimeout: const Duration(minutes: 5),
          ),
          cancelToken: cancelToken,
        );

        if (byteRange != null && response.statusCode != 206) {
          throw StateError('Server ignored the requested byte range');
        }
        if (byteRange != null) {
          final contentRange = response.headers.value(
            HttpHeaders.contentRangeHeader,
          );
          final match = contentRange == null
              ? null
              : RegExp(r'^bytes (\d+)-(\d+)/(?:\d+|\*)$')
                    .firstMatch(contentRange);
          if (match == null ||
              int.parse(match.group(1)!) != byteRange.offset ||
              int.parse(match.group(2)!) != byteRange.end) {
            throw StateError('Server returned a different byte range');
          }
        }

        final body = response.data!;
        var received = 0;
        final sink = partFile.openWrite();
        try {
          await for (final chunk in body.stream) {
            sink.add(chunk);
            received += chunk.length;
          }
          await sink.flush();
        } finally {
          await sink.close();
        }

        if (byteRange != null && received != byteRange.length) {
          throw StateError(
            'Byte range length mismatch: $received of ${byteRange.length}',
          );
        }

        // Atomic rename into place.
        await partFile.rename(targetFile.path);
        return SegmentDownloadResult(success: true, bytes: received);
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          await _cleanup(partFile);
          return SegmentDownloadResult(success: false, error: 'canceled');
        }
        _log.warning('Segment attempt ${attempt + 1} failed: $url ($e)');
        await _cleanup(partFile);
        if (attempt < maxRetries) {
          await Future<void>.delayed(_backoffs[attempt]);
        } else {
          return SegmentDownloadResult(
            success: false,
            error: e.response?.statusCode == null
                ? (e.message ?? 'download failed')
                : 'HTTP ${e.response!.statusCode}',
          );
        }
      } catch (e) {
        await _cleanup(partFile);
        return SegmentDownloadResult(success: false, error: '$e');
      }
    }
    return const SegmentDownloadResult(success: false, error: 'unreachable');
  }

  Future<void> _cleanup(File file) async {
    if (await file.exists()) {
      try {
        await file.delete();
      } on FileSystemException {
        // Ignore cleanup failures.
      }
    }
  }
}
