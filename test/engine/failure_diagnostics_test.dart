import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/failure_diagnostics.dart';

void main() {
  group('FailureDiagnosis', () {
    test('reports a useful cause without URL tokens or headers', () {
      final diagnosis = FailureDiagnosis.fromError('HTTP 403');
      expect(diagnosis.code, 'http_auth');
      final report = diagnosis.report(
        taskId: 'task-1',
        url: 'https://video.example.com/media.m3u8?token=secret',
      );
      expect(report, contains('video.example.com'));
      expect(report, isNot(contains('secret')));
      expect(report, isNot(contains('media.m3u8')));
    });

    test('classifies storage and network errors', () {
      expect(
        FailureDiagnosis.fromError('No space left on device').code,
        'no_space',
      );
      expect(FailureDiagnosis.fromError('Connection timeout').code, 'network');
    });
  });
}
