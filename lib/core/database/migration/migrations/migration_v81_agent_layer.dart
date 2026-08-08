import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV81AgentLayer extends Migration {
  @override
  int get version => 81;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. Add new columns to assistant_audit_log safely
    for (final sql in [
      "ALTER TABLE assistant_audit_log ADD COLUMN assistantId TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN personaId TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN planId TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN commandId TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN payloadJson TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN inverseJson TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN status TEXT",
      "ALTER TABLE assistant_audit_log ADD COLUMN undoneAt INTEGER",
    ]) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    // 2. Create index on planId for auditing
    try {
      await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_assistant_audit_log_planId ON assistant_audit_log(planId);',
      );
    } catch (_) {}

    // 3. Create assistant_plans table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_plans (
        id TEXT PRIMARY KEY,
        titleFa TEXT NOT NULL,
        personaId TEXT NOT NULL,
        stepCount INTEGER NOT NULL,
        status TEXT NOT NULL,          -- previewed | applied | undone | failed
        createdAt INTEGER NOT NULL,
        appliedAt INTEGER,
        undoneAt INTEGER
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_assistant_plans_createdAt ON assistant_plans(createdAt);',
    );

    // 3b. Create konkur_plans table to fix database crash/discrepancy
    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_plans (
        id TEXT PRIMARY KEY,
        topicName TEXT NOT NULL,
        plannedMinutes INTEGER NOT NULL DEFAULT 60,
        createdAt INTEGER NOT NULL
      );
    ''');

    // 4. Default settings keys
    final defaults = {
      'ai_agent_mode': 'confirm',
      'ai_undo_window_hours': '24',
      'ai_domain_cycle_write': 'false',
      'ai_domain_cycle_read': 'false',
      'ai_domain_medical_read': 'false',
      'ai_domain_reflection_read': 'false',
    };

    for (final e in defaults.entries) {
      await db.insert(
        'app_settings',
        {'key': e.key, 'value': e.value, 'updatedAt': nowMs},
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {}
}
