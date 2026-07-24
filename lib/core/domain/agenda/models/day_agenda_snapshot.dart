import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_conflict_detector.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_gap_calculator.dart';
import 'package:ritmo/core/domain/agenda/analysis/agenda_suggestion_ranker.dart';

class DayAgendaSnapshot {
  const DayAgendaSnapshot({
    required this.dayAgenda,
    required this.completedCount,
    required this.remainingCount,
    required this.freeGaps,
    required this.conflicts,
    required this.overloadScore,
    this.currentActivity,
    this.nextActivity,
    required this.suggestions,
  });

  final DayAgenda dayAgenda;
  final int completedCount;
  final int remainingCount;
  final List<TimeGap> freeGaps;
  final List<AgendaConflict> conflicts;
  final double overloadScore;
  final AgendaItem? currentActivity;
  final AgendaItem? nextActivity;
  final List<AgendaSuggestion> suggestions;

  String get dateStr => dayAgenda.dateStr;
  List<AgendaItem> get items => dayAgenda.items;
  int get rhythmScore => dayAgenda.rhythmScore;
}
