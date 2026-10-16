// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tabTasks => 'Tasks';

  @override
  String get tabCalendar => 'Calendar';

  @override
  String get tasksTitle => 'To-do';

  @override
  String get history => 'History';

  @override
  String get settings => 'Settings';

  @override
  String get newTask => 'New task';

  @override
  String get editTask => 'Edit task';

  @override
  String get save => 'Save';

  @override
  String get undo => 'Undo';

  @override
  String taskDeleted(Object title) {
    return '\"$title\" deleted';
  }

  @override
  String taskCompleted(Object title) {
    return '\"$title\" completed';
  }

  @override
  String get emptyTasksTitle => 'No tasks yet';

  @override
  String get emptyTasksHint => 'Tap + to add your first task';

  @override
  String get allDoneTitle => 'All done 🎉';

  @override
  String allDoneSubtitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'You finished $count tasks today',
      one: 'You finished 1 task today',
    );
    return '$_temp0';
  }

  @override
  String todayProgress(int done, int total) {
    return 'Today $done / $total done';
  }

  @override
  String get todayProgressLabel => 'Today\'s progress';

  @override
  String doneOfTotal(int done, int total) {
    return '$done / $total done';
  }

  @override
  String get historyEmptyDay => 'No tasks were on the list this day';

  @override
  String dueToday(Object time) {
    return 'Today $time';
  }

  @override
  String dueTomorrow(Object time) {
    return 'Tomorrow $time';
  }

  @override
  String dueYesterday(Object time) {
    return 'Yesterday $time';
  }

  @override
  String overdue(Object when) {
    return 'Overdue · $when';
  }

  @override
  String get priorityHigh => 'High';

  @override
  String get priorityMedium => 'Medium';

  @override
  String get priorityLow => 'Low';

  @override
  String priorityA11y(Object priority) {
    return '$priority priority';
  }

  @override
  String get taskTitleLabel => 'What needs doing?';

  @override
  String get priority => 'Priority';

  @override
  String get dueDate => 'Due date';

  @override
  String get pickDate => 'Pick a date';

  @override
  String get removeDate => 'Remove date';

  @override
  String get taskReminderHint =>
      'Reminders 1 day before, 1 hour before and at the due time.';

  @override
  String get note => 'Note';

  @override
  String get markDone => 'Mark as done';

  @override
  String get markNotDone => 'Mark as not done';

  @override
  String get itemGone => 'This item no longer exists (deleted).';

  @override
  String get upcoming => 'Upcoming';

  @override
  String get newEntryTooltip => 'New birthday / event';

  @override
  String get calendarEmpty =>
      'Nothing saved yet.\nTap + to add a birthday or event.';

  @override
  String get dayEmpty => 'Nothing on this day.';

  @override
  String turnsAge(int age) {
    return 'turns $age';
  }

  @override
  String daysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days ago',
      one: '1 day ago',
    );
    return '$_temp0';
  }

  @override
  String inDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'in $count days',
      one: 'in 1 day',
    );
    return '$_temp0';
  }

  @override
  String get today => 'Today';

  @override
  String get tomorrow => 'Tomorrow';

  @override
  String get monthView => 'Month';

  @override
  String get birthday => 'Birthday';

  @override
  String get event => 'Event';

  @override
  String get newEntry => 'New entry';

  @override
  String get edit => 'Edit';

  @override
  String get delete => 'Delete';

  @override
  String get cancel => 'Cancel';

  @override
  String get deleteConfirmTitle => 'Delete?';

  @override
  String deleteConfirmBody(Object title) {
    return '\"$title\" will be removed from the calendar.';
  }

  @override
  String get birthdayNameLabel => 'Whose birthday?';

  @override
  String get eventNameLabel => 'Event name';

  @override
  String get birthDate => 'Date of birth';

  @override
  String get date => 'Date';

  @override
  String get unknownBirthYear => 'I don\'t know the birth year';

  @override
  String get addTime => 'Add a time';

  @override
  String get repeatYearly => 'Repeat every year';

  @override
  String get repeatYearlyHint => 'Like anniversaries';

  @override
  String eventReminderHint(Object time) {
    return 'Reminders 3 days before and on the day at $time (change it in Settings).';
  }

  @override
  String timedEventReminderHint(Object time) {
    return 'Reminders 3 days before at $time and 1 hour before it starts.';
  }

  @override
  String get completedSection => 'Completed tasks';

  @override
  String get strikeThrough => 'Keep them, struck through';

  @override
  String get strikeThroughHint =>
      'They stay on the list all day, so you see what you\'ve done.';

  @override
  String get hideCompleted => 'Remove them from the list';

  @override
  String get hideCompletedHint =>
      'They leave the list as soon as you tick them.';

  @override
  String get completedFooter =>
      'The next day only unfinished tasks stay on the list. You can see past days in History.';

  @override
  String get remindersSection => 'Reminders';

  @override
  String get reminderTimeTitle => 'Birthday and event time';

  @override
  String get reminderTimeSubtitle =>
      '3 days before and on the day, at this time';

  @override
  String get reminderTimePicker => 'Reminder time';

  @override
  String get remindersFooter =>
      'Tasks are reminded 1 day before, 1 hour before and at the due time. Events with a time are reminded 1 hour before.';

  @override
  String get languageSection => 'Language';

  @override
  String get languageSystem => 'Automatic (phone language)';

  @override
  String notifDueTomorrow(Object time) {
    return 'Due tomorrow $time';
  }

  @override
  String notifOneHourLeft(Object time) {
    return '1 hour left · $time';
  }

  @override
  String get notifDueNow => 'Due now';

  @override
  String get notifBirthdayIn3Days => 'Birthday in 3 days';

  @override
  String get notifIn3Days => 'In 3 days';

  @override
  String get notifBirthdayToday => 'Birthday today! 🎉';

  @override
  String notifInOneHour(Object time) {
    return 'In 1 hour · $time';
  }
}
