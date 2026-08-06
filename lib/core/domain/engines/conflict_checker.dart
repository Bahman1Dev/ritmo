import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/features/calendar/logic/timeline_snapping.dart';
import 'package:ritmo/features/calendar/utils/calendar_defaults.dart';

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

      final startMinutes = TimelineSnappingHelper.parseTimeToMinutes(timeStr);
      final dur = durationMinutes <= 0 ? CalendarDefaults.fallbackDurationMinutes : durationMinutes;

      final detector = const AgendaConflictDetector();
      final conflicts = detector.checkCandidate(
        existing: items,
        startMinutes: startMinutes,
        durationMinutes: dur,
        ignoreSourceId: ignoreSourceId,
      );

      return conflicts.map((c) => c.itemA).toList();
    } catch (_) {
      return [];
    }
  }
}
