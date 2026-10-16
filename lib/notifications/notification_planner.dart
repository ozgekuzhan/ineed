import '../l10n/l10n.dart';
import '../models/dates.dart';
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

/// All reminders after [now], soonest first, capped at
/// [maxPlannedNotifications]. Birthday and event reminders come at
/// [reminderTime]. Texts are in the language of [l10n].
List<PlannedNotification> planNotifications({
  required List<Task> tasks,
  required List<Event> events,
  required DateTime now,
  required AppLocalizations l10n,
  ClockTime reminderTime = (hour: 9, minute: 0),
}) {
  final plan =
      <PlannedNotification>[
        for (final t in tasks) ..._forTask(t, l10n),
        for (final e in events) ..._forEvent(e, now, reminderTime, l10n),
      ].where((n) => n.at.isAfter(now)).toList()..sort((a, b) {
        final byTime = a.at.compareTo(b.at);
        return byTime != 0 ? byTime : a.title.compareTo(b.title);
      });
  return plan.length > maxPlannedNotifications
      ? plan.sublist(0, maxPlannedNotifications)
      : plan;
}

Iterable<PlannedNotification> _forTask(Task t, AppLocalizations l10n) sync* {
  final due = t.dueDate;
  if (t.done || due == null) return;
  final time = l10n.dates.time(due);
  final title = '⏰ ${t.title}';
  final payload = 'task:${t.id}';
  // Same wall-clock time on the previous calendar day (not 24 hours, which
  // is off by an hour across a clock change).
  yield PlannedNotification(
    at: DateTime(due.year, due.month, due.day - 1, due.hour, due.minute),
    title: title,
    body: l10n.notifDueTomorrow(time),
    payload: payload,
  );
  yield PlannedNotification(
    at: due.subtract(const Duration(hours: 1)),
    title: title,
    body: l10n.notifOneHourLeft(time),
    payload: payload,
  );
  yield PlannedNotification(
    at: due,
    title: title,
    body: l10n.notifDueNow,
    payload: payload,
  );
}

Iterable<PlannedNotification> _forEvent(
  Event e,
  DateTime now,
  ClockTime at,
  AppLocalizations l10n,
) sync* {
  final next = e.nextOccurrence(now);
  if (next == null) return;
  yield* _forOccurrence(e, next, at, l10n);
  // Also the one after, in case the app isn't opened for a long while.
  if (e.repeatsYearly) {
    final following = e.dayInYear(next.year + 1);
    if (following != null) yield* _forOccurrence(e, following, at, l10n);
  }
}

Iterable<PlannedNotification> _forOccurrence(
  Event e,
  DateTime day,
  ClockTime at,
  AppLocalizations l10n,
) sync* {
  final isBirthday = e.kind == EventKind.birthday;
  final title = '${isBirthday ? '🎂' : '📅'} ${e.title}';
  final payload = 'event:${e.id}';
  final age = e.ageOn(day);
  final time = e.hasTime && !isBirthday ? l10n.dates.time(e.date) : null;
  final dayText = l10n.dates.dayMonthWeekday(day);

  yield PlannedNotification(
    at: DateTime(day.year, day.month, day.day - 3, at.hour, at.minute),
    title: title,
    body: [
      isBirthday ? l10n.notifBirthdayIn3Days : l10n.notifIn3Days,
      dayText,
      ?time,
      if (age != null) l10n.turnsAge(age),
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
      body: l10n.notifInOneHour(time),
      payload: payload,
    );
  } else {
    yield PlannedNotification(
      at: DateTime(day.year, day.month, day.day, at.hour, at.minute),
      title: title,
      body: isBirthday
          ? [
              l10n.notifBirthdayToday,
              if (age != null) l10n.turnsAge(age),
            ].join(' · ')
          : l10n.today,
      payload: payload,
    );
  }
}
