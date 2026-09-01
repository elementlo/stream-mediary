/// Segment-level concurrency scheduler.
///
/// Runs segment download jobs through a fixed-size semaphore pool, always
/// dispatching lower sequence numbers first so merging can start as early as
/// possible. Supports pause (stop dispatching, abort in-flight) and cancel.
library;

import 'dart:async';
import 'dart:collection';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

final Logger _log = Logger('SegmentScheduler');

/// A unit of work scheduled by [SegmentScheduler].
class SchedulerJob {
  SchedulerJob({required this.seq, required this.run});

  /// Media sequence number; lower values are dispatched first.
  final int seq;

  /// Executes the job, receiving a [CancelToken] used to abort the transfer
  /// on pause/cancel. Returns true on success.
  final Future<bool> Function(CancelToken token) run;
}

/// Callback invoked when a job finishes: (seq, success, wasCanceled).
typedef JobDoneCallback = void Function(
    int seq, bool success, bool wasCanceled);

class SegmentScheduler {
  SegmentScheduler({this.concurrency = 8});

  /// Number of segments downloaded concurrently.
  final int concurrency;

  final Queue<SchedulerJob> _queue = Queue();
  final Map<int, CancelToken> _inFlight = {};
  int _running = 0;
  bool _paused = false;
  bool _disposed = false;

  JobDoneCallback? onJobDone;

  /// Completes when the queue drains and no jobs are running.
  final Completer<void> _drained = Completer<void>();
  Future<void> get drained => _drained.future;

  bool get isPaused => _paused;

  /// Enqueues jobs (sorted by seq ascending) and starts dispatching.
  void submit(List<SchedulerJob> jobs) {
    final sorted = [...jobs]..sort((a, b) => a.seq.compareTo(b.seq));
    _queue.addAll(sorted);
    _pump();
  }

  /// Pauses dispatching; in-flight downloads are canceled and re-queued so
  /// they resume later.
  void pause() {
    if (_paused || _disposed) return;
    _paused = true;
    _cancelInFlight('paused', requeue: true);
  }

  /// Resumes dispatching after [pause].
  void resume() {
    if (!_paused || _disposed) return;
    _paused = false;
    _pump();
  }

  /// Cancels all in-flight work and clears the queue. [drained] completes.
  void cancel() {
    if (_disposed) return;
    _disposed = true;
    _queue.clear();
    _cancelInFlight('canceled', requeue: false);
    _maybeCompleteDrained();
  }

  void _cancelInFlight(String reason, {required bool requeue}) {
    final entries = _inFlight.entries.toList();
    _inFlight.clear();
    for (final entry in entries) {
      entry.value.cancel(reason);
      if (requeue) {
        // Re-queue is handled by the job-done path detecting cancellation.
      }
    }
  }

  void _pump() {
    if (_disposed || _paused) return;
    while (_running < concurrency && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _running++;
      unawaited(_runJob(job));
    }
    _maybeCompleteDrained();
  }

  Future<void> _runJob(SchedulerJob job) async {
    final token = CancelToken();
    _inFlight[job.seq] = token;
    var success = false;
    try {
      success = await job.run(token);
    } catch (e) {
      _log.warning('Job ${job.seq} threw: $e');
      success = false;
    } finally {
      _inFlight.remove(job.seq);
      _running--;
    }

    final wasCanceled = token.isCancelled;

    if (_disposed) {
      _maybeCompleteDrained();
      return;
    }

    // On pause, re-queue canceled jobs so they resume later.
    if (wasCanceled && _paused && !_disposed) {
      _queue.addFirst(job);
    }

    onJobDone?.call(job.seq, success, wasCanceled);
    _pump();
  }

  void _maybeCompleteDrained() {
    if (!_drained.isCompleted && _queue.isEmpty && _running == 0) {
      _drained.complete();
    }
  }
}
