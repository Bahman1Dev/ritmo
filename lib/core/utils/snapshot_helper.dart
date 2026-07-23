import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SnapshotHelper {
  /// Updates the notification settings in SharedPreferences for Kotlin consumption.
  static Future<void> updateNotificationSettingsSnapshot(Map<String, String> settings) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    
    final digestMode = settings['digest_mode'] ?? 'false';
    final coalescingMinutes = int.tryParse(settings['coalescing_window_minutes'] ?? '10') ?? 10;
    final maxNonEssential = int.tryParse(settings['max_non_essential_per_hour'] ?? '3') ?? 3;

    await prefs.setString('notif_digest_mode', digestMode);
    await prefs.setInt('notif_coalescing_window_minutes', coalescingMinutes);
    await prefs.setInt('notif_max_non_essential_per_hour', maxNonEssential);
  }

  /// Updates the snapshot used by the App Widgets.
  /// Keys in SharedPreferences will be prefixed with 'flutter.' by the plugin.
  /// In Kotlin, read: "flutter.widget_snapshot"
  static Future<void> updateWidgetSnapshot({
    required String nextActionTitle,
    required int rhythmScore,
    required String currentEnergyLevel,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'nextActionTitle': nextActionTitle,
      'rhythmScore': rhythmScore,
      'currentEnergyLevel': currentEnergyLevel,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString('widget_snapshot', jsonEncode(data));
  }

  /// Updates the rich snapshot used by the full-screen dashboard widget.
  /// Keys in SharedPreferences are prefixed with 'flutter.' by the plugin.
  /// In Kotlin, read: "flutter.widget_full_snapshot".
  ///
  /// [modules] is the already-formatted module list (Persian digits/labels
  /// resolved in Flutter); each entry has: id, title, primary, secondary,
  /// emoji, color (hex). Kotlin only renders it.
  static Future<void> updateFullWidgetSnapshot({
    required int rhythmScore,
    required String nextActionTitle,
    required String energyLabel,
    required int energyPercent,
    required List<Map<String, String>> modules,
  }) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'rhythmScore': rhythmScore,
      'nextActionTitle': nextActionTitle,
      'energyLabel': energyLabel,
      'energyPercent': energyPercent,
      'modules': modules,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString('widget_full_snapshot', jsonEncode(data));
  }

  /// Updates the snapshot of active reminders/alarms for BootReceiver.
  /// Keys in SharedPreferences will be prefixed with 'flutter.' by the plugin.
  /// In Kotlin, read: "flutter.active_reminders_snapshot"
  static Future<void> updateActiveAlarmsSnapshot(
    List<Map<String, Object?>> alarms,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final data = alarms.map((alarm) {
      final alarmMap = alarm;
      return {
        'id': alarmMap['id'], // pending_reminder ID
        'routineId': alarmMap['routineId'],
        'title': alarmMap['title'],
        'scheduledTime': alarmMap['scheduledTime'], // epoch millis UTC
        'isEssential': (alarmMap['isEssential'] == 1),
      };
    }).toList();

    await prefs.setString('active_reminders_snapshot', jsonEncode(data));
  }

  /// Updates the snapshot of today's agenda items for the Agenda App Widget.
  /// Keys in SharedPreferences will be prefixed with 'flutter.' by the plugin.
  /// In Kotlin, read: "flutter.widget_agenda_snapshot"
  static Future<void> updateAgendaWidgetSnapshot({
    required String dateStr,
    required String remainingText,
    required List<Map<String, dynamic>> items,
  }) async {
    if (kIsWeb) return;
    final prefs = await SharedPreferences.getInstance();
    final data = {
      'dateStr': dateStr,
      'remainingText': remainingText,
      'items': items,
      'updatedAt': DateTime.now().millisecondsSinceEpoch,
    };
    await prefs.setString('widget_agenda_snapshot', jsonEncode(data));
  }
}
