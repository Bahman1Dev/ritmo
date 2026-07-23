import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class CycleNotificationService {
  static final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;

    tz.initializeTimeZones();

    const initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initializationSettingsDarwin = DarwinInitializationSettings(
      
    );

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsDarwin,
    );

    await _notificationsPlugin.initialize(settings: initializationSettings);
    _initialized = true;
  }

  /// Schedule period reminder notifications
  static Future<void> scheduleReminders({
    required DateTime nextPeriodWindowStart,
    required bool consentReminders,
    required bool pregnancyMode,
  }) async {
    await _ensureInitialized();
    await cancelAll();

    if (!consentReminders || pregnancyMode) {
      return;
    }

    final today = DateTime.now();

    // 2 days before nextPeriodWindowStart
    final dayMinus2 = nextPeriodWindowStart.subtract(const Duration(days: 2));
    // 1 day before nextPeriodWindowStart
    final dayMinus1 = nextPeriodWindowStart.subtract(const Duration(days: 1));

    // Schedule 2 days before reminder
    if (dayMinus2.isAfter(today)) {
      final scheduledDateTime = DateTime(dayMinus2.year, dayMinus2.month, dayMinus2.day, 10); // 10:00 AM
      if (scheduledDateTime.isAfter(today)) {
        await _scheduleNotification(
          id: 2002,
          title: 'یادآوری ریتمو 🌸',
          body: 'لوازم شخصیات رو چک کن 💜',
          scheduledDate: scheduledDateTime,
        );
      }
    }

    // Schedule 1 day before reminder
    if (dayMinus1.isAfter(today)) {
      final scheduledDateTime = DateTime(dayMinus1.year, dayMinus1.month, dayMinus1.day, 10); // 10:00 AM
      if (scheduledDateTime.isAfter(today)) {
        await _scheduleNotification(
          id: 2001,
          title: 'ریتمو 🌸',
          body: 'فردا ممکنه شروع بشه، آماده باش 💪',
          scheduledDate: scheduledDateTime,
        );
      }
    }
  }

  static Future<void> _scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'cycle_reminders',
      'یادآوری‌های شخصی',
      channelDescription: 'یادآوری شروع چرخه بدنی',
      color: Color(0xffEC4899),
    );

    const iosDetails = DarwinNotificationDetails();

    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final tzDateTime = tz.TZDateTime.from(scheduledDate, tz.local);

    try {
      await _notificationsPlugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tzDateTime,
        notificationDetails: platformChannelSpecifics,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } catch (_) {
      try {
        await _notificationsPlugin.zonedSchedule(
          id: id,
          title: title,
          body: body,
          scheduledDate: tzDateTime,
          notificationDetails: platformChannelSpecifics,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (e) {
        debugPrint('Fallback notification scheduling also failed: $e');
      }
    }
  }

  /// Cancel all cycle-related notifications
  static Future<void> cancelAll() async {
    await _ensureInitialized();
    await _notificationsPlugin.cancel(id: 2001);
    await _notificationsPlugin.cancel(id: 2002);
  }

  /// Show an immediate local notification (used for backup warnings etc.)
  static Future<void> showImmediateNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _ensureInitialized();
    const androidDetails = AndroidNotificationDetails(
      'backup_reminders',
      'پشتیبان‌گیری ریتمو',
      channelDescription: 'اطلاع‌رسانی وضعیت پشتیبان‌گیری',
      importance: Importance.high,
      priority: Priority.high,
    );
    const iosDetails = DarwinNotificationDetails();
    const platformChannelSpecifics = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    await _notificationsPlugin.show(
      id: id,
      title: title,
      body: body,
      notificationDetails: platformChannelSpecifics,
    );
  }
}
