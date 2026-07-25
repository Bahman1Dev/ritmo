import 'dart:convert';

import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/engines/routine_occurrence_generator.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:sqflite/sqflite.dart';

/// Shared source of truth for "which routines are active on a given date".
///
/// Extracted from the duplicated inline logic that lived in
/// `calendar_screen.dart::_getActiveRoutinesForDate` and the dashboard
/// controller, so both the Calendar and `DayAgendaService` consume the same
/// resolution rules (DB occurrences first, then RecurrenceRule fallback).
///
/// Holds raw in-memory rows (loaded once) and resolves per-date without extra
/// queries, which keeps the month range view (31 days) cheap.
class RoutineAgendaSource {

  const RoutineAgendaSource({
    required this.routines,
    required this.schedules,
    required this.occurrences,
    required this.avgDurations,
    required this.categoryAvgDurations,
    required this.activeModules,
  });
  final List<Map<String, dynamic>> routines;
  final List<Map<String, dynamic>> schedules;
  final List<Map<String, dynamic>> occurrences;
  final Map<String, double> avgDurations;
  final Map<String, double> categoryAvgDurations;

  /// Module gates the routine list honors: keys `religion`, `medicine`, `courses`.
  final Map<String, bool> activeModules;

  /// Loads all routine rows once. Reuse the returned instance for a whole
  /// range; do not reload per day.
  static Future<RoutineAgendaSource> load(
    Database db,
    Map<String, String> settingsMap,
  ) async {
    final routines = await db.query('routines', where: 'isArchived = 0');
    final schedules = await db.query('routine_schedules');
    final occurrences = await db.query('routine_occurrences');

    final avgDurations = <String, double>{};
    try {
      final list = await db.rawQuery('''
        SELECT routineId, AVG(COALESCE(actual_duration_minutes, durationMinutes)) as avgDur 
        FROM routine_completions 
        WHERE (actual_duration_minutes IS NOT NULL AND actual_duration_minutes > 0)
           OR (durationMinutes IS NOT NULL AND durationMinutes > 0)
        GROUP BY routineId
      ''');
      for (final row in list) {
        final rId = row['routineId']! as String;
        final avg = (row['avgDur'] as num?)?.toDouble();
        if (avg != null && avg > 0) {
          avgDurations[rId] = avg;
        }
      }
    } catch (_) {}

    final categoryAvgDurations = <String, double>{};
    try {
      final list = await db.rawQuery('''
        SELECT r.category, AVG(COALESCE(c.actual_duration_minutes, c.durationMinutes)) as avgDur 
        FROM routine_completions c
        JOIN routines r ON c.routineId = r.id
        WHERE (c.actual_duration_minutes IS NOT NULL AND c.actual_duration_minutes > 0)
           OR (c.durationMinutes IS NOT NULL AND c.durationMinutes > 0)
        GROUP BY r.category
      ''');
      for (final row in list) {
        final cat = row['category']! as String;
        final avg = (row['avgDur'] as num?)?.toDouble();
        if (avg != null && avg > 0) {
          categoryAvgDurations[cat] = avg;
        }
      }
    } catch (_) {}

    return RoutineAgendaSource(
      routines: routines.map(Map<String, dynamic>.from).toList(),
      schedules: schedules.map(Map<String, dynamic>.from).toList(),
      occurrences:
          occurrences.map(Map<String, dynamic>.from).toList(),
      avgDurations: avgDurations,
      categoryAvgDurations: categoryAvgDurations,
      activeModules: {
        'religion': settingsMap['module_religion_enabled'] == 'true',
        'medicine': settingsMap['module_medicine_enabled'] == 'true',
        'courses': settingsMap['module_courses_enabled'] == 'true',
      },
    );
  }

  static String _dateStr(DateTime dt) => dt.toIso8601String().substring(0, 10);

  bool _isCategoryModuleEnabled(String category) {
    if (category == 'religious' && !(activeModules['religion'] ?? false)) {
      return false;
    }
    if (category == 'medical' && !(activeModules['medicine'] ?? false)) {
      return false;
    }
    if (category == 'learning' && !(activeModules['courses'] ?? false)) {
      return false;
    }
    return true;
  }

  /// Active routines (raw `{routine, schedule}` maps) for [date].
  ///
  /// Mirrors the previous `_getActiveRoutinesForDate` behavior exactly so the
  /// Calendar keeps the same output when it switches to this source.
  List<Map<String, dynamic>> activeForDate(DateTime date) {
    final active = <Map<String, dynamic>>[];
    final dateStr = _dateStr(date);

    for (final r in routines) {
      final cat = r['category'] as String;
      if (!_isCategoryModuleEnabled(cat)) continue;

      final s = schedules.firstWhere(
        (sched) => sched['routineId'] == r['id'],
        orElse: () => <String, dynamic>{},
      );

      if (s.isEmpty) continue;

      // 1. Check database occurrences in memory.
      final hasOcc = occurrences
          .any((occ) => occ['routineId'] == r['id'] && occ['date'] == dateStr);
      if (hasOcc) {
        active.add({'routine': r, 'schedule': s});
        continue;
      }

      // 2. Fallback: RecurrenceRule calculation.
      RecurrenceRule rule;
      final ruleStr = s['recurrenceRule'] as String?;
      if (ruleStr != null && ruleStr.isNotEmpty) {
        rule = RecurrenceRule.fromMap(jsonDecode(ruleStr));
      } else {
        final daysStr = s['daysOfWeek'] as String? ?? '6,7,1,2,3,4,5';
        final days =
            daysStr.split(',').map((d) => int.tryParse(d.trim()) ?? 1).toList();
        rule = RecurrenceRule(
          weekdays: days,
          reminderTimes:
              s['timeOfDay'] != null ? [s['timeOfDay'] as String] : ['08:00'],
        );
      }

      if (RoutineOccurrenceGenerator.shouldOccurOnDate(date, rule)) {
        active.add({'routine': r, 'schedule': s});
      }
    }

    return active;
  }

