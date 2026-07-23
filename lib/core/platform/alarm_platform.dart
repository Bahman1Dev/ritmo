// lib/core/platform/alarm_platform.dart

import 'package:ritmo/core/services/native_bridge.dart';

abstract interface class AlarmPlatform {
  /// Schedules an exact alarm via the platform-specific scheduler.
  Future<bool> scheduleExactAlarm({
    required String id,
    required int timeMsUTC,
    required String title,
    required bool isEssential,
  });

  /// Cancels a scheduled alarm.
  Future<bool> cancelAlarm(String id);
}

class MethodChannelAlarmPlatform implements AlarmPlatform {
  const MethodChannelAlarmPlatform();

  @override
  Future<bool> scheduleExactAlarm({
    required String id,
    required int timeMsUTC,
    required String title,
    required bool isEssential,
  }) {
    return NativeBridge.scheduleExactAlarm(
      id: id,
      timeMsUTC: timeMsUTC,
      title: title,
      isEssential: isEssential,
    );
  }

  @override
  Future<bool> cancelAlarm(String id) {
    return NativeBridge.cancelAlarm(id);
  }
}
