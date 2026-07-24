import 'dart:convert';

import 'package:flutter/foundation.dart' hide Category;
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/routine_agenda_source.dart';
import 'package:ritmo/core/domain/engines/cycle_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/services/prayer_time_provider.dart';
import 'package:ritmo/core/utils/cycle_privacy_guard.dart';
import 'package:ritmo/features/courses/logic/courses_repository.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/konkur/logic/konkur_repository.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:shamsi_date/shamsi_date.dart';
import 'package:sqflite/sqflite.dart';

/// 🔑 The single source of truth for "what is on a day".
///
/// Aggregates every section (routine, prayer, mustahab, worship debt, course,
/// goal step, konkur, cycle) into a normalized [AgendaItem] list. Both the Home
/// dashboard and the Calendar feed from this service so the app stays coherent.
///
/// Each per-domain collector is module-gated and reuses the owning repo/engine
/// (no fresh raw SQL per section beyond what's needed). For a range, shared
/// data (settings, prayer times, worship rows, cycle output, course/konkur
/// lookups) is loaded once and bucketed in memory.
class DayAgendaService {
  DayAgendaService._() {
    _subscribeToEvents();
  }
  static final DayAgendaService instance = DayAgendaService._();

  /// Small per-date cache (invalidated reactively via the event bus).
  final Map<String, DayAgenda> _cache = {};

  /// Completion-style events fired outside the routine kernel. The kernel
  /// already refreshes the UI for its own routine events, so for these we both
  /// invalidate the cache *and* fan out a single UI refresh signal. Routine
  /// events only invalidate the cache (no double refresh).
  static const Set<String> _uiRefreshEvents = {
    'CourseSessionCompleted',
    'GoalStepToggled',
    'PrayerCompleted',
    'WorshipUpdated',
    'RoutineDeleted',
  };

  static const Set<String> _cacheInvalidatingEvents = {
    'CourseSessionCompleted',
    'GoalStepToggled',
    'PrayerCompleted',
    'WorshipUpdated',
    'RoutineCompleted',
    'RoutineSkipped',
    'RoutineCreated',
    'RoutineEdited',
    'RoutineDeleted',
    'CycleStarted',
    'CycleEnded',
    'DayRolledOver',
    'DataImported',
  };

  void _subscribeToEvents() {
    RitmoEventBus().onEvents.listen((event) {
      if (!_cacheInvalidatingEvents.contains(event.type)) return;

      final date = event.payload['date'] as String?;
      if (event.type == 'DayRolledOver' || event.type == 'DataImported') {
        invalidateAll();
      } else if (date != null) {
        invalidateDate(date);
      } else {
        invalidateAll();
      }

      if (_uiRefreshEvents.contains(event.type)) {
        // Unified UI refresh notifier (Home + Calendar listen to this).
        RitmoEvents.notifyRoutineChanged();
      }
    });
  }

  /// Drop the whole cache (e.g. on broad data changes).
  void invalidateAll() => _cache.clear();

  /// Drop a single date's cached agenda.
  void invalidateDate(String dateStr) => _cache.remove(dateStr);

  static String _dateStr(DateTime dt) => dt.toIso8601String().substring(0, 10);

  Future<DayAgenda> agendaForDate(
    DateTime date, {
    AgendaQueryOptions? options,
  }) async {
    final map = await agendaForRange(date, date, options: options);
    return map[_dateStr(date)] ?? DayAgenda.empty(_dateStr(date));
  }

  Future<Map<String, DayAgenda>> agendaForRange(
    DateTime start,
    DateTime end, {
    AgendaQueryOptions? options,
  }) async {
    final opts = options ?? const AgendaQueryOptions();
    final result = <String, DayAgenda>{};

    final dates = <DateTime>[];
    var d = DateTime(start.year, start.month, start.day);
    final endD = DateTime(end.year, end.month, end.day);
    while (!d.isAfter(endD)) {
      dates.add(d);
      d = d.add(const Duration(days: 1));
    }

    try {
      final ctx = await _buildContext(start, end, opts);
      for (final date in dates) {
        final ds = _dateStr(date);
        // Cache only the full, unfiltered agenda; filtered queries are rebuilt.
        if (opts.domains.isEmpty && opts.includeCompleted && _cache.containsKey(ds)) {
          result[ds] = _cache[ds]!;
          continue;
        }
        final agenda = await _assembleDay(date, ds, ctx, opts);
        if (opts.domains.isEmpty && opts.includeCompleted) {
          _cache[ds] = agenda;
        }
        result[ds] = agenda;
      }
    } catch (e, st) {
      debugPrint('DayAgendaService.agendaForRange error: $e\n$st');
      for (final date in dates) {
        result.putIfAbsent(_dateStr(date), () => DayAgenda.empty(_dateStr(date)));
      }
    }

    return result;
  }

  // ---------------------------------------------------------------------------
  // Context (loaded once per range)
  // ---------------------------------------------------------------------------

