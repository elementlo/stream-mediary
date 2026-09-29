import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/scheduler/segment_scheduler.dart';

/// Unit tests for the AIMD adaptive concurrency window.
void main() {
  SchedulerJob job(int seq) =>
      SchedulerJob(seq: seq, run: (_) async => true);

  group('AIMD window', () {
    test('starts at the configured maximum', () {
      final s = SegmentScheduler(concurrency: 16);
      expect(s.effectiveConcurrency, 16);
    });

    test('congestion halves the window', () {
      final s = SegmentScheduler(concurrency: 16, minConcurrency: 2);
      s.reportCongestion();
      expect(s.effectiveConcurrency, 8);
    });

    test('a burst of congestion reports within one second halves once', () {
      final s = SegmentScheduler(concurrency: 16, minConcurrency: 2);
      s.reportCongestion();
      s.reportCongestion();
      s.reportCongestion();
      expect(s.effectiveConcurrency, 8);
    });

    test('window never drops below minConcurrency', () async {
      final s = SegmentScheduler(concurrency: 8, minConcurrency: 2);
      for (var i = 0; i < 5; i++) {
        s.reportCongestion();
        await Future<void>.delayed(const Duration(milliseconds: 1100));
      }
      expect(s.effectiveConcurrency, 2);
    });

    test('successful jobs grow the window back to the maximum', () async {
      final s = SegmentScheduler(concurrency: 3, minConcurrency: 1);
      s.reportCongestion();
      expect(s.effectiveConcurrency, 2); // (3/2).round()

      // Additive increase needs `effective` successes per +1 step; run
      // enough successful jobs to climb from 2 back to 3.
      s.submit(List.generate(20, job));
      await s.drained;
      expect(s.effectiveConcurrency, 3);
    });

    test('window stays capped at the configured maximum', () async {
      final s = SegmentScheduler(concurrency: 4, minConcurrency: 1);
      s.submit(List.generate(50, job));
      await s.drained;
      expect(s.effectiveConcurrency, 4);
    });

    test('all jobs run when the window shrinks', () async {
      final s = SegmentScheduler(concurrency: 8, minConcurrency: 2);
      final done = <int>[];
      s.onJobDone = (seq, success, canceled) => done.add(seq);
      s.reportCongestion();
      expect(s.effectiveConcurrency, 4);
      s.submit(List.generate(20, job));
      await s.drained;
      expect(done.toSet().length, 20);
    });
  });

  group('CancelToken plumbing', () {
    test('job receives a working cancel token', () async {
      final s = SegmentScheduler(concurrency: 2);
      CancelToken? seen;
      s.submit([
        SchedulerJob(seq: 0, run: (token) async {
          seen = token;
          return true;
        }),
      ]);
      await s.drained;
      expect(seen, isNotNull);
      expect(seen!.isCancelled, isFalse);
    });
  });
}
