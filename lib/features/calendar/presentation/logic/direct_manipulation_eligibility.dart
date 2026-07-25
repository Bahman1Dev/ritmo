import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';

/// Centralized eligibility rules for timeline direct manipulation (drag & resize).
class DirectManipulationEligibility {
  const DirectManipulationEligibility._();

  /// Returns true if [item] is eligible to be moved (dragged) on the timeline grid.
  static bool isDraggable(AgendaItem item) {
    // Must be a timed item (not all-day)
    if (!item.isTimed) return false;

    // Fixed items (like prayers, fixed Shari'ah anchors) cannot be moved
    if (item.isFixed && item.domain == AgendaDomain.prayer) return false;
    if (item.domain == AgendaDomain.cycle || item.domain == AgendaDomain.worshipDebt) return false;

    // Supported domains with safe time mutation paths
    switch (item.domain) {
      case AgendaDomain.routine:
      case AgendaDomain.course:
      case AgendaDomain.sport:
      case AgendaDomain.goalStep:
      case AgendaDomain.konkur:
        return true;
      case AgendaDomain.mustahab:
        return item.itemType == AgendaItemType.flexible || item.itemType == AgendaItemType.floating;
      default:
        return false;
    }
  }

  /// Returns true if [item] is eligible to have its duration resized on the timeline grid.
  static bool isResizable(AgendaItem item) {
    if (!isDraggable(item)) return false;

    // Resizable domains with duration support
    switch (item.domain) {
      case AgendaDomain.routine:
      case AgendaDomain.course:
      case AgendaDomain.sport:
      case AgendaDomain.konkur:
        return true;
      default:
        return false;
    }
  }
}

/// Helper utilities for snapping minutes and duration calculations.
class TimelineSnappingHelper {
  const TimelineSnappingHelper._();

  static const int defaultSnapIntervalMinutes = 15;
  static const int minDurationMinutes = 15;

  /// Snaps [rawMinutes] to the nearest [intervalMinutes] (default 15 mins)
  /// and clamps within valid day minutes `[0, 1440 - duration]`.
  static int snapStartMinutes(
    int rawMinutes, {
    int intervalMinutes = defaultSnapIntervalMinutes,
    int durationMinutes = 30,
  }) {
    final interval = intervalMinutes > 0 ? intervalMinutes : 15;
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
    final interval = intervalMinutes > 0 ? intervalMinutes : 15;
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
