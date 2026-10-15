import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/models/event.dart';
import 'package:ineed/notifications/notification_planner.dart';
import 'package:ineed/notifications/notification_sync.dart';
import 'package:ineed/notifications/notifier.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

class _FakeNotifier implements Notifier {
  int permissionRequests = 0;
  final calls = <List<PlannedNotification>>[];
  bool failNext = false;

  @override
  Future<void> requestPermission() async => permissionRequests++;

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    if (failNext) {
      failNext = false;
      throw Exception('plugin error');
    }
    calls.add(plan);
  }
}

void main() {
  final now = DateTime(2026, 10, 14, 12);
  late TaskStore tasks;
  late EventStore events;
  late SettingsStore settings;
  late _FakeNotifier notifier;
  late NotificationSync sync;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  Future<void> start() async {
    tasks = TaskStore(TaskRepository(), clock: () => now);
    events = EventStore(EventRepository());
    await tasks.load();
    await events.load();
    settings = SettingsStore();
    await settings.load();
    notifier = _FakeNotifier();
    sync = NotificationSync(
      tasks: tasks,
      events: events,
      settings: settings,
      notifier: notifier,
      clock: () => now,
    )..start();
    addTearDown(sync.dispose);
  }

  /// Lets the debounce timer fire and the queued update run.
  Future<void> settle(WidgetTester tester) async {
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
  }

  testWidgets('nothing to remind: no permission prompt', (tester) async {
    await start();
    await settle(tester);
    expect(notifier.calls.single, isEmpty);
    expect(notifier.permissionRequests, 0);
  });

  testWidgets('a task with a deadline schedules reminders', (tester) async {
    await start();
    await tasks.add(title: 'Huur', dueDate: DateTime(2026, 10, 20, 18));
    await settle(tester);

    expect(notifier.permissionRequests, 1);
    expect(notifier.calls.last, hasLength(3));
  });

  testWidgets('completing the task clears its reminders', (tester) async {
    await start();
    await tasks.add(title: 'Huur', dueDate: DateTime(2026, 10, 20, 18));
    await settle(tester);
    await tasks.toggleDone(tasks.openTasks.single);
    await settle(tester);

    expect(notifier.calls.last, isEmpty);
  });

  testWidgets('a burst of edits is one update', (tester) async {
    await start();
    await settle(tester);
    final before = notifier.calls.length;
    for (var i = 0; i < 5; i++) {
      await tasks.add(title: 'T$i', dueDate: DateTime(2026, 10, 20, 18));
    }
    await events.add(
      kind: EventKind.birthday,
      title: 'Ayşe',
      date: DateTime(1990, 10, 20),
    );
    await settle(tester);

    expect(notifier.calls.length, before + 1);
    expect(notifier.calls.last, hasLength(5 * 3 + 4));
    expect(notifier.permissionRequests, 1);
  });

  testWidgets('a failed update does not stop later ones', (tester) async {
    await start();
    await settle(tester);
    notifier.failNext = true;
    await tasks.add(title: 'A', dueDate: DateTime(2026, 10, 20, 18));
    await settle(tester);
    await tasks.add(title: 'B', dueDate: DateTime(2026, 10, 21, 18));
    await settle(tester);

    expect(notifier.calls.last, hasLength(6));
  });

  testWidgets('coming back to the app re-plans', (tester) async {
    await start();
    await settle(tester);
    final before = notifier.calls.length;

    for (final s in [
      AppLifecycleState.inactive,
      AppLifecycleState.hidden,
      AppLifecycleState.paused,
      AppLifecycleState.hidden,
      AppLifecycleState.inactive,
      AppLifecycleState.resumed,
    ]) {
      tester.binding.handleAppLifecycleStateChanged(s);
    }
    await settle(tester);
    expect(notifier.calls.length, before + 1);
  });

  testWidgets('changing the reminder time re-plans at the new time', (
    tester,
  ) async {
    await start();
    await events.add(
      kind: EventKind.birthday,
      title: 'Ayşe',
      date: DateTime(1990, 10, 20),
    );
    await settle(tester);
    expect(notifier.calls.last.first.at, DateTime(2026, 10, 17, 9));

    await settings.setReminderTime((hour: 7, minute: 30));
    await settle(tester);
    expect(notifier.calls.last.first.at, DateTime(2026, 10, 17, 7, 30));
  });
}
