import 'package:ritmo/features/courses/models/course_models.dart';

class CourseScheduler {
  /// Sunday = 0, Monday = 1, ..., Saturday = 6
  static int getFarsiWeekday(DateTime dt) {
    return dt.weekday == 7 ? 0 : dt.weekday;
  }

  /// Saturday is the start of Farsi week
  static DateTime getSaturdayOfWeek(DateTime dt) {
    final w = getFarsiWeekday(dt);
    final daysSinceSaturday = (w == 6) ? 0 : (w + 1);
    final dateOnly = DateTime(dt.year, dt.month, dt.day);
    return dateOnly.subtract(Duration(days: daysSinceSaturday));
  }

  /// Distributes pendingCount session dates starting from 'from'
  /// respecting the weeklyTarget limit per Saturday-to-Friday Farsi week.
  /// If preferredDays is empty, schedules on consecutive days.
  static List<DateTime> distributeSessions({
    required int pendingCount,
    required DateTime from,
    required int weeklyTarget,
    required List<int> preferredDays,
  }) {
    if (pendingCount <= 0) return [];

    final result = <DateTime>[];
    final weekCounts = <DateTime, int>{}; // SaturdayOfWeek -> session count

    var currentDate = DateTime(from.year, from.month, from.day);
    var remaining = pendingCount;

    // Safety counter to prevent infinite loops
    var safetyCounter = 0;

    while (remaining > 0 && safetyCounter < 10000) {
      safetyCounter++;
      final farsiDay = getFarsiWeekday(currentDate);

      // Check if it's a valid preferred day
      final isPreferred = preferredDays.isEmpty || preferredDays.contains(farsiDay);

      if (isPreferred) {
        final satOfWeek = getSaturdayOfWeek(currentDate);
        final currentWeekCount = weekCounts[satOfWeek] ?? 0;

        if (currentWeekCount < weeklyTarget) {
          result.add(currentDate);
          weekCounts[satOfWeek] = currentWeekCount + 1;
          remaining--;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    return result;
  }

  /// Calculates number of PENDING sessions whose plannedDate is before today
  static int daysBehind({
    required List<CourseSession> sessions,
    required DateTime today,
  }) {
    final todayStr = _formatDate(today);
    var count = 0;
    for (final session in sessions) {
      if (session.completionStatus != 'COMPLETED' && session.plannedDate != null) {
        if (session.plannedDate!.compareTo(todayStr) < 0) {
          count++;
        }
      }
    }
    return count;
  }

  /// Estimates the end date using distributeSessions
  static DateTime? estimatedEndDate({
    required int remaining,
    required int weeklyTarget,
    required DateTime from,
    required List<int> preferredDays,
  }) {
    if (remaining <= 0) return null;
    final dates = distributeSessions(
      pendingCount: remaining,
      from: from,
      weeklyTarget: weeklyTarget,
      preferredDays: preferredDays,
    );
    if (dates.isEmpty) return null;
    return dates.last;
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
