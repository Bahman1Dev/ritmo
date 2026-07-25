// lib/features/routines/domain/strategies/generic_strategy.dart

import 'dart:convert';

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';

/// Handles: personal (non-reflect), free, work, konkur, and fitness ROUTINE type.
/// Also used as the fallback for any unknown category.
class GenericStrategy implements PlannerCategoryStrategy {
  const GenericStrategy();

  @override
  Category get category => Category.personal;

  @override
  bool matches(Category category, {String? itemType}) {
    // Matches any category that no other strategy claims
    // (personal without REFLECT, free, work, konkur)
    return true;
  }

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;
    final now = DateTime.now().millisecondsSinceEpoch;
    final routineId = c.isEditing
        ? c.routineToEdit!['id'] as String
        : 'routine_$now';

    final routineData = {
      'id': routineId,
      'title': c.title,
      'description': c.description.isNotEmpty ? c.description : null,
      'category': c.selectedCategory.name,
      'customCategoryId': null,
      'zoneId': c.selectedZoneId,
      'routineType': c.itemType == 'ROUTINE'
          ? RoutineType.timeBased.name
          : RoutineType.asNeeded.name,
      'notificationLevel': NotificationLevel.normal.name,
      'isEssential': 0,
      'isEssentialLocked': 0,
      'energyRule': c.energyRule,
      'priority': c.priority,
      'targetDurationMinutes': DurationBounds.sanitize(c.targetDuration),
      'lightDurationMinutes': 0,
      'minimalDurationMinutes': 0,
      'isArchived': 0,
      'isPrivate': 0,
      'displayOrder': 1,
      'createdAt': c.isEditing ? c.routineToEdit!['createdAt'] ?? now : now,
      'updatedAt': now,
      'dependsOnRoutineId': c.dependsOnRoutineId,
      'itemType': c.itemType,
      'reminderOffsetMinutes': c.reminderOffsetMinutes,
    };

    final timeStr = c.formatTime(c.selectedTime);
    final scheduleData = {
      'id': 'sched_$routineId',
      'routineId': routineId,
      'scheduleType': c.itemType == 'TASK'
          ? 'DAILY'
          : (c.recurrenceType == 'CUSTOM_DAYS' ? 'SPECIFIC_DAYS' : 'RECURRENCE'),
      'timeOfDay': timeStr,
      'daysOfWeek': '6,7,1,2,3,4,5',
      'recurrenceRule': jsonEncode({
        'weekdays': [1, 2, 3, 4, 5, 6, 7],
        'startDate': c.formatDate(c.selectedDate),
      }),
      'createdAt': c.isEditing ? c.routineToEdit!['createdAt'] ?? now : now,
      'updatedAt': now,
    };

    if (c.isEditing) {
      await RitmoExecutionKernel.instance.execute(
        EditRoutineCommand(
          routineId: routineId,
          routineData: routineData,
          scheduleData: scheduleData,
          applyToAll: true,
        ),
      );
    } else {
      await RitmoExecutionKernel.instance.execute(
        CreateRoutineCommand(
          routineData: routineData,
          scheduleData: scheduleData,
        ),
      );
    }
    RitmoEventBus().fire(RitmoEvent(
      type: 'RoutineChanged',
      timestamp: DateTime.now(),
      payload: const {},
    ));
  }
}
