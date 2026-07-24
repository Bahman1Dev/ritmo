import 'dart:async';

import 'package:flutter/cupertino.dart'; // برای CupertinoIcons
import 'package:flutter/material.dart';
import 'package:ritmo/core/ai/ai_briefing_service.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/reflection_engine.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_engine_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_intelligence_engine.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/daily_behavior.dart';
import 'package:ritmo/core/domain/models/reflection_context.dart';
import 'package:ritmo/core/platform/notification_platform.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/core/utils/persian_digits.dart'; // toPersianDigits
import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/worship/logic/worship_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/sleep/models/sleep_models.dart';        // SleepLog, SleepQuality
import 'package:ritmo/features/today/presentation/widgets/dashboard/dashboard_module_summary.dart';
import 'package:sqflite/sqflite.dart';

class DashboardController {
  bool isLoading = true;
  int rhythmScore = 82;
  List<Map<String, dynamic>> completionsToday = [];
  RoutineTask? nextTask;
  AiBriefing? briefing;
  bool isBriefingLoading = false;


  // Timeline list representation
  List<Map<String, dynamic>> timelineItems = [];

  // 🔑 Single source of truth for "today" — fed by DayAgendaService.
  List<AgendaItem> agenda = [];

  // Typed adapter views over [agenda] so existing Home widgets keep working.
  List<Map<String, dynamic>> todaysGoalSteps = [];
  List<CourseSession> todaysCourseSessions = [];
  List<Course> allCourses = [];
  CycleEngineOutput? cycleEngineOutput;
  List<KonkurPlanItem> todaysKonkurPlanItems = [];
  List<KonkurSubject> konkurSubjects = [];
  List<KonkurTopic> konkurTopics = [];
  List<DashboardModuleSummary> moduleSummaries = [];

  // Specialized Dashboard state variables
  Map<String, String> settingsMap = {};
  List<Map<String, dynamic>> worshipDebts = [];
  Map<String, String> prayerTimes = {};
  List<Map<String, dynamic>> medicationRoutines = [];
  Map<String, int> medicationCompletionsToday = {};

  DailyBehavior? dailyBehavior;
  Map<String, dynamic>? activeZone;
  String? activeZoneName;
  String? activeZoneIcon;
  String? activeZoneTimeRange;
  String? activeZoneColorHex;
  int activeZoneRoutinesCount = 0;
  RitmoEngineOutput? engineOutput;
  bool needCheckin = true;
  bool hasReflection = false;
  bool reflectionDismissed = false;

  // Dynamic Energy State fields
  double currentEnergyPercent = 65;
  String currentEnergyLabel = 'متوسط';
  String currentEnergyDesc = 'مناسب برای مطالعه، پروژه‌ها و روتین‌ها';
  String currentEnergyTimeAgo = 'بر اساس پیش‌فرض';
  List<String> currentEnergyExplanation = [];
  String? peakPerformanceWindow;
  String? mostFatiguedWindow;
  String? mostProductiveWeekday;

  // Check if a category module is enabled
  bool _isModuleEnabled(Category category, Map<String, String> settings) {
    if (category == Category.custom) return true;
    final prefix = 'module_${category.name}_enabled';
    return settings[prefix] == 'true';
  }

  // ─────────────────────────────────────────────────────────
  // POP v1.1 — Two-phase loading
  //
  //  loadP0()  ← critical path — everything needed for first paint
  //             (settings, routines, zone, RIE, timeline, score)
  //  loadP1()  ← deferred path — everything below the fold
  //             (agenda sections, energy, dailyBehavior, widgets, native)
  //
  //  loadDashboardData() calls both in sequence (backward-compatible).
  // ─────────────────────────────────────────────────────────

  Future<void> loadDashboardData() async {
    await loadP0();
    await loadP1();
  }

