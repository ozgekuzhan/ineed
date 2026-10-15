import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:ineed/models/event.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/notifications/notification_planner.dart';

void main() {
  setUpAll(() => initializeDateFormatting('tr'));

  final now = DateTime(2026, 10, 14, 12);

  Task task(DateTime? due, {DateTime? completed, String id = 't'}) => Task(
    id: id,
    title: 'Belasting',
    dueDate: due,
    completedAt: completed,
    createdAt: DateTime(2026, 10, 1),
  );

  List<PlannedNotification> plan({
    List<Task> tasks = const [],
    List<Event> events = const [],
    DateTime? at,
  }) => planNotifications(tasks: tasks, events: events, now: at ?? now);

  group('tasks', () {
    test('a day before, an hour before, and at the deadline', () {
      final p = plan(tasks: [task(DateTime(2026, 10, 20, 18))]);
      expect(p.map((n) => n.at), [
        DateTime(2026, 10, 19, 18),
        DateTime(2026, 10, 20, 17),
        DateTime(2026, 10, 20, 18),
      ]);
      expect(p.first.title, '⏰ Belasting');
      expect(p.map((n) => n.body), [
        'Son tarih yarın 18:00',
        '1 saat kaldı · 18:00',
        'Son tarih şimdi',
      ]);
      expect(p.first.payload, 'task:t');
    });

    test('reminders already in the past are skipped', () {
      final p = plan(tasks: [task(DateTime(2026, 10, 14, 12, 30))]);
      expect(p.map((n) => n.body), ['Son tarih şimdi']);
    });

    test('done tasks and tasks without a date get none', () {
      expect(
        plan(
          tasks: [
            task(DateTime(2026, 10, 20, 18), completed: now),
            task(null),
          ],
        ),
        isEmpty,
      );
    });

    // With TZ=Europe/Amsterdam: clocks go back at 03:00 on 25 Oct, so
    // 24 hours before 25 Oct 18:00 is 24 Oct 19:00. "A day before" must
    // stay at 18:00.
    test('a day before keeps the wall-clock time across a clock change', () {
      final p = plan(tasks: [task(DateTime(2026, 10, 25, 18))]);
      expect(p.first.at, DateTime(2026, 10, 24, 18));
      expect(p.first.at.hour, 18);
    });
  });

  group('birthdays and events', () {
    test('birthday: 3 days before and on the day at 09:00, with age', () {
      final p = plan(
        events: [
          Event(
            id: 'b',
            kind: EventKind.birthday,
            title: 'Ayşe',
            date: DateTime(1990, 10, 20),
          ),
        ],
      );
      expect(p.take(2).map((n) => n.at), [
        DateTime(2026, 10, 17, 9),
        DateTime(2026, 10, 20, 9),
      ]);
      expect(p[0].title, '🎂 Ayşe');
      expect(
        p[0].body,
        'Doğum günü 3 gün sonra · 20 Ekim Salı · 36 yaşına giriyor',
      );
      expect(p[1].body, 'Bugün doğum günü! 🎉 · 36 yaşına giriyor');
      expect(p[0].payload, 'event:b');
    });

    test('yearly entries also plan the following year', () {
      final p = plan(
        events: [
          Event(
            id: 'b',
            kind: EventKind.birthday,
            title: 'Ayşe',
            date: DateTime(1990, 10, 20),
          ),
        ],
      );
      expect(p.map((n) => n.at), [
        DateTime(2026, 10, 17, 9),
        DateTime(2026, 10, 20, 9),
        DateTime(2027, 10, 17, 9),
        DateTime(2027, 10, 20, 9),
      ]);
      expect(p[3].body, contains('37 yaşına giriyor'));
    });

    test('birthday today: 3-day reminder is past, on-the-day still ahead', () {
      final p = plan(
        at: DateTime(2026, 10, 20, 8),
        events: [
          Event(
            id: 'b',
            kind: EventKind.birthday,
            title: 'Ayşe',
            date: DateTime(Event.placeholderYear, 10, 20),
            hasYear: false,
          ),
        ],
      );
      expect(p.first.at, DateTime(2026, 10, 20, 9));
      expect(p.first.body, 'Bugün doğum günü! 🎉');
    });

    test('timed event: on the day an hour before the start', () {
      final p = plan(
        events: [
          Event(
            id: 'e',
            kind: EventKind.event,
            title: 'Concert',
            date: DateTime(2026, 10, 30, 20, 30),
            hasTime: true,
          ),
        ],
      );
      expect(p.map((n) => n.at), [
        DateTime(2026, 10, 27, 9),
        DateTime(2026, 10, 30, 19, 30),
      ]);
      expect(p[0].title, '📅 Concert');
      expect(p[0].body, '3 gün sonra · 30 Ekim Cuma · 20:30');
      expect(p[1].body, '1 saat sonra · 20:30');
    });

    test('past one-time events get nothing', () {
      expect(
        plan(
          events: [
            Event(
              id: 'e',
              kind: EventKind.event,
              title: 'Old',
              date: DateTime(2026, 9, 1),
            ),
          ],
        ),
        isEmpty,
      );
    });

    test('3 days before a 1 March birthday crosses into February', () {
      final p = plan(
        events: [
          Event(
            id: 'b',
            kind: EventKind.birthday,
            title: 'Can',
            date: DateTime(1995, 3, 1),
          ),
        ],
      );
      expect(p.first.at, DateTime(2027, 2, 26, 9));
    });
  });

  test('birthday and event reminders use the chosen time', () {
    final p = planNotifications(
      tasks: const [],
      events: [
        Event(
          id: 'b',
          kind: EventKind.birthday,
          title: 'Ayşe',
          date: DateTime(1990, 10, 20),
        ),
      ],
      now: now,
      reminderTime: (hour: 20, minute: 15),
    );
    expect(p.take(2).map((n) => n.at), [
      DateTime(2026, 10, 17, 20, 15),
      DateTime(2026, 10, 20, 20, 15),
    ]);
  });

  test('keeps only the soonest 60, in time order', () {
    final tasks = [
      for (var i = 0; i < 40; i++)
        task(DateTime(2026, 11, 1 + i % 28, 10 + i % 8), id: '$i'),
    ];
    final p = plan(tasks: tasks);
    expect(p, hasLength(maxPlannedNotifications));
    for (var i = 1; i < p.length; i++) {
      expect(p[i].at.isBefore(p[i - 1].at), false);
    }
    // The very first reminder (the day before task 0, due 1 Nov 10:00)
    // must be kept, i.e. the cap drops from the far end.
    expect(p.first.at, DateTime(2026, 10, 31, 10));
  });
}
