import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// What happens to a task on today's list once it is ticked off.
enum CompletedBehavior {
  /// Stays in place, struck through, until the day ends.
  strikeThrough,

  /// Leaves the list right away.
  hide,
}

class SettingsStore extends ChangeNotifier {
  static const _completedKey = 'settings_completed_behavior';

  CompletedBehavior _completedBehavior = CompletedBehavior.strikeThrough;

  CompletedBehavior get completedBehavior => _completedBehavior;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_completedKey);
    _completedBehavior =
        CompletedBehavior.values.asNameMap()[saved] ??
        CompletedBehavior.strikeThrough;
    notifyListeners();
  }

  Future<void> setCompletedBehavior(CompletedBehavior value) async {
    if (value == _completedBehavior) return;
    _completedBehavior = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, value.name);
  }
}