  /// Phase 0 — blocks until the timeline and rhythm score are ready.
  Future<void> loadP0() async {
    try {
      isLoading = true;

      // Sync snapshots and run backfill engine
      await SnapshotSyncService.syncAll();

      final db = await DatabaseHelper.instance.database;

      // Ensure dummy routine exists for worship debts
      await _ensureWorshipDebtRoutineExists(db);

      final settings = await db.query('app_settings');
      settingsMap = <String, String>{for (final s in settings) s['key']! as String: s['value']! as String};

      // Load today's check-in status
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final checkins = await db.query(
        'daily_checkins',
        where: 'date = ?',
        whereArgs: [todayStr],
      );
      needCheckin = checkins.isEmpty;

      // Load today's reflection status
      final reflections = await db.query(
        'daily_reflections',
        where: 'date = ?',
        whereArgs: [todayStr],
      );
      hasReflection = reflections.isNotEmpty;

      // Check if reflection suggestion was dismissed today
      final dismissedReflectionDate = settingsMap['dismissed_reflection_date'] ?? '';
      reflectionDismissed = dismissedReflectionDate == todayStr;

      // 2. Load today's routine completions
      final completionsTodayRaw = await db.query(
        'routine_completions',
        where: 'completionDate = ?',
        whereArgs: [todayStr],
      );
      completionsToday = completionsTodayRaw.map(Map<String, dynamic>.from).toList();

      final completedIds = completionsToday
          .where((c) => c['resultType'] != 'SNOOZED' && c['resultType'] != 'CANNOT_NOW' && c['resultType'] != 'SKIPPED')
          .map((c) => c['routineId'] as String)
          .toSet();

      // Load today's routine occurrences
      final occurrencesToday = await db.query(
        'routine_occurrences',
        where: 'date = ?',
        whereArgs: [todayStr],
      );
      final occurrenceMap = {
        for (final o in occurrencesToday) o['routine_id']! as String: o
      };

      // 3. Load all active routines and schedules
      final routinesMapListRaw = await db.query('routines', where: 'isArchived = 0');
      final routinesMapList = routinesMapListRaw.map(Map<String, dynamic>.from).toList();
      final activeTasks = <RoutineTask>[];
      final medRoutines = <Map<String, dynamic>>[];
      final routineList = <Routine>[];

      for (final rMap in routinesMapList) {
        final rId = rMap['id'] as String;
        final categoryStr = rMap['category'] as String;
        final category = Category.values.firstWhere(
          (e) => e.name.toLowerCase() == categoryStr.toLowerCase(),
          orElse: () => Category.custom,
        );

        // Separate medical routines
        if (category == Category.medical) {
          medRoutines.add(rMap);
        }

        final moduleEnabled = _isModuleEnabled(category, settingsMap);

        final routine = Routine(
          id: rId,
          title: rMap['title'] as String,
          description: rMap['description'] as String?,
          category: category,
          customCategoryId: rMap['customCategoryId'] as String?,
          zoneId: rMap['zoneId'] as String?,
          routineType: RoutineType.values.firstWhere(
            (e) => e.name.toLowerCase() == (rMap['routineType'] as String? ?? '').toLowerCase(),
            orElse: () => RoutineType.timeBased,
          ),
          notificationLevel: NotificationLevel.values.firstWhere(
            (e) => e.name.toLowerCase() == (rMap['notificationLevel'] as String? ?? '').toLowerCase(),
            orElse: () => NotificationLevel.none,
          ),
          isEssential: rMap['isEssential'] == 1,
          isEssentialLocked: (rMap['isEssentialLocked'] as int? ?? 0) == 1,
          energyRule: EnergyRule.values.firstWhere(
            (e) => e.name.toLowerCase() == (rMap['energyRule'] as String? ?? '').toLowerCase(),
            orElse: () => EnergyRule.none,
          ),

          priority: rMap['priority'] as double? ?? 1.0,
          targetDurationMinutes: rMap['targetDurationMinutes'] as int?,
          lightDurationMinutes: rMap['lightDurationMinutes'] as int?,
          minimalDurationMinutes: rMap['minimalDurationMinutes'] as int?,
          medStockCount: rMap['medStockCount'] as int? ?? 0,
          medRefillThreshold: rMap['medRefillThreshold'] as int? ?? 0,
          minIntervalHours: rMap['minIntervalHours'] as int? ?? 0,
          maxDosesPerDay: rMap['maxDosesPerDay'] as int? ?? 0,
          progressionMode: rMap['progressionMode'] as String? ?? 'NONE',
          progressionStart: rMap['progressionStart'] as int? ?? 0,
          progressionTarget: rMap['progressionTarget'] as int? ?? 0,
          progressionStep: rMap['progressionStep'] as int? ?? 0,
          progressionEveryN: rMap['progressionEveryN'] as int? ?? 1,
          progressionCurrent: rMap['progressionCurrent'] as int? ?? 0,
          progressionDoneSinceAdvance: rMap['progressionDoneSinceAdvance'] as int? ?? 0,
          itemType: rMap['itemType'] as String? ?? 'ROUTINE',
        );

        if (moduleEnabled) {
          routineList.add(routine);
          final hasOccurrence = occurrenceMap.containsKey(rId);
          if (hasOccurrence) {
            final occ = occurrenceMap[rId]!;
            final timeOfDayStr = occ['scheduled_time'] as String? ?? '08:00';
            final parts = timeOfDayStr.split(':');
            final schedTime = DateTime.now().copyWith(
              hour: int.tryParse(parts[0]) ?? 8,
              minute: int.tryParse(parts[1]) ?? 0,
              second: 0,
              millisecond: 0,
              microsecond: 0,
            );

            activeTasks.add(RoutineTask(
              routine: routine,
              scheduleTimeStr: timeOfDayStr,
              scheduledTime: schedTime,
            ));
          }
        }
      }

      medicationRoutines = medRoutines;

      // Load medication completions today
      final medCompletions = <String, int>{};
      for (final rMap in medicationRoutines) {
        final rId = rMap['id'] as String;
        final count = completionsToday.where((c) => c['routineId'] == rId).length;
        medCompletions[rId] = count;
      }
      medicationCompletionsToday = medCompletions;

      // Calculate active zone name and parameters
      final actZone = await _resolveActiveZone(db, DateTime.now());
      activeZone = actZone;
      final activeZoneId = activeZone?['id'] as String?;
      final activeZoneMode = activeZone?['mode'] as String? ?? 'NORMAL';
      final actZoneName = activeZone?['name'] as String? ?? 'خارج از قلمرو';
      activeZoneName = actZoneName;
      activeZoneIcon = activeZone?['icon'] as String?;
      activeZoneColorHex = activeZone?['color'] as String?;
      final activeStart = activeZone?['startTime'] as String?;
      final activeEnd = activeZone?['endTime'] as String?;
      
      final isOverride = activeZone?['isOverride'] == true;
      if (isOverride) {
        final overrideUntilMs = activeZone?['overrideUntilMs'] as int? ?? 0;
        final remainingMs = overrideUntilMs - DateTime.now().millisecondsSinceEpoch;
        final remainingMin = (remainingMs / 60000).ceil();
        activeZoneTimeRange = 'فعال‌سازی دستی ($remainingMin دقیقه)';
      } else if (activeStart != null && activeEnd != null) {
        activeZoneTimeRange = '$activeStart - $activeEnd';
      } else {
        activeZoneTimeRange = null;
      }
      
      activeZoneRoutinesCount = 0;
      if (activeZoneId != null) {
        activeZoneRoutinesCount = routineList.where((r) => r.zoneId == activeZoneId).length;
      }

      // Load current energy (default value — full analytics run in loadP1)
      final energyStr = settingsMap['default_energy_level'] ?? 'MEDIUM';
      final currentEnergy = EnergyLevel.values.firstWhere(
        (e) => e.name.toLowerCase() == energyStr.toLowerCase(),
        orElse: () => EnergyLevel.medium,
      );

      final isMenstruating = await DatabaseHelper.instance.isUserMenstruating();

      // Run RIE Pipeline
      final nowTime = DateTime.now();

      // Self-reflection signal → feeds the intelligence engine's gentle mode.
      final reflectionContext = await _buildReflectionContext(db, nowTime);

      engineOutput = await RitmoIntelligenceEngine.evaluate(
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

      // Map suggested routine to nextTask so existing UI is compatible
      final visibleIds = engineOutput?.visibleRoutines.map((r) => r.id).toSet() ?? {};
      if (engineOutput?.suggestedRoutine != null) {
        final sugg = engineOutput!.suggestedRoutine!;
        nextTask = activeTasks.firstWhere(
          (t) => t.routine.id == sugg.id,
          orElse: () => RoutineTask(
            routine: sugg,
            scheduleTimeStr: '--:--',
            scheduledTime: DateTime.now(),
          ),
        );
      } else {
        nextTask = null;
      }

      // Calculate weighted rhythmScore
      var totalWeight = 0.0;
      var completedWeight = 0.0;
      final completionMap = {
        for (final c in completionsToday) c['routineId'] as String: c
      };

      for (final task in activeTasks) {
        final rId = task.routine.id;
        final routineType = task.routine.routineType;
        final completion = completionMap[rId];
        final isAsNeeded = routineType == RoutineType.asNeeded;
        final isSystemResult = completion != null && completion['resultSource'] == 'SYSTEM';

        if (!isAsNeeded && !isSystemResult) {
          totalWeight += task.routine.priority;
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
            completedWeight += completionValue * task.routine.priority;
          }
        }
      }

      rhythmScore = 0;
      if (totalWeight > 0) {
        rhythmScore = ((completedWeight / totalWeight) * 100).round();
      } else {
        rhythmScore = 82; // Fallback to mockup value if no weight
      }

      // 7. Build timeline items (only show visible routines)
      final items = activeTasks
          .where((t) => visibleIds.contains(t.routine.id))
          .map((t) {
        final isCompleted = completedIds.contains(t.routine.id);
        return <String, dynamic>{
          'type': 'task',
          'id': t.routine.id,
          'title': t.routine.title,
          'time': t.scheduleTimeStr ?? '--:--',
          'status': isCompleted ? '✓ انجام' : 'منتظر',
          'isCompleted': isCompleted,
          'category': t.routine.category.name,
          'routine': t.routine,
        };
      }).toList();

      items.sort((a, b) => (a['time'] as String).compareTo(b['time'] as String));
      timelineItems = items;

    } catch (e, stack) {
      debugPrint('Error in loadP0: $e\n$stack');
    } finally {
      isLoading = false;
    }
  }

