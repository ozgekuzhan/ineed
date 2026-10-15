import 'package:intl/intl.dart';

import '../models/event.dart';
import '../models/task.dart';

/// A reminder to show at a local wall-clock time.
class PlannedNotification {
  const PlannedNotification({
    required this.at,
    required this.title,
    required this.body,
    required this.payload,
  });

  final DateTime at;
  final String title;
  final String body;

  /// Identifies what the reminder is about, e.g. `task:<id>`.
  final String payload;

  @override
  String toString() => 'PlannedNotification($at, $title, $body)';
}

/// iOS keeps at most 64 pending local notifications per app and silently
/// drops the rest; stay below that and keep the soonest ones. The plan is
/// rebuilt on every change and app start, so later ones follow in time.
const maxPlannedNotifications = 60;

/// Hour of the day for birthday/event reminders.
const eventReminderHour = 9;

/// All reminders after [now], soonest first, capped at
/// [maxPlannedNotifications].
List<PlannedNotification> planNotifications({
  required List<Task> tasks,
  required List<Event> events,
  required DateTime now,
}) {
  final plan =
      <PlannedNotification>[
        for (final t in tasks) ..._forTask(t),
        for (final e in events) ..._forEvent(e, now),
      ].where((n) => n.at.isAfter(now)).toList()..sort((a, b) {
        final byTime = a.at.compareTo(b.at);
        return byTime != 0 ? byTime : a.title.compareTo(b.title);
      });
  return plan.length > maxPlannedNotifications
      ? plan.sublist(0, maxPlannedNotifications)
      : plan;
}

Iterable<PlannedNotification> _forTask(Task t) sync* {
  final due = t.dueDate;
  if (t.done || due == null) return;
  final time = DateFormat('HH:mm', 'tr').format(due);
  final title = '⏰ ${t.title}';
  final payload = 'task:${t.id}';
  // Same wall-clock time on the previous calendar day (not 24 hours, which
  // is off by an hour across a clock change).
  yield PlannedNotification(
    at: DateTime(due.year, due.month, due.day - 1, due.hour, due.minute),
    title: title,
    body: 'Son tarih yarın $time',
    payload: payload,
  );
  yield PlannedNotification(
    at: due.subtract(const Duration(hours: 1)),
    title: title,
    body: '1 saat kaldı · $time',
    payload: payload,
  );
  yield PlannedNotification(
    at: due,
    title: title,
    body: 'Son tarih şimdi',
    payload: payload,
  );
}

Iterable<PlannedNotification> _forEvent(Event e, DateTime now) sync* {
  final next = e.nextOccurrence(now);
  if (next == null) return;
  yield* _forOccurrence(e, next);
  // Also the one after, in case the app isn't opened for a long while.
  if (e.repeatsYearly) {
    final following = e.dayInYear(next.year + 1);
    if (following != null) yield* _forOccurrence(e, following);
  }
}

Iterable<PlannedNotification> _forOccurrence(Event e, DateTime day) sync* {
  final isBirthday = e.kind == EventKind.birthday;
  final title = '${isBirthday ? '🎂' : '📅'} ${e.title}';
  final payload = 'event:${e.id}';
  final age = e.ageOn(day);
  final time = e.hasTime && !isBirthday
      ? DateFormat('HH:mm', 'tr').format(e.date)
      : null;
  final dayText = DateFormat('d MMMM EEEE', 'tr').format(day);

  yield PlannedNotification(
    at: DateTime(day.year, day.month, day.day - 3, eventReminderHour),
    title: title,
    body: [
      isBirthday ? 'Doğum günü 3 gün sonra' : '3 gün sonra',
      dayText,
      ?time,
      if (age != null) '$age yaşına giriyor',
    ].join(' · '),
    payload: payload,
  );

  if (time != null) {
    // Timed events: an hour before, so an early start isn't missed.
    yield PlannedNotification(
      at: DateTime(
        day.year,
        day.month,
        day.day,
        e.date.hour,
        e.date.minute,
      ).subtract(const Duration(hours: 1)),
      title: title,
      body: '1 saat sonra · $time',
      payload: payload,
    );
  } else {
    yield PlannedNotification(
      at: DateTime(day.year, day.month, day.day, eventReminderHour),
      title: title,
      body: isBirthday
          ? [
              'Bugün doğum günü! 🎉',
              if (age != null) '$age yaşına giriyor',
            ].join(' · ')
          : 'Bugün',
      payload: payload,
    );
  }
}
