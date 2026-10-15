import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/event.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

void main() {
  // Wednesday 14 October 2026.
  final now = DateTime(2026, 10, 14, 12);
  late EventStore events;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  Future<void> openCalendar(WidgetTester tester) async {
    // iPhone-sized screen.
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      IneedApp(
        store: TaskStore(TaskRepository(), clock: () => now),
        events: events,
        settings: SettingsStore(),
        clock: () => now,
      ),
    );
    await tester.tap(find.text('Takvim'));
    await tester.pumpAndSettle();
  }

  Future<void> seed() async {
    events = EventStore(EventRepository());
    await events.load();
    await events.add(
      kind: EventKind.birthday,
      title: 'Mert',
      date: DateTime(1990, 10, 17),
    );
    await events.add(
      kind: EventKind.event,
      title: 'Concert',
      date: DateTime(2026, 10, 15, 20, 30),
      hasTime: true,
    );
    await events.add(
      kind: EventKind.birthday,
      title: 'Elif',
      date: DateTime(Event.placeholderYear, 10, 14),
      hasYear: false,
    );
  }

  testWidgets('upcoming list: soonest first with countdowns and age', (
    tester,
  ) async {
    await seed();
    await openCalendar(tester);

    expect(find.text('Yaklaşanlar'), findsOneWidget);
    final elif = tester.getTopLeft(find.text('Elif')).dy;
    final concert = tester.getTopLeft(find.text('Concert')).dy;
    final mert = tester.getTopLeft(find.text('Mert')).dy;
    expect(elif, lessThan(concert));
    expect(concert, lessThan(mert));

    expect(find.text('Bugün'), findsOneWidget);
    expect(find.text('Yarın'), findsOneWidget);
    expect(find.text('3 gün sonra'), findsOneWidget);
    expect(find.textContaining('36 yaşına giriyor'), findsOneWidget);
    expect(find.textContaining('20:30'), findsOneWidget);
  });

  testWidgets('tapping a day shows that day; tapping again goes back', (
    tester,
  ) async {
    await seed();
    await openCalendar(tester);

    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();
    expect(find.text('17 Ekim 2026, Cumartesi'), findsOneWidget);
    expect(find.text('Mert'), findsOneWidget);
    expect(find.text('Concert'), findsNothing);

    await tester.tap(find.text('17'));
    await tester.pumpAndSettle();
    expect(find.text('Concert'), findsOneWidget);
  });

  testWidgets('add a birthday on the tapped day', (tester) async {
    events = EventStore(EventRepository());
    await events.load();
    await openCalendar(tester);
    expect(find.textContaining('Henüz kayıt yok'), findsOneWidget);

    await tester.tap(find.text('20'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Yeni doğum günü / etkinlik'));
    await tester.pumpAndSettle();

    // The tapped day is already filled in.
    expect(find.text('20 Ekim 2026'), findsOneWidget);
    await tester.enterText(find.byType(TextField).first, 'Zeynep');
    await tester.tap(find.text('Doğum yılını bilmiyorum'));
    await tester.pump();
    // Turning the year off keeps the day; the year is no longer shown.
    expect(find.text('20 Ekim'), findsOneWidget);
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    final saved = events.all.single;
    expect(saved.kind, EventKind.birthday);
    expect(saved.hasYear, false);
    expect(saved.date, DateTime(Event.placeholderYear, 10, 20));
    expect(find.text('Zeynep'), findsOneWidget);
  });

  testWidgets('turning a known year back on asks for the date again', (
    tester,
  ) async {
    await seed();
    await openCalendar(tester);
    await tester.tap(find.text('Elif'));
    await tester.pumpAndSettle();

    expect(find.text('14 Ekim'), findsOneWidget);
    await tester.tap(find.text('Doğum yılını bilmiyorum'));
    await tester.pump();
    expect(find.text('Tarih seç'), findsOneWidget);
    final save = tester.widget<TextButton>(
      find.widgetWithText(TextButton, 'Kaydet'),
    );
    expect(save.onPressed, isNull);
  });

  testWidgets('delete asks first', (tester) async {
    await seed();
    await openCalendar(tester);
    await tester.tap(find.text('Mert'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Vazgeç'));
    await tester.pumpAndSettle();
    expect(events.all, hasLength(3));

    await tester.tap(find.byTooltip('Sil'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sil'));
    await tester.pumpAndSettle();
    expect(events.all.map((e) => e.title), isNot(contains('Mert')));
    expect(find.text('Mert'), findsNothing);
  });

  testWidgets('switching tabs keeps the task list working', (tester) async {
    await seed();
    await openCalendar(tester);
    await tester.tap(find.text('Görevler'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Yeni görev'));
    await tester.pumpAndSettle();
    expect(find.text('Yeni görev'), findsOneWidget);
  });

  testWidgets('long lists scroll on a small phone', (tester) async {
    events = EventStore(EventRepository());
    await events.load();
    for (var i = 1; i <= 12; i++) {
      await events.add(
        kind: EventKind.birthday,
        title: 'Kişi $i',
        date: DateTime(1990, 11, i),
      );
    }
    await openCalendar(tester);
    // iPhone SE size.
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('Kişi 12'),
      200,
      // The page's vertical scroll view, not the calendar's month pager.
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.text('Kişi 12'), findsOneWidget);
  });
}
