import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/calendar/utils/calendar_defaults.dart';

/// Helper utilities for snapping minutes and duration calculations.
class TimelineSnappingHelper {
  const TimelineSnappingHelper._();

  static const int defaultSnapIntervalMinutes = CalendarDefaults.snapIntervalMinutes;
  static const int minDurationMinutes = CalendarDefaults.minDurationMinutes;

  /// Snaps [rawMinutes] to the nearest [intervalMinutes] (default 15 mins)
  /// and clamps within valid day minutes `[0, 1440 - duration]`.
  static int snapStartMinutes(
    int rawMinutes, {
    int intervalMinutes = defaultSnapIntervalMinutes,
    int durationMinutes = CalendarDefaults.fallbackDurationMinutes,
  }) {
    final interval = intervalMinutes > 0 ? intervalMinutes : CalendarDefaults.snapIntervalMinutes;
    final snapped = (rawMinutes / interval).round() * interval;
    final maxAllowed = (1440 - durationMinutes).clamp(0, 1440);
    return snapped.clamp(0, maxAllowed);
  }

  /// Snaps [rawDurationMinutes] to the nearest [intervalMinutes]
  /// enforcing a minimum duration of [minDurationMinutes] (default 15 mins).
  static int snapDurationMinutes(
    int rawDurationMinutes, {
    int startMinutes = 0,
    int intervalMinutes = defaultSnapIntervalMinutes,
  }) {
    final interval = intervalMinutes > 0 ? intervalMinutes : CalendarDefaults.snapIntervalMinutes;
    final snapped = (rawDurationMinutes / interval).round() * interval;
    final untilEndOfDay = 1440 - startMinutes;
    final maxAllowed = untilEndOfDay.clamp(minDurationMinutes, DurationBounds.maxMinutes);
    return snapped.clamp(minDurationMinutes, maxAllowed);
  }

  /// Converts minute offset of day (0..1439) to 'HH:mm' string format.
  static String minutesToTimeString(int totalMinutes) {
    final clamped = totalMinutes.clamp(0, 1439);
    final hour = clamped ~/ 60;
    final minute = clamped % 60;
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Parses 'HH:mm' string to total minutes of day (0..1439).
  static int parseTimeToMinutes(String timeStr) {
    try {
      final parts = timeStr.trim().split(':');
      if (parts.length != 2) return 0;
      final h = int.parse(parts[0]);
      final m = int.parse(parts[1]);
      return (h * 60) + m;
    } catch (_) {
      return 0;
    }
  }
}
