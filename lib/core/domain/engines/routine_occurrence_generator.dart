import 'dart:convert';

import 'package:ritmo/core/domain/models.dart';
import 'package:sqflite/sqflite.dart';

/// Engine responsible for generating and calculating routine occurrence dates.
class RoutineOccurrenceGenerator {
  /// Deterministically checks if a routine should occur on a specific date based on its RecurrenceRule.
  static bool shouldOccurOnDate(DateTime date, RecurrenceRule rule) {
    // Strip time component for date-only comparisons
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (rule.startDate != null) {
      final startOnly = DateTime(
        rule.startDate!.year,
        rule.startDate!.month,
        rule.startDate!.day,
      );
      if (dateOnly.isBefore(startOnly)) return false;
    }

    if (rule.endDate != null) {
      final endOnly = DateTime(
        rule.endDate!.year,
        rule.endDate!.month,
        rule.endDate!.day,
      );
      if (dateOnly.isAfter(endOnly)) return false;
    }

    if (rule.excludedDates != null) {
      for (final ex in rule.excludedDates!) {
        if (ex.year == date.year &&
            ex.month == date.month &&
            ex.day == date.day) {
          return false;
        }
      }
    }

    // Interval in Hours (Hourly Recurrence)
    if (rule.intervalHours != null && rule.intervalHours! > 0) {
      if (rule.startDate == null) return false;
      final start = rule.startDate!;
      final targetStart = DateTime(date.year, date.month, date.day);
      var k = 0;
      if (targetStart.isAfter(start)) {
        final diffSeconds = targetStart.difference(start).inSeconds;
        final intervalSeconds = rule.intervalHours! * 3600;
        k = (diffSeconds / intervalSeconds).ceil();
      }
      final occurrence = start.add(Duration(hours: k * rule.intervalHours!));
      return occurrence.year == date.year &&
          occurrence.month == date.month &&
          occurrence.day == date.day;
    }

    // 1. Weekly with optional weekdays list
    if (rule.weekdays.isNotEmpty) {
      final weekdayMatch = rule.weekdays.contains(date.weekday);
      if (!weekdayMatch) return false;

      if (rule.intervalDays != null && rule.intervalDays! > 7) {
        if (rule.startDate == null) return false;
        final startOnly = DateTime(
          rule.startDate!.year,
          rule.startDate!.month,
          rule.startDate!.day,
        );
        // Align weeks to Saturday
        int daysToSaturday(int weekday) =>
            weekday >= 6 ? weekday - 6 : weekday + 1;
        final startSaturday = startOnly.subtract(
          Duration(days: daysToSaturday(startOnly.weekday)),
        );
        final targetSaturday = dateOnly.subtract(
          Duration(days: daysToSaturday(dateOnly.weekday)),
        );
        final diffWeeks = targetSaturday.difference(startSaturday).inDays ~/ 7;
        final intervalWeeks = rule.intervalDays! ~/ 7;
        return diffWeeks >= 0 && diffWeeks % intervalWeeks == 0;
      }
      return true;
    }

    // 2. Interval in Days (e.g., Every N days)
    if (rule.intervalDays != null && rule.intervalDays! > 0) {
      if (rule.startDate == null) return false;
      final startOnly = DateTime(
        rule.startDate!.year,
        rule.startDate!.month,
        rule.startDate!.day,
      );
      final diff = dateOnly.difference(startOnly).inDays;
      return diff >= 0 && diff % rule.intervalDays! == 0;
    }

    // 3. Monthly on specific day (e.g., Day 15 of every month)
    if (rule.monthDay != null) {
      return date.day == rule.monthDay;
    }

    // Default: daily
    return true;
  }

