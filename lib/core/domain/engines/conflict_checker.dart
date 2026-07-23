import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';

class ConflictChecker {
  static Future<List<AgendaItem>> checkConflicts({
    required String timeStr,
    required int durationMinutes,
    required String dateStr,
    String? ignoreSourceId,
  }) async {
    if (timeStr.isEmpty || !timeStr.contains(':')) {
      return [];
    }

    try {
      final dateParts = dateStr.split('-');
      final y = int.parse(dateParts[0]);
      final m = int.parse(dateParts[1]);
      final d = int.parse(dateParts[2]);
      final targetDate = DateTime(y, m, d);

      final dayAgenda = await DayAgendaService.instance.agendaForDate(targetDate);
      final items = dayAgenda.items;

      final newStart = _timeToMinutes(timeStr);
      final newDur = durationMinutes <= 0 ? 30 : durationMinutes;
      final newEnd = newStart + newDur;

      final conflicts = <AgendaItem>[];

      for (final item in items) {
        if (item.timeOfDay == null || !item.timeOfDay!.contains(':')) {
          continue;
        }

        // Ignore self
        if (ignoreSourceId != null && 
            (item.sourceId == ignoreSourceId || item.id == ignoreSourceId || item.id == 'routine:$ignoreSourceId')) {
          continue;
        }

        final start = _timeToMinutes(item.timeOfDay!);
        final dur = (item.durationMinutes == null || item.durationMinutes! <= 0) ? 30 : item.durationMinutes!;
        final end = start + dur;

        // Check overlap
        if (newStart < end && newEnd > start) {
          conflicts.add(item);
        }
      }

      return conflicts;
    } catch (_) {
      return [];
    }
  }

  static int _timeToMinutes(String hhmm) {
    try {
      final parts = hhmm.split(':');
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return h * 60 + m;
    } catch (_) {
      return 0;
    }
  }
}
