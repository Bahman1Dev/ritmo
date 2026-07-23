import 'package:ritmo/features/goals/models/goal_models.dart';

double goalProgress(
  String goalId,
  List<Goal> allGoals,
  Map<String, List<GoalStep>> stepsByGoal, [
  Set<String>? visited,
]) {
  final currentVisited = visited ?? <String>{};
  if (currentVisited.contains(goalId)) {
    return 0; // Loop prevention
  }
  currentVisited.add(goalId);

  // Check if this goal has children
  final children = allGoals.where((g) => g.parentGoalId == goalId).toList();

  if (children.isNotEmpty) {
    // Parent goal: average of children's progress
    var sum = 0.0;
    for (final child in children) {
      sum += goalProgress(child.id, allGoals, stepsByGoal, Set<String>.from(currentVisited));
    }
    return sum / children.length;
  } else {
    // Childless goal: completedSteps / totalSteps
    final steps = stepsByGoal[goalId] ?? [];
    if (steps.isEmpty) {
      final self = allGoals.firstWhere(
        (g) => g.id == goalId,
        orElse: () => Goal(
          id: goalId,
          title: '',
          goalType: GoalLevel.daily,
          createdAt: 0,
          updatedAt: 0,
        ),
      );
      return self.status == 'COMPLETED' ? 1.0 : 0.0;
    }
    final completedCount = steps.where((s) => s.isCompleted).length;
    return completedCount / steps.length;
  }
}
