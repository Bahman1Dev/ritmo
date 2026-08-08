import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV73StudySchema extends Migration {
  @override
  int get version => 73;

  @override
  Future<void> up(Database db) async {
    // 1. Add columns to konkur_subjects, konkur_topics, konkur_study_sessions
    await safeAddColumn(db, 'konkur_subjects', 'origin', "TEXT NOT NULL DEFAULT 'USER'");
    await safeAddColumn(db, 'konkur_subjects', 'emoji', 'TEXT');
    await safeAddColumn(db, 'konkur_subjects', 'weeklyTargetMinutes', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'konkur_topics', 'origin', "TEXT NOT NULL DEFAULT 'USER'");

    await safeAddColumn(db, 'konkur_study_sessions', 'startedAtMs', 'INTEGER');
    await safeAddColumn(db, 'konkur_study_sessions', 'endedAtMs', 'INTEGER');
    await safeAddColumn(db, 'konkur_study_sessions', 'source', "TEXT NOT NULL DEFAULT 'MANUAL'");
    await safeAddColumn(db, 'konkur_study_sessions', 'quality', 'INTEGER');

    // 2. Create study_active_session table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS study_active_session (
        id TEXT PRIMARY KEY CHECK (id = 'singleton'),
        subjectId TEXT,
        topicId TEXT,
        mode TEXT NOT NULL DEFAULT 'LEARN',
        startedAtMs INTEGER NOT NULL,
        accumulatedSeconds INTEGER NOT NULL DEFAULT 0,
        isPaused INTEGER NOT NULL DEFAULT 0,
        plannedMinutes INTEGER,
        createdAt INTEGER NOT NULL
      );
    ''');

    // 3. Mark existing presets
    await db.execute("UPDATE konkur_subjects SET origin = 'KONKUR_PRESET' WHERE isPreset = 1;");
    await db.execute("UPDATE konkur_topics SET origin = 'KONKUR_PRESET' WHERE subjectId IN (SELECT id FROM konkur_subjects WHERE isPreset = 1);");

    // 4. Migrate settings keys
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    await db.execute('''
      INSERT OR REPLACE INTO app_settings (key, value, updatedAt)
      SELECT 'study_konkur_mode', 'true', $nowMs
      WHERE EXISTS (
        SELECT 1 FROM app_settings WHERE key = 'module_konkur_enabled' AND value = 'true'
      );
    ''');

    await db.execute('''
      INSERT OR REPLACE INTO app_settings (key, value, updatedAt)
      SELECT 'study_konkur_setup_done', value, $nowMs
      FROM app_settings WHERE key = 'konkur_setup_done';
    ''');

    await db.execute("DELETE FROM app_settings WHERE key = 'module_konkur_enabled';");
  }

  @override
  Future<void> down(Database db) async {}
}
