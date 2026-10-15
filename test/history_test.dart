import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/models/dates.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

void main() {
  late DateTime now;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  /// Builds a store with this history (all October 2026):
  /// - "Fiets" created on the 10th, finished on the 12th
  /// - "Huur" created on the 11th, still open
  /// - "Oud" created on the 3rd, finished on the 9th
  Future<TaskStore> storeWithHistory() async {
    final store = TaskStore(TaskRepository(), clock: () => now);
    await store.load();

    now = DateTime(2026, 10, 3, 9);
    await store.add(title: 'Oud');
    now = DateTime(2026, 10, 9, 20);
    await store.toggleDone(store.openTasks.single);

    now = DateTime(2026, 10, 10, 9);
    await store.add(title: 'Fiets');
    now = DateTime(2026, 10, 11, 9);
    await store.add(title: 'Huur', dueDate: DateTime(2026, 10, 11, 18));
    now = DateTime(2026, 10, 12, 21);
    await store.toggleDone(
      store.openTasks.firstWhere((t) => t.title == 'Fiets'),
    );

    now = DateTime(2026, 10, 14, 12);
    return store;
  }

  group('tasksForDay', () {
    test('shows each day as it was', () async {
      final store = await storeWithHistory();
      List<String> titles(int day) => store
          .tasksForDay(DateTime(2026, 10, day))
          .map((t) => t.title)
          .toList();

      expect(titles(2), isEmpty);
      expect(titles(5), ['Oud']);
      expect(titles(9), ['Oud']);
      expect(titles(10), ['Fiets']);
      expect(titles(11), unorderedEquals(['Fiets', 'Huur']));
      expect(titles(12), unorderedEquals(['Fiets', 'Huur']));
      expect(titles(13), ['Huur']);
    });
  });

  group('history screen', () {
    Future<void> open(WidgetTester tester, TaskStore store) async {
      await tester.pumpWidget(
        IneedApp(
          events: EventStore(EventRepository()),
          store: store,
          settings: SettingsStore(),
          clock: () => now,
        ),
      );
      await tester.tap(find.byTooltip('Geçmiş'));
      await tester.pumpAndSettle();
    }

    bool struck(WidgetTester tester, String title) =>
        tester.widget<Text>(find.text(title)).style?.decoration ==
        TextDecoration.lineThrough;

    testWidgets('starts on today', (tester) async {
      final store = await storeWithHistory();
      await open(tester, store);

      expect(find.text('14 Ekim 2026, Çarşamba'), findsOneWidget);
      expect(find.text('Huur'), findsOneWidget);
      expect(find.text('Fiets'), findsNothing);
    });

    testWidgets('a past day shows what was done then, struck through', (
      tester,
    ) async {
      final store = await storeWithHistory();
      await open(tester, store);
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      expect(find.text('12 Ekim 2026, Pazartesi'), findsOneWidget);
      expect(find.text('1 / 2 tamamlandı'), findsOneWidget);
      expect(struck(tester, 'Fiets'), true);
      expect(struck(tester, 'Huur'), false);
      expect(find.text('Oud'), findsNothing);
    });

    testWidgets('a task finished later shows as open on earlier days', (
      tester,
    ) async {
      final store = await storeWithHistory();
      await open(tester, store);
      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();

      expect(struck(tester, 'Fiets'), false);
      expect(find.text('0 / 2 tamamlandı'), findsOneWidget);
    });

    testWidgets('labels are drawn as of that day', (tester) async {
      final store = await storeWithHistory();
      await open(tester, store);
      await tester.tap(find.text('11'));
      await tester.pumpAndSettle();

      // Due 18:00 on the 11th: by the end of that day it was late.
      expect(find.textContaining('Gecikti · Bugün 18:00'), findsOneWidget);
    });

    testWidgets('history is read-only', (tester) async {
      final store = await storeWithHistory();
      await open(tester, store);
      await tester.tap(find.text('12'));
      await tester.pumpAndSettle();

      final box = tester.widget<Checkbox>(
        find.descendant(
          of: find.widgetWithText(ListTile, 'Huur'),
          matching: find.byType(Checkbox),
        ),
      );
      expect(box.onChanged, isNull);
    });

    testWidgets('empty day says so', (tester) async {
      final store = await storeWithHistory();
      await open(tester, store);
      // Nothing existed yet on the 2nd.
      await tester.tap(find.text('2'));
      await tester.pumpAndSettle();

      expect(find.text('Bu gün listede görev yoktu'), findsOneWidget);
    });
  });

  testWidgets('a long day list scrolls on a small phone', (tester) async {
    final store = TaskStore(TaskRepository(), clock: () => now);
    await store.load();
    now = DateTime(2026, 10, 14, 9);
    for (var i = 1; i <= 15; i++) {
      await store.add(title: 'Görev $i');
    }
    tester.view.physicalSize = const Size(750, 1334);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      IneedApp(
        events: EventStore(EventRepository()),
        store: store,
        settings: SettingsStore(),
        clock: () => now,
      ),
    );
    await tester.tap(find.byTooltip('Geçmiş'));
    await tester.pumpAndSettle();

    final finder = find.text('Görev 15');
    await tester.scrollUntilVisible(
      finder,
      200,
      scrollable: find
          .descendant(
            of: find.byType(CustomScrollView),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(finder, findsOneWidget);
  });

  test('localDay keeps the calendar day of a UTC midnight', () {
    expect(localDay(DateTime.utc(2026, 10, 25)), DateTime(2026, 10, 25));
    expect(localDay(DateTime.utc(2026, 3, 29)), DateTime(2026, 3, 29));
  });

  test('Task.compare is total even for identical tasks', () {
    final t = DateTime(2026);
    final a = Task(id: 'a', title: 'x', createdAt: t);
    final b = Task(id: 'b', title: 'x', createdAt: t);
    expect(Task.compare(a, b), lessThan(0));
    expect(Task.compare(b, a), greaterThan(0));
  });
}
