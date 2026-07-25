// lib/features/registry/logic/sources/goal_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';

class GoalRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.goal;

  @override
  String get moduleSettingsKey => 'module_goals_enabled';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final where = includeArchived ? '1=1' : 'isArchived = 0';
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM goals WHERE $where');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<List<RegistryEntry>> fetch({
    required int limit,
    required int offset,
    bool includeArchived = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final where = includeArchived ? '1=1' : 'isArchived = 0';
    final rows = await db.query(
      'goals',
      where: where,
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final entries = <RegistryEntry>[];
    for (final r in rows) {
      final id = r['id'] as String;
      final title = r['title'] as String? ?? '';
      final isArchived = (r['isArchived'] as int? ?? 0) == 1;

      // Count steps
      final stepsRes = await db.rawQuery(
        'SELECT COUNT(*) as total, SUM(CASE WHEN isCompleted = 1 THEN 1 ELSE 0 END) as done FROM goal_steps WHERE goalId = ?',
        [id],
      );
      final totalSteps = Sqflite.firstIntValue(stepsRes) ?? 0;
      final doneSteps = (stepsRes.first['done'] as num?)?.toInt() ?? 0;

      final subtitle = totalSteps > 0 ? '$doneSteps از $totalSteps گام' : 'بدون گام';

      entries.add(RegistryEntry(
        id: 'goal:$id',
        domain: RegistryDomain.goal,
        sourceId: id,
        title: title,
        subtitle: subtitle,
        scheduleSummary: 'بدون زمان‌بندی',
        status: isArchived
            ? RegistryStatus.archived
            : (doneSteps >= totalSteps && totalSteps > 0
                ? RegistryStatus.completed
                : RegistryStatus.active),
        agendaProxy: AgendaItem(
          id: 'goal:$id',
          domain: AgendaDomain.goalStep,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          category: Category.personal,
          deepLink: AgendaDeepLink(domain: AgendaDomain.goalStep, targetId: id),
        ),
      ));
    }

    return entries;
  }
}
