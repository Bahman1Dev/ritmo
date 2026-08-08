// lib/features/registry/logic/sources/konkur_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';

class KonkurRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.konkur;

  @override
  String get moduleSettingsKey => 'module_study_enabled';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM konkur_subjects');
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
      'konkur_subjects',
      orderBy: 'name ASC',
      limit: limit,
      offset: offset,
    );

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final entries = <RegistryEntry>[];
    for (final r in rows) {
      final id = r['id'] as String;
      final title = r['name'] as String? ?? '';

      // Count topics
      final topicsRes = await db.rawQuery(
        'SELECT COUNT(*) as cnt FROM konkur_topics WHERE subjectId = ?',
        [id],
      );
      final topicCount = Sqflite.firstIntValue(topicsRes) ?? 0;

      entries.add(RegistryEntry(
        id: 'konkur:$id',
        domain: RegistryDomain.konkur,
        sourceId: id,
        title: title,
        subtitle: topicCount > 0 ? '$topicCount سرفصل' : null,
        scheduleSummary: 'برنامه مطالعه کنکور',
        status: RegistryStatus.active,
        agendaProxy: AgendaItem(
          id: 'konkur:$id',
          domain: AgendaDomain.konkur,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          category: Category.konkur,
          deepLink: AgendaDeepLink(domain: AgendaDomain.konkur, targetId: id),
        ),
      ));
    }

    return entries;
  }
}
