import 'package:ritmo/core/domain/engines/context_engine.dart';
import 'package:ritmo/core/domain/models.dart';

class TodaySnapshotState {
  const TodaySnapshotState({
    required this.now,
    required this.todayStr,
    required this.settingsMap,
    required this.completions,
    required this.completionMap,
    required this.completedIds,
    required this.routinesResult,
    required this.schedulesResult,
    required this.activeTasks,
    required this.rhythmScore,
    required this.resolvedEnergy,
    required this.nextTask,
  });

  final DateTime now;
  final String todayStr;
  final Map<String, String> settingsMap;
  final List<Map<String, dynamic>> completions;
  final Map<String, Map<String, dynamic>> completionMap;
  final Set<String> completedIds;
  final List<Map<String, dynamic>> routinesResult;
  final List<Map<String, dynamic>> schedulesResult;
  final List<RoutineTask> activeTasks;
  final int rhythmScore;
  final EnergyLevel resolvedEnergy;
  final RoutineTask? nextTask;
}
