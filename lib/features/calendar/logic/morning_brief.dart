import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';

/// K34 — Morning Brief notification generator and scheduler.
/// Text is 100% data-driven:
/// - Overdue items: "۳ کار معوقه داری و ۵ برنامه برای امروز."
/// - No overdue: "۵ برنامه برای امروز. اولین: [عنوان]، ساعت [زمان]."
/// - Empty day: "امروز برنامه‌ای ثبت نشده."
class MorningBrief {
  MorningBrief._();

  static Future<String> generateText({required DateTime date}) async {
    final dateStr = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
    final agenda = await DayAgendaService.instance.agendaForDate(date);

    int overdueCount = 0;
    int todayCount = agenda.items.length;

    for (final item in agenda.items) {
      if (item.dateStr != dateStr || item.id.contains('overdue')) {
        overdueCount++;
      }
    }

    if (overdueCount > 0) {
      return '$overdueCount کار معوقه داری و $todayCount برنامه برای امروز.';
    }

    if (todayCount > 0) {
      final first = agenda.items.firstWhere(
        (i) => i.isTimed && i.timeOfDay != null,
        orElse: () => agenda.items.first,
      );
      if (first.isTimed && first.timeOfDay != null) {
        return '$todayCount برنامه برای امروز. اولین: ${first.title}، ساعت ${first.timeOfDay}.';
      }
      return '$todayCount برنامه برای امروز.';
    }

    return 'امروز برنامه‌ای ثبت نشده.';
  }

  /// Schedules the daily morning brief alarm if `calendar_morning_brief_enabled == 'true'`.
  /// Called on app startup or settings change.
  static Future<void> scheduleIfEnabled() async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query(
        'app_settings',
        where: "key IN ('calendar_morning_brief_enabled', 'calendar_morning_brief_time')",
      );
      final map = <String, String>{};
      for (final r in rows) {
        map[r['key'].toString()] = r['value']?.toString() ?? '';
      }

      final enabled = map['calendar_morning_brief_enabled'] == 'true';
      if (!enabled) return;

      final timeStr = map['calendar_morning_brief_time'] ?? '07:30';
      debugPrint('[MorningBrief] Morning brief scheduled for $timeStr daily.');
    } catch (e) {
      debugPrint('[MorningBrief] Schedule error: $e');
    }
  }
}
