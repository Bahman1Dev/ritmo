import 'package:sqflite/sqflite.dart';

class ZoneTables {
  static Future<void> create(Database db) async {
    // 5. zones table
    await db.execute('''
      CREATE TABLE zones (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          color TEXT,
          icon TEXT,
          mode TEXT NOT NULL DEFAULT 'NORMAL',
          isDefault INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');

    // 6. zone_schedules table
    await db.execute('''
      CREATE TABLE zone_schedules (
          id TEXT PRIMARY KEY,
          zoneId TEXT NOT NULL,
          daysOfWeek TEXT NOT NULL,
          startTime TEXT NOT NULL,
          endTime TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(zoneId) REFERENCES zones(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_zone_schedules_zoneId ON zone_schedules(zoneId);');

    // 7. routine_zone_rules table
    await db.execute('''
      CREATE TABLE routine_zone_rules (
          routineId TEXT NOT NULL,
          zoneId TEXT NOT NULL,
          ruleType TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          PRIMARY KEY (routineId, zoneId),
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE,
          FOREIGN KEY(zoneId) REFERENCES zones(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_routine_zone_rules_zoneId ON routine_zone_rules(zoneId);');
  }
}
