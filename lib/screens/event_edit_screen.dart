import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/dates.dart';
import '../models/event.dart';
import '../state/event_store.dart';
import '../state/settings_store.dart';

class EventEditScreen extends StatefulWidget {
  const EventEditScreen({
    super.key,
    required this.store,
    required this.settings,
    this.event,
    this.initialDate,
    this.clock = DateTime.now,
  });

  final EventStore store;
  final SettingsStore settings;

  /// Null when creating a new entry.
  final Event? event;

  /// Day to start a new entry on (e.g. the day tapped in the calendar).
  final DateTime? initialDate;
  final DateTime Function() clock;

  @override
  State<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends State<EventEditScreen> {
  late final _title = TextEditingController(text: widget.event?.title);
  late final _note = TextEditingController(text: widget.event?.note);
  late EventKind _kind = widget.event?.kind ?? EventKind.birthday;
  late DateTime? _date = widget.event?.date ?? widget.initialDate;
  // A day tapped in the calendar gives only day and month for a birthday;
  // its year (this year) isn't the birth year.
  late bool _hasYear = widget.event?.hasYear ?? (widget.initialDate == null);
  late TimeOfDay? _time = (widget.event?.hasTime ?? false)
      ? TimeOfDay.fromDateTime(widget.event!.date)
      : null;
  late bool _yearly = widget.event?.yearly ?? false;
  bool _saving = false;

  bool get _isNew => widget.event == null;
  bool get _isBirthday => _kind == EventKind.birthday;

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

  Future<void> _pickDate() async {
    final now = widget.clock();
    final first = _isBirthday ? DateTime(1900) : DateTime(2000);
    final last = _isBirthday ? now : DateTime(now.year + 20, 12, 31);
    var initial = _date ?? (_isBirthday ? DateTime(now.year - 30) : now);
    // An unknown-year birthday is stored in a placeholder year; show the
    // picker on the same day in a recent year instead.
    if (_isBirthday && !_hasYear && _date != null) {
      initial = DateTime(now.year - 1, _date!.month, _date!.day);
    }
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _time ?? const TimeOfDay(hour: 19, minute: 0),
    );
    if (picked != null) setState(() => _time = picked);
  }

  /// The date to store, with placeholder year / time applied.
  DateTime _composedDate() {
    final d = _date!;
    if (_isBirthday) {
      return DateTime(
        _hasYear ? d.year : Event.placeholderYear,
        d.month,
        d.day,
      );
    }
    final t = _time;
    return t == null
        ? DateTime(d.year, d.month, d.day)
        : DateTime(d.year, d.month, d.day, t.hour, t.minute);
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty || _date == null || _saving) return;
    _saving = true;
    try {
      final note = _note.text.trim();
      final date = _composedDate();
      final existing = widget.event;
      if (existing == null) {
        await widget.store.add(
          kind: _kind,
          title: title,
          date: date,
          hasYear: !_isBirthday || _hasYear,
          hasTime: !_isBirthday && _time != null,
          yearly: !_isBirthday && _yearly,
          note: note,
        );
      } else {
        await widget.store.update(
          existing.copyWith(
            kind: _kind,
            title: title,
            date: date,
            hasYear: !_isBirthday || _hasYear,
            hasTime: !_isBirthday && _time != null,
            yearly: !_isBirthday && _yearly,
            note: note,
          ),
        );
      }
    } catch (e) {
      // The change is already in memory and is written again with the
      // next save, so closing the screen is still correct.
      debugPrint('Saving event failed: $e');
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _delete() async {
    final event = widget.event!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.deleteConfirmTitle),
        content: Text(context.l10n.deleteConfirmBody(event.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(context.l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(context.l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    await widget.store.remove(event);
    if (mounted) Navigator.of(context).pop();
  }

  String _dateLabel(AppLocalizations l10n) {
    final d = _date;
    if (d == null) return l10n.pickDate;
    if (_isBirthday) {
      return _hasYear ? l10n.dates.dayMonthYear(d) : l10n.dates.dayMonth(d);
    }
    return l10n.dates.long(d);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final canSave = _title.text.trim().isNotEmpty && _date != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? l10n.newEntry : l10n.edit),
        actions: [
          if (!_isNew)
            IconButton(
              tooltip: l10n.delete,
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
            ),
          TextButton(onPressed: canSave ? _save : null, child: Text(l10n.save)),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<EventKind>(
            segments: [
              ButtonSegment(
                value: EventKind.birthday,
                label: Text(l10n.birthday),
                icon: const Icon(Icons.cake_outlined),
              ),
              ButtonSegment(
                value: EventKind.event,
                label: Text(l10n.event),
                icon: const Icon(Icons.event_outlined),
              ),
            ],
            selected: {_kind},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _kind = s.first),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _title,
            autofocus: _isNew,
            textCapitalization: _isBirthday
                ? TextCapitalization.words
                : TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: _isBirthday
                  ? l10n.birthdayNameLabel
                  : l10n.eventNameLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            _isBirthday ? l10n.birthDate : l10n.date,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _pickDate,
            icon: const Icon(Icons.event),
            label: Text(_dateLabel(l10n)),
          ),
          if (_isBirthday)
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.unknownBirthYear),
              value: !_hasYear,
              onChanged: (unknown) => setState(() {
                // Going from "unknown" to a known year: the stored placeholder
                // year isn't the real one, so ask for the date again.
                if (!unknown && !_hasYear) _date = null;
                _hasYear = !unknown;
              }),
            )
          else ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.addTime),
              subtitle: _time == null ? null : Text(_time!.format(context)),
              value: _time != null,
              onChanged: (v) {
                if (v) {
                  _pickTime();
                } else {
                  setState(() => _time = null);
                }
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.repeatYearly),
              subtitle: Text(l10n.repeatYearlyHint),
              value: _yearly,
              onChanged: (v) => setState(() => _yearly = v),
            ),
          ],
          const SizedBox(height: 16),
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 6,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              labelText: l10n.note,
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.notifications_outlined,
                size: 18,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isBirthday || _time == null
                      ? l10n.eventReminderHint(
                          formatClockTime(widget.settings.reminderTime),
                        )
                      : l10n.timedEventReminderHint(
                          formatClockTime(widget.settings.reminderTime),
                        ),
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
