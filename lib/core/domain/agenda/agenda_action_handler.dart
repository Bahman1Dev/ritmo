import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:sqflite/sqflite.dart';

class AgendaActionHandler {
  AgendaActionHandler._();
  static final AgendaActionHandler instance = AgendaActionHandler._();

  /// Centralized logic to toggle a prayer completion state.
  Future<void> togglePrayer({
    required String group,
    required bool isDone,
    required String dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    var ids = <String>[];
    if (group == 'FAJR') {
      ids = ['wp_fajr'];
    } else if (group == 'DHUHR_ASR') {
      ids = ['wp_dhuhr'];
    } else if (group == 'MAGHRIB_ISHA') {
      ids = ['wp_maghrib'];
    }

    final targetVal = isDone ? 1 : 0;

    await db.transaction((txn) async {
      for (final id in ids) {
        await txn.update(
          'worship_practices',
          {
            'dailyDone': targetVal,
            'dailyDoneDate': dateStr,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    });

    _invalidateAndNotify(dateStr, 'PrayerCompleted', {
      'group': group,
      'done': isDone,
      'date': dateStr,
    });
  }

  /// Centralized logic to snooze a prayer reminder.
  Future<void> snoozePrayer({
    required List<String> practiceIds,
    required int minutes,
    required String dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final snoozeUntilMs = nowMs + (minutes * 60 * 1000);

    await db.transaction((txn) async {
      for (final id in practiceIds) {
        final List<Map<String, dynamic>> practiceRows = await txn.query(
          'worship_practices',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (practiceRows.isEmpty) continue;

        final currentDeferCount = practiceRows.first['deferCount'] as int? ?? 0;
        if (currentDeferCount >= 3) {
          throw Exception('حداکثر تعداد تعویق (۳ بار) برای این مورد ثبت شده است.');
        }

        final newDeferCount = currentDeferCount + 1;

        // 1. Update Worship practice
        await txn.update(
          'worship_practices',
          {
            'deferCount': newDeferCount,
            'lastDeferredUntil': snoozeUntilMs,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        // 2. Insert/Replace pending reminder
        final reminderId = 'worship_snooze_${id}_$nowMs';
        await txn.insert(
          'pending_reminders',
          {
            'id': reminderId,
            'routineId': 'worship_$id',
            'originalTime': nowMs,
            'scheduledTime': snoozeUntilMs,
            'snoozeUntil': snoozeUntilMs,
            'state': 'delayed',
            'deferCount': newDeferCount,
            'createdAt': nowMs,
            'updatedAt': nowMs,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    });

    _invalidateAndNotify(dateStr, 'WorshipUpdated', {'date': dateStr});
  }

  /// Centralized logic to skip a prayer and optionally add it to Qada debts.
  Future<void> skipPrayer({
    required List<Map<String, dynamic>> practices,
    required bool addToQada,
    required String dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      for (final practiceMap in practices) {
        final id = practiceMap['id'] as String;
        final subType = practiceMap['subType'] as String? ?? 'PRAYER';
        final title = practiceMap['title'] as String? ?? '';
        final practiceType = practiceMap['practiceType'] as String? ?? 'PRAYER';

        // 1. Update practice status to skipped (-1)
        await txn.update(
          'worship_practices',
          {
            'dailyDone': -1,
            'dailyDoneDate': dateStr,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [id],
        );

        // 2. Add to Qada debts if requested
        if (addToQada) {
          final debtId = 'debt_${subType}_$nowMs';
          final debtType = practiceType == 'FASTING' ? 'FAST' : 'PRAYER';
          final debtTitle = practiceType == 'FASTING' ? 'روزه قضا' : title;

          final existingDebt = await txn.query(
            'worship_debts',
            where: 'debtType = ? AND title = ? AND isArchived = 0',
            whereArgs: [debtType, debtTitle],
            limit: 1,
          );

          if (existingDebt.isNotEmpty) {
            final existingId = existingDebt.first['id']! as String;
            final currentTotal = existingDebt.first['totalCount'] as int? ?? 0;
            final currentRemaining = existingDebt.first['remainingCount'] as int? ?? 0;

            await txn.update(
              'worship_debts',
              {
                'totalCount': currentTotal + 1,
                'remainingCount': currentRemaining + 1,
                'updatedAt': nowMs,
              },
              where: 'id = ?',
              whereArgs: [existingId],
            );
          } else {
            await txn.insert(
              'worship_debts',
              {
                'id': debtId,
                'debtType': debtType,
                'title': debtTitle,
                'totalCount': 1,
                'remainingCount': 1,
                'dailyTarget': 1,
                'autoCreated': 1,
                'isArchived': 0,
                'createdAt': nowMs,
                'updatedAt': nowMs,
              },
            );
          }
        }
      }
    });

    _invalidateAndNotify(dateStr, 'WorshipUpdated', {'date': dateStr});
  }

  Future<void> toggleAgendaItem({
    required AgendaItem item,
    required bool isDone,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      if (item.domain == AgendaDomain.course) {
        await txn.update(
          'course_sessions',
          {
            'completionStatus': isDone ? 'COMPLETED' : 'PENDING',
            'actualDurationMinutes': isDone ? (item.durationMinutes ?? 30) : 0,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [item.sourceId],
        );
      } else if (item.domain == AgendaDomain.goalStep) {
        await txn.update(
          'goal_steps',
          {
            'isCompleted': isDone ? 1 : 0,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [item.sourceId],
        );

        final auditId = '${DateTime.now().microsecondsSinceEpoch}';
        await txn.insert('assistant_audit_log', {
          'id': auditId,
          'actionType': 'completeGoalStep',
          'targetKey': item.sourceId,
          'newValue': isDone ? 'COMPLETED' : 'PENDING',
          'appliedAt': nowMs,
        });
      } else if (item.domain == AgendaDomain.worshipDebt) {
        final List<Map<String, dynamic>> debts = await txn.query(
          'worship_debts',
          where: 'id = ?',
          whereArgs: [item.sourceId],
        );
        if (debts.isNotEmpty) {
          final currentRemaining = debts.first['remainingCount'] as int? ?? 0;
          final newRemaining = isDone 
              ? (currentRemaining - 1).clamp(0, 99999)
              : (currentRemaining + 1).clamp(0, 99999);
          final isNowArchived = newRemaining == 0;

          await txn.update(
            'worship_debts',
            {
              'remainingCount': newRemaining,
              'isArchived': isNowArchived ? 1 : 0,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [item.sourceId],
          );

          if (item.sourceId.startsWith('debt_cycle_fast_')) {
            final cycleDebtId = item.sourceId.replaceFirst('debt_cycle_fast_', '');
            await txn.update(
              'fasting_debt',
              {
                'isResolved': isNowArchived ? 1 : 0,
                'updatedAt': nowMs,
              },
              where: 'id = ?',
              whereArgs: [cycleDebtId],
            );
          }
        }
      } else if (item.domain == AgendaDomain.mustahab) {
        await txn.update(
          'worship_practices',
          {
            'dailyDone': isDone ? 1 : 0,
            'dailyDoneDate': item.dateStr,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [item.sourceId],
        );
      }
    });

    if (item.domain == AgendaDomain.course) {
      RitmoEventBus().fire(RitmoEvent(
        type: 'CourseSessionCompleted',
        timestamp: DateTime.now(),
        payload: {
          'sessionId': item.sourceId,
          'done': isDone,
          'plannedDate': item.dateStr,
        },
      ));
    }

    _invalidateAndNotify(item.dateStr, 'AgendaItemToggled', {
      'domain': item.domain.name,
      'isDone': isDone,
      'date': item.dateStr,
    });
  }

  /// Updates start time and/or duration for an agenda item directly.
  Future<void> updateAgendaItemTimeAndDuration({
    required AgendaItem item,
    String? newTimeOfDay,
    int? newDurationMinutes,
  }) async {
    if (newDurationMinutes != null) {
      newDurationMinutes = DurationBounds.sanitize(newDurationMinutes);
    }
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      if (item.domain == AgendaDomain.routine) {
        if (newTimeOfDay != null) {
          await txn.update(
            'routine_schedules',
            {
              'timeOfDay': newTimeOfDay,
              'updatedAt': nowMs,
            },
            where: 'routineId = ?',
            whereArgs: [item.sourceId],
          );
        }
        if (newDurationMinutes != null) {
          await txn.update(
            'routines',
            {
              'targetDurationMinutes': newDurationMinutes,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [item.sourceId],
          );
        }
      } else if (item.domain == AgendaDomain.course) {
        final courseId = item.deepLink.targetId;
        final updates = <String, dynamic>{'updatedAt': nowMs};
        if (newTimeOfDay != null) updates['preferredTime'] = newTimeOfDay;
        if (newDurationMinutes != null) updates['sessionDurationMinutes'] = newDurationMinutes;

        await txn.update(
          'courses',
          updates,
          where: 'id = ?',
          whereArgs: [courseId],
        );
      } else if (item.domain == AgendaDomain.sport) {
        if (newDurationMinutes != null) {
          await txn.update(
            'ss_workout_plan',
            {
              'estimatedMinutes': newDurationMinutes,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [item.sourceId],
          );
        }
      } else if (item.domain == AgendaDomain.konkur) {
        if (newDurationMinutes != null) {
          await txn.update(
            'konkur_plan',
            {
              'plannedMinutes': newDurationMinutes,
              'updatedAt': nowMs,
            },
            where: 'id = ?',
            whereArgs: [item.sourceId],
          );
        }
      }
    });

    final payload = <String, dynamic>{
      'id': item.id,
      'domain': item.domain.name,
      'date': item.dateStr,
    };
    if (newTimeOfDay != null) payload['timeOfDay'] = newTimeOfDay;
    if (newDurationMinutes != null) payload['durationMinutes'] = newDurationMinutes;

    _invalidateAndNotify(item.dateStr, 'RoutineUpdated', payload);
  }

  /// Clears scheduled start time for an agenda item (moving it to untimed/unscheduled).
  Future<void> clearAgendaItemTime({required AgendaItem item}) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      if (item.domain == AgendaDomain.routine) {
        await txn.update(
          'routine_schedules',
          {
            'timeOfDay': null,
            'updatedAt': nowMs,
          },
          where: 'routineId = ?',
          whereArgs: [item.sourceId],
        );
      } else if (item.domain == AgendaDomain.course) {
        final courseId = item.deepLink.targetId;
        await txn.update(
          'courses',
          {
            'preferredTime': null,
            'updatedAt': nowMs,
          },
          where: 'id = ?',
          whereArgs: [courseId],
        );
      }
    });

    _invalidateAndNotify(item.dateStr, 'RoutineUpdated', {
      'id': item.id,
      'domain': item.domain.name,
      'date': item.dateStr,
      'timeOfDay': null,
    });
  }

  void notifyWorshipUpdated(String dateStr) {
    _invalidateAndNotify(dateStr, 'WorshipUpdated', {'date': dateStr});
  }

  void _invalidateAndNotify(String dateStr, String eventType, Map<String, dynamic> payload) {
    DayAgendaService.instance.invalidateDate(dateStr);
    RitmoEvents.notifyRoutineChanged();
    RitmoEventBus().fire(RitmoEvent(
      type: eventType,
      timestamp: DateTime.now(),
      payload: payload,
    ));
  }
}
