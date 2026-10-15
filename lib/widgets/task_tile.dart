import 'package:flutter/material.dart';

import '../models/due_label.dart';
import '../models/task.dart';
import 'priority_style.dart';

class TaskTile extends StatelessWidget {
  const TaskTile({
    super.key,
    required this.task,
    required this.now,
    this.done,
    this.relativeDates = true,
    this.onToggle,
    this.onTap,
  });

  final Task task;

  /// Current time, passed in so the list can refresh labels as time passes.
  final DateTime now;

  /// Whether to draw the task as done. Defaults to its current state; the
  /// history view passes the state it had on the day being shown.
  final bool? done;

  /// "Bugün 18:00" style; false writes the date out (history view).
  final bool relativeDates;

  /// Null makes the tile read-only.
  final VoidCallback? onToggle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final due = task.dueDate;
    final isDone = done ?? task.done;

    return ListTile(
      onTap: onTap,
      leading: Checkbox(
        value: isDone,
        onChanged: onToggle == null ? null : (_) => onToggle!(),
        shape: const CircleBorder(),
      ),
      title: Text(
        task.title,
        style: isDone
            ? TextStyle(
                decoration: TextDecoration.lineThrough,
                color: scheme.onSurfaceVariant,
              )
            : null,
      ),
      subtitle: due == null && task.note.isEmpty
          ? null
          : Text.rich(
              TextSpan(
                children: [
                  if (due != null) _dueSpan(due, isDone, scheme),
                  if (due != null && task.note.isNotEmpty)
                    const TextSpan(text: '  ·  '),
                  if (task.note.isNotEmpty) TextSpan(text: task.note),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
      trailing: isDone
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

  InlineSpan _dueSpan(DateTime due, bool isDone, ColorScheme scheme) {
    final text = dueText(due, now, relative: relativeDates);
    // Done tasks only show the date, without urgency colors.
    if (isDone) return TextSpan(text: text);

    final status = dueStatus(due, now);
    final label = status == DueStatus.overdue ? 'Gecikti · $text' : text;
    final color = switch (status) {
      DueStatus.overdue => scheme.error,
      DueStatus.today => scheme.primary,
      DueStatus.tomorrow || DueStatus.later => scheme.onSurfaceVariant,
    };
    final icon = switch (status) {
      DueStatus.overdue => Icons.error_outline,
      DueStatus.today => Icons.today,
      DueStatus.tomorrow || DueStatus.later => Icons.event,
    };
    final weight = status == DueStatus.later
        ? FontWeight.normal
        : FontWeight.w600;
    return TextSpan(
      style: TextStyle(color: color, fontWeight: weight),
      children: [
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Icon(icon, size: 14, color: color),
          ),
        ),
        TextSpan(text: label),
      ],
    );
  }
}
