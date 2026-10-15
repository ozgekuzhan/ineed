import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/models/dates.dart';
import 'package:ineed/models/event.dart';
import 'package:ineed/state/event_store.dart';

Event birthday(
  DateTime date, {
  bool hasYear = true,
  String title = 'Ayşe',
  String id = '1',
}) => Event(
  id: id,
  kind: EventKind.birthday,
  title: title,
  date: date,
  hasYear: hasYear,
);

Event event(
  DateTime date, {
  bool yearly = false,
  bool hasTime = false,
  String title = 'Konser',
  String id = '2',
}) => Event(
  id: id,
  kind: EventKind.event,
  title: title,
  date: date,
  yearly: yearly,
  hasTime: hasTime,
);

void main() {
  final today = DateTime(2026, 10, 14, 15, 30);

  group('nextOccurrence', () {
    test('birthday later this year', () {
      expect(
        birthday(DateTime(1990, 11, 2)).nextOccurrence(today),
        DateTime(2026, 11, 2),
      );
    });

    test('birthday today counts as today, whatever the time', () {
      expect(
        birthday(DateTime(1990, 10, 14)).nextOccurrence(today),
        DateTime(2026, 10, 14),
      );
    });

    test('birthday already passed moves to next year', () {
      expect(
        birthday(DateTime(1990, 10, 13)).nextOccurrence(today),
        DateTime(2027, 10, 13),
      );
    });

    test('29 February falls on 28 February in other years', () {
      final b = birthday(DateTime(2000, 2, 29));
      expect(b.nextOccurrence(today), DateTime(2027, 2, 28));
      expect(b.nextOccurrence(DateTime(2027, 3, 1)), DateTime(2028, 2, 29));
      expect(b.occursOn(DateTime(2027, 2, 28)), true);
      expect(b.occursOn(DateTime(2028, 2, 28)), false);
    });

    test('unknown-year 29 February birthday works too', () {
      final b = birthday(
        DateTime(Event.placeholderYear, 2, 29),
        hasYear: false,
      );
      expect(b.nextOccurrence(today), DateTime(2027, 2, 28));
    });

    test('one-time event: upcoming, today, over', () {
      expect(
        event(DateTime(2026, 12, 5)).nextOccurrence(today),
        DateTime(2026, 12, 5),
      );
      expect(
        event(DateTime(2026, 10, 14, 9), hasTime: true).nextOccurrence(today),
        DateTime(2026, 10, 14),
      );
      expect(event(DateTime(2026, 10, 1)).nextOccurrence(today), isNull);
      // Years ahead is still upcoming.
      expect(
        event(DateTime(2028, 5, 1)).nextOccurrence(today),
        DateTime(2028, 5, 1),
      );
    });

    test('yearly event repeats but not before it first happened', () {
      final anniversary = event(DateTime(2020, 6, 1), yearly: true);
      expect(anniversary.nextOccurrence(today), DateTime(2027, 6, 1));
      expect(anniversary.occursOn(DateTime(2019, 6, 1)), false);
      expect(anniversary.occursOn(DateTime(2031, 6, 1)), true);
    });

    test('yearly event that starts in a later year', () {
      expect(
        event(DateTime(2029, 6, 1), yearly: true).nextOccurrence(today),
        DateTime(2029, 6, 1),
      );
    });

    test('a known-year birthday does not appear before birth', () {
      final b = birthday(DateTime(2025, 3, 1));
      expect(b.occursOn(DateTime(2024, 3, 1)), false);
      expect(b.occursOn(DateTime(2025, 3, 1)), true);
    });

    test('unknown-year birthday appears every year', () {
      final b = birthday(DateTime(Event.placeholderYear, 3, 1), hasYear: false);
      expect(b.occursOn(DateTime(1990, 3, 1)), true);
    });
  });

  group('ageOn', () {
    test('age on the birthday when the year is known', () {
      expect(birthday(DateTime(1990, 11, 2)).ageOn(DateTime(2026, 11, 2)), 36);
    });

    test('no age without a year, for events, or in the birth year', () {
      expect(
        birthday(
          DateTime(Event.placeholderYear, 11, 2),
          hasYear: false,
        ).ageOn(DateTime(2026, 11, 2)),
        isNull,
      );
      expect(event(DateTime(2020, 1, 1)).ageOn(DateTime(2026, 1, 1)), isNull);
      expect(
        birthday(DateTime(2026, 1, 1)).ageOn(DateTime(2026, 1, 1)),
        isNull,
      );
    });
  });

  group('daysBetween', () {
    test('ignores the time of day', () {
      expect(daysBetween(today, DateTime(2026, 10, 17)), 3);
      expect(
        daysBetween(DateTime(2026, 10, 14, 23, 59), DateTime(2026, 10, 15)),
        1,
      );
    });

    // Run with TZ=Europe/Amsterdam: these spans include a 23- or 25-hour day.
    test('across clock changes', () {
      expect(daysBetween(DateTime(2026, 10, 23), DateTime(2026, 10, 26)), 3);
      expect(daysBetween(DateTime(2026, 3, 27), DateTime(2026, 3, 30)), 3);
    });
  });

  test('JSON round trip keeps all fields', () {
    final e = Event(
      id: 'x',
      kind: EventKind.event,
      title: 'Koningsdag',
      date: DateTime(2027, 4, 27, 10, 30),
      hasTime: true,
      yearly: true,
      note: 'Vondelpark',
    );
    expect(Event.fromJson(e.toJson()).toJson(), e.toJson());
  });

  group('EventStore', () {
    setUp(() => SharedPreferences.setMockInitialValues({}));

    test(
      'upcoming is sorted soonest first, birthdays first on a day',
      () async {
        final store = EventStore(EventRepository());
        await store.load();
        await store.add(
          kind: EventKind.event,
          title: 'Diner',
          date: DateTime(2026, 11, 2, 19),
          hasTime: true,
        );
        await store.add(
          kind: EventKind.birthday,
          title: 'Mert',
          date: DateTime(1988, 11, 2),
        );
        await store.add(
          kind: EventKind.birthday,
          title: 'Ayşe',
          date: DateTime(1990, 10, 20),
        );
        await store.add(
          kind: EventKind.event,
          title: 'Geçmiş',
          date: DateTime(2026, 1, 1),
        );

        final list = store.upcoming(today);
        expect(list.map((u) => u.event.title), ['Ayşe', 'Mert', 'Diner']);
        expect(list.first.day, DateTime(2026, 10, 20));
      },
    );

    test('events persist', () async {
      final store = EventStore(EventRepository());
      await store.load();
      await store.add(
        kind: EventKind.birthday,
        title: 'Mert',
        date: DateTime(1988, 11, 2),
      );

      final reloaded = EventStore(EventRepository());
      await reloaded.load();
      expect(reloaded.all.single.title, 'Mert');
      expect(reloaded.on(DateTime(2026, 11, 2)).single.title, 'Mert');
    });
  });
}
