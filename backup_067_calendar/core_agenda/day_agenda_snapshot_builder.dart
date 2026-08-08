import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_overload_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_suggestion_ranker.dart';
import 'package:ritmo/core/domain/agenda/models/day_agenda_snapshot.dart';
import 'package:ritmo/core/domain/agenda/sleep_window_resolver.dart';

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

  DayAgendaSnapshot buildSnapshot(
    DayAgenda dayAgenda, {
    DateTime? now,
    SleepWindowBlock? sleepWindow,
  }) {
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
    final freeGaps = gapCalculator.calculateFreeGaps(
      items,
      now: currentTime,
      sleepWindow: sleepWindow,
    );
    final overloadScore = overloadDetector.calculateOverloadScore(items);
    final suggestions = suggestionRanker.generateSuggestions(
      items: items,
      conflicts: conflicts,
      freeGaps: freeGaps,
      overloadScore: overloadScore,
      now: currentTime,
      sleepWindow: sleepWindow,
    );

    AgendaItem? current;
    AgendaItem? next;

    final timedItems = items.where((i) => i.isTimed).toList();
    timedItems.sort((a, b) {
      final aM = _parseMinutes(a.timeOfDay);
      final bM = _parseMinutes(b.timeOfDay);
      return aM.compareTo(bM);
    });

    final currentMinutes = (currentTime.hour * 60) + currentTime.minute;

    for (final item in timedItems) {
      final startMinutes = _parseMinutes(item.timeOfDay);
      var duration = item.durationMinutes ?? 30;
      if (duration <= 0) duration = 30;
      final endMinutes = startMinutes + duration;

      if (currentMinutes >= startMinutes && currentMinutes < endMinutes) {
        current ??= item;
      } else if (startMinutes > currentMinutes) {
        if (!item.isCompleted && next == null) {
          next = item;
        }
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
      sleepWindow: sleepWindow,
    );
  }

  static int _parseMinutes(String? timeOfDay) {
    if (timeOfDay == null) return 0;
    final match = RegExp(r'^(\d{1,2}):(\d{2})$').firstMatch(timeOfDay.trim());
    if (match == null) return 0;
    final h = int.tryParse(match.group(1)!) ?? 0;
    final m = int.tryParse(match.group(2)!) ?? 0;
    return (h * 60) + m;
  }
}
