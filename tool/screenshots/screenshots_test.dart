// Renders the app's real screens with sample data, iPhone-sized, as PNGs.
//
//   flutter test tool/screenshots --update-goldens
//
// Not part of the normal test run (it needs the fonts below on disk).

// Lives outside test/ on purpose, so the analyzer flags the mock prefs.
// ignore_for_file: invalid_use_of_visible_for_testing_member
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/l10n/l10n.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/event.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

const _inter = '/usr/share/fonts/opentype/inter';
const _icons =
    '/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf';

Future<void> _loadFont(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    loader.addFont(File(f).readAsBytes().then((b) => ByteData.view(b.buffer)));
  }
  await loader.load();
}

Future<void> _loadFonts() async {
  final inter = [
    for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold'])
      '$_inter/Inter-$w.otf',
  ];
  // Stand-in for the iPhone system font (SF Pro).
  for (final family in [
    'CupertinoSystemText',
    'CupertinoSystemDisplay',
    '.SF Pro Text',
    '.SF Pro Display',
    'Roboto',
  ]) {
    await _loadFont(family, inter);
  }
  await _loadFont('MaterialIcons', [_icons]);
}

void main() {
  // Thursday 15 October 2026, 10:30 in Amsterdam.
  var now = DateTime(2026, 10, 15, 10, 30);
  late TaskStore tasks;
  late EventStore events;
  late SettingsStore settings;

  /// Language of the current run, and a picker for sample-data texts.
  var lang = AppLanguage.tr;
  String t(String tr, String en) => lang == AppLanguage.tr ? tr : en;
  AppLocalizations l10n() =>
      lookupAppLocalizations(Locale(lang == AppLanguage.tr ? 'tr' : 'en'));

  setUpAll(() async {
    await _loadFonts();
    await initializeDateFormatting('tr');
    await initializeDateFormatting('en');
  });

  setUp(() => SharedPreferences.setMockInitialValues({}));

  Future<void> at(DateTime t, Future<void> Function() action) async {
    now = t;
    await action();
  }

  Future<String> addTask(
    String title, {
    Priority priority = Priority.medium,
    DateTime? due,
    String note = '',
    DateTime? created,
  }) async {
    await at(created ?? DateTime(2026, 10, 10, 9), () async {
      await tasks.add(
        title: title,
        priority: priority,
        dueDate: due,
        note: note,
      );
    });
    return tasks.openTasks.firstWhere((t) => t.title == title).id;
  }

  Future<void> complete(String id, DateTime when) =>
      at(when, () => tasks.toggleDone(tasks.byId(id)!));

  Future<void> seed() async {
    tasks = TaskStore(TaskRepository(), clock: () => now);
    events = EventStore(EventRepository());
    settings = SettingsStore();
    await Future.wait([tasks.load(), events.load(), settings.load()]);
    await settings.setLanguage(lang);

    // Finished on earlier days (show up in history only).
    final ov = await addTask(
      t("OV-chipkaart'a para yükle", 'Top up OV-chipkaart'),
      priority: Priority.low,
      created: DateTime(2026, 10, 11, 8),
    );
    await complete(ov, DateTime(2026, 10, 13, 8, 15));
    final kilit = await addTask(
      t('Bisiklet kilidi al', 'Buy a bike lock'),
      created: DateTime(2026, 10, 12, 19),
    );
    await complete(kilit, DateTime(2026, 10, 13, 17, 40));

    // Today's list.
    await addTask(
      t('Kira ödemesi (huur)', 'Pay the rent (huur)'),
      priority: Priority.high,
      due: DateTime(2026, 10, 15, 18),
    );
    await addTask(
      t('Belastingdienst beyannamesi', 'Belastingdienst tax return'),
      priority: Priority.high,
      due: DateTime(2026, 10, 13, 17),
      note: t('DigiD ile giriş', 'Log in with DigiD'),
    );
    await addTask(
      t('Fiets lastiğini tamir ettir', 'Get the bike tyre fixed'),
      due: DateTime(2026, 10, 16, 12),
      note: t("Vondelstraat'taki dükkan", 'Shop on Vondelstraat'),
    );
    await addTask(
      t('Gemeente randevusu için evrak', 'Papers for the gemeente'),
      due: DateTime(2026, 10, 20, 9, 30),
      note: t('Pasaport + kira kontratı', 'Passport + rental contract'),
    );
    final annem = await addTask(t('Annemi ara', 'Call mum'));
    final ah = await addTask(
      t('Albert Heijn alışverişi', 'Albert Heijn groceries'),
      priority: Priority.low,
      note: t('süt, yumurta, stroopwafel', 'milk, eggs, stroopwafels'),
    );
    await addTask(
      t('Spor salonu üyeliğini yenile', 'Renew gym membership'),
      priority: Priority.low,
      due: DateTime(2026, 10, 31, 12),
    );
    await complete(annem, DateTime(2026, 10, 15, 9, 10));
    await complete(ah, DateTime(2026, 10, 15, 9, 45));

    await events.add(
      kind: EventKind.birthday,
      title: 'Elif',
      date: DateTime(Event.placeholderYear, 10, 15),
      hasYear: false,
    );
    await events.add(
      kind: EventKind.birthday,
      title: t('Annem', 'Mum'),
      date: DateTime(1962, 10, 17),
    );
    await events.add(
      kind: EventKind.event,
      title: t('Concertgebouw konseri', 'Concertgebouw concert'),
      date: DateTime(2026, 10, 24, 20, 15),
      hasTime: true,
      note: t('Biletler e-postada', 'Tickets in email'),
    );
    await events.add(
      kind: EventKind.birthday,
      title: 'Mert',
      date: DateTime(1991, 11, 3),
    );
    await events.add(
      kind: EventKind.event,
      title: t('Ayşe & Can evlilik yıldönümü', "Ayşe & Can's anniversary"),
      date: DateTime(2019, 11, 9),
      yearly: true,
    );
    await events.add(
      kind: EventKind.event,
      title: 'Koningsdag',
      date: DateTime(2014, 4, 27),
      yearly: true,
    );

    now = DateTime(2026, 10, 15, 10, 30);
  }

  Future<void> pumpApp(WidgetTester tester, {bool dark = false}) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
    // Tests draw shadows as solid outlines by default; show real ones.
    debugDisableShadows = false;
    tester.view.physicalSize = const Size(1179, 2556); // iPhone 15/16 Pro
    tester.view.devicePixelRatio = 3;
    tester.view.padding = const FakeViewPadding(top: 59 * 3, bottom: 34 * 3);
    tester.platformDispatcher.platformBrightnessTestValue = dark
        ? Brightness.dark
        : Brightness.light;
    addTearDown(() {
      tester.view.reset();
      tester.platformDispatcher.clearPlatformBrightnessTestValue();
    });
    await tester.pumpWidget(
      IneedApp(
        store: tasks,
        events: events,
        settings: settings,
        clock: () => now,
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> shot(String name) => expectLater(
    find.byType(MaterialApp),
    matchesGoldenFile('raw/${lang.name}/$name.png'),
  );

  Future<void> run(WidgetTester tester, Future<void> Function() body) async {
    await seed();
    try {
      await body();
    } finally {
      debugDefaultTargetPlatformOverride = null;
      debugDisableShadows = true;
    }
  }

  for (final language in [AppLanguage.tr, AppLanguage.en]) {
    group(language.name, () {
      setUp(() => lang = language);

      testWidgets('01 tasks', (tester) async {
        await run(tester, () async {
          await pumpApp(tester);
          await shot('01_gorevler');
        });
      });

      testWidgets('02 tasks dark', (tester) async {
        await run(tester, () async {
          await pumpApp(tester, dark: true);
          await shot('02_gorevler_koyu');
        });
      });

      testWidgets('03 task editor', (tester) async {
        await run(tester, () async {
          await pumpApp(tester);
          await tester.tap(
            find.text(
              t('Fiets lastiğini tamir ettir', 'Get the bike tyre fixed'),
            ),
          );
          await tester.pumpAndSettle();
          await shot('03_gorev_duzenle');
        });
      });

      testWidgets('04 history', (tester) async {
        await run(tester, () async {
          await pumpApp(tester);
          await tester.tap(find.byTooltip(l10n().history));
          await tester.pumpAndSettle();
          await tester.tap(find.text('13'));
          await tester.pumpAndSettle();
          await shot('04_gecmis');
        });
      });

      testWidgets('05 calendar', (tester) async {
        await run(tester, () async {
          await pumpApp(tester);
          await tester.tap(find.text(l10n().tabCalendar));
          await tester.pumpAndSettle();
          await shot('05_takvim');
        });
      });

      testWidgets('06 birthday editor', (tester) async {
        await run(tester, () async {
          await pumpApp(tester);
          await tester.tap(find.text(l10n().tabCalendar));
          await tester.pumpAndSettle();
          await tester.tap(find.text(t('Annem', 'Mum')));
          await tester.pumpAndSettle();
          await shot('06_dogum_gunu');
        });
      });

      testWidgets('07 settings', (tester) async {
        await run(tester, () async {
          await pumpApp(tester);
          await tester.tap(find.byTooltip(l10n().settings));
          await tester.pumpAndSettle();
          await shot('07_ayarlar');
        });
      });
    });
  }
}
