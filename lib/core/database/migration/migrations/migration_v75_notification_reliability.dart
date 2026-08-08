import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV75NotificationReliability extends Migration {
  @override
  int get version => 75;

  @override
  Future<void> up(Database db) async {
    // 1. Column tracking native alarm registration success
    await safeAddColumn(db, 'pending_reminders', 'nativeScheduled', 'INTEGER DEFAULT 0');

    // 2. Per-routine user preference for full-screen alarm
    await safeAddColumn(db, 'routines', 'fullScreenAlarm', 'INTEGER DEFAULT 0');

    // 3. Unify snooze occurrence status ('rescheduled' -> 'snoozed')
    await db.rawUpdate(
      "UPDATE routine_occurrences SET status = 'snoozed' WHERE status = 'rescheduled'",
    );

    // 4. Delivery audit log table for reliability watchdog
    await db.execute('''
      CREATE TABLE IF NOT EXISTS alarm_delivery_log (
        id TEXT PRIMARY KEY,
        reminderId TEXT NOT NULL,
        routineId TEXT,
        expectedAt INTEGER NOT NULL,
        firedAt INTEGER,
        outcome TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      )
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_alarm_delivery_expected ON alarm_delivery_log(expectedAt)',
    );
  }

  @override
  Future<void> down(Database db) async {}
}
