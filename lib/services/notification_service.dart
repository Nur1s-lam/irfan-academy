import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_time.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _channelId = 'prayer_reminders';
  static const String _channelName = 'Напоминания о намазе';
  static const String _channelDescription = 'Уведомления о наступлении намаза';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) {
      return;
    }

    if (kIsWeb) {
      _initialized = true;
      return;
    }

    tz.initializeTimeZones();
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(settings: initializationSettings);
    await _requestPermissions();
    _initialized = true;
  }

  Future<void> schedulePrayerNotifications(List<PrayerTime> prayers) async {
    if (kIsWeb) {
      return;
    }
    await initialize();
    await _notifications.cancelAll();

    final now = DateTime.now();
    for (var index = 0; index < prayers.length; index++) {
      final prayer = prayers[index];
      if (prayer.isFaint || !prayer.dateTime.isAfter(now)) {
        continue;
      }

      await _schedulePrayerNotification(id: 1000 + index, prayer: prayer);
    }
  }

  Future<void> _schedulePrayerNotification({
    required int id,
    required PrayerTime prayer,
  }) async {
    final scheduledDate = tz.TZDateTime.from(prayer.dateTime, tz.local);
    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: _channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        category: AndroidNotificationCategory.reminder,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: 'Время намаза',
        body: '${prayer.nameRu} в ${prayer.time}',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      await _notifications.zonedSchedule(
        id: id,
        title: 'Время намаза',
        body: '${prayer.nameRu} в ${prayer.time}',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> _requestPermissions() async {
    final android = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    await android?.requestNotificationsPermission();
    await android?.requestExactAlarmsPermission();

    final ios = _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    await ios?.requestPermissions(alert: true, badge: true, sound: true);

    final macOS = _notifications
        .resolvePlatformSpecificImplementation<
          MacOSFlutterLocalNotificationsPlugin
        >();
    await macOS?.requestPermissions(alert: true, badge: true, sound: true);
  }
}
