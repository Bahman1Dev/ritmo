import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV76SimpleMode extends Migration {
  @override
  int get version => 76;

  @override
  Future<void> up(Database db) async {
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    // 1. CREATE TABLE simple_tasks
    await db.execute('''
      CREATE TABLE IF NOT EXISTS simple_tasks (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          note TEXT,
          isDone INTEGER NOT NULL DEFAULT 0,
          doneAt INTEGER,
          dueDate TEXT,
          dueTime TEXT,
          reminderAtMs INTEGER,
          reminderId TEXT,
          linkedRoutineId TEXT,
          orderIndex INTEGER NOT NULL DEFAULT 0,
          origin TEXT NOT NULL DEFAULT 'SIMPLE',
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_simple_tasks_isDone ON simple_tasks(isDone);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_simple_tasks_dueDate ON simple_tasks(dueDate);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_simple_tasks_order ON simple_tasks(orderIndex);');

    // 2. Default app_settings
    final defaults = {
      'app_mode': 'SIMPLE',
      'simple_tasks_seen_hint': 'false',
      'snooze_quota_enabled': 'false',
      'identity_gender_asked': 'false',
      'identity_age_asked': 'false',
    };

    for (final entry in defaults.entries) {
      await db.execute('''
        INSERT OR IGNORE INTO app_settings (key, value, updatedAt)
        VALUES ('${entry.key}', '${entry.value}', $nowMs);
      ''');
    }

    // Existing user migration: if onboarding_completed == 'true', app_mode -> 'FULL'
    final onboardingRows = await db.query(
      'app_settings',
      where: "key = 'onboarding_completed'",
      limit: 1,
    );
    if (onboardingRows.isNotEmpty && onboardingRows.first['value'] == 'true') {
      await db.execute('''
        UPDATE app_settings
        SET value = 'FULL', updatedAt = $nowMs
        WHERE key = 'app_mode';
      ''');
    }
  }

  @override
  Future<void> down(Database db) async {}
}
