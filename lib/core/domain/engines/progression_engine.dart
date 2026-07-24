import 'dart:math';

import 'package:ritmo/core/domain/models/completion_result.dart';
import 'package:sqflite/sqflite.dart';

class ProgressionEngine {
  int currentTargetMinutes(Map<String, dynamic> routine) {
    if (routine['progressionMode'] == 'NONE' || routine['progressionMode'] == null) {
      return routine['targetDurationMinutes'] as int? ?? 0;
    }
    final current = routine['progressionCurrent'] as int? ?? 0;
    if (current == 0) {
      final start = routine['progressionStart'] as int? ?? 0;
      if (start == 0) {
        return routine['targetDurationMinutes'] as int? ?? 0;
      }
      return start;
    }
    return current;
  }

  Future<void> onCompletion(DatabaseExecutor db, String routineId, [CompletionResult? result]) async {
    if (result != null && !result.advancesProgression) return;

    final List<Map<String, dynamic>> results = await db.query(
      'routines',
      where: 'id = ?',
      whereArgs: [routineId],
    );
    if (results.isEmpty) return;

    final routine = results.first;
    final mode = routine['progressionMode'] as String? ?? 'NONE';
    if (mode != 'NONE') {
      final step = routine['progressionStep'] as int? ?? 0;
      final target = routine['progressionTarget'] as int? ?? 0;
      final everyN = routine['progressionEveryN'] as int? ?? 1;
      
      var current = routine['progressionCurrent'] as int? ?? 0;
      var done = routine['progressionDoneSinceAdvance'] as int? ?? 0;

      done = done + 1;
      if (done >= everyN) {
        if (mode == 'DURATION_RAMP') {
          current = min(current + step, target);
        } else if (mode == 'TIME_SHIFT') {
          current = max(current - step, target);
        }
        done = 0;
      }

      await db.update(
        'routines',
        {
          'progressionCurrent': current,
          'progressionDoneSinceAdvance': done,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [routineId],
      );
    }
  }
}
