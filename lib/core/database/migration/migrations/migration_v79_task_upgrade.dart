import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV79TaskUpgrade extends Migration {
  @override
  int get version => 79;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. New columns for simple_tasks
    for (final sql in [
      "ALTER TABLE simple_tasks ADD COLUMN isImportant INTEGER NOT NULL DEFAULT 0",
      "ALTER TABLE simple_tasks ADD COLUMN importantAt INTEGER",
    ]) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_simple_tasks_important ON simple_tasks(isImportant);',
    );

    // 2. task_steps table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_steps (
          id TEXT PRIMARY KEY,
          taskId TEXT NOT NULL,
          title TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          displayOrder INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          completedAt INTEGER
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_steps_task ON task_steps(taskId, displayOrder);',
    );

    // 3. task_attachments table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS task_attachments (
          id TEXT PRIMARY KEY,
          taskId TEXT NOT NULL,
          fileName TEXT NOT NULL,
          fileSizeBytes INTEGER NOT NULL DEFAULT 0,
          mimeType TEXT,
          localPath TEXT NOT NULL,
          createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_task_attachments_task ON task_attachments(taskId);',
    );

    // 4. Default settings keys
    const defaults = {
      'tasks_completion_sound_enabled': 'false',
      'tasks_confirm_delete': 'true',
      'daily_planning_nudge_enabled': 'false',
      'daily_planning_nudge_time': '08:30',
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
