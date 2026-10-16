import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/event_repository.dart';
import 'package:ineed/data/task_repository.dart';
import 'package:ineed/l10n/l10n.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/event.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/notifications/notification_planner.dart';
import 'package:ineed/notifications/notification_sync.dart';
import 'package:ineed/notifications/notifier.dart';
import 'package:ineed/state/event_store.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

class _FakeNotifier implements Notifier {
  final calls = <List<PlannedNotification>>[];

  @override
  Future<void> requestPermission() async {}

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async =>
      calls.add(plan);
}

void main() {
  final en = lookupAppLocalizations(const Locale('en'));
  final tr = lookupAppLocalizations(const Locale('tr'));
  // Wednesday 14 October 2026, 12:00.
  final now = DateTime(2026, 10, 14, 12);

  setUp(() => SharedPreferences.setMockInitialValues({}));

  group('resolveLocale', () {
    test('explicit choices win over the phone', () {
      expect(
        resolveLocale(AppLanguage.en, const [Locale('tr')]).languageCode,
        'en',
      );
      expect(
        resolveLocale(AppLanguage.tr, const [Locale('en')]).languageCode,
        'tr',
      );
    });

    test('automatic follows the first supported phone language', () {
      expect(
        resolveLocale(AppLanguage.system, const [
          Locale('nl', 'NL'),
          Locale('tr', 'TR'),
        ]).languageCode,
        'tr',
      );
      expect(
        resolveLocale(AppLanguage.system, const [
          Locale('en', 'GB'),
        ]).languageCode,
        'en',
      );
    });

    test('automatic falls back to English (e.g. a Dutch-only phone)', () {
      expect(
        resolveLocale(AppLanguage.system, const [
          Locale('nl', 'NL'),
        ]).languageCode,
        'en',
      );
      expect(resolveLocale(AppLanguage.system, const []).languageCode, 'en');
    });
  });

  test('both translations have the same keys and placeholders', () {
    Map<String, dynamic> read(String f) =>
        jsonDecode(File('lib/l10n/$f').readAsStringSync())
            as Map<String, dynamic>;
    final enArb = read('app_en.arb');
    final trArb = read('app_tr.arb');
    final keys = enArb.keys.where((k) => !k.startsWith('@')).toSet();
    final trKeys = trArb.keys.where((k) => !k.startsWith('@')).toSet();
    expect(trKeys, keys);

    final placeholder = RegExp(r'\{(\w+)[,}]');
    for (final k in keys) {
      Set<String> names(String text) =>
          placeholder.allMatches(text).map((m) => m.group(1)!).toSet();
      expect(
        names(trArb[k] as String),
        names(enArb[k] as String),
        reason: 'placeholders of "$k"',
      );
    }
  });

  group('English texts', () {
    test('plurals', () {
      expect(en.allDoneSubtitle(1), 'You finished 1 task today');
      expect(en.allDoneSubtitle(3), 'You finished 3 tasks today');
      expect(en.inDays(1), 'in 1 day');
      expect(en.inDays(5), 'in 5 days');
      expect(en.daysAgo(2), '2 days ago');
      expect(tr.inDays(5), '5 gün sonra');
    });

    test('due dates', () {
      expect(en.dueText(DateTime(2026, 10, 14, 18), now), 'Today 18:00');
      expect(en.dueText(DateTime(2026, 10, 15, 9), now), 'Tomorrow 09:00');
      expect(en.dueText(DateTime(2026, 10, 13, 9), now), 'Yesterday 09:00');
      expect(en.dueText(DateTime(2026, 10, 17, 18), now), 'Sat 17 Oct 18:00');
      expect(en.dueText(DateTime(2027, 1, 3, 9), now), '3 Jan 2027 09:00');
      expect(tr.dueText(DateTime(2026, 10, 17, 18), now), '17 Eki Cmt 18:00');
    });

    test('reminders', () {
      final p = planNotifications(
        tasks: [
          Task(
            id: 't',
            title: 'Rent',
            dueDate: DateTime(2026, 10, 20, 18),
            createdAt: DateTime(2026, 10, 1),
          ),
        ],
        events: [
          Event(
            id: 'b',
            kind: EventKind.birthday,
            title: 'Ayse',
            date: DateTime(1990, 10, 20),
          ),
        ],
        now: now,
        l10n: en,
      );
      final bodies = p.map((n) => n.body).toList();
      expect(bodies, contains('Due tomorrow 18:00'));
      expect(bodies, contains('1 hour left · 18:00'));
      expect(bodies, contains('Due now'));
      expect(
        bodies,
        contains('Birthday in 3 days · Tuesday 20 October · turns 36'),
      );
      expect(bodies, contains('Birthday today! 🎉 · turns 36'));
    });
  });

  testWidgets('reminders follow the language setting', (tester) async {
    final tasks = TaskStore(TaskRepository(), clock: () => now);
    final events = EventStore(EventRepository());
    final settings = SettingsStore();
    await Future.wait([tasks.load(), events.load(), settings.load()]);
    await tasks.add(title: 'Rent', dueDate: DateTime(2026, 10, 20, 18));
    final notifier = _FakeNotifier();
    final sync = NotificationSync(
      tasks: tasks,
      events: events,
      settings: settings,
      notifier: notifier,
      clock: () => now,
      deviceLocales: () => const [Locale('tr')],
    )..start();
    addTearDown(sync.dispose);

    await tester.pump(const Duration(seconds: 1));
    expect(notifier.calls.last.last.body, 'Son tarih şimdi');

    await settings.setLanguage(AppLanguage.en);
    await tester.pump(const Duration(seconds: 1));
    expect(notifier.calls.last.last.body, 'Due now');
  });

  group('app in English', () {
    late TaskStore tasks;
    late EventStore events;
    late SettingsStore settings;

    Future<void> pumpApp(
      WidgetTester tester, {
      AppLanguage language = AppLanguage.en,
    }) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);
      tasks = TaskStore(TaskRepository(), clock: () => now);
      events = EventStore(EventRepository());
      settings = SettingsStore();
      await Future.wait([tasks.load(), events.load(), settings.load()]);
      await settings.setLanguage(language);
      // ASCII-only sample data, so any Turkish letter on screen must come
      // from an untranslated text.
      await tasks.add(
        title: 'Pay rent',
        priority: Priority.high,
        dueDate: DateTime(2026, 10, 13, 17),
        note: 'Bank app',
      );
      await tasks.add(
        title: 'Bike repair',
        dueDate: DateTime(2026, 10, 15, 12),
      );
      await tasks.add(title: 'Groceries');
      await tasks.toggleDone(
        tasks.openTasks.firstWhere((t) => t.title == 'Groceries'),
      );
      await events.add(
        kind: EventKind.birthday,
        title: 'Mum',
        date: DateTime(1962, 10, 17),
      );
      await events.add(
        kind: EventKind.event,
        title: 'Concert',
        date: DateTime(2026, 10, 24, 20, 15),
        hasTime: true,
      );
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

    final turkishLetters = RegExp('[ğĞıİşŞçÇöÖüÜ]');

    /// Every text on screen, from Text and RichText widgets.
    List<String> screenTexts(WidgetTester tester) => [
      for (final w in tester.widgetList<RichText>(find.byType(RichText)))
        w.text.toPlainText(),
    ];

    void expectNoTurkish(WidgetTester tester, String screen) {
      final leftovers = screenTexts(tester)
          .where((t) => turkishLetters.hasMatch(t))
          .toList();
      expect(leftovers, isEmpty, reason: 'Turkish text on $screen');
    }

    testWidgets('no Turkish text on any screen', (tester) async {
      await pumpApp(tester);

      expect(find.text('To-do'), findsOneWidget);
      expect(find.text('Tasks'), findsOneWidget);
      expect(find.textContaining('Overdue · Yesterday 17:00'), findsOneWidget);
      expect(find.textContaining('Tomorrow 12:00'), findsOneWidget);
      expect(find.text('Today 1 / 3 done'), findsOneWidget);
      expectNoTurkish(tester, 'tasks');

      await tester.tap(find.text('Bike repair'));
      await tester.pumpAndSettle();
      expect(find.text('Edit task'), findsOneWidget);
      expectNoTurkish(tester, 'task editor');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('History'));
      await tester.pumpAndSettle();
      expect(find.text('Wednesday 14 October 2026'), findsOneWidget);
      expectNoTurkish(tester, 'history');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('Settings'));
      await tester.pumpAndSettle();
      expect(find.text('Language'), findsOneWidget);
      // The one allowed exception: the language's own name.
      final settingsTexts = screenTexts(tester)
          .where((t) => turkishLetters.hasMatch(t) && t != 'Türkçe');
      expect(settingsTexts, isEmpty);
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calendar'));
      await tester.pumpAndSettle();
      expect(find.text('Upcoming'), findsOneWidget);
      expect(find.text('in 3 days'), findsOneWidget);
      expect(find.textContaining('turns 64'), findsOneWidget);
      expect(find.text('Mon'), findsOneWidget);
      expectNoTurkish(tester, 'calendar');

      await tester.tap(find.text('Mum'));
      await tester.pumpAndSettle();
      expect(find.text('Whose birthday?'), findsOneWidget);
      expectNoTurkish(tester, 'birthday editor');
      await tester.pageBack();
      await tester.pumpAndSettle();

      await tester.tap(find.byTooltip('New birthday / event'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Event'));
      await tester.pumpAndSettle();
      expect(find.text('Event name'), findsOneWidget);
      expectNoTurkish(tester, 'event editor');
    });

    testWidgets('changing the language updates the app at once', (
      tester,
    ) async {
      await pumpApp(tester, language: AppLanguage.tr);
      expect(find.text('Yapılacaklar'), findsOneWidget);

      await tester.tap(find.byTooltip('Ayarlar'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('English'));
      await tester.pumpAndSettle();
      expect(find.text('Settings'), findsOneWidget);
      expect(settings.language, AppLanguage.en);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('To-do'), findsOneWidget);
    });

    testWidgets('automatic uses the phone language', (tester) async {
      tester.platformDispatcher.localesTestValue = const [Locale('en', 'GB')];
      await pumpApp(tester, language: AppLanguage.system);
      expect(find.text('To-do'), findsOneWidget);

      tester.platformDispatcher.localesTestValue = const [Locale('tr', 'TR')];
      await tester.pumpAndSettle();
      expect(find.text('Yapılacaklar'), findsOneWidget);
    });

    testWidgets('the language choice is remembered', (tester) async {
      await pumpApp(tester);
      final reloaded = SettingsStore();
      await reloaded.load();
      expect(reloaded.language, AppLanguage.en);
    });
  });
}
