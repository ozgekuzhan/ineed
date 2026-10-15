import 'dart:async';

import 'package:flutter/widgets.dart';

import '../state/event_store.dart';
import '../state/save_queue.dart';
import '../state/task_store.dart';
import 'notification_planner.dart';
import 'notifier.dart';

/// Keeps the device's pending reminders in line with tasks and events:
/// re-plans after every change (briefly debounced, so a burst of edits is
/// one update) and whenever the app comes back to the foreground, which
/// also rolls the 60-reminder window forward.
class NotificationSync {
  NotificationSync({
    required this.tasks,
    required this.events,
    required this.notifier,
    this.clock = DateTime.now,
    this.debounce = const Duration(milliseconds: 500),
  });

  final TaskStore tasks;
  final EventStore events;
  final Notifier notifier;
  final DateTime Function() clock;
  final Duration debounce;

  final _queue = SaveQueue();
  Timer? _timer;
  AppLifecycleListener? _lifecycle;
  bool _askedPermission = false;

  void start() {
    tasks.addListener(_schedule);
    events.addListener(_schedule);
    _lifecycle = AppLifecycleListener(onResume: _schedule);
    _schedule();
  }

  void dispose() {
    _timer?.cancel();
    tasks.removeListener(_schedule);
    events.removeListener(_schedule);
    _lifecycle?.dispose();
  }

  void _schedule() {
    _timer?.cancel();
    _timer = Timer(debounce, () => _queue.add(_sync));
  }

  Future<void> _sync() async {
    try {
      final plan = planNotifications(
        tasks: tasks.openTasks,
        events: events.all,
        now: clock(),
      );
      if (plan.isNotEmpty && !_askedPermission) {
        _askedPermission = true;
        await notifier.requestPermission();
      }
      await notifier.replaceAll(plan);
    } catch (e) {
      // Reminders are best effort; the next change or resume tries again.
      debugPrint('Updating reminders failed: $e');
    }
  }
}
