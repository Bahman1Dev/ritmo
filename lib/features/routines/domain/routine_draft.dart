import 'package:flutter/foundation.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/planner_item_type.dart';
import 'package:ritmo/features/routines/domain/routine_recurrence.dart';

/// The single typed intermediate model representing what a user configured or edited in the UI.
/// Created from UI forms, passed to kernel commands, and never directly sent raw to SQL.
@immutable
class RoutineDraft {
  const RoutineDraft({
    this.id,
    required this.title,
    this.description,
    required this.category,
    this.customCategoryId,
    this.itemType = PlannerItemType.routine,
    required this.targetDurationMinutes,
    this.lightDurationMinutes,
    this.minimalDurationMinutes,
    required this.timeOfDay,
    required this.recurrence,
    this.reminderOffsetMinutes = 0,
    this.notificationLevel = NotificationLevel.normal,
    this.isEssential = false,
    this.zoneId,
    this.dependsOnRoutineId,
    this.notes,
    this.energyRule = EnergyRule.none,
    this.priority = 1.0,
  });

  final String? id;
  final String title;
  final String? description;
  final String category;
  final String? customCategoryId;
  final PlannerItemType itemType;
  final int targetDurationMinutes;
  final int? lightDurationMinutes;
  final int? minimalDurationMinutes;
  final String timeOfDay; // "HH:mm"
  final RoutineRecurrence recurrence;
  final int reminderOffsetMinutes;
  final NotificationLevel notificationLevel;
  final bool isEssential;
  final String? zoneId;
  final String? dependsOnRoutineId;
  final String? notes;
  final EnergyRule energyRule;
  final double priority;

  /// Loads a [RoutineDraft] from raw database rows.
  factory RoutineDraft.fromRow(
    Map<String, dynamic> routineRow,
    Map<String, dynamic>? scheduleRow,
  ) {
    final catName = routineRow['category'] as String? ?? 'personal';
    final notifLevelStr = routineRow['notificationLevel'] as String? ?? 'normal';
    final notifLevel = NotificationLevel.values.firstWhere(
      (e) => e.name == notifLevelStr,
      orElse: () => NotificationLevel.normal,
    );

    final energyRuleStr = routineRow['energyRule'] as String? ?? 'NONE';
    final energyRule = EnergyRule.values.firstWhere(
      (e) => e.name.toUpperCase() == energyRuleStr.toUpperCase(),
      orElse: () => EnergyRule.none,
    );

    final itemTypeStr = routineRow['itemType'] as String? ?? 'ROUTINE';
    final itemType = PlannerItemType.fromCode(itemTypeStr);

    final timeOfDay = scheduleRow?['timeOfDay'] as String? ?? '08:00';
    final offsetMin = routineRow['reminderOffsetMinutes'] as int? ?? 0;

    // Parse recurrence from scheduleRow
    RoutineRecurrence recurrence = const DailyRecurrence();
    if (scheduleRow != null) {
      final schedType = scheduleRow['scheduleType'] as String? ?? 'EVERY_DAY';
      final daysStr = scheduleRow['daysOfWeek'] as String? ?? '';
      if (schedType == 'SPECIFIC_DAYS' && daysStr.isNotEmpty) {
        final days = daysStr
            .split(',')
            .map((d) => int.tryParse(d.trim()))
            .whereType<int>()
            .toSet();
        if (days.isNotEmpty) {
          recurrence = WeekdaysRecurrence(weekdays: days);
        }
      } else if (schedType == 'EVERY_N_DAYS') {
        final intervalHours = scheduleRow['intervalHours'] as int? ?? 24;
        recurrence = IntervalRecurrence(days: (intervalHours / 24).round());
      } else if (schedType == 'ONCE') {
        final startDateStr = scheduleRow['startDate'] as String? ?? '';
        final parsedDate = DateTime.tryParse(startDateStr) ?? DateTime.now();
        recurrence = OnceRecurrence(date: parsedDate);
      }
    }

    return RoutineDraft(
      id: routineRow['id'] as String?,
      title: routineRow['title'] as String? ?? '',
      description: routineRow['description'] as String?,
      category: catName,
      customCategoryId: routineRow['customCategoryId'] as String?,
      itemType: itemType,
      targetDurationMinutes: routineRow['targetDurationMinutes'] as int? ?? 30,
      lightDurationMinutes: routineRow['lightDurationMinutes'] as int?,
      minimalDurationMinutes: routineRow['minimalDurationMinutes'] as int?,
      timeOfDay: timeOfDay,
      recurrence: recurrence,
      reminderOffsetMinutes: offsetMin,
      notificationLevel: notifLevel,
      isEssential: (routineRow['isEssential'] as int? ?? 0) == 1,
      zoneId: routineRow['zoneId'] as String?,
      dependsOnRoutineId: routineRow['dependsOnRoutineId'] as String?,
      notes: routineRow['notes'] as String?,
      energyRule: energyRule,
      priority: (routineRow['priority'] as num?)?.toDouble() ?? 1.0,
    );
  }

