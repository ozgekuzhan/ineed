import 'dart:async';

import 'package:flutter/widgets.dart';

import '../models/due_label.dart';

/// Rebuilds [builder] right after every minute boundary and whenever the app
/// returns to the foreground, so time-based labels and "today" stay current
/// (a task turns overdue at 18:00, the list resets after midnight).
class MinuteTicker extends StatefulWidget {
  const MinuteTicker({super.key, required this.clock, required this.builder});

  final DateTime Function() clock;
  final Widget Function(BuildContext context, DateTime now) builder;

  @override
  State<MinuteTicker> createState() => _MinuteTickerState();
}

class _MinuteTickerState extends State<MinuteTicker> {
  Timer? _ticker;
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _schedule();
    // Timers don't run while the app is in the background, so refresh as
    // soon as it comes back.
    _lifecycle = AppLifecycleListener(onResume: _tick);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  void _schedule() {
    _ticker?.cancel();
    _ticker = Timer(untilNextMinute(widget.clock()), _tick);
  }

  void _tick() {
    if (!mounted) return;
    // The builder reads the clock on every build, so a rebuild is enough.
    setState(() {});
    _schedule();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, widget.clock());
}
