// lib/features/routines/domain/strategies/sports_strategy.dart

import 'dart:convert';

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/routines/domain/routine_recurrence.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';
import 'package:ritmo/features/supplementary_sports/movement/presentation/movement_log_sheet.dart';

class SportsStrategy implements PlannerCategoryStrategy {
  const SportsStrategy();

  @override
  Category get category => Category.fitness;

  @override
  bool matches(Category category, {String? itemType}) => category == Category.fitness;

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;
    final now = DateTime.now().millisecondsSinceEpoch;

    // --- Case A: LOG mode ---
    if (c.sportsOpType == 'LOG') {
      await showMovementLogSheet(context);
      return;
    }

    // --- Case B: ROUTINE / MEETUP mode (Use Kernel Command) ---
    final routineId = c.isEditing
        ? c.routineToEdit!['id'] as String
        : RitmoIdFactory.routine();
    final timeStr = c.formatTime(c.selectedTime);

    final routineData = {
      'id': routineId,
      'title': c.title,
      'description': c.description.isNotEmpty ? c.description : null,
      'category': Category.fitness.name,
      'customCategoryId': null,
      'zoneId': c.selectedZoneId,
      'routineType': RoutineType.timeBased.name,
      'notificationLevel': NotificationLevel.normal.name,
      'isEssential': 0,
      'isEssentialLocked': 0,
      'energyRule': 'NONE',
      'priority': 1.0,
      'targetDurationMinutes': c.sportsDuration > 0 ? c.sportsDuration : 30,
      'lightDurationMinutes': 0,
      'minimalDurationMinutes': 0,
      'isArchived': 0,
      'isPrivate': 0,
      'displayOrder': 1,
      'createdAt': c.isEditing ? c.routineToEdit!['createdAt'] ?? now : now,
      'updatedAt': now,
      'dependsOnRoutineId': null,
      'itemType': 'ROUTINE',
      'reminderOffsetMinutes': 15,
    };

    final (schedType, daysOfWeek) = deriveScheduleParams(const DailyRecurrence());
    final recurrenceJson = encodeRecurrenceRule(
      recurrence: const DailyRecurrence(),
      startDate: c.selectedDate,
      reminderTimes: [timeStr],
    );

    final scheduleData = {
      'id': RitmoIdFactory.schedule(routineId),
      'routineId': routineId,
      'scheduleType': schedType,
      'timeOfDay': timeStr,
      'daysOfWeek': daysOfWeek,
      'recurrenceRule': recurrenceJson,
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
  }
}
