import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:sqflite/sqflite.dart';

/// AgendaSource for the Medicine domain.
class MedicineAgendaSource {
  MedicineAgendaSource({
    required this.medicineLogsByDate,
    required this.medicineEnabled,
  });

  final Map<String, List<Map<String, dynamic>>> medicineLogsByDate;
  final bool medicineEnabled;

  static Future<MedicineAgendaSource> load(
    Database db,
    Map<String, String> settingsMap,
  ) async {
    final medicineEnabled = settingsMap['module_medicine_enabled'] == 'true';
    if (!medicineEnabled) {
      return MedicineAgendaSource(medicineLogsByDate: const {}, medicineEnabled: false);
    }

    final medicineLogsByDate = <String, List<Map<String, dynamic>>>{};
    try {
      final logs = await db.query('medication_logs');
      for (final l in logs) {
        final dateStr = l['scheduledDate'] as String? ?? l['date'] as String?;
        if (dateStr != null) {
          medicineLogsByDate
              .putIfAbsent(dateStr, () => [])
              .add(Map<String, dynamic>.from(l));
        }
      }
    } catch (e) {
      debugPrint('[MedicineAgendaSource] Load error: $e');
    }

    return MedicineAgendaSource(
      medicineLogsByDate: medicineLogsByDate,
      medicineEnabled: medicineEnabled,
    );
  }

  List<AgendaItem> itemsForDate(String dateStr) {
    if (!medicineEnabled) return const [];

    final logs = medicineLogsByDate[dateStr] ?? const [];
    if (logs.isEmpty) return const [];

    final items = <AgendaItem>[];
    for (final log in logs) {
      final id = log['id']?.toString() ?? 'med_$dateStr';
      final title = log['medicationName'] as String? ?? 'مصرف دارو';
      final timeOfDay = log['scheduledTime'] as String? ?? log['timeOfDay'] as String?;
      final isDone = log['isTaken'] == 1 || log['status'] == 'TAKEN';

      items.add(AgendaItem(
        id: 'medicine_${id}_$dateStr',
        sourceId: id,
        domain: AgendaDomain.medicine,
        type: AgendaItemType.fixed,
        title: title,
        dateStr: dateStr,
        timeOfDay: timeOfDay,
        durationMinutes: 10,
        completion: isDone ? AgendaCompletion.done : AgendaCompletion.pending,
        meta: {'medicationLog': log},
      ));
    }

    return items;
  }
}
