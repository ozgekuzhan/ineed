import 'package:flutter/material.dart';

import '../models/task.dart';
import '../state/task_store.dart';
import '../widgets/task_tile.dart';
import 'task_edit_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.store});

  final TaskStore store;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _showDone = false;

  TaskStore get store => widget.store;

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

  Widget _tile(Task task) {
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

          if (open.isEmpty && done.isEmpty) {
            return const _EmptyState();
          }

          return ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              ...open.map(_tile),
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
                if (_showDone) ...done.map(_tile),
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