  Future<_AgendaContext> _buildContext(
    DateTime start,
    DateTime end,
    AgendaQueryOptions opts,
  ) async {
    final db = await DatabaseHelper.instance.database;

    final settings = await db.query('app_settings');
    final settingsMap = <String, String>{
      for (final s in settings) s['key']! as String: s['value']! as String
    };

    final religionEnabled = settingsMap['module_religion_enabled'] == 'true';
    final coursesEnabled = settingsMap['module_courses_enabled'] == 'true';
    final konkurEnabled = settingsMap['module_konkur_enabled'] == 'true' &&
        settingsMap['konkur_show_in_dashboard'] != 'false';
    final sportsEnabled = settingsMap['module_sports_enabled'] == 'true' ||
        settingsMap['module_supplementary_sports_enabled'] == 'true';
    final medicineEnabled = settingsMap['module_medicine_enabled'] == 'true';

    // Cycle gates mirror the Home dashboard (conservative: dashboard consent).
    final isFemale = CyclePrivacyGuard.isVisible(settingsMap);
    final cycleEnabled = settingsMap['module_cycle_enabled'] == 'true';
    final cycleConsent = settingsMap['cycle_consent_dashboard'] == 'true';
    final cycleSetupDone = settingsMap['cycle_setup_done'] == 'true';
    final showCycleInCalendar = settingsMap['show_cycle_in_calendar'] == 'true';
    final cycleAllowed =
        isFemale && cycleEnabled && cycleConsent && cycleSetupDone && showCycleInCalendar;

    final routineSource = await RoutineAgendaSource.load(db, settingsMap);

    // Routine completions keyed by date -> routineId -> row.
    final completionsByDate = <String, Map<String, Map<String, dynamic>>>{};
    if (opts.wants(AgendaDomain.routine)) {
      final comps = await db.query('routine_completions');
      for (final c in comps) {
        final resType = c['resultType'] as String?;
        if (resType == 'SNOOZED' || resType == 'CANNOT_NOW') continue;
        final dateStr = c['completionDate'] as String?;
        final routineId = c['routineId'] as String?;
        if (dateStr == null || routineId == null) continue;
        completionsByDate
            .putIfAbsent(dateStr, () => {})[routineId] =
            Map<String, dynamic>.from(c);
      }
    }

    // Worship practices (prayers + mustahab) and debts, loaded once.
    final prayerPractices = <Map<String, dynamic>>[];
    final mustahabPractices = <Map<String, dynamic>>[];
    var worshipDebts = <Map<String, dynamic>>[];
    if (religionEnabled) {
      final practices = await db.query(
        'worship_practices',
        where: 'isActive = 1',
      );
      for (final p in practices) {
        final type = p['practiceType'] as String? ?? '';
        if (type == 'PRAYER') {
          prayerPractices.add(Map<String, dynamic>.from(p));
        } else if (type == 'MUSTAHAB' || type == 'QURAN' || type == 'DHIKR') {
          if (p['reminderEnabled'] == 1) {
            mustahabPractices.add(Map<String, dynamic>.from(p));
          }
        }
      }
      // Worship debts are no longer shown in the calendar per user request
      worshipDebts = [];
    }

    // Courses: active course titles + all sessions bucketed by plannedDate.
    final courseTitles = <String, String>{};
    final coursesMap = <String, Course>{};
    final sessionsByDate = <String, List<CourseSession>>{};
    if (coursesEnabled && opts.wants(AgendaDomain.course)) {
      final courses = await CoursesRepository.instance.getActiveCourses();
      for (final c in courses) {
        courseTitles[c.id] = c.title;
        coursesMap[c.id] = c;
      }
      final activeIds = courseTitles.keys.toSet();
      final sessionRows = await db.query('course_sessions');
      for (final row in sessionRows) {
        final session = CourseSession.fromMap(row);
        if (session.plannedDate == null) continue;
        if (!activeIds.contains(session.courseId)) continue;
        sessionsByDate
            .putIfAbsent(session.plannedDate!, () => [])
            .add(session);
      }
    }

    // Konkur: plan items bucketed by date + subject names for subtitles.
    final konkurByDate = <String, List<KonkurPlanItem>>{};
    final konkurSubjectNames = <String, String>{};
    if (konkurEnabled && opts.wants(AgendaDomain.konkur)) {
      final repo = KonkurRepository.instance;
      final plan = await repo.getPlanItems();
      for (final item in plan) {
        konkurByDate.putIfAbsent(item.dateIso, () => []).add(item);
      }
      if (konkurByDate.isNotEmpty) {
        final subjects = await repo.getSubjects();
        for (final s in subjects) {
          konkurSubjectNames[s.id] = s.name;
        }
      }
    }

    // Cycle output computed once for "now" and classified per-date by window.
    CycleEngineOutput? cycleOutput;
    if (cycleAllowed && opts.wants(AgendaDomain.cycle)) {
      try {
        cycleOutput = await CycleEngine().calculate(CycleEngineInput(
          db: db,
          appSettings: settingsMap,
          now: DateTime.now(),
        ));
      } catch (e) {
        debugPrint('DayAgendaService cycle calc error: $e');
      }
    }

    // Coordinates lookup for cityId
    final cityId = settingsMap['prayer_city_id'] ??
        settingsMap['home_city_id'] ??
        'TEHRAN_TEHRAN';
    final cityResult = await db.query(
      'iran_cities',
      where: 'id = ?',
      whereArgs: [cityId],
      limit: 1,
    );

    var latitude = 35.6892; // default Tehran
    var longitude = 51.3890;

    if (cityResult.isNotEmpty) {
      latitude = cityResult.first['latitude']! as double;
      longitude = cityResult.first['longitude']! as double;
    }

    final ihtiyatMinutes = int.tryParse(settingsMap['ihtiyat_minutes'] ?? '10') ?? 10;
    final calcMethodStr = settingsMap['prayer_calculation_method'] ?? 'TEHRAN_GEOPHYSICS';

    // Preload goal steps for the range
    final goalStepsByDate = <String, List<Map<String, dynamic>>>{};
    if (opts.wants(AgendaDomain.goalStep)) {
      final startStr = _dateStr(start);
      final endStr = _dateStr(end);
      final res = await db.rawQuery('''
        SELECT gs.*, g.title as goalTitle
        FROM goal_steps gs
        JOIN goals g ON gs.goalId = g.id
        WHERE gs.scheduledDate >= ? AND gs.scheduledDate <= ? AND g.status = 'ACTIVE'
      ''', [startStr, endStr]);
      for (final row in res) {
        final dateStr = row['scheduledDate'] as String?;
        if (dateStr != null) {
          goalStepsByDate.putIfAbsent(dateStr, () => []).add(Map<String, dynamic>.from(row));
        }
      }
    }

    // Preload cached Hijri dates
    final cachedHijriDates = <String, HijriDate>{};
    if (religionEnabled) {
      final hijriSettings = await db.query(
        'app_settings',
        where: "key LIKE 'hijri_date_%'",
      );
      for (final row in hijriSettings) {
        try {
          final val = row['value']! as String;
          final decoded = json.decode(val) as Map<String, dynamic>;
          final dateKey = row['key']! as String;
          cachedHijriDates[dateKey] = HijriDate.fromMap(decoded);
        } catch (e) {
          debugPrint('Error decoding cached Hijri date in _buildContext: $e');
        }
      }
    }
    final sportsPlansByDay = <int, List<Map<String, dynamic>>>{};
    if (sportsEnabled && opts.wants(AgendaDomain.sport)) {
      try {
        final plans = await db.query('ss_workout_plan');
        for (final p in plans) {
          final dow = p['dayOfWeek'] as int?;
          if (dow != null) {
            sportsPlansByDay.putIfAbsent(dow, () => []).add(Map<String, dynamic>.from(p));
          }
        }
      } catch (e) {
        debugPrint('DayAgendaService sports query error: $e');
      }
    }

    // Preload medicine logs if enabled
    final medicineLogsByDate = <String, List<Map<String, dynamic>>>{};
    if (medicineEnabled && opts.wants(AgendaDomain.medicine)) {
      try {
        final logs = await db.query('medication_logs');
        for (final l in logs) {
          final schedTime = l['scheduledTime'] as int?;
          if (schedTime != null) {
            final dt = DateTime.fromMillisecondsSinceEpoch(schedTime);
            final ds = _dateStr(dt);
            medicineLogsByDate.putIfAbsent(ds, () => []).add(Map<String, dynamic>.from(l));
          }
        }
      } catch (e) {
        debugPrint('DayAgendaService medicine query error: $e');
      }
    }

    return _AgendaContext(
      db: db,
      settingsMap: settingsMap,
      religionEnabled: religionEnabled,
      coursesEnabled: coursesEnabled,
      konkurEnabled: konkurEnabled,
      cycleAllowed: cycleAllowed,
      sportsEnabled: sportsEnabled,
      medicineEnabled: medicineEnabled,
      routineSource: routineSource,
      completionsByDate: completionsByDate,
      prayerPractices: prayerPractices,
      mustahabPractices: mustahabPractices,
      worshipDebts: worshipDebts,
      courseTitles: courseTitles,
      coursesMap: coursesMap,
      sessionsByDate: sessionsByDate,
      konkurByDate: konkurByDate,
      konkurSubjectNames: konkurSubjectNames,
      cycleOutput: cycleOutput,
      goalStepsByDate: goalStepsByDate,
      sportsPlansByDay: sportsPlansByDay,
      medicineLogsByDate: medicineLogsByDate,
      cachedHijriDates: cachedHijriDates,
      latitude: latitude,
      longitude: longitude,
      ihtiyatMinutes: ihtiyatMinutes,
      calcMethodStr: calcMethodStr,
    );
  }

