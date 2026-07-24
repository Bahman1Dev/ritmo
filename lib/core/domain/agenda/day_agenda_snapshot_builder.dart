import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_overload_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_suggestion_ranker.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';

class DayAgendaSnapshotBuilder {
  const DayAgendaSnapshotBuilder({
    this.conflictDetector = const AgendaConflictDetector(),
    this.gapCalculator = const AgendaGapCalculator(),
    this.overloadDetector = const AgendaOverloadDetector(),
    this.suggestionRanker = const AgendaSuggestionRanker(),
  });

  final AgendaConflictDetector conflictDetector;
  final AgendaGapCalculator gapCalculator;
  final AgendaOverloadDetector overloadDetector;
  final AgendaSuggestionRanker suggestionRanker;

  DayAgendaSnapshot buildSnapshot(DayAgenda dayAgenda, {DateTime? now}) {
    final currentTime = now ?? DateTime.now();
    final items = dayAgenda.items;

    var completed = 0;
    var remaining = 0;

    for (final item in items) {
      if (item.isCompleted) {
        completed++;
      } else {
        remaining++;
      }
    }

    final conflicts = conflictDetector.detectConflicts(items);
    final freeGaps = gapCalculator.calculateFreeGaps(items);
    final overloadScore = overloadDetector.calculateOverloadScore(items);
    final suggestions = suggestionRanker.generateSuggestions(
      items: items,
      conflicts: conflicts,
      freeGaps: freeGaps,
      overloadScore: overloadScore,
    );

    AgendaItem? current;
    AgendaItem? next;

    final timedItems = items.where((i) => i.isTimed).toList();
    final currentMinutes = (currentTime.hour * 60) + currentTime.minute;

    for (final item in timedItems) {
      final parts = item.timeOfDay!.split(':');
      if (parts.length != 2) continue;
      final startH = int.tryParse(parts[0]) ?? 0;
      final startM = int.tryParse(parts[1]) ?? 0;
      final startMinutes = (startH * 60) + startM;
      final duration = item.durationMinutes ?? 30;
      final endMinutes = startMinutes + duration;

      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        current = item;
      } else if (startMinutes > currentMinutes) {
        next ??= item;
      }
    }

    return DayAgendaSnapshot(
      dayAgenda: dayAgenda,
      completedCount: completed,
      remainingCount: remaining,
      freeGaps: freeGaps,
      conflicts: conflicts,
      overloadScore: overloadScore,
      currentActivity: current,
      nextActivity: next,
      suggestions: suggestions,
    );
  }
}
