import 'package:sqflite/sqflite.dart';

class MigrationV70EngineIndexes {
  static Future<void> migrate(Database db) async {
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_routine_completions_date ON routine_completions(completionDate);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_routine_occurrences_date ON routine_occurrences(date);');
    await db.execute(
        'CREATE INDEX IF NOT EXISTS idx_energy_logs_logged_at ON energy_logs(loggedAt);');
  }
}
