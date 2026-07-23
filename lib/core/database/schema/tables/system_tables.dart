import 'package:sqflite/sqflite.dart';

class SystemTables {
  static Future<void> create(Database db) async {
    // 8. temporary_events table
    await db.execute('''
      CREATE TABLE temporary_events (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          date TEXT NOT NULL,
          startTime TEXT,
          endTime TEXT,
          durationMinutes INTEGER NOT NULL,
          isLocked INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_temporary_events_date ON temporary_events(date);');

    // 11. energy_logs table
    await db.execute('''
      CREATE TABLE energy_logs (
          id TEXT PRIMARY KEY,
          energyLevel TEXT NOT NULL,
          source TEXT NOT NULL DEFAULT 'MANUAL',
          note TEXT,
          loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_energy_logs_loggedAt ON energy_logs(loggedAt);');

    // 12. daily_rhythm table
    await db.execute('''
      CREATE TABLE daily_rhythm (
          date TEXT PRIMARY KEY,
          rhythmScore INTEGER NOT NULL DEFAULT 0,
          scheduledCount INTEGER NOT NULL DEFAULT 0,
          countedCount INTEGER NOT NULL DEFAULT 0,
          successCount INTEGER NOT NULL DEFAULT 0,
          essentialMet INTEGER NOT NULL DEFAULT 0,
          energyDrained INTEGER NOT NULL DEFAULT 0,
          energyRecharged INTEGER NOT NULL DEFAULT 0,
          lifeBalanceScore INTEGER NOT NULL DEFAULT 0,
          isGraceDay INTEGER NOT NULL DEFAULT 0,
          updatedAt INTEGER NOT NULL,
          rhythm_score INTEGER NOT NULL DEFAULT 0,
          total_routines INTEGER NOT NULL DEFAULT 0,
          completed_routines INTEGER NOT NULL DEFAULT 0,
          critical_routines INTEGER NOT NULL DEFAULT 0,
          completion_ratio REAL NOT NULL DEFAULT 0.0,
          UNIQUE(date)
      );
    ''');

    // 13. pending_reminders table
    await db.execute('''
      CREATE TABLE pending_reminders (
          id TEXT PRIMARY KEY,
          routineId TEXT,
          scheduleId TEXT,
          courseSessionId TEXT,
          originalTime INTEGER NOT NULL,
          scheduledTime INTEGER NOT NULL,
          state TEXT NOT NULL DEFAULT 'SCHEDULED',
          deferCount INTEGER NOT NULL DEFAULT 0,
          deferReason TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          snoozeUntil INTEGER,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE,
          FOREIGN KEY(scheduleId) REFERENCES routine_schedules(id) ON DELETE CASCADE,
          FOREIGN KEY(courseSessionId) REFERENCES course_sessions(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_pending_reminders_routineId ON pending_reminders(routineId);');
    await db.execute('CREATE INDEX index_pending_reminders_scheduleId ON pending_reminders(scheduleId);');
    await db.execute('CREATE INDEX index_pending_reminders_scheduledTime ON pending_reminders(scheduledTime);');
    await db.execute('CREATE UNIQUE INDEX index_pending_reminders_unique_slot ON pending_reminders(routineId, scheduleId, originalTime);');

    // 14. prayer_times_cache table
    await db.execute('''
      CREATE TABLE prayer_times_cache (
          date TEXT NOT NULL,
          cityId TEXT NOT NULL,
          fajr TEXT NOT NULL,
          sunrise TEXT NOT NULL,
          dhuhr TEXT NOT NULL,
          asr TEXT NOT NULL,
          maghrib TEXT NOT NULL,
          isha TEXT NOT NULL,
          midnightShari TEXT NOT NULL,
          sunset TEXT NOT NULL DEFAULT '',
          calculationMethod TEXT NOT NULL DEFAULT 'TEHRAN_GEOPHYSICS',
          ihtiyatMinutes INTEGER NOT NULL DEFAULT 10,
          computedAt INTEGER NOT NULL,
          PRIMARY KEY (date, cityId),
          FOREIGN KEY(cityId) REFERENCES iran_cities(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_prayer_times_cache_cityId ON prayer_times_cache(cityId);');

    // 15. iran_cities table (offline bundled seed data)
    await db.execute('''
      CREATE TABLE iran_cities (
          id TEXT PRIMARY KEY,
          province TEXT NOT NULL,
          city TEXT NOT NULL,
          latitude REAL NOT NULL,
          longitude REAL NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_iran_cities_province ON iran_cities(province);');

    // 16. app_settings table
    await db.execute('''
      CREATE TABLE app_settings (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');

    // 17. calendar_exceptions table
    await db.execute('''
      CREATE TABLE calendar_exceptions (
          date TEXT PRIMARY KEY,
          exceptionType TEXT NOT NULL,
          behavior TEXT NOT NULL DEFAULT 'NORMAL',
          title TEXT,
          isAutoGrace INTEGER NOT NULL DEFAULT 0,
          isUserDefined INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_calendar_exceptions_exceptionType ON calendar_exceptions(exceptionType);');

    // 18. active_timers table
    await db.execute('''
      CREATE TABLE active_timers (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          startedAt INTEGER NOT NULL,
          plannedDurationMinutes INTEGER NOT NULL,
          pausedAccumulatedMs INTEGER NOT NULL DEFAULT 0,
          state TEXT NOT NULL DEFAULT 'RUNNING',
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');

    // custom_categories table (V3 table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS custom_categories (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          icon TEXT NOT NULL,
          color TEXT NOT NULL,
          sortOrder INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          isArchived INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // milestones_unlocked table (V5 table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS milestones_unlocked (
          id TEXT PRIMARY KEY,
          unlockedAt INTEGER NOT NULL
      );
    ''');

    // bedtime_diagnostics (V2 table)
    await db.execute('''
      CREATE TABLE bedtime_diagnostics (
          date TEXT PRIMARY KEY,
          reason TEXT NOT NULL,
          note TEXT,
          createdAt INTEGER NOT NULL,
          bedtimeAt INTEGER,
          wakeAt INTEGER,
          durationMinutes INTEGER,
          quality INTEGER NOT NULL DEFAULT 3,
          awakenings INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // daily_checkins (V2 table)
    await db.execute('''
      CREATE TABLE daily_checkins (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL UNIQUE,
          mood TEXT NOT NULL,
          note TEXT,
          createdAt INTEGER NOT NULL
      );
    ''');

    // daily_reflections (V2 table)
    await db.execute('''
      CREATE TABLE daily_reflections (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL UNIQUE,
          goodThing TEXT,
          reflectionNote TEXT,
          mood_score INTEGER,
          reflection_text TEXT,
          learnings TEXT,
          gratitude TEXT,
          wins TEXT,
          challenges TEXT,
          tomorrowFocus TEXT,
          timestamp INTEGER,
          isPrivate INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL
      );
    ''');

    // notification_history (V2 table)
    await db.execute('''
      CREATE TABLE notification_history (
          id TEXT PRIMARY KEY,
          routineId TEXT,
          notificationType TEXT NOT NULL,
          sentAt INTEGER NOT NULL,
          actionTaken TEXT NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX index_notification_history_routineId ON notification_history(routineId);');

    // assistant_suggestions (V2 table)
    await db.execute('''
      CREATE TABLE assistant_suggestions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          suggestionType TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'PENDING',
          createdAt INTEGER NOT NULL
      );
    ''');

    // assistant_audit_log (V2 table)
    await db.execute('''
      CREATE TABLE assistant_audit_log (
          id TEXT PRIMARY KEY,
          actionType TEXT NOT NULL,
          targetKey TEXT,
          oldValue TEXT,
          newValue TEXT,
          appliedAt INTEGER NOT NULL
      );
    ''');

    // mood_logs (V17 table)
    await db.execute('''
      CREATE TABLE mood_logs (
          id TEXT PRIMARY KEY,
          mood TEXT NOT NULL,
          valence INTEGER NOT NULL DEFAULT 3,
          note TEXT,
          loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_mood_logs_loggedAt ON mood_logs(loggedAt);');

    // devices (V22 table)
    await db.execute('''
      CREATE TABLE devices (
          id TEXT PRIMARY KEY,
          deviceName TEXT,
          platform TEXT,
          model TEXT,
          firstSeenAt INTEGER,
          lastActiveAt INTEGER,
          isCurrent INTEGER DEFAULT 1
      );
    ''');

    // inbox_items (V26 table)
    await db.execute('''
      CREATE TABLE inbox_items (
        id TEXT PRIMARY KEY,
        category TEXT NOT NULL,
        sourceSystem TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT,
        priority INTEGER NOT NULL DEFAULT 0,
        linkModule TEXT,
        linkEntityId TEXT,
        linkAction TEXT,
        payloadJson TEXT,
        status TEXT NOT NULL DEFAULT 'UNREAD',
        createdAt INTEGER NOT NULL,
        readAt INTEGER,
        expiresAt INTEGER,
        dedupeKey TEXT
      );
    ''');
    await db.execute('CREATE INDEX idx_inbox_status ON inbox_items(status);');
    await db.execute('CREATE INDEX idx_inbox_createdAt ON inbox_items(createdAt);');
    await db.execute('CREATE UNIQUE INDEX idx_inbox_dedupe ON inbox_items(dedupeKey);');
  }
}
