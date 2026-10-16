import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';
import '../models/dates.dart';

/// What happens to a task on today's list once it is ticked off.
enum CompletedBehavior {
  /// Stays in place, struck through, until the day ends.
  strikeThrough,

  /// Leaves the list right away.
  hide,
}

class SettingsStore extends ChangeNotifier {
  static const _completedKey = 'settings_completed_behavior';
  static const _reminderKey = 'settings_reminder_minutes';
  static const _languageKey = 'settings_language';
  static const defaultReminderTime = (hour: 9, minute: 0);

  CompletedBehavior _completedBehavior = CompletedBehavior.strikeThrough;
  ClockTime _reminderTime = defaultReminderTime;
  AppLanguage _language = AppLanguage.system;

  AppLanguage get language => _language;

  CompletedBehavior get completedBehavior => _completedBehavior;

  /// Time of day for birthday and event reminders.
  ClockTime get reminderTime => _reminderTime;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_completedKey);
    _completedBehavior =
        CompletedBehavior.values.asNameMap()[saved] ??
        CompletedBehavior.strikeThrough;
    final minutes = prefs.getInt(_reminderKey);
    _reminderTime = minutes != null && minutes >= 0 && minutes < 24 * 60
        ? (hour: minutes ~/ 60, minute: minutes % 60)
        : defaultReminderTime;
    _language =
        AppLanguage.values.asNameMap()[prefs.getString(_languageKey)] ??
        AppLanguage.system;
    notifyListeners();
  }

  Future<void> setCompletedBehavior(CompletedBehavior value) async {
    if (value == _completedBehavior) return;
    _completedBehavior = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_completedKey, value.name);
  }

  Future<void> setReminderTime(ClockTime value) async {
    if (value == _reminderTime) return;
    _reminderTime = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderKey, value.hour * 60 + value.minute);
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (value == _language) return;
    _language = value;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, value.name);
  }
}
