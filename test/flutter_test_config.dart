import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// Runs before every test file: the simulated phone is set to Turkish, so
/// the default "automatic" language shows the Turkish texts the tests
/// expect. English is covered in localization_test.dart.
Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('tr');
  await initializeDateFormatting('en');
  setUp(() {
    binding.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
  });
  await testMain();
}
