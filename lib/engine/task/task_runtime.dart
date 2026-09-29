/// Runtime state for a single active download task.
library;

import 'package:dio/dio.dart';

import '../engine_store.dart';
import '../m3u8/playlist.dart';
import '../scheduler/segment_scheduler.dart';
import 'task_state.dart';

/// Tracks live, non-persisted state for one running task.
class TaskRuntime {
  TaskRuntime({required this.taskId});

  final String taskId;

  /// The in-memory record this runtime is driving. Holding it here keeps
  /// live progress (doneSegments/downloadedBytes) authoritative: control
  /// operations like pause must persist *this* record, not a stale reload
  /// from the store, or the UI progress would snap back to zero.
  EngineTaskRecord? record;

  MediaPlaylist? playlist;
  SegmentScheduler? scheduler;

  /// Cancel token used to abort key fetches and the whole task.
  CancelToken cancelToken = CancelToken();

  TaskState state = TaskState.created;

  int doneSegments = 0;
  int totalSegments = 0;
  int downloadedBytes = 0;
  int totalBytes = 0;

  /// True when [totalBytes] is an exact figure (e.g. a byte-range playlist
  /// whose segment lengths are all known up front). When false, [totalBytes]
  /// is a running estimate derived from completed segments and must not be
  /// treated as authoritative.
  bool totalBytesExact = false;

  // Speed tracking.
  int _lastBytes = 0;
  DateTime _lastSample = DateTime.now();
  double bytesPerSecond = 0;

  /// Timestamp of the last throttled progress flush to the store.
  DateTime lastProgressPersist = DateTime.fromMillisecondsSinceEpoch(0);

  /// Cached AES keys by key URI.
  final Map<String, List<int>> keyCache = {};

  void sampleSpeed() {
    final now = DateTime.now();
    final elapsed = now.difference(_lastSample).inMilliseconds;
    if (elapsed >= 500) {
      final delta = downloadedBytes - _lastBytes;
      bytesPerSecond = delta * 1000 / elapsed;
      _lastBytes = downloadedBytes;
      _lastSample = now;
    }
  }

  double get fraction =>
      totalBytes <= 0 ? 0 : downloadedBytes / totalBytes;
}
