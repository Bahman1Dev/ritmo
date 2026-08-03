import 'package:sqflite/sqflite.dart';

class RoutineTables {
  static Future<void> create(Database db) async {
    // 1. routines table
    await db.execute('''
      CREATE TABLE routines (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          routineType TEXT NOT NULL,
          notificationLevel TEXT NOT NULL,
          isEssential INTEGER NOT NULL DEFAULT 0,
          energyRule TEXT NOT NULL DEFAULT 'NONE',
          priority REAL NOT NULL DEFAULT 1.0,
          targetDurationMinutes INTEGER,
          lightDurationMinutes INTEGER,
          minimalDurationMinutes INTEGER,
          energyImpact INTEGER NOT NULL DEFAULT 0,
          dependsOnRoutineId TEXT,
          dependencyType TEXT,
          dependencyOffsetMinutes INTEGER,
          dependencyWindowMinutes INTEGER,
          isArchived INTEGER NOT NULL DEFAULT 0,
          isPrivate INTEGER NOT NULL DEFAULT 0,
          medStockCount INTEGER NOT NULL DEFAULT 0,
          medRefillThreshold INTEGER NOT NULL DEFAULT 0,
          minIntervalHours INTEGER NOT NULL DEFAULT 0,
          maxDosesPerDay INTEGER NOT NULL DEFAULT 0,
          displayOrder INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          isEssentialLocked INTEGER NOT NULL DEFAULT 0,
          customCategoryId TEXT,
          zoneId TEXT,
          progressionMode TEXT NOT NULL DEFAULT 'NONE',
          progressionStart INTEGER NOT NULL DEFAULT 0,
          progressionTarget INTEGER NOT NULL DEFAULT 0,
          progressionStep INTEGER NOT NULL DEFAULT 0,
          progressionEveryN INTEGER NOT NULL DEFAULT 1,
          progressionCurrent INTEGER NOT NULL DEFAULT 0,
          progressionDoneSinceAdvance INTEGER NOT NULL DEFAULT 0,
          itemType TEXT NOT NULL DEFAULT 'ROUTINE',
          reminderOffsetMinutes INTEGER DEFAULT 0,
          FOREIGN KEY(dependsOnRoutineId) REFERENCES routines(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX index_routines_dependsOnRoutineId ON routines(dependsOnRoutineId);');
    await db.execute('CREATE INDEX index_routines_category ON routines(category);');

    // 2. routine_schedules table
    await db.execute('''
      CREATE TABLE routine_schedules (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          scheduleType TEXT NOT NULL,
          timeOfDay TEXT,
          anchorEvent TEXT,
          anchorOffsetMinutes INTEGER,
          windowEndAnchor TEXT,
          escalationLeadMinutes INTEGER,
          escalationPolicy TEXT NOT NULL DEFAULT 'NONE',
          daysOfWeek TEXT,
          intervalHours INTEGER,
          targetCount INTEGER,
          startDate TEXT,
          stepValueMinutes INTEGER NOT NULL DEFAULT 0,
          targetTimeOfDay TEXT,
          currentStepOffsetMinutes INTEGER NOT NULL DEFAULT 0,
          advanceAfterSuccessDays INTEGER NOT NULL DEFAULT 2,
          regressOnFailure INTEGER NOT NULL DEFAULT 1,
          recurrenceRule TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_routine_schedules_routineId ON routine_schedules(routineId);');

    // 3. routine_completions table
    await db.execute('''
      CREATE TABLE routine_completions (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          completionDate TEXT NOT NULL,
          completionTime INTEGER NOT NULL,
          resultType TEXT NOT NULL,
          resultSource TEXT NOT NULL DEFAULT 'USER',
          debtId TEXT,
          durationMinutes INTEGER,
          delayMinutes INTEGER,
          note TEXT,
          actual_duration_minutes INTEGER,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_routine_completions_routineId ON routine_completions(routineId);');
    await db.execute('CREATE INDEX index_routine_completions_completionDate ON routine_completions(completionDate);');

    // 4. routine_occurrences table
    await db.execute('''
      CREATE TABLE routine_occurrences (
          routine_id TEXT NOT NULL,
          date TEXT NOT NULL,
          scheduled_time TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          PRIMARY KEY (routine_id, date),
          FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_routine_occurrences_routine_id ON routine_occurrences(routine_id);');
    await db.execute('CREATE INDEX index_routine_occurrences_date ON routine_occurrences(date);');

    // 5. routine_logs table
    await db.execute('''
      CREATE TABLE routine_logs (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          completionId TEXT,
          content TEXT NOT NULL,
          templateType TEXT,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE,
          FOREIGN KEY(completionId) REFERENCES routine_completions(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX index_routine_logs_routineId ON routine_logs(routineId);');
    await db.execute('CREATE INDEX index_routine_logs_completionId ON routine_logs(completionId);');

    // 6. routine_actual_completions view for analytics
    await db.execute('''
      CREATE VIEW IF NOT EXISTS routine_actual_completions AS
      SELECT * FROM routine_completions
      WHERE resultType IN ('FULL', 'PARTIAL', 'MINIMAL', 'DONE', 'LIGHT', 'COMPLETED');
    ''');
  }
}
