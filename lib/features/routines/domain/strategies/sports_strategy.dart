// lib/features/routines/domain/strategies/sports_strategy.dart

import 'dart:convert';

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';

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

    if (c.sportsOpType == 'LOG') {
      // --- Log a completed workout ---
      final db = await DatabaseHelper.instance.database;
      await db.insert('workout_logs', {
        'id': 'workout_manual_$now',
        'type': c.sportsType.toUpperCase(),
        'durationMinutes': c.sportsDuration,
        'intensity': c.sportsIntensity.toUpperCase(),
        'note': c.notes.isNotEmpty ? c.notes : null,
        'loggedAt': now,
        'tier': 'FULL',
        'muscleGroups': '',
        'feeling': c.sportsFeeling,
        'location': c.sportsLocation,
      });
      RitmoEventBus().fire(RitmoEvent(
        type: 'WorkoutLogChanged',
        timestamp: DateTime.now(),
        payload: const {},
      ));
    } else {
      // --- Create a recurring workout routine ---
      final routineId = c.isEditing
          ? c.routineToEdit!['id'] as String
          : 'routine_$now';
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
        'targetDurationMinutes': c.sportsDuration,
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
      final scheduleData = {
        'id': 'sched_$routineId',
        'routineId': routineId,
        'scheduleType': 'RECURRENCE',
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
}
