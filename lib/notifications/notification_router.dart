import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../screens/event_edit_screen.dart';
import '../screens/task_edit_screen.dart';
import '../state/event_store.dart';
import '../state/settings_store.dart';
import '../state/task_store.dart';

/// Opens the task or calendar entry a tapped reminder is about.
class NotificationRouter {
  NotificationRouter({
    required this.navigatorKey,
    required this.messengerKey,
    required this.tasks,
    required this.events,
    required this.settings,
    this.clock = DateTime.now,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final GlobalKey<ScaffoldMessengerState> messengerKey;
  final TaskStore tasks;
  final EventStore events;
  final SettingsStore settings;
  final DateTime Function() clock;

  /// Handles a payload such as `task:<id>` or `event:<id>`.
  void open(String payload, {bool retried = false}) {
    final navigator = navigatorKey.currentState;
    if (navigator == null) {
      // The app is still starting; try once more after the first frame.
      if (!retried) {
        WidgetsBinding.instance.addPostFrameCallback(
          (_) => open(payload, retried: true),
        );
      }
      return;
    }

    final separator = payload.indexOf(':');
    if (separator <= 0) return;
    final kind = payload.substring(0, separator);
    final id = payload.substring(separator + 1);

    final Widget? screen = switch (kind) {
      'task' => switch (tasks.byId(id)) {
        final task? => TaskEditScreen(store: tasks, task: task),
        null => null,
      },
      'event' => switch (events.byId(id)) {
        final event? => EventEditScreen(
          store: events,
          settings: settings,
          event: event,
          clock: clock,
        ),
        null => null,
      },
      _ => null,
    };

    if (screen == null) {
      if (kind == 'task' || kind == 'event') {
        messengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(navigator.context).itemGone),
          ),
        );
      }
      return;
    }
    // Pushed on top rather than replacing what's open, so an editor with
    // unsaved changes is never thrown away.
    navigator.push(MaterialPageRoute(builder: (_) => screen));
  }
}
