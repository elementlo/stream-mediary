import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';
import 'package:stream_mediary/engine/net/segment_downloader.dart';

/// Regression suite for byte-range download validation: the downloader must
/// refuse servers that ignore the Range header, return a different range, or
/// deliver a truncated body — never writing a corrupt segment silently.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('range_dl');
  });

  tearDown(() async {
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// Serves [body] with the given behaviour for ranged requests.
  Future<HttpServer> startServer({
    required int status,
    String? contentRange,
    List<int>? body,
  }) async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      request.response.statusCode = status;
      if (contentRange != null) {
        request.response.headers.set(
          HttpHeaders.contentRangeHeader,
          contentRange,
        );
      }
      if (body != null) request.response.add(body);
      request.response.close();
    });
    return server;
  }

  test('accepts a correct 206 response', () async {
    final server = await startServer(
      status: 206,
      contentRange: 'bytes 10-19/100',
      body: List.filled(10, 7),
    );
    final downloader = SegmentDownloader();
    final target = File('${tempDir.path}/seg.ts');
    final result = await downloader.download(
      'http://127.0.0.1:${server.port}/seg',
      targetFile: target,
      byteRange: const ByteRange(10, 10),
    );
    expect(result.success, isTrue);
    expect(result.bytes, 10);
    expect(await target.readAsBytes(), List.filled(10, 7));
    await server.close(force: true);
  });

  test('fails when the server ignores the range (200)', () async {
    final server = await startServer(status: 200, body: List.filled(100, 1));
    final downloader = SegmentDownloader();
    final result = await downloader.download(
      'http://127.0.0.1:${server.port}/seg',
      targetFile: File('${tempDir.path}/seg.ts'),
      byteRange: const ByteRange(10, 10),
    );
    expect(result.success, isFalse);
    expect(result.error, contains('byte range'));
    await server.close(force: true);
  });

  test('fails when Content-Range does not match the request', () async {
    final server = await startServer(
      status: 206,
      contentRange: 'bytes 0-9/100', // requested 10-19
      body: List.filled(10, 3),
    );
    final downloader = SegmentDownloader();
    final result = await downloader.download(
      'http://127.0.0.1:${server.port}/seg',
      targetFile: File('${tempDir.path}/seg.ts'),
      byteRange: const ByteRange(10, 10),
    );
    expect(result.success, isFalse);
    expect(result.error, contains('different byte range'));
    await server.close(force: true);
  });

  test('fails when the body length does not match the range', () async {
    final server = await startServer(
      status: 206,
      contentRange: 'bytes 10-19/100',
      body: List.filled(6, 9), // truncated: 6 of 10 bytes
    );
    final downloader = SegmentDownloader();
    final result = await downloader.download(
      'http://127.0.0.1:${server.port}/seg',
      targetFile: File('${tempDir.path}/seg.ts'),
      byteRange: const ByteRange(10, 10),
    );
    expect(result.success, isFalse);
    expect(result.error, contains('length mismatch'));
    // The corrupt .part file must not be promoted to the target.
    expect(await File('${tempDir.path}/seg.ts').exists(), isFalse);
    await server.close(force: true);
  });

  test('plain download without a range still works', () async {
    final server = await startServer(status: 200, body: [1, 2, 3]);
    final downloader = SegmentDownloader();
    final target = File('${tempDir.path}/plain.ts');
    final result = await downloader.download(
      'http://127.0.0.1:${server.port}/seg',
      targetFile: target,
    );
    expect(result.success, isTrue);
    expect(await target.readAsBytes(), [1, 2, 3]);
    await server.close(force: true);
  });
}
