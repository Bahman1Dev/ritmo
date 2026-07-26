import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/supplementary_sports/movement/data/movement_repository.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_event.dart';
import 'package:ritmo/features/supplementary_sports/movement/domain/movement_kind.dart';

/// Single gateway entry point for all completion and state-change requests across Ritmo.
class CompletionGateway {
  CompletionGateway._();
  static final instance = CompletionGateway._();

  /// Submits any CompletionRequest and returns a standardized CompletionOutcome.
  Future<CompletionOutcome> submit(CompletionRequest request) async {
    try {
      return switch (request) {
        final RoutineCompletion req        => _handleRoutineCompletion(req),
        final RoutineSkip req              => _handleRoutineSkip(req),
        final RoutineReschedule req         => _handleRoutineReschedule(req),
        final RoutineSnooze req             => _handleRoutineSnooze(req),
        final CourseSessionCompletion req   => _handleCourseCompletion(req),
        final KonkurSessionCompletion req   => _handleKonkurCompletion(req),
        final WorshipCompletion req         => _handleWorshipCompletion(req),
        final GoalStepCompletion req       => _handleGoalStepCompletion(req),
        final MedicationTake req           => _handleMedicationTake(req),
        final MovementCompletion req       => _handleMovementCompletion(req),
        _                                  => CompletionOutcome.failure('نوع درخواست شناخته‌شده نیست'),
      };
    } catch (e, st) {
      debugPrint('CompletionGateway submission error: $e\n$st');
      return CompletionOutcome.failure(e.toString());
    }
  }

