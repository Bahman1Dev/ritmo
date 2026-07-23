import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class NativeBridge {
  static const _alarmChannel = MethodChannel('com.ritmo.app/alarms');
  static const _serviceChannel = MethodChannel('com.ritmo.app/foreground_service');
  static const _keystoreChannel = MethodChannel('com.ritmo.app/keystore');

  /// Requests the master encryption key from the secure Android Keystore.
  static Future<String> getOrCreateMasterKey() async {
    if (kIsWeb) {
      // Return a fixed 32-byte hex key for encryption/decryption in the web demo
      return '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
    }
    try {
      final String key = await _keystoreChannel.invokeMethod('getOrCreateKey');
      return key;
    } on PlatformException catch (e) {
      throw Exception('Failed to get Master Key from Keystore: ${e.message}');
    }
  }

  /// Schedules an exact alarm in Android's AlarmManager.
  static Future<bool> scheduleExactAlarm({
    required String id,
    required int timeMsUTC,
    required String title,
    required bool isEssential,
  }) async {
    if (kIsWeb) {
      debugPrint('Web: Mock scheduled exact alarm $id at $timeMsUTC');
      return true;
    }
    try {
      final bool success = await _alarmChannel.invokeMethod('scheduleExactAlarm', {
        'id': id,
        'time': timeMsUTC,
        'title': title,
        'isEssential': isEssential,
      });
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error scheduling exact alarm: ${e.message}');
      return false;
    }
  }

  /// Cancels a scheduled alarm in Android's AlarmManager.
  static Future<bool> cancelAlarm(String id) async {
    if (kIsWeb) {
      debugPrint('Web: Mock cancelled alarm $id');
      return true;
    }
    try {
      final bool success = await _alarmChannel.invokeMethod('cancelAlarm', {
        'id': id,
      });
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error cancelling alarm: ${e.message}');
      return false;
    }
  }

  /// Starts or updates the persistent foreground service in Status Mode.
  static Future<bool> startStatusMode({
    required String zone,
    required String energy,
    required String proposedTask,
    String? proposedTaskId,
    int completedRoutines = 0,
    int totalRoutines = 0,
    int completedPrayers = 0,
    int totalPrayers = 0,
    List<String>? zoneNames,
    List<String>? zoneIds,
  }) async {
    if (kIsWeb) {
      debugPrint('Web: Mock startStatusMode (zone: $zone, energy: $energy, task: $proposedTask, id: $proposedTaskId, completedRoutines: $completedRoutines, totalRoutines: $totalRoutines, completedPrayers: $completedPrayers, totalPrayers: $totalPrayers)');
      return true;
    }
    try {
      final bool success = await _serviceChannel.invokeMethod('startStatusMode', {
        'zone': zone,
        'energy': energy,
        'proposedTask': proposedTask,
        'proposedTaskId': proposedTaskId,
        'completedRoutines': completedRoutines,
        'totalRoutines': totalRoutines,
        'completedPrayers': completedPrayers,
        'totalPrayers': totalPrayers,
        'zoneNames': zoneNames,
        'zoneIds': zoneIds,
      });
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error starting status service: ${e.message}');
      return false;
    }
  }

  /// Starts the persistent foreground service in countdown Timer Mode.
  static Future<bool> startTimerMode({
    required String title,
    required int durationSeconds,
    required int elapsedSeconds,
  }) async {
    if (kIsWeb) {
      debugPrint('Web: Mock startTimerMode ($title, duration: $durationSeconds, elapsed: $elapsedSeconds)');
      return true;
    }
    try {
      final bool success = await _serviceChannel.invokeMethod('startTimerMode', {
        'title': title,
        'durationSeconds': durationSeconds,
        'elapsedSeconds': elapsedSeconds,
      });
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error starting timer service: ${e.message}');
      return false;
    }
  }

  /// Stops the persistent foreground service.
  static Future<bool> stopForegroundService() async {
    if (kIsWeb) {
      debugPrint('Web: Mock stopForegroundService');
      return true;
    }
    try {
      final bool success = await _serviceChannel.invokeMethod('stopService');
      return success;
    } on PlatformException catch (e) {
      debugPrint('Error stopping service: ${e.message}');
      return false;
    }
  }

  static const _widgetChannel = MethodChannel('com.ritmo.app/widget');

  /// Asks the OS to repaint the home-screen widgets after the snapshot changed.
  /// Best-effort: only works when an activity engine is attached (foreground);
  /// silently no-ops on web or in headless background isolates.
  static Future<void> refreshWidgets() async {
    if (kIsWeb) return;
    try {
      await _widgetChannel.invokeMethod('refreshWidgets');
    } on PlatformException catch (e) {
      debugPrint('Error refreshing widgets: ${e.message}');
    } catch (e) {
      // No attached engine (background isolate) — ignore.
    }
  }

  static const _launchIntentChannel = MethodChannel('com.ritmo.app/launch_intent');

  /// Fetches any start timer parameters if the app was launched by clicking the "الان انجام می‌دهم" button
  static Future<Map<String, dynamic>?> getLaunchIntent() async {
    if (kIsWeb) return null;
    try {
      final res = await _launchIntentChannel.invokeMethod('getLaunchIntent');
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } on PlatformException catch (e) {
      debugPrint('Error getting launch intent: ${e.message}');
    }
    return null;
  }
}
