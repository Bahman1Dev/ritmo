import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/sleep_window_resolver.dart';

/// Bundled contextual signals used for deterministic calendar intelligence & suggestion ranking.
class SuggestionSignalBundle {
  const SuggestionSignalBundle({
    required this.items,
    required this.conflicts,
    required this.freeGaps,
    required this.overloadScore,
    this.now,
    this.sleepWindow,
  });

  final List<AgendaItem> items;
  final List<AgendaConflict> conflicts;
  final List<TimeGap> freeGaps;
  final double overloadScore;
  final DateTime? now;
  final SleepWindowBlock? sleepWindow;

  /// Returns total count of completed items.
  int get completedCount => items.where((i) => i.isCompleted).length;

  /// Returns total count of pending items.
  int get pendingCount => items.where((i) => !i.isCompleted).length;

  /// Minute of the current time (0..1439), if [now] is available.
  int? get currentMinutes => now != null ? (now!.hour * 60) + now!.minute : null;
}