  /// Pre-generates occurrences for a routine for [days] count forward.
  static Future<void> generateFutureOccurrences(
    DatabaseExecutor db,
    String routineId,
    RecurrenceRule rule, {
    int days = 30,
  }) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    for (var i = 0; i < days; i++) {
      final targetDate = today.add(Duration(days: i));
      final dateStr = targetDate.toIso8601String().substring(0, 10);

      if (shouldOccurOnDate(targetDate, rule)) {
        var timeStr =
            rule.reminderTimes.isNotEmpty
                ? rule.reminderTimes.first
                : '08:00';
        if (rule.intervalHours != null &&
            rule.intervalHours! > 0 &&
            rule.startDate != null) {
          final start = rule.startDate!;
          final targetStart = DateTime(
            targetDate.year,
            targetDate.month,
            targetDate.day,
          );
          var k = 0;
          if (targetStart.isAfter(start)) {
            final diffSeconds = targetStart.difference(start).inSeconds;
            final intervalSeconds = rule.intervalHours! * 3600;
            k = (diffSeconds / intervalSeconds).ceil();
          }
          final occurrence = start.add(
            Duration(hours: k * rule.intervalHours!),
          );
          timeStr = occurrence.toIso8601String().substring(11, 16);
        }

        await db.insert(
          'routine_occurrences',
          {
            'routine_id': routineId,
            'date': dateStr,
            'scheduled_time': timeStr,
            'status': 'pending',
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    }
  }

  /// Regenerates occurrences starting from today. Preserves past occurrences.
  static Future<void> regenerateOccurrences(
    DatabaseExecutor db,
    String routineId,
    RecurrenceRule rule,
  ) async {
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    // Delete future/today occurrences
    await db.delete(
      'routine_occurrences',
      where: 'routine_id = ? AND date >= ?',
      whereArgs: [routineId, todayStr],
    );

    // Generate for next 30 days starting today
    await generateFutureOccurrences(db, routineId, rule);
  }

  /// Clears all occurrences for a routine (e.g. when deleted).
  static Future<void> clearAllOccurrences(
    DatabaseExecutor db,
    String routineId,
  ) async {
    await db.delete(
      'routine_occurrences',
      where: 'routine_id = ?',
      whereArgs: [routineId],
    );
  }

  /// Scans all active routines and backfills missing days in past 30 days.
  static Future<void> backfillAndGenerateAll(DatabaseExecutor db) async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Load active routines and schedules
    final routines = await db.query('routines', where: 'isArchived = 0');
    final schedules = await db.query('routine_schedules');

    final batch = db.batch();

    for (final rMap in routines) {
      final rId = rMap['id']! as String;
      final sched = schedules.firstWhere(
        (s) => s['routineId'] == rId,
        orElse: () => <String, dynamic>{},
      );
      if (sched.isEmpty) continue;

      RecurrenceRule rule;
      if (sched['recurrenceRule'] != null &&
          (sched['recurrenceRule']! as String).isNotEmpty) {
        final decoded =
            jsonDecode(sched['recurrenceRule']! as String) as Map<String, dynamic>;
        rule = RecurrenceRule.fromMap(decoded);
      } else {
        // Build fallback RecurrenceRule from daysOfWeek / timeOfDay
        final daysStr = sched['daysOfWeek'] as String? ?? '6,7,1,2,3,4,5';
        final days =
            daysStr.split(',').map((d) => int.tryParse(d.trim()) ?? 1).toList();
        rule = RecurrenceRule(
          weekdays: days,
          reminderTimes:
              sched['timeOfDay'] != null
                  ? [sched['timeOfDay']! as String]
                  : ['08:00'],
        );
      }

      // Backfill past 30 days and generate future 30 days
      for (var i = -30; i < 30; i++) {
        final targetDate = today.add(Duration(days: i));
        final dateStr = targetDate.toIso8601String().substring(0, 10);

        if (shouldOccurOnDate(targetDate, rule)) {
          var timeStr =
              rule.reminderTimes.isNotEmpty
                  ? rule.reminderTimes.first
                  : '08:00';
          if (rule.intervalHours != null &&
              rule.intervalHours! > 0 &&
              rule.startDate != null) {
            final start = rule.startDate!;
            final targetStart = DateTime(
              targetDate.year,
              targetDate.month,
              targetDate.day,
            );
            var k = 0;
            if (targetStart.isAfter(start)) {
              final diffSeconds = targetStart.difference(start).inSeconds;
              final intervalSeconds = rule.intervalHours! * 3600;
              k = (diffSeconds / intervalSeconds).ceil();
            }
            final occurrence = start.add(
              Duration(hours: k * rule.intervalHours!),
            );
            timeStr = occurrence.toIso8601String().substring(11, 16);
          }

          batch.insert(
            'routine_occurrences',
            {
              'routine_id': rId,
              'date': dateStr,
              'scheduled_time': timeStr,
              'status': 'pending',
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      }
    }

    await batch.commit(noResult: true);
  }
}
