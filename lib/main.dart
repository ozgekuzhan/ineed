import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/event_repository.dart';
import 'data/task_repository.dart';
import 'notifications/notification_router.dart';
import 'notifications/notification_sync.dart';
import 'notifications/notifier.dart';
import 'screens/root_screen.dart';
import 'state/event_store.dart';
import 'state/settings_store.dart';
import 'state/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');
  final store = TaskStore(TaskRepository());
  final events = EventStore(EventRepository());
  final settings = SettingsStore();
  await Future.wait([store.load(), events.load(), settings.load()]);
  final navigatorKey = GlobalKey<NavigatorState>();
  final messengerKey = GlobalKey<ScaffoldMessengerState>();
  runApp(
    IneedApp(
      store: store,
      events: events,
      settings: settings,
      navigatorKey: navigatorKey,
      messengerKey: messengerKey,
    ),
  );
  // After the first frame is on its way, so reminders can never delay or
  // block opening the app.
  final router = NotificationRouter(
    navigatorKey: navigatorKey,
    messengerKey: messengerKey,
    tasks: store,
    events: events,
    settings: settings,
  );
  unawaited(_startReminders(store, events, settings, router));
}

Future<void> _startReminders(
  TaskStore tasks,
  EventStore events,
  SettingsStore settings,
  NotificationRouter router,
) async {
  try {
    final notifier = LocalNotifier();
    await notifier.init();
    // Tapping a reminder opens what it is about.
    notifier.taps.listen(router.open);
    final launch = await notifier.launchPayload();
    if (launch != null) router.open(launch);
    NotificationSync(
      tasks: tasks,
      events: events,
      settings: settings,
      notifier: notifier,
    ).start();
  } catch (e) {
    // The app works without reminders.
    debugPrint('Reminders unavailable: $e');
  }
}

class IneedApp extends StatelessWidget {
  const IneedApp({
    super.key,
    required this.store,
    required this.events,
    required this.settings,
    this.navigatorKey,
    this.messengerKey,
    this.clock = DateTime.now,
  });

  final TaskStore store;
  final EventStore events;
  final SettingsStore settings;
  final GlobalKey<NavigatorState>? navigatorKey;
  final GlobalKey<ScaffoldMessengerState>? messengerKey;

  /// Source of the current time; replaced in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F6D7A);
    return MaterialApp(
      title: 'ineed',
      navigatorKey: navigatorKey,
      scaffoldMessengerKey: messengerKey,
      debugShowCheckedModeBanner: false,
      locale: const Locale('tr'),
      supportedLocales: const [Locale('tr')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      theme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.light),
      darkTheme: ThemeData(colorSchemeSeed: seed, brightness: Brightness.dark),
      home: RootScreen(
        tasks: store,
        events: events,
        settings: settings,
        clock: clock,
      ),
    );
  }
}
