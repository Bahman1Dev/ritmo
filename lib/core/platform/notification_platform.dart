// lib/core/platform/notification_platform.dart

import 'package:ritmo/core/services/native_bridge.dart';

abstract interface class NotificationPlatform {
  /// Starts the persistent foreground service in Status Mode.
  Future<bool> startStatusMode({
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
  });

  /// Starts the persistent foreground service in Timer Mode.
  Future<bool> startTimerMode({
    required String title,
    required int durationSeconds,
    required int elapsedSeconds,
  });

  /// Stops the persistent foreground service.
  Future<bool> stopForegroundService();

  /// Requests the home-screen widgets to repaint.
  Future<void> refreshWidgets();

  /// Fetches launch intent information if launched from notification action.
  Future<Map<String, dynamic>?> getLaunchIntent();
}

class MethodChannelNotificationPlatform implements NotificationPlatform {
  const MethodChannelNotificationPlatform();

  @override
  Future<bool> startStatusMode({
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
  }) {
    return NativeBridge.startStatusMode(
      zone: zone,
      energy: energy,
      proposedTask: proposedTask,
      proposedTaskId: proposedTaskId,
      completedRoutines: completedRoutines,
      totalRoutines: totalRoutines,
      completedPrayers: completedPrayers,
      totalPrayers: totalPrayers,
      zoneNames: zoneNames,
      zoneIds: zoneIds,
    );
  }

  @override
  Future<bool> startTimerMode({
    required String title,
    required int durationSeconds,
    required int elapsedSeconds,
  }) {
    return NativeBridge.startTimerMode(
      title: title,
      durationSeconds: durationSeconds,
      elapsedSeconds: elapsedSeconds,
    );
  }

  @override
  Future<bool> stopForegroundService() {
    return NativeBridge.stopForegroundService();
  }

  @override
  Future<void> refreshWidgets() {
    return NativeBridge.refreshWidgets();
  }

  @override
  Future<Map<String, dynamic>?> getLaunchIntent() {
    return NativeBridge.getLaunchIntent();
  }
}
