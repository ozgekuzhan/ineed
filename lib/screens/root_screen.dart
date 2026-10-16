import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../state/event_store.dart';
import '../state/settings_store.dart';
import '../state/task_store.dart';
import 'calendar_screen.dart';
import 'home_screen.dart';

/// Bottom navigation between the task list and the calendar.
class RootScreen extends StatefulWidget {
  const RootScreen({
    super.key,
    required this.tasks,
    required this.events,
    required this.settings,
    this.clock = DateTime.now,
  });

  final TaskStore tasks;
  final EventStore events;
  final SettingsStore settings;
  final DateTime Function() clock;

  @override
  State<RootScreen> createState() => _RootScreenState();
}

class _RootScreenState extends State<RootScreen> {
  int _tab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Both tabs stay alive so switching keeps scroll position and state.
      body: IndexedStack(
        index: _tab,
        children: [
          HomeScreen(
            store: widget.tasks,
            settings: widget.settings,
            clock: widget.clock,
          ),
          CalendarScreen(
            store: widget.events,
            settings: widget.settings,
            clock: widget.clock,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.checklist_outlined),
            selectedIcon: const Icon(Icons.checklist),
            label: context.l10n.tabTasks,
          ),
          NavigationDestination(
            icon: const Icon(Icons.calendar_month_outlined),
            selectedIcon: const Icon(Icons.calendar_month),
            label: context.l10n.tabCalendar,
          ),
        ],
      ),
    );
  }
}