  // ---------------------------------------------------------------------------
  // Per-day assembly
  // ---------------------------------------------------------------------------

  Future<DayAgenda> _assembleDay(
    DateTime date,
    String dateStr,
    _AgendaContext ctx,
    AgendaQueryOptions opts,
  ) async {
    final todayStr = _dateStr(DateTime.now());
    final isToday = dateStr == todayStr;
    final prayerTimes = await ctx.prayerTimesFor(date);
    final items = <AgendaItem>[];

    HijriDate? hijriDate;
    final hasLunarMustahab = ctx.religionEnabled && ctx.mustahabPractices.any((p) => p['reminderFrequency'] == 'LUNAR_MONTHLY');
    if (hasLunarMustahab) {
      hijriDate = await _getHijriDate(date, ctx);
    }

    final enabledDomains = <AgendaDomain, bool>{
      AgendaDomain.routine: true,
      AgendaDomain.prayer: ctx.religionEnabled,
      AgendaDomain.mustahab: ctx.religionEnabled,
      AgendaDomain.worshipDebt: ctx.religionEnabled && opts.includeWorshipDebt,
      AgendaDomain.course: ctx.coursesEnabled,
      AgendaDomain.goalStep: true,
      AgendaDomain.konkur: ctx.konkurEnabled,
      AgendaDomain.cycle: ctx.cycleAllowed,
      AgendaDomain.sport: ctx.sportsEnabled,
      AgendaDomain.medicine: ctx.medicineEnabled,
    };

    if (opts.wants(AgendaDomain.routine)) {
      final routines = ctx.routineSource.agendaItemsForDate(
        date,
        prayerTimes: prayerTimes,
        completionsByRoutineId: ctx.completionsByDate[dateStr] ?? const {},
      );

      final activeWorshipTitles = <String>{};
      if (ctx.religionEnabled) {
        for (final p in ctx.prayerPractices) {
          final title = p['title'] as String?;
          if (title != null) activeWorshipTitles.add(title.trim());
        }
        for (final p in ctx.mustahabPractices) {
          final title = p['title'] as String?;
          if (title != null) activeWorshipTitles.add(title.trim());
        }
      }

      final filteredRoutines = routines.where((r) {
        final matches = activeWorshipTitles.contains(r.title.trim());
        return !matches;
      }).toList();

      items.addAll(filteredRoutines);
    }

    if (ctx.religionEnabled) {
      if (opts.wants(AgendaDomain.prayer)) {
        items.addAll(_collectPrayers(ctx, dateStr, isToday, prayerTimes));
      }
      if (opts.wants(AgendaDomain.mustahab)) {
        items.addAll(await _collectMustahab(ctx, dateStr, isToday, prayerTimes, hijriDate));
      }
      if (opts.wants(AgendaDomain.worshipDebt)) {
        items.addAll(_collectWorshipDebts(ctx, dateStr));
      }
    }

    if (ctx.coursesEnabled && opts.wants(AgendaDomain.course)) {
      items.addAll(_collectCourses(ctx, dateStr));
    }

    if (opts.wants(AgendaDomain.goalStep)) {
      items.addAll(_collectGoalSteps(ctx, dateStr));
    }

    if (ctx.konkurEnabled && opts.wants(AgendaDomain.konkur)) {
      items.addAll(_collectKonkur(ctx, dateStr));
    }

    if (ctx.cycleAllowed && opts.wants(AgendaDomain.cycle)) {
      final cycleItem = _collectCycle(ctx, date, dateStr, isToday);
      if (cycleItem != null) items.add(cycleItem);
    }

    if (ctx.sportsEnabled && opts.wants(AgendaDomain.sport)) {
      items.addAll(_collectSports(ctx, dateStr, date));
    }

    if (ctx.medicineEnabled && opts.wants(AgendaDomain.medicine)) {
      items.addAll(_collectMedicine(ctx, dateStr, isToday));
    }

    final filtered = opts.includeCompleted
        ? items
        : items.where((i) {
            return i.completion != AgendaCompletion.done &&
                i.completion != AgendaCompletion.partial &&
                i.completion != AgendaCompletion.skipped;
          }).toList();

    _sortItems(filtered);

    return DayAgenda(
      dateStr: dateStr,
      items: filtered,
      enabledDomains: enabledDomains,
    );
  }

