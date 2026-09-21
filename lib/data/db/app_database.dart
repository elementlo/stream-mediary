import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqlite3_flutter_libs/sqlite3_flutter_libs.dart';

import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [Tasks, Segments, Settings, BoardComments])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  /// Test constructor allowing an in-memory or custom executor.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(boardComments);
          }
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );

  // ---- Tasks ----

  Stream<List<Task>> watchAllTasks() =>
      (select(tasks)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<Task> watchTask(String id) =>
      (select(tasks)..where((t) => t.id.equals(id))).watchSingle();

  Future<void> upsertTask(TasksCompanion task) =>
      into(tasks).insertOnConflictUpdate(task);

  Future<void> deleteTask(String id) async {
    await (delete(segments)..where((s) => s.taskId.equals(id))).go();
    await (delete(tasks)..where((t) => t.id.equals(id))).go();
  }

  // ---- Segments ----

  Future<List<Segment>> segmentsForTask(String taskId) =>
      (select(segments)..where((s) => s.taskId.equals(taskId))).get();

  Future<void> upsertSegments(List<SegmentsCompanion> rows) =>
      batch((b) => b.insertAllOnConflictUpdate(segments, rows));

  Future<void> deleteSegments(String taskId) =>
      (delete(segments)..where((s) => s.taskId.equals(taskId))).go();

  // ---- Settings ----

  Stream<List<Setting>> watchSettings() => select(settings).watch();

  Future<String?> settingValue(String key) async {
    final row = await (select(settings)..where((s) => s.key.equals(key)))
        .getSingleOrNull();
    return row?.value;
  }

  Future<void> setSetting(String key, String value) =>
      into(settings).insertOnConflictUpdate(
        SettingsCompanion.insert(key: key, value: value),
      );

  // ---- Board comment cache ----

  Future<List<BoardComment>> cachedBoardComments() =>
      (select(boardComments)
            ..orderBy([(t) => OrderingTerm.asc(t.sortIndex)]))
          .get();

  /// Replaces the whole cache with the freshly fetched page set.
  Future<void> replaceBoardComments(
      List<BoardCommentsCompanion> rows) async {
    await batch((b) {
      b.deleteAll(boardComments);
      b.insertAll(boardComments, rows);
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir = await getApplicationSupportDirectory();
    final file = File(p.join(dir.path, 'stream_mediary.sqlite'));

    if (Platform.isAndroid) {
      await applyWorkaroundToOpenSqlite3OnOldAndroidVersions();
    }
    return NativeDatabase.createInBackground(file);
  });
}