  /// Phase 1 — deferred after first frame; loads below-fold data.
  Future<void> loadP1() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final nowTime = DateTime.now();
      final energyStr = settingsMap['default_energy_level'] ?? 'MEDIUM';
      final actZoneName = activeZoneName ?? 'خارج از قلمرو';

      // 4. Load Worship Debts if module enabled
      if (settingsMap['module_religion_enabled'] == 'true') {
        final worshipDebtsRaw = await db.query('worship_debts', where: 'isArchived = 0');
        worshipDebts = worshipDebtsRaw.map(Map<String, dynamic>.from).toList();
        
        // Load prayer times from central WorshipRepository
        prayerTimes = await WorshipRepository.instance.getPrayerTimesForDate(
          DateTime.now(),
          settingsMap: settingsMap,
        );
      } else {
        worshipDebts = [];
        prayerTimes = {};
      }

      // 🔑 Feed today's cross-section lists from the shared DayAgendaService.
      await _loadAgendaSections(nowTime, db);

      // Update current energy state dynamically from DB
      await updateCurrentEnergyState(db);

      // DailyBehavior (uses RIE gentle mode signal)
      dailyBehavior = await RitmoIntelligenceEngine.resolveDailyBehavior(
        date: nowTime,
        db: db,
        settings: settingsMap,
      );

