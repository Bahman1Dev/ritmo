import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/domain/engines/progression_engine.dart';
import 'package:sqflite/sqflite.dart';

class ProgressionMockDatabase implements Database {
  final Map<String, Map<String, dynamic>> routines = {};

  @override
  Future<List<Map<String, Object?>>> query(
    String table, {
    bool? distinct,
    List<String>? columns,
    String? where,
    List<Object?>? whereArgs,
    String? groupBy,
    String? having,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    if (table == 'routines') {
      final id = whereArgs?.first as String?;
      if (id != null && routines.containsKey(id)) {
        return [routines[id]!];
      }
    }
    return [];
  }

  @override
  Future<int> update(
    String table,
    Map<String, Object?> values, {
    String? where,
    List<Object?>? whereArgs,
    ConflictAlgorithm? conflictAlgorithm,
  }) async {
    if (table == 'routines') {
      final id = whereArgs?.first as String?;
      if (id != null && routines.containsKey(id)) {
        // Merge the updated values
        routines[id] = {
          ...routines[id]!,
          ...values,
        };
        return 1;
      }
    }
    return 0;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('ProgressionEngine Tests', () {
    late ProgressionEngine engine;
    late ProgressionMockDatabase db;

    setUp(() {
      engine = ProgressionEngine();
      db = ProgressionMockDatabase();
    });

    test('currentTargetMinutes returns targetDurationMinutes if mode is NONE', () {
      final routine = {
        'progressionMode': 'NONE',
        'targetDurationMinutes': 20,
        'progressionCurrent': 10,
      };
      expect(engine.currentTargetMinutes(routine), 20);
    });

    test('currentTargetMinutes returns progressionCurrent if mode is DURATION_RAMP', () {
      final routine = {
        'progressionMode': 'DURATION_RAMP',
        'targetDurationMinutes': 20,
        'progressionCurrent': 15,
      };
      expect(engine.currentTargetMinutes(routine), 15);
    });

    test('currentTargetMinutes returns progressionStart fallback if progressionCurrent is 0', () {
      final routine = {
        'progressionMode': 'DURATION_RAMP',
        'targetDurationMinutes': 20,
        'progressionStart': 10,
        'progressionCurrent': 0,
      };
      expect(engine.currentTargetMinutes(routine), 10);
    });

    test('currentTargetMinutes returns targetDurationMinutes fallback if progressionCurrent and progressionStart are 0', () {
      final routine = {
        'progressionMode': 'DURATION_RAMP',
        'targetDurationMinutes': 20,
        'progressionStart': 0,
        'progressionCurrent': 0,
      };
      expect(engine.currentTargetMinutes(routine), 20);
    });

    test('onCompletion does nothing if mode is NONE', () async {
      db.routines['r1'] = {
        'id': 'r1',
        'progressionMode': 'NONE',
        'progressionStart': 10,
        'progressionTarget': 20,
        'progressionStep': 2,
        'progressionEveryN': 1,
        'progressionCurrent': 10,
        'progressionDoneSinceAdvance': 0,
      };

      await engine.onCompletion(db, 'r1');

      expect(db.routines['r1']!['progressionCurrent'], 10);
      expect(db.routines['r1']!['progressionDoneSinceAdvance'], 0);
    });

    test('onCompletion increments done count, and advances when it reaches everyN (DURATION_RAMP)', () async {
      db.routines['r1'] = {
        'id': 'r1',
        'progressionMode': 'DURATION_RAMP',
        'progressionStart': 10,
        'progressionTarget': 20,
        'progressionStep': 2,
        'progressionEveryN': 2,
        'progressionCurrent': 10,
        'progressionDoneSinceAdvance': 0,
      };

      // First completion: done goes from 0 to 1. everyN is 2, so current remains 10.
      await engine.onCompletion(db, 'r1');
      expect(db.routines['r1']!['progressionCurrent'], 10);
      expect(db.routines['r1']!['progressionDoneSinceAdvance'], 1);

      // Second completion: done goes from 1 to 2. 2 >= everyN (2), so current should go to 10 + 2 = 12. done resets to 0.
      await engine.onCompletion(db, 'r1');
      expect(db.routines['r1']!['progressionCurrent'], 12);
      expect(db.routines['r1']!['progressionDoneSinceAdvance'], 0);
    });

    test('onCompletion clamps progressionCurrent to target (DURATION_RAMP)', () async {
      db.routines['r1'] = {
        'id': 'r1',
        'progressionMode': 'DURATION_RAMP',
        'progressionStart': 10,
        'progressionTarget': 15,
        'progressionStep': 4,
        'progressionEveryN': 1,
        'progressionCurrent': 12,
        'progressionDoneSinceAdvance': 0,
      };

      // 12 + 4 = 16. Clamps to target (15).
      await engine.onCompletion(db, 'r1');
      expect(db.routines['r1']!['progressionCurrent'], 15);
    });

    test('onCompletion decrements progressionCurrent down to target (TIME_SHIFT)', () async {
      db.routines['r1'] = {
        'id': 'r1',
        'progressionMode': 'TIME_SHIFT',
        'progressionStart': 100, // e.g. minutes from midnight
        'progressionTarget': 80,
        'progressionStep': 15,
        'progressionEveryN': 1,
        'progressionCurrent': 100,
        'progressionDoneSinceAdvance': 0,
      };

      // First completion: 100 - 15 = 85.
      await engine.onCompletion(db, 'r1');
      expect(db.routines['r1']!['progressionCurrent'], 85);

      // Second completion: 85 - 15 = 70. Clamps to target (80).
      await engine.onCompletion(db, 'r1');
      expect(db.routines['r1']!['progressionCurrent'], 80);
    });
  });
}
