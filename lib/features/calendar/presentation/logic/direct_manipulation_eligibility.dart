import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/calendar/logic/timeline_snapping.dart';

export 'package:ritmo/features/calendar/logic/timeline_snapping.dart';

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
      case AgendaDomain.task:
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

  /// آیا این آیتمِ بدون زمان را می‌توان روی تایم‌لاین نشاند؟
  static bool isSchedulable(AgendaItem item) {
    if (item.isTimed) return false;
    switch (item.domain) {
      case AgendaDomain.cycle:
      case AgendaDomain.worshipDebt:
      case AgendaDomain.prayer:
        return false; // زمان نماز از پنجرهٔ شرعی می‌آید، دستی تعیین نمی‌شود
      default:
        return true;
    }
  }

  /// آیا این آیتمِ زمان‌دار را می‌توان از زمان‌بندی خارج کرد؟
  static bool isUnschedulable(AgendaItem item) =>
      item.isTimed && isDraggable(item) && !item.isFixed;
}
