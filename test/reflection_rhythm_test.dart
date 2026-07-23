import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/services/snapshot_sync_service.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final List<String> executedStatements = [];
  final List<Map<String, dynamic>> insertedRows = [];
  final Map<String, List<Map<String, dynamic>>> queryResponses = {};

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    insertedRows.add({
      'table': table,
      'values': values,
      'conflictAlgorithm': conflictAlgorithm,
    });
    return 1;
  }

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
    if (table == 'daily_rhythm' && whereArgs != null && whereArgs.isNotEmpty) {
      final date = whereArgs.first! as String;
      if (date == '2026-06-20') {
        return [{'date': '2026-06-20'}];
      } else {
        return []; // Missing!
      }
    }
    return queryResponses[table] ?? [];
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('MIN(completionDate)')) {
      return [{'minDate': '2026-06-20'}];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('Ritmo Phase 3 — Database Migration v6 Tests', () {
    test('onUpgrade to v6 adds new columns to daily_reflections and daily_rhythm', () async {
      final mockDb = MockDatabase();
      await DatabaseHelper.instance.onUpgrade(mockDb, 5, 6);

      final allExecutedSql = mockDb.executedStatements.join('\n').toLowerCase();
      
      // Check reflection columns
      expect(allExecutedSql, contains('mood_score'));
      expect(allExecutedSql, contains('reflection_text'));
      expect(allExecutedSql, contains('learnings'));
      expect(allExecutedSql, contains('timestamp'));

      // Check rhythm columns
      expect(allExecutedSql, contains('rhythm_score'));
      expect(allExecutedSql, contains('total_routines'));
      expect(allExecutedSql, contains('completed_routines'));
      expect(allExecutedSql, contains('critical_routines'));
      expect(allExecutedSql, contains('completion_ratio'));
    });
  });

  group('Ritmo Phase 3 — Daily Rhythm Sync & Backfill Tests', () {
    test('syncDailyRhythmForDate calculates rhythm score and ratio correctly', () async {
      final mockDb = MockDatabase();

      // Mock routines and schedules
      mockDb.queryResponses['routines'] = [
        {'id': 'r1', 'priority': 1.0, 'routineType': 'timeBased', 'isEssential': 1, 'category': 'custom'},
        {'id': 'r2', 'priority': 2.0, 'routineType': 'timeBased', 'isEssential': 0, 'category': 'custom'},
      ];
      mockDb.queryResponses['routine_schedules'] = [
        {'routineId': 'r1'},
        {'routineId': 'r2'},
      ];

      // Mock completions for 2026-06-21: only r1 is completed
      mockDb.queryResponses['routine_completions'] = [
        {'routineId': 'r1', 'completionDate': '2026-06-21', 'resultType': 'FULL'},
      ];

      await SnapshotSyncService.syncDailyRhythmForDate(mockDb, '2026-06-21', {});

      expect(mockDb.insertedRows.length, 1);
      final row = mockDb.insertedRows.first;
      expect(row['table'], 'daily_rhythm');
      final values = row['values'] as Map<String, dynamic>;
      expect(values['date'], '2026-06-21');
      expect(values['total_routines'], 2);
      expect(values['completed_routines'], 1);
      expect(values['critical_routines'], 1);
      expect(values['rhythm_score'], 33); // 1.0 / (1.0 + 2.0) * 100 = 33%
      expect(values['completion_ratio'], 0.5); // 1 / 2 = 0.5
      expect(row['conflictAlgorithm'], ConflictAlgorithm.replace);
    });

    test('backfillRhythmLogs identifies missing days and fills them', () async {
      final mockDb = MockDatabase();

      // Mock routines and schedules
      mockDb.queryResponses['routines'] = [
        {'id': 'r1', 'priority': 1.0, 'routineType': 'timeBased', 'isEssential': 1, 'category': 'custom'},
      ];
      mockDb.queryResponses['routine_schedules'] = [
        {'routineId': 'r1'},
      ];

      // Earliest completion is 2026-06-20 (from rawQuery mock)
      // Suppose today is 2026-06-22.
      // Dates to check: 2026-06-20 (already exists, returns [{'date': '2026-06-20'}])
      // 2026-06-21 (missing, returns empty list from MockDatabase.query)
      // Today is 2026-06-22 (not backfilled by backfillRhythmLogs, handled by syncAll instead)

      await SnapshotSyncService.backfillRhythmLogs(mockDb, {});

      // Verify that syncDailyRhythmForDate was called only for 2026-06-21 (the missing day)
      // and it inserted the rhythm row for 2026-06-21.
      final backfilledRows = mockDb.insertedRows.where((r) => r['values']['date'] == '2026-06-21').toList();
      expect(backfilledRows.length, 1);

      final row20 = mockDb.insertedRows.where((r) => r['values']['date'] == '2026-06-20').toList();
      expect(row20.isEmpty, true); // Already existed, so it was skipped.
    });
  });
}
