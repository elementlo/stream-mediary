import 'package:stream_mediary/engine/engine_store.dart';

/// In-memory [EngineTaskStore] for unit/integration tests.
class InMemoryTaskStore implements EngineTaskStore {
  final Map<String, EngineTaskRecord> _tasks = {};
  final Map<String, List<EngineSegmentRecord>> _segments = {};

  @override
  Future<void> saveTask(EngineTaskRecord task) async {
    _tasks[task.id] = task;
  }

  @override
  Future<EngineTaskRecord?> loadTask(String id) async => _tasks[id];

  @override
  Future<List<EngineTaskRecord>> loadAllTasks() async =>
      _tasks.values.toList();

  @override
  Future<void> deleteTask(String id) async {
    _tasks.remove(id);
    _segments.remove(id);
  }

  @override
  Future<void> saveSegments(List<EngineSegmentRecord> segments) async {
    if (segments.isEmpty) return;
    final taskId = segments.first.taskId;
    final list = _segments.putIfAbsent(taskId, () => []);
    for (final seg in segments) {
      final idx = list.indexWhere((s) => s.seq == seg.seq);
      if (idx >= 0) {
        list[idx] = seg;
      } else {
        list.add(seg);
      }
    }
  }

  @override
  Future<List<EngineSegmentRecord>> loadSegments(String taskId) async =>
      List.of(_segments[taskId] ?? const []);

  @override
  Future<void> deleteSegments(String taskId) async {
    _segments.remove(taskId);
  }
}