  /// Builds a raw map for [CreateRoutineCommand].
  Map<String, dynamic> toCreatePayload({required DateTime now}) {
    final (schedType, daysOfWeek) = deriveScheduleParams(recurrence);
    final recurrenceJson = encodeRecurrenceRule(
      recurrence: recurrence,
      startDate: now,
      reminderTimes: [timeOfDay],
    );

    return {
      'routineData': {
        if (id != null) 'id': id,
        'title': title,
        'description': description,
        'category': category,
        'customCategoryId': customCategoryId,
        'routineType': RoutineType.timeBased.name,
        'notificationLevel': notificationLevel.name,
        'isEssential': isEssential ? 1 : 0,
        'energyRule': energyRule.name,
        'priority': priority,
        'targetDurationMinutes': targetDurationMinutes,
        'lightDurationMinutes': lightDurationMinutes,
        'minimalDurationMinutes': minimalDurationMinutes,
        'dependsOnRoutineId': dependsOnRoutineId,
        'zoneId': zoneId,
        'itemType': itemType.code,
        'reminderOffsetMinutes': reminderOffsetMinutes,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      'scheduleData': {
        'scheduleType': schedType,
        'timeOfDay': timeOfDay,
        'daysOfWeek': daysOfWeek,
        'recurrenceRule': recurrenceJson,
        'createdAt': now.millisecondsSinceEpoch,
        'updatedAt': now.millisecondsSinceEpoch,
      },
    };
  }

  /// Builds a raw patch map for [EditRoutineCommand], excluding ID and unmodifiable fields.
  Map<String, dynamic> toEditPatch({required DateTime now}) {
    final (schedType, daysOfWeek) = deriveScheduleParams(recurrence);
    final recurrenceJson = encodeRecurrenceRule(
      recurrence: recurrence,
      startDate: now,
      reminderTimes: [timeOfDay],
    );

    return {
      'routineData': {
        'title': title,
        'description': description,
        'category': category,
        'customCategoryId': customCategoryId,
        'notificationLevel': notificationLevel.name,
        'isEssential': isEssential ? 1 : 0,
        'energyRule': energyRule.name,
        'priority': priority,
        'targetDurationMinutes': targetDurationMinutes,
        'lightDurationMinutes': lightDurationMinutes,
        'minimalDurationMinutes': minimalDurationMinutes,
        'dependsOnRoutineId': dependsOnRoutineId,
        'zoneId': zoneId,
        'itemType': itemType.code,
        'reminderOffsetMinutes': reminderOffsetMinutes,
        'updatedAt': now.millisecondsSinceEpoch,
      },
      'scheduleData': {
        'scheduleType': schedType,
        'timeOfDay': timeOfDay,
        'daysOfWeek': daysOfWeek,
        'recurrenceRule': recurrenceJson,
        'updatedAt': now.millisecondsSinceEpoch,
      },
    };
  }
}
