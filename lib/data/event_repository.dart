import '../models/event.dart';
import 'json_list_repository.dart';

class EventRepository extends JsonListRepository<Event> {
  EventRepository()
    : super(key: 'events_v1', fromJson: Event.fromJson, toJson: _toJson);

  static Map<String, dynamic> _toJson(Event e) => e.toJson();
}
