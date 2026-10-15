import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../data/event_repository.dart';
import '../models/event.dart';
import 'save_queue.dart';

/// An event together with the day it next falls on.
typedef Upcoming = ({Event event, DateTime day});

class EventStore extends ChangeNotifier {
  EventStore(this._repository);

  final EventRepository _repository;
  final _uuid = const Uuid();
  final _saves = SaveQueue();
  List<Event> _events = [];

  List<Event> get all => List.unmodifiable(_events);

  Future<void> load() async {
    _events = await _repository.load();
    notifyListeners();
  }

  /// Events falling on [day], birthdays first, then by time and title.
  List<Event> on(DateTime day) =>
      _events.where((e) => e.occursOn(day)).toList()..sort(_compareSameDay);

  /// Everything still to come from [today] on, soonest first.
  List<Upcoming> upcoming(DateTime today) {
    final list = <Upcoming>[
      for (final e in _events)
        if (e.nextOccurrence(today) case final day?) (event: e, day: day),
    ];
    list.sort((a, b) {
      final byDay = a.day.compareTo(b.day);
      return byDay != 0 ? byDay : _compareSameDay(a.event, b.event);
    });
    return list;
  }

  Future<Event> add({
    required EventKind kind,
    required String title,
    required DateTime date,
    bool hasYear = true,
    bool hasTime = false,
    bool yearly = false,
    String note = '',
  }) async {
    final event = Event(
      id: _uuid.v4(),
      kind: kind,
      title: title,
      date: date,
      hasYear: hasYear,
      hasTime: hasTime,
      yearly: yearly,
      note: note,
    );
    _events.add(event);
    await _commit();
    return event;
  }

  Future<void> update(Event event) {
    final i = _events.indexWhere((e) => e.id == event.id);
    if (i == -1) return Future.value();
    _events[i] = event;
    return _commit();
  }

  Future<void> remove(Event event) {
    _events.removeWhere((e) => e.id == event.id);
    return _commit();
  }

  Future<void> restore(Event event) {
    if (_events.any((e) => e.id == event.id)) return Future.value();
    _events.add(event);
    return _commit();
  }

  Future<void> _commit() {
    notifyListeners();
    final snapshot = List<Event>.of(_events);
    return _saves.add(() => _repository.save(snapshot));
  }
}

int _compareSameDay(Event a, Event b) {
  if (a.kind != b.kind) return a.kind.index.compareTo(b.kind.index);
  if (a.hasTime != b.hasTime) return a.hasTime ? 1 : -1;
  if (a.hasTime) {
    final byTime = (a.date.hour * 60 + a.date.minute).compareTo(
      b.date.hour * 60 + b.date.minute,
    );
    if (byTime != 0) return byTime;
  }
  final byTitle = a.title.toLowerCase().compareTo(b.title.toLowerCase());
  return byTitle != 0 ? byTitle : a.id.compareTo(b.id);
}