  /// Timed items first (by time), then untimed by descending priority.
  void _sortItems(List<AgendaItem> items) {
    items.sort((a, b) {
      if (a.isTimed && b.isTimed) {
        return a.timeOfDay!.compareTo(b.timeOfDay!);
      }
      if (a.isTimed) return -1;
      if (b.isTimed) return 1;
      return b.priority.compareTo(a.priority);
    });
  }

  // ---------------------------------------------------------------------------
  // Collectors
  // ---------------------------------------------------------------------------

  static const Map<String, String> _prayerSubTypeToKey = {
    'FAJR': 'fajr',
    'DHUHR': 'dhuhr',
    'ASR': 'asr',
    'MAGHRIB': 'maghrib',
    'ISHA': 'isha',
  };

  List<AgendaItem> _collectPrayers(
    _AgendaContext ctx,
    String dateStr,
    bool isToday,
    Map<String, String> prayerTimes,
  ) {
    final items = <AgendaItem>[];
    
    // Group by subType for combining Dhuhr/Asr and Maghrib/Isha
    final bySubType = <String, Map<String, dynamic>>{};
    final others = <Map<String, dynamic>>[];
    
    for (final p in ctx.prayerPractices) {
      final subType = (p['subType'] as String? ?? '').toUpperCase();
      if (['FAJR', 'DHUHR', 'ASR', 'MAGHRIB', 'ISHA'].contains(subType)) {
        bySubType[subType] = p;
      } else {
        others.add(p);
      }
    }

    // 1. Fajr
    final fajr = bySubType['FAJR'];
    if (fajr != null) {
      final id = fajr['id'] as String;
      final timeOfDay = prayerTimes['fajr'];
      var completion = AgendaCompletion.none;
      if (isToday) {
        final doneDate = fajr['dailyDoneDate'] as String?;
        final done = (fajr['dailyDone'] as int? ?? 0) == 1 &&
            (doneDate == null || doneDate == dateStr);
        completion = done ? AgendaCompletion.done : AgendaCompletion.pending;
      }
      final start = _parseDateTime(dateStr, prayerTimes['fajr']);
      final end = _parseDateTime(dateStr, prayerTimes['sunrise']);
      items.add(AgendaItem(
        id: 'prayer:$id',
        domain: AgendaDomain.prayer,
        sourceId: id,
        title: fajr['title'] as String? ?? 'نماز صبح',
        dateStr: dateStr,
        timeOfDay: timeOfDay,
        category: Category.religious,
        completion: completion,
        priority: 3,
        isEssential: true,
        deepLink: AgendaDeepLink(domain: AgendaDomain.prayer, targetId: id),
        windowStart: start,
        windowEnd: end,
        meta: {'practice': fajr},
      ));
    }

    // 2. Dhuhr & Asr combined
    final dhuhr = bySubType['DHUHR'];
    final asr = bySubType['ASR'];
    if (dhuhr != null || asr != null) {
      final representative = dhuhr ?? asr!;
      final id = representative['id'] as String;
      final timeOfDay = prayerTimes['dhuhr'] ?? prayerTimes['asr'];
      
      var completion = AgendaCompletion.none;
      if (isToday) {
        var dhuhrDone = false;
        if (dhuhr != null) {
          final doneDate = dhuhr['dailyDoneDate'] as String?;
          dhuhrDone = (dhuhr['dailyDone'] as int? ?? 0) == 1 &&
              (doneDate == null || doneDate == dateStr);
        } else {
          dhuhrDone = true;
        }
        
        var asrDone = false;
        if (asr != null) {
          final doneDate = asr['dailyDoneDate'] as String?;
          asrDone = (asr['dailyDone'] as int? ?? 0) == 1 &&
              (doneDate == null || doneDate == dateStr);
        } else {
          asrDone = true;
        }
        
        completion = (dhuhrDone && asrDone) ? AgendaCompletion.done : AgendaCompletion.pending;
      }
      
      final start = _parseDateTime(dateStr, prayerTimes['dhuhr']);
      final end = _parseDateTime(dateStr, prayerTimes['maghrib']);
      items.add(AgendaItem(
        id: 'prayer:${id}_combined',
        domain: AgendaDomain.prayer,
        sourceId: id,
        title: 'نماز ظهر و عصر',
        dateStr: dateStr,
        timeOfDay: timeOfDay,
        category: Category.religious,
        completion: completion,
        priority: 3,
        isEssential: true,
        deepLink: AgendaDeepLink(domain: AgendaDomain.prayer, targetId: id),
        windowStart: start,
        windowEnd: end,
        meta: {'practice': representative},
      ));
    }

    // 3. Maghrib & Isha combined
    final maghrib = bySubType['MAGHRIB'];
    final isha = bySubType['ISHA'];
    if (maghrib != null || isha != null) {
      final representative = maghrib ?? isha!;
      final id = representative['id'] as String;
      final timeOfDay = prayerTimes['maghrib'] ?? prayerTimes['isha'];
      
      var completion = AgendaCompletion.none;
      if (isToday) {
        var maghribDone = false;
        if (maghrib != null) {
          final doneDate = maghrib['dailyDoneDate'] as String?;
          maghribDone = (maghrib['dailyDone'] as int? ?? 0) == 1 &&
              (doneDate == null || doneDate == dateStr);
        } else {
          maghribDone = true;
        }
        
        var ishaDone = false;
        if (isha != null) {
          final doneDate = isha['dailyDoneDate'] as String?;
          ishaDone = (isha['dailyDone'] as int? ?? 0) == 1 &&
              (doneDate == null || doneDate == dateStr);
        } else {
          ishaDone = true;
        }
        
        completion = (maghribDone && ishaDone) ? AgendaCompletion.done : AgendaCompletion.pending;
      }
      
      final start = _parseDateTime(dateStr, prayerTimes['maghrib']);
      final end = _parseDateTime(dateStr, prayerTimes['midnightShari'], nextDayIfBefore: true, referenceTime: start);
      items.add(AgendaItem(
        id: 'prayer:${id}_combined',
        domain: AgendaDomain.prayer,
        sourceId: id,
        title: 'نماز مغرب و عشا',
        dateStr: dateStr,
        timeOfDay: timeOfDay,
        category: Category.religious,
        completion: completion,
        priority: 3,
        isEssential: true,
        deepLink: AgendaDeepLink(domain: AgendaDomain.prayer, targetId: id),
        windowStart: start,
        windowEnd: end,
        meta: {'practice': representative},
      ));
    }

    // 4. Others
    for (final p in others) {
      final id = p['id'] as String;
      final subType = (p['subType'] as String? ?? '').toUpperCase();
      final timeKey = _prayerSubTypeToKey[subType];
      final timeOfDay = timeKey != null ? prayerTimes[timeKey] : null;

      var completion = AgendaCompletion.none;
      if (isToday) {
        final doneDate = p['dailyDoneDate'] as String?;
        final done = (p['dailyDone'] as int? ?? 0) == 1 &&
            (doneDate == null || doneDate == dateStr);
        completion = done ? AgendaCompletion.done : AgendaCompletion.pending;
      }

      items.add(AgendaItem(
        id: 'prayer:$id',
        domain: AgendaDomain.prayer,
        sourceId: id,
        title: p['title'] as String? ?? '',
        dateStr: dateStr,
        timeOfDay: timeOfDay,
        category: Category.religious,
        completion: completion,
        priority: 3,
        isEssential: true,
        deepLink: AgendaDeepLink(domain: AgendaDomain.prayer, targetId: id),
        meta: {'practice': p},
      ));
    }

    return items;
  }

