import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/engine_config.dart';
import 'package:stream_mediary/engine/engine_events.dart';
import 'package:stream_mediary/engine/task/task_runtime.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

void main() {
  group('DownloadRequest.effectiveTitle', () {
    test('uses explicit non-empty title', () {
      const r = DownloadRequest(url: 'https://cdn/a.m3u8', title: ' My Show ');
      expect(r.effectiveTitle, 'My Show');
    });

    test('falls back to last path segment without .m3u8', () {
      const r = DownloadRequest(url: 'https://cdn/videos/episode01.m3u8');
      expect(r.effectiveTitle, 'episode01');
    });

    test('ignores blank title', () {
      const r = DownloadRequest(url: 'https://cdn/videos/ep.m3u8', title: '  ');
      expect(r.effectiveTitle, 'ep');
    });

    test('falls back to raw url when no path segments', () {
      const r = DownloadRequest(url: 'not-a-url');
      expect(r.effectiveTitle, 'not-a-url');
    });
  });

  group('EngineConfig.copyWith', () {
    test('overrides only provided fields', () {
      const base = EngineConfig();
      final copy = base.copyWith(segmentConcurrency: 16, preferMp4: false);
      expect(copy.taskConcurrency, base.taskConcurrency);
      expect(copy.segmentConcurrency, 16);
      expect(copy.preferMp4, isFalse);
      expect(copy.ffmpegPath, isNull);
    });

    test('keeps values when nothing provided', () {
      const base = EngineConfig(
        taskConcurrency: 5,
        segmentConcurrency: 4,
        preferMp4: false,
        ffmpegPath: '/usr/bin/ffmpeg',
      );
      final copy = base.copyWith();
      expect(copy.taskConcurrency, 5);
      expect(copy.segmentConcurrency, 4);
      expect(copy.preferMp4, isFalse);
      expect(copy.ffmpegPath, '/usr/bin/ffmpeg');
    });
  });

  group('EngineEvent fractions', () {
    test('ProgressEvent.fraction guards zero total', () {
      const p = ProgressEvent(
        taskId: 't',
        doneSegments: 0,
        totalSegments: 0,
        downloadedBytes: 0,
        totalBytes: 0,
        bytesPerSecond: 0,
      );
      expect(p.fraction, 0);

      const p2 = ProgressEvent(
        taskId: 't',
        doneSegments: 1,
        totalSegments: 4,
        downloadedBytes: 25,
        totalBytes: 100,
        bytesPerSecond: 10,
      );
      expect(p2.fraction, 0.25);
    });

    test('MergeProgressEvent.fraction guards zero total', () {
      const m = MergeProgressEvent(taskId: 't', writtenBytes: 0, totalBytes: 0);
      expect(m.fraction, 0);

      const m2 = MergeProgressEvent(taskId: 't', writtenBytes: 50, totalBytes: 200);
      expect(m2.fraction, 0.25);
    });

    test('state and error events carry payload', () {
      const s = TaskStateChangedEvent(
        taskId: 't',
        state: TaskState.failed,
        error: 'boom',
      );
      expect(s.state, TaskState.failed);
      expect(s.error, 'boom');

      const c = TaskCompletedEvent(taskId: 't', outputPath: '/out.mp4');
      expect(c.outputPath, '/out.mp4');

      const e = ErrorOccurredEvent(taskId: 't', message: 'oops');
      expect(e.message, 'oops');
    });
  });

  group('TaskRuntime', () {
    test('fraction guards zero total', () {
      final rt = TaskRuntime(taskId: 't');
      expect(rt.fraction, 0);
      rt.totalBytes = 200;
      rt.downloadedBytes = 50;
      expect(rt.fraction, 0.25);
    });

    test('sampleSpeed only updates after 500ms window', () async {
      final rt = TaskRuntime(taskId: 't');
      rt.downloadedBytes = 1000;
      // Immediately after construction the window has not elapsed.
      rt.sampleSpeed();
      expect(rt.bytesPerSecond, 0);

      await Future<void>.delayed(const Duration(milliseconds: 550));
      rt.sampleSpeed();
      expect(rt.bytesPerSecond, greaterThan(0));
    });
  });
}