  static String _mapAnchorToKey(String anchor) {
    switch (anchor.toUpperCase()) {
      case 'FAJR':
        return 'fajr';
      case 'SUNRISE':
        return 'sunrise';
      case 'DHUHR':
        return 'dhuhr';
      case 'ASR':
        return 'asr';
      case 'MAGHRIB':
        return 'maghrib';
      case 'ISHA':
        return 'isha';
      default:
        return anchor.toLowerCase();
    }
  }

  static String? _normalizeTimeOfDay(String? raw) {
    if (raw == null) return null;
    final value = raw.trim();

    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(value);
    if (match == null) return null;

    final hour = int.tryParse(match.group(1)!);
    final minute = int.tryParse(match.group(2)!);
    if (hour == null || minute == null) return null;
    if (hour < 0 || hour >= 24 || minute < 0 || minute >= 60) return null;

    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Resolves the concrete `HH:mm` for a routine schedule, honoring prayer
  /// anchors (anchor time + offset) via [prayerTimes].
  static String? resolveTime(
    Map<String, dynamic> schedule,
    Map<String, String> prayerTimes,
  ) {
    final rawTime = schedule['timeOfDay'] as String?;
    final normalizedDirect = _normalizeTimeOfDay(rawTime);
    if (normalizedDirect != null) return normalizedDirect;

    final anchorEvent = schedule['anchorEvent'] as String?;
    if (anchorEvent != null) {
      final adhanTimeStr = prayerTimes[_mapAnchorToKey(anchorEvent)];
      final normalizedAnchor = _normalizeTimeOfDay(adhanTimeStr);

      if (normalizedAnchor != null) {
        final parts = normalizedAnchor.split(':');
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);

        final offset = schedule['anchorOffsetMinutes'] as int? ?? 0;
        var total = h * 60 + m + offset;

        while (total < 0) {
          total += 24 * 60;
        }
        total = total % (24 * 60);

        final rh = total ~/ 60;
        final rm = total % 60;

        return '${rh.toString().padLeft(2, '0')}:${rm.toString().padLeft(2, '0')}';
      }
    }

    return null;
  }

  /// Builds normalized [AgendaItem]s for routines active on [date].
  ///
  /// [completionsByRoutineId] maps routineId -> the completion row for [date]
  /// (already filtered to that date by the caller).
  List<AgendaItem> agendaItemsForDate(
    DateTime date, {
    required Map<String, String> prayerTimes,
    Map<String, Map<String, dynamic>> completionsByRoutineId = const {},
  }) {
    final dateStr = _dateStr(date);
    final items = <AgendaItem>[];

    for (final entry in activeForDate(date)) {
      final r = entry['routine'] as Map<String, dynamic>;
      final s = entry['schedule'] as Map<String, dynamic>;
      final routineId = r['id'] as String;

      final catStr = r['category'] as String;
      final category = Category.values.firstWhere(
        (e) => e.name.toLowerCase() == catStr.toLowerCase(),
        orElse: () => Category.custom,
      );

      final resolvedTime = resolveTime(s, prayerTimes);

      final completion = completionsByRoutineId[routineId];
      var completionState = AgendaCompletion.pending;
      if (completion != null) {
        final resType = completion['resultType'] as String? ?? 'FULL';
        switch (resType) {
          case 'FULL':
            completionState = AgendaCompletion.done;
          case 'LIGHT':
          case 'MINIMAL':
            completionState = AgendaCompletion.partial;
          case 'SKIPPED':
            completionState = AgendaCompletion.skipped;
          default:
            completionState = AgendaCompletion.pending;
        }
      }

      var dur = r['targetDurationMinutes'] as int?;
      var isEstimated = false;

      // Only estimate when duration is missing or invalid.
      // Do NOT replace legitimate long routines with a fake shorter average.
      if (dur == null || dur <= 0) {
        final avg = avgDurations[routineId] ?? categoryAvgDurations[catStr] ?? 30.0;
        dur = avg.round().clamp(DurationBounds.minMinutes, 120);
        isEstimated = true;
      } else {
        dur = DurationBounds.sanitize(dur);
      }

      items.add(AgendaItem(
        id: 'routine:$routineId',
        domain: AgendaDomain.routine,
        sourceId: routineId,
        title: r['title'] as String? ?? '',
        dateStr: dateStr,
        timeOfDay: resolvedTime,
        durationMinutes: dur,
        category: category,
        completion: completionState,
        priority: (r['priority'] as num?)?.toDouble() ?? 1.0,
        isEssential: r['isEssential'] == 1,
        deepLink:
            AgendaDeepLink(domain: AgendaDomain.routine, targetId: routineId),
        meta: {
          'routine': r,
          'schedule': s,
          if (isEstimated) 'isAIEstimated': true,
        },
      ));
    }

    return items;
  }
}
