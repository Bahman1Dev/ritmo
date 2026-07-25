import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';
import 'package:ritmo/features/registry/presentation/utils/schedule_summary_formatter.dart';

class CourseRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.course;

  @override
  String get moduleSettingsKey => 'module_courses_enabled';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM courses');
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
      'courses',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    final entries = <RegistryEntry>[];
    for (final r in rows) {
      final id = r['id'] as String;
      final title = r['title'] as String? ?? '';
      final instructor = r['instructor'] as String?;
      final prefTime = r['preferredTime'] as String?;
      final sessionDur = r['sessionDurationMinutes'] as int?;
      final totalSessions = r['totalSessions'] as int? ?? 0;

      // Count completed sessions
      final doneRes = await db.rawQuery(
        "SELECT COUNT(*) as cnt FROM course_sessions WHERE courseId = ? AND isCompleted = 1",
        [id],
      );
      final doneCount = Sqflite.firstIntValue(doneRes) ?? 0;

      final summary = ScheduleSummaryFormatter.format(timeOfDay: prefTime);
      final subtitle = instructor != null && instructor.isNotEmpty
          ? '$instructor · $doneCount از $totalSessions جلسه'
          : '$doneCount از $totalSessions جلسه';

      entries.add(RegistryEntry(
        id: 'course:$id',
        domain: RegistryDomain.course,
        sourceId: id,
        title: title,
        subtitle: subtitle,
        scheduleSummary: summary,
        status: doneCount >= totalSessions && totalSessions > 0
            ? RegistryStatus.completed
            : RegistryStatus.active,
        agendaProxy: AgendaItem(
          id: 'course:$id',
          domain: AgendaDomain.course,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          timeOfDay: prefTime,
          durationMinutes: sessionDur,
          category: Category.learning,
          deepLink: AgendaDeepLink(domain: AgendaDomain.course, targetId: id),
        ),
      ));
    }

    return entries;
  }
}
