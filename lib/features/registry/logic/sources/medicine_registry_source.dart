// lib/features/registry/logic/sources/medicine_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';
import 'package:ritmo/features/registry/presentation/utils/schedule_summary_formatter.dart';

class MedicineRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.medicine;

  @override
  String get moduleSettingsKey => 'module_health_enabled';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final where = includeArchived
        ? "itemType = 'MEDICINE'"
        : "itemType = 'MEDICINE' AND isArchived = 0";
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
        ? "r.itemType = 'MEDICINE'"
        : "r.itemType = 'MEDICINE' AND r.isArchived = 0";

    final rows = await db.rawQuery('''
      SELECT r.id, r.title, r.description, r.isArchived, r.medStockCount, r.medRefillThreshold,
             s.timeOfDay, s.daysOfWeek, s.scheduleType
      FROM routines r
      LEFT JOIN routine_schedules s ON r.id = s.routineId
      WHERE $where
      ORDER BY r.createdAt DESC
      LIMIT ? OFFSET ?
    ''', [limit, offset]);

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    return rows.map((r) {
      final id = r['id'] as String;
      final title = r['title'] as String? ?? '';
      final description = r['description'] as String?;
      final isArchived = (r['isArchived'] as int? ?? 0) == 1;
      final stock = r['medStockCount'] as int? ?? 0;
      final threshold = r['medRefillThreshold'] as int? ?? 0;
      final timeOfDay = r['timeOfDay'] as String?;
      final daysOfWeek = r['daysOfWeek'] as String?;
      final scheduleType = r['scheduleType'] as String?;

      final summary = ScheduleSummaryFormatter.format(
        scheduleType: scheduleType,
        daysOfWeekStr: daysOfWeek,
        timeOfDay: timeOfDay,
      );

      var sub = description;
      if (stock > 0 && stock <= threshold) {
        sub = '⚠️ موجودی کم: ${toPersianDigits(stock.toString())} عدد باقی مانده';
      }

      return RegistryEntry(
        id: 'medicine:$id',
        domain: RegistryDomain.medicine,
        sourceId: id,
        title: title,
        subtitle: sub,
        scheduleSummary: summary,
        status: isArchived ? RegistryStatus.archived : RegistryStatus.active,
        reminderHealth: ReminderHealth.armed,
        isEssential: true,
        agendaProxy: AgendaItem(
          id: 'medicine:$id',
          domain: AgendaDomain.medicine,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          timeOfDay: timeOfDay,
          category: Category.medical,
          isEssential: true,
          deepLink: AgendaDeepLink(domain: AgendaDomain.medicine, targetId: id),
        ),
      );
    }).toList();
  }
}
