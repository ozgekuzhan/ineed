import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../models/dates.dart';
import '../models/event.dart';
import '../state/event_store.dart';
import '../widgets/minute_ticker.dart';
import 'event_edit_screen.dart';

/// Birthdays and events: a month calendar with dots, and below it either
/// what's coming up or, once a day is tapped, that day's entries.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.store,
    this.clock = DateTime.now,
  });

  final EventStore store;
  final DateTime Function() clock;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _focused = localDay(widget.clock());

  /// Null shows the upcoming list instead of a single day.
  DateTime? _selected;

  void _openEditor({Event? event, DateTime? day}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        fullscreenDialog: event == null,
        builder: (_) => EventEditScreen(
          store: widget.store,
          event: event,
          initialDate: day,
          clock: widget.clock,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Takvim'),
        actions: [
          if (_selected != null)
            TextButton(
              onPressed: () => setState(() => _selected = null),
              child: const Text('Yaklaşanlar'),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: 'add-event',
        tooltip: 'Yeni doğum günü / etkinlik',
        onPressed: () => _openEditor(day: _selected),
        child: const Icon(Icons.add),
      ),
      body: MinuteTicker(
        clock: widget.clock,
        builder: (context, now) => ListenableBuilder(
          listenable: widget.store,
          builder: (context, _) => _build(localDay(now)),
        ),
      ),
    );
  }

  Widget _build(DateTime today) {
    final scheme = Theme.of(context).colorScheme;
    final selected = _selected;
    // One scroll view, so the calendar scrolls away and long lists get the
    // whole screen.
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: TableCalendar<Event>(
            locale: 'tr',
            firstDay: DateTime(1900),
            lastDay: DateTime(today.year + 20, 12, 31),
            focusedDay: _focused,
            currentDay: today,
            startingDayOfWeek: StartingDayOfWeek.monday,
            availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
            // Only month swipes; vertical drags must scroll the page.
            availableGestures: AvailableGestures.horizontalSwipe,
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
            calendarStyle: CalendarStyle(
              markerDecoration: BoxDecoration(
                color: scheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
            selectedDayPredicate: (d) =>
                selected != null && isSameDay(d, selected),
            eventLoader: (d) => widget.store.on(localDay(d)),
            onDaySelected: (day, focused) => setState(() {
              final local = localDay(day);
              // Tapping the selected day again goes back to "upcoming".
              _selected = isSameDay(local, _selected) ? null : local;
              _focused = localDay(focused);
            }),
            onPageChanged: (focused) => _focused = localDay(focused),
          ),
        ),
        const SliverToBoxAdapter(child: Divider(height: 1)),
        if (selected == null)
          _UpcomingList(
            store: widget.store,
            today: today,
            onTap: (e) => _openEditor(event: e),
          )
        else
          _DayList(
            store: widget.store,
            day: selected,
            today: today,
            onTap: (e) => _openEditor(event: e),
          ),
        const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
      ],
    );
  }
}

class _UpcomingList extends StatelessWidget {
  const _UpcomingList({
    required this.store,
    required this.today,
    required this.onTap,
  });

  final EventStore store;
  final DateTime today;
  final ValueChanged<Event> onTap;

  @override
  Widget build(BuildContext context) {
    final upcoming = store.upcoming(today);
    if (upcoming.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: _Hint('Henüz kayıt yok.\n+ ile doğum günü veya etkinlik ekle.'),
      );
    }
    return SliverList.list(
      children: [
        const _SectionTitle('Yaklaşanlar'),
        for (final u in upcoming)
          EventTile(
            event: u.event,
            day: u.day,
            today: today,
            onTap: () => onTap(u.event),
          ),
      ],
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({
    required this.store,
    required this.day,
    required this.today,
    required this.onTap,
  });

  final EventStore store;
  final DateTime day;
  final DateTime today;
  final ValueChanged<Event> onTap;

  @override
  Widget build(BuildContext context) {
    final events = store.on(day);
    return SliverList.list(
      children: [
        _SectionTitle(DateFormat('d MMMM y, EEEE', 'tr').format(day)),
        if (events.isEmpty)
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text('Bu günde kayıt yok.'),
          ),
        for (final e in events)
          EventTile(event: e, day: day, today: today, onTap: () => onTap(e)),
      ],
    );
  }
}

/// One birthday or event, with how far away [day] is from [today].
class EventTile extends StatelessWidget {
  const EventTile({
    super.key,
    required this.event,
    required this.day,
    required this.today,
    this.onTap,
  });

  final Event event;

  /// The occurrence being shown.
  final DateTime day;
  final DateTime today;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isBirthday = event.kind == EventKind.birthday;
    final age = event.ageOn(day);
    final details = [
      DateFormat('d MMMM EEEE', 'tr').format(day),
      if (event.hasTime && !isBirthday)
        DateFormat('HH:mm', 'tr').format(event.date),
      if (age != null) '$age yaşına giriyor',
    ].join(' · ');

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: isBirthday
            ? scheme.tertiaryContainer
            : scheme.secondaryContainer,
        child: Icon(
          isBirthday ? Icons.cake_outlined : Icons.event_outlined,
          color: isBirthday
              ? scheme.onTertiaryContainer
              : scheme.onSecondaryContainer,
          semanticLabel: event.kind.label,
        ),
      ),
      title: Text(event.title),
      subtitle: Text(details),
      trailing: _Countdown(days: daysBetween(today, day)),
    );
  }
}

class _Countdown extends StatelessWidget {
  const _Countdown({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soon = days >= 0 && days <= 3;
    final text = switch (days) {
      < 0 => '${-days} gün önce',
      0 => 'Bugün',
      1 => 'Yarın',
      _ => '$days gün sonra',
    };
    return Text(
      text,
      style: theme.textTheme.labelLarge?.copyWith(
        color: soon ? theme.colorScheme.primary : null,
        fontWeight: soon ? FontWeight.w600 : null,
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(text, style: theme.textTheme.titleMedium),
    );
  }
}

class _Hint extends StatelessWidget {
  const _Hint(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}