  String? _resolveAnchorTime(
    String anchor,
    int offsetMinutes,
    Map<String, String> prayerTimes,
    Map<String, String> settingsMap,
  ) {
    String? baseTime;
    if (anchor == 'WAKEUP') {
      baseTime = settingsMap['sleep_target_wake'] ?? '07:00';
    } else if (anchor == 'BEDTIME') {
      baseTime = settingsMap['sleep_target_bedtime'] ?? '23:30';
    } else {
      String key;
      switch (anchor.toUpperCase()) {
        case 'FAJR':
          key = 'fajr';
        case 'SUNRISE':
          key = 'sunrise';
        case 'DHUHR':
          key = 'dhuhr';
        case 'ASR':
          key = 'asr';
        case 'MAGHRIB':
          key = 'maghrib';
        case 'ISHA':
          key = 'isha';
        case 'MIDNIGHT_SHARI':
          key = 'midnightShari';
        default:
          return null;
      }
      baseTime = prayerTimes[key];
    }

    if (baseTime == null || baseTime.isEmpty) return null;

    final parts = baseTime.split(':');
    if (parts.length == 2) {
      final h = int.tryParse(parts[0]) ?? 0;
      final m = int.tryParse(parts[1]) ?? 0;
      var total = h * 60 + m + offsetMinutes;
      if (total < 0) total += 24 * 60;
      final rh = (total ~/ 60) % 24;
      final rm = total % 60;
      return '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}';
    }
    return null;
  }

  Future<HijriDate?> _getHijriDate(DateTime date, _AgendaContext ctx) async {
    final y = date.year;
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    final key = 'hijri_date_${y}_${m}_$d';
    if (ctx.cachedHijriDates.containsKey(key)) {
      return ctx.cachedHijriDates[key];
    }
    // Fallback: fetch from database/network (original call)
    final hDate = await HijriDate.getOrFetch(date, ctx.db);
    if (hDate != null) {
      ctx.cachedHijriDates[key] = hDate;
    }
    return hDate;
  }

