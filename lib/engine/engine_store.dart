/// Persistence contract used by the download engine.
///
/// The engine is pure Dart and depends only on this abstraction; the data
/// layer supplies a drift-backed implementation. This keeps the engine
/// unit-testable with an in-memory fake.
library;

import 'task/task_state.dart';

/// Persisted task record as seen by the engine.
class EngineTaskRecord {
  EngineTaskRecord({
    required this.id,
    required this.url,
    this.sourceUrl,
    required this.title,
    required this.state,
    this.headers = const {},
    this.customKeyHex,
    this.customIvHex,
    this.variantJson,
    this.playlistSnapshot,
    required this.saveDir,
    this.outputPath,
    this.totalSegments = 0,
    this.doneSegments = 0,
    this.totalBytes = 0,
    this.downloadedBytes = 0,
    this.errorMsg,
    this.playbackMs = 0,
    this.durationMs = 0,
    this.queueOrder = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  String url;
  String? sourceUrl;
  String title;
  TaskState state;
  Map<String, String> headers;
  String? customKeyHex;
  String? customIvHex;
  String? variantJson;
  String? playlistSnapshot;
  final String saveDir;
  String? outputPath;
  int totalSegments;
  int doneSegments;
  int totalBytes;
  int downloadedBytes;
  String? errorMsg;
  int playbackMs;
  int durationMs;
  int queueOrder;
  final int createdAt;
  int updatedAt;
}

/// Persisted segment record as seen by the engine.
class EngineSegmentRecord {
  EngineSegmentRecord({
    required this.taskId,
    required this.seq,
    required this.url,
    this.status = SegmentStatus.pending,
    this.byteSize = 0,
    this.retryCount = 0,
  });

  final String taskId;
  final int seq;
  final String url;
  SegmentStatus status;
  int byteSize;
  int retryCount;
}

enum SegmentStatus { pending, downloading, done, failed }

/// Abstract persistence for engine task/segment state.
abstract class EngineTaskStore {
  Future<void> saveTask(EngineTaskRecord task);
  Future<EngineTaskRecord?> loadTask(String id);
  Future<List<EngineTaskRecord>> loadAllTasks();
  Future<void> deleteTask(String id);

  Future<void> saveSegments(List<EngineSegmentRecord> segments);
  Future<List<EngineSegmentRecord>> loadSegments(String taskId);
  Future<void> deleteSegments(String taskId);
}
