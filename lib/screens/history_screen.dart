import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/dates.dart';
import '../state/task_store.dart';
import '../widgets/minute_ticker.dart';
import '../widgets/task_tile.dart';

/// Calendar of past days; picking one shows the task list as it stood that
/// day, with what was finished then struck through. Read-only.
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.store,
    this.clock = DateTime.now,
  });

  final TaskStore store;

  /// Source of the current time; replaced in tests.
  final DateTime Function() clock;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late DateTime _selected = localDay(widget.clock());
  late DateTime _focused = _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Geçmiş')),
      // Keeps "today" right if the screen stays open past midnight.
      body: MinuteTicker(
        clock: widget.clock,
        builder: (context, now) => ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) => _build(localDay(now), now),
        ),
      ),
    );
  }

  Widget _build(DateTime today, DateTime now) {
    // One scroll view, so the calendar scrolls away and a long day list gets
    // the whole screen.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TableCalendar<void>(
            locale: 'tr',
            firstDay: DateTime(2020),
            lastDay: today,
            focusedDay: _focused.isAfter(today) ? today : _focused,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
            // Only month swipes; vertical drags must scroll the page.
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            selectedDayPredicate: (d) => isSameDay(d, _selected),
            // One dot under each day on which something was finished.
            eventLoader: (d) => [
              if (widget.store.completedOn(localDay(d)) > 0) null,
            ],
            onDaySelected: (selected, focused) => setState(() {
              _selected = localDay(selected);
              _focused = localDay(focused);
            }),
            onPageChanged: (focused) => _focused = localDay(focused),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        _DayList(store: widget.store, day: _selected, now: now),
        const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
      ],
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({required this.store, required this.day, required this.now});

  final TaskStore store;
  final DateTime day;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tasks = store.tasksForDay(day);
    final done = tasks.where((t) => t.wasCompletedOn(day)).length;
    // Labels are drawn as of the end of that day, so a past list reads the
    // way it would have looked then ("Gecikti" only if it was late by then).
    final endOfDay = DateTime(
      day.year,
      day.month,
      day.day + 1,
    ).subtract(const Duration(milliseconds: 1));
    final asOf = now.isBefore(endOfDay) ? now : endOfDay;

    return SliverList.list(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            DateFormat('d MMMM y, EEEE', 'tr').format(day),
            style: theme.textTheme.titleMedium,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            tasks.isEmpty
                ? 'Bu gün listede görev yoktu'
                : '$done / ${tasks.length} tamamlandı',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        for (final t in tasks)
          TaskTile(
            task: t,
            now: asOf,
            done: t.wasCompletedOn(day),
            relativeDates: false,
          ),
      ],
    );
  }
}
