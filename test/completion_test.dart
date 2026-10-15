import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

Task _task(String id, {required DateTime created, DateTime? completed}) =>
    Task(id: id, title: id, createdAt: created, completedAt: completed);

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  group('Task day membership', () {
    final day = DateTime(2026, 10, 14);

    test('open task created before or during the day is on the list', () {
      expect(_task('a', created: DateTime(2026, 10, 1)).isOnListOf(day), true);
      expect(
        _task('a', created: DateTime(2026, 10, 14, 23, 59)).isOnListOf(day),
        true,
      );
    });

    test('task created the next day is not', () {
      expect(
        _task('a', created: DateTime(2026, 10, 15)).isOnListOf(day),
        false,
      );
    });

    test('task finished that day is on it, finished earlier is not', () {
      final created = DateTime(2026, 10, 1);
      final doneThatDay = _task(
        'a',
        created: created,
        completed: DateTime(2026, 10, 14, 0, 0),
      );
      expect(doneThatDay.isOnListOf(day), true);
      expect(doneThatDay.wasCompletedOn(day), true);

      final doneDayBefore = _task(
        'b',
        created: created,
        completed: DateTime(2026, 10, 13, 23, 59),
      );
      expect(doneDayBefore.isOnListOf(day), false);
    });

    test('task finished later still shows as open on that day', () {
      final t = _task(
        'a',
        created: DateTime(2026, 10, 1),
        completed: DateTime(2026, 10, 20),
      );
      expect(t.isOnListOf(day), true);
      expect(t.wasCompletedOn(day), false);
    });

    // The 25-hour day when Amsterdam's clocks go back.
    test('completion late on the long autumn day counts for that day', () {
      final t = _task(
        'a',
        created: DateTime(2026, 10, 1),
        completed: DateTime(2026, 10, 25, 23, 30),
      );
      expect(t.isOnListOf(DateTime(2026, 10, 25)), true);
      expect(t.isOnListOf(DateTime(2026, 10, 26)), false);
    });

    test('old data with only a done flag still loads as done', () {
      final t = Task.fromJson({
        'id': 'x',
        'title': 'x',
        'done': true,
        'createdAt': '2026-10-01T09:00:00.000',
      });
      expect(t.done, true);
      expect(t.completedAt, DateTime(2026, 10, 1, 9));
    });
  });

  test('settings are remembered', () async {
    final settings = SettingsStore();
    await settings.load();
    expect(settings.completedBehavior, CompletedBehavior.strikeThrough);
    await settings.setCompletedBehavior(CompletedBehavior.hide);

    final reloaded = SettingsStore();
    await reloaded.load();
    expect(reloaded.completedBehavior, CompletedBehavior.hide);
  });

  test('reminder time is remembered', () async {
    final settings = SettingsStore();
    await settings.load();
    expect(settings.reminderTime, (hour: 9, minute: 0));
    await settings.setReminderTime((hour: 7, minute: 45));

    final reloaded = SettingsStore();
    await reloaded.load();
    expect(reloaded.reminderTime, (hour: 7, minute: 45));
  });

  test('a broken saved reminder time falls back to 09:00', () async {
    SharedPreferences.setMockInitialValues({'settings_reminder_minutes': 9999});
    final settings = SettingsStore();
    await settings.load();
    expect(settings.reminderTime, (hour: 9, minute: 0));
  });

  testWidgets('reminder time can be picked in settings', (tester) async {
    final settings = SettingsStore();
    await settings.load();
    await tester.pumpWidget(
      IneedApp(
        events: EventStore(EventRepository()),
        store: TaskStore(TaskRepository()),
        settings: settings,
      ),
    );
    await tester.tap(find.byTooltip('Ayarlar'));
    await tester.pumpAndSettle();
    expect(find.text('09:00'), findsOneWidget);

    await tester.tap(find.text('Doğum günü ve etkinlik saati'));
    await tester.pumpAndSettle();
    // Switch the picker to typing and enter 07:30.
    await tester.tap(find.byIcon(Icons.keyboard_outlined));
    await tester.pumpAndSettle();
    final fields = find.descendant(
      of: find.byType(TimePickerDialog),
      matching: find.byType(TextField),
    );
    await tester.enterText(fields.at(0), '07');
    await tester.enterText(fields.at(1), '30');
    await tester.tap(find.text('Tamam'));
    await tester.pumpAndSettle();

    expect(settings.reminderTime, (hour: 7, minute: 30));
    expect(find.text('07:30'), findsOneWidget);
  });

  group('today list', () {
    late DateTime now;
    late TaskStore store;
    late SettingsStore settings;

    Future<void> setUpApp(
      WidgetTester tester,
      CompletedBehavior behavior,
    ) async {
      now = DateTime(2026, 10, 14, 23, 40);
      store = TaskStore(TaskRepository(), clock: () => now);
      await store.load();
      settings = SettingsStore();
      await settings.setCompletedBehavior(behavior);
      // Created a few minutes apart so the list order is well defined.
      await store.add(title: 'Boodschappen');
      now = DateTime(2026, 10, 14, 23, 45);
      await store.add(title: 'Sporten');
      now = DateTime(2026, 10, 14, 23, 50);
      await tester.pumpWidget(
        IneedApp(
          events: EventStore(EventRepository()),
          store: store,
          settings: settings,
          clock: () => now,
        ),
      );
    }

    Finder checkboxOf(String title) => find.descendant(
      of: find.widgetWithText(ListTile, title),
      matching: find.byType(Checkbox),
    );

    TextStyle? styleOf(WidgetTester tester, String text) =>
        tester.widget<Text>(find.text(text)).style;

    testWidgets('strike-through: done task stays, struck, with progress', (
      tester,
    ) async {
      await setUpApp(tester, CompletedBehavior.strikeThrough);
      await tester.tap(checkboxOf('Boodschappen'));
      await tester.pump();

      expect(find.text('Boodschappen'), findsOneWidget);
      expect(
        styleOf(tester, 'Boodschappen')?.decoration,
        TextDecoration.lineThrough,
      );
      expect(find.text('Bugün 1 / 2 tamamlandı'), findsOneWidget);
      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('strike-through: done task keeps its place', (tester) async {
      await setUpApp(tester, CompletedBehavior.strikeThrough);
      await tester.tap(checkboxOf('Boodschappen'));
      await tester.pump();

      final first = tester.getTopLeft(find.text('Boodschappen')).dy;
      final second = tester.getTopLeft(find.text('Sporten')).dy;
      expect(first, lessThan(second));
    });

    testWidgets('next day only unfinished tasks remain', (tester) async {
      await setUpApp(tester, CompletedBehavior.strikeThrough);
      await tester.tap(checkboxOf('Boodschappen'));
      await tester.pump();
      expect(find.text('Boodschappen'), findsOneWidget);

      now = DateTime(2026, 10, 15, 0, 0, 30);
      await tester.pump(const Duration(minutes: 10));

      expect(find.text('Boodschappen'), findsNothing);
      expect(find.text('Sporten'), findsOneWidget);
      expect(find.textContaining('tamamlandı'), findsNothing);
    });

    testWidgets('hide: done task leaves the list and can be undone', (
      tester,
    ) async {
      await setUpApp(tester, CompletedBehavior.hide);
      await tester.tap(checkboxOf('Boodschappen'));
      await tester.pump();

      expect(find.text('Boodschappen'), findsNothing);
      expect(find.text('"Boodschappen" tamamlandı'), findsOneWidget);

      // Let the snack bar finish sliding in before tapping its button.
      await tester.pump(const Duration(seconds: 1));
      await tester.tap(find.text('Geri al'));
      await tester.pump();
      expect(find.text('Boodschappen'), findsOneWidget);
      expect(store.openTasks, hasLength(2));
    });

    testWidgets('hide: all done shows a celebration', (tester) async {
      await setUpApp(tester, CompletedBehavior.hide);
      await tester.tap(checkboxOf('Boodschappen'));
      await tester.pump();
      await tester.tap(checkboxOf('Sporten'));
      await tester.pump();

      expect(find.text('Hepsi tamam 🎉'), findsOneWidget);
      expect(find.text('Bugün 2 görev tamamladın'), findsOneWidget);
    });

    testWidgets('changing the setting updates the list', (tester) async {
      await setUpApp(tester, CompletedBehavior.strikeThrough);
      await tester.tap(checkboxOf('Boodschappen'));
      await tester.pump();

      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Listeden kalksın'));
      await tester.pump();
      expect(settings.completedBehavior, CompletedBehavior.hide);

      tester.state<NavigatorState>(find.byType(Navigator)).pop();
      await tester.pumpAndSettle();
      expect(find.text('Boodschappen'), findsNothing);
      expect(find.text('Sporten'), findsOneWidget);
    });
  });
}
