import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/strategies/generic_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/reflection_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/sports_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/worship_strategy.dart';

class PlannerStrategyRegistry {
  PlannerStrategyRegistry._();

  /// Ordered list — first strategy whose [matches] returns true wins.
  static final List<PlannerCategoryStrategy> _strategies = [
    const ReflectionStrategy(), // must come BEFORE GenericStrategy (itemType check)
    const WorshipStrategy(),
    const SportsStrategy(),
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
