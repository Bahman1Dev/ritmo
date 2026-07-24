import 'package:ritmo/core/domain/agenda/agenda_item.dart';

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
  });

  final AgendaItem itemA;
  final AgendaItem itemB;
  final ConflictType type;
  final String description;
}

class AgendaConflictDetector {
  const AgendaConflictDetector();

  List<AgendaConflict> detectConflicts(List<AgendaItem> items) {
    final conflicts = <AgendaConflict>[];
    final timedItems = items.where((item) => item.isTimed).toList();

    for (var i = 0; i < timedItems.length; i++) {
      for (var j = i + 1; j < timedItems.length; j++) {
        final itemA = timedItems[i];
        final itemB = timedItems[j];

        final startA = _parseStartMinutes(itemA.timeOfDay!);
        final durationA = itemA.durationMinutes ?? 0;
        final endA = startA + durationA;

        final startB = _parseStartMinutes(itemB.timeOfDay!);
        final durationB = itemB.durationMinutes ?? 0;
        final endB = startB + durationB;

        if (startA == startB) {
          conflicts.add(AgendaConflict(
            itemA: itemA,
            itemB: itemB,
            type: ConflictType.sameStart,
            description: '${itemA.title} and ${itemB.title} start at the exact same time (${itemA.timeOfDay}).',
          ));
        } else if (endA > 0 && endA == endB && durationA > 0 && durationB > 0) {
          conflicts.add(AgendaConflict(
            itemA: itemA,
            itemB: itemB,
            type: ConflictType.sameEnd,
            description: '${itemA.title} and ${itemB.title} end at the exact same time.',
          ));
        } else if (startA < endB && startB < endA) {
          conflicts.add(AgendaConflict(
            itemA: itemA,
            itemB: itemB,
            type: ConflictType.overlap,
            description: '${itemA.title} overlaps with ${itemB.title}.',
          ));
        }
      }
    }

    return conflicts;
  }

  static int _parseStartMinutes(String timeOfDay) {
    final parts = timeOfDay.split(':');
    if (parts.length != 2) return 0;
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts[1]) ?? 0;
    return (h * 60) + m;
  }
}
