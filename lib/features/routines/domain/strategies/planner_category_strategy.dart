// lib/features/routines/domain/strategies/planner_category_strategy.dart
//
// Abstract interface for Planner Category Strategies.
// Each category (Worship, Sports, Medical, Course, Goal, Reflection, Generic)
// implements this interface to encapsulate its own save logic.
//
// GUARD RAILS:
// - Strategies must NOT import any Flutter Widget classes directly.
// - Strategies must NOT hold references to BuildContext beyond the save() call.
// - All user-visible feedback is done via RitmoToast or RitmoEventBus.
// - Strategies may use: RitmoExecutionKernel, DatabaseHelper, CoursesRepository,
//   GoalsRepository, RitmoEventBus, RitmoToast.

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/domain/models.dart';

/// Abstract interface that all planner category strategies must implement.
abstract interface class PlannerCategoryStrategy {
  /// The primary category this strategy handles.
  Category get category;

  /// Returns true when this strategy applies for the given [category] and
  /// optional [itemType] discriminator (e.g. 'REFLECT' for personal category).
  bool matches(Category category, {String? itemType});

  /// Whether the module backing this strategy is enabled in app settings.
  bool isModuleEnabled(covariant Object controller);

  /// Persists the data captured in [controller] and fires the appropriate
  /// RitmoEventBus event. Throws on failure.
  Future<void> save(covariant Object controller, BuildContext context);
}
