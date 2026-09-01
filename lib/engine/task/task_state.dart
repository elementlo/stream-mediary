/// Download task state machine.
///
/// States and legal transitions are centralized here; every transition is
/// validated through [canTransition] so illegal moves are caught early.
library;

enum TaskState {
  /// Task created but not yet parsed.
  created,

  /// Fetching and parsing the playlist.
  parsing,

  /// Playlist parsed, waiting for user confirmation (preview shown).
  previewReady,

  /// Confirmed, waiting for a concurrency slot.
  queued,

  /// Actively downloading segments.
  downloading,

  /// Paused by the user.
  paused,

  /// All segments downloaded, merging into a single file.
  merging,

  /// Finished successfully; output file available.
  completed,

  /// Failed with a retryable error.
  failed,

  /// Canceled by the user.
  canceled;

  bool get isTerminal =>
      this == completed || this == failed || this == canceled;

  bool get isActive => this == downloading || this == merging;
}

/// Legal state transitions.
const Map<TaskState, Set<TaskState>> _transitions = {
  TaskState.created: {TaskState.parsing, TaskState.canceled},
  TaskState.parsing: {
    TaskState.previewReady,
    TaskState.failed,
    TaskState.canceled,
  },
  TaskState.previewReady: {TaskState.queued, TaskState.canceled},
  TaskState.queued: {TaskState.downloading, TaskState.canceled},
  TaskState.downloading: {
    TaskState.paused,
    TaskState.merging,
    TaskState.failed,
    TaskState.canceled,
  },
  TaskState.paused: {
    TaskState.queued,
    TaskState.downloading,
    TaskState.canceled,
  },
  TaskState.merging: {TaskState.completed, TaskState.failed},
  TaskState.failed: {TaskState.queued, TaskState.canceled},
  TaskState.canceled: {TaskState.queued},
  TaskState.completed: {},
};

/// Returns true when transitioning from [from] to [to] is allowed.
bool canTransition(TaskState from, TaskState to) =>
    _transitions[from]?.contains(to) ?? false;

/// Validates a transition, throwing [StateError] when illegal.
void validateTransition(TaskState from, TaskState to) {
  if (!canTransition(from, to)) {
    throw StateError('Illegal task transition: $from -> $to');
  }
}
