import 'dart:async';

import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/ai/engines/helpers/sensitive_reflection_filter.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

// Per-module identity for the native home-screen widget (Kotlin can't use
// Flutter IconData/Color, so we mirror an emoji + hex accent per moduleId).
const Map<String, String> kWidgetModuleEmoji = {
  'sleep': '🌙', 'sports': '🏋️', 'energy': '⚡', 'medicine': '💊',
  'worship': '🕌', 'cycle': '🌸', 'goals': '🚩', 'courses': '📚', 'konkur': '📝',
};
const Map<String, String> kWidgetModuleColor = {
  'sleep': '#8B5CF6', 'sports': '#10B981', 'energy': '#EC4899', 'medicine': '#EF4444',
  'worship': '#FBBF24', 'cycle': '#EC4899', 'goals': '#F59E0B', 'courses': '#3B82F6', 'konkur': '#8B5CF6',
};

class SnapshotSyncService {
  static Future<void> syncDailyRhythmForDate(Database db, String dateStr, Map<String, String> settingsMap) async {
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

        final moduleEnabled = _isModuleEnabled(category, settingsMap);

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

  static Future<void> backfillRhythmLogs(Database db, Map<String, String> settingsMap) async {
    final minDateResult = await db.rawQuery('SELECT MIN(completionDate) as minDate FROM routine_completions');
    if (minDateResult.isEmpty || minDateResult.first['minDate'] == null) {
      return;
    }

    final earliestDateStr = minDateResult.first['minDate']! as String;
    final earliestDate = DateTime.tryParse(earliestDateStr);
    if (earliestDate == null) return;

    final now = DateTime.now();

    // We want to check all dates from earliestDate up to yesterday
    var checkDate = earliestDate;
    while (checkDate.isBefore(now)) {
      final checkDateStr = checkDate.toIso8601String().substring(0, 10);
      final todayStr = now.toIso8601String().substring(0, 10);

      if (checkDateStr != todayStr) {
        // Check if a record already exists
        final existing = await db.query('daily_rhythm', where: 'date = ?', whereArgs: [checkDateStr]);
        if (existing.isEmpty) {
          debugPrint('SnapshotSyncService: Backfilling rhythm snapshot for $checkDateStr');
          await syncDailyRhythmForDate(db, checkDateStr, settingsMap);
        }
      }
      checkDate = checkDate.add(const Duration(days: 1));
    }
  }

  static Future<void> syncAll() async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // 1. Get active settings
    final settingsResult = await db.query('app_settings');
    final settingsMap = {for (final s in settingsResult) s['key']! as String: s['value']! as String};

    // Run backfill engine for missing days
    await backfillRhythmLogs(db, settingsMap);

    // Sync today's rhythm snapshot
    await syncDailyRhythmForDate(db, todayStr, settingsMap);

    // Backfill missing occurrences and pre-generate future 30 days
    await RoutineOccurrenceGenerator.backfillAndGenerateAll(db);

    // 2. Query today's completions and calculate weighted rhythm score
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

        // Check if the module is enabled (Node Zero check equivalent)
        final categoryStr = rMap['category']! as String;
        final isBuiltIn = Category.values.any((e) => e.name == categoryStr);
        final category = isBuiltIn 
            ? Category.values.firstWhere(
                (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
                orElse: () => Category.custom,
              )
            : Category.custom;

        final customCategoryId = isBuiltIn ? null : categoryStr;
        final moduleEnabled = _isModuleEnabled(category, settingsMap);

        if (moduleEnabled) {
          final isAsNeeded = routineTypeStr == 'asNeeded' || routineTypeStr == RoutineType.asNeeded.name;
          final completion = completionMap[rId];
          final isSystemResult = completion != null && completion['resultSource'] == 'SYSTEM';

          if (!isAsNeeded && !isSystemResult) {
            totalWeight += priority;
            if (completion != null) {
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

    // 3. Resolve energy
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

    // 4. Resolve next proposed task
    final isMenstruating = await DatabaseHelper.instance.isUserMenstruating();
    final nextTask = ContextEngine.getNextProposedTask(
      activeTasksForToday: activeTasks,
      completedRoutineIdsToday: completedIds.toList(),
      appSettings: settingsMap,
      blockedZoneIdsForRoutines: {},
      isMenstruating: isMenstruating,
    );

    // 5. Update widget snapshot
    await SnapshotHelper.updateWidgetSnapshot(
      nextActionTitle: nextTask?.routine.title ?? 'استراحت 🌿',
      rhythmScore: rhythmScore,
      currentEnergyLevel: resolvedEnergy.name,
    );

    // 5b. Full home-screen widget snapshot (single source for foreground AND
    //     the background WorkManager task — keeps the widget fresh without the
    //     app open, with zero business logic mirrored into Kotlin).
    try {
      final en = resolvedEnergy.name.toLowerCase();
      final modules = await _buildWidgetModules(
        db: db,
        s: settingsMap,
        now: now,
        resolvedEnergy: resolvedEnergy,
        routinesResult: routinesResult,
        completions: completions,
      );
      await SnapshotHelper.updateFullWidgetSnapshot(
        rhythmScore: rhythmScore,
        nextActionTitle: nextTask?.routine.title ?? 'استراحت 🌿',
        energyLabel: en == 'low' ? 'کم' : en == 'high' ? 'زیاد' : 'متوسط',
        energyPercent: en == 'low' ? 30 : en == 'high' ? 90 : 65,
        modules: modules,
      );
      await sl<NotificationPlatform>().refreshWidgets();
    } catch (e) {
      debugPrint('SnapshotSyncService: full widget snapshot failed: $e');
    }

    // 5c. Update Agenda Widget Snapshot (Zero-Leak filtered, chronological today's items)
    try {
      final dayAgenda = await DayAgendaService.instance.agendaForDate(
        now,
        options: const AgendaQueryOptions(),
      );

      // Filter out cycle and sensitive items (Zero-Leak)
      final filteredItems = dayAgenda.items.where((item) {
        if (item.domain == AgendaDomain.cycle) return false;
        
        final categoryStr = item.category.name.toLowerCase();
        if (categoryStr == 'medical' || categoryStr == 'cycle') return false;

        final titleLower = item.title.toLowerCase();
        final subtitleLower = (item.subtitle ?? '').toLowerCase();

        for (final kw in SensitiveReflectionFilter.cycleKeywords) {
          if (titleLower.contains(kw) || subtitleLower.contains(kw)) return false;
        }
        for (final kw in SensitiveReflectionFilter.medicalKeywords) {
          if (titleLower.contains(kw) || subtitleLower.contains(kw)) return false;
        }

        return true;
      }).toList();

      // Sort items: pending first, then completed. Timed first, then untimed.
      filteredItems.sort((a, b) {
        final aComp = a.isCompleted ? 1 : 0;
        final bComp = b.isCompleted ? 1 : 0;
        if (aComp != bComp) return aComp.compareTo(bComp);

        final aTimed = a.isTimed ? 0 : 1;
        final bTimed = b.isTimed ? 0 : 1;
        if (aTimed != bTimed) return aTimed.compareTo(bTimed);

        if (a.isTimed && b.isTimed) {
          return a.timeOfDay!.compareTo(b.timeOfDay!);
        }

        return b.priority.compareTo(a.priority); // Higher priority first
      });

      final jalali = Jalali.now();
      final formattedDate = '${jalali.formatter.wN}، ${toPersianDigits(jalali.day.toString())} ${jalali.formatter.mN}';

      final completedCount = filteredItems.where((i) => i.isCompleted).length;
      final totalCount = filteredItems.length;
      final remainingCount = totalCount - completedCount;
      final remainingText = totalCount == 0 
          ? 'امروز چیزی برنامه‌ریزی نشده'
          : '${toPersianDigits(remainingCount.toString())} از ${toPersianDigits(totalCount.toString())} مانده';

      final itemsData = filteredItems.map((item) {
        return {
          'id': item.id,
          'title': item.title,
          'time': item.timeOfDay != null ? toPersianDigits(item.timeOfDay!) : '',
          'isCompleted': item.isCompleted,
          'routineId': item.domain == AgendaDomain.routine ? item.sourceId : '',
          'dateStr': item.dateStr,
          'domain': item.domain.name,
          'isTickable': item.domain == AgendaDomain.routine,
        };
      }).toList();

      await SnapshotHelper.updateAgendaWidgetSnapshot(
        dateStr: formattedDate,
        remainingText: remainingText,
        items: itemsData,
      );
    } catch (e, st) {
      debugPrint('SnapshotSyncService: agenda widget snapshot failed: $e\n$st');
    }

    // Include both routine-linked reminders, standalone alarms (doctor visits),
    // and course session reminders.
    final activeReminders = await db.rawQuery('''
      SELECT pr.id, pr.routineId, pr.scheduledTime,
             COALESCE(
               r.title, 
               'نوبت پزشک: ' || dv.doctorName, 
               'کلاس: ' || c.title, 
               pr.id
             ) AS title,
             CASE 
               WHEN r.isEssential IS NOT NULL THEN r.isEssential
               WHEN dv.id IS NOT NULL THEN 1
               ELSE 0
             END AS isEssential
      FROM pending_reminders pr
      LEFT JOIN routines r ON pr.routineId = r.id
      LEFT JOIN doctor_visits dv ON pr.id = 'visit_' || dv.id
      LEFT JOIN course_sessions cs ON pr.courseSessionId = cs.id
      LEFT JOIN courses c ON cs.courseId = c.id
      WHERE (pr.state = 'unknown' OR pr.state = 'delayed' OR pr.state = 'SCHEDULED')
        AND (r.isArchived = 0 OR r.id IS NULL)
    ''');

    await SnapshotHelper.updateActiveAlarmsSnapshot(activeReminders);
    await SnapshotHelper.updateNotificationSettingsSnapshot(settingsMap);
  }

  /// Builds the active-module rows for the full home-screen widget. Mirrors
  /// DashboardController._buildModuleSummaries but is fully self-contained
  /// (computes from db/settings only) so it also runs in the headless
  /// background isolate. Each module is independently guarded — a failure in
  /// one degrades that row, never the whole snapshot.
  static Future<List<Map<String, String>>> _buildWidgetModules({
    required Database db,
    required Map<String, String> s,
    required DateTime now,
    required EnergyLevel resolvedEnergy,
    required List<Map<String, Object?>> routinesResult,
    required List<Map<String, Object?>> completions,
  }) async {
    final out = <Map<String, String>>[];
    String fa(Object v) => toPersianDigits(v.toString());
    Map<String, String> row(String id, String title, String primary, String secondary) => {
          'id': id,
          'title': title,
          'primary': primary,
          'secondary': secondary,
          'emoji': kWidgetModuleEmoji[id] ?? '•',
          'color': kWidgetModuleColor[id] ?? '#10B981',
        };

    // خواب
    if (s['module_sleep_enabled'] == 'true') {
      try {
        final rows = await db.query('bedtime_diagnostics', orderBy: 'date DESC', limit: 1);
        if (rows.isNotEmpty) {
          final log = SleepLog.fromMap(rows.first);
          final h = log.durationMinutes ~/ 60;
          final m = log.durationMinutes % 60;
          out.add(row('sleep', 'خواب', '${fa(h)}:${fa(m.toString().padLeft(2, '0'))} ساعت',
              'کیفیت دیشب: ${log.quality.emoji} ${log.quality.label}'));
        } else {
          out.add(row('sleep', 'خواب', '—', 'هنوز خوابی ثبت نشده'));
        }
      } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
    }

    // ورزش
    if (s['module_sports_enabled'] == 'true') {
      try {
        final weekAgo = now.subtract(const Duration(days: 7)).millisecondsSinceEpoch;
        final rows = await db.query('workout_logs', where: 'loggedAt >= ?', whereArgs: [weekAgo]);
        final sessions = rows.length;
        final minutes = rows.fold<int>(0, (a, r) => a + ((r['durationMinutes'] as int?) ?? 0));
        out.add(row('sports', 'ورزش', '${fa(sessions)} جلسه', 'این هفته: ${fa(minutes)} دقیقه'));
      } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
    }

    // انرژی و مود — از سطح انرژیِ resolved
    if (s['module_energy_enabled'] == 'true') {
      final en = resolvedEnergy.name.toLowerCase();
      final label = en == 'low' ? 'کم' : en == 'high' ? 'زیاد' : 'متوسط';
      final pct = en == 'low' ? 30 : en == 'high' ? 90 : 65;
      out.add(row('energy', 'انرژی و مود', '${fa(pct)}٪', 'سطح: $label'));
    }

    // دارو — پایبندی امروز
    if (s['module_medicine_enabled'] == 'true') {
      try {
        final medRoutines = routinesResult
            .where((r) => (r['category'] as String?)?.toLowerCase() == 'medical')
            .toList();
        final totalDoses = medRoutines.fold<int>(0, (a, r) {
          final mx = (r['maxDosesPerDay'] as int?) ?? 1;
          return a + (mx <= 0 ? 1 : mx);
        });
        var taken = 0;
        for (final r in medRoutines) {
          final rId = r['id']! as String;
          taken += completions.where((c) => c['routineId'] == rId).length;
        }
        final pct = totalDoses > 0 ? ((taken / totalDoses) * 100).round().clamp(0, 100) : 0;
        final remaining = (totalDoses - taken) < 0 ? 0 : (totalDoses - taken);
        out.add(row('medicine', 'دارو', '${fa(pct)}٪', 'پایبندی امروز · ${fa(remaining)} باقی‌مانده'));
      } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
    }

    // عبادت — قضاها + نماز بعدی (best-effort)
    if (s['module_religion_enabled'] == 'true') {
      try {
        final debtsRows = await db.query('worship_debts', where: 'isArchived = 0');
        final debts = debtsRows.length;
        var secondaryText = 'برنامه‌ی عبادی';
        try {
          final homeCityId = s['home_city_id'] ?? 'TEHRAN_TEHRAN';
          final prayerTimes = await PrayerTimeProvider.instance
              .getPrayerTimesForDate(cityId: homeCityId, date: now);
          secondaryText = _nextPrayerText(prayerTimes, now) ?? secondaryText;
        } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
        out.add(row('worship', 'عبادت', debts > 0 ? '${fa(debts)} قضا' : 'به‌روز ✓', secondaryText));
      } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
    }

    // چرخه — فاز فعلی (هم‌شرط با داشبورد)
    if (s['module_cycle_enabled'] == 'true' &&
        s['cycle_consent_dashboard'] == 'true' &&
        s['cycle_setup_done'] == 'true') {
      try {
        final output = await CycleEngine()
            .calculate(CycleEngineInput(db: db, appSettings: s, now: now));
        final p = output.currentPhase;
        final label = p == CyclePhase.menstrual
            ? 'قاعدگی'
            : p == CyclePhase.follicular
                ? 'فولیکولار'
                : p == CyclePhase.ovulation
                    ? 'تخمک‌گذاری'
                    : 'لوتئال';
        out.add(row('cycle', 'چرخه بدن', label, 'فاز کنونی بدن'));
      } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
    }

    // اهداف / دوره‌ها / کنکور — از اجندای مشترکِ امروز
    final goalsEnabled = s['module_goals_enabled'] == 'true';
    final coursesEnabled = s['module_courses_enabled'] == 'true';
    final konkurEnabled = s['module_konkur_enabled'] == 'true';
    if (goalsEnabled || coursesEnabled || konkurEnabled) {
      try {
        final dayAgenda = await DayAgendaService.instance.agendaForDate(
          now,
          options: const AgendaQueryOptions(),
        );
        final items = dayAgenda.items;
        if (goalsEnabled) {
          final steps = items.where((i) => i.domain == AgendaDomain.goalStep).toList();
          final total = steps.length;
          final done = steps.where((i) => i.isCompleted).length;
          out.add(row('goals', 'اهداف', total > 0 ? '${fa(done)}/${fa(total)}' : '—', 'گام‌های امروز'));
        }
        if (coursesEnabled) {
          final sessions =
              items.where((i) => i.domain == AgendaDomain.course && !i.isCompleted).length;
          out.add(row('courses', 'دوره‌ها', '${fa(sessions)} جلسه', 'مطالعه‌ی امروز'));
        }
        if (konkurEnabled) {
          final konkur = items
              .where((i) => i.domain == AgendaDomain.konkur && i.completion == AgendaCompletion.pending)
              .length;
          out.add(row('konkur', 'کنکور', '${fa(konkur)} مبحث', 'برنامه‌ی امروز'));
        }
      } catch (e, st) {
        debugPrint('Error in SnapshotSyncService module loader: $e\n$st');
      }
    }

    return out;
  }

  /// Returns `"<prayer name>: <time>"` for the next prayer today (Persian digits),
  /// or null if prayer times are unavailable.
  static String? _nextPrayerText(Map<String, String> prayerTimes, DateTime now) {
    int? toMin(String? t) {
      if (t == null || !t.contains(':')) return null;
      final p = t.split(':');
      final h = int.tryParse(p[0]);
      final m = int.tryParse(p[1]);
      if (h == null || m == null) return null;
      return h * 60 + m;
    }

    final cur = now.hour * 60 + now.minute;
    final fajr = toMin(prayerTimes['fajr']);
    final dhuhr = toMin(prayerTimes['dhuhr']);
    final maghrib = toMin(prayerTimes['maghrib']);
    final isha = toMin(prayerTimes['isha']);

    String? name;
    String? time;
    if (fajr != null && cur < fajr) {
      name = 'اذان صبح';
      time = prayerTimes['fajr'];
    } else if (dhuhr != null && cur < dhuhr) {
      name = 'اذان ظهر';
      time = prayerTimes['dhuhr'];
    } else if (maghrib != null && cur < maghrib) {
      name = 'اذان مغرب';
      time = prayerTimes['maghrib'];
    } else if (isha != null && cur < isha) {
      name = 'نماز عشا';
      time = prayerTimes['isha'];
    } else if (fajr != null) {
      name = 'اذان صبح فردا';
      time = prayerTimes['fajr'];
    }
    if (name != null && time != null) return '$name: ${toPersianDigits(time)}';
    return null;
  }

  static bool _isModuleEnabled(Category category, Map<String, String> settings) {
    switch (category) {
      case Category.religious:
        return settings['module_religion_enabled'] == 'true';
      case Category.medical:
        return settings['module_medicine_enabled'] == 'true';
      case Category.learning:
        return settings['module_courses_enabled'] == 'true';
      case Category.konkur:
        return settings['module_konkur_enabled'] == 'true';
      case Category.custom:
        return true;
      default:
        return true;
    }
  }
}

