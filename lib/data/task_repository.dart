import '../models/task.dart';
import 'json_list_repository.dart';

class TaskRepository extends JsonListRepository<Task> {
  TaskRepository()
    : super(key: 'tasks_v1', fromJson: Task.fromJson, toJson: _toJson);

  static Map<String, dynamic> _toJson(Task t) => t.toJson();
}
