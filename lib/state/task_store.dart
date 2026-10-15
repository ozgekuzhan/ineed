import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/task_repository.dart';
import '../models/task.dart';
import 'save_queue.dart';

class TaskStore extends ChangeNotifier {
  TaskStore(this._repository, {this._clock = DateTime.now});

  final TaskRepository _repository;
  final DateTime Function() _clock;
  final _uuid = const Uuid();
  List<Task> _tasks = [];
  final _saves = SaveQueue();

  List<Task> get openTasks =>
      (_tasks.where((t) => !t.done).toList()..sort(Task.compare));

  List<Task> get doneTasks =>
      (_tasks.where((t) => t.done).toList()..sort(Task.compare));

  /// The list as it stood on [day]: tasks that existed by then and weren't
  /// done before it began. Tasks ticked off that day are included (shown
  /// struck through); they keep their place instead of sinking to the end.
  List<Task> tasksForDay(DateTime day) =>
      (_tasks.where((t) => t.isOnListOf(day)).toList()
        ..sort((a, b) => Task.compare(a, b, doneLast: false)));

  /// Number of tasks finished during [day].
  int completedOn(DateTime day) =>
      _tasks.where((t) => t.wasCompletedOn(day)).length;

  Future<void> load() async {
    _tasks = await _repository.load();
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
        createdAt: _clock(),
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

  /// Flips the done state of the stored task with [task]'s id, so a stale
  /// copy held by the UI can't overwrite newer edits.
  Future<void> toggleDone(Task task) {
    final current = _tasks.where((t) => t.id == task.id).firstOrNull;
    if (current == null) return Future.value();
    return update(
      current.done
          ? current.copyWith(clearCompletedAt: true)
          : current.copyWith(completedAt: _clock()),
    );
  }

  Future<void> remove(Task task) {
    _tasks.removeWhere((t) => t.id == task.id);
    return _commit();
  }

  Future<void> restore(Task task) {
    if (_tasks.any((t) => t.id == task.id)) return Future.value();
    _tasks.add(task);
    return _commit();
  }

  /// Saves run one after another on a snapshot of the list, so a slow
  /// earlier save can never overwrite a newer one.
  Future<void> _commit() {
    notifyListeners();
    final snapshot = List<Task>.of(_tasks);
    return _saves.add(() => _repository.save(snapshot));
  }
}