  Future<bool> _isLastDayOfHijriMonth(DateTime date, _AgendaContext ctx) async {
    final tomorrow = date.add(const Duration(days: 1));
    final tomorrowHijri = await _getHijriDate(tomorrow, ctx);
    return tomorrowHijri != null && tomorrowHijri.day == 1;
  }

  Future<List<AgendaItem>> _collectMustahab(
    _AgendaContext ctx,
    String dateStr,
    bool isToday,
    Map<String, String> prayerTimes,
    HijriDate? hijriDate,
  ) async {
    final items = <AgendaItem>[];
    for (final p in ctx.mustahabPractices) {
      final id = p['id'] as String;

      // Filter by days of week or month if applicable
      final freq = p['reminderFrequency'] as String? ?? 'DAILY';
      if (freq == 'WEEKLY') {
        final daysOfWeekStr = p['reminderDaysOfWeek'] as String?;
        if (daysOfWeekStr != null && daysOfWeekStr.trim().isNotEmpty) {
          final parsedDate = DateTime.parse(dateStr);
          final allowedDays = daysOfWeekStr.split(',').map(int.tryParse).whereType<int>().toSet();
          if (allowedDays.isNotEmpty && !allowedDays.contains(parsedDate.weekday)) {
            continue; // Skip this mustahab for this date
          }
        }
      } else if (freq == 'MONTHLY') {
        final dayOfMonthStr = p['reminderDaysOfWeek'] as String?;
        if (dayOfMonthStr != null && dayOfMonthStr.trim().isNotEmpty) {
          final parsedDate = DateTime.parse(dateStr);
          final jalaliDate = Jalali.fromDateTime(parsedDate);
          final allowedDays = dayOfMonthStr.split(',').map(int.tryParse).whereType<int>().toSet();
          if (allowedDays.isNotEmpty) {
            var matches = false;
            for (final targetDay in allowedDays) {
              if (jalaliDate.day == targetDay) {
                matches = true;
                break;
              }
              // Handle day 31 / 30 for months with fewer days
              if (targetDay == 31 && jalaliDate.monthLength < 31 && jalaliDate.day == jalaliDate.monthLength) {
                matches = true;
                break;
              }
              if (targetDay == 30 && jalaliDate.monthLength < 30 && jalaliDate.day == jalaliDate.monthLength) {
                matches = true;
                break;
              }
            }
            if (!matches) {
              continue; // Skip this mustahab for this date
            }
          }
        }
      } else if (freq == 'LUNAR_MONTHLY') {
        final dayOfMonthStr = p['reminderDaysOfWeek'] as String?;
        if (dayOfMonthStr != null && dayOfMonthStr.trim().isNotEmpty && hijriDate != null) {
          final allowedDays = dayOfMonthStr.split(',').map(int.tryParse).whereType<int>().toSet();
          if (allowedDays.isNotEmpty) {
            var matches = false;
            final parsedDate = DateTime.parse(dateStr);
            final isLastDay = await _isLastDayOfHijriMonth(parsedDate, ctx);
            for (final targetDay in allowedDays) {
              if (hijriDate.day == targetDay) {
                matches = true;
                break;
              }
              // Handle day 30 for 29-day Hijri months
              if (targetDay == 30 && isLastDay && hijriDate.day == 29) {
                matches = true;
                break;
              }
            }
            if (!matches) {
              continue; // Skip this mustahab for this date
            }
          }
        }
      } else if (freq == 'ONCE') {
        final targetDateStr = p['reminderDaysOfWeek'] as String?;
        if (targetDateStr != dateStr) {
          continue; // Skip this mustahab for this date
        }
      }

      var completion = AgendaCompletion.none;
      if (isToday) {
        final doneDate = p['dailyDoneDate'] as String?;
        final done = (p['dailyDone'] as int? ?? 0) == 1 &&
            (doneDate == null || doneDate == dateStr);
        completion = done ? AgendaCompletion.done : AgendaCompletion.pending;
      }

      final anchor = p['reminderAnchor'] as String? ?? 'NONE';
      final offsetMinutes = p['reminderOffsetMinutes'] as int? ?? 0;
      var resolvedTimes = <String>[];

      if (anchor != 'NONE') {
        final resolved = _resolveAnchorTime(anchor, offsetMinutes, prayerTimes, ctx.settingsMap);
        if (resolved != null) {
          resolvedTimes.add(resolved);
        }
      } else {
        // Multiple fixed times
        final multipleTimesStr = p['reminderTimes'] as String?;
        if (multipleTimesStr != null && multipleTimesStr.trim().isNotEmpty) {
          try {
            final decoded = jsonDecode(multipleTimesStr);
            if (decoded is List) {
              resolvedTimes = decoded.map((e) => e.toString()).toList();
            }
          } catch (_) {}
        }
        if (resolvedTimes.isEmpty) {
          final singleTime = p['reminderTime'] as String?;
          if (singleTime != null && singleTime.isNotEmpty) {
            resolvedTimes.add(singleTime);
          }
        }
      }

      if (resolvedTimes.isEmpty) {
        resolvedTimes.add('08:00'); // fallback
      }

      for (final resolvedTime in resolvedTimes) {
        items.add(AgendaItem(
          id: resolvedTimes.length > 1 ? 'mustahab:$id:$resolvedTime' : 'mustahab:$id',
          domain: AgendaDomain.mustahab,
          sourceId: id,
          title: p['title'] as String? ?? '',
          dateStr: dateStr,
          timeOfDay: resolvedTime,
          category: Category.religious,
          completion: completion,
          deepLink: AgendaDeepLink(domain: AgendaDomain.mustahab, targetId: id),
          meta: {'practice': p},
        ));
      }
    }
    return items;
  }

