import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV69 extends Migration {
  @override
  int get version => 69;

  @override
  Future<void> up(Database db) async {
    // 1. occurrence_overrides table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS occurrence_overrides (
        id TEXT PRIMARY KEY,
        sourceType TEXT NOT NULL,
        sourceId TEXT NOT NULL,
        dateStr TEXT NOT NULL,
        timeOfDay TEXT,
        durationMinutes INTEGER,
        status TEXT,
        note TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    await db.execute('''
      CREATE UNIQUE INDEX IF NOT EXISTS idx_occ_override_unique
        ON occurrence_overrides (sourceType, sourceId, dateStr);
    ''');

    await db.execute('''
      CREATE INDEX IF NOT EXISTS idx_occ_override_date
        ON occurrence_overrides (dateStr);
    ''');

    // 2. Incremental columns
    await safeAddColumn(db, 'routines', 'defaultDurationMinutes', 'INTEGER');
    await safeAddColumn(db, 'routine_completions', 'actualStartMinutes', 'INTEGER');
    await safeAddColumn(db, 'routines', 'travelBeforeMinutes', 'INTEGER');
    await safeAddColumn(db, 'routines', 'travelAfterMinutes', 'INTEGER');

    // 3. Backfill defaultDurationMinutes from existing durationMinutes
    try {
      await db.execute('''
        UPDATE routines
        SET defaultDurationMinutes = durationMinutes
        WHERE durationMinutes IS NOT NULL AND durationMinutes > 0 AND defaultDurationMinutes IS NULL;
      ''');
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS occurrence_overrides;');
  }
}
