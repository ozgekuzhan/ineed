import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/task.dart';

class TaskRepository {
  static const _key = 'tasks_v1';
  static const _backupPrefix = 'tasks_v1_unreadable_';

  /// Loads saved tasks. Never throws on bad data: unreadable entries are
  /// skipped and the original string is kept under a backup key so nothing
  /// is lost for good.
  Future<List<Task>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null) return [];

    final tasks = <Task>[];
    var hadErrors = false;
    try {
      for (final entry in jsonDecode(raw) as List<dynamic>) {
        try {
          tasks.add(Task.fromJson(entry as Map<String, dynamic>));
        } catch (e) {
          hadErrors = true;
          debugPrint('Skipping unreadable task: $e');
        }
      }
    } catch (e) {
      hadErrors = true;
      debugPrint('Task data unreadable: $e');
    }

    if (hadErrors) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString('$_backupPrefix$stamp', raw);
      // Store the readable part right away, so the same broken data isn't
      // backed up again on every launch.
      await save(tasks);
    }
    return tasks;
  }

  Future<void> save(List<Task> tasks) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(tasks.map((t) => t.toJson()).toList()),
    );
  }
}
