import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/download_engine.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';
import 'package:stream_mediary/engine/net/segment_downloader.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

import 'in_memory_task_store.dart';

/// Regression suite for "download freezes": a stalled server (accepts the
/// request, then stops sending) must never hang a segment job forever, and
/// pausing must cancel an in-flight key fetch so its scheduler slot frees.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('stall_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('stalled segment server fails within the receive timeout', () async {
    // Sends headers and a few bytes, then hangs without closing.
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = server.listen((request) async {
      request.response.headers.set('Content-Type', 'video/mp2t');
      request.response.add([1, 2, 3]);
      await request.response.flush();
      // Never close: the body stalls mid-stream.
    });
    // Shorten the production timeouts so the test does not wait ~13s of
    // retries; the code path under test is identical.
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            options.connectTimeout = const Duration(milliseconds: 300);
            options.receiveTimeout = const Duration(milliseconds: 300);
            handler.next(options);
          },
        ),
      );
    try {
      final target = File('${tempDir.path}/seg.ts');
      final stopwatch = Stopwatch()..start();
      final result = await SegmentDownloader(dio: dio).download(
        'http://127.0.0.1:${server.port}/seg0.ts',
        targetFile: target,
      );
      stopwatch.stop();
      // Before the fix the receive timeout was 5 minutes and a stalled
      // body hung the job (and its scheduler slot) essentially forever.
      expect(result.success, isFalse);
      expect(stopwatch.elapsed, lessThan(const Duration(seconds: 25)));
      // Neither the target nor a corrupt .part may survive.
      expect(target.existsSync(), isFalse);
      expect(File('${target.path}.part').existsSync(), isFalse);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
    }
  });

  test('pause cancels an in-flight key fetch', () async {
    final keyRequested = Completer<void>();
    // Captured from the key request so we can assert which CancelToken the
    // engine actually attached. The fix routes the per-segment job token
    // here; before, it used the runtime token that pause never cancels.
    CancelToken? keyToken;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final base = 'http://127.0.0.1:${server.port}';
    final subscription = server.listen((request) async {
      final path = request.uri.path;
      if (path == '/index.m3u8') {
        request.response
          ..statusCode = 200
          ..write(
            '#EXTM3U\n'
            '#EXT-X-KEY:METHOD=AES-128,URI="key.bin"\n'
            '#EXTINF:2.0,\n'
            'seg0.ts\n'
            '#EXT-X-ENDLIST\n',
          );
      } else if (path == '/seg0.ts') {
        request.response
          ..statusCode = 200
          ..add(List.filled(32, 7));
      } else if (path == '/key.bin') {
        if (!keyRequested.isCompleted) keyRequested.complete();
        // Dribble bytes so the client's receiveTimeout never fires; the only
        // way this request ends is the client aborting it (pause).
        unawaited(() async {
          try {
            while (true) {
              request.response.add([0]);
              await request.response.flush();
              await Future<void>.delayed(const Duration(milliseconds: 200));
            }
          } catch (_) {
            // Client disconnected.
          }
        }());
        return;
      }
      await request.response.close();
    });

    // Inject a Dio that records the CancelToken used for the key request.
    final dio = Dio()
      ..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            if (options.path.endsWith('/key.bin')) {
              keyToken = options.cancelToken;
            }
            handler.next(options);
          },
        ),
      );

    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false, segmentConcurrency: 1),
      defaultSaveDir: tempDir.path,
      dio: dio,
    );
    try {
      final media = (await engine.parseForPreview(
        '$base/index.m3u8',
      ) as MediaParseResult).media;
      await engine.startTask(
        id: 'k1',
        request: DownloadRequest(url: '$base/index.m3u8'),
        playlist: media,
      );

      // The segment downloads, then the job blocks fetching the AES key.
      await keyRequested.future.timeout(const Duration(seconds: 10));
      expect(keyToken, isNotNull, reason: 'key request must carry a token');
      expect(keyToken!.isCancelled, isFalse);

      await engine.pauseTask('k1');

      // The job token must now be cancelled, which aborts the hung key fetch
      // and frees its scheduler slot. Before the fix this stayed false and
      // the connection hung forever, freezing the task.
      expect(keyToken!.isCancelled, isTrue);

      final paused = await store.loadTask('k1');
      expect(paused!.state, TaskState.paused);
    } finally {
      await engine.dispose();
      await subscription.cancel();
      await server.close(force: true);
    }
  });
}
