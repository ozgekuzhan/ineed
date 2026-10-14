import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/task_repository.dart';
import '../models/task.dart';

class TaskStore extends ChangeNotifier {
  TaskStore(this._repository);

  final TaskRepository _repository;
  final _uuid = const Uuid();
  List<Task> _tasks = [];
  bool _loaded = false;

  bool get loaded => _loaded;

  List<Task> get openTasks =>
      (_tasks.where((t) => !t.done).toList()..sort(Task.compare));

  List<Task> get doneTasks =>
      (_tasks.where((t) => t.done).toList()..sort(Task.compare));

  Future<void> load() async {
    _tasks = await _repository.load();
    _loaded = true;
    notifyListeners();
  }

  Future<void> add({
    required String title,
    String note = '',
    Priority priority = Priority.medium,
    DateTime? dueDate,
  }) {
    _tasks.add(
      Task(
        id: _uuid.v4(),
        title: title,
        note: note,
        priority: priority,
        dueDate: dueDate,
        createdAt: DateTime.now(),
      ),
    );
    return _commit();
  }

  Future<void> update(Task task) {
    final i = _tasks.indexWhere((t) => t.id == task.id);
    if (i == -1) return Future.value();
    _tasks[i] = task;
    return _commit();
  }

  Future<void> toggleDone(Task task) => update(task.copyWith(done: !task.done));

  Future<void> remove(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);
    return _commit();
  }

  Future<void> restore(Task task) {
    if (_tasks.any((t) => t.id == task.id)) return Future.value();
    _tasks.add(task);
    return _commit();
  }

  Future<void> _commit() {
    notifyListeners();
    return _repository.save(_tasks);
  }
}
