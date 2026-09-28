import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/download_engine.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/engine_events.dart';
import 'package:stream_mediary/engine/engine_store.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

import 'in_memory_task_store.dart';

/// Serves segments behind a rotating signature so stale URLs 403, mimicking
/// a PNG-disguised source whose signed links expire while paused. Each
/// segment response is delayed so a pause reliably lands mid-download.
class _SignedServer {
  HttpServer? _server;
  late String baseUrl;

  /// The only signature currently accepted; bumping it invalidates old URLs.
  String validSig = 'sig1';
  final Map<int, List<int>> segments = {};
  Duration segmentDelay = const Duration(milliseconds: 120);

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${_server!.port}';
    _server!.listen((request) async {
      final path = request.uri.path;
      final sig = request.uri.queryParameters['sig'];
      if (path == '/index.m3u8') {
        // The playlist always reflects the current signature.
        final lines = <String>['#EXTM3U', '#EXT-X-TARGETDURATION:2'];
        for (final i in segments.keys.toList()..sort()) {
          lines.add('#EXTINF:2.0,');
          lines.add('seg$i.ts?sig=$validSig');
        }
        lines.add('#EXT-X-ENDLIST');
        request.response
          ..statusCode = 200
          ..write(lines.join('\n'));
      } else if (path.startsWith('/seg')) {
        final idx = int.parse(
          path.substring('/seg'.length).replaceAll('.ts', ''),
        );
        if (sig != validSig) {
          request.response.statusCode = 403;
        } else {
          await Future<void>.delayed(segmentDelay);
          request.response
            ..statusCode = 200
            ..add(segments[idx] ?? const []);
        }
      } else {
        request.response.statusCode = 404;
      }
      await request.response.close();
    });
  }

  Future<void> stop() => _server?.close(force: true) ?? Future.value();
}

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('engine_fix_');
  });

  tearDown(() async {
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('pause persists live progress instead of resetting it to zero', () async {
    final server = _SignedServer();
    for (var i = 0; i < 40; i++) {
      server.segments[i] = List.filled(64, i % 256);
    }
    await server.start();
    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false, segmentConcurrency: 2),
      defaultSaveDir: tempDir.path,
    );
    try {
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult).media;
      await engine.startTask(
        id: 'p1',
        request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
        playlist: media,
      );

      // Wait until some progress has been made.
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      var record = await store.loadTask('p1');
      while (DateTime.now().isBefore(deadline) &&
          (record == null || record.doneSegments == 0)) {
        await Future<void>.delayed(const Duration(milliseconds: 30));
        record = await store.loadTask('p1');
      }
      expect(record!.doneSegments, greaterThan(0));

      await engine.pauseTask('p1');
      final paused = await store.loadTask('p1');
      expect(paused!.state, TaskState.paused);
      // The regression: pause used to reload a stale record and write zeros.
      expect(paused.doneSegments, greaterThan(0));
      expect(paused.downloadedBytes, greaterThan(0));
    } finally {
      await engine.dispose();
      await server.stop();
    }
  });

  test('resume refreshes expired signed URLs and completes', () async {
    final server = _SignedServer();
    for (var i = 0; i < 8; i++) {
      server.segments[i] = List.filled(16, i + 1);
    }
    await server.start();
    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false, segmentConcurrency: 1),
      defaultSaveDir: tempDir.path,
    );
    try {
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult).media;
      await engine.startTask(
        id: 'r1',
        request: DownloadRequest(
          url: '${server.baseUrl}/index.m3u8',
          sourceUrl: '${server.baseUrl}/index.m3u8',
        ),
        playlist: media,
      );

      // Pause only after real progress so the task cannot finish first.
      final deadline = DateTime.now().add(const Duration(seconds: 15));
      var record = await store.loadTask('r1');
      while (DateTime.now().isBefore(deadline) &&
          (record == null || record.doneSegments == 0)) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        record = await store.loadTask('r1');
      }
      await engine.pauseTask('r1');

      // Rotate the signature: every URL captured before the pause is stale.
      server.validSig = 'sig2';

      final completed = engine.events
          .where((e) => e is TaskCompletedEvent && e.taskId == 'r1')
          .cast<TaskCompletedEvent>()
          .first
          .timeout(const Duration(seconds: 25));
      await engine.resumeTask('r1');
      final done = await completed;

      final bytes = await File(done.outputPath).readAsBytes();
      final expected = <int>[];
      for (var i = 0; i < 8; i++) {
        expected.addAll(List.filled(16, i + 1));
      }
      expect(bytes, expected);
    } finally {
      await engine.dispose();
      await server.stop();
    }
  });

  test('retry refreshes expired signed URLs and completes', () async {
    final server = _SignedServer();
    for (var i = 0; i < 3; i++) {
      server.segments[i] = List.filled(8, i + 1);
    }
    await server.start();
    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false, segmentConcurrency: 1),
      defaultSaveDir: tempDir.path,
    );
    try {
      // Seed a failed task whose snapshot holds an expired signature, exactly
      // the state a disguised download lands in after its links rot.
      final stale = MediaPlaylist(
        segments: [
          for (var i = 0; i < 3; i++)
            Segment(
              seq: i,
              url: '${server.baseUrl}/seg$i.ts?sig=expired',
              duration: 2,
            ),
        ],
        totalDuration: 6,
        mediaSequence: 0,
      );
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(
        EngineTaskRecord(
          id: 'f1',
          url: '${server.baseUrl}/index.m3u8',
          sourceUrl: '${server.baseUrl}/index.m3u8',
          title: 'clip',
          state: TaskState.failed,
          saveDir: tempDir.path,
          playlistSnapshot: jsonEncode(stale.toJson()),
          totalSegments: 3,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await store.saveSegments([
        for (var i = 0; i < 3; i++)
          EngineSegmentRecord(
            taskId: 'f1',
            seq: i,
            url: '${server.baseUrl}/seg$i.ts?sig=expired',
          ),
      ]);

      final completed = engine.events
          .where((e) => e is TaskCompletedEvent && e.taskId == 'f1')
          .cast<TaskCompletedEvent>()
          .first
          .timeout(const Duration(seconds: 25));
      await engine.retryTask('f1');
      final done = await completed;

      final bytes = await File(done.outputPath).readAsBytes();
      final expected = <int>[];
      for (var i = 0; i < 3; i++) {
        expected.addAll(List.filled(8, i + 1));
      }
      expect(bytes, expected);
    } finally {
      await engine.dispose();
      await server.stop();
    }
  });
}
