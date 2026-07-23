// lib/features/routines/domain/strategies/goal_strategy.dart

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';

class GoalStrategy implements PlannerCategoryStrategy {
  const GoalStrategy();

  @override
  Category get category => Category.custom;

  @override
  bool matches(Category category, {String? itemType}) => category == Category.custom;

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;

    final parsedSteps = c.goalSteps
        .where((s) => s.trim().isNotEmpty)
        .map((s) => {
              'title': s.trim(),
              'scheduledDate': c.formatDate(c.selectedDate),
              'linkedRoutineId': null,
            })
        .toList();

    await GoalsRepository.instance.saveGoal(
      title: c.title,
      description: c.description.isNotEmpty ? c.description : null,
      goalType: c.goalType,
      parentGoalId: null,
      targetDate: c.formatDate(c.goalTargetDate),
      steps: parsedSteps,
    );
    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: const {},
    ));
  }
}
