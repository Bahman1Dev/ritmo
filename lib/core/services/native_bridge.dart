import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ritmo/core/logging/ritmo_logger.dart';
import 'package:ritmo/core/platform/native_channel_contract.dart';

class NativeBridge {
  static const _alarmChannel = MethodChannel(NativeChannels.alarms);
  static const _serviceChannel = MethodChannel(NativeChannels.foregroundService);
  static const _keystoreChannel = MethodChannel(NativeChannels.keystore);
  static const _widgetChannel = MethodChannel(NativeChannels.widget);
  static const _launchIntentChannel = MethodChannel(NativeChannels.launchIntent);

  /// Requests the master encryption key from the secure Android Keystore.
  static Future<String> getOrCreateMasterKey() async {
    if (kIsWeb) {
      return '00112233445566778899aabbccddeeff00112233445566778899aabbccddeeff';
    }
    try {
      final String? key = await _keystoreChannel.invokeMethod<String>(KeystoreMethods.getOrCreateKey);
      if (key == null || key.isEmpty) {
        throw Exception('Keystore returned empty master key.');
      }
      return key;
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${KeystoreMethods.getOrCreateKey} on channel ${NativeChannels.keystore}',
        e,
        st,
      );
      throw Exception('Keystore channel method unhandled: ${e.message}');
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'PlatformException in getOrCreateMasterKey', e, st);
      throw Exception('Failed to get Master Key from Keystore: ${e.message}');
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error in getOrCreateMasterKey', e, st);
      rethrow;
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
      final bool? success = await _alarmChannel.invokeMethod<bool>(AlarmMethods.scheduleExactAlarm, {
        'id': id,
        'time': timeMsUTC,
        'title': title,
        'isEssential': isEssential,
      });
      return success ?? false;
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${AlarmMethods.scheduleExactAlarm} on channel ${NativeChannels.alarms}',
        e,
        st,
      );
      return false;
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error scheduling exact alarm: ${e.message}', e, st);
      return false;
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error scheduling exact alarm', e, st);
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
      final bool? success = await _alarmChannel.invokeMethod<bool>(AlarmMethods.cancelAlarm, {
        'id': id,
      });
      return success ?? false;
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${AlarmMethods.cancelAlarm} on channel ${NativeChannels.alarms}',
        e,
        st,
      );
      return false;
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error cancelling alarm: ${e.message}', e, st);
      return false;
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error cancelling alarm', e, st);
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
      debugPrint('Web: Mock startStatusMode');
      return true;
    }
    try {
      final bool? success = await _serviceChannel.invokeMethod<bool>(ForegroundServiceMethods.startStatusMode, {
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
      return success ?? false;
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${ForegroundServiceMethods.startStatusMode} on channel ${NativeChannels.foregroundService}',
        e,
        st,
      );
      return false;
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error starting status service: ${e.message}', e, st);
      return false;
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error starting status service', e, st);
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
      debugPrint('Web: Mock startTimerMode');
      return true;
    }
    try {
      final bool? success = await _serviceChannel.invokeMethod<bool>(ForegroundServiceMethods.startTimerMode, {
        'title': title,
        'durationSeconds': durationSeconds,
        'elapsedSeconds': elapsedSeconds,
      });
      return success ?? false;
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${ForegroundServiceMethods.startTimerMode} on channel ${NativeChannels.foregroundService}',
        e,
        st,
      );
      return false;
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error starting timer service: ${e.message}', e, st);
      return false;
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error starting timer service', e, st);
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
      final bool? success = await _serviceChannel.invokeMethod<bool>(ForegroundServiceMethods.stopService);
      return success ?? false;
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${ForegroundServiceMethods.stopService} on channel ${NativeChannels.foregroundService}',
        e,
        st,
      );
      return false;
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error stopping service: ${e.message}', e, st);
      return false;
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error stopping service', e, st);
      return false;
    }
  }

  /// Asks the OS to repaint the home-screen widgets after the snapshot changed.
  static Future<void> refreshWidgets() async {
    if (kIsWeb) return;
    try {
      await _widgetChannel.invokeMethod(WidgetMethods.refreshWidgets);
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${WidgetMethods.refreshWidgets} on channel ${NativeChannels.widget}',
        e,
        st,
      );
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error refreshing widgets: ${e.message}', e, st);
    } catch (e) {
      // No attached engine (background isolate) — ignore.
    }
  }

  /// Fetches any start timer parameters if the app was launched by clicking notification action
  static Future<Map<String, dynamic>?> getLaunchIntent() async {
    if (kIsWeb) return null;
    try {
      final res = await _launchIntentChannel.invokeMethod(LaunchIntentMethods.getLaunchIntent);
      if (res != null) {
        return Map<String, dynamic>.from(res);
      }
    } on MissingPluginException catch (e, st) {
      RitmoLog.error(
        'NativeBridge',
        'Channel contract mismatch or unhandled method ${LaunchIntentMethods.getLaunchIntent} on channel ${NativeChannels.launchIntent}',
        e,
        st,
      );
    } on PlatformException catch (e, st) {
      RitmoLog.error('NativeBridge', 'Platform error getting launch intent: ${e.message}', e, st);
    } catch (e, st) {
      RitmoLog.error('NativeBridge', 'Unexpected error getting launch intent', e, st);
    }
    return null;
  }
}

