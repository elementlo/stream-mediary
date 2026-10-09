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

/// Minimal localhost HLS server serving a fixed playlist and segments.
class _FakeHlsServer {
  HttpServer? _server;
  late String baseUrl;
  final Map<int, List<int>> segments = {};
  String playlist = '';

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    baseUrl = 'http://127.0.0.1:${_server!.port}';
    _server!.listen((request) {
      final path = request.uri.path;
      if (path == '/index.m3u8') {
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType(
            'application',
            'vnd.apple.mpegurl',
          )
          ..write(playlist);
      } else if (path.startsWith('/seg')) {
        final idx = int.parse(
          path.substring('/seg'.length).replaceAll('.ts', ''),
        );
        final data = segments[idx];
        if (data == null) {
          request.response.statusCode = 404;
        } else {
          request.response
            ..statusCode = 200
            ..add(data);
        }
      } else {
        request.response.statusCode = 404;
      }
      request.response.close();
    });
  }

  Future<void> stop() async => _server?.close(force: true);
}

void main() {
  late _FakeHlsServer server;
  late Directory tempDir;

  setUp(() async {
    server = _FakeHlsServer();
    tempDir = await Directory.systemTemp.createTemp('disk_full');
    final lines = <String>[
      '#EXTM3U',
      '#EXT-X-VERSION:3',
      '#EXT-X-TARGETDURATION:2',
    ];
    for (var i = 0; i < 3; i++) {
      server.segments[i] = List.generate(128, (b) => (i * 128 + b) % 256);
      lines
        ..add('#EXTINF:2.0,')
        ..add('seg$i.ts');
    }
    lines.add('#EXT-X-ENDLIST');
    server.playlist = lines.join('\n');
    await server.start();
  });

  tearDown(() async {
    await server.stop();
    if (await tempDir.exists()) await tempDir.delete(recursive: true);
  });

  test('merge pre-flight pauses the task with diskFull when space is short',
      () async {
    // Report almost no free space so the merge pre-flight trips.
    var freeBytes = 1024;
    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
      freeSpaceQuery: (_) async => freeBytes,
    );

    final media = (await engine.parseForPreview(
      '${server.baseUrl}/index.m3u8',
    ) as MediaParseResult).media;

    await engine.startTask(
      id: 'df-1',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );

    // The task should pause (not fail) with diskFull set.
    final paused = await engine.events
        .where((e) =>
            e is TaskStateChangedEvent &&
            e.taskId == 'df-1' &&
            e.state == TaskState.paused)
        .cast<TaskStateChangedEvent>()
        .first
        .timeout(const Duration(seconds: 30));
    expect(paused.diskFull, isTrue);

    final record = await store.loadTask('df-1');
    expect(record!.state, TaskState.paused);
    expect(record.state, isNot(TaskState.failed));

    // Segments were downloaded before the merge, so progress is preserved.
    expect(record.doneSegments, 3);

    // Now free up space and resume: the task should complete.
    freeBytes = 1 << 40; // 1 TiB
    await engine.resumeTask('df-1');

    final done = await engine.events
        .where((e) => e is TaskCompletedEvent && e.taskId == 'df-1')
        .cast<TaskCompletedEvent>()
        .first
        .timeout(const Duration(seconds: 30));
    expect(done.outputPath, endsWith('.ts'));

    final after = await store.loadTask('df-1');
    expect(after!.state, TaskState.completed);

    await engine.dispose();
  });

  test('a null free-space query skips the pre-flight and completes', () async {
    final engine = DownloadEngine(
      store: InMemoryTaskStore(),
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
      freeSpaceQuery: (_) async => null,
    );
    final media = (await engine.parseForPreview(
      '${server.baseUrl}/index.m3u8',
    ) as MediaParseResult).media;
    await engine.startTask(
      id: 'df-2',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );
    final done = await engine.events
        .where((e) => e is TaskCompletedEvent && e.taskId == 'df-2')
        .first
        .timeout(const Duration(seconds: 30));
    expect(done, isA<TaskCompletedEvent>());
    await engine.dispose();
  });

  // Regression: an older build with no disk-full detection hung the merge on a
  // full disk, leaving the task persisted as `merging`. After a restart it had
  // no runtime, stayed in the download list forever and offered no action.
  // restoreUnfinished must now cold-resume such a stale `merging` record.
  test('restoreUnfinished cold-resumes a stale merging task', () async {
    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
    );
    try {
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult).media;

      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(
        EngineTaskRecord(
          id: 'stuck-merge',
          url: '${server.baseUrl}/index.m3u8',
          sourceUrl: '${server.baseUrl}/index.m3u8',
          title: 'clip',
          // The zombie state left behind by the interrupted old-version merge.
          state: TaskState.merging,
          saveDir: tempDir.path,
          playlistSnapshot: jsonEncode(media.toJson()),
          totalSegments: media.segmentCount,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await store.saveSegments([
        for (final s in media.segments)
          EngineSegmentRecord(taskId: 'stuck-merge', seq: s.seq, url: s.url),
      ]);

      final done = engine.events
          .where((e) => e is TaskCompletedEvent && e.taskId == 'stuck-merge')
          .cast<TaskCompletedEvent>()
          .first
          .timeout(const Duration(seconds: 30));
      await engine.restoreUnfinished();
      final completed = await done;
      expect(completed.outputPath, endsWith('.ts'));

      final after = await store.loadTask('stuck-merge');
      expect(after!.state, TaskState.completed);
    } finally {
      await engine.dispose();
    }
  });
}
