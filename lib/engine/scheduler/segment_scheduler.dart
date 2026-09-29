/// Segment-level concurrency scheduler.
///
/// Runs segment download jobs through a semaphore pool, always dispatching
/// lower sequence numbers first so merging can start as early as possible.
/// Supports pause (stop dispatching, abort in-flight) and cancel.
///
/// Concurrency is adaptive (AIMD, like TCP congestion control): it starts at
/// [concurrency] (the user-configured maximum), grows additively while
/// downloads succeed, and is halved whenever a job reports congestion
/// (timeout / connection error / 429 / 5xx). This keeps throughput high on
/// healthy sources while backing off quickly on slow or rate-limiting ones.
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
  SegmentScheduler({this.concurrency = 16, this.minConcurrency = 2})
    : _effective = concurrency;

  /// User-configured maximum number of concurrent segment downloads.
  /// Also the starting point for the adaptive window.
  final int concurrency;

  /// Floor for the adaptive window; never throttles below this.
  final int minConcurrency;

  /// Current effective concurrency (AIMD window).
  int _effective;

  /// Successes since the last additive increase.
  int _successesSinceIncrease = 0;

  /// Timestamp of the last multiplicative decrease, so a burst of failures
  /// from one congestion event only halves the window once.
  DateTime _lastDecrease = DateTime.fromMillisecondsSinceEpoch(0);

  int get effectiveConcurrency => _effective;

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

  /// Reports a congestion-type failure (timeout, connection error, 429/5xx).
  ///
  /// Multiplicative decrease: halve the window (down to [minConcurrency]).
  /// Repeated reports within one second are treated as a single event.
  void reportCongestion() {
    final now = DateTime.now();
    if (now.difference(_lastDecrease) < const Duration(seconds: 1)) return;
    _lastDecrease = now;
    final next = (_effective / 2).round().clamp(minConcurrency, concurrency);
    if (next < _effective) {
      _log.info('AIMD decrease: $_effective -> $next');
      _effective = next;
      _successesSinceIncrease = 0;
    }
  }

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
    while (_running < _effective && _queue.isNotEmpty) {
      final job = _queue.removeFirst();
      _running++;
      unawaited(_runJob(job));
    }
    _maybeCompleteDrained();
  }

  /// Additive increase: after every [concurrency] successful jobs (one full
  /// window of healthy downloads), grow the window by one, capped at the
  /// user-configured maximum.
  void _onJobSuccess() {
    if (_effective >= concurrency) return;
    _successesSinceIncrease++;
    if (_successesSinceIncrease >= _effective) {
      _successesSinceIncrease = 0;
      _effective++;
      _log.info('AIMD increase: $_effective');
      _pump();
    }
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

    if (success && !wasCanceled) _onJobSuccess();
    onJobDone?.call(job.seq, success, wasCanceled);
    _pump();
  }

  void _maybeCompleteDrained() {
    if (!_drained.isCompleted && _queue.isEmpty && _running == 0) {
      _drained.complete();
    }
  }
}
