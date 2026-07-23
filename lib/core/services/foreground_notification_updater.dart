import 'package:flutter/foundation.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/reflection_context.dart';
import 'package:ritmo/core/platform/notification_platform.dart';

class ForegroundNotificationUpdater {
  static Future<void> update() async {
    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Check if persistent status notification is enabled in settings
      final settingsList = await db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['persistent_status_notification_enabled'],
      );
      final isEnabled = settingsList.isEmpty || settingsList.first['value'] != 'false';

      if (!isEnabled) {
        await sl<NotificationPlatform>().stopForegroundService();
        return;
      }

      // 2. Fetch all required data to evaluate
      final settingsMap = {
        for (final row in await db.query('app_settings'))
          row['key']! as String: row['value']! as String
      };

      // RIE details
      final activeZoneId = settingsMap['active_zone_id'] ?? 'default_zone';
      final activeZoneMode = settingsMap['active_zone_mode'] ?? 'WORK';
      final currentEnergyStr = settingsMap['current_energy_state'] ?? 'MEDIUM';
      final currentEnergy = EnergyLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == currentEnergyStr.toLowerCase(),
        orElse: () => EnergyLevel.medium,
      );
      
      // Determine zone name
      var actZoneName = 'آزاد';
      if (activeZoneId != 'default_zone') {
        final List<Map<String, dynamic>> zones = await db.query(
          'zones',
          where: 'id = ?',
          whereArgs: [activeZoneId],
        );
        if (zones.isNotEmpty) {
          actZoneName = zones.first['name'] as String;
        }
      }

      // Is menstruating
      final isMenstruating = await DatabaseHelper.instance.isUserMenstruating();

      // Routines list
      final List<Map<String, dynamic>> routinesMapList = await db.query(
        'routines',
        where: 'isArchived = 0',
      );
      final routineList = routinesMapList.map(Routine.fromMap).toList();

      // Reflection Context
      final nowTime = DateTime.now();
      ReflectionContext? reflectionContext;
      try {
        final reflectionMaps = await db.query('daily_reflections', orderBy: 'date DESC');
        if (reflectionMaps.isNotEmpty) {
          final checkinMaps = await db.query('daily_checkins', orderBy: 'date DESC');
          final energyLogs = await db.query('energy_logs');
          final moodLogs = await db.query('mood_logs');

          final out = await RitmoEngineBus.instance.execute<ReflectionEngineInput, ReflectionEngineOutput>(
            ReflectionEngine,
            ReflectionEngineInput(
              dailyReflections: reflectionMaps,
              dailyCheckins: checkinMaps,
              energyLogs: energyLogs,
              moodLogs: moodLogs,
              today: nowTime,
            ),
          );

          if (out.entryCount > 0) {
            var direction = MoodTrendDirection.flat;
            final trend = out.moodTrend;
            if (trend.length >= 2) {
              final delta = trend.last - trend.first;
              if (delta > 0.3) {
                direction = MoodTrendDirection.up;
              } else if (delta < -0.3) {
                direction = MoodTrendDirection.down;
              }
            }

            reflectionContext = ReflectionContext(
              avgMoodScore: out.avgMoodScore,
              moodTrendDirection: direction,
              currentStreak: out.currentStreak,
              reflectionEnergyCorrelation: out.reflectionEnergyCorrelation,
            );
          }
        }
      } catch (e) {
        debugPrint('Error building reflection context in background: $e');
      }

      // Evaluate
      final engineOutput = await RitmoIntelligenceEngine.evaluate(
        routines: routineList,
        appSettings: settingsMap,
        activeZoneId: activeZoneId,
        activeZoneMode: activeZoneMode,
        currentEnergy: currentEnergy,
        isMenstruating: isMenstruating,
        now: nowTime,
        db: db,
        reflectionContext: reflectionContext,
      );

      final nextTask = engineOutput.suggestedRoutine;

      // 1. Fetch routines progress stats for today
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final occurrences = await db.query(
        'routine_occurrences',
        where: 'date = ?',
        whereArgs: [todayStr],
      );
      final totalRoutines = occurrences.length;
      final completedRoutines = occurrences.where((e) => e['status'] == 'done').length;

      // 2. Fetch worship practices completion stats for today
      final activePrayers = await db.query(
        'worship_practices',
        where: 'isActive = 1',
      );
      final completedPrayersList = await db.query(
        'worship_practices',
        where: 'dailyDoneDate = ? AND dailyDone >= 1 AND isActive = 1',
        whereArgs: [todayStr],
      );
      final totalPrayers = activePrayers.length;
      final completedPrayers = completedPrayersList.length;

      // 3. Fetch list of available zones
      final zonesList = await db.query('zones');
      final zoneNames = zonesList.map((e) => e['name']! as String).toList();
      final zoneIds = zonesList.map((e) => e['id']! as String).toList();

      // Update Native notification
      await sl<NotificationPlatform>().startStatusMode(
        zone: actZoneName,
        energy: currentEnergyStr == 'LOW' ? 'پایین' : (currentEnergyStr == 'HIGH' ? 'بالا' : 'متوسط'),
        proposedTask: nextTask?.title ?? 'استراحت 🌿',
        proposedTaskId: nextTask?.id,
        completedRoutines: completedRoutines,
        totalRoutines: totalRoutines,
        completedPrayers: completedPrayers,
        totalPrayers: totalPrayers,
        zoneNames: zoneNames,
        zoneIds: zoneIds,
      );
    } catch (e, stack) {
      debugPrint('[ForegroundNotificationUpdater] failed to update notification: $e\n$stack');
    }
  }
}

