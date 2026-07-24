import 'package:sqflite/sqflite.dart';

class DayPlanTables {
  static Future<void> create(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS day_plan_commits (
        id TEXT PRIMARY KEY,
        date_iso TEXT NOT NULL,
        plan_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        groupId TEXT
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_day_plan_commits_date '
      'ON day_plan_commits(date_iso);',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS day_plan_templates (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        plan_json TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_day_plan_templates_title '
      'ON day_plan_templates(title);',
    );
  }
}
