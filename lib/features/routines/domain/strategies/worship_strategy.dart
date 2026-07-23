// lib/features/routines/domain/strategies/worship_strategy.dart

import 'package:flutter/material.dart' show BuildContext;
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_category_strategy.dart';
import 'package:ritmo/features/routines/domain/strategies/planner_save_context.dart';

class WorshipStrategy implements PlannerCategoryStrategy {
  const WorshipStrategy();

  @override
  Category get category => Category.religious;

  @override
  bool matches(Category category, {String? itemType}) => category == Category.religious;

  @override
  bool isModuleEnabled(Object controller) => true;

  @override
  Future<void> save(Object ctx, BuildContext context) async {
    final c = ctx as PlannerSaveContext;
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (c.worshipType == 'DEBT') {
      await db.insert('worship_debts', {
        'id': 'worship_debt_$now',
        'debtType': c.worshipDebtType,
        'title': c.title,
        'totalCount': c.worshipTotalCount,
        'remainingCount': c.worshipTotalCount,
        'dailyTarget': c.worshipDailyTarget,
        'autoCreated': 0,
        'isArchived': 0,
        'createdAt': now,
        'updatedAt': now,
      });
    } else {
      final timeStr = c.formatTime(c.selectedTime);
      await db.insert('worship_practices', {
        'id': 'worship_practice_$now',
        'practiceType': c.worshipType,
        'subType': null,
        'title': c.title,
        'dailyTarget': c.worshipDailyTarget,
        'dailyDone': 0,
        'totalTarget': null,
        'totalDone': 0,
        'reminderEnabled': 1,
        'reminderTime': c.worshipReminderAnchor == 'NONE' ? timeStr : null,
        'reminderOffsetMinutes': c.worshipOffsetMinutes,
        'reminderAnchor': c.worshipReminderAnchor,
        'reminderDaysOfWeek': c.worshipRepeatType == 'ONCE'
            ? c.formatDate(c.selectedDate)
            : c.worshipSelectedDays.join(','),
        'reminderTimes': null,
        'deferCount': 0,
        'lastDeferredUntil': null,
        'sortOrder': 0,
        'isActive': 1,
        'allowQada': 0,
        'reminderFrequency': c.worshipRepeatType == 'ONCE' ? 'ONCE' : 'WEEKLY',
        'notes': c.notes.isNotEmpty ? c.notes : null,
        'dailyDoneDate': null,
        'createdAt': now,
        'updatedAt': now,
      });
    }
    RitmoEventBus().fire(RitmoEvent(
      type: 'WorshipPracticeChanged',
      timestamp: DateTime.now(),
      payload: const {},
    ));
  }
}
