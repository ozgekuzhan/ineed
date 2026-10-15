import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/event_repository.dart';
import 'data/task_repository.dart';
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

  final notifier = LocalNotifier();
  try {
    await notifier.init();
    NotificationSync(tasks: store, events: events, notifier: notifier).start();
  } catch (e) {
    // The app works without reminders; don't block start-up on them.
    debugPrint('Reminders unavailable: $e');
  }
  runApp(IneedApp(store: store, events: events, settings: settings));
}

class IneedApp extends StatelessWidget {
  const IneedApp({
    super.key,
    required this.store,
    required this.events,
    required this.settings,
    this.clock = DateTime.now,
  });

  final TaskStore store;
  final EventStore events;
  final SettingsStore settings;

  /// Source of the current time; replaced in tests.
  final DateTime Function() clock;

  @override
  Widget build(BuildContext context) {
    const seed = Color(0xFF4F6D7A);
    return MaterialApp(
      title: 'ineed',
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
