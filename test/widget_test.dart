import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ineed/data/task_repository.dart';
import 'package:ineed/main.dart';
import 'package:ineed/models/task.dart';
import 'package:ineed/state/task_store.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await initializeDateFormatting('tr');
  });

  group('Task', () {
    test('JSON round trip keeps all fields', () {
      final task = Task(
        id: '1',
        title: 'Vergi beyannamesi',
        note: 'Belastingdienst',
        priority: Priority.high,
        dueDate: DateTime(2026, 11, 1, 18),
        createdAt: DateTime(2026, 10, 14),
      );
      final copy = Task.fromJson(task.toJson());
      expect(copy.toJson(), task.toJson());
    });

    test('sorts open before done, then priority, then due date', () {
      final created = DateTime(2026, 1, 1);
      Task t(String id, Priority p, {DateTime? due, bool done = false}) => Task(
        id: id,
        title: id,
        priority: p,
        dueDate: due,
        done: done,
        createdAt: created,
      );
      final tasks = [
        t('low', Priority.low),
        t('done-high', Priority.high, done: true),
        t('high-nodate', Priority.high),
        t('high-late', Priority.high, due: DateTime(2026, 12, 1)),
        t('high-soon', Priority.high, due: DateTime(2026, 11, 1)),
      ]..sort(Task.compare);
      expect(tasks.map((t) => t.id), [
        'high-soon',
        'high-late',
        'high-nodate',
        'low',
        'done-high',
      ]);
    });
  });

  test('store persists tasks', () async {
    final store = TaskStore(TaskRepository());
    await store.load();
    await store.add(title: 'Süt al', priority: Priority.low);
    await store.toggleDone(store.openTasks.single);

    final reloaded = TaskStore(TaskRepository());
    await reloaded.load();
    expect(reloaded.openTasks, isEmpty);
    expect(reloaded.doneTasks.single.title, 'Süt al');
  });

  testWidgets('add a task through the UI', (tester) async {
    final store = TaskStore(TaskRepository());
    await store.load();
    await tester.pumpWidget(IneedApp(store: store));

    expect(find.text('Henüz görev yok'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.add));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'Fiets tamir');
    await tester.tap(find.text('Yüksek'));
    await tester.pump();
    await tester.tap(find.text('Kaydet'));
    await tester.pumpAndSettle();

    expect(find.text('Fiets tamir'), findsOneWidget);
    expect(store.openTasks.single.priority, Priority.high);
  });
}
