// lib/core/domain/engines/rie/context_resolver.dart

import 'package:ritmo/core/domain/engines/rie/context_snapshot.dart';
import 'package:ritmo/core/domain/engines/rie/daily_behavior_resolver.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/reflection_context.dart';
import 'package:sqflite/sqflite.dart';

class ContextResolver {
  ContextResolver._();

  /// Infrastructure component to pre-fetch all database context inputs and build
  /// an immutable [ContextSnapshot] in a single transaction/batch.
  static Future<ContextSnapshot> resolve({
    required List<Routine> routines,
    required Map<String, String> appSettings,
    required String? activeZoneId,
    required String? activeZoneMode,
    required EnergyLevel currentEnergy,
    required bool isMenstruating,
    required DateTime now,
    required DatabaseExecutor db,
    ReflectionContext? reflectionContext,
  }) async {
    final dateStr = now.toIso8601String().substring(0, 10);

    // 1. Fetch Calendar Exceptions for today
    final calendarExceptionsToday = await db.query(
      'calendar_exceptions',
      where: 'date = ?',
      whereArgs: [dateStr],
    );

    // 2. Fetch Active Worship Seasons
    final activeWorshipSeasonsToday = await db.query(
      'worship_seasons',
      where: 'isActive = 1 AND startDate <= ? AND endDate >= ?',
      whereArgs: [dateStr, dateStr],
    );

    // 3. Fetch Konkur Mock Exams scheduled for today
    final konkurMockExamsToday = await db.query(
      'konkur_mock_exams',
      where: 'examDate = ?',
      whereArgs: [dateStr],
    );

    // 4. Fetch all routines (non-archived) for busy checks
    final nonArchivedRoutinesRaw = await db.query(
      'routines',
      where: 'isArchived = 0',
    );

    // 5. Fetch all routine schedules
    final allSchedulesRaw = await db.query('routine_schedules');

    // 6. Fetch completions for today (excluding snoozed)
    final completionsListToday = await db.query(
      'routine_completions',
      where: 'completionDate = ? AND resultType != ?',
      whereArgs: [dateStr, 'SNOOZED'],
    );
    final completedRoutineIdsToday = completionsListToday
        .map((c) => c['routineId']! as String)
        .toSet();

    // 7. Fetch Zone blocked rules
    final blockedRoutineIdsInZone = <String>{};
    if (activeZoneId != null) {
      final zoneRules = await db.query(
        'routine_zone_rules',
        where: 'zoneId = ? AND ruleType = ?',
        whereArgs: [activeZoneId, 'BLOCKED'],
      );
      for (final rule in zoneRules) {
        final rId = rule['routineId'] as String?;
        if (rId != null) {
          blockedRoutineIdsInZone.add(rId);
        }
      }
    }

    // 8. Resolve DailyBehavior context
    final dailyBehavior = DailyBehaviorResolver.resolve(
      date: now,
      settings: appSettings,
      calendarExceptionsToday: calendarExceptionsToday,
      activeWorshipSeasonsToday: activeWorshipSeasonsToday,
      konkurMockExamsToday: konkurMockExamsToday,
      nonArchivedRoutines: nonArchivedRoutinesRaw,
      routineSchedules: allSchedulesRaw,
    );

    // Map schedules by routine ID for quick O(1) lookup inside scorers/filters
    final routineSchedulesByRoutineId = <String, Map<String, dynamic>>{};
    for (final s in allSchedulesRaw) {
      final rId = s['routineId'] as String?;
      if (rId != null) {
        routineSchedulesByRoutineId[rId] = s;
      }
    }

    return ContextSnapshot(
      now: now,
      appSettings: appSettings,
      activeZoneId: activeZoneId,
      activeZoneMode: activeZoneMode,
      currentEnergy: currentEnergy,
      isMenstruating: isMenstruating,
      reflectionContext: reflectionContext,
      dailyBehavior: dailyBehavior,
      blockedRoutineIdsInZone: blockedRoutineIdsInZone,
      completedRoutineIdsToday: completedRoutineIdsToday,
      routineSchedulesByRoutineId: routineSchedulesByRoutineId,
      enteredRoutines: routines,
    );
  }
}
