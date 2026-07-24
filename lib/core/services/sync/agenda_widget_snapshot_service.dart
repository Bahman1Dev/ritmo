import 'package:flutter/foundation.dart';
import 'package:ritmo/core/ai/engines/helpers/sensitive_reflection_filter.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/core/utils/snapshot_helper.dart';
import 'package:shamsi_date/shamsi_date.dart';

class AgendaWidgetSnapshotService {
  const AgendaWidgetSnapshotService();

  Future<void> sync({
    required DateTime now,
  }) async {
    try {
      final dayAgenda = await DayAgendaService.instance.agendaForDate(
        now,
        options: const AgendaQueryOptions(),
      );

      // Filter out cycle and sensitive items (Zero-Leak)
      final filteredItems = dayAgenda.items.where((item) {
        if (item.domain == AgendaDomain.cycle) return false;
        
        final categoryStr = item.category.name.toLowerCase();
        if (categoryStr == 'medical' || categoryStr == 'cycle') return false;

        final titleLower = item.title.toLowerCase();
        final subtitleLower = (item.subtitle ?? '').toLowerCase();

        for (final kw in SensitiveReflectionFilter.cycleKeywords) {
          if (titleLower.contains(kw) || subtitleLower.contains(kw)) return false;
        }
        for (final kw in SensitiveReflectionFilter.medicalKeywords) {
          if (titleLower.contains(kw) || subtitleLower.contains(kw)) return false;
        }

        return true;
      }).toList();

      // Sort items: pending first, then completed. Timed first, then untimed.
      filteredItems.sort((a, b) {
        final aComp = a.isCompleted ? 1 : 0;
        final bComp = b.isCompleted ? 1 : 0;
        if (aComp != bComp) return aComp.compareTo(bComp);

        final aTimed = a.isTimed ? 0 : 1;
        final bTimed = b.isTimed ? 0 : 1;
        if (aTimed != bTimed) return aTimed.compareTo(bTimed);

        if (a.isTimed && b.isTimed) {
          return a.timeOfDay!.compareTo(b.timeOfDay!);
        }

        return b.priority.compareTo(a.priority); // Higher priority first
      });

      final jalali = Jalali.now();
      final formattedDate = '${jalali.formatter.wN}، ${toPersianDigits(jalali.day.toString())} ${jalali.formatter.mN}';

      final completedCount = filteredItems.where((i) => i.isCompleted).length;
      final totalCount = filteredItems.length;
      final remainingCount = totalCount - completedCount;
      final remainingText = totalCount == 0 
          ? 'امروز چیزی برنامه‌ریزی نشده'
          : '${toPersianDigits(remainingCount.toString())} از ${toPersianDigits(totalCount.toString())} مانده';

      final itemsData = filteredItems.map((item) {
        return {
          'id': item.id,
          'title': item.title,
          'time': item.timeOfDay != null ? toPersianDigits(item.timeOfDay!) : '',
          'isCompleted': item.isCompleted,
          'routineId': item.domain == AgendaDomain.routine ? item.sourceId : '',
          'dateStr': item.dateStr,
          'domain': item.domain.name,
          'isTickable': item.domain == AgendaDomain.routine,
        };
      }).toList();

      await SnapshotHelper.updateAgendaWidgetSnapshot(
        dateStr: formattedDate,
        remainingText: remainingText,
        items: itemsData,
      );
    } catch (e, st) {
      debugPrint('AgendaWidgetSnapshotService: agenda widget snapshot failed: $e\n$st');
    }
  }
}
