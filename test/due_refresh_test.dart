import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

void main() {
  late DateTime now;
  late TaskStore store;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
    now = DateTime(2026, 10, 14, 17, 59, 30);
  });

  // The store is created inside each test body (not in setUp) so its
  // futures belong to the test's fake-async zone.
  Future<void> createStore() async {
    store = TaskStore(TaskRepository(), clock: () => now);
    await store.load();
  }

  Future<void> pumpApp(WidgetTester tester) => tester.pumpWidget(
    IneedApp(
      events: EventStore(EventRepository()),
      store: store,
      settings: SettingsStore(),
      clock: () => now,
    ),
  );

  testWidgets('label turns overdue when the minute passes', (tester) async {
    await createStore();
    await store.add(title: 'Huur', dueDate: DateTime(2026, 10, 14, 18));
    await pumpApp(tester);
    expect(find.textContaining('Bugün 18:00'), findsOneWidget);
    expect(find.textContaining('Gecikti'), findsNothing);

    now = DateTime(2026, 10, 14, 18, 0, 0, 1);
    await tester.pump(const Duration(seconds: 30));
    expect(find.textContaining('Gecikti · Bugün 18:00'), findsOneWidget);
  });

  testWidgets('labels refresh when the app comes back', (tester) async {
    await createStore();
    await store.add(title: 'Huur', dueDate: DateTime(2026, 10, 15, 9));
    await pumpApp(tester);
    expect(find.textContaining('Yarın 09:00'), findsOneWidget);

    // App sits in the background overnight; no timers ran meanwhile.
    for (final state in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    now = DateTime(2026, 10, 15, 8);
    for (final state in [
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(state);
    }
    await tester.pump();
    expect(find.textContaining('Bugün 09:00'), findsOneWidget);
  });

  testWidgets('done tasks never show as overdue', (tester) async {
    await createStore();
    await store.add(title: 'Huur', dueDate: DateTime(2026, 10, 1, 9));
    await store.toggleDone(store.openTasks.single);
    await pumpApp(tester);

    expect(find.text('Huur'), findsOneWidget);
    expect(find.textContaining('Gecikti'), findsNothing);
  });
}
