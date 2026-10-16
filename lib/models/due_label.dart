enum DueStatus { overdue, today, tomorrow, later }

/// Calendar-day helpers use the date constructor instead of adding
/// `Duration(days: 1)`, so 23- and 25-hour days around daylight saving
/// changes (late March / late October in Amsterdam) are handled correctly.
DateTime _day(DateTime t) => DateTime(t.year, t.month, t.day);

bool _sameDay(DateTime a, DateTime b) => _day(a) == _day(b);

/// Time left until the next full minute; always in (0, 1 minute].
///
/// Computed from the seconds within the minute rather than by building the
/// next minute's local time: in the repeated hour when clocks go back
/// (e.g. 02:00–03:00 on 25 Oct 2026 in Amsterdam) that local time can
/// resolve to the earlier occurrence and give a negative delay.
Duration untilNextMinute(DateTime now) {
  final intoMinute = Duration(
    seconds: now.second,
    milliseconds: now.millisecond,
    microseconds: now.microsecond,
  );
  return const Duration(minutes: 1) - intoMinute;
}

DueStatus dueStatus(DateTime due, DateTime now) {
  if (due.isBefore(now)) return DueStatus.overdue;
  if (_sameDay(due, now)) return DueStatus.today;
  if (_sameDay(due, DateTime(now.year, now.month, now.day + 1))) {
    return DueStatus.tomorrow;
  }
  return DueStatus.later;
}
