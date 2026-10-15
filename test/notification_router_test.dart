import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/event.dart';
import 'package:ineed/notifications/notification_router.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

void main() {
  final now = DateTime(2026, 10, 14, 12);
  late TaskStore tasks;
  late EventStore events;
  late SettingsStore settings;
  late NotificationRouter router;
  late GlobalKey<NavigatorState> navigatorKey;
  late GlobalKey<ScaffoldMessengerState> messengerKey;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  Future<void> createStores() async {
    tasks = TaskStore(TaskRepository(), clock: () => now);
    events = EventStore(EventRepository());
    settings = SettingsStore();
    await Future.wait([tasks.load(), events.load(), settings.load()]);
    navigatorKey = GlobalKey<NavigatorState>();
    messengerKey = GlobalKey<ScaffoldMessengerState>();
    router = NotificationRouter(
      navigatorKey: navigatorKey,
      messengerKey: messengerKey,
      tasks: tasks,
      events: events,
      settings: settings,
      clock: () => now,
    );
  }

  Widget app() => IneedApp(
    store: tasks,
    events: events,
    settings: settings,
    navigatorKey: navigatorKey,
    messengerKey: messengerKey,
    clock: () => now,
  );

  testWidgets('a task reminder opens that task', (tester) async {
    await createStores();
    await tasks.add(title: 'Belasting', dueDate: DateTime(2026, 10, 20, 18));
    await tasks.add(title: 'Other');
    await tester.pumpWidget(app());

    final id = tasks.openTasks.firstWhere((t) => t.title == 'Belasting').id;
    router.open('task:$id');
    await tester.pumpAndSettle();

    expect(find.text('Görevi düzenle'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Belasting'), findsOneWidget);
  });

  testWidgets('a birthday reminder opens that entry', (tester) async {
    await createStores();
    final event = await events.add(
      kind: EventKind.birthday,
      title: 'Ayşe',
      date: DateTime(1990, 10, 20),
    );
    await tester.pumpWidget(app());

    router.open('event:${event.id}');
    await tester.pumpAndSettle();

    expect(find.text('Düzenle'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Ayşe'), findsOneWidget);
  });

  testWidgets('a deleted item shows a short message', (tester) async {
    await createStores();
    await tester.pumpWidget(app());

    router.open('task:gone');
    await tester.pump();

    expect(find.text('Bu kayıt artık yok (silinmiş).'), findsOneWidget);
    expect(find.text('Görevi düzenle'), findsNothing);
  });

  testWidgets('a malformed payload is ignored', (tester) async {
    await createStores();
    await tester.pumpWidget(app());

    for (final payload in ['', 'task', ':x', 'other:1', 'task:']) {
      router.open(payload);
    }
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Görevi düzenle'), findsNothing);
  });

  testWidgets('a tap that arrives while the app starts still opens it', (
    tester,
  ) async {
    await createStores();
    await tasks.add(title: 'Belasting');
    final id = tasks.openTasks.single.id;

    // Navigator not built yet.
    router.open('task:$id');
    await tester.pumpWidget(app());
    await tester.pumpAndSettle();

    expect(find.text('Görevi düzenle'), findsOneWidget);
  });

  testWidgets('a task can be completed from its editor', (tester) async {
    await createStores();
    await tasks.add(title: 'Belasting');
    final id = tasks.openTasks.single.id;
    await tester.pumpWidget(app());

    router.open('task:$id');
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Belasting 2026');
    await tester.tap(find.text('Tamamlandı olarak işaretle'));
    await tester.pumpAndSettle();

    final task = tasks.byId(id)!;
    expect(task.done, true);
    // Edits made before tapping are kept.
    expect(task.title, 'Belasting 2026');
    expect(find.text('Görevi düzenle'), findsNothing);
  });

  testWidgets('a done task can be reopened from its editor', (tester) async {
    await createStores();
    await tasks.add(title: 'Belasting');
    final id = tasks.openTasks.single.id;
    await tasks.toggleDone(tasks.byId(id)!);
    await tester.pumpWidget(app());

    router.open('task:$id');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tamamlanmadı olarak işaretle'));
    await tester.pumpAndSettle();

    expect(tasks.byId(id)!.done, false);
  });
}
