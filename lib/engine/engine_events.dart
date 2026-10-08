/// Events emitted by the download engine to the UI layer.
library;

import 'task/task_state.dart';

sealed class EngineEvent {
  const EngineEvent({required this.taskId});
  final String taskId;
}

class TaskStateChangedEvent extends EngineEvent {
  const TaskStateChangedEvent({
    required super.taskId,
    required this.state,
    this.error,
    this.diskFull = false,
  });

  final TaskState state;
  final String? error;

  /// True when the task was paused because the disk is full. The UI shows a
  /// "free up space then resume" hint instead of a generic pause.
  final bool diskFull;
}

class ProgressEvent extends EngineEvent {
  const ProgressEvent({
    required super.taskId,
    required this.doneSegments,
    required this.totalSegments,
    required this.downloadedBytes,
    required this.totalBytes,
    required this.bytesPerSecond,
  });

  final int doneSegments;
  final int totalSegments;
  final int downloadedBytes;
  final int totalBytes;
  final double bytesPerSecond;

  double get fraction =>
      totalBytes <= 0 ? 0 : downloadedBytes / totalBytes;
}

class MergeProgressEvent extends EngineEvent {
  const MergeProgressEvent({
    required super.taskId,
    required this.writtenBytes,
    required this.totalBytes,
  });

  final int writtenBytes;
  final int totalBytes;

  double get fraction =>
      totalBytes <= 0 ? 0 : writtenBytes / totalBytes;
}

class TaskCompletedEvent extends EngineEvent {
  const TaskCompletedEvent({
    required super.taskId,
    required this.outputPath,
  });

  final String outputPath;
}

class ErrorOccurredEvent extends EngineEvent {
  const ErrorOccurredEvent({
    required super.taskId,
    required this.message,
  });

  final String message;
}
