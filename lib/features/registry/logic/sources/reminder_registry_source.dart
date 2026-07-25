// lib/features/registry/logic/sources/reminder_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';

class ReminderRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.routine;

  @override
  String get moduleSettingsKey => '';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery(
      "SELECT COUNT(*) as cnt FROM pending_reminders WHERE state IN ('unknown','delayed','SCHEDULED')",
    );
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<List<RegistryEntry>> fetch({
    required int limit,
    required int offset,
    bool includeArchived = false,
  }) async {
    final db = await DatabaseHelper.instance.database;

    final rows = await db.rawQuery('''
      SELECT pr.id, pr.routineId, pr.scheduledTime, pr.state, pr.deferCount,
             COALESCE(r.title, 'کلاس: ' || c.title, pr.id) AS title,
             CASE WHEN r.id IS NULL AND cs.id IS NULL THEN 1 ELSE 0 END AS isOrphan
      FROM pending_reminders pr
      LEFT JOIN routines r ON pr.routineId = r.id
      LEFT JOIN course_sessions cs ON pr.courseSessionId = cs.id
      LEFT JOIN courses c ON cs.courseId = c.id
      WHERE pr.state IN ('unknown','delayed','SCHEDULED')
      ORDER BY pr.scheduledTime ASC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    final todayStr = DateTime.now().toIso8601String().split('T').first;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    return rows.map((r) {
      final id = r['id'] as String;
      final routineId = r['routineId'] as String?;
      final isOrphanInt = r['isOrphan'] as int? ?? 0;
      final state = r['state'] as String? ?? 'SCHEDULED';
      final scheduledTime = r['scheduledTime'] as int? ?? 0;

      var title = r['title'] as String? ?? id;
      if (routineId == 'cycle_private_reminder') {
        title = 'یادآور خصوصی';
      }

      ReminderHealth health = ReminderHealth.armed;
      if (isOrphanInt == 1 && routineId != 'cycle_private_reminder') {
        health = ReminderHealth.silent;
      } else if (scheduledTime < nowMs && state == 'unknown') {
        health = ReminderHealth.overdue;
      }

      final date = DateTime.fromMillisecondsSinceEpoch(scheduledTime);
      final timeStr =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      final dateIsoStr = date.toIso8601String().split('T').first;

      return RegistryEntry(
        id: 'reminder:$id',
        domain: RegistryDomain.routine,
        sourceId: id,
        title: title,
        subtitle: 'وضعیت: $state',
        scheduleSummary: '$dateIsoStr · ${toPersianDigits(timeStr)}',
        status: RegistryStatus.active,
        reminderHealth: health,
        agendaProxy: AgendaItem(
          id: 'routine:${routineId ?? id}',
          domain: AgendaDomain.routine,
          sourceId: routineId ?? id,
          title: title,
          dateStr: todayStr,
          timeOfDay: timeStr,
          category: Category.personal,
          deepLink: AgendaDeepLink(domain: AgendaDomain.routine, targetId: routineId ?? id),
        ),
      );
    }).toList();
  }
}
