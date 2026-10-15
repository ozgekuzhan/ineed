import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'data/task_repository.dart';
import 'screens/home_screen.dart';
import 'state/settings_store.dart';
import 'state/task_store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');
  final store = TaskStore(TaskRepository());
  final settings = SettingsStore();
  await Future.wait([store.load(), settings.load()]);
  runApp(IneedApp(store: store, settings: settings));
}

class IneedApp extends StatelessWidget {
  const IneedApp({
    super.key,
    required this.store,
    required this.settings,
    this.clock = DateTime.now,
  });

  final TaskStore store;
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
      home: HomeScreen(store: store, settings: settings, clock: clock),
    );
  }
}
