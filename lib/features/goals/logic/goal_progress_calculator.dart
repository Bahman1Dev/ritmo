import 'package:ritmo/features/goals/models/goal_models.dart';

/// Helper to count the total leaf items under [goalId] for weighting purposes.
/// A leaf is either a direct step or a childless goal with no steps.
int countGoalLeaves(
  String goalId,
  List<Goal> allGoals,
  Map<String, List<GoalStep>> stepsByGoal, [
  Set<String>? visited,
]) {
  final currentVisited = visited ?? <String>{};
  if (currentVisited.contains(goalId)) return 0;
  currentVisited.add(goalId);

  final children = allGoals.where((g) => g.parentGoalId == goalId && g.status != 'ABANDONED').toList();
  final directSteps = stepsByGoal[goalId] ?? [];

  if (children.isEmpty && directSteps.isEmpty) {
    return 1;
  }

  var total = directSteps.length;
  for (final child in children) {
    total += countGoalLeaves(child.id, allGoals, stepsByGoal, Set<String>.from(currentVisited));
  }
  return total > 0 ? total : 1;
}

double goalProgress(
  String goalId,
  List<Goal> allGoals,
  Map<String, List<GoalStep>> stepsByGoal, [
  Set<String>? visited,
]) {
  final currentVisited = visited ?? <String>{};
  if (currentVisited.contains(goalId)) {
    return 0.0;
  }
  currentVisited.add(goalId);

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

  final children = allGoals.where((g) => g.parentGoalId == goalId && g.status != 'ABANDONED').toList();
  final directSteps = stepsByGoal[goalId] ?? [];

  double weightedValueSum = 0.0;
  double totalWeightSum = 0.0;

  // 1. Process non-abandoned sub-goals
  for (final child in children) {
    final childLeaves = countGoalLeaves(child.id, allGoals, stepsByGoal, <String>{goalId});
    final childWeight = (child.weight <= 0 ? 1.0 : child.weight) * (childLeaves > 0 ? childLeaves : 1);
    final childProgressVal = goalProgress(child.id, allGoals, stepsByGoal, Set<String>.from(currentVisited));

    weightedValueSum += childProgressVal * childWeight;
    totalWeightSum += childWeight;
  }

  // 2. Process direct steps of this goal
  if (directSteps.isNotEmpty) {
    final completedCount = directSteps.where((s) => s.isCompleted).length;
    final stepProgressVal = completedCount / directSteps.length;
    final stepWeight = directSteps.length.toDouble();

    weightedValueSum += stepProgressVal * stepWeight;
    totalWeightSum += stepWeight;
  }

  // 3. Childless and stepless goals
  if (totalWeightSum == 0.0) {
    if (self.metricTarget != null && self.metricTarget! > 0) {
      final start = self.metricStart ?? 0.0;
      final target = self.metricTarget!;
      if (target != start) {
        final current = self.progressCache; // or checkin value
        final ratio = (current - start) / (target - start);
        return ratio.clamp(0.0, 1.0);
      }
    }
    return self.status == 'COMPLETED' ? 1.0 : 0.0;
  }

  return (weightedValueSum / totalWeightSum).clamp(0.0, 1.0);
}

