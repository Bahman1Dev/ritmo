import 'package:sqflite/sqflite.dart';

class CycleTables {
  static Future<void> create(Database db) async {
    // 22. cycle_logs (V2 table)
    await db.execute('''
      CREATE TABLE cycle_logs (
          id TEXT PRIMARY KEY,
          cycleStartDate TEXT NOT NULL,
          cycleEndDate TEXT,
          phase TEXT,
          flowLevel TEXT,
          symptomsJson TEXT,
          isPredicted INTEGER NOT NULL DEFAULT 0,
          suppressedPrayer INTEGER NOT NULL DEFAULT 1,
          fastDebtCreated INTEGER NOT NULL DEFAULT 0,
          note TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_cycle_logs_cycleStartDate ON cycle_logs(cycleStartDate);');

    // V14 cycle_periods table
    await db.execute('''
      CREATE TABLE cycle_periods (
          id TEXT PRIMARY KEY,
          startDate TEXT NOT NULL,
          endDate TEXT,
          flowIntensity TEXT DEFAULT 'MEDIUM',
          isPredicted INTEGER DEFAULT 0,
          note TEXT,
          createdAt INTEGER,
          updatedAt INTEGER
      );
    ''');

    // V14 cycle_day_logs table
    await db.execute('''
      CREATE TABLE cycle_day_logs (
          id TEXT PRIMARY KEY,
          logDate TEXT NOT NULL UNIQUE,
          flowLevel TEXT,
          symptomsJson TEXT,
          mood TEXT,
          energyTag TEXT,
          note TEXT,
          createdAt INTEGER,
          updatedAt INTEGER
      );
    ''');
  }
}
