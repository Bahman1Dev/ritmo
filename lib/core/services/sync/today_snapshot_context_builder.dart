import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/sync/models/today_snapshot_state.dart';
import 'package:ritmo/core/services/sync/sync_module_gate.dart';
import 'package:sqflite/sqflite.dart';

class TodaySnapshotContextBuilder {
  const TodaySnapshotContextBuilder();

  Future<TodaySnapshotState> build({
    required Database db,
    required DateTime now,
    required Map<String, String> settingsMap,
  }) async {
    final todayStr = now.toIso8601String().substring(0, 10);

    // Query today's completions and calculate weighted rhythm score
    final completions = await db.query(
      'routine_completions',
      where: 'completionDate = ?',
      whereArgs: [todayStr],
    );
    final completedIds = completions.map((c) => c['routineId']! as String).toSet();
    final completionMap = {
      for (final c in completions) c['routineId']! as String: c
    };

    final routinesResult = await db.query('routines', where: 'isArchived = 0');
    final schedulesResult = await db.query('routine_schedules');

    final activeTasks = <RoutineTask>[];
    var totalWeight = 0.0;
    var completedWeight = 0.0;

    for (final rMap in routinesResult) {
      final rId = rMap['id']! as String;
      final schedule = schedulesResult.firstWhere(
        (s) => s['routineId'] == rId,
        orElse: () => <String, dynamic>{},
      );

      if (schedule.isNotEmpty) {
        final timeOfDayStr = schedule['timeOfDay'] as String? ?? '08:00';
        final parts = timeOfDayStr.split(':');
        final schedTime = now.copyWith(
          hour: int.tryParse(parts[0]) ?? 8,
          minute: int.tryParse(parts[1]) ?? 0,
          second: 0,
        );

        final priority = rMap['priority'] as double? ?? 1.0;
        final routineTypeStr = rMap['routineType']! as String;

        // Check if the module is enabled
        final categoryStr = rMap['category']! as String;
        final isBuiltIn = Category.values.any((e) => e.name == categoryStr);
        final category = isBuiltIn 
            ? Category.values.firstWhere(
                (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
                orElse: () => Category.custom,
              )
            : Category.custom;

        final customCategoryId = isBuiltIn ? null : categoryStr;
        final moduleEnabled = SyncModuleGate.isModuleEnabled(category, settingsMap);

        if (moduleEnabled) {
          final isAsNeeded = routineTypeStr == 'asNeeded' || routineTypeStr == RoutineType.asNeeded.name;
          final completion = completionMap[rId];
          final isSystemResult = completion != null && completion['resultSource'] == 'SYSTEM';

          if (!isAsNeeded && !isSystemResult) {
            totalWeight += priority;
            if (completion != null) {
              final resType = completion['resultType'] as String?;
              final partialRatio = (completion['partialRatio'] as num?)?.toDouble();
              final completionValue = CompletionResult.fromDb(resType).rhythmWeight(partialRatio);
              completedWeight += completionValue * priority;
            }
          }

          final routine = Routine(
            id: rId,
            title: rMap['title']! as String,
            category: category,
            customCategoryId: customCategoryId,
            routineType: RoutineType.values.firstWhere(
              (e) => e.name.toLowerCase() == routineTypeStr.toLowerCase(),
              orElse: () => RoutineType.timeBased,
            ),
            notificationLevel: NotificationLevel.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['notificationLevel'] as String? ?? '').toLowerCase(),
              orElse: () => NotificationLevel.none,
            ),
            isEssential: rMap['isEssential'] == 1,
            isEssentialLocked: rMap['isEssentialLocked'] == 1,
            energyRule: EnergyRule.values.firstWhere(
              (e) => e.name.toLowerCase() == (rMap['energyRule'] as String? ?? '').toLowerCase(),
              orElse: () => EnergyRule.none,
            ),
            priority: priority,
            targetDurationMinutes: rMap['targetDurationMinutes'] as int?,
            lightDurationMinutes: rMap['lightDurationMinutes'] as int?,
            minimalDurationMinutes: rMap['minimalDurationMinutes'] as int?,
            progressionMode: rMap['progressionMode'] as String? ?? 'NONE',
            progressionStart: rMap['progressionStart'] as int? ?? 0,
            progressionTarget: rMap['progressionTarget'] as int? ?? 0,
            progressionStep: rMap['progressionStep'] as int? ?? 0,
            progressionEveryN: rMap['progressionEveryN'] as int? ?? 1,
            progressionCurrent: rMap['progressionCurrent'] as int? ?? 0,
            progressionDoneSinceAdvance: rMap['progressionDoneSinceAdvance'] as int? ?? 0,
            itemType: rMap['itemType'] as String? ?? 'ROUTINE',
          );

          activeTasks.add(RoutineTask(
            routine: routine,
            scheduleTimeStr: timeOfDayStr,
            scheduledTime: schedTime,
          ));
        }
      }
    }

    var rhythmScore = 0;
    if (totalWeight > 0) {
      rhythmScore = ((completedWeight / totalWeight) * 100).round();
    }

    // Resolve energy
    var resolvedEnergy = EnergyLevel.medium;
    final energyLog = await db.query('energy_logs', limit: 1, orderBy: 'loggedAt DESC');
    if (energyLog.isNotEmpty) {
      final eLevelStr = energyLog.first['energyLevel']! as String;
      final loggedAt = energyLog.first['loggedAt']! as int;
      final validity = int.tryParse(settingsMap['energy_validity_minutes'] ?? '180') ?? 180;
      final isStale = DateTime.now().millisecondsSinceEpoch - loggedAt > validity * 60 * 1000;

      if (!isStale) {
        resolvedEnergy = EnergyLevel.values.firstWhere(
          (e) => e.name.toLowerCase() == eLevelStr.toLowerCase(),
          orElse: () => EnergyLevel.medium,
        );
      }
    }

    // Resolve next proposed task
    final isMenstruating = await DatabaseHelper.instance.isUserMenstruating();
    final nextTask = ContextEngine.getNextProposedTask(
      activeTasksForToday: activeTasks,
      completedRoutineIdsToday: completedIds.toList(),
      appSettings: settingsMap,
      blockedZoneIdsForRoutines: {},
      isMenstruating: isMenstruating,
    );

    return TodaySnapshotState(
      now: now,
      todayStr: todayStr,
      settingsMap: settingsMap,
      completions: completions,
      completionMap: completionMap,
      completedIds: completedIds,
      routinesResult: routinesResult,
      schedulesResult: schedulesResult,
      activeTasks: activeTasks,
      rhythmScore: rhythmScore,
      resolvedEnergy: resolvedEnergy,
      nextTask: nextTask,
    );
  }
}
