import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:sqflite/sqflite.dart';

/// Represents a search match across calendar/agenda sources.
class CalendarSearchHit {
  const CalendarSearchHit({
    required this.id,
    required this.sourceId,
    required this.title,
    this.subtitle,
    required this.domain,
    required this.dateStr,
    this.timeOfDay,
  });

  final String id;
  final String sourceId;
  final String title;
  final String? subtitle;
  final AgendaDomain domain;
  final String dateStr;
  final String? timeOfDay;
}

/// K35 + K38 — Global Calendar Search Repository.
/// Queries tasks, routines, goal steps across the whole database range.
/// Zero-Leak (K38): Excludes sensitive medical/cycle keywords if required.
class CalendarSearchRepository {
  CalendarSearchRepository._();
  static final CalendarSearchRepository instance = CalendarSearchRepository._();

  static const _sensitiveKeywords = ['پریود', 'چرخه', 'قاعدگی', 'دارو', 'پزشکی'];

  Future<List<CalendarSearchHit>> search(
    String query, {
    int limit = 50,
  }) async {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return [];

    final hits = <CalendarSearchHit>[];

    try {
      final db = await DatabaseHelper.instance.database;

      // 1. Search simple_tasks
      final tasks = await db.rawQuery('''
        SELECT id, title, note, dueDate, dueTime, isDone
        SELECT_FROM_TASKS
        WHERE title LIKE ? OR note LIKE ?
        ORDER BY createdAt DESC
        LIMIT ?
      '''.replaceAll('SELECT_FROM_TASKS', 'FROM simple_tasks'), ['%$q%', '%$q%', limit]);

      for (final row in tasks) {
        final title = row['title']?.toString() ?? '';
        if (_isSensitive(title)) continue;

        final dueDate = row['dueDate']?.toString() ?? 'بدون تاریخ';
        hits.add(CalendarSearchHit(
          id: 'task:${row['id']}:$dueDate',
          sourceId: row['id'].toString(),
          title: title,
          subtitle: row['note']?.toString(),
          domain: AgendaDomain.task,
          dateStr: dueDate,
          timeOfDay: row['dueTime']?.toString(),
        ));
      }

      // 2. Search routines
      final routines = await db.rawQuery('''
        SELECT id, title, category
        FROM routines
        WHERE title LIKE ?
        LIMIT ?
      ''', ['%$q%', limit]);

      for (final row in routines) {
        final title = row['title']?.toString() ?? '';
        if (_isSensitive(title)) continue;

        hits.add(CalendarSearchHit(
          id: 'routine:${row['id']}',
          sourceId: row['id'].toString(),
          title: title,
          subtitle: 'روتین',
          domain: AgendaDomain.routine,
          dateStr: DateTime.now().toIso8601String().substring(0, 10),
        ));
      }

      // 3. Search goal_steps
      final steps = await db.rawQuery('''
        SELECT gs.id, gs.title, gs.scheduledDate, g.title as goalTitle
        FROM goal_steps gs
        JOIN goals g ON gs.goalId = g.id
        WHERE gs.title LIKE ? OR g.title LIKE ?
        LIMIT ?
      ''', ['%$q%', '%$q%', limit]);

      for (final row in steps) {
        final title = row['title']?.toString() ?? '';
        if (_isSensitive(title)) continue;

        final dateStr = row['scheduledDate']?.toString() ?? '';
        hits.add(CalendarSearchHit(
          id: 'goalStep:${row['id']}:$dateStr',
          sourceId: row['id'].toString(),
          title: title,
          subtitle: row['goalTitle']?.toString(),
          domain: AgendaDomain.goalStep,
          dateStr: dateStr.isNotEmpty ? dateStr : 'بدون تاریخ',
        ));
      }
    } catch (e) {
      debugPrint('[CalendarSearchRepository] Search error: $e');
    }

    return hits.take(limit).toList();
  }

  static bool _isSensitive(String text) {
    final lower = text.toLowerCase();
    for (final kw in _sensitiveKeywords) {
      if (lower.contains(kw)) return true;
    }
    return false;
  }
}