  List<AgendaItem> _collectWorshipDebts(_AgendaContext ctx, String dateStr) {
    final items = <AgendaItem>[];
    for (final dbt in ctx.worshipDebts) {
      final id = dbt['id'] as String;
      final remaining = dbt['remainingCount'] as int? ?? 0;
      if (remaining <= 0) continue;
      items.add(AgendaItem(
        id: 'worshipDebt:$id',
        domain: AgendaDomain.worshipDebt,
        sourceId: id,
        title: dbt['title'] as String? ?? 'قضا',
        subtitle: '$remaining باقی‌مانده',
        dateStr: dateStr,
        category: Category.religious,
        priority: 0.5,
        deepLink:
            AgendaDeepLink(domain: AgendaDomain.worshipDebt, targetId: id),
        meta: {'debt': dbt},
      ));
    }
    return items;
  }

  List<AgendaItem> _collectCourses(_AgendaContext ctx, String dateStr) {
    final sessions = ctx.sessionsByDate[dateStr] ?? const [];
    return sessions.map((s) {
      final course = ctx.coursesMap[s.courseId];
      return AgendaItem(
        id: 'course:${s.id}',
        domain: AgendaDomain.course,
        sourceId: s.id,
        title: s.sessionTitle ?? 'جلسه ${s.sessionNumber}',
        subtitle: course?.title,
        dateStr: dateStr,
        timeOfDay: course?.preferredTime,
        durationMinutes: course?.sessionDurationMinutes,
        category: Category.learning,
        completion:
            s.isCompleted ? AgendaCompletion.done : AgendaCompletion.pending,
        priority: 1.5,
        deepLink:
            AgendaDeepLink(domain: AgendaDomain.course, targetId: s.courseId),
        meta: {'session': s.toMap()},
      );
    }).toList();
  }

  List<AgendaItem> _collectGoalSteps(_AgendaContext ctx, String dateStr) {
    final rows = ctx.goalStepsByDate[dateStr] ?? const [];
    return rows.map((m) {
      final id = m['id'] as String;
      final goalId = m['goalId'] as String? ?? '';
      final completed = (m['isCompleted'] as int? ?? 0) == 1;
      return AgendaItem(
        id: 'goalStep:$id',
        domain: AgendaDomain.goalStep,
        sourceId: id,
        title: m['title'] as String? ?? '',
        subtitle: m['goalTitle'] as String?,
        dateStr: dateStr,
        category: Category.personal,
        completion:
            completed ? AgendaCompletion.done : AgendaCompletion.pending,
        deepLink:
            AgendaDeepLink(domain: AgendaDomain.goalStep, targetId: goalId),
        meta: {'step': m},
      );
    }).toList();
  }

  List<AgendaItem> _collectKonkur(_AgendaContext ctx, String dateStr) {
    final plan = ctx.konkurByDate[dateStr] ?? const [];
    return plan.map((item) {
      AgendaCompletion completion;
      switch (item.status) {
        case 'DONE':
          completion = AgendaCompletion.done;
        case 'SKIPPED':
          completion = AgendaCompletion.skipped;
        default:
          completion = AgendaCompletion.pending;
      }
      final subjectName =
          item.subjectId != null ? ctx.konkurSubjectNames[item.subjectId] : null;
      return AgendaItem(
        id: 'konkur:${item.id}',
        domain: AgendaDomain.konkur,
        sourceId: item.id,
        title: subjectName ?? 'برنامه کنکور',
        subtitle: item.plannedMinutes > 0 ? '${item.plannedMinutes} دقیقه' : null,
        dateStr: dateStr,
        durationMinutes: item.plannedMinutes > 0 ? item.plannedMinutes : null,
        category: Category.konkur,
        completion: completion,
        priority: 1.2,
        deepLink:
            AgendaDeepLink(domain: AgendaDomain.konkur, targetId: item.id),
        meta: {'planItem': item.toMap()},
      );
    }).toList();
  }

  AgendaItem? _collectCycle(
    _AgendaContext ctx,
    DateTime date,
    String dateStr,
    bool isToday,
  ) {
    final out = ctx.cycleOutput;
    if (out == null || !out.hasData) return null;

    final day = DateTime(date.year, date.month, date.day);
    bool inWindow(DateTime start, DateTime end) {
      final s = DateTime(start.year, start.month, start.day);
      final e = DateTime(end.year, end.month, end.day);
      return !day.isBefore(s) && !day.isAfter(e);
    }

    String? title;
    if (isToday && out.dayOfPeriod > 0) {
      title = 'چرخه ماهانه (روز ${out.dayOfPeriod})';
    } else if (inWindow(out.nextPeriodWindowStart, out.nextPeriodWindowEnd)) {
      title = 'پیش‌بینی شروع دوره';
    } else if (inWindow(out.pmsWindowStart, out.pmsWindowEnd)) {
      title = 'پنجره‌ی PMS';
    } else if (inWindow(out.fertileWindowStart, out.fertileWindowEnd)) {
      title = 'پنجره‌ی باروری';
    }

    if (title == null) return null;

    return AgendaItem(
      id: 'cycle:$dateStr',
      domain: AgendaDomain.cycle,
      sourceId: dateStr,
      title: title,
      dateStr: dateStr,
      category: Category.personal,
      priority: 0.8,
      deepLink: AgendaDeepLink(domain: AgendaDomain.cycle, targetId: dateStr),
    );
  }

