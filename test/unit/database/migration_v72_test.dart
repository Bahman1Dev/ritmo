import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v72_cleanup.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseV72 implements Database {
  final List<String> executedStatements = [];

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
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
    return null;
  }
}

void main() {
  group('Migration V72 Cleanup Tests', () {
    test('MigrationV72Cleanup drops zones, zone_schedules & worship_seasons tables', () async {
      final migration = MigrationV72Cleanup();
      expect(migration.version, equals(72));

      final mockDb = MockDatabaseV72();
      await migration.up(mockDb);

      final sql = mockDb.executedStatements.join('\n');
      expect(sql, contains('DROP TABLE IF EXISTS zones'));
      expect(sql, contains('DROP TABLE IF EXISTS zone_schedules'));
      expect(sql, contains('DROP TABLE IF EXISTS worship_seasons'));
    });
  });
}
