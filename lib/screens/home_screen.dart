import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/task.dart';
import '../state/settings_store.dart';
import '../state/task_store.dart';
import '../widgets/minute_ticker.dart';
import '../widgets/task_tile.dart';
import 'history_screen.dart';
import 'settings_screen.dart';
import 'task_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({
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
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TaskStore get store => widget.store;

  void _openEditor([Task? task]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: task == null,
        builder: (_) => TaskEditScreen(store: store, task: task),
      ),
    );
  }

  void _openHistory() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => HistoryScreen(store: store, clock: widget.clock),
      ),
    );
  }

  void _openSettings() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SettingsScreen(settings: widget.settings),
      ),
    );
  }

  void _showUndo(String message, VoidCallback undo) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(label: context.l10n.undo, onPressed: undo),
        ),
      );
  }

  void _delete(Task task) {
    store.remove(task);
    _showUndo(context.l10n.taskDeleted(task.title), () => store.restore(task));
  }

  void _toggle(Task task) {
    final completing = !task.done;
    store.toggleDone(task);
    // When finished tasks leave the list, offer a way back in case the tap
    // was a mistake.
    if (completing &&
        widget.settings.completedBehavior == CompletedBehavior.hide) {
      _showUndo(
        context.l10n.taskCompleted(task.title),
        () => store.toggleDone(task),
      );
    }
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
        onToggle: () => _toggle(task),
        onTap: () => _openEditor(task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.tasksTitle),
        actions: [
          IconButton(
            tooltip: context.l10n.history,
            onPressed: _openHistory,
            icon: const Icon(Icons.history),
          ),
          IconButton(
            tooltip: context.l10n.settings,
            onPressed: _openSettings,
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openEditor,
        tooltip: context.l10n.newTask,
        child: const Icon(Icons.add),
      ),
      body: MinuteTicker(
        clock: widget.clock,
        builder: (context, now) => ListenableBuilder(
          listenable: Listenable.merge([store, widget.settings]),
          builder: (context, _) => _buildList(now),
        ),
      ),
    );
  }

  Widget _buildList(DateTime now) {
    // Today's list: open tasks plus those finished today. Anything finished
    // on an earlier day has dropped off, so each day starts with only what
    // is still to do.
    final today = store.tasksForDay(now);
    final strike =
        widget.settings.completedBehavior == CompletedBehavior.strikeThrough;
    final visible = strike ? today : today.where((t) => !t.done).toList();
    final doneToday = today.where((t) => t.done).length;

    if (visible.isEmpty) {
      return doneToday == 0
          ? _EmptyState(
              icon: Icons.check_circle_outline,
              title: context.l10n.emptyTasksTitle,
              subtitle: context.l10n.emptyTasksHint,
            )
          : _EmptyState(
              icon: Icons.celebration_outlined,
              title: context.l10n.allDoneTitle,
              subtitle: context.l10n.allDoneSubtitle(doneToday),
            );
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        if (strike && doneToday > 0)
          _Progress(done: doneToday, total: today.length),
        ...visible.map((t) => _tile(t, now)),
      ],
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.done, required this.total});

  final int done;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            context.l10n.todayProgress(done, total),
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: done / total,
              minHeight: 6,
              // The value is announced as a percentage; the line above
              // already says "x / y".
              semanticsLabel: context.l10n.todayProgressLabel,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text(title, style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
