import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v73_study_schema.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseV73 implements Database {
  final List<String> executedStatements = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    // Return empty table info so safeAddColumn adds columns
    if (sql.contains('PRAGMA table_info')) {
      return [];
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #execute) {
      return execute(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List<Object?>?
            : null,
      );
    }
    if (invocation.memberName == #rawQuery) {
      return rawQuery(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments.length > 1
            ? invocation.positionalArguments[1] as List<Object?>?
            : null,
      );
    }
    return null;
  }
}

void main() {
  group('Migration V73 Study Schema Tests', () {
    test('MigrationV73StudySchema creates study_active_session and migrates settings', () async {
      final migration = MigrationV73StudySchema();
      expect(migration.version, equals(73));

      final mockDb = MockDatabaseV73();
      await migration.up(mockDb);

      final sql = mockDb.executedStatements.join('\n');
      expect(sql, contains('study_active_session'));
      expect(sql, contains('study_konkur_mode'));
      expect(sql, contains("DELETE FROM app_settings WHERE key = 'module_konkur_enabled';"));
    });
  });
}
