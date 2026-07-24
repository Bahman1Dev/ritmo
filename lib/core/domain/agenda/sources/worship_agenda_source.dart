import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/worship/logic/worship_repository.dart';
import 'package:sqflite/sqflite.dart';

/// AgendaSource for the Worship domain (Prayers and Mustahab practices).
///
/// Encapsulates all domain rules for translating active worship practices
/// and computed prayer times into normalized [AgendaItem]s.
class WorshipAgendaSource {
  WorshipAgendaSource({
    required this.prayers,
    required this.mustahab,
    required this.religionEnabled,
  });

  final List<Map<String, dynamic>> prayers;
  final List<Map<String, dynamic>> mustahab;
  final bool religionEnabled;

  static Future<WorshipAgendaSource> load(
    Database db,
    Map<String, String> settingsMap,
  ) async {
    final religionEnabled = settingsMap['module_religion_enabled'] == 'true';
    if (!religionEnabled) {
      return WorshipAgendaSource(
        prayers: const [],
        mustahab: const [],
        religionEnabled: false,
      );
    }

    final practices = await WorshipRepository.instance.getActivePractices();
    return WorshipAgendaSource(
      prayers: practices.prayers,
      mustahab: practices.mustahab,
      religionEnabled: true,
    );
  }

  Future<List<AgendaItem>> itemsForDate(
    DateTime date,
    String dateStr, {
    required Database db,
    required Map<String, String> settingsMap,
  }) async {
    if (!religionEnabled) return const [];

    final items = <AgendaItem>[];
    try {
      final prayerTimes = await WorshipRepository.instance.getPrayerTimesForDate(
        date,
        settingsMap: settingsMap,
      );

      // 1. Mandatory Prayers
      if (prayerTimes.isNotEmpty) {
        final logs = await db.query(
          'prayer_logs',
          where: 'date = ?',
          whereArgs: [dateStr],
        );
        final statusMap = <String, Map<String, dynamic>>{};
        for (final l in logs) {
          final pKey = l['prayerKey'] as String?;
          if (pKey != null) statusMap[pKey] = l;
        }

        for (final p in prayers) {
          final key = p['prayerKey'] as String? ?? '';
          final time = prayerTimes[key];
          final title = p['customTitle'] as String? ?? key;

          final log = statusMap[key];
          final isDone = log != null && log['isDone'] == 1;

          items.add(AgendaItem(
            id: 'prayer_${key}_$dateStr',
            sourceId: key,
            domain: AgendaDomain.prayer,
            type: AgendaItemType.fixed,
            title: title,
            dateStr: dateStr,
            timeOfDay: time,
            durationMinutes: 15,
            completion: isDone ? AgendaCompletion.done : AgendaCompletion.pending,
            meta: {'prayer': p, 'log': log, 'prayerTimes': prayerTimes},
          ));
        }
      }

      // 2. Mustahab / Quran / Dhikr
      if (mustahab.isNotEmpty) {
        final logs = await db.query(
          'worship_logs',
          where: 'date = ?',
          whereArgs: [dateStr],
        );
        final worshipLogMap = <String, Map<String, dynamic>>{};
        for (final l in logs) {
          final pId = l['practiceId'] as String?;
          if (pId != null) worshipLogMap[pId] = l;
        }

        for (final m in mustahab) {
          final pId = m['id'] as String;
          final title = m['customTitle'] as String? ?? 'Mustahab';
          final preferredTime = m['preferredTime'] as String?;

          final log = worshipLogMap[pId];
          final isDone = log != null && log['isDone'] == 1;

          items.add(AgendaItem(
            id: 'mustahab_${pId}_$dateStr',
            sourceId: pId,
            domain: AgendaDomain.mustahab,
            type: AgendaItemType.optional,
            title: title,
            dateStr: dateStr,
            timeOfDay: preferredTime,
            durationMinutes: 20,
            completion: isDone ? AgendaCompletion.done : AgendaCompletion.pending,
            meta: {'practice': m, 'log': log},
          ));
        }
      }
    } catch (e) {
      debugPrint('[WorshipAgendaSource] itemsForDate error: $e');
    }

    return items;
  }
}
