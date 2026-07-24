import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/database/schema/tables/ai_tables.dart';
import 'package:ritmo/core/database/schema/tables/day_plan_tables.dart';
import 'package:sqflite/sqflite.dart';

class MockAiSchemaDb implements Database {
  final List<String> executedStatements = [];
  final List<Map<String, Object?>> pragmaColumns;

  MockAiSchemaDb({this.pragmaColumns = const []});

  @override
  Future<void> execute(String sql, [List<Object?>? arguments]) async {
    executedStatements.add(sql);
  }

  @override
  Future<List<Map<String, Object?>>> rawQuery(String sql, [List<Object?>? arguments]) async {
    if (sql.contains('PRAGMA table_info')) {
      return pragmaColumns;
    }
    return [];
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

void main() {
  group('Database Schema Self-Healing & Migration Safety Tests', () {
    test('1. AiTables.ensureSchema creates full ai_memory schema on empty DB', () async {
      final mockDb = MockAiSchemaDb();

      await AiTables.ensureSchema(mockDb);

      final allSql = mockDb.executedStatements.join('\n');
      expect(allSql.contains('CREATE TABLE IF NOT EXISTS ai_memory'), isTrue);
      expect(allSql.contains('createdAt INTEGER NOT NULL DEFAULT 0'), isTrue);
      expect(allSql.contains('updatedAt INTEGER NOT NULL DEFAULT 0'), isTrue);
      expect(allSql.contains('lastAccessedAt INTEGER NOT NULL DEFAULT 0'), isTrue);
      expect(allSql.contains('idx_ai_memory_created'), isTrue);
      expect(allSql.contains('createdAt DESC'), isTrue);
    });

    test('2. AiTables.ensureSchema self-heals old 5-column ai_memory schema by adding missing columns', () async {
      final legacyPragma = [
        {'name': 'id'},
        {'name': 'content'},
        {'name': 'category'},
        {'name': 'created_at'},
        {'name': 'updated_at'},
      ];

      final mockDb = MockAiSchemaDb(pragmaColumns: legacyPragma);

      await AiTables.ensureSchema(mockDb);

      final allSql = mockDb.executedStatements.join('\n');
      expect(allSql.contains('ALTER TABLE ai_memory ADD COLUMN type'), isTrue);
      expect(allSql.contains('ALTER TABLE ai_memory ADD COLUMN domain'), isTrue);
      expect(allSql.contains('ALTER TABLE ai_memory ADD COLUMN status'), isTrue);
      expect(allSql.contains('ALTER TABLE ai_memory ADD COLUMN createdAt'), isTrue);
      expect(allSql.contains('ALTER TABLE ai_memory ADD COLUMN updatedAt'), isTrue);
      expect(allSql.contains('ALTER TABLE ai_memory ADD COLUMN lastAccessedAt'), isTrue);
      expect(allSql.contains('DROP INDEX IF EXISTS idx_ai_memory_created'), isTrue);
      expect(allSql.contains('CREATE INDEX IF NOT EXISTS idx_ai_memory_created ON ai_memory(createdAt DESC)'), isTrue);
    });

    test('3. DayPlanTables.ensureSchema self-heals day_plan_commits schema safely', () async {
      final mockDb = MockAiSchemaDb();

      await DayPlanTables.ensureSchema(mockDb);

      final allSql = mockDb.executedStatements.join('\n');
      expect(allSql.contains('CREATE TABLE IF NOT EXISTS day_plan_commits'), isTrue);
      expect(allSql.contains('date_iso TEXT NOT NULL'), isTrue);
      expect(allSql.contains('CREATE INDEX IF NOT EXISTS idx_day_plan_commits_date'), isTrue);
      expect(allSql.contains('CREATE TABLE IF NOT EXISTS day_plan_templates'), isTrue);
    });
  });
}
