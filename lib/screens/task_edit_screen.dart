import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
    final canSave = _title.text.trim().isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'Yeni görev' : 'Görevi düzenle'),
        actions: [
          TextButton(
            onPressed: canSave ? _save : null,
            child: const Text('Kaydet'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: _title,
            autofocus: _isNew,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Ne yapılacak?',
              border: OutlineInputBorder(),
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 24),
          Text('Öncelik', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SegmentedButton<Priority>(
            segments: [
              for (final p in Priority.values)
                ButtonSegment(
                  value: p,
                  label: Text(p.label),
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
          Text('Son tarih', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickDueDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _dueDate == null
                        ? 'Tarih seç'
                        : DateFormat(
                            'd MMMM y, EEEE HH:mm',
                            'tr',
                          ).format(_dueDate!),
                  ),
                ),
              ),
              if (_dueDate != null)
                IconButton(
                  tooltip: 'Tarihi kaldır',
                  onPressed: () => setState(() => _dueDate = null),
                  icon: const Icon(Icons.close),
                ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _note,
            minLines: 3,
            maxLines: 8,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Not',
              alignLabelWithHint: true,
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
    );
  }
}
