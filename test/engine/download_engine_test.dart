import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/download_engine.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/engine_events.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

import 'in_memory_task_store.dart';

/// Serves a synthetic m3u8 playlist and its segments over localhost HTTP.
class _FakeHlsServer {
  HttpServer? _server;
  late String baseUrl;

  /// segment index -> bytes
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
          ..headers.contentType = ContentType('application', 'vnd.apple.mpegurl')
          ..write(playlist);
      } else if (path.startsWith('/seg')) {
        final idx = int.parse(path.substring('/seg'.length).replaceAll('.ts', ''));
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

  Future<void> stop() async {
    await _server?.close(force: true);
  }
}

void main() {
  late _FakeHlsServer server;
  late Directory tempDir;

  setUp(() async {
    server = _FakeHlsServer();
    tempDir = await Directory.systemTemp.createTemp('engine_e2e');
  });

  tearDown(() async {
    await server.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  test('downloads, merges and completes a plaintext playlist', () async {
    // Build 5 segments with distinct content.
    final segData = <int, List<int>>{};
    final lines = <String>['#EXTM3U', '#EXT-X-VERSION:3', '#EXT-X-TARGETDURATION:2'];
    for (var i = 0; i < 5; i++) {
      segData[i] = List.generate(64, (b) => (i * 64 + b) % 256);
      lines.add('#EXTINF:2.0,');
      lines.add('seg$i.ts');
    }
    lines.add('#EXT-X-ENDLIST');
    server.segments.addAll(segData);
    server.playlist = lines.join('\n');
    await server.start();

    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
    );

    final events = <EngineEvent>[];
    final sub = engine.events.listen(events.add);

    // Parse preview.
    final parseResult = await engine.parseForPreview('${server.baseUrl}/index.m3u8');
    expect(parseResult, isA<MediaParseResult>());
    final media = (parseResult as MediaParseResult).media;
    expect(media.segmentCount, 5);

    // Start the task.
    final id = await engine.startTask(
      id: 'task-1',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );
    expect(id, 'task-1');

    // Wait for completion.
    final completed = await engine.events
        .where((e) => e is TaskCompletedEvent && e.taskId == id)
        .first
        .timeout(const Duration(seconds: 30));

    expect(completed, isA<TaskCompletedEvent>());
    final outputPath = (completed as TaskCompletedEvent).outputPath;
    expect(outputPath, endsWith('.ts'));

    // Verify merged output equals concatenated segments.
    final merged = File(outputPath).readAsBytesSync();
    final expected = <int>[];
    for (var i = 0; i < 5; i++) {
      expected.addAll(segData[i]!);
    }
    expect(merged, expected);

    // Verify persisted task state.
    final record = await store.loadTask(id);
    expect(record, isNotNull);
    expect(record!.state, TaskState.completed);
    expect(record.outputPath, outputPath);

    // Verify progress events were emitted.
    expect(events.whereType<ProgressEvent>(), isNotEmpty);
    expect(events.whereType<MergeProgressEvent>(), isNotEmpty);

    await sub.cancel();
    await engine.dispose();
  });

  test('duplicate titles get a numeric suffix so folders never clash',
      () async {
    final lines = <String>['#EXTM3U', '#EXT-X-TARGETDURATION:2'];
    for (var i = 0; i < 2; i++) {
      server.segments[i] = List.filled(16, i);
      lines.add('#EXTINF:2.0,');
      lines.add('seg$i.ts');
    }
    lines.add('#EXT-X-ENDLIST');
    server.playlist = lines.join('\n');
    await server.start();

    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
    );

    final media = (await engine.parseForPreview('${server.baseUrl}/index.m3u8')
        as MediaParseResult)
        .media;

    // Subscribe before starting: the broadcast stream would drop events
    // emitted before a listener exists, and these tasks are tiny.
    final completedIds = <String>[];
    final sub = engine.events.listen((e) {
      if (e is TaskCompletedEvent) completedIds.add(e.taskId);
    });

    await engine.startTask(
      id: 'dup-1',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );
    await engine.startTask(
      id: 'dup-2',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );
    await engine.startTask(
      id: 'dup-3',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );

    // Let all three tasks finish so tearDown can remove the temp dir.
    final deadline = DateTime.now().add(const Duration(seconds: 30));
    while (completedIds.length < 3 && DateTime.now().isBefore(deadline)) {
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }
    expect(completedIds, hasLength(3));
    await sub.cancel();

    final t1 = (await store.loadTask('dup-1'))!.title;
    final t2 = (await store.loadTask('dup-2'))!.title;
    final t3 = (await store.loadTask('dup-3'))!.title;
    expect({t1, t2, t3}, hasLength(3), reason: 'titles must be unique');
    expect(t2, '$t1 (2)');
    expect(t3, '$t1 (3)');

    await engine.dispose();
  });

  test('restoreUnfinished resumes a persisted downloading task', () async {
    final segData = <int, List<int>>{};
    final lines = <String>['#EXTM3U', '#EXT-X-TARGETDURATION:2'];
    for (var i = 0; i < 3; i++) {
      segData[i] = List.filled(32, i + 1);
      lines.add('#EXTINF:2.0,');
      lines.add('seg$i.ts');
    }
    lines.add('#EXT-X-ENDLIST');
    server.segments.addAll(segData);
    server.playlist = lines.join('\n');
    await server.start();

    final store = InMemoryTaskStore();
    final engine = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
    );

    final parseResult = await engine.parseForPreview('${server.baseUrl}/index.m3u8');
    final media = (parseResult as MediaParseResult).media;

    await engine.startTask(
      id: 'task-2',
      request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
      playlist: media,
    );

    // Wait for completion first.
    await engine.events
        .where((e) => e is TaskCompletedEvent && e.taskId == 'task-2')
        .first
        .timeout(const Duration(seconds: 30));

    // Simulate restart: mark task as downloading and restore.
    final record = await store.loadTask('task-2');
    record!.state = TaskState.downloading;
    await store.saveTask(record);

    final engine2 = DownloadEngine(
      store: store,
      config: const EngineConfig(preferMp4: false),
      defaultSaveDir: tempDir.path,
    );
    await engine2.restoreUnfinished();

    final completed = await engine2.events
        .where((e) => e is TaskCompletedEvent && e.taskId == 'task-2')
        .first
        .timeout(const Duration(seconds: 30));
    expect(completed, isA<TaskCompletedEvent>());

    await engine.dispose();
    await engine2.dispose();
  });
}