  List<AgendaItem> _collectSports(
    _AgendaContext ctx,
    String dateStr,
    DateTime date,
  ) {
    final items = <AgendaItem>[];
    final plans = ctx.sportsPlansByDay[date.weekday] ?? const [];
    for (final plan in plans) {
      final id = plan['id'] as String;
      final estMins = plan['estimatedMinutes'] as int? ?? 45;
      final muscleGroups = plan['muscleGroups'] as String? ?? 'تمرین ورزشی';
      items.add(AgendaItem(
        id: 'sport:plan:$id',
        domain: AgendaDomain.sport,
        sourceId: id,
        title: 'برنامه ورزشی: $muscleGroups',
        subtitle: '$estMins دقیقه',
        dateStr: dateStr,
        durationMinutes: estMins,
        category: Category.fitness,
        priority: 1.4,
        deepLink: AgendaDeepLink(domain: AgendaDomain.sport, targetId: id),
        meta: {'workoutPlan': plan},
      ));
    }
    return items;
  }

  List<AgendaItem> _collectMedicine(
    _AgendaContext ctx,
    String dateStr,
    bool isToday,
  ) {
    final items = <AgendaItem>[];
    final logs = ctx.medicineLogsByDate[dateStr] ?? const [];
    for (final log in logs) {
      final id = log['id'] as String;
      final status = log['status'] as String? ?? 'TAKEN';
      final isDone = status == 'TAKEN';
      items.add(AgendaItem(
        id: 'medicine:log:$id',
        domain: AgendaDomain.medicine,
        sourceId: id,
        title: 'یادآور دارو',
        subtitle: log['note'] as String?,
        dateStr: dateStr,
        category: Category.medical,
        completion: isDone ? AgendaCompletion.done : AgendaCompletion.pending,
        priority: 2.0,
        isEssential: true,
        deepLink: AgendaDeepLink(domain: AgendaDomain.medicine, targetId: id),
        meta: {'medicationLog': log},
      ));
    }
    return items;
  }

  DateTime? _parseDateTime(String dateStr, String? timeStr, {bool nextDayIfBefore = false, DateTime? referenceTime}) {
    if (timeStr == null || timeStr.isEmpty) return null;
    try {
      final parts = timeStr.split(':');
      final date = DateTime.parse(dateStr);
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      var dt = DateTime(date.year, date.month, date.day, hour, minute);
      if (nextDayIfBefore && referenceTime != null && dt.isBefore(referenceTime)) {
        dt = dt.add(const Duration(days: 1));
      }
      return dt;
    } catch (_) {
      return null;
    }
  }
}

/// Shared, range-scoped data loaded once and reused across every day.
class _AgendaContext {

  _AgendaContext({
    required this.db,
    required this.settingsMap,
    required this.religionEnabled,
    required this.coursesEnabled,
    required this.konkurEnabled,
    required this.cycleAllowed,
    required this.sportsEnabled,
    required this.medicineEnabled,
    required this.routineSource,
    required this.completionsByDate,
    required this.prayerPractices,
    required this.mustahabPractices,
    required this.worshipDebts,
    required this.courseTitles,
    required this.coursesMap,
    required this.sessionsByDate,
    required this.konkurByDate,
    required this.konkurSubjectNames,
    required this.cycleOutput,
    required this.goalStepsByDate,
    required this.sportsPlansByDay,
    required this.medicineLogsByDate,
    required this.cachedHijriDates,
    required this.latitude,
    required this.longitude,
    required this.ihtiyatMinutes,
    required this.calcMethodStr,
  });
  final Database db;
  final Map<String, String> settingsMap;
  final bool religionEnabled;
  final bool coursesEnabled;
  final bool konkurEnabled;
  final bool cycleAllowed;
  final bool sportsEnabled;
  final bool medicineEnabled;
  final RoutineAgendaSource routineSource;
  final Map<String, Map<String, Map<String, dynamic>>> completionsByDate;
  final List<Map<String, dynamic>> prayerPractices;
  final List<Map<String, dynamic>> mustahabPractices;
  final List<Map<String, dynamic>> worshipDebts;
  final Map<String, String> courseTitles;
  final Map<String, Course> coursesMap;
  final Map<String, List<CourseSession>> sessionsByDate;
  final Map<String, List<KonkurPlanItem>> konkurByDate;
  final Map<String, String> konkurSubjectNames;
  final CycleEngineOutput? cycleOutput;
  final Map<String, List<Map<String, dynamic>>> goalStepsByDate;
  final Map<int, List<Map<String, dynamic>>> sportsPlansByDay;
  final Map<String, List<Map<String, dynamic>>> medicineLogsByDate;
  final Map<String, HijriDate> cachedHijriDates;
  final double latitude;
  final double longitude;
  final int ihtiyatMinutes;
  final String calcMethodStr;

  /// Prayer-times cache keyed by `cityId|date`.
  final Map<String, Map<String, String>> _prayerCache = {};

  Future<Map<String, String>> prayerTimesFor(DateTime date) async {
    final cityId = settingsMap['prayer_city_id'] ??
        settingsMap['home_city_id'] ??
        'TEHRAN_TEHRAN';
    final ds = date.toIso8601String().substring(0, 10);
    final key = '$cityId|$ds';
    final cached = _prayerCache[key];
    if (cached != null) return cached;
    try {
      final times = PrayerTimeProvider.instance.computePrayerTimes(
        latitude: latitude,
        longitude: longitude,
        ihtiyatMinutes: ihtiyatMinutes,
        calcMethodStr: calcMethodStr,
        date: date,
      );
      _prayerCache[key] = times;
      return times;
    } catch (e) {
      debugPrint('DayAgendaService prayer times error: $e');
      _prayerCache[key] = const {};
      return const {};
    }
  }
}
