// lib/features/registry/logic/sources/worship_debt_registry_source.dart

import 'package:sqflite/sqflite.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/registry/domain/registry_entry.dart';
import 'package:ritmo/features/registry/logic/sources/registry_source.dart';

class WorshipDebtRegistrySource implements RegistrySource {
  @override
  RegistryDomain get domain => RegistryDomain.worshipDebt;

  @override
  String get moduleSettingsKey => 'module_worship_enabled';

  @override
  Future<int> count({bool includeArchived = false}) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('SELECT COUNT(*) as cnt FROM worship_debts');
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
      'worship_debts',
      orderBy: 'createdAt DESC',
      limit: limit,
      offset: offset,
    );

    final todayStr = DateTime.now().toIso8601String().split('T').first;

    return rows.map((r) {
      final id = r['id'] as String;
      final title = r['title'] as String? ?? 'قضا';
      final remaining = r['remainingCount'] as int? ?? 0;

      return RegistryEntry(
        id: 'worshipDebt:$id',
        domain: RegistryDomain.worshipDebt,
        sourceId: id,
        title: title,
        subtitle: '${toPersianDigits(remaining.toString())} باقی‌مانده',
        scheduleSummary: 'بدون زمان‌بندی',
        status: remaining <= 0 ? RegistryStatus.completed : RegistryStatus.active,
        agendaProxy: AgendaItem(
          id: 'worshipDebt:$id',
          domain: AgendaDomain.worshipDebt,
          sourceId: id,
          title: title,
          dateStr: todayStr,
          category: Category.religious,
          deepLink: AgendaDeepLink(domain: AgendaDomain.worshipDebt, targetId: id),
        ),
      );
    }).toList();
  }
}
