import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/sync/sync_module_gate.dart';
import 'package:sqflite/sqflite.dart';

class RhythmSnapshotService {
  const RhythmSnapshotService();

  Future<void> syncDailyRhythmForDate({
    required Database db,
    required String dateStr,
    required Map<String, String> settingsMap,
  }) async {
    // 1. Get completions for dateStr
    final completions = await db.query(
      'routine_completions',
      where: 'completionDate = ?',
      whereArgs: [dateStr],
    );
    final completionMap = {
      for (final c in completions) c['routineId']! as String: c
    };

    // 2. Load all active routines and schedules
    final routinesResult = await db.query('routines', where: 'isArchived = 0');
    final schedulesResult = await db.query('routine_schedules');

    var totalRoutines = 0;
    var completedRoutines = 0;
    var criticalRoutines = 0;
    var totalWeight = 0.0;
    var completedWeight = 0.0;

    for (final rMap in routinesResult) {
      final rId = rMap['id']! as String;
      final schedule = schedulesResult.firstWhere(
        (s) => s['routineId'] == rId,
        orElse: () => <String, dynamic>{},
      );

      if (schedule.isNotEmpty) {
        final priority = rMap['priority'] as double? ?? 1.0;
        final routineTypeStr = rMap['routineType']! as String;
        final isEssential = rMap['isEssential'] == 1;

        // Check if the module is enabled
        final categoryStr = rMap['category']! as String;
        final isBuiltIn = Category.values.any((e) => e.name == categoryStr);
        final category = isBuiltIn 
            ? Category.values.firstWhere(
                (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
                orElse: () => Category.custom,
              )
            : Category.custom;

        final moduleEnabled = SyncModuleGate.isModuleEnabled(category, settingsMap);

        if (moduleEnabled) {
          final isAsNeeded = routineTypeStr == 'asNeeded' || routineTypeStr == RoutineType.asNeeded.name;
          final completion = completionMap[rId];
          final isSystemResult = completion != null && completion['resultSource'] == 'SYSTEM';

          if (!isAsNeeded && !isSystemResult) {
            totalRoutines++;
            totalWeight += priority;
            
            if (completion != null) {
              completedRoutines++;
              if (isEssential) {
                criticalRoutines++;
              }
              final resType = completion['resultType'] as String? ?? 'FULL';
              var completionValue = 0.0;
              if (resType == 'FULL') {
                completionValue = 1.0;
              } else if (resType == 'LIGHT') {
                completionValue = 0.7;
              } else if (resType == 'MINIMAL') {
                completionValue = 0.4;
              }
              completedWeight += completionValue * priority;
            }
          }
        }
      }
    }

    var rhythmScore = 0;
    if (totalWeight > 0) {
      rhythmScore = ((completedWeight / totalWeight) * 100).round();
    }
    final completionRatio = totalRoutines > 0 ? (completedRoutines / totalRoutines) : 0.0;

    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // Insert or replace in daily_rhythm table
    await db.insert(
      'daily_rhythm',
      {
        'date': dateStr,
        'rhythmScore': rhythmScore,
        'scheduledCount': totalRoutines,
        'countedCount': completedRoutines,
        'successCount': completedRoutines,
        'essentialMet': criticalRoutines,
        'energyDrained': 0,
        'energyRecharged': 0,
        'lifeBalanceScore': 0,
        'isGraceDay': 0,
        'updatedAt': nowMs,
        'rhythm_score': rhythmScore,
        'total_routines': totalRoutines,
        'completed_routines': completedRoutines,
        'critical_routines': criticalRoutines,
        'completion_ratio': completionRatio,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> backfillRhythmLogs({
    required Database db,
    required Map<String, String> settingsMap,
  }) async {
    final minDateResult = await db.rawQuery('SELECT MIN(completionDate) as minDate FROM routine_completions');
    if (minDateResult.isEmpty || minDateResult.first['minDate'] == null) {
      return;
    }

    final earliestDateStr = minDateResult.first['minDate']! as String;
    final earliestDate = DateTime.tryParse(earliestDateStr);
    if (earliestDate == null) return;

    final now = DateTime.now();

    // Check all dates from earliestDate up to yesterday
    var checkDate = earliestDate;
    while (checkDate.isBefore(now)) {
      final checkDateStr = checkDate.toIso8601String().substring(0, 10);
      final todayStr = now.toIso8601String().substring(0, 10);

      if (checkDateStr != todayStr) {
        // Check if a record already exists
        final existing = await db.query('daily_rhythm', where: 'date = ?', whereArgs: [checkDateStr]);
        if (existing.isEmpty) {
          debugPrint('RhythmSnapshotService: Backfilling rhythm snapshot for $checkDateStr');
          await syncDailyRhythmForDate(
            db: db,
            dateStr: checkDateStr,
            settingsMap: settingsMap,
          );
        }
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
  }
}
