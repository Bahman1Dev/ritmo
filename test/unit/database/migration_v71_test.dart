import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v71_motivation_cognitive.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseV71 implements Database {
  final List<String> executedStatements = [];
  final List<Map<String, dynamic>> tableColumns = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    // Return empty table info so safeAddColumn proceeds to execute ALTER TABLE
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
  group('Migration V71 Tests', () {
    test('MigrationV71MotivationCognitive adds cognitiveLoad, firstPhysicalStep, temptationBundle, identityStatement, skipReason, masteryRating & pleasureRating', () async {
      final migration = MigrationV71MotivationCognitive();
      expect(migration.version, equals(71));

      final mockDb = MockDatabaseV71();
      await migration.up(mockDb);

      final sql = mockDb.executedStatements.join('\n');
      expect(sql, contains('ALTER TABLE routines ADD COLUMN cognitiveLoad TEXT'));
      expect(sql, contains('ALTER TABLE routines ADD COLUMN firstPhysicalStep TEXT'));
      expect(sql, contains('ALTER TABLE routines ADD COLUMN temptationBundle TEXT'));
      expect(sql, contains('ALTER TABLE goals ADD COLUMN identityStatement TEXT'));
      expect(sql, contains('ALTER TABLE routine_completions ADD COLUMN skipReason TEXT'));
      expect(sql, contains('ALTER TABLE routine_completions ADD COLUMN masteryRating INTEGER'));
      expect(sql, contains('ALTER TABLE routine_completions ADD COLUMN pleasureRating INTEGER'));
    });
  });
}
