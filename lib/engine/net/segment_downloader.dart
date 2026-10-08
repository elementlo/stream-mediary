/// Segment downloader built on dio streaming responses.
///
/// Downloads a single segment to a `.part` temp file and atomically renames
/// it on completion. Supports custom headers, cancellation and exponential
/// backoff retries.
library;

import 'dart:io';
import 'dart:isolate';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../disk_space.dart';
import '../m3u8/playlist.dart';
import 'roud_decoder.dart';

final Logger _log = Logger('SegmentDownloader');

/// Result of a segment download attempt.
class SegmentDownloadResult {
  const SegmentDownloadResult({
    required this.success,
    this.bytes = 0,
    this.error,
    this.congested = false,
    this.diskFull = false,
  });

  final bool success;
  final int bytes;
  final String? error;

  /// True when the failure signals server/network congestion (timeouts,
  /// connection errors, 429/5xx) rather than a permanent problem. Consumers
  /// use it to throttle adaptive concurrency.
  final bool congested;

  /// True when the write failed because the disk is full. This is not
  /// retryable and not congestion: the caller pauses the task so the user
  /// can free space and resume.
  final bool diskFull;
}

/// HTTP statuses that will not change by retrying: fail fast instead of
/// burning three backoff rounds on a dead or forbidden URL.
const Set<int> _permanentStatuses = {400, 401, 403, 404, 410};

/// HTTP statuses that indicate the server is overloaded or rate-limiting.
const Set<int> _congestionStatuses = {429, 500, 502, 503, 504};

class SegmentDownloader {
  SegmentDownloader({Dio? dio}) : _dio = dio ?? Dio();

  final Dio _dio;

  static const int maxRetries = 3;

  // Short first backoff: a transient blip should cost milliseconds, not
  // seconds. Later rounds grow to ride out longer server hiccups.
  static const List<Duration> _backoffs = [
    Duration(milliseconds: 300),
    Duration(seconds: 1),
    Duration(seconds: 3),
  ];

  /// Downloads [url] to [targetFile] (writing to a `.part` file first).
  ///
  /// [headers] are attached to the request. [cancelToken] aborts the
  /// transfer. [onCongestion] fires on every congestion-type failure
  /// (including retried attempts) so callers can adapt concurrency.
  /// Returns a [SegmentDownloadResult]; never throws for network
  /// errors (they are captured in the result).
  Future<SegmentDownloadResult> download(
    String url, {
    required File targetFile,
    Map<String, String> headers = const {},
    CancelToken? cancelToken,
    ByteRange? byteRange,
    void Function()? onCongestion,
  }) async {
    final partFile = File('${targetFile.path}.part');
    await targetFile.parent.create(recursive: true);
    // Byte ranges refer to the decoded media, not the outer PNG container.
    final localRange =
        byteRange != null &&
        Uri.tryParse(url)?.path.toLowerCase().endsWith('.png') == true;

    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await _dio.get<ResponseBody>(
          url,
          options: Options(
            responseType: ResponseType.stream,
            headers: {
              ...headers,
              if (byteRange != null && !localRange)
                'Range': 'bytes=${byteRange.offset}-${byteRange.end}',
            },
            followRedirects: true,
            // Bound both the TCP connect and the gap between body chunks so a
            // stalled server cannot hang a segment (and its scheduler slot)
            // forever. A hung slot is what makes a task appear frozen while
            // the last completed segment's speed still shows. The receive
            // timeout is an idle bound (reset on every chunk), so slow but
            // progressing connections are never cut off.
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 60),
          ),
          cancelToken: cancelToken,
        );

        if (byteRange != null && !localRange && response.statusCode != 206) {
          throw StateError('Server ignored the requested byte range');
        }
        if (byteRange != null && !localRange) {
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

        if (byteRange != null && !localRange && received != byteRange.length) {
          throw StateError(
            'Byte range length mismatch: $received of ${byteRange.length}',
          );
        }

        // PNG-wrapped resources must be decoded before AES and merge. The
        // roUd unwrap runs zlib decompression, which is CPU-bound: do it on
        // a worker isolate so the event loop keeps servicing the other
        // concurrent segment connections.
        final input = await partFile.open();
        final signature = await input.read(8);
        await input.close();
        if (isPng(signature)) {
          final path = partFile.path;
          final decoded = await Isolate.run(
            () => unwrapRoud(File(path).readAsBytesSync()),
          );
          if (localRange) {
            if (byteRange.end >= decoded.length) {
              throw const FormatException('Decoded byte range exceeds media');
            }
            await partFile.writeAsBytes(
              decoded.sublist(byteRange.offset, byteRange.end + 1),
              flush: true,
            );
            received = byteRange.length;
          } else {
            await partFile.writeAsBytes(decoded, flush: true);
            received = decoded.length;
          }
        } else if (localRange) {
          // A .png URL may actually return plain media; apply the range here.
          final data = await partFile.readAsBytes();
          if (byteRange.end >= data.length) {
            throw const FormatException('Byte range exceeds media');
          }
          await partFile.writeAsBytes(
            data.sublist(byteRange.offset, byteRange.end + 1),
            flush: true,
          );
          received = byteRange.length;
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

        final status = e.response?.statusCode;
        final congested =
            status == null || _congestionStatuses.contains(status);
        if (congested) onCongestion?.call();

        // Permanent client errors (403/404/…) will not heal by retrying;
        // fail immediately so the task surfaces the real problem instead of
        // burning backoff rounds.
        if (status != null && _permanentStatuses.contains(status)) {
          return SegmentDownloadResult(
            success: false,
            error: 'HTTP $status',
            congested: false,
          );
        }
        if (attempt < maxRetries) {
          await Future<void>.delayed(_backoffs[attempt]);
        } else {
          return SegmentDownloadResult(
            success: false,
            error: status == null
                ? (e.message ?? 'download failed')
                : 'HTTP $status',
            congested: congested,
          );
        }
      } catch (e) {
        await _cleanup(partFile);
        // A full disk is not retryable and not congestion: surface it so the
        // caller can pause the task instead of burning backoff rounds.
        if (isDiskFull(e)) {
          return SegmentDownloadResult(
            success: false,
            error: '$e',
            diskFull: true,
          );
        }
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
