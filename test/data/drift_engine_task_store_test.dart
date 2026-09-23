import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/data/db/app_database.dart';
import 'package:stream_mediary/data/repositories/drift_engine_task_store.dart';
import 'package:stream_mediary/engine/engine_store.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

/// Regression suite for the drift-backed task store, focused on the schema v5
/// columns (sourceUrl, playbackMs, durationMs, queueOrder) round-tripping
/// through the real database.
void main() {
  late AppDatabase db;
  late DriftEngineTaskStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = DriftEngineTaskStore(db);
  });

  tearDown(() async => db.close());

  EngineTaskRecord record(String id) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return EngineTaskRecord(
      id: id,
      url: 'http://media.example/index.m3u8',
      sourceUrl: 'https://page.example/watch',
      title: 'clip',
      state: TaskState.completed,
      saveDir: '/tmp',
      playbackMs: 754000,
      durationMs: 6000000,
      queueOrder: 42,
      createdAt: now,
      updatedAt: now,
    );
  }

  test('persists and reloads the v5 columns', () async {
    await store.saveTask(record('t1'));
    final loaded = await store.loadTask('t1');
    expect(loaded, isNotNull);
    expect(loaded!.sourceUrl, 'https://page.example/watch');
    expect(loaded.playbackMs, 754000);
    expect(loaded.durationMs, 6000000);
    expect(loaded.queueOrder, 42);
  });

  test('upsert updates existing row without duplicating', () async {
    await store.saveTask(record('t2'));
    final updated = record('t2')
      ..playbackMs = 999
      ..title = 'renamed';
    await store.saveTask(updated);

    final all = await store.loadAllTasks();
    expect(all.where((t) => t.id == 't2'), hasLength(1));
    final loaded = await store.loadTask('t2');
    expect(loaded!.playbackMs, 999);
    expect(loaded.title, 'renamed');
  });

  test('nullable sourceUrl defaults to null for legacy rows', () async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await store.saveTask(EngineTaskRecord(
      id: 'legacy',
      url: 'http://media.example/index.m3u8',
      title: 'old',
      state: TaskState.completed,
      saveDir: '/tmp',
      createdAt: now,
      updatedAt: now,
    ));
    final loaded = await store.loadTask('legacy');
    expect(loaded!.sourceUrl, isNull);
    expect(loaded.playbackMs, 0);
    expect(loaded.queueOrder, 0);
  });

  test('segments round-trip with status and size', () async {
    await store.saveTask(record('t3'));
    await store.saveSegments([
      EngineSegmentRecord(
        taskId: 't3',
        seq: 0,
        url: 'http://media.example/seg0.ts',
        status: SegmentStatus.done,
        byteSize: 1024,
      ),
      EngineSegmentRecord(taskId: 't3', seq: 1, url: 'http://media.example/seg1.ts'),
    ]);
    final segments = await store.loadSegments('t3');
    expect(segments, hasLength(2));
    final first = segments.firstWhere((s) => s.seq == 0);
    expect(first.status, SegmentStatus.done);
    expect(first.byteSize, 1024);
  });
}
