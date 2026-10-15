import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_planner.dart';

/// Schedules reminders on the device. Replaced by a fake in tests.
abstract class Notifier {
  /// Asks for permission to show notifications (iOS shows the prompt only
  /// the first time).
  Future<void> requestPermission();

  /// Replaces every pending reminder with [plan].
  Future<void> replaceAll(List<PlannedNotification> plan);
}

class LocalNotifier implements Notifier {
  final _plugin = FlutterLocalNotificationsPlugin();
  final _taps = StreamController<String>.broadcast();

  /// Payloads of reminders tapped while the app is running.
  Stream<String> get taps => _taps.stream;

  /// Payload of the reminder whose tap started the app, if any.
  Future<String?> launchPayload() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return details.notificationResponse?.payload;
  }

  /// Fallback if the device's time zone can't be read.
  static const _fallbackZone = 'Europe/Amsterdam';

  Future<void> init() async {
    tz_data.initializeTimeZones();
    tz.setLocalLocation(tz.getLocation(_fallbackZone));
    await _updateLocalZone();

    await _plugin.initialize(
      settings: const InitializationSettings(
        // Permission is asked once there is something to remind about.
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestSoundPermission: false,
          requestBadgePermission: false,
        ),
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;
        if (payload != null) _taps.add(payload);
      },
    );
  }

  @override
  Future<void> requestPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
  }

  /// Reads the device's current time zone, so reminders follow the phone
  /// when travelling (e.g. 09:00 in Istanbul, not 09:00 Amsterdam time).
  Future<void> _updateLocalZone() async {
    try {
      final zone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(zone.identifier));
    } catch (e) {
      debugPrint('Time zone lookup failed, keeping ${tz.local.name}: $e');
    }
  }

  @override
  Future<void> replaceAll(List<PlannedNotification> plan) async {
    await _updateLocalZone();
    // Only pending ones: reminders already in the notification centre stay.
    await _plugin.cancelAllPendingNotifications();
    for (final (i, n) in plan.indexed) {
      await _plugin.zonedSchedule(
        id: i,
        // Wall-clock time in the device's zone, so 09:00 stays 09:00 across
        // daylight-saving changes.
        scheduledDate: tz.TZDateTime(
          tz.local,
          n.at.year,
          n.at.month,
          n.at.day,
          n.at.hour,
          n.at.minute,
        ),
        title: n.title,
        body: n.body,
        payload: n.payload,
        notificationDetails: const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          android: AndroidNotificationDetails(
            'reminders',
            'Hatırlatıcılar',
            importance: Importance.high,
            priority: Priority.high,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}
