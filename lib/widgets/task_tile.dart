import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import 'priority_style.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.onToggle,
    required this.onTap,
  });

  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final overdue = task.isOverdue(DateTime.now());
    final due = task.dueDate;

    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: task.done,
        onChanged: (_) => onToggle(),
        shape: const CircleBorder(),
      ),
      title: Text(
        task.title,
        style: task.done
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: due == null && task.note.isEmpty
          ? null
          : Text(
              [
                if (due != null) DateFormat('d MMM, HH:mm', 'tr').format(due),
                if (task.note.isNotEmpty) task.note,
              ].join(' · '),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: overdue ? TextStyle(color: scheme.error) : null,
            ),
      trailing: task.done
          ? null
          : Semantics(
              label: '${task.priority.label} öncelik',
              child: Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: priorityColor(task.priority, scheme),
                  shape: BoxShape.circle,
                ),
              ),
            ),
    );
  }
}
