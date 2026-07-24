import 'package:ritmo/features/courses/logic/course_validation.dart';
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

  /// Calculates weekly occupancy map (SaturdayOfWeek -> count) for sessions already scheduled/completed.
  static Map<DateTime, int> weeklyOccupancy({
    required List<CourseSession> sessions,
  }) {
    final map = <DateTime, int>{};
    for (final s in sessions) {
      if (s.plannedDate != null && s.plannedDate!.trim().isNotEmpty) {
        final parts = s.plannedDate!.split('-');
        if (parts.length == 3) {
          final y = int.tryParse(parts[0]);
          final m = int.tryParse(parts[1]);
          final d = int.tryParse(parts[2]);
          if (y != null && m != null && d != null) {
            final dt = DateTime(y, m, d);
            final sat = getSaturdayOfWeek(dt);
            map[sat] = (map[sat] ?? 0) + 1;
          }
        }
      }
    }
    return map;
  }

  /// Distributes pendingCount session dates starting from 'from'
  /// respecting weeklyTarget limit, preferredDays, occupiedWeeklyCounts, and blockedDates.
  static List<DateTime> distributeSessions({
    required int pendingCount,
    required DateTime from,
    required int weeklyTarget,
    required List<int> preferredDays,
    Map<DateTime, int> occupiedWeeklyCounts = const {},
    Set<DateTime> blockedDates = const {},
  }) {
    if (pendingCount <= 0) return [];
    if (weeklyTarget <= 0) {
      throw CourseValidationException('INVALID_WEEKLY_TARGET', 'هدف هفتگی باید حداقل ۱ باشد.');
    }

    final normalizedDays = CourseValidator.normalizePreferredDays(preferredDays);
    final effectiveWeeklyTarget = preferredDays.isNotEmpty
        ? (weeklyTarget > normalizedDays.length ? normalizedDays.length : weeklyTarget)
        : weeklyTarget;

    final result = <DateTime>[];
    final weekCounts = Map<DateTime, int>.from(occupiedWeeklyCounts);

    var currentDate = DateTime(from.year, from.month, from.day);
    var remaining = pendingCount;

    var safetyCounter = 0;
    const maxDaysLimit = 730; // 2 years

    while (remaining > 0 && safetyCounter < maxDaysLimit) {
      safetyCounter++;
      final farsiDay = getFarsiWeekday(currentDate);

      // Check if day is blocked
      final dateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final isBlocked = blockedDates.contains(dateOnly);

      final isPreferred = normalizedDays.contains(farsiDay);

      if (isPreferred && !isBlocked) {
        final satOfWeek = getSaturdayOfWeek(currentDate);
        final currentWeekCount = weekCounts[satOfWeek] ?? 0;

        if (currentWeekCount < effectiveWeeklyTarget) {
          result.add(dateOnly);
          weekCounts[satOfWeek] = currentWeekCount + 1;
          remaining--;
        }
      }

      currentDate = currentDate.add(const Duration(days: 1));
    }

    if (result.length != pendingCount) {
      throw CourseValidationException(
        'SCHEDULE_INCOMPLETE',
        'امکان زمان‌بندی کامل $pendingCount جلسه در بازه زمانی مجاز (۷۳۰ روز) وجود ندارد.',
      );
    }

    return result;
  }

  /// Calculates number of PENDING sessions whose plannedDate is before today
  /// SKIPPED sessions are treated as completed and do NOT count as days behind.
  static int daysBehind({
    required List<CourseSession> sessions,
    required DateTime today,
  }) {
    final todayStr = _formatDate(today);
    var count = 0;
    for (final session in sessions) {
      if (!session.isCompleted && !session.isSkipped && session.plannedDate != null) {
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
    Map<DateTime, int> occupiedWeeklyCounts = const {},
    Set<DateTime> blockedDates = const {},
  }) {
    if (remaining <= 0) return null;
    try {
      final dates = distributeSessions(
        pendingCount: remaining,
        from: from,
        weeklyTarget: weeklyTarget,
        preferredDays: preferredDays,
        occupiedWeeklyCounts: occupiedWeeklyCounts,
        blockedDates: blockedDates,
      );
      if (dates.isEmpty) return null;
      return dates.last;
    } catch (_) {
      return null;
    }
  }

  static String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