      // Build widget snapshot
      await SnapshotHelper.updateWidgetSnapshot(
        nextActionTitle: nextTask?.routine.title ?? 'استراحت 🌿',
        rhythmScore: rhythmScore,
        currentEnergyLevel: energyStr.toLowerCase(),
      );

      // Update foreground service Status Notification if enabled
      final persistentNotifEnabled = settingsMap['persistent_status_notification_enabled'] != 'false';
      if (persistentNotifEnabled) {
        await sl<NotificationPlatform>().startStatusMode(
          zone: actZoneName,
          energy: energyStr == 'LOW' ? 'پایین' : (energyStr == 'HIGH' ? 'بالا' : 'متوسط'),
          proposedTask: nextTask?.routine.title ?? 'استراحت 🌿',
          proposedTaskId: nextTask?.routine.id,
        );
      } else {
        await sl<NotificationPlatform>().stopForegroundService();
      }

      // Load AI Daily Briefing
      isBriefingLoading = true;
      try {
        briefing = await AiBriefingService.instance.getOrRefresh();
      } catch (e) {
        debugPrint('[BRIEFING] failed in loadP1: $e');
        briefing = await AiBriefingService.instance.getCached();
      } finally {
        isBriefingLoading = false;
      }

      await _buildModuleSummaries(db);
    } catch (e, stack) {
      debugPrint('Error in loadP1: $e\n$stack');
    }
  }

  Future<void> _buildModuleSummaries(Database db) async {
    final out = <DashboardModuleSummary>[];
    final s = settingsMap;
    String fa(Object v) => toPersianDigits(v.toString());

    // خواب — آخرین لاگ از bedtime_diagnostics
    if (s['module_sleep_enabled'] == 'true') {
      final rows = await db.query('bedtime_diagnostics', orderBy: 'date DESC', limit: 1);
      if (rows.isNotEmpty) {
        final log = SleepLog.fromMap(rows.first);
        final h = log.durationMinutes ~/ 60;
        final m = log.durationMinutes % 60;
        out.add(DashboardModuleSummary(
          moduleId: 'sleep', title: 'خواب',
          icon: CupertinoIcons.moon_stars_fill, accentColor: const Color(0xff8B5CF6),
          primary: '${fa(h)}:${fa(m.toString().padLeft(2, '0'))} ساعت',
          secondary: 'کیفیت دیشب: ${log.quality.emoji} ${log.quality.label}',
          backgroundImage: 'assets/images/sleep_card_top.png',
        ));
      } else {
        out.add(const DashboardModuleSummary(
          moduleId: 'sleep', title: 'خواب',
          icon: CupertinoIcons.moon_stars_fill, accentColor: Color(0xff8B5CF6),
          primary: '—', secondary: 'هنوز خوابی ثبت نشده',
          backgroundImage: 'assets/images/sleep_card_top.png',
        ));
      }
    }

    // ورزش — جلسات و دقایق این هفته از workout_logs
    if (s['module_sports_enabled'] == 'true') {
      final weekAgo = DateTime.now().subtract(const Duration(days: 7)).millisecondsSinceEpoch;
      final rows = await db.query('workout_logs', where: 'loggedAt >= ?', whereArgs: [weekAgo]);
      final sessions = rows.length;
      final minutes = rows.fold<int>(0, (a, r) => a + ((r['durationMinutes'] as int?) ?? 0));
      out.add(DashboardModuleSummary(
        moduleId: 'sports', title: 'ورزش',
        icon: Icons.fitness_center, accentColor: const Color(0xff10B981),
        primary: '${fa(sessions)} جلسه', secondary: 'این هفته: ${fa(minutes)} دقیقه',
        backgroundImage: 'assets/images/sports_card_top.png',
      ));
    }

    // انرژی و مود — از فیلدهای از قبل محاسبهشدهی کنترلر
    if (s['module_energy_enabled'] == 'true') {
      out.add(DashboardModuleSummary(
        moduleId: 'energy', title: 'انرژی و مود',
        icon: CupertinoIcons.bolt_fill, accentColor: const Color(0xffEC4899),
        primary: '${fa(currentEnergyPercent.round())}٪', secondary: 'سطح: $currentEnergyLabel',
        backgroundImage: 'assets/images/energy_card_top.png',
      ));
    }

    // دارو — پایبندی امروز از medicationRoutines + medicationCompletionsToday
    if (s['module_medicine_enabled'] == 'true') {
      final totalDoses = medicationRoutines.fold<int>(
          0, (a, r) => a + (((r['maxDosesPerDay'] as int?) ?? 1) <= 0 ? 1 : ((r['maxDosesPerDay'] as int?) ?? 1)));
      final taken = medicationCompletionsToday.values.fold<int>(0, (a, c) => a + c);
      final pct = totalDoses > 0 ? ((taken / totalDoses) * 100).round().clamp(0, 100) : 0;
      final remaining = (totalDoses - taken) < 0 ? 0 : (totalDoses - taken);
      out.add(DashboardModuleSummary(
        moduleId: 'medicine', title: 'دارو',
        icon: CupertinoIcons.bandage_fill, accentColor: const Color(0xffEF4444),
        primary: '${fa(pct)}٪', secondary: 'پایبندی امروز · ${fa(remaining)} باقیمانده',
        backgroundImage: 'assets/images/medicine_card_top.png',
      ));
    }

    // عبادت — تعداد قضاها از worshipDebts (نماز بعدی از prayerTimes اختیاری است)
    if (s['module_religion_enabled'] == 'true') {
      final debts = worshipDebts.length;
      
      // استخراج نماز بعدی از prayerTimes
      var secondaryText = 'برنامهی عبادی';
      try {
        final now = DateTime.now();
        final currentMinutes = now.hour * 60 + now.minute;
        
        int? parseTimeToMinutes(String? timeStr) {
          if (timeStr == null || !timeStr.contains(':')) return null;
          final parts = timeStr.split(':');
          final h = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          if (h == null || m == null) return null;
          return h * 60 + m;
        }
        
        final fajrMin = parseTimeToMinutes(prayerTimes['fajr']);
        final dhuhrMin = parseTimeToMinutes(prayerTimes['dhuhr']);
        final maghribMin = parseTimeToMinutes(prayerTimes['maghrib']);
        final ishaMin = parseTimeToMinutes(prayerTimes['isha']);
        
        String? nextName;
        String? nextTime;
        
        if (fajrMin != null && currentMinutes < fajrMin) {
          nextName = 'اذان صبح';
          nextTime = prayerTimes['fajr'];
        } else if (dhuhrMin != null && currentMinutes < dhuhrMin) {
          nextName = 'اذان ظهر';
          nextTime = prayerTimes['dhuhr'];
        } else if (maghribMin != null && currentMinutes < maghribMin) {
          nextName = 'اذان مغرب';
          nextTime = prayerTimes['maghrib'];
        } else if (ishaMin != null && currentMinutes < ishaMin) {
          nextName = 'نماز عشا';
          nextTime = prayerTimes['isha'];
        } else if (fajrMin != null) {
          nextName = 'اذان صبح فردا';
          nextTime = prayerTimes['fajr'];
        }
        
        if (nextName != null && nextTime != null) {
          secondaryText = '$nextName: ${toPersianDigits(nextTime)}';
        }
      } catch (e) {
        // fallback to default
      }

      out.add(DashboardModuleSummary(
        moduleId: 'worship', title: 'عبادت',
        icon: CupertinoIcons.circle_grid_hex, accentColor: const Color(0xffFBBF24),
        primary: debts > 0 ? '${fa(debts)} قضا' : 'بهروز ✓',
        secondary: secondaryText,
        backgroundImage: 'assets/images/worship_card_top.png',
      ));
    }

    // چرخه — فاز فعلی از cycleEngineOutput (همان فیلدی که کنترلر در P1 پر میکند)
    if (cycleEngineOutput != null) {
      final p = cycleEngineOutput!.currentPhase;
      final label = p == CyclePhase.menstrual ? 'قاعدگی'
          : p == CyclePhase.follicular ? 'فولیکولار'
          : p == CyclePhase.ovulation ? 'تخمکگذاری' : 'لوتئال';
      out.add(DashboardModuleSummary(
        moduleId: 'cycle', title: 'چرخه بدن',
        icon: CupertinoIcons.heart_fill, accentColor: const Color(0xffEC4899),
        primary: label, secondary: 'فاز کنونی بدن',
        backgroundImage: 'assets/images/cycle_card_top.png',
      ));
    }

    // اهداف — گامهای امروز از todaysGoalSteps
    if (s['module_goals_enabled'] == 'true') {
      final total = todaysGoalSteps.length;
      final done = todaysGoalSteps.where((g) =>
          g['isCompleted'] == 1 || g['isCompleted'] == true || g['completedAt'] != null).length;
      out.add(DashboardModuleSummary(
        moduleId: 'goals', title: 'اهداف',
        icon: CupertinoIcons.flag_fill, accentColor: const Color(0xffF59E0B),
        primary: total > 0 ? '${fa(done)}/${fa(total)}' : '—',
        secondary: 'گامهای امروز',
        backgroundImage: 'assets/images/goals_card_top.png',
      ));
    }

    // دورهها — جلسات مطالعهی امروز
    if (s['module_courses_enabled'] == 'true') {
      out.add(DashboardModuleSummary(
        moduleId: 'courses', title: 'دورهها',
        icon: CupertinoIcons.book_fill, accentColor: const Color(0xff3B82F6),
        primary: '${fa(todaysCourseSessions.length)} جلسه', secondary: 'مطالعهی امروز',
        backgroundImage: 'assets/images/courses_card_top.png',
      ));
    }

    // کنکور — مباحث امروز
    if (s['module_konkur_enabled'] == 'true') {
      out.add(DashboardModuleSummary(
        moduleId: 'konkur', title: 'کنکور',
        icon: CupertinoIcons.doc_plaintext, accentColor: const Color(0xff8B5CF6),
        primary: '${fa(todaysKonkurPlanItems.length)} مبحث', secondary: 'برنامهی امروز',
        backgroundImage: 'assets/images/konkur_card_top.png',
      ));
    }

    moduleSummaries = out;
  }

  /// Runs the ReflectionEngine and maps it into a compact [ReflectionContext]

  /// for the intelligence engine. Returns null when there is no recent
  /// reflection signal, so the engine keeps its default (un-softened) behavior.
  Future<ReflectionContext?> _buildReflectionContext(
    Database db,
    DateTime now,
  ) async {
    try {
      final reflectionMaps =
          await db.query('daily_reflections', orderBy: 'date DESC');
      if (reflectionMaps.isEmpty) return null;
      final checkinMaps =
          await db.query('daily_checkins', orderBy: 'date DESC');
      final energyLogs = await db.query('energy_logs');
      final moodLogs = await db.query('mood_logs');

      final out = await RitmoEngineBus.instance
          .execute<ReflectionEngineInput, ReflectionEngineOutput>(
        ReflectionEngine,
        ReflectionEngineInput(
          dailyReflections: reflectionMaps,
          dailyCheckins: checkinMaps,
          energyLogs: energyLogs,
          moodLogs: moodLogs,
          today: now,
        ),
      );

      // No entries inside the horizon → no actionable signal.
      if (out.entryCount == 0) return null;

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

      return ReflectionContext(
        avgMoodScore: out.avgMoodScore,
        moodTrendDirection: direction,
        currentStreak: out.currentStreak,
        reflectionEnergyCorrelation: out.reflectionEnergyCorrelation,
      );
    } catch (e) {
      debugPrint('Error building reflection context: $e');
      return null;
    }
  }

  /// Loads today's cross-section agenda once and derives the typed lists the
  /// Home widgets consume. Replaces the inline goal/course/konkur/cycle DB
  /// queries that used to live in `now_dashboard_screen._loadDashboardData`.
  Future<void> _loadAgendaSections(DateTime now, Database db) async {
    try {
      final dayAgenda = await DayAgendaService.instance.agendaForDate(
        now,
        options: const AgendaQueryOptions(),
      );
      agenda = dayAgenda.items;

      // Goal steps: raw rows (with goalTitle) — Home shows all, completed too.
      todaysGoalSteps = agenda
          .where((i) => i.domain == AgendaDomain.goalStep)
          .map((i) => Map<String, dynamic>.from(i.meta['step'] as Map))
          .toList();

      // Course sessions: Home shows only the not-yet-completed ones.
      todaysCourseSessions = agenda
          .where((i) => i.domain == AgendaDomain.course && !i.isCompleted)
          .map((i) => CourseSession.fromMap(
              Map<String, dynamic>.from(i.meta['session'] as Map)))
          .toList();
      if (todaysCourseSessions.isNotEmpty &&
          settingsMap['module_courses_enabled'] == 'true') {
        allCourses = await CoursesRepository.instance.getActiveCourses();
      } else {
        allCourses = [];
      }

      // Konkur plan items: Home shows only PENDING.
      todaysKonkurPlanItems = agenda
          .where((i) =>
              i.domain == AgendaDomain.konkur &&
              i.completion == AgendaCompletion.pending)
          .map((i) => KonkurPlanItem.fromMap(
              Map<String, dynamic>.from(i.meta['planItem'] as Map)))
          .toList();
      if (todaysKonkurPlanItems.isNotEmpty) {
        final repo = KonkurRepository.instance;
        konkurSubjects = await repo.getSubjects();
        konkurTopics = await repo.getTopics();
      } else {
        konkurSubjects = [];
        konkurTopics = [];
      }

      // Cycle: the Home cycle widget needs the full engine output, which the
      // agenda only summarizes — compute it here under the same gates.
      final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
      final cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
      final dashboardConsent = settingsMap['cycle_consent_dashboard'] == 'true';
      final setupDone = settingsMap['cycle_setup_done'] == 'true';
      if (isFemale && cycleEnabled && dashboardConsent && setupDone) {
        cycleEngineOutput = await CycleEngine().calculate(CycleEngineInput(
          db: db,
          appSettings: settingsMap,
          now: now,
        ));
      } else {
        cycleEngineOutput = null;
      }
    } catch (e, st) {
      debugPrint('Error loading agenda sections: $e\n$st');
    }
  }

  Future<void> updateCurrentEnergyState(Database db) async {
    try {
      final energyLogs = await db.query('energy_logs');
      final completions = await db.query('routine_completions');
      final dailyRhythm = await db.query('daily_rhythm');

      final validityMinutes = int.tryParse(settingsMap['energy_validity_minutes'] ?? '180') ?? 180;
      final defaultLevel = settingsMap['default_energy_level'] ?? 'MEDIUM';
      final now = DateTime.now();

      // Query bedtime diagnostics in the last 24 hours
      final oneDayAgo = now.subtract(const Duration(hours: 24)).millisecondsSinceEpoch;
      final sleepDiagList = await db.query(
        'bedtime_diagnostics',
        where: 'createdAt >= ?',
        whereArgs: [oneDayAgo],
        orderBy: 'createdAt DESC',
      );

      final energyOut = await RitmoEngineBus.instance.execute<EnergyAnalyticsEngineInput, EnergyAnalyticsOutput>(
        EnergyAnalyticsEngine,
        EnergyAnalyticsEngineInput(
          energyLogs: energyLogs,
          routineCompletions: completions,
          dailyRhythm: dailyRhythm,
          sleepDiagList: sleepDiagList,
          now: now,
          validityMinutes: validityMinutes,
          defaultEnergyLevel: defaultLevel,
        ),
      );

      final finalPercent = energyOut.currentDynamicEnergy;
      final explanations = energyOut.currentDynamicEnergyExplanations;

      // Determine label & description based on the final percentage
      var label = 'متوسط';
      var desc = 'مناسب برای مطالعه، پروژه‌ها و روتین‌ها';

      if (finalPercent >= 75.0) {
        label = 'بالا';
        desc = 'آماده برای کارهای عمیق و تمرکز سنگین';
      } else if (finalPercent < 45.0) {
        label = 'پایین';
        desc = 'زمان مناسب برای استراحت و کار سبک';
      }

      // Update state
      currentEnergyPercent = finalPercent;
      currentEnergyLabel = label;
      currentEnergyDesc = desc;
      currentEnergyExplanation = explanations;

      // Cache analytical windows in state
      peakPerformanceWindow = energyOut.peakPerformanceWindow;
      mostFatiguedWindow = energyOut.mostFatiguedWindow;
      mostProductiveWeekday = energyOut.mostProductiveWeekday;

      // Find the latest log manually from energyLogs to determine lastManualTime
      int? lastManualTime;
      if (energyLogs.isNotEmpty) {
        var latestLog = energyLogs.first;
        for (final log in energyLogs) {
          if ((log['loggedAt'] as int? ?? 0) > (latestLog['loggedAt'] as int? ?? 0)) {
            latestLog = log;
          }
        }
        final loggedAt = latestLog['loggedAt']! as int;
        final differenceMinutes = now.difference(DateTime.fromMillisecondsSinceEpoch(loggedAt)).inMinutes;

        if (differenceMinutes <= validityMinutes) {
          lastManualTime = loggedAt;
        }
      }

      if (lastManualTime != null) {
        final diffMin = now.difference(DateTime.fromMillisecondsSinceEpoch(lastManualTime)).inMinutes;
        final lastLog = energyLogs.firstWhere((log) => log['loggedAt'] == lastManualTime);
        final note = lastLog['note'] as String?;
        final noteSuffix = (note != null && note.isNotEmpty) ? ' ($note)' : '';
        currentEnergyTimeAgo = 'ثبت شده در $diffMin دقیقه پیش$noteSuffix';
      } else {
        currentEnergyTimeAgo = 'بر اساس محاسبات و مقادیر پیش‌فرض';
      }
    } catch (e) {
      debugPrint('Error updating energy state: $e');
    }
  }

  Future<Map<String, String?>> loadEnergyAnalyticsData() async {
    return {
      'peak': peakPerformanceWindow,
      'fatigued': mostFatiguedWindow,
      'productive': mostProductiveWeekday,
    };
  }

  Future<void> _ensureWorshipDebtRoutineExists(Database db) async {
    final results = await db.query('routines', where: 'id = ?', whereArgs: ['worship_debt_routine']);
    if (results.isEmpty) {
      final now = DateTime.now().millisecondsSinceEpoch;
      await db.insert('routines', {
        'id': 'worship_debt_routine',
        'title': 'بدهی عبادی',
        'category': 'religious',
        'routineType': 'asNeeded',
        'notificationLevel': 'none',
        'isEssential': 0,
        'energyRule': 'NONE',
        'priority': 1.0,
        'isArchived': 0,
        'isPrivate': 0,
        'displayOrder': 999,
        'createdAt': now,
        'updatedAt': now,
      });
    }
  }

  Future<Map<String, dynamic>?> _resolveActiveZone(Database db, DateTime now) async {
    // Check override settings first
    final overrideIdQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['realm_override_id'],
    );
    final overrideUntilQuery = await db.query(
      'app_settings',
      where: 'key = ?',
      whereArgs: ['realm_override_until_ms'],
    );

    if (overrideIdQuery.isNotEmpty && overrideUntilQuery.isNotEmpty) {
      final overrideId = overrideIdQuery.first['value'] as String?;
      final overrideUntilStr = overrideUntilQuery.first['value'] as String?;
      if (overrideId != null && overrideId.isNotEmpty && overrideUntilStr != null) {
        final overrideUntilMs = int.tryParse(overrideUntilStr) ?? 0;
        if (now.millisecondsSinceEpoch < overrideUntilMs) {
          final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [overrideId]);
          if (zoneQuery.isNotEmpty) {
            final zone = Map<String, dynamic>.from(zoneQuery.first);
            zone['isOverride'] = true;
            zone['overrideUntilMs'] = overrideUntilMs;
            return zone;
          }
        }
      }
    }

    final weekday = now.weekday;
    final currentMinutes = now.hour * 60 + now.minute;

    final schedulesRaw = await db.query('zone_schedules');
    final schedules = schedulesRaw.map(Map<String, dynamic>.from).toList();
    for (final sched in schedules) {
      final daysOfWeekStr = sched['daysOfWeek'] as String? ?? '';
      final days = daysOfWeekStr.split(',').map((d) => int.tryParse(d.trim()) ?? 0).toSet();
      if (days.contains(weekday)) {
        final startTimeStr = sched['startTime'] as String? ?? '00:00';
        final endTimeStr = sched['endTime'] as String? ?? '23:59';

        final startParts = startTimeStr.split(':');
        final endParts = endTimeStr.split(':');
        if (startParts.length == 2 && endParts.length == 2) {
          final startMin = (int.tryParse(startParts[0]) ?? 0) * 60 + (int.tryParse(startParts[1]) ?? 0);
          final endMin = (int.tryParse(endParts[0]) ?? 0) * 60 + (int.tryParse(endParts[1]) ?? 0);

          if (currentMinutes >= startMin && currentMinutes <= endMin) {
            final zoneId = sched['zoneId'] as String;
            final zoneQuery = await db.query('zones', where: 'id = ?', whereArgs: [zoneId]);
            if (zoneQuery.isNotEmpty) {
              final zone = Map<String, dynamic>.from(zoneQuery.first);
              zone['startTime'] = startTimeStr;
              zone['endTime'] = endTimeStr;
              return zone;
            }
          }
        }
      }
    }
    return null;
  }
}

