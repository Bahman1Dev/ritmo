import 'package:sqflite/sqflite.dart';

class WorshipTables {
  static Future<void> create(Database db) async {
    // 19. worship_debts
    await db.execute('''
      CREATE TABLE worship_debts (
          id TEXT PRIMARY KEY,
          practiceId TEXT,
          sourceKind TEXT DEFAULT 'MANUAL',
          debtType TEXT NOT NULL,
          title TEXT NOT NULL,
          totalCount INTEGER NOT NULL,
          remainingCount INTEGER NOT NULL,
          dailyTarget INTEGER NOT NULL DEFAULT 0,
          autoCreated INTEGER NOT NULL DEFAULT 0,
          isArchived INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_worship_debts_debtType ON worship_debts(debtType);');
    await db.execute('CREATE INDEX idx_worship_debts_practiceId ON worship_debts(practiceId);');

    // 20. worship_seasons
    await db.execute('''
      CREATE TABLE worship_seasons (
          id TEXT PRIMARY KEY,
          seasonType TEXT NOT NULL,
          title TEXT NOT NULL,
          startDate TEXT NOT NULL,
          endDate TEXT NOT NULL,
          calendar TEXT NOT NULL DEFAULT 'HIJRI',
          behaviorJson TEXT,
          isActive INTEGER NOT NULL DEFAULT 1,
          createdAt INTEGER NOT NULL,
          priority_weight REAL NOT NULL DEFAULT 1.0,
          start_date TEXT,
          end_date TEXT,
          type TEXT DEFAULT 'custom',
          is_active INTEGER DEFAULT 1
      );
    ''');
    await db.execute('CREATE INDEX index_worship_seasons_startDate ON worship_seasons(startDate);');

    // 21. worship_practices (V12 table)
    await db.execute('''
      CREATE TABLE worship_practices (
          id TEXT PRIMARY KEY,
          practiceType TEXT NOT NULL,
          subType TEXT,
          title TEXT NOT NULL,
          dailyTarget INTEGER DEFAULT 1,
          dailyDone INTEGER DEFAULT 0,
          totalTarget INTEGER,
          totalDone INTEGER DEFAULT 0,
          reminderEnabled INTEGER DEFAULT 0,
          reminderTime TEXT,
          reminderOffsetMinutes INTEGER,
          deferCount INTEGER DEFAULT 0,
          lastDeferredUntil INTEGER,
          sortOrder INTEGER DEFAULT 0,
          isActive INTEGER DEFAULT 1,
          allowQada INTEGER DEFAULT 0,
          reminderFrequency TEXT DEFAULT 'DAILY',
          notes TEXT,
          dailyDoneDate TEXT,
          reminderAnchor TEXT DEFAULT 'NONE',
          reminderDaysOfWeek TEXT,
          reminderTimes TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX idx_wp_type ON worship_practices(practiceType);');
    await db.execute('CREATE INDEX idx_wp_active ON worship_practices(isActive);');

    // 22. fasting_debt (V19 table)
    await db.execute('''
      CREATE TABLE fasting_debt (
        id TEXT PRIMARY KEY,
        dateIso TEXT NOT NULL,
        daysOwed INTEGER NOT NULL DEFAULT 1,
        reason TEXT,
        isResolved INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER,
        updatedAt INTEGER
      );
    ''');

    // 23. worship_completions (V57 table)
    await db.execute('''
      CREATE TABLE worship_completions (
          id TEXT PRIMARY KEY,
          practiceId TEXT NOT NULL,
          dateStr TEXT NOT NULL,
          practiceType TEXT NOT NULL,
          resultType TEXT NOT NULL,
          countDone INTEGER NOT NULL DEFAULT 1,
          countTarget INTEGER,
          reason TEXT,
          loggedAt INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          UNIQUE(practiceId, dateStr)
      );
    ''');
    await db.execute('CREATE INDEX idx_worship_completions_date ON worship_completions(dateStr);');
    await db.execute('CREATE INDEX idx_worship_completions_practice ON worship_completions(practiceId, dateStr);');
  }
}
