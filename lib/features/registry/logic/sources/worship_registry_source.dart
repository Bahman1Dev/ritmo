// lib/features/registry/logic/sources/worship_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';
import 'package:ritmo/features/registry/presentation/utils/schedule_summary_formatter.dart';

class WorshipRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.worship;

  @override
  String get moduleSettingsKey => 'module_worship_enabled';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM worship_practices');
    return Sqflite.firstIntValue(res) ?? 0;
  }

  @override
  Future<List<RegistryEntry>> fetch({
    required int limit,
    required int offset,
    bool includeArchived = false,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query(
      'worship_practices',
      orderBy: 'displayOrder ASC',
      limit: limit,
      offset: offset,
    );

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    return rows.map((r) {
      final id = r['id'] as String;
      final title = r['title'] as String? ?? '';
      final type = r['practiceType'] as String? ?? 'OBLIGATORY';
      final isSystem = type == 'OBLIGATORY' || id.startsWith('worship_default_');

      final reminderTime = r['reminderTime'] as String?;
      final reminderDays = r['reminderDaysOfWeek'] as String?;
      final summary = ScheduleSummaryFormatter.format(
        daysOfWeekStr: reminderDays,
        timeOfDay: reminderTime,
      );

      final caps = isSystem
          ? const RegistryCapabilities.systemGenerated()
          : const RegistryCapabilities();

      return RegistryEntry(
        id: 'worship:$id',
        domain: RegistryDomain.worship,
        sourceId: id,
        title: title,
        subtitle: type == 'OBLIGATORY' ? 'نماز واجب' : 'مستحب',
        scheduleSummary: summary,
        status: RegistryStatus.active,
        isEssential: type == 'OBLIGATORY',
        caps: caps,
        agendaProxy: AgendaItem(
          id: 'worship_$id',
          domain: type == 'PRAYER' ? AgendaDomain.prayer : AgendaDomain.mustahab,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          timeOfDay: reminderTime,
          category: Category.religious,
          isEssential: type == 'OBLIGATORY',
          deepLink: AgendaDeepLink(domain: AgendaDomain.prayer, targetId: id),
        ),
      );
    }).toList();
  }
}
