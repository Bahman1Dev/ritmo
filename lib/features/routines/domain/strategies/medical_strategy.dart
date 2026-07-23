// lib/features/routines/domain/strategies/medical_strategy.dart

import 'dart:convert';

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';

class MedicalStrategy implements PlannerCategoryStrategy {
  const MedicalStrategy();

  @override
  Category get category => Category.medical;

  @override
  bool matches(Category category, {String? itemType}) => category == Category.medical;

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;
    final now = DateTime.now().millisecondsSinceEpoch;
    final routineId = c.isEditing
        ? c.routineToEdit!['id'] as String
        : 'medication_$now';

    final routineData = {
      'id': routineId,
      'title': c.title,
      'description': c.description.isNotEmpty ? c.description : null,
      'category': 'medical',
      'routineType': c.medicalMode == 'FIXED' ? 'timeBased' : 'asNeeded',
      'notificationLevel': 'normal',
      'isEssential': 0,
      'isEssentialLocked': 0,
      'energyRule': 'NONE',
      'priority': 1.0,
      'medStockCount': c.medicalStockCount,
      'medRefillThreshold': c.medicalRefillWarning,
      'minIntervalHours': c.medicalMode == 'PRN' ? c.medicalMinIntervalHours : 0,
      'maxDosesPerDay': c.medicalMode == 'PRN' ? c.medicalMaxDosesPerDay : 0,
      'isArchived': 0,
      'isPrivate': 0,
      'displayOrder': 1,
      'createdAt': c.isEditing ? c.routineToEdit!['createdAt'] ?? now : now,
      'updatedAt': now,
      'itemType': 'ROUTINE',
    };

    final firstTime = c.medicalMode == 'FIXED' && c.medicalTimes.isNotEmpty
        ? c.formatTime(c.medicalTimes.first)
        : '08:00';

    final rule = {
      'weekdays': [6, 7, 1, 2, 3, 4, 5],
      'reminderTimes': c.medicalTimes.map(c.formatTime).toList(),
      'startDate': DateTime.now().toIso8601String().substring(0, 10),
    };

    final scheduleData = {
      'id': 'sched_$routineId',
      'routineId': routineId,
      'scheduleType': c.medicalMode == 'FIXED' ? 'RECURRENCE' : 'DAILY',
      'timeOfDay': firstTime,
      'daysOfWeek': '6,7,1,2,3,4,5',
      'recurrenceRule': jsonEncode(rule),
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
