import 'dart:async';

import 'package:flutter/material.dart';

import '../models/due_label.dart';
import '../models/task.dart';
import '../state/task_store.dart';
import '../widgets/task_tile.dart';
import 'task_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store, this.clock = DateTime.now});

  final TaskStore store;

  /// Source of the current time; replaced in tests.
  final DateTime Function() clock;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDone = false;
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;

  TaskStore get store => widget.store;

  @override
  void initState() {
    super.initState();
    _scheduleTick();
    // Timers don't run while the app is in the background, so refresh as
    // soon as it comes back.
    _lifecycle = AppLifecycleListener(onResume: _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  /// Refreshes due labels right after each minute boundary, so a task turns
  /// "overdue" at 18:00 and not up to a minute later.
  void _scheduleTick() {
    _ticker?.cancel();
    _ticker = Timer(untilNextMinute(widget.clock()), _tick);
  }

  void _tick() {
    if (!mounted) return;
    // The list reads the clock on every build, so a rebuild is enough.
    setState(() {});
    _scheduleTick();
  }

  void _openEditor([Task? task]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: task == null,
        builder: (_) => TaskEditScreen(store: store, task: task),
      ),
    );
  }

  void _delete(Task task) {
    store.remove(task);
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('"${task.title}" silindi'),
          action: SnackBarAction(
            label: 'Geri al',
            onPressed: () => store.restore(task),
          ),
        ),
      );
  }

  Widget _tile(Task task, DateTime now) {
    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        color: Theme.of(context).colorScheme.errorContainer,
        child: const Icon(Icons.delete_outline),
      ),
      onDismissed: (_) => _delete(task),
      child: TaskTile(
        task: task,
        now: now,
        onToggle: () => store.toggleDone(task),
        onTap: () => _openEditor(task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Yapılacaklar')),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        tooltip: 'Yeni görev',
        child: const Icon(Icons.add),
      ),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final open = store.openTasks;
          final done = store.doneTasks;
          final now = widget.clock();

          if (open.isEmpty && done.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              ...open.map((t) => _tile(t, now)),
              if (open.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(child: Text('Hepsi tamam 🎉')),
                ),
              if (done.isNotEmpty) ...[
                ListTile(
                  title: Text('Tamamlananlar (${done.length})'),
                  trailing: Icon(
                    _showDone ? Icons.expand_less : Icons.expand_more,
                  ),
                  onTap: () => setState(() => _showDone = !_showDone),
                ),
                if (_showDone) ...done.map((t) => _tile(t, now)),
              ],
            ],
          );
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: theme.colorScheme.outline,
          ),
          const SizedBox(height: 12),
          Text('Henüz görev yok', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            '+ ile ilk görevini ekle',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
