import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV67 extends Migration {
  @override
  int get version => 67;

  Future<bool> _columnExists(Database db, String table, String column) async {
    try {
      final info = await db.rawQuery('PRAGMA table_info($table)');
      return info.any((row) => row['name'] == column);
    } catch (_) {
      return false;
    }
  }

  @override
  Future<void> up(Database db) async {
    // 1. worship_practices: userDisabledAt
    if (!await _columnExists(db, 'worship_practices', 'userDisabledAt')) {
      await db.execute('ALTER TABLE worship_practices ADD COLUMN userDisabledAt TEXT;');
    }

    // 2. worship_completions: qualityWindow
    if (!await _columnExists(db, 'worship_completions', 'qualityWindow')) {
      await db.execute('ALTER TABLE worship_completions ADD COLUMN qualityWindow TEXT;');
    }

    // 3. worship_seasons: recurrence, dayList, hijriMonth
    if (!await _columnExists(db, 'worship_seasons', 'recurrence')) {
      await db.execute('ALTER TABLE worship_seasons ADD COLUMN recurrence TEXT;');
    }
    if (!await _columnExists(db, 'worship_seasons', 'dayList')) {
      await db.execute('ALTER TABLE worship_seasons ADD COLUMN dayList TEXT;');
    }
    if (!await _columnExists(db, 'worship_seasons', 'hijriMonth')) {
      await db.execute('ALTER TABLE worship_seasons ADD COLUMN hijriMonth INTEGER;');
    }

    // 4. prayer_times_cache: Iso full date-time columns
    final isoColumns = [
      'fajrIso', 'sunriseIso', 'dhuhrIso', 'asrIso',
      'maghribIso', 'sunsetIso', 'ishaIso', 'midnightShariIso'
    ];
    for (final col in isoColumns) {
      if (!await _columnExists(db, 'prayer_times_cache', col)) {
        await db.execute('ALTER TABLE prayer_times_cache ADD COLUMN $col TEXT;');
      }
    }

    // 5. worship_debts: sourcePracticeId
    if (!await _columnExists(db, 'worship_debts', 'sourcePracticeId')) {
      await db.execute('ALTER TABLE worship_debts ADD COLUMN sourcePracticeId TEXT;');
    }

    // 6. Table worship_day_context
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_day_context (
        date TEXT PRIMARY KEY,
        isTraveller INTEGER NOT NULL DEFAULT 0,
        fastingExempt INTEGER NOT NULL DEFAULT 0,
        prayerExempt INTEGER NOT NULL DEFAULT 0,
        reason TEXT,
        createdAt TEXT NOT NULL,
        updatedAt TEXT NOT NULL
      );
    ''');

    // Indexes
    await db.execute('CREATE INDEX IF NOT EXISTS idx_worship_day_context_date ON worship_day_context(date);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_worship_completions_date ON worship_completions(dateStr);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_worship_completions_practice_date ON worship_completions(practiceId, dateStr);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_app_settings_key ON app_settings(key);');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_worship_debts_source ON worship_debts(sourcePracticeId, debtType) WHERE isArchived = 0;');
  }

  @override
  Future<void> down(Database db) async {}
}
