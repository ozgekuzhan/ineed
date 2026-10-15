import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Keeps a list of items as one JSON string in shared preferences.
class JsonListRepository<T> {
  JsonListRepository({
    required this.key,
    required this.fromJson,
    required this.toJson,
  });

  final String key;
  final T Function(Map<String, dynamic>) fromJson;
  final Map<String, dynamic> Function(T) toJson;

  String get _backupPrefix => '${key}_unreadable_';

  /// Loads saved items. Never throws on bad data: unreadable entries are
  /// skipped and the original string is kept under a backup key so nothing
  /// is lost for good.
  Future<List<T>> load() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null) return [];

    final items = <T>[];
    var hadErrors = false;
    try {
      for (final entry in jsonDecode(raw) as List<dynamic>) {
        try {
          items.add(fromJson(entry as Map<String, dynamic>));
        } catch (e) {
          hadErrors = true;
          debugPrint('Skipping unreadable entry in $key: $e');
        }
      }
    } catch (e) {
      hadErrors = true;
      debugPrint('Data in $key unreadable: $e');
    }

    if (hadErrors) {
      final stamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setString('$_backupPrefix$stamp', raw);
      // Store the readable part right away, so the same broken data isn't
      // backed up again on every launch.
      await save(items);
    }
    return items;
  }

  Future<void> save(List<T> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(items.map(toJson).toList()));
  }
}
