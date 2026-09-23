import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/download_engine.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/engine_events.dart';
import 'package:stream_mediary/engine/engine_store.dart';
import 'package:stream_mediary/engine/m3u8/m3u8_parser.dart';
import 'package:stream_mediary/engine/m3u8/playlist.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

import 'fake_hls_server.dart';
import 'in_memory_task_store.dart';

/// Regression suite for the round-1/2 product features that live in the
/// engine: size estimation, rename, playback progress, redownload, expired
/// source reuse and the queue-allowed gate.
void main() {
  late FakeHlsServer server;
  late Directory tempDir;

  setUp(() async {
    server = FakeHlsServer();
    tempDir = await Directory.systemTemp.createTemp('engine_features');
  });

  tearDown(() async {
    await server.stop();
    if (await tempDir.exists()) {
      await tempDir.delete(recursive: true);
    }
  });

  /// A 4-segment plaintext playlist with 100-byte segments (400 bytes total).
  void servePlainPlaylist({int segmentCount = 4, int segmentSize = 100}) {
    final lines = <String>['#EXTM3U', '#EXT-X-TARGETDURATION:2'];
    for (var i = 0; i < segmentCount; i++) {
      server.segments[i] = List.filled(segmentSize, i + 1);
      lines
        ..add('#EXTINF:2.0,')
        ..add('seg$i.ts');
    }
    lines.add('#EXT-X-ENDLIST');
    server.playlist = lines.join('\n');
  }

  DownloadEngine buildEngine(InMemoryTaskStore store) => DownloadEngine(
        store: store,
        config: const EngineConfig(preferMp4: false),
        defaultSaveDir: tempDir.path,
      );

  group('estimateMediaBytes', () {
    test('byte-range playlist sums range lengths exactly, no network',
        () async {
      // No server started: an exact estimate must not touch the network.
      final playlist = MediaPlaylist(
        segments: [
          Segment(
            seq: 0,
            url: 'http://invalid/movie.mp4',
            duration: 2,
            byteRange: const ByteRange(0, 1000),
          ),
          Segment(
            seq: 1,
            url: 'http://invalid/movie.mp4',
            duration: 2,
            byteRange: const ByteRange(1000, 500),
          ),
        ],
        totalDuration: 4,
        mediaSequence: 0,
      );
      final engine = buildEngine(InMemoryTaskStore());
      expect(await engine.estimateMediaBytes(playlist), 1500);
      await engine.dispose();
    });

    test('samples HEAD sizes and scales by duration', () async {
      servePlainPlaylist(segmentCount: 4, segmentSize: 100);
      await server.start();
      final engine = buildEngine(InMemoryTaskStore());
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult)
          .media;

      final estimate = await engine.estimateMediaBytes(media);
      // 4 segments x 100 bytes, uniform durations -> exact 400.
      expect(estimate, 400);
      await engine.dispose();
    });

    test('returns null when the host rejects HEAD', () async {
      servePlainPlaylist();
      await server.start();
      server.segmentOverrideStatus = 405; // Method Not Allowed
      final engine = buildEngine(InMemoryTaskStore());
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult)
          .media;
      expect(await engine.estimateMediaBytes(media), isNull);
      await engine.dispose();
    });

    test('empty playlist estimates null', () async {
      final engine = buildEngine(InMemoryTaskStore());
      final empty = MediaPlaylist(
        segments: const [],
        totalDuration: 0,
        mediaSequence: 0,
      );
      expect(await engine.estimateMediaBytes(empty), isNull);
      await engine.dispose();
    });
  });

  group('renameTask', () {
    test('renames a completed task and trims whitespace', () async {
      final store = InMemoryTaskStore();
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(EngineTaskRecord(
        id: 'done',
        url: 'http://x/index.m3u8',
        title: 'old',
        state: TaskState.completed,
        saveDir: tempDir.path,
        createdAt: now,
        updatedAt: now,
      ));
      final engine = buildEngine(store);
      await engine.renameTask('done', '  new name  ');
      expect((await store.loadTask('done'))!.title, 'new name');
      await engine.dispose();
    });

    test('ignores rename for non-completed tasks and blank titles', () async {
      final store = InMemoryTaskStore();
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(EngineTaskRecord(
        id: 'active',
        url: 'http://x/index.m3u8',
        title: 'keep',
        state: TaskState.downloading,
        saveDir: tempDir.path,
        createdAt: now,
        updatedAt: now,
      ));
      final engine = buildEngine(store);
      await engine.renameTask('active', 'changed');
      expect((await store.loadTask('active'))!.title, 'keep');
      await engine.renameTask('active', '   ');
      expect((await store.loadTask('active'))!.title, 'keep');
      await engine.dispose();
    });
  });

  group('savePlayback', () {
    test('persists position and duration in milliseconds', () async {
      final store = InMemoryTaskStore();
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(EngineTaskRecord(
        id: 'p1',
        url: 'http://x/index.m3u8',
        title: 'movie',
        state: TaskState.completed,
        saveDir: tempDir.path,
        createdAt: now,
        updatedAt: now,
      ));
      final engine = buildEngine(store);
      await engine.savePlayback(
        'p1',
        const Duration(minutes: 12, seconds: 34),
        const Duration(hours: 1, minutes: 40),
      );
      final record = await store.loadTask('p1');
      expect(record!.playbackMs, (12 * 60 + 34) * 1000);
      expect(record.durationMs, 100 * 60 * 1000);
      await engine.dispose();
    });

    test('unknown task id is a no-op', () async {
      final engine = buildEngine(InMemoryTaskStore());
      await engine.savePlayback(
        'missing',
        Duration.zero,
        const Duration(seconds: 1),
      ); // must not throw
      await engine.dispose();
    });
  });

  group('redownloadTask', () {
    test('creates a fresh task from a completed snapshot', () async {
      servePlainPlaylist(segmentCount: 2, segmentSize: 8);
      await server.start();
      final store = InMemoryTaskStore();
      final engine = buildEngine(store);
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult)
          .media;
      await engine.startTask(
        id: 'original',
        request: DownloadRequest(
          url: '${server.baseUrl}/index.m3u8',
          sourceUrl: 'https://source.example/page',
        ),
        playlist: media,
      );
      await engine.events
          .where((e) => e is TaskCompletedEvent && e.taskId == 'original')
          .first
          .timeout(const Duration(seconds: 30));

      final newId = await engine.redownloadTask('original', 'copy-1');
      expect(newId, 'copy-1');
      await engine.events
          .where((e) => e is TaskCompletedEvent && e.taskId == 'copy-1')
          .first
          .timeout(const Duration(seconds: 30));

      final copy = await store.loadTask('copy-1');
      expect(copy!.state, TaskState.completed);
      // The user-facing source URL survives the redownload.
      expect(copy.sourceUrl, 'https://source.example/page');
      await engine.dispose();
    });

    test('throws when the original has no playlist snapshot', () async {
      final store = InMemoryTaskStore();
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(EngineTaskRecord(
        id: 'no-snap',
        url: 'http://x/index.m3u8',
        title: 't',
        state: TaskState.completed,
        saveDir: tempDir.path,
        createdAt: now,
        updatedAt: now,
      ));
      final engine = buildEngine(store);
      expect(
        () => engine.redownloadTask('no-snap', 'x'),
        throwsA(isA<StateError>()),
      );
      await engine.dispose();
    });
  });

  group('replaceExpiredSource reuse', () {
    test('identical segment structure reuses downloaded bytes', () async {
      servePlainPlaylist(segmentCount: 2, segmentSize: 4);
      await server.start();
      final store = InMemoryTaskStore();
      final engine = buildEngine(store);

      // A failed task whose snapshot matches what the server now serves
      // (same URLs), with segment 0 already on disk.
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult)
          .media;
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(EngineTaskRecord(
        id: 'reuse',
        url: '${server.baseUrl}/index.m3u8',
        title: 'clip',
        state: TaskState.failed,
        saveDir: tempDir.path,
        playlistSnapshot: jsonEncode(media.toJson()),
        totalSegments: 2,
        doneSegments: 1,
        createdAt: now,
        updatedAt: now,
      ));
      await store.saveSegments([
        EngineSegmentRecord(
          taskId: 'reuse',
          seq: 0,
          url: media.segments[0].url,
          status: SegmentStatus.done,
          byteSize: 4,
        ),
        EngineSegmentRecord(taskId: 'reuse', seq: 1, url: media.segments[1].url),
      ]);
      final segmentDir = Directory('${tempDir.path}/clip/segments');
      await segmentDir.create(recursive: true);
      await File('${segmentDir.path}/000000.ts').writeAsBytes([1, 1, 1, 1]);

      final completed = engine.events
          .where((e) => e is TaskCompletedEvent)
          .cast<TaskCompletedEvent>()
          .first
          .timeout(const Duration(seconds: 15));
      await engine.replaceExpiredSource('reuse', '${server.baseUrl}/index.m3u8');
      final done = await completed;

      expect(await File(done.outputPath).readAsBytes(), [1, 1, 1, 1, 2, 2, 2, 2]);
      // Segment 0 was reused: only segment 1 hit the network.
      expect(server.segmentRequests[0], isNull);
      expect(server.segmentRequests[1], 1);
      await engine.dispose();
    });

    test('only failed tasks may replace their source', () async {
      final store = InMemoryTaskStore();
      final now = DateTime.now().millisecondsSinceEpoch;
      await store.saveTask(EngineTaskRecord(
        id: 'queued',
        url: 'http://x/index.m3u8',
        title: 't',
        state: TaskState.queued,
        saveDir: tempDir.path,
        createdAt: now,
        updatedAt: now,
      ));
      final engine = buildEngine(store);
      expect(
        () => engine.replaceExpiredSource('queued', 'http://y/index.m3u8'),
        throwsA(isA<StateError>()),
      );
      await engine.dispose();
    });
  });

  group('queue gate', () {
    test('tasks stay queued while the queue is disallowed', () async {
      servePlainPlaylist(segmentCount: 1);
      await server.start();
      final engine = buildEngine(InMemoryTaskStore())..setQueueAllowed(false);
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult)
          .media;
      await engine.startTask(
        id: 'held',
        request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
        playlist: media,
      );
      // Give any (incorrect) download a chance to start.
      await Future<void>.delayed(const Duration(milliseconds: 500));
      expect(server.segmentRequests, isEmpty);

      engine.setQueueAllowed(true);
      await engine.events
          .where((e) => e is TaskCompletedEvent && e.taskId == 'held')
          .first
          .timeout(const Duration(seconds: 15));
      expect(server.segmentRequests[0], 1);
      await engine.dispose();
    });
  });

  group('live playlist rejection', () {
    test('startTask refuses a live playlist', () async {
      // No ENDLIST -> live.
      server.playlist = '''
#EXTM3U
#EXT-X-TARGETDURATION:2
#EXTINF:2,
seg0.ts
''';
      server.segments[0] = [1];
      await server.start();
      final engine = buildEngine(InMemoryTaskStore());
      final media = (await engine.parseForPreview(
        '${server.baseUrl}/index.m3u8',
      ) as MediaParseResult)
          .media;
      expect(media.isLive, isTrue);
      expect(
        () => engine.startTask(
          id: 'live',
          request: DownloadRequest(url: '${server.baseUrl}/index.m3u8'),
          playlist: media,
        ),
        throwsA(isA<M3u8ParseException>()),
      );
      await engine.dispose();
    });
  });
}
