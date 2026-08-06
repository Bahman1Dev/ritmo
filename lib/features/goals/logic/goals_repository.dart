import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/core/services/alarm_scheduler_service.dart';
import 'package:ritmo/core/utils/ritmo_id_factory.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/goals/logic/goal_progress_calculator.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:sqflite/sqflite.dart';

class GoalCycleException implements Exception {
  final String goalId;
  final String parentId;
  GoalCycleException(this.goalId, this.parentId);
  @override
  String toString() => 'این هدف نمی‌تواند زیرمجموعهٔ یکی از زیرهدف‌های خودش باشد. (GoalCycleException: $goalId -> $parentId)';
}

class GoalsRepository {
  GoalsRepository._();
  static final GoalsRepository instance = GoalsRepository._();

  Future<List<Goal>> getGoals() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('goals', orderBy: 'createdAt DESC');
    return res.map(Goal.fromMap).toList();
  }

  /// Orphan guard T12: INNER JOIN goals ensures no orphaned steps are fetched
  Future<Map<String, List<GoalStep>>> getGoalSteps() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT s.* 
      FROM goal_steps s
      INNER JOIN goals g ON g.id = s.goalId
      ORDER BY s.displayOrder ASC
    ''');
    final map = <String, List<GoalStep>>{};
    for (final row in res) {
      final step = GoalStep.fromMap(row);
      map.putIfAbsent(step.goalId, () => []).add(step);
    }
    return map;
  }

  /// T22 Typed return for routines
  Future<List<RoutineRef>> getRoutines() async {
    final db = await DatabaseHelper.instance.database;
    final rows = await db.query('routines', where: 'isArchived = 0', orderBy: 'title ASC');
    return rows.map(RoutineRef.fromMap).toList();
  }

  /// T17 Scoped completions query
  Future<List<Map<String, dynamic>>> getRoutineCompletions({
    List<String>? routineIds,
    String? sinceDateIso,
  }) async {
    final db = await DatabaseHelper.instance.database;
    if (routineIds != null && routineIds.isEmpty) {
      return [];
    }

    if (routineIds != null && sinceDateIso != null) {
      final placeholders = List.filled(routineIds.length, '?').join(',');
      return db.rawQuery('''
        SELECT * FROM routine_completions
        WHERE routineId IN ($placeholders) AND completionDate >= ?
      ''', [...routineIds, sinceDateIso]);
    } else if (routineIds != null) {
      final placeholders = List.filled(routineIds.length, '?').join(',');
      return db.rawQuery('''
        SELECT * FROM routine_completions
        WHERE routineId IN ($placeholders)
      ''', routineIds);
    } else if (sinceDateIso != null) {
      return db.query('routine_completions', where: 'completionDate >= ?', whereArgs: [sinceDateIso]);
    } else {
      return db.query('routine_completions');
    }
  }

  Future<List<Course>> getCourses() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('courses');
    return res.map(Course.fromMap).toList();
  }

  Future<List<CourseSession>> getCourseSessions() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('course_sessions');
    return res.map(CourseSession.fromMap).toList();
  }

  Future<List<KonkurSubject>> getKonkurSubjects() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('konkur_subjects');
    return res.map(KonkurSubject.fromMap).toList();
  }

  Future<List<KonkurTopic>> getKonkurTopics() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('konkur_topics');
    return res.map(KonkurTopic.fromMap).toList();
  }

  Future<List<KonkurPlanItem>> getKonkurPlanItems() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('konkur_plan_items');
    return res.map(KonkurPlanItem.fromMap).toList();
  }

  Future<List<Map<String, dynamic>>> getStepsForDate(String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT gs.*, g.title as goalTitle
      FROM goal_steps gs
      INNER JOIN goals g ON gs.goalId = g.id
      WHERE gs.scheduledDate = ? AND g.status = 'ACTIVE'
      ORDER BY gs.displayOrder ASC
    ''', [dateStr]);
    return res.map(Map<String, dynamic>.from).toList();
  }

  /// T9: Check cycle prevention inside transaction
  Future<void> _checkGoalCycle(DatabaseExecutor txn, String goalId, String? parentId) async {
    if (parentId == null || parentId.isEmpty) return;
    if (parentId == goalId) {
      throw GoalCycleException(goalId, parentId);
    }

    final allRows = await txn.query('goals', columns: ['id', 'parentGoalId']);
    final descendants = <String>{};
    final queue = [goalId];
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      descendants.add(curr);
      for (final row in allRows) {
        final id = row['id'] as String;
        final p = row['parentGoalId'] as String?;
        if (p == curr && !descendants.contains(id)) {
          queue.add(id);
        }
      }
    }

    if (descendants.contains(parentId)) {
      throw GoalCycleException(goalId, parentId);
    }
  }

  /// T6: Recompute progress cache upwards for [goalId] and its parents
  Future<void> _recomputeProgressUpwards(DatabaseExecutor txn, String goalId) async {
    final goalRows = await txn.query('goals');
    final stepRows = await txn.rawQuery('''
      SELECT s.* FROM goal_steps s
      INNER JOIN goals g ON g.id = s.goalId
    ''');

    final allGoals = goalRows.map(Goal.fromMap).toList();
    final stepsByGoal = <String, List<GoalStep>>{};
    for (final row in stepRows) {
      final step = GoalStep.fromMap(row);
      stepsByGoal.putIfAbsent(step.goalId, () => []).add(step);
    }

    var currId = goalId;
    final updatedIds = <String>{};

    while (currId.isNotEmpty && !updatedIds.contains(currId)) {
      updatedIds.add(currId);
      final pVal = goalProgress(currId, allGoals, stepsByGoal);
      await txn.update(
        'goals',
        {'progressCache': pVal, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [currId],
      );

      final parentRow = allGoals.firstWhere(
        (g) => g.id == currId,
        orElse: () => Goal(id: '', title: '', goalType: GoalLevel.daily, createdAt: 0, updatedAt: 0),
      );
      if (parentRow.parentGoalId != null && parentRow.parentGoalId!.isNotEmpty) {
        currId = parentRow.parentGoalId!;
      } else {
        break;
      }
    }
  }

  /// T1 Tree-based completion check
  Future<bool> _isTreeComplete(
    DatabaseExecutor txn,
    String goalId, {
    Set<String>? visited,
  }) async {
    final currentVisited = visited ?? <String>{};
    if (currentVisited.contains(goalId)) {
      debugPrint('GOALS_CYCLE detected at $goalId');
      return false;
    }
    currentVisited.add(goalId);

    final steps = await txn.query('goal_steps', where: 'goalId = ?', whereArgs: [goalId]);
    final subGoals = await txn.query('goals', where: 'parentGoalId = ? AND status != "ABANDONED"', whereArgs: [goalId]);

    final allStepsDone = steps.every((s) => s['isCompleted'] == 1);
    final allSubGoalsDone = subGoals.every((g) => g['status'] == 'COMPLETED');

    final hasContent = steps.isNotEmpty || subGoals.isNotEmpty;
    final isComplete = hasContent && allStepsDone && allSubGoalsDone;

    if (isComplete) {
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      await txn.update(
        'goals',
        {
          'status': 'COMPLETED',
          'completionSource': 'AUTO',
          'completedAt': nowMs,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [goalId],
      );

      // Recursively check parent
      final pRow = await txn.query('goals', columns: ['parentGoalId'], where: 'id = ?', whereArgs: [goalId]);
      if (pRow.isNotEmpty) {
        final pId = pRow.first['parentGoalId'] as String?;
        if (pId != null && pId.isNotEmpty) {
          await _isTreeComplete(txn, pId, visited: Set<String>.from(currentVisited));
        }
      }
    }
    return isComplete;
  }

  /// T1–T4 & T13: Toggle step with tree completion, transaction & event bus
  Future<void> toggleStep(String stepId, bool currentVal, String goalId) async {
    final db = await DatabaseHelper.instance.database;
    final newVal = currentVal ? 0 : 1;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    String? scheduledDate;

    await db.transaction((txn) async {
      await txn.update(
        'goal_steps',
        {
          'isCompleted': newVal,
          'completedAt': newVal == 1 ? nowMs : null,
        },
        where: 'id = ?',
        whereArgs: [stepId],
      );

      await txn.update(
        'goals',
        {'lastActivityAt': nowMs, 'updatedAt': nowMs},
        where: 'id = ?',
        whereArgs: [goalId],
      );

      final stepRows = await txn.query('goal_steps', columns: ['scheduledDate'], where: 'id = ?', whereArgs: [stepId]);
      scheduledDate = stepRows.isNotEmpty ? stepRows.first['scheduledDate'] as String? : null;

      if (newVal == 1) {
        await _isTreeComplete(txn, goalId);
      } else {
        // T2 Reversion matrix: only revert if completionSource == 'AUTO'
        final gRows = await txn.query('goals', columns: ['status', 'completionSource'], where: 'id = ?', whereArgs: [goalId]);
        if (gRows.isNotEmpty) {
          final status = gRows.first['status'] as String?;
          final source = gRows.first['completionSource'] as String?;
          if (status == 'COMPLETED' && source == 'AUTO') {
            await txn.update(
              'goals',
              {
                'status': 'ACTIVE',
                'completionSource': null,
                'completedAt': null,
                'updatedAt': nowMs,
              },
              where: 'id = ?',
              whereArgs: [goalId],
            );
          }
        }
      }

      await _recomputeProgressUpwards(txn, goalId);
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalStepToggled',
      timestamp: DateTime.now(),
      payload: {
        'stepId': stepId,
        'goalId': goalId,
        'completed': newVal == 1,
        'date': scheduledDate,
      },
    ));
    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'goalId': goalId},
    ));
  }

  /// T11: Calculate deletion impact
  Future<GoalDeletionImpact> getDeletionImpact(String goalId) async {
    final db = await DatabaseHelper.instance.database;
    final allGoals = await db.query('goals', columns: ['id', 'parentGoalId']);

    final descendantGoalIds = <String>{};
    final queue = [goalId];
    while (queue.isNotEmpty) {
      final curr = queue.removeAt(0);
      descendantGoalIds.add(curr);
      for (final r in allGoals) {
        final id = r['id'] as String;
        final p = r['parentGoalId'] as String?;
        if (p == curr && !descendantGoalIds.contains(id)) {
          queue.add(id);
        }
      }
    }

    descendantGoalIds.remove(goalId); // subgoals count

    final placeholders = List.filled(descendantGoalIds.length + 1, '?').join(',');
    final targetGoalIds = [goalId, ...descendantGoalIds];

    final steps = await db.rawQuery('''
      SELECT isCompleted, linkedRoutineId, reminderEnabled 
      FROM goal_steps 
      WHERE goalId IN ($placeholders)
    ''', targetGoalIds);

    final stepCount = steps.length;
    final completedStepCount = steps.where((s) => (s['isCompleted'] as int? ?? 0) == 1).length;
    final linkedRoutineCount = steps.where((s) => s['linkedRoutineId'] != null).length;
    final scheduledReminderCount = steps.where((s) => (s['reminderEnabled'] as int? ?? 0) == 1).length;

    return GoalDeletionImpact(
      subGoalCount: descendantGoalIds.length,
      stepCount: stepCount,
      completedStepCount: completedStepCount,
      linkedRoutineCount: linkedRoutineCount,
      scheduledReminderCount: scheduledReminderCount,
    );
  }

  /// T4 & T11: Cascading deletion in transaction
  Future<void> deleteGoal(String goalId) async {
    final db = await DatabaseHelper.instance.database;
    String? parentGoalId;

    await db.transaction((txn) async {
      final targetRow = await txn.query('goals', columns: ['parentGoalId'], where: 'id = ?', whereArgs: [goalId]);
      if (targetRow.isNotEmpty) {
        parentGoalId = targetRow.first['parentGoalId'] as String?;
      }

      final allGoals = await txn.query('goals', columns: ['id', 'parentGoalId']);
      final targetGoalIds = <String>{};
      final queue = [goalId];
      while (queue.isNotEmpty) {
        final curr = queue.removeAt(0);
        targetGoalIds.add(curr);
        for (final r in allGoals) {
          final id = r['id'] as String;
          final p = r['parentGoalId'] as String?;
          if (p == curr && !targetGoalIds.contains(id)) {
            queue.add(id);
          }
        }
      }

      final placeholders = List.filled(targetGoalIds.length, '?').join(',');
      final targetList = targetGoalIds.toList();

      // Cancel reminders before deletion
      final reminderSteps = await txn.rawQuery('''
        SELECT id FROM goal_steps 
        WHERE goalId IN ($placeholders) AND reminderEnabled = 1
      ''', targetList);

      for (final r in reminderSteps) {
        final sId = r['id'] as String;
        try {
          await AlarmSchedulerService.cancel('goal_step_$sId');
        } catch (_) {}
      }

      await txn.rawDelete('DELETE FROM goal_steps WHERE goalId IN ($placeholders)', targetList);
      await txn.rawDelete('DELETE FROM goals WHERE id IN ($placeholders)', targetList);

      if (parentGoalId != null && parentGoalId!.isNotEmpty) {
        await _recomputeProgressUpwards(txn, parentGoalId!);
      }
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'goalId': goalId},
    ));
  }

  /// T4 & T5 & F8: Update goal status in transaction
  Future<void> updateGoalStatus(
    String goalId,
    String status, {
    String? completionSource,
    String? abandonReason,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      final updateMap = <String, dynamic>{
        'status': status,
        'updatedAt': nowMs,
        'lastActivityAt': nowMs,
      };

      if (status == 'COMPLETED') {
        updateMap['completedAt'] = nowMs;
        updateMap['completionSource'] = completionSource ?? 'MANUAL';
      } else if (status == 'ACTIVE') {
        updateMap['completedAt'] = null;
        updateMap['completionSource'] = null;
        updateMap['pausedAt'] = null;
        updateMap['abandonedAt'] = null;
      } else if (status == 'PAUSED') {
        updateMap['pausedAt'] = nowMs;
      } else if (status == 'ABANDONED') {
        updateMap['abandonedAt'] = nowMs;
        updateMap['abandonReason'] = abandonReason;
      }

      await txn.update('goals', updateMap, where: 'id = ?', whereArgs: [goalId]);
      await _recomputeProgressUpwards(txn, goalId);
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'goalId': goalId},
    ));
  }

  /// T5 & T9: Update entire goal model
  Future<void> updateGoal(Goal updatedGoal) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await _checkGoalCycle(txn, updatedGoal.id, updatedGoal.parentGoalId);

      final map = updatedGoal.toMap();
      map['updatedAt'] = nowMs;
      map['lastActivityAt'] = nowMs;

      await txn.update('goals', map, where: 'id = ?', whereArgs: [updatedGoal.id]);
      await _recomputeProgressUpwards(txn, updatedGoal.id);
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'goalId': updatedGoal.id},
    ));
  }

  /// T4 & T5 & T9: Save goal in transaction with full attributes
  Future<String> saveGoal({
    required String title,
    required String? description,
    required String goalType,
    required String? parentGoalId,
    required String? targetDate,
    required bool isPrivate,
    double weight = 1.0,
    String? whyItMatters,
    String? pastFailure,
    String? selfPromise,
    String? metricUnit,
    double? metricTarget,
    double? metricStart,
    String? iconKey,
    required List<Map<String, dynamic>> steps,
    List<Map<String, dynamic>>? subGoals,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final mainGoalId = RitmoIdFactory.goal();
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.transaction((txn) async {
      await _checkGoalCycle(txn, mainGoalId, parentGoalId);

      await txn.insert('goals', {
        'id': mainGoalId,
        'parentGoalId': parentGoalId,
        'title': title,
        'description': description,
        'goalType': goalType,
        'status': 'ACTIVE',
        'targetDate': targetDate,
        'progressCache': 0.0,
        'isPrivate': isPrivate ? 1 : 0,
        'weight': weight,
        'whyItMatters': whyItMatters,
        'pastFailure': pastFailure,
        'selfPromise': selfPromise,
        'metricUnit': metricUnit,
        'metricTarget': metricTarget,
        'metricStart': metricStart,
        'iconKey': iconKey,
        'lastActivityAt': nowMs,
        'createdAt': nowMs,
        'updatedAt': nowMs,
      });

      if (subGoals != null && subGoals.isNotEmpty) {
        for (var i = 0; i < steps.length; i++) {
          final step = steps[i];
          final stepTitle = step['title'] as String;
          if (stepTitle.isNotEmpty) {
            final stepId = RitmoIdFactory.goalStep();
            await txn.insert('goal_steps', {
              'id': stepId,
              'goalId': mainGoalId,
              'title': stepTitle,
              'isCompleted': 0,
              'displayOrder': i,
              'createdAt': nowMs,
              'scheduledDate': step['scheduledDate'],
              'linkedRoutineId': step['linkedRoutineId'],
              'completionRule': step['completionRule'] ?? 'MANUAL',
              'ruleConfig': step['ruleConfig'],
              'dependsOnStepId': step['dependsOnStepId'],
              'reminderEnabled': (step['reminderEnabled'] == true || step['reminderEnabled'] == 1) ? 1 : 0,
              'reminderTime': step['reminderTime'],
              'estimatedMinutes': step['estimatedMinutes'],
              'notes': step['notes'],
            });
          }
        }

        for (var i = 0; i < subGoals.length; i++) {
          final sg = subGoals[i];
          final sgTitle = sg['title'] as String;
          if (sgTitle.isNotEmpty) {
            final subGoalId = RitmoIdFactory.goal();
            await txn.insert('goals', {
              'id': subGoalId,
              'parentGoalId': mainGoalId,
              'title': sgTitle,
              'description': sg['description'],
              'goalType': sg['goalType'] ?? 'DAILY',
              'status': 'ACTIVE',
              'targetDate': sg['targetDate'],
              'progressCache': 0.0,
              'isPrivate': isPrivate ? 1 : 0,
              'weight': (sg['weight'] as num?)?.toDouble() ?? 1.0,
              'lastActivityAt': nowMs + i,
              'createdAt': nowMs + i,
              'updatedAt': nowMs + i,
            });

            final sgSteps = sg['steps'] as List<dynamic>? ?? [];
            for (var j = 0; j < sgSteps.length; j++) {
              final step = sgSteps[j];
              final stepTitle = step['title'] as String;
              if (stepTitle.isNotEmpty) {
                await txn.insert('goal_steps', {
                  'id': RitmoIdFactory.goalStep(),
                  'goalId': subGoalId,
                  'title': stepTitle,
                  'isCompleted': 0,
                  'displayOrder': j,
                  'createdAt': nowMs,
                  'scheduledDate': step['scheduledDate'],
                  'linkedRoutineId': step['linkedRoutineId'],
                  'completionRule': step['completionRule'] ?? 'MANUAL',
                  'ruleConfig': step['ruleConfig'],
                  'dependsOnStepId': step['dependsOnStepId'],
                  'reminderEnabled': (step['reminderEnabled'] == true || step['reminderEnabled'] == 1) ? 1 : 0,
                  'reminderTime': step['reminderTime'],
                  'estimatedMinutes': step['estimatedMinutes'],
                  'notes': step['notes'],
                });
              }
            }
          }
        }
      } else {
        for (var i = 0; i < steps.length; i++) {
          final step = steps[i];
          final stepTitle = step['title'] as String;
          if (stepTitle.isNotEmpty) {
            await txn.insert('goal_steps', {
              'id': RitmoIdFactory.goalStep(),
              'goalId': mainGoalId,
              'title': stepTitle,
              'isCompleted': 0,
              'displayOrder': i,
              'createdAt': nowMs,
              'scheduledDate': step['scheduledDate'],
              'linkedRoutineId': step['linkedRoutineId'],
              'completionRule': step['completionRule'] ?? 'MANUAL',
              'ruleConfig': step['ruleConfig'],
              'dependsOnStepId': step['dependsOnStepId'],
              'reminderEnabled': (step['reminderEnabled'] == true || step['reminderEnabled'] == 1) ? 1 : 0,
              'reminderTime': step['reminderTime'],
              'estimatedMinutes': step['estimatedMinutes'],
              'notes': step['notes'],
            });
          }
        }
      }

      await _recomputeProgressUpwards(txn, mainGoalId);
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'goalId': mainGoalId},
    ));

    return mainGoalId;
  }

  /// T6 Repair function for progressCache across all goals
  Future<int> backfillAllProgressCache() async {
    final db = await DatabaseHelper.instance.database;
    int count = 0;

    await db.transaction((txn) async {
      final goalRows = await txn.query('goals');
      final stepRows = await txn.rawQuery('''
        SELECT s.* FROM goal_steps s
        INNER JOIN goals g ON g.id = s.goalId
      ''');

      final allGoals = goalRows.map(Goal.fromMap).toList();
      final stepsByGoal = <String, List<GoalStep>>{};
      for (final row in stepRows) {
        final step = GoalStep.fromMap(row);
        stepsByGoal.putIfAbsent(step.goalId, () => []).add(step);
      }

      for (final g in allGoals) {
        final pVal = goalProgress(g.id, allGoals, stepsByGoal);
        await txn.update(
          'goals',
          {'progressCache': pVal},
          where: 'id = ?',
          whereArgs: [g.id],
        );
        count++;
      }
    });

    return count;
  }

  /// F1: Bridge for routine completions to auto-complete ROUTINE_STREAK steps (Fixes ه-03)
  Future<void> onRoutineCompleted({
    required String routineId,
    required String dateIso,
    required String resultType,
  }) async {
    if (['SNOOZED', 'CANNOT_NOW', 'SKIPPED'].contains(resultType)) return;

    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    final matchingSteps = await db.rawQuery('''
      SELECT s.* 
      FROM goal_steps s
      INNER JOIN goals g ON g.id = s.goalId
      WHERE s.linkedRoutineId = ? 
        AND s.completionRule = 'ROUTINE_STREAK'
        AND s.isCompleted = 0
        AND g.status = 'ACTIVE'
    ''', [routineId]);

    if (matchingSteps.isEmpty) return;

    final completions = await db.query(
      'routine_completions',
      where: 'routineId = ?',
      whereArgs: [routineId],
    );
    final completionCount = completions.length;

    await db.transaction((txn) async {
      for (final row in matchingSteps) {
        final stepId = row['id'] as String;
        final goalId = row['goalId'] as String;
        final ruleConfigRaw = row['ruleConfig'] as String?;

        var targetCount = 1;
        if (ruleConfigRaw != null && ruleConfigRaw.isNotEmpty) {
          try {
            final parsed = jsonDecode(ruleConfigRaw) as Map<String, dynamic>;
            targetCount = (parsed['target'] as num?)?.toInt() ?? 1;
          } catch (_) {}
        }

        if (completionCount >= targetCount) {
          await txn.update(
            'goal_steps',
            {'isCompleted': 1, 'completedAt': nowMs},
            where: 'id = ?',
            whereArgs: [stepId],
          );

          await _isTreeComplete(txn, goalId);
          await _recomputeProgressUpwards(txn, goalId);
        }
      }
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'routineId': routineId},
    ));
  }

  /// Add metric/manual checkin for a goal (Fixes ه-06 & ط10)
  Future<void> addCheckin({
    required String goalId,
    required double value,
    String? note,
    String kind = 'METRIC',
  }) async {
    final db = await DatabaseHelper.instance.database;
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final dateIso = DateTime.now().toIso8601String().substring(0, 10);
    final checkinId = RitmoIdFactory.goalStep();

    await db.transaction((txn) async {
      await txn.insert('goal_checkins', {
        'id': checkinId,
        'goalId': goalId,
        'dateIso': dateIso,
        'kind': kind,
        'value': value,
        'note': note,
        'createdAt': nowMs,
      });

      await txn.update(
        'goals',
        {
          'progressCache': value,
          'lastActivityAt': nowMs,
          'updatedAt': nowMs,
        },
        where: 'id = ?',
        whereArgs: [goalId],
      );

      await _recomputeProgressUpwards(txn, goalId);
    });

    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalChanged',
      timestamp: DateTime.now(),
      payload: {'goalId': goalId},
    ));
  }
}

