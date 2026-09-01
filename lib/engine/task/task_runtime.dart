/// Runtime state for a single active download task.
library;

import 'package:dio/dio.dart';

import '../m3u8/playlist.dart';
import '../scheduler/segment_scheduler.dart';
import 'task_state.dart';

/// Tracks live, non-persisted state for one running task.
class TaskRuntime {
  TaskRuntime({required this.taskId});

  final String taskId;

  MediaPlaylist? playlist;
  SegmentScheduler? scheduler;

  /// Cancel token used to abort key fetches and the whole task.
  CancelToken cancelToken = CancelToken();

  TaskState state = TaskState.created;

  int doneSegments = 0;
  int totalSegments = 0;
  int downloadedBytes = 0;
  int totalBytes = 0;

  // Speed tracking.
  int _lastBytes = 0;
  DateTime _lastSample = DateTime.now();
  double bytesPerSecond = 0;

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
