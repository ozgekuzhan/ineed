enum EventKind {
  birthday('Doğum günü'),
  event('Etkinlik');

  const EventKind(this.label);

  final String label;
}

/// A birthday or an event on the calendar.
class Event {
  const Event({
    required this.id,
    required this.kind,
    required this.title,
    required this.date,
    this.hasYear = true,
    this.hasTime = false,
    this.yearly = false,
    this.note = '',
  });

  final String id;
  final EventKind kind;
  final String title;

  /// The date (and time, if [hasTime]) of the event, or the birth date.
  final DateTime date;

  /// For birthdays: whether the birth year is known (shows the age). When
  /// it isn't, [date] uses [placeholderYear].
  final bool hasYear;

  /// A leap year, so an unknown-year birthday on 29 February can be stored.
  static const placeholderYear = 2000;

  /// For events: whether [date] carries a meaningful time of day.
  final bool hasTime;

  /// For events: repeats every year on the same day (birthdays always do).
  final bool yearly;
  final String note;

  bool get repeatsYearly => kind == EventKind.birthday || yearly;

  /// The calendar day this event falls on in [year], or null when a
  /// one-time event is in another year. A 29 February date falls on
  /// 28 February in years without one.
  DateTime? dayInYear(int year) {
    if (!repeatsYearly) {
      return date.year == year ? DateTime(year, date.month, date.day) : null;
    }
    // Nothing to show before it first happened (or before birth). Without a
    // known birth year, [date] holds a placeholder year.
    final yearKnown = kind == EventKind.event || hasYear;
    if (yearKnown && year < date.year) return null;
    var day = date.day;
    if (date.month == 2 && day == 29 && !_isLeapYear(year)) day = 28;
    return DateTime(year, date.month, day);
  }

  bool occursOn(DateTime day) {
    final d = dayInYear(day.year);
    return d != null && d.month == day.month && d.day == day.day;
  }

  /// The first calendar day on or after [today] this event falls on, or
  /// null for a one-time event that is already over.
  DateTime? nextOccurrence(DateTime today) {
    final from = DateTime(today.year, today.month, today.day);
    if (!repeatsYearly) {
      final d = DateTime(date.year, date.month, date.day);
      return d.isBefore(from) ? null : d;
    }
    // A yearly date that hasn't started yet first happens in its own year.
    final firstYear = date.year > from.year ? date.year : from.year;
    for (final year in [firstYear, firstYear + 1]) {
      final d = dayInYear(year);
      if (d != null && !d.isBefore(from)) return d;
    }
    return null;
  }

  /// Age turned on the birthday that falls on [day], if the year is known.
  int? ageOn(DateTime day) {
    if (kind != EventKind.birthday || !hasYear) return null;
    final age = day.year - date.year;
    return age > 0 ? age : null;
  }

  Event copyWith({
    EventKind? kind,
    String? title,
    DateTime? date,
    bool? hasYear,
    bool? hasTime,
    bool? yearly,
    String? note,
  }) {
    return Event(
      id: id,
      kind: kind ?? this.kind,
      title: title ?? this.title,
      date: date ?? this.date,
      hasYear: hasYear ?? this.hasYear,
      hasTime: hasTime ?? this.hasTime,
      yearly: yearly ?? this.yearly,
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.name,
    'title': title,
    'date': date.toIso8601String(),
    'hasYear': hasYear,
    'hasTime': hasTime,
    'yearly': yearly,
    'note': note,
  };

  factory Event.fromJson(Map<String, dynamic> json) => Event(
    id: json['id'] as String,
    kind: EventKind.values.asNameMap()[json['kind']] ?? EventKind.event,
    title: json['title'] as String,
    date: DateTime.parse(json['date'] as String),
    hasYear: json['hasYear'] as bool? ?? true,
    hasTime: json['hasTime'] as bool? ?? false,
    yearly: json['yearly'] as bool? ?? false,
    note: json['note'] as String? ?? '',
  );
}

bool _isLeapYear(int y) => (y % 4 == 0 && y % 100 != 0) || y % 400 == 0;
