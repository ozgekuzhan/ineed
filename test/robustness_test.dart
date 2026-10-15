import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/state/settings_store.dart';
import 'package:ineed/state/task_store.dart';

/// Repository whose saves finish in whatever order the test chooses.
class _ControlledRepository implements TaskRepository {
  final pending = <Completer<void>>[];
  List<Task>? lastSaved;

  @override
  Future<List<Task>> load() async => [];

  @override
  Future<void> save(List<Task> tasks) {
    final c = Completer<void>();
    pending.add(c);
    return c.future.then((_) => lastSaved = tasks);
  }
}

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  group('TaskRepository.load', () {
    test('survives completely broken data and keeps a backup', () async {
      SharedPreferences.setMockInitialValues({'tasks_v1': 'not json'});
      final tasks = await TaskRepository().load();
      expect(tasks, isEmpty);

      final prefs = await SharedPreferences.getInstance();
      final backups = prefs.getKeys().where(
        (k) => k.startsWith('tasks_v1_unreadable_'),
      );
      expect(backups, hasLength(1));
      expect(prefs.getString(backups.single), 'not json');
    });

    test('backs up broken data only once', () async {
      SharedPreferences.setMockInitialValues({'tasks_v1': 'not json'});
      await TaskRepository().load();
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('tasks_v1'), '[]');

      // Backup keys carry a millisecond stamp; make sure a second backup
      // would get its own key instead of overwriting the first.
      await Future<void>.delayed(const Duration(milliseconds: 5));
      await TaskRepository().load();

      final backups = prefs.getKeys().where(
        (k) => k.startsWith('tasks_v1_unreadable_'),
      );
      expect(backups, hasLength(1));
    });

    test('skips only the broken entry', () async {
      final good = Task(
        id: 'ok',
        title: 'Good',
        createdAt: DateTime(2026, 1, 1),
      ).toJson();
      SharedPreferences.setMockInitialValues({
        'tasks_v1': jsonEncode([
          good,
          {'id': 'bad'},
        ]),
      });
      final tasks = await TaskRepository().load();
      expect(tasks.map((t) => t.id), ['ok']);
    });
  });

  group('TaskStore', () {
    test('saves never finish out of order', () async {
      final repo = _ControlledRepository();
      final store = TaskStore(repo);
      await store.load();

      unawaited(store.add(title: 'first'));
      unawaited(store.add(title: 'second'));
      await Future<void>.delayed(Duration.zero);

      // Only the first save may start; the second waits for it.
      expect(repo.pending, hasLength(1));
      repo.pending[0].complete();
      await Future<void>.delayed(Duration.zero);
      expect(repo.pending, hasLength(2));
      repo.pending[1].complete();
      await Future<void>.delayed(Duration.zero);

      expect(repo.lastSaved!.map((t) => t.title), ['first', 'second']);
    });

    test('a failed save does not block later saves', () async {
      final repo = _ControlledRepository();
      final store = TaskStore(repo);
      await store.load();

      final first = store.add(title: 'first');
      await Future<void>.delayed(Duration.zero);
      repo.pending[0].completeError(Exception('disk full'));
      await expectLater(first, throwsException);

      final second = store.add(title: 'second');
      await Future<void>.delayed(Duration.zero);
      repo.pending[1].complete();
      await second;
      expect(repo.lastSaved, hasLength(2));
    });

    test('toggleDone uses the stored task, not a stale copy', () async {
      final store = TaskStore(TaskRepository());
      await store.load();
      await store.add(title: 'Old title');
      final stale = store.openTasks.single;
      await store.update(stale.copyWith(title: 'New title'));

      await store.toggleDone(stale);
      expect(store.doneTasks.single.title, 'New title');
    });
  });

  testWidgets('double tapping save adds the task once', (tester) async {
    // Saves stay pending, so the second tap lands while the first save is
    // still in progress — the case the guard exists for.
    final repo = _ControlledRepository();
    final store = TaskStore(repo);
    await store.load();
    await tester.pumpWidget(IneedApp(store: store, settings: SettingsStore()));

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Once');
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.tap(find.text('Kaydet'));
    for (final c in repo.pending) {
      c.complete();
    }
    await tester.pumpAndSettle();

    expect(store.openTasks, hasLength(1));
  });

  testWidgets('date picker opens for a task due years ago', (tester) async {
    final store = TaskStore(TaskRepository());
    await store.load();
    await store.add(title: 'Ancient', dueDate: DateTime(2020, 3, 1, 9));
    await tester.pumpWidget(IneedApp(store: store, settings: SettingsStore()));

    await tester.tap(find.text('Ancient'));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.event));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(DatePickerDialog), findsOneWidget);
  });
}
