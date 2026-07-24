import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/agenda/day_agenda_service.dart';
import 'package:ritmo/core/domain/completion/completion_outcome.dart';
import 'package:ritmo/core/domain/completion/completion_request.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/domain/engines/ritmo_execution_kernel.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';

/// Single gateway entry point for all completion and state-change requests across Ritmo.
class CompletionGateway {
  CompletionGateway._();
  static final instance = CompletionGateway._();

  /// Submits any CompletionRequest and returns a standardized CompletionOutcome.
  Future<CompletionOutcome> submit(CompletionRequest request) async {
    try {
      return switch (request) {
        RoutineCompletion req      => _handleRoutineCompletion(req),
        RoutineSkip req            => _handleRoutineSkip(req),
        RoutineSnooze req          => _handleRoutineSnooze(req),
        CourseSessionCompletion req=> _handleCourseCompletion(req),
        KonkurSessionCompletion req => _handleKonkurCompletion(req),
        WorshipCompletion req      => _handleWorshipCompletion(req),
        GoalStepCompletion req     => _handleGoalStepCompletion(req),
        MedicationTake req         => _handleMedicationTake(req),
        MovementCompletion _       => throw UnimplementedError('پرامپت ۰۲۴'),
      };
    } catch (e, st) {
      debugPrint('CompletionGateway submission error: $e\n$st');
      return CompletionOutcome.failure(e.toString());
    }
  }

  Future<CompletionOutcome> _handleRoutineCompletion(RoutineCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final undoId = RitmoIdFactory.routine();

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
    return CompletionOutcome.success(undoToken: undoId);
  }

  Future<CompletionOutcome> _handleRoutineSkip(RoutineSkip req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final undoId = RitmoIdFactory.routine();

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

      await txn.rawUpdate('''
        UPDATE routine_occurrences 
        SET status = 'skipped', updatedAt = ?
        WHERE routineId = ? AND date = ?
      ''', [nowMs, req.routineId, req.dateStr]);
    });

    _notifySuccess(domain: 'routine', itemId: req.routineId, dateStr: req.dateStr, result: 'SKIPPED');
    return CompletionOutcome.success(undoToken: undoId);
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
    return CompletionOutcome.success();
  }

  Future<CompletionOutcome> _handleKonkurCompletion(KonkurSessionCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert('konkur_study_logs', {
      'id': RitmoIdFactory.routine(),
      'topicId': req.topicId,
      'subjectId': req.subjectId,
      'dateStr': req.dateStr,
      'durationMinutes': req.durationMinutes,
      'questionsCount': req.questionsCount,
      'createdAt': nowMs,
    });

    _notifySuccess(domain: 'konkur', itemId: req.topicId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success();
  }

  Future<CompletionOutcome> _handleWorshipCompletion(WorshipCompletion req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert('worship_logs', {
      'id': RitmoIdFactory.routine(),
      'worshipId': req.worshipId,
      'date': req.dateStr,
      'count': req.count,
      'createdAt': nowMs,
    });

    _notifySuccess(domain: 'worship', itemId: req.worshipId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success();
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
    return CompletionOutcome.success();
  }

  Future<CompletionOutcome> _handleMedicationTake(MedicationTake req) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert('medication_logs', {
      'id': RitmoIdFactory.routine(),
      'medicationId': req.medicationId,
      'date': req.dateStr,
      'doseTime': req.doseTime,
      'takenAt': nowMs,
    });

    _notifySuccess(domain: 'medication', itemId: req.medicationId, dateStr: req.dateStr, result: 'FULL');
    return CompletionOutcome.success();
  }

  /// Reverts a completion given an undo token.
  Future<CompletionOutcome> undo(String undoToken) async {
    try {
      final db = await DatabaseHelper.instance.database;
      final rows = await db.query('routine_completions', where: 'id = ?', whereArgs: [undoToken]);
      if (rows.isNotEmpty) {
        final comp = rows.first;
        final rId = comp['routineId']! as String;
        final dateStr = comp['completionDate']! as String;

        await db.transaction((txn) async {
          await txn.delete('routine_completions', where: 'id = ?', whereArgs: [undoToken]);
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
    } catch (e) {
      return CompletionOutcome.failure(e.toString());
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
        type: RitmoEventType.workoutLogChanged.code,
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
