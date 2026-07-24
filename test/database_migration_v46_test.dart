import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/database_helper.dart';
import 'package:ritmo/core/database/migration/migration_runner.dart';
import 'package:sqflite/sqflite.dart';

class MockMigrationDatabase implements Database {
  final List<String> executedSql = [];
  final Map<String, List<Map<String, dynamic>>> tables = {};

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    executedSql.add(sql);
    return [];
  }

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    executedSql.add('INSERT INTO $table');
    return 1;
  }

  @override
  Future<int> update(String table, Map<String, Object?> values, {String? where, List<Object?>? whereArgs, ConflictAlgorithm? conflictAlgorithm}) async {
    executedSql.add('UPDATE $table');
    return 1;
  }

  @override
  Future<int> delete(String table, {String? where, List<Object?>? whereArgs}) async {
    executedSql.add('DELETE FROM $table');
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('PR-4 Database Discipline & Migration v46 Tests', () {
    test('1. MigrationRunner executes migrations 42 through 46 in order', () async {
      final mockDb = MockMigrationDatabase();

      await MigrationRunner.run(mockDb, 41, 46);

      // Verify sql executions for v42 through v46
      final allSql = mockDb.executedSql.join('\n');
      expect(allSql.contains('chat_sessions'), true);
      expect(allSql.contains('chat_messages'), true);
      expect(allSql.contains('ai_memory'), true);
      expect(allSql.contains('day_plan_commits'), true);
      expect(allSql.contains('day_plan_templates'), true);
      expect(allSql.contains('reminderOffsetMinutes'), true);
      expect(allSql.contains('idx_perf_completions_routine_date'), true);
    });

    test('2. DatabaseHelper instance exists and initializes facade', () {
      expect(DatabaseHelper.instance, isNotNull);
    });
  });
}
