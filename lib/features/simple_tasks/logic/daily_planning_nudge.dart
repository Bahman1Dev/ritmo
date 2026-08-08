import 'package:flutter/foundation.dart';
import 'package:ritmo/core/di/service_locator.dart';
import 'package:ritmo/core/platform/alarm_platform.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';
import 'package:ritmo/core/utils/persian_digits.dart';
import 'package:ritmo/features/simple_tasks/data/simple_task_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DailyPlanningNudge {
  static const String reminderId = 'daily_planning_nudge';

  static Future<void> syncNudgeSchedule() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final enabled = prefs.getString('daily_planning_nudge_enabled') == 'true';
      final timeStr = prefs.getString('daily_planning_nudge_time') ?? '08:30';

      // Always cancel existing alarm first
      try {
        await sl<AlarmPlatform>().cancelAlarm(reminderId);
      } catch (_) {}

      if (!enabled) return;

      final parts = timeStr.split(':');
      if (parts.length != 2) return;
      final hour = int.tryParse(parts[0]) ?? 8;
      final minute = int.tryParse(parts[1]) ?? 30;

      final now = DateTime.now();
      var scheduledTime = DateTime(now.year, now.month, now.day, hour, minute);
      if (scheduledTime.isBefore(now)) {
        scheduledTime = scheduledTime.add(const Duration(days: 1));
      }

      final todayIso = DayKey.from(now).value;
      final overdueTasks = await SimpleTaskRepository.instance.today(todayIso);
      final activeOverdueCount = overdueTasks.where((t) => t.dueDate != null && t.dueDate!.compareTo(todayIso) < 0).length;
      final activeTodayCount = overdueTasks.where((t) => t.dueDate == todayIso).length;

      String message;
      if (activeOverdueCount > 0) {
        message = '${PersianDigits.toPersian(activeOverdueCount)} کار از روزهای قبل مانده. الان تعیین تکلیفشان کن.';
      } else if (activeTodayCount > 0) {
        message = '${PersianDigits.toPersian(activeTodayCount)} کار برای امروز داری.';
      } else {
        message = 'امروز چه کاری داری؟';
      }

      await SimpleTaskRepository.instance.addPendingReminder(
        reminderId: reminderId,
        title: 'برنامه‌ریزی روزانه 📋',
        body: message,
        scheduledTimeMs: scheduledTime.millisecondsSinceEpoch,
        taskId: 'nudge',
      );
    } catch (e) {
      debugPrint('[DailyPlanningNudge] Error syncing schedule: $e');
    }
  }
}
