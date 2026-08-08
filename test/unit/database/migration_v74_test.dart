import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/migration/migrations/migration_v74_psych_layer_settings.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabaseV74 implements Database {
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
  group('Migration V74 Psych Layer Settings Tests', () {
    test('MigrationV74PsychLayerSettings inserts all 9 default settings keys', () async {
      final migration = MigrationV74PsychLayerSettings();
      expect(migration.version, equals(74));

      final mockDb = MockDatabaseV74();
      await migration.up(mockDb);

      final sql = mockDb.executedStatements.join('\n');
      expect(sql, contains('motivation_diagnosis_enabled'));
      expect(sql, contains('daily_budget_warning_enabled'));
      expect(sql, contains('wip_limit_enabled'));
      expect(sql, contains('wip_limit_count'));
      expect(sql, contains('cognitive_routing_enabled'));
      expect(sql, contains('fresh_start_enabled'));
      expect(sql, contains('capture_inbox_enabled'));
      expect(sql, contains('mastery_pleasure_sampling_enabled'));
      expect(sql, contains('mastery_decay_enabled'));
    });
  });
}
