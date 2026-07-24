import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';

class AgendaSuggestion {
  const AgendaSuggestion({
    required this.id,
    required this.message,
    required this.priorityScore,
    this.suggestedTimeOfDay,
    this.targetItemId,
  });

  final String id;
  final String message;
  final double priorityScore;
  final String? suggestedTimeOfDay;
  final String? targetItemId;
}

class AgendaSuggestionRanker {
  const AgendaSuggestionRanker();

  List<AgendaSuggestion> generateSuggestions({
    required List<AgendaItem> items,
    required List<AgendaConflict> conflicts,
    required List<TimeGap> freeGaps,
    required double overloadScore,
  }) {
    final suggestions = <AgendaSuggestion>[];

    if (overloadScore > 1.0) {
      suggestions.add(AgendaSuggestion(
        id: 'overload_warning',
        message: 'Day is overloaded (${(overloadScore * 100).toInt()}% scheduled capacity). Consider skipping optional tasks.',
        priorityScore: 0.95,
      ));
    }

    for (final conflict in conflicts) {
      final flexibleItem = conflict.itemA.isFlexible ? conflict.itemA : (conflict.itemB.isFlexible ? conflict.itemB : null);
      if (flexibleItem != null && freeGaps.isNotEmpty) {
        final targetGap = freeGaps.firstWhere(
          (gap) => gap.durationMinutes >= (flexibleItem.durationMinutes ?? 15),
          orElse: () => freeGaps.first,
        );
        suggestions.add(AgendaSuggestion(
          id: 'resolve_conflict_${conflict.itemA.id}_${conflict.itemB.id}',
          message: 'Move flexible task "${flexibleItem.title}" to free slot at ${targetGap.startTimeStr}.',
          priorityScore: 0.85,
          suggestedTimeOfDay: targetGap.startTimeStr,
          targetItemId: flexibleItem.id,
        ));
      }
    }

    final untimedFlexible = items.where((i) => !i.isTimed && i.isFlexible && !i.isCompleted).toList();
    if (untimedFlexible.isNotEmpty && freeGaps.isNotEmpty) {
      final item = untimedFlexible.first;
      final suitableGap = freeGaps.firstWhere(
        (g) => g.durationMinutes >= (item.durationMinutes ?? 30),
        orElse: () => freeGaps.first,
      );
      suggestions.add(AgendaSuggestion(
        id: 'schedule_untimed_${item.id}',
        message: 'Schedule "${item.title}" into available gap at ${suitableGap.startTimeStr}.',
        priorityScore: 0.65,
        suggestedTimeOfDay: suitableGap.startTimeStr,
        targetItemId: item.id,
      ));
    }

    suggestions.sort((a, b) => b.priorityScore.compareTo(a.priorityScore));
    return suggestions;
  }
}
