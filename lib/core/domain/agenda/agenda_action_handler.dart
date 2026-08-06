import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/agenda_item.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/completion/snooze_policy.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/models.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/features/worship/logic/prayer_timeline.dart';
import 'package:ritmo/features/worship/logic/worship_completion_repository.dart';
import 'package:ritmo/features/worship/logic/worship_engine.dart';
import 'package:ritmo/features/worship/logic/worship_repository.dart';
import 'package:ritmo/features/worship/models/worship_models.dart';
import 'package:sqflite/sqflite.dart';

class AgendaActionHandler {
  AgendaActionHandler._();
  static final AgendaActionHandler instance = AgendaActionHandler._();

  Future<List<String>> _practiceIdsForGroup(DatabaseExecutor db, String group) async {
    if (group == 'RAMADAN_FAST') {
      final rows = await db.query(
        'worship_practices',
        columns: ['id'],
        where: "id = 'wp_fasting_ramadan' OR subType = 'RAMADAN' OR practiceType = 'FASTING'",
      );
      if (rows.isNotEmpty) {
        return rows.map((r) => r['id']! as String).toList();
      }
      return ['wp_fasting_ramadan'];
    }

    const subTypesByGroup = {
      'FAJR': ['FAJR'],
      'DHUHR_ASR': ['DHUHR', 'ASR'],
      'MAGHRIB_ISHA': ['MAGHRIB', 'ISHA'],
    };

    final subTypes = subTypesByGroup[group] ?? const <String>[];
    if (subTypes.isEmpty) return const [];

    final rows = await db.query(
      'worship_practices',
      columns: ['id'],
      where: 'subType IN (${List.filled(subTypes.length, '?').join(',')})',
      whereArgs: subTypes,
    );

    if (rows.isEmpty) {
      if (group == 'FAJR') return ['wp_fajr'];
      if (group == 'DHUHR_ASR') return ['wp_dhuhr', 'wp_asr'];
      if (group == 'MAGHRIB_ISHA') return ['wp_maghrib', 'wp_isha'];
    }

    return rows.map((r) => r['id']! as String).toList();
  }

  /// Centralized logic to toggle a prayer completion state.
  Future<void> togglePrayer({
    required String group,
    required bool isDone,
    required String dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final ids = await _practiceIdsForGroup(db, group);

    if (ids.isEmpty) {
      debugPrint('[AgendaActionHandler] Unknown or unconfigured prayer group: $group');
      return;
    }

    final date = DateTime.tryParse(dateStr) ?? DateTime.now();
    for (final id in ids) {
      if (isDone) {
        await WorshipEngine.instance.logDone(
          practiceId: id,
          date: date,
        );
      } else {
        await WorshipEngine.instance.clearLog(
          practiceId: id,
          date: date,
        );
      }
    }

    _invalidateAndNotify(dateStr, 'WorshipUpdated', {'date': dateStr, 'group': group});
  }

  /// Centralized logic to snooze a prayer reminder.
  Future<void> snoozePrayer({
    required List<String> practiceIds,
    required int minutes,
    required String dateStr,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final now = DateTime.now();
    final nowMs = now.millisecondsSinceEpoch;

    final pTimesMap = await WorshipRepository.instance.getPrayerTimesForDate(now);
    final pTime = PrayerTime.fromMap(pTimesMap);

    await db.transaction((txn) async {
      for (final id in practiceIds) {
        final practiceRows = await txn.query(
          'worship_practices',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (practiceRows.isEmpty) continue;

        final pMap = practiceRows.first;
        final currentDeferCount = pMap['deferCount'] as int? ?? 0;
        final subType = (pMap['subType'] as String? ?? 'FAJR').toUpperCase();
        final pType = (pMap['practiceType'] as String? ?? 'PRAYER').toUpperCase();

        final decision = SnoozePolicy.evaluate(
          itemId: id,
          now: now,
          requestedMinutes: minutes,
          currentDeferCount: currentDeferCount,
          category: 'religious',
          isEssential: pType == 'PRAYER' ? 1 : 0,
          configuredMax: 2,
        );

        if (decision.verdict == SnoozeVerdict.exhausted || decision.verdict == SnoozeVerdict.blockedMidnight) {
          throw Exception(decision.userMessage ?? 'سقف تعویق این مورد پر شده است.');
        }

        var allowedMins = decision.allowedMinutes;
        final deadline = PrayerTimeline.deadlineFor(subType, pTime, now);

        if (deadline != null) {
          final targetTime = now.add(Duration(minutes: allowedMins));
          if (targetTime.isAfter(deadline)) {
            final remainingToDeadline = deadline.difference(now).inMinutes;
            if (remainingToDeadline < 5) {
              throw Exception('مهلت شرعی این نماز در حال پایان است.');
            }
            allowedMins = remainingToDeadline;
          }
        }

        final snoozeUntilMs = nowMs + (allowedMins * 60 * 1000);
        final newDeferCount = decision.deferCount;

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
    final date = DateTime.tryParse(dateStr) ?? DateTime.now();

    for (final practiceMap in practices) {
      final id = practiceMap['id'] as String;
      await WorshipEngine.instance.logSkip(
        practiceId: id,
        date: date,
        addToQada: addToQada,
      );
    }

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
            'konkur_plan_items',
            {
              'plannedMinutes': newDurationMinutes,
              'isUserEdited': 1,
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
