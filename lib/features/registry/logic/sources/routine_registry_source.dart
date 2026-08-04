// lib/features/registry/logic/sources/routine_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';
import 'package:ritmo/features/registry/presentation/utils/schedule_summary_formatter.dart';

class RoutineRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.routine;

  @override
  String get moduleSettingsKey => ''; // Always enabled

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final where = includeArchived
        ? "itemType != 'MEDICINE'"
        : "itemType != 'MEDICINE' AND isArchived = 0";
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM routines WHERE $where');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<List<RegistryEntry>> fetch({
    required int limit,
    required int offset,
    bool includeArchived = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = includeArchived
        ? "r.itemType != 'MEDICINE'"
        : "r.itemType != 'MEDICINE' AND r.isArchived = 0";

    final rows = await db.rawQuery('''
      SELECT r.id, r.title, r.description, r.category, r.isEssential, r.isArchived,
             r.targetDurationMinutes, r.notificationLevel,
             s.timeOfDay, s.daysOfWeek, s.scheduleType
      FROM routines r
      LEFT JOIN routine_schedules s ON r.id = s.routineId
      WHERE $where
      GROUP BY r.id
      ORDER BY r.displayOrder ASC, r.createdAt DESC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    return rows.map((r) {
      final id = r['id'] as String;
      final title = r['title'] as String? ?? '';
      final description = r['description'] as String?;
      final catStr = r['category'] as String? ?? 'personal';
      final category = Category.values.firstWhere(
        (c) => c.name == catStr,
        orElse: () => Category.personal,
      );
      final isEssential = (r['isEssential'] as int? ?? 0) == 1;
      final isArchived = (r['isArchived'] as int? ?? 0) == 1;
      final timeOfDay = r['timeOfDay'] as String?;
      final daysOfWeek = r['daysOfWeek'] as String?;
      final scheduleType = r['scheduleType'] as String?;
      final dur = r['targetDurationMinutes'] as int?;
      final notifLevel = r['notificationLevel'] as String? ?? 'NONE';

      final summary = ScheduleSummaryFormatter.format(
        scheduleType: scheduleType,
        daysOfWeekStr: daysOfWeek,
        timeOfDay: timeOfDay,
      );

      final reminderHealth = notifLevel == 'NONE'
          ? ReminderHealth.off
          : ReminderHealth.armed;

      return RegistryEntry(
        id: 'routine:$id',
        domain: RegistryDomain.routine,
        sourceId: id,
        title: title,
        subtitle: description,
        scheduleSummary: summary,
        status: isArchived ? RegistryStatus.archived : RegistryStatus.active,
        reminderHealth: reminderHealth,
        isEssential: isEssential,
        agendaProxy: AgendaItem(
          id: 'routine:$id',
          domain: AgendaDomain.routine,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          timeOfDay: timeOfDay,
          durationMinutes: dur,
          category: category,
          isEssential: isEssential,
          deepLink: AgendaDeepLink(domain: AgendaDomain.routine, targetId: id),
        ),
      );
    }).toList();
  }
}
