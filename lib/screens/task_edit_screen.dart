import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/task.dart';
import '../state/task_store.dart';
import '../widgets/priority_style.dart';

class TaskEditScreen extends StatefulWidget {
  const TaskEditScreen({super.key, required this.store, this.task});

  final TaskStore store;

  /// Null when creating a new task.
  final Task? task;

  @override
  State<TaskEditScreen> createState() => _TaskEditScreenState();
}

class _TaskEditScreenState extends State<TaskEditScreen> {
  late final _title = TextEditingController(text: widget.task?.title);
  late final _note = TextEditingController(text: widget.task?.note);
  late Priority _priority = widget.task?.priority ?? Priority.medium;
  late DateTime? _dueDate = widget.task?.dueDate;

  bool _saving = false;

  bool get _isNew => widget.task == null;

  @override
  void initState() {
    super.initState();
    _title.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final initial = _dueDate ?? now.add(const Duration(days: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      // An old task's date must stay inside the picker's range.
      firstDate: initial.isBefore(now) ? initial : now,
      lastDate: DateTime(now.year + 5, 12, 31),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: _dueDate != null
          ? TimeOfDay.fromDateTime(_dueDate!)
          : const TimeOfDay(hour: 18, minute: 0),
    );
    if (time == null) return;
    setState(() {
      _dueDate = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _saving) return;
    _saving = true;
    try {
      final note = _note.text.trim();
      final existing = widget.task;
      if (existing == null) {
        await widget.store.add(
          title: title,
          note: note,
          priority: _priority,
          dueDate: _dueDate,
        );
      } else {
        await widget.store.update(
          existing.copyWith(
            title: title,
            note: note,
            priority: _priority,
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
          ),
        );
      }
    } catch (e) {
      // The change is already in memory and is written again with the
      // next save, so closing the screen is still correct.
      debugPrint('Saving task failed: $e');
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    final canSave = _title.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newTask : l10n.editTask),
        actions: [
          TextButton(onPressed: canSave ? _save : null, child: Text(l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.taskTitleLabel,
              border: const OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          Text(l10n.priority, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Priority>(
            segments: [
              for (final p in Priority.values)
                ButtonSegment(
                  value: p,
                  label: Text(l10n.priorityLabel(p)),
                  icon: Icon(
                    Icons.circle,
                    size: 12,
                    color: priorityColor(p, scheme),
                  ),
                ),
            ],
            selected: {_priority},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 24),
          Text(l10n.dueDate, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _dueDate == null
                        ? l10n.pickDate
                        : l10n.dates.longWithTime(_dueDate!),
                  ),
                ),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: l10n.removeDate,
                  onPressed: () => setState(() => _dueDate = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          if (_dueDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.taskReminderHint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 24),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.note,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          if (!_isNew) ...[
            const SizedBox(height: 24),
            FilledButton.tonalIcon(
              onPressed: _toggleDone,
              icon: Icon(_wasDone ? Icons.undo : Icons.check),
              label: Text(_wasDone ? l10n.markNotDone : l10n.markDone),
            ),
          ],
        ],
      ),
    );
  }

  bool get _wasDone => widget.task?.done ?? false;

  /// Saves any edits, then flips done (e.g. straight from a reminder).
  Future<void> _toggleDone() async {
    if (_saving) return;
    _saving = true;
    final task = widget.task!;
    final title = _title.text.trim();
    // Both changes apply in memory right away; only the disk writes are
    // awaited, so a failed write can't leave the task half-updated.
    final writes = [
      if (title.isNotEmpty)
        widget.store.update(
          task.copyWith(
            title: title,
            note: _note.text.trim(),
            priority: _priority,
            dueDate: _dueDate,
            clearDueDate: _dueDate == null,
          ),
        ),
      widget.store.toggleDone(task),
    ];
    try {
      await Future.wait(writes);
    } catch (e) {
      debugPrint('Saving task failed: $e');
    }
    if (mounted) Navigator.of(context).pop();
  }
}
