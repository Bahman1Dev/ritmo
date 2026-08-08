import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

/// K17 — DB Migration v83: Calendar Upgrade
/// - Creates `day_marks` table for day exceptions (REST, TRAVEL, SPECIAL, NORMAL)
/// - Inserts default calendar settings into `app_settings`
class MigrationV83CalendarUpgrade extends Migration {
  @override
  int get version => 83;

  @override
  Future<void> up(Database db) async {
    // 1) day_marks table — for marking special days
    await db.execute('''
      CREATE TABLE IF NOT EXISTS day_marks (
          date TEXT PRIMARY KEY,
          kind TEXT NOT NULL DEFAULT 'NORMAL',
          note TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_day_marks_kind ON day_marks(kind);');

    // 2) Default calendar settings — ConflictAlgorithm.ignore preserves existing user prefs
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    const defaults = <String, String>{
      'calendar_default_scale': 'agenda',
      'calendar_show_tasks': 'true',
      'calendar_show_occasions': 'true',
      'calendar_show_hijri': 'true',
      'calendar_morning_brief_enabled': 'false',
      'calendar_morning_brief_time': '07:30',
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
  Future<void> down(Database db) async {
    // Intentionally empty — schema is additive only (rule 8)
  }
}