  Future<CompletionOutcome> _handleMovementCompletion(MovementCompletion req) async {
    final event = MovementEvent(
      id: RitmoIdFactory.movementLog(),
      kindCode: req.kindCode,
      durationMinutes: req.durationMinutes,
      intensity: MovementIntensity.fromCode(req.intensity),
      loggedAt: DateTime.tryParse(req.dateStr)?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch,
    );
    await MovementRepository.instance.logEvent(event);
    _notifySuccess(domain: 'movement', itemId: event.id, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success(undoToken: 'movement:${event.id}');
  }

  Future<CompletionOutcome> _handleRoutineCompletion(RoutineCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final undoId = RitmoIdFactory.completion();

    await db.transaction((txn) async {
      await txn.insert('routine_completions', {
        'id': undoId,
        'routineId': req.routineId,
        'completionDate': req.dateStr,
        'completionTime': nowMs,
        'resultType': req.result.dbValue,
        'partialRatio': req.partialRatio,
        'durationMinutes': req.durationMinutes,
        'actual_duration_minutes': req.durationMinutes,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      await txn.rawUpdate('''
        UPDATE routine_occurrences 
        SET status = 'done', updatedAt = ?
        WHERE routineId = ? AND date = ?
      ''', [nowMs, req.routineId, req.dateStr]);

      await ProgressionEngine().onCompletion(txn, req.routineId, req.result);
    });

    _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.dateStr, result: req.result.dbValue);
    return CompletionOutcome.success(undoToken: 'routine:$undoId');
  }

  Future<CompletionOutcome> _handleRoutineSkip(RoutineSkip req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final undoId = RitmoIdFactory.completion();

    await db.transaction((txn) async {
      await txn.insert('routine_completions', {
        'id': undoId,
        'routineId': req.routineId,
        'completionDate': req.dateStr,
        'completionTime': nowMs,
        'resultType': 'SKIPPED',
        'reason': req.reason,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      try {
        await txn.insert('skip_reasons', {
          'id': RitmoIdFactory.completion(),
          'itemId': req.routineId,
          'domain': 'routine',
          'dateStr': req.dateStr,
          'reason': req.reason ?? 'SKIPPED',
          'note': null,
          'createdAt': nowMs,
        });
      } catch (_) {}

      await txn.rawUpdate('''
        UPDATE routine_occurrences 
        SET status = 'skipped', updatedAt = ?
        WHERE routineId = ? AND date = ?
      ''', [nowMs, req.routineId, req.dateStr]);
    });

    _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.dateStr, result: 'SKIPPED');
    return CompletionOutcome.success(undoToken: 'routine:$undoId');
  }

  Future<CompletionOutcome> _handleRoutineReschedule(RoutineReschedule req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final undoId = RitmoIdFactory.completion();

    // Check if target date occurrence already exists
    final existingTomorrow = await db.query(
      'routine_occurrences',
      where: 'routineId = ? AND date = ?',
      whereArgs: [req.routineId, req.toDateStr],
    );

    if (existingTomorrow.isNotEmpty) {
      await db.transaction((txn) async {
        await txn.rawUpdate('''
          UPDATE routine_occurrences 
          SET status = 'rescheduled', updatedAt = ?
          WHERE routineId = ? AND date = ?
        ''', [nowMs, req.routineId, req.fromDateStr]);

        await txn.insert('routine_completions', {
          'id': undoId,
          'routineId': req.routineId,
          'completionDate': req.fromDateStr,
          'completionTime': nowMs,
          'resultType': 'RESCHEDULED',
          'reason': req.reason,
          'createdAt': nowMs,
          'updatedAt': nowMs,
        });

        try {
          await txn.insert('skip_reasons', {
            'id': RitmoIdFactory.completion(),
            'itemId': req.routineId,
            'domain': 'routine',
            'dateStr': req.fromDateStr,
            'reason': req.reason ?? 'موکول شد به فردا',
            'note': null,
            'createdAt': nowMs,
          });
        } catch (_) {}
      });

      _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.fromDateStr, result: 'RESCHEDULED');
      _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.toDateStr, result: 'RESCHEDULED');

      return CompletionOutcome.success(
        undoToken: 'reschedule:${req.routineId}|${req.fromDateStr}|${req.toDateStr}',
        userMessage: 'از قبل برای فردا برنامه‌ریزی شده بود',
      );
    }

    String? scheduledTime;
    final todayRows = await db.query(
      'routine_occurrences',
      where: 'routineId = ? AND date = ?',
      whereArgs: [req.routineId, req.fromDateStr],
    );
    if (todayRows.isNotEmpty) {
      scheduledTime = todayRows.first['scheduled_time']?.toString();
    }

    await db.transaction((txn) async {
      await txn.rawUpdate('''
        UPDATE routine_occurrences 
        SET status = 'rescheduled', updatedAt = ?
        WHERE routineId = ? AND date = ?
      ''', [nowMs, req.routineId, req.fromDateStr]);

      final occId = RitmoIdFactory.routine();
      await txn.insert('routine_occurrences', {
        'id': occId,
        'routineId': req.routineId,
        'date': req.toDateStr,
        'status': 'pending',
        'scheduled_time': scheduledTime ?? '08:00',
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      try {
        await txn.insert('skip_reasons', {
          'id': RitmoIdFactory.completion(),
          'itemId': req.routineId,
          'domain': 'routine',
          'dateStr': req.fromDateStr,
          'reason': req.reason ?? 'موکول شد به فردا',
          'note': null,
          'createdAt': nowMs,
        });
      } catch (_) {}

      await txn.insert('routine_completions', {
        'id': undoId,
        'routineId': req.routineId,
        'completionDate': req.fromDateStr,
        'completionTime': nowMs,
        'resultType': 'RESCHEDULED',
        'reason': req.reason,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });
    });

    _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.fromDateStr, result: 'RESCHEDULED');
    _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.toDateStr, result: 'RESCHEDULED');

    return CompletionOutcome.success(
      undoToken: 'reschedule:${req.routineId}|${req.fromDateStr}|${req.toDateStr}',
      userMessage: 'به فردای همین ساعت منتقل شد',
    );
  }

  Future<CompletionOutcome> _handleRoutineSnooze(RoutineSnooze req) async {
    await RitmoExecutionKernel.instance.execute(
      SnoozeReminderCommand(
        reminderId: req.reminderId,
        snoozeMinutes: req.snoozeMinutes,
        dateStr: req.dateStr,
      ),
    );

    _notifySuccess(domain: 'routine', itemId: req.reminderId, dateStr: req.dateStr, result: 'SNOOZED');
    return CompletionOutcome.success();
  }

  Future<CompletionOutcome> _handleCourseCompletion(CourseSessionCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'course_sessions',
      {
        'completionStatus': 'COMPLETED',
        'isCompleted': 1,
        'completedAt': nowMs,
        'actualDurationMinutes': req.durationMinutes,
        'updatedAt': nowMs,
      },
      where: 'id = ?',
      whereArgs: [req.sessionId],
    );

    _notifySuccess(domain: 'course', itemId: req.sessionId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success(undoToken: 'course:${req.sessionId}');
  }

  Future<CompletionOutcome> _handleKonkurCompletion(KonkurSessionCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final logId = RitmoIdFactory.konkurLog();

    await db.insert('konkur_study_logs', {
      'id': logId,
      'topicId': req.topicId,
      'subjectId': req.subjectId,
      'dateStr': req.dateStr,
      'durationMinutes': req.durationMinutes,
      'questionsCount': req.questionsCount,
      'createdAt': nowMs,
    });

    _notifySuccess(domain: 'konkur', itemId: req.topicId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success(undoToken: 'konkur:$logId');
  }

  Future<CompletionOutcome> _handleWorshipCompletion(WorshipCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final logId = RitmoIdFactory.worshipLog();

    await db.insert('worship_logs', {
      'id': logId,
      'worshipId': req.worshipId,
      'date': req.dateStr,
      'count': req.count,
      'createdAt': nowMs,
    });

    _notifySuccess(domain: 'worship', itemId: req.worshipId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success(undoToken: 'worship:$logId');
  }

  Future<CompletionOutcome> _handleGoalStepCompletion(GoalStepCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.update(
      'goal_steps',
      {
        'isCompleted': req.isCompleted ? 1 : 0,
        'completedAt': req.isCompleted ? nowMs : null,
        'updatedAt': nowMs,
      },
      where: 'id = ? AND goalId = ?',
      whereArgs: [req.stepId, req.goalId],
    );

    _notifySuccess(domain: 'goalStep', itemId: req.stepId, dateStr: req.dateStr, result: req.isCompleted ? 'FULL' : 'SKIPPED');
    return CompletionOutcome.success(undoToken: 'goalStep:${req.goalId}|${req.stepId}');
  }

  Future<CompletionOutcome> _handleMedicationTake(MedicationTake req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final logId = RitmoIdFactory.medicationLog();

    await db.insert('medication_logs', {
      'id': logId,
      'medicationId': req.medicationId,
      'date': req.dateStr,
      'doseTime': req.doseTime,
      'takenAt': nowMs,
    });

    _notifySuccess(domain: 'medicine', itemId: req.medicationId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success(undoToken: 'medicine:$logId');
  }

  /// Reverts a completion given an undo token.
  Future<CompletionOutcome> undo(String undoToken) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final parts = undoToken.split(':');

      if (parts.length < 2) {
        final rows = await db.query('routine_completions', where: 'id = ?', whereArgs: [undoToken]);
        if (rows.isNotEmpty) {
          final comp = rows.first;
          final rId = comp['routineId']! as String;
          final dateStr = comp['completionDate']! as String;

          await db.transaction((txn) async {
            await txn.delete('routine_completions', where: 'id = ?', whereArgs: [undoToken]);
            await txn.delete('skip_reasons', where: 'itemId = ? AND dateStr = ?', whereArgs: [rId, dateStr]);
            await txn.rawUpdate('''
              UPDATE routine_occurrences 
              SET status = 'pending', updatedAt = ?
              WHERE routineId = ? AND date = ?
            ''', [DateTime.now().millisecondsSinceEpoch, rId, dateStr]);
          });

          DayAgendaService.instance.invalidateDate(dateStr);
          return CompletionOutcome.success();
        }
        return CompletionOutcome.failure('توکن لغو یافت نشد');
      }

      final domain = parts[0];
      final idPayload = parts.sublist(1).join(':');

      switch (domain) {
        case 'routine':
          final rows = await db.query('routine_completions', where: 'id = ?', whereArgs: [idPayload]);
          if (rows.isNotEmpty) {
            final comp = rows.first;
            final rId = comp['routineId']! as String;
            final dateStr = comp['completionDate']! as String;

            await db.transaction((txn) async {
              await txn.delete('routine_completions', where: 'id = ?', whereArgs: [idPayload]);
              await txn.delete('skip_reasons', where: 'itemId = ? AND dateStr = ?', whereArgs: [rId, dateStr]);
              await txn.rawUpdate('''
                UPDATE routine_occurrences 
                SET status = 'pending', updatedAt = ?
                WHERE routineId = ? AND date = ?
              ''', [DateTime.now().millisecondsSinceEpoch, rId, dateStr]);
            });

            DayAgendaService.instance.invalidateDate(dateStr);
            return CompletionOutcome.success();
          }
          return CompletionOutcome.failure('توکن لغو روتین یافت نشد');

        case 'movement':
          await MovementRepository.instance.deleteEvent(idPayload);
          return CompletionOutcome.success();

        case 'course':
          await db.update(
            'course_sessions',
            {
              'completionStatus': 'PENDING',
              'isCompleted': 0,
              'completedAt': null,
              'updatedAt': DateTime.now().millisecondsSinceEpoch,
            },
            where: 'id = ?',
            whereArgs: [idPayload],
          );
          return CompletionOutcome.success();

        case 'konkur':
          await db.delete('konkur_study_logs', where: 'id = ?', whereArgs: [idPayload]);
          return CompletionOutcome.success();

        case 'worship':
          await db.delete('worship_logs', where: 'id = ?', whereArgs: [idPayload]);
          return CompletionOutcome.success();

        case 'medicine':
          await db.delete('medication_logs', where: 'id = ?', whereArgs: [idPayload]);
          return CompletionOutcome.success();

        case 'goalStep':
          final stepParts = idPayload.split('|');
          if (stepParts.length == 2) {
            final goalId = stepParts[0];
            final stepId = stepParts[1];
            await db.update(
              'goal_steps',
              {
                'isCompleted': 0,
                'completedAt': null,
                'updatedAt': DateTime.now().millisecondsSinceEpoch,
              },
              where: 'id = ? AND goalId = ?',
              whereArgs: [stepId, goalId],
            );
            return CompletionOutcome.success();
          }
          return CompletionOutcome.failure('شناسه گام هدف غیرمجاز است');

        case 'reschedule':
          final reschParts = idPayload.split('|');
          if (reschParts.length == 3) {
            final routineId = reschParts[0];
            final fromDateStr = reschParts[1];
            final toDateStr = reschParts[2];
            final nowMs = DateTime.now().millisecondsSinceEpoch;

            await db.transaction((txn) async {
              await txn.delete(
                'routine_occurrences',
                where: 'routineId = ? AND date = ? AND status = ?',
                whereArgs: [routineId, toDateStr, 'pending'],
              );

              await txn.rawUpdate('''
                UPDATE routine_occurrences 
                SET status = 'pending', updatedAt = ?
                WHERE routineId = ? AND date = ?
              ''', [nowMs, routineId, fromDateStr]);

              await txn.delete(
                'skip_reasons',
                where: 'itemId = ? AND dateStr = ?',
                whereArgs: [routineId, fromDateStr],
              );

              await txn.delete(
                'routine_completions',
                where: 'routineId = ? AND completionDate = ? AND resultType = ?',
                whereArgs: [routineId, fromDateStr, 'RESCHEDULED'],
              );
            });

            DayAgendaService.instance.invalidateDate(fromDateStr);
            DayAgendaService.instance.invalidateDate(toDateStr);
            return CompletionOutcome.success();
          }
          return CompletionOutcome.failure('شناسه تعویق غیرمجاز است');

        default:
          return CompletionOutcome.failure('دامنه بازگردانی پشتیبانی نمی‌شود');
      }
    } catch (e) {
      return CompletionOutcome.failure('خطا در بازگردانی: $e');
    }
  }

  void _notifySuccess({
    required String domain,
    required String itemId,
    required String dateStr,
    required String result,
  }) {
    DayAgendaService.instance.invalidateDate(dateStr);
    RitmoEventBus().fire(
      RitmoEvent(
        type: RitmoEventType.completionRecorded.code,
        timestamp: DateTime.now(),
        payload: {
          'domain': domain,
          'itemId': itemId,
          'dateStr': dateStr,
          'result': result,
          'didWrite': true,
        },
      ),
    );
  }
}
