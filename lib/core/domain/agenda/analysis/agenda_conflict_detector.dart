import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/features/calendar/presentation/logic/direct_manipulation_eligibility.dart';

enum ConflictType {
  overlap,
  sameStart,
  sameEnd,
  zeroDuration,
  overnight,
}

class AgendaConflict {
  const AgendaConflict({
    required this.itemA,
    required this.itemB,
    required this.type,
    required this.description,
    this.isHardConflict = false,
    this.severity = 0.5,
    this.isResolvable = true,
    this.reason = '',
  });

  final AgendaItem itemA;
  final AgendaItem itemB;
  final ConflictType type;
  final String description;

  /// True if both items are fixed/non-movable constraints (e.g. prayer vs fixed meeting).
  final bool isHardConflict;

  /// Severity score between 0.0 (soft touch) and 1.0 (hard unresolvable overlap).
  final double severity;

  /// True if at least one item is eligible for direct manipulation / rescheduling.
  final bool isResolvable;

  /// Concise human-usable rationale for conflict ranking.
  final String reason;
}

class AgendaConflictDetector {
  const AgendaConflictDetector();

  List<AgendaConflict> detectConflicts(List<AgendaItem> items) {
    final conflicts = <AgendaConflict>[];
    final timedItems = items.where((item) => item.isTimed && !item.isCompleted).toList();

    for (var i = 0; i < timedItems.length; i++) {
      for (var j = i + 1; j < timedItems.length; j++) {
        final itemA = timedItems[i];
        final itemB = timedItems[j];

        final startA = _parseStartMinutes(itemA.timeOfDay!);
        final durationA = (itemA.durationMinutes ?? 0) <= 0 ? 15 : itemA.durationMinutes!;
        final endA = startA + durationA;

        final startB = _parseStartMinutes(itemB.timeOfDay!);
        final durationB = (itemB.durationMinutes ?? 0) <= 0 ? 15 : itemB.durationMinutes!;
        final endB = startB + durationB;

        final isDragA = DirectManipulationEligibility.isDraggable(itemA);
        final isDragB = DirectManipulationEligibility.isDraggable(itemB);
        final isHard = !isDragA && !isDragB;
        final isResolvable = isDragA || isDragB;

        if (startA == startB) {
          final severity = isHard ? 1.0 : 0.85;
          final reason = isHard
              ? 'تداخل دو مورد ثابت در زمان یکسان'
              : 'شروع همزمان؛ امکان انتقال مورد انعطاف‌پذیر وجود دارد';

          conflicts.add(AgendaConflict(
            itemA: itemA,
            itemB: itemB,
            type: ConflictType.sameStart,
            description: '${itemA.title} and ${itemB.title} start at the exact same time (${itemA.timeOfDay}).',
            isHardConflict: isHard,
            severity: severity,
            isResolvable: isResolvable,
            reason: reason,
          ));
        } else if (endA > 0 && endA == endB && durationA > 0 && durationB > 0) {
          final severity = isHard ? 0.8 : 0.5;
          conflicts.add(AgendaConflict(
            itemA: itemA,
            itemB: itemB,
            type: ConflictType.sameEnd,
            description: '${itemA.title} and ${itemB.title} end at the exact same time.',
            isHardConflict: isHard,
            severity: severity,
            isResolvable: isResolvable,
            reason: 'پایان همزمان دو برنامه',
          ));
        } else if (startA < endB && startB < endA) {
          final overlapMins = _calculateOverlap(startA, endA, startB, endB);
          final severity = isHard ? 1.0 : (overlapMins >= 15 ? 0.75 : 0.40);
          final reason = isHard
              ? 'تداخل برنامه‌های غیرقابل جابه‌جایی'
              : 'تداخل زمانی ($overlapMins دقیقه)';

          conflicts.add(AgendaConflict(
            itemA: itemA,
            itemB: itemB,
            type: ConflictType.overlap,
            description: '${itemA.title} overlaps with ${itemB.title}.',
            isHardConflict: isHard,
            severity: severity,
            isResolvable: isResolvable,
            reason: reason,
          ));
        }
      }
    }

    conflicts.sort((a, b) => b.severity.compareTo(a.severity));
    return conflicts;
  }

  static int _calculateOverlap(int sA, int eA, int sB, int eB) {
    final start = sA > sB ? sA : sB;
    final end = eA < eB ? eA : eB;
    return (end - start).clamp(0, 1440);
  }

  static int _parseStartMinutes(String timeOfDay) {
    final parts = timeOfDay.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }
}
