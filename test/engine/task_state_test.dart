import 'package:flutter_test/flutter_test.dart';
import 'package:stream_mediary/engine/task/task_state.dart';

void main() {
  group('task state machine', () {
    test('happy path transitions are legal', () {
      expect(canTransition(TaskState.created, TaskState.parsing), isTrue);
      expect(canTransition(TaskState.parsing, TaskState.previewReady), isTrue);
      expect(canTransition(TaskState.previewReady, TaskState.queued), isTrue);
      expect(canTransition(TaskState.queued, TaskState.downloading), isTrue);
      expect(canTransition(TaskState.downloading, TaskState.merging), isTrue);
      expect(canTransition(TaskState.merging, TaskState.completed), isTrue);
    });

    test('pause and resume transitions are legal', () {
      expect(canTransition(TaskState.downloading, TaskState.paused), isTrue);
      expect(canTransition(TaskState.paused, TaskState.downloading), isTrue);
      expect(canTransition(TaskState.paused, TaskState.queued), isTrue);
    });

    test('retry from failed and canceled is legal', () {
      expect(canTransition(TaskState.failed, TaskState.queued), isTrue);
      expect(canTransition(TaskState.canceled, TaskState.queued), isTrue);
    });

    test('completed is terminal', () {
      expect(TaskState.completed.isTerminal, isTrue);
      expect(canTransition(TaskState.completed, TaskState.queued), isFalse);
      expect(
          canTransition(TaskState.completed, TaskState.downloading), isFalse);
    });

    test('illegal transitions are rejected', () {
      expect(canTransition(TaskState.created, TaskState.completed), isFalse);
      expect(canTransition(TaskState.parsing, TaskState.merging), isFalse);
      expect(canTransition(TaskState.merging, TaskState.paused), isFalse);
      expect(canTransition(TaskState.queued, TaskState.completed), isFalse);
    });

    test('validateTransition throws on illegal move', () {
      expect(
        () => validateTransition(TaskState.created, TaskState.completed),
        throwsA(isA<StateError>()),
      );
      expect(
        () => validateTransition(TaskState.downloading, TaskState.paused),
        returnsNormally,
      );
    });

    test('isActive reflects downloading and merging', () {
      expect(TaskState.downloading.isActive, isTrue);
      expect(TaskState.merging.isActive, isTrue);
      expect(TaskState.paused.isActive, isFalse);
      expect(TaskState.completed.isActive, isFalse);
    });
  });
}
