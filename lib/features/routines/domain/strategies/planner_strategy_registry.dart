// lib/features/routines/domain/strategies/planner_strategy_registry.dart
//
// Maps each planner category to its concrete strategy.
// The registry is the single source of truth for which strategy handles what.

import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/strategies/course_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/generic_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/goal_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/medical_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/reflection_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/sports_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/worship_strategy.dart';

class PlannerStrategyRegistry {
  PlannerStrategyRegistry._();

  /// Ordered list — first strategy whose [matches] returns true wins.
  static final List<PlannerCategoryStrategy> _strategies = [
    const WorshipStrategy(),
    const SportsStrategy(),
    const MedicalStrategy(),
    const CourseStrategy(),
    const GoalStrategy(),
    const ReflectionStrategy(), // must come BEFORE GenericStrategy (itemType check)
    const GenericStrategy(),    // fallback — always matches
  ];

  /// Returns the first strategy that claims the [category] / [itemType] pair.
  /// Never returns null because [GenericStrategy] is the final fallback.
  static PlannerCategoryStrategy resolve(Category category, {String? itemType}) {
    return _strategies.firstWhere(
      (s) => s.matches(category, itemType: itemType),
    );
  }
}
