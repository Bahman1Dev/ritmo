import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

class DayPlanTables {
  static Future<void> create(Database db) async {
    await ensureSchema(db);
  }

  /// Self-healing schema check for `day_plan_commits` and `day_plan_templates`.
  /// Ensures all required columns and indexes exist safely without crashing migrations.
  static Future<void> ensureSchema(Database db) async {
    try {
      // 1. Create day_plan_commits table with full schema if it does not exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS day_plan_commits (
          id TEXT PRIMARY KEY,
          date_iso TEXT NOT NULL,
          dateIso TEXT,
          plan_json TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0,
          updatedAt INTEGER NOT NULL DEFAULT 0,
          groupId TEXT
        );
      ''');

      // Add missing columns to existing day_plan_commits if table existed from an older version
      final pragmaCommits = await db.rawQuery("PRAGMA table_info('day_plan_commits');");
      final rawCommitCols = pragmaCommits.map((r) => r['name'] as String).toSet();
      final lowerCommitCols = rawCommitCols.map((n) => n.toLowerCase()).toSet();

      final commitAdditions = <String, String>{
        'date_iso': "TEXT NOT NULL DEFAULT ''",
        'dateIso': "TEXT",
        'groupId': "TEXT",
        'created_at': "INTEGER NOT NULL DEFAULT 0",
        'createdAt': "INTEGER NOT NULL DEFAULT 0",
        'updated_at': "INTEGER NOT NULL DEFAULT 0",
        'updatedAt': "INTEGER NOT NULL DEFAULT 0",
      };

      for (final entry in commitAdditions.entries) {
        if (!rawCommitCols.contains(entry.key) && !lowerCommitCols.contains(entry.key.toLowerCase())) {
          try {
            await db.execute('ALTER TABLE day_plan_commits ADD COLUMN ${entry.key} ${entry.value};');
          } catch (e) {
            debugPrint('[DAY_PLAN_TABLES] Note adding commit column ${entry.key}: $e');
          }
        }
      }

      // Safely create index for day_plan_commits
      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_day_plan_commits_date '
          'ON day_plan_commits(date_iso);',
        );
      } catch (e) {
        try {
          await db.execute(
            'CREATE INDEX IF NOT EXISTS idx_day_plan_commits_date '
            'ON day_plan_commits(dateIso);',
          );
        } catch (_) {}
      }

      // 2. Create day_plan_templates table if it does not exist
      await db.execute('''
        CREATE TABLE IF NOT EXISTS day_plan_templates (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          plan_json TEXT NOT NULL,
          created_at INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL DEFAULT 0,
          updated_at INTEGER NOT NULL DEFAULT 0,
          updatedAt INTEGER NOT NULL DEFAULT 0
        );
      ''');

      final pragmaTemplates = await db.rawQuery("PRAGMA table_info('day_plan_templates');");
      final rawTemplateCols = pragmaTemplates.map((r) => r['name'] as String).toSet();
      final lowerTemplateCols = rawTemplateCols.map((n) => n.toLowerCase()).toSet();

      final templateAdditions = <String, String>{
        'created_at': "INTEGER NOT NULL DEFAULT 0",
        'createdAt': "INTEGER NOT NULL DEFAULT 0",
        'updated_at': "INTEGER NOT NULL DEFAULT 0",
        'updatedAt': "INTEGER NOT NULL DEFAULT 0",
      };

      for (final entry in templateAdditions.entries) {
        if (!rawTemplateCols.contains(entry.key) && !lowerTemplateCols.contains(entry.key.toLowerCase())) {
          try {
            await db.execute('ALTER TABLE day_plan_templates ADD COLUMN ${entry.key} ${entry.value};');
          } catch (e) {
            debugPrint('[DAY_PLAN_TABLES] Note adding template column ${entry.key}: $e');
          }
        }
      }

      try {
        await db.execute(
          'CREATE INDEX IF NOT EXISTS idx_day_plan_templates_title '
          'ON day_plan_templates(title);',
        );
      } catch (_) {}

    } catch (e, st) {
      debugPrint('[DAY_PLAN_TABLES] Error in ensureSchema: $e\n$st');
    }
  }
}
