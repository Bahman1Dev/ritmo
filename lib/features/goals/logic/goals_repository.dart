import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/domain/engines/ritmo_event_bus.dart';
import 'package:ritmo/features/courses/models/course_models.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';

class GoalsRepository {
  GoalsRepository._();
  static final GoalsRepository instance = GoalsRepository._();

  Future<List<Goal>> getGoals() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('goals', orderBy: 'createdAt DESC');
    return res.map(Goal.fromMap).toList();
  }

  Future<Map<String, List<GoalStep>>> getGoalSteps() async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.query('goal_steps', orderBy: 'displayOrder ASC');
    final map = <String, List<GoalStep>>{};
    for (final row in res) {
      final step = GoalStep.fromMap(row);
      map.putIfAbsent(step.goalId, () => []).add(step);
    }
    return map;
  }

  Future<List<Map<String, dynamic>> > getRoutines() async {
    final db = await DatabaseHelper.instance.database;
    return db.query('routines', where: 'isArchived = 0', orderBy: 'title ASC');
  }

  Future<List<Map<String, dynamic>> > getRoutineCompletions() async {
    final db = await DatabaseHelper.instance.database;
    return db.query('routine_completions');
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

  /// Raw goal-step rows scheduled on [dateStr] (YYYY-MM-DD) for ACTIVE goals,
  /// joined with the parent goal title (`goalTitle`).
  ///
  /// Mirrors the inline query the Home dashboard used, so `DayAgendaService`
  /// and the dashboard share one definition of "today's goal steps".
  Future<List<Map<String, dynamic>>> getStepsForDate(String dateStr) async {
    final db = await DatabaseHelper.instance.database;
    final res = await db.rawQuery('''
      SELECT gs.*, g.title as goalTitle
      FROM goal_steps gs
      JOIN goals g ON gs.goalId = g.id
      WHERE gs.scheduledDate = ? AND g.status = 'ACTIVE'
    ''', [dateStr]);
    return res.map(Map<String, dynamic>.from).toList();
  }

  Future<void> toggleStep(String stepId, bool currentVal, String goalId) async {
    final db = await DatabaseHelper.instance.database;
    final newVal = currentVal ? 0 : 1;
    await db.update(
      'goal_steps',
      {'isCompleted': newVal},
      where: 'id = ?',
      whereArgs: [stepId],
    );

    // Capture the step's scheduled date so the right agenda day is refreshed.
    final stepRows = await db.query('goal_steps',
        columns: ['scheduledDate'], where: 'id = ?', whereArgs: [stepId]);
    final scheduledDate =
        stepRows.isNotEmpty ? stepRows.first['scheduledDate'] as String? : null;

    // Check if all steps of this goal are completed, and auto-complete the goal if they are.
    final steps = await db.query('goal_steps', where: 'goalId = ?', whereArgs: [goalId]);
    final allCompleted = steps.every((s) => s['isCompleted'] == 1);
    if (allCompleted && steps.isNotEmpty) {
      await db.update(
        'goals',
        {'status': 'COMPLETED', 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [goalId],
      );
    } else {
      await db.update(
        'goals',
        {'status': 'ACTIVE', 'updatedAt': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [goalId],
      );
    }

    // Notify the reactive layer (invalidates DayAgenda cache + refreshes UI).
    RitmoEventBus().fire(RitmoEvent(
      type: 'GoalStepToggled',
      timestamp: DateTime.now(),
      payload: {
        'stepId': stepId,
        'goalId': goalId,
        'completed': newVal == 1,
        'date': ?scheduledDate,
      },
    ));
  }

  Future<void> deleteGoal(String goalId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('goals', where: 'id = ?', whereArgs: [goalId]);
  }

  Future<void> updateGoalStatus(String goalId, String status) async {
    final db = await DatabaseHelper.instance.database;
    await db.update(
      'goals',
      {'status': status, 'updatedAt': DateTime.now().millisecondsSinceEpoch},
      where: 'id = ?',
      whereArgs: [goalId],
    );
  }

  Future<void> saveGoal({
    required String title,
    required String? description,
    required String goalType,
    required String? parentGoalId,
    required String? targetDate,
    required List<Map<String, dynamic>> steps,
    List<Map<String, dynamic>>? subGoals,
  }) async {
    final db = await DatabaseHelper.instance.database;
    final mainGoalId = 'goal_${DateTime.now().millisecondsSinceEpoch}';
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    await db.insert('goals', {
      'id': mainGoalId,
      'parentGoalId': parentGoalId,
      'title': title,
      'description': description,
      'goalType': goalType,
      'status': 'ACTIVE',
      'targetDate': targetDate,
      'progressCache': 0.0,
      'createdAt': nowMs,
      'updatedAt': nowMs,
    });

    if (subGoals != null && subGoals.isNotEmpty) {
      // Save direct steps
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final stepTitle = step['title'] as String;
        if (stepTitle.isNotEmpty) {
          await db.insert('goal_steps', {
            'id': 'step_${mainGoalId}_direct_$i',
            'goalId': mainGoalId,
            'title': stepTitle,
            'isCompleted': 0,
            'displayOrder': i,
            'createdAt': nowMs,
            'scheduledDate': step['scheduledDate'],
            'linkedRoutineId': step['linkedRoutineId'],
          });
        }
      }

      // Save sub-goals & steps
      for (var i = 0; i < subGoals.length; i++) {
        final sg = subGoals[i];
        final sgTitle = sg['title'] as String;
        if (sgTitle.isNotEmpty) {
          final subGoalId = 'goal_${mainGoalId}_sub_$i';
          await db.insert('goals', {
            'id': subGoalId,
            'parentGoalId': mainGoalId,
            'title': sgTitle,
            'description': sg['description'],
            'goalType': sg['goalType'] ?? 'DAILY',
            'status': 'ACTIVE',
            'targetDate': sg['targetDate'],
            'progressCache': 0.0,
            'createdAt': nowMs + i,
            'updatedAt': nowMs + i,
          });

          final sgSteps = sg['steps'] as List<dynamic>? ?? [];
          for (var j = 0; j < sgSteps.length; j++) {
            final step = sgSteps[j];
            final stepTitle = step['title'] as String;
            if (stepTitle.isNotEmpty) {
              await db.insert('goal_steps', {
                'id': 'step_${subGoalId}_$j',
                'goalId': subGoalId,
                'title': stepTitle,
                'isCompleted': 0,
                'displayOrder': j,
                'createdAt': nowMs,
                'scheduledDate': step['scheduledDate'],
                'linkedRoutineId': step['linkedRoutineId'],
              });
            }
          }
        }
      }
    } else {
      // Save manual steps
      for (var i = 0; i < steps.length; i++) {
        final step = steps[i];
        final stepTitle = step['title'] as String;
        if (stepTitle.isNotEmpty) {
          await db.insert('goal_steps', {
            'id': 'step_${mainGoalId}_$i',
            'goalId': mainGoalId,
            'title': stepTitle,
            'isCompleted': 0,
            'displayOrder': i,
            'createdAt': nowMs,
            'scheduledDate': step['scheduledDate'],
            'linkedRoutineId': step['linkedRoutineId'],
          });
        }
      }
    }
  }
}
