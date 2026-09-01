import 'dart:convert';

import 'package:drift/drift.dart';

import '../../engine/engine_store.dart';
import '../../engine/task/task_state.dart';
import '../db/app_database.dart';

/// Drift-backed implementation of [EngineTaskStore].
class DriftEngineTaskStore implements EngineTaskStore {
  DriftEngineTaskStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> saveTask(EngineTaskRecord task) {
    return _db.upsertTask(TasksCompanion.insert(
      id: task.id,
      url: task.url,
      title: task.title,
      status: task.state.index,
      headers: Value(jsonEncode(task.headers)),
      customKey: Value(task.customKeyHex),
      customIv: Value(task.customIvHex),
      variantJson: Value(task.variantJson),
      playlistSnapshot: Value(task.playlistSnapshot),
      saveDir: task.saveDir,
      outputPath: Value(task.outputPath),
      totalSegments: Value(task.totalSegments),
      doneSegments: Value(task.doneSegments),
      totalBytes: Value(task.totalBytes),
      downloadedBytes: Value(task.downloadedBytes),
      errorMsg: Value(task.errorMsg),
      createdAt: task.createdAt,
      updatedAt: task.updatedAt,
    ));
  }

  @override
  Future<EngineTaskRecord?> loadTask(String id) async {
    final query = _db.select(_db.tasks)..where((t) => t.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _toRecord(row);
  }

  @override
  Future<List<EngineTaskRecord>> loadAllTasks() async {
    final rows = await _db.select(_db.tasks).get();
    return rows.map(_toRecord).toList();
  }

  @override
  Future<void> deleteTask(String id) => _db.deleteTask(id);

  @override
  Future<void> saveSegments(List<EngineSegmentRecord> segments) {
    return _db.upsertSegments(segments
        .map((s) => SegmentsCompanion.insert(
              taskId: s.taskId,
              seq: s.seq,
              url: s.url,
              status: Value(s.status.index),
              byteSize: Value(s.byteSize),
              retryCount: Value(s.retryCount),
            ))
        .toList());
  }

  @override
  Future<List<EngineSegmentRecord>> loadSegments(String taskId) async {
    final rows = await _db.segmentsForTask(taskId);
    return rows
        .map((r) => EngineSegmentRecord(
              taskId: r.taskId,
              seq: r.seq,
              url: r.url,
              status: SegmentStatus.values[r.status],
              byteSize: r.byteSize,
              retryCount: r.retryCount,
            ))
        .toList();
  }

  @override
  Future<void> deleteSegments(String taskId) => _db.deleteSegments(taskId);

  EngineTaskRecord _toRecord(Task row) {
    Map<String, String> headers = {};
    try {
      final decoded = jsonDecode(row.headers);
      if (decoded is Map) {
        headers = decoded.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } on FormatException {
      headers = {};
    }

    return EngineTaskRecord(
      id: row.id,
      url: row.url,
      title: row.title,
      state: TaskState.values[row.status],
      headers: headers,
      customKeyHex: row.customKey,
      customIvHex: row.customIv,
      variantJson: row.variantJson,
      playlistSnapshot: row.playlistSnapshot,
      saveDir: row.saveDir,
      outputPath: row.outputPath,
      totalSegments: row.totalSegments,
      doneSegments: row.doneSegments,
      totalBytes: row.totalBytes,
      downloadedBytes: row.downloadedBytes,
      errorMsg: row.errorMsg,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
    );
  }
}
