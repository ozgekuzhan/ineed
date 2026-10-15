/// The calendar day of [d] as a local midnight. Also turns the UTC
/// midnights handed out by the calendar package into local days.
DateTime localDay(DateTime d) => DateTime(d.year, d.month, d.day);

/// Whole calendar days from [from] to [to], ignoring the time of day and
/// unaffected by daylight-saving changes.
int daysBetween(DateTime from, DateTime to) => DateTime.utc(
  to.year,
  to.month,
  to.day,
).difference(DateTime.utc(from.year, from.month, from.day)).inDays;

/// A time of day, without the Material dependency of TimeOfDay.
typedef ClockTime = ({int hour, int minute});

/// "09:05"-style text for a [ClockTime].
String formatClockTime(ClockTime t) =>
    '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
