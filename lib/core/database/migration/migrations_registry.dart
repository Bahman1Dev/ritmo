import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:ritmo/core/database/migration/migration_interface.dart';
import 'package:ritmo/core/database/schema/tables/ai_tables.dart';
import 'package:ritmo/core/database/schema/tables/day_plan_tables.dart';
import 'package:ritmo/core/database/schema/tables/supplementary_sports_tables.dart';
import 'package:ritmo/core/database/seed/seed_service.dart';
import 'package:ritmo/core/domain/models/duration_bounds.dart';
import 'package:ritmo/core/time/ritmo_clock.dart';
import 'package:sqflite/sqflite.dart';

class MigrationV2 extends Migration {
  @override
  int get version => 2;

  @override
  Future<void> up(Database db) async {
    // 19. worship_debts
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_debts (
          id TEXT PRIMARY KEY,
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
    await db.execute('CREATE INDEX IF NOT EXISTS index_worship_debts_debtType ON worship_debts(debtType);');

    // 20. worship_seasons
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_seasons (
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
    await db.execute('CREATE INDEX IF NOT EXISTS index_worship_seasons_startDate ON worship_seasons(startDate);');

    // 21. prn_logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS prn_logs (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          takenAt INTEGER NOT NULL,
          dosage TEXT,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_prn_logs_routineId ON prn_logs(routineId);');
    await db.execute('CREATE INDEX IF NOT EXISTS index_prn_logs_takenAt ON prn_logs(takenAt);');

    // 22. cycle_logs
    await db.execute('''
      CREATE TABLE IF NOT EXISTS cycle_logs (
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
    await db.execute('CREATE INDEX IF NOT EXISTS index_cycle_logs_cycleStartDate ON cycle_logs(cycleStartDate);');

    // 23. konkur_subjects
    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_subjects (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          importanceFactor REAL NOT NULL DEFAULT 1.0,
          progressPercentage REAL NOT NULL DEFAULT 0.0,
          isArchived INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          subjectGroup TEXT NOT NULL DEFAULT 'SPECIALIZED',
          examQuestionCount INTEGER NOT NULL DEFAULT 0,
          orderIndex INTEGER NOT NULL DEFAULT 0,
          colorHex TEXT,
          isPreset INTEGER NOT NULL DEFAULT 0
      );
    ''');

    // 24. konkur_topics
    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_topics (
          id TEXT PRIMARY KEY,
          subjectId TEXT NOT NULL,
          parentTopicId TEXT,
          name TEXT NOT NULL,
          progressPercentage REAL NOT NULL DEFAULT 0.0,
          studyTargetMinutes INTEGER NOT NULL DEFAULT 0,
          studyCompletedMinutes INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          examQuestionCount INTEGER NOT NULL DEFAULT 0,
          masteryLevel TEXT NOT NULL DEFAULT 'NOT_STARTED',
          lastStudiedAt INTEGER,
          nextReviewDate TEXT,
          plannedDate TEXT,
          orderIndex INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(subjectId) REFERENCES konkur_subjects(id) ON DELETE CASCADE,
          FOREIGN KEY(parentTopicId) REFERENCES konkur_topics(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_topics_subjectId ON konkur_topics(subjectId);');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_topics_parentTopicId ON konkur_topics(parentTopicId);');

    // 25. konkur_mock_exams
    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_mock_exams (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          examDate TEXT NOT NULL,
          createdAt INTEGER NOT NULL,
          provider TEXT,
          note TEXT
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_mock_exams_examDate ON konkur_mock_exams(examDate);');

    // 26. konkur_mock_exam_results
    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_mock_exam_results (
          id TEXT PRIMARY KEY,
          mockExamId TEXT NOT NULL,
          subjectId TEXT NOT NULL,
          percentage REAL NOT NULL,
          correctAnswers INTEGER NOT NULL DEFAULT 0,
          wrongAnswers INTEGER NOT NULL DEFAULT 0,
          emptyAnswers INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          totalQuestions INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(mockExamId) REFERENCES konkur_mock_exams(id) ON DELETE CASCADE,
          FOREIGN KEY(subjectId) REFERENCES konkur_subjects(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_mock_exam_results_mockExamId ON konkur_mock_exam_results(mockExamId);');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_mock_exam_results_subjectId ON konkur_mock_exam_results(subjectId);');

    // 27. goals
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goals (
          id TEXT PRIMARY KEY,
          parentGoalId TEXT,
          title TEXT NOT NULL,
          description TEXT,
          goalType TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          targetDate TEXT,
          progressCache REAL NOT NULL DEFAULT 0,
          isPrivate INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(parentGoalId) REFERENCES goals(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_goals_parentGoalId ON goals(parentGoalId);');

    // 28. goal_steps
    await db.execute('''
      CREATE TABLE IF NOT EXISTS goal_steps (
          id TEXT PRIMARY KEY,
          goalId TEXT NOT NULL,
          title TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          displayOrder INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          scheduledDate TEXT,
          linkedRoutineId TEXT,
          FOREIGN KEY(goalId) REFERENCES goals(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_goal_steps_goalId ON goal_steps(goalId);');

    // 29. bedtime_diagnostics
    await db.execute('''
      CREATE TABLE IF NOT EXISTS bedtime_diagnostics (
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

    // 30. daily_checkins
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_checkins (
          id TEXT PRIMARY KEY,
          date TEXT NOT NULL UNIQUE,
          mood TEXT NOT NULL,
          note TEXT,
          createdAt INTEGER NOT NULL
      );
    ''');

    // 31. daily_reflections
    await db.execute('''
      CREATE TABLE IF NOT EXISTS daily_reflections (
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

    // 33. notification_history
    await db.execute('''
      CREATE TABLE IF NOT EXISTS notification_history (
          id TEXT PRIMARY KEY,
          routineId TEXT,
          notificationType TEXT NOT NULL,
          sentAt INTEGER NOT NULL,
          actionTaken TEXT NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_notification_history_routineId ON notification_history(routineId);');

    // 34. assistant_suggestions
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_suggestions (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          body TEXT NOT NULL,
          suggestionType TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'PENDING',
          createdAt INTEGER NOT NULL
      );
    ''');

    // 35. assistant_audit_log
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_audit_log (
          id TEXT PRIMARY KEY,
          actionType TEXT NOT NULL,
          targetKey TEXT,
          oldValue TEXT,
          newValue TEXT,
          appliedAt INTEGER NOT NULL
      );
    ''');

    // assistant_chats (V2 legacy table)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_chats (
          id TEXT PRIMARY KEY,
          title TEXT,
          createdAt INTEGER NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS worship_debts;');
    await db.execute('DROP TABLE IF EXISTS worship_seasons;');
    await db.execute('DROP TABLE IF EXISTS prn_logs;');
    await db.execute('DROP TABLE IF EXISTS cycle_logs;');
    await db.execute('DROP TABLE IF EXISTS konkur_subjects;');
    await db.execute('DROP TABLE IF EXISTS konkur_topics;');
    await db.execute('DROP TABLE IF EXISTS konkur_mock_exams;');
    await db.execute('DROP TABLE IF EXISTS konkur_mock_exam_results;');
    await db.execute('DROP TABLE IF EXISTS goals;');
    await db.execute('DROP TABLE IF EXISTS goal_steps;');
    await db.execute('DROP TABLE IF EXISTS bedtime_diagnostics;');
    await db.execute('DROP TABLE IF EXISTS daily_checkins;');
    await db.execute('DROP TABLE IF EXISTS daily_reflections;');
    await db.execute('DROP TABLE IF EXISTS notification_history;');
    await db.execute('DROP TABLE IF EXISTS assistant_suggestions;');
    await db.execute('DROP TABLE IF EXISTS assistant_audit_log;');
    await db.execute('DROP TABLE IF EXISTS assistant_chats;');
  }
}

class MigrationV3 extends Migration {
  @override
  int get version => 3;

  @override
  Future<void> up(Database db) async {
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
    await safeAddColumn(db, 'routines', 'isEssentialLocked', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'routines', 'customCategoryId', 'TEXT');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS custom_categories;');
  }
}

class MigrationV4 extends Migration {
  @override
  int get version => 4;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'routines', 'zoneId', 'TEXT');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV5 extends Migration {
  @override
  int get version => 5;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS milestones_unlocked (
          id TEXT PRIMARY KEY,
          unlockedAt INTEGER NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS milestones_unlocked;');
  }
}

class MigrationV6 extends Migration {
  @override
  int get version => 6;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'daily_reflections', 'mood_score', 'INTEGER');
    await safeAddColumn(db, 'daily_reflections', 'reflection_text', 'TEXT');
    await safeAddColumn(db, 'daily_reflections', 'learnings', 'TEXT');
    await safeAddColumn(db, 'daily_reflections', 'timestamp', 'INTEGER');

    await safeAddColumn(db, 'daily_rhythm', 'rhythm_score', 'INTEGER DEFAULT 0');
    await safeAddColumn(db, 'daily_rhythm', 'total_routines', 'INTEGER DEFAULT 0');
    await safeAddColumn(db, 'daily_rhythm', 'completed_routines', 'INTEGER DEFAULT 0');
    await safeAddColumn(db, 'daily_rhythm', 'critical_routines', 'INTEGER DEFAULT 0');
    await safeAddColumn(db, 'daily_rhythm', 'completion_ratio', 'REAL DEFAULT 0.0');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV7 extends Migration {
  @override
  int get version => 7;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'worship_seasons', 'priority_weight', 'REAL DEFAULT 1.0');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV8 extends Migration {
  @override
  int get version => 8;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS routine_occurrences (
          routine_id TEXT NOT NULL,
          date TEXT NOT NULL,
          scheduled_time TEXT,
          status TEXT NOT NULL DEFAULT 'pending',
          PRIMARY KEY (routine_id, date),
          FOREIGN KEY(routine_id) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_routine_occurrences_routine_id ON routine_occurrences(routine_id);');
    await db.execute('CREATE INDEX IF NOT EXISTS index_routine_occurrences_date ON routine_occurrences(date);');

    await safeAddColumn(db, 'routine_schedules', 'recurrenceRule', 'TEXT');
    await safeAddColumn(db, 'pending_reminders', 'snoozeUntil', 'INTEGER');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS routine_occurrences;');
  }
}

class MigrationV9 extends Migration {
  @override
  int get version => 9;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'worship_seasons', 'start_date', 'TEXT');
    await safeAddColumn(db, 'worship_seasons', 'end_date', 'TEXT');
    await safeAddColumn(db, 'worship_seasons', 'type', "TEXT DEFAULT 'custom'");
    await safeAddColumn(db, 'worship_seasons', 'is_active', 'INTEGER DEFAULT 1');

    await db.execute('''
      UPDATE worship_seasons
      SET start_date = startDate,
          end_date = endDate,
          type = seasonType,
          is_active = isActive;
    ''');

    await safeAddColumn(db, 'routines', 'progressionMode', "TEXT NOT NULL DEFAULT 'NONE'");
    await safeAddColumn(db, 'routines', 'progressionStart', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'routines', 'progressionTarget', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'routines', 'progressionStep', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'routines', 'progressionEveryN', 'INTEGER NOT NULL DEFAULT 1');
    await safeAddColumn(db, 'routines', 'progressionCurrent', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'routines', 'progressionDoneSinceAdvance', 'INTEGER NOT NULL DEFAULT 0');

    await safeAddColumn(db, 'goal_steps', 'scheduledDate', 'TEXT');
    await safeAddColumn(db, 'goal_steps', 'linkedRoutineId', 'TEXT');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV10 extends Migration {
  @override
  int get version => 10;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'routines', 'itemType', "TEXT NOT NULL DEFAULT 'ROUTINE'");
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV11 extends Migration {
  @override
  int get version => 11;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS doctor_visits (
          id TEXT PRIMARY KEY, doctorName TEXT NOT NULL, specialty TEXT,
          clinicName TEXT, clinicAddress TEXT, clinicPhone TEXT,
          visitDateTime INTEGER NOT NULL, visitType TEXT NOT NULL DEFAULT 'IN_PERSON',
          status TEXT NOT NULL DEFAULT 'UPCOMING', reason TEXT,
          doctorNotes TEXT, userNotes TEXT, followUpDate INTEGER,
          reminderBefore INTEGER NOT NULL DEFAULT 60, attachmentPath TEXT,
          createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blood_sugar_logs (
          id TEXT PRIMARY KEY, value INTEGER NOT NULL,
          measurementType TEXT NOT NULL DEFAULT 'FASTING', note TEXT, loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bs_loggedAt ON blood_sugar_logs(loggedAt);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS blood_pressure_logs (
          id TEXT PRIMARY KEY, systolic INTEGER NOT NULL, diastolic INTEGER NOT NULL,
          pulse INTEGER, arm TEXT DEFAULT 'LEFT', position TEXT DEFAULT 'SITTING',
          note TEXT, loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_bp_loggedAt ON blood_pressure_logs(loggedAt);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vital_signs_logs (
          id TEXT PRIMARY KEY, vitalType TEXT NOT NULL, value REAL NOT NULL,
          unit TEXT NOT NULL, note TEXT, loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_vs_loggedAt ON vital_signs_logs(loggedAt);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_documents (
          id TEXT PRIMARY KEY, title TEXT NOT NULL, category TEXT NOT NULL,
          documentDate INTEGER NOT NULL, labName TEXT, summary TEXT,
          doctorNotes TEXT, userNotes TEXT, createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_md_category ON medical_documents(category);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_md_documentDate ON medical_documents(documentDate);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_document_images (
          id TEXT PRIMARY KEY, documentId TEXT NOT NULL, imagePath TEXT NOT NULL,
          pageNumber INTEGER DEFAULT 1, caption TEXT,
          FOREIGN KEY(documentId) REFERENCES medical_documents(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS vaccinations (
          id TEXT PRIMARY KEY, vaccineName TEXT NOT NULL, diseaseTarget TEXT,
          doseNumber INTEGER DEFAULT 1, totalDoses INTEGER, dateAdministered INTEGER,
          nextDoseDue INTEGER, batchNumber TEXT, clinicName TEXT, notes TEXT,
          createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS allergies (
          id TEXT PRIMARY KEY, allergen TEXT NOT NULL, category TEXT NOT NULL,
          reaction TEXT, severity TEXT NOT NULL DEFAULT 'MODERATE',
          diagnosedDate INTEGER, notes TEXT, createdAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS medical_profile (
          id TEXT PRIMARY KEY, profileKey TEXT NOT NULL UNIQUE,
          profileValue TEXT NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pregnancy_tracker (
          id TEXT PRIMARY KEY, lmpDate TEXT NOT NULL, estimatedDueDate TEXT NOT NULL,
          currentWeek INTEGER NOT NULL, currentTrimester INTEGER NOT NULL,
          isActive INTEGER NOT NULL DEFAULT 1, notes TEXT,
          createdAt INTEGER NOT NULL, updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pregnancy_checkups (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, title TEXT NOT NULL,
          scheduledDate INTEGER, actualDate INTEGER, type TEXT NOT NULL,
          result TEXT, notes TEXT, isCompleted INTEGER DEFAULT 0, createdAt INTEGER NOT NULL,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS pregnancy_symptoms (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, date TEXT NOT NULL,
          symptom TEXT NOT NULL, severity TEXT DEFAULT 'MILD', note TEXT,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS kick_counts (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, startTime INTEGER NOT NULL,
          endTime INTEGER, kickCount INTEGER, loggedAt INTEGER NOT NULL,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS contraction_timer (
          id TEXT PRIMARY KEY, pregnancyId TEXT NOT NULL, startTime INTEGER NOT NULL,
          endTime INTEGER, durationSeconds INTEGER, intervalFromPrevious INTEGER,
          loggedAt INTEGER NOT NULL,
          FOREIGN KEY(pregnancyId) REFERENCES pregnancy_tracker(id) ON DELETE CASCADE
      );
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'module_health_enabled': 'true',
      'patient_has_diabetes': 'false',
      'module_pregnancy_enabled': 'false',
      'patient_has_hypertension': 'false',
    };
    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS doctor_visits;');
    await db.execute('DROP TABLE IF EXISTS blood_sugar_logs;');
    await db.execute('DROP TABLE IF EXISTS blood_pressure_logs;');
    await db.execute('DROP TABLE IF EXISTS vital_signs_logs;');
    await db.execute('DROP TABLE IF EXISTS medical_documents;');
    await db.execute('DROP TABLE IF EXISTS medical_document_images;');
    await db.execute('DROP TABLE IF EXISTS vaccinations;');
    await db.execute('DROP TABLE IF EXISTS allergies;');
    await db.execute('DROP TABLE IF EXISTS medical_profile;');
    await db.execute('DROP TABLE IF EXISTS pregnancy_tracker;');
    await db.execute('DROP TABLE IF EXISTS pregnancy_checkups;');
    await db.execute('DROP TABLE IF EXISTS pregnancy_symptoms;');
    await db.execute('DROP TABLE IF EXISTS kick_counts;');
    await db.execute('DROP TABLE IF EXISTS contraction_timer;');
  }
}

class MigrationV12 extends Migration {
  @override
  int get version => 12;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS worship_practices (
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wp_type ON worship_practices(practiceType);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_wp_active ON worship_practices(isActive);');

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {
        'key': 'module_religion_enabled',
        'value': 'true',
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    await db.insert(
      'app_settings',
      {
        'key': 'prayer_city_id',
        'value': 'TEHRAN_TEHRAN',
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    final prayers = [
      {
        'id': 'wp_fajr',
        'practiceType': 'PRAYER',
        'subType': 'FAJR',
        'title': 'نماز صبح',
        'dailyTarget': 1,
        'dailyDone': 0,
        'reminderEnabled': 1,
        'reminderOffsetMinutes': 10,
        'sortOrder': 1,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'wp_dhuhr',
        'practiceType': 'PRAYER',
        'subType': 'DHUHR',
        'title': 'نماز ظهر و عصر',
        'dailyTarget': 1,
        'dailyDone': 0,
        'reminderEnabled': 1,
        'reminderOffsetMinutes': 15,
        'sortOrder': 2,
        'createdAt': now,
        'updatedAt': now,
      },
      {
        'id': 'wp_maghrib',
        'practiceType': 'PRAYER',
        'subType': 'MAGHRIB',
        'title': 'نماز مغرب و عشا',
        'dailyTarget': 1,
        'dailyDone': 0,
        'reminderEnabled': 1,
        'reminderOffsetMinutes': 5,
        'sortOrder': 4,
        'createdAt': now,
        'updatedAt': now,
      },
    ];

    for (final p in prayers) {
      await db.insert('worship_practices', p, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS worship_practices;');
  }
}

class MigrationV13 extends Migration {
  @override
  int get version => 13;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'courses', 'courseType', "TEXT NOT NULL DEFAULT 'VIDEO'");
    await safeAddColumn(db, 'courses', 'unitLabel', 'TEXT');
    await safeAddColumn(db, 'courses', 'emoji', 'TEXT');
    await safeAddColumn(db, 'courses', 'colorHex', 'TEXT');
    await safeAddColumn(db, 'courses', 'provider', 'TEXT');
    await safeAddColumn(db, 'courses', 'weeklyTargetSessions', 'INTEGER NOT NULL DEFAULT 3');
    await safeAddColumn(db, 'courses', 'isAdaptive', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'courses', 'preferredDays', 'TEXT');
    await safeAddColumn(db, 'courses', 'preferredTime', 'TEXT');
    await safeAddColumn(db, 'courses', 'reminderEnabled', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'courses', 'linkedGoalId', 'TEXT');
    await safeAddColumn(db, 'courses', 'status', "TEXT NOT NULL DEFAULT 'ACTIVE'");
    await safeAddColumn(db, 'courses', 'completedAt', 'INTEGER');
    await safeAddColumn(db, 'courses', 'targetEndDate', 'TEXT');

    await safeAddColumn(db, 'course_sessions', 'sessionTitle', 'TEXT');

    var countBefore = 0;
    try {
      final countBeforeRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM pending_reminders');
      if (countBeforeRes.isNotEmpty) {
        countBefore = countBeforeRes.first['cnt'] as int? ?? 0;
      }
    } catch (_) {}

    await db.execute('ALTER TABLE pending_reminders RENAME TO pending_reminders_old;');
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

    await db.execute('''
      INSERT INTO pending_reminders (
        id, routineId, scheduleId, courseSessionId, originalTime, 
        scheduledTime, state, deferCount, deferReason, createdAt, 
        updatedAt, snoozeUntil
      )
      SELECT 
        id, routineId, scheduleId, courseSessionId, originalTime, 
        scheduledTime, state, deferCount, deferReason, createdAt, 
        updatedAt, snoozeUntil 
      FROM pending_reminders_old;
    ''');
    await db.execute('DROP TABLE pending_reminders_old;');

    await db.execute('CREATE INDEX index_pending_reminders_routineId ON pending_reminders(routineId);');
    await db.execute('CREATE INDEX index_pending_reminders_scheduleId ON pending_reminders(scheduleId);');
    await db.execute('CREATE INDEX index_pending_reminders_scheduledTime ON pending_reminders(scheduledTime);');
    await db.execute('CREATE UNIQUE INDEX index_pending_reminders_unique_slot ON pending_reminders(routineId, scheduleId, originalTime);');

    final countAfterRes = await db.rawQuery('SELECT COUNT(*) as cnt FROM pending_reminders');
    var countAfter = 0;
    if (countAfterRes.isNotEmpty) {
      countAfter = countAfterRes.first['cnt'] as int? ?? 0;
    }
    if (countBefore != countAfter) {
      throw Exception('Migration failed: count of reminders mismatched. Before: $countBefore, After: $countAfter');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV14 extends Migration {
  @override
  int get version => 14;

  @override
  Future<void> up(Database db) async {
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

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'cycle_avg_length': '28',
      'cycle_avg_period': '6',
      'cycle_biometric_enabled': 'false',
      'cycle_setup_done': 'false',
      'cycle_consent_energy': 'false',
      'cycle_consent_reminders': 'false',
      'cycle_consent_worship': 'false',
      'cycle_consent_dashboard': 'false',
      'module_cycle_enabled': 'false',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }

    final settings = await db.query('app_settings');
    final settingsMap = {for (final s in settings) s['key']! as String: s['value']! as String};
    
    // Auto-enable cycle if female
    if (settingsMap['user_gender'] == 'FEMALE') {
      await db.insert(
        'app_settings',
        {
          'key': 'module_cycle_enabled',
          'value': 'true',
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS cycle_periods;');
    await db.execute('DROP TABLE IF EXISTS cycle_day_logs;');
  }
}

class MigrationV15 extends Migration {
  @override
  int get version => 15;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_study_sessions (
        id TEXT PRIMARY KEY,
        topicId TEXT,
        subjectId TEXT,
        dateIso TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        mode TEXT NOT NULL DEFAULT 'STUDY',
        testsTotal INTEGER NOT NULL DEFAULT 0,
        testsCorrect INTEGER NOT NULL DEFAULT 0,
        testsWrong INTEGER NOT NULL DEFAULT 0,
        testsBlank INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_sessions_dateIso ON konkur_study_sessions(dateIso);');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_sessions_subjectId ON konkur_study_sessions(subjectId);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS konkur_plan_items (
        id TEXT PRIMARY KEY,
        dateIso TEXT NOT NULL,
        subjectId TEXT,
        topicId TEXT,
        plannedMinutes INTEGER NOT NULL DEFAULT 0,
        status TEXT NOT NULL DEFAULT 'PENDING',
        createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_konkur_plan_dateIso ON konkur_plan_items(dateIso);');

    await safeAddColumn(db, 'konkur_subjects', 'subjectGroup', "TEXT NOT NULL DEFAULT 'SPECIALIZED'");
    await safeAddColumn(db, 'konkur_subjects', 'examQuestionCount', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'konkur_subjects', 'orderIndex', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'konkur_subjects', 'colorHex', 'TEXT');
    await safeAddColumn(db, 'konkur_subjects', 'isPreset', 'INTEGER NOT NULL DEFAULT 0');

    await safeAddColumn(db, 'konkur_topics', 'examQuestionCount', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'konkur_topics', 'masteryLevel', "TEXT NOT NULL DEFAULT 'NOT_STARTED'");
    await safeAddColumn(db, 'konkur_topics', 'lastStudiedAt', 'INTEGER');
    await safeAddColumn(db, 'konkur_topics', 'nextReviewDate', 'TEXT');
    await safeAddColumn(db, 'konkur_topics', 'plannedDate', 'TEXT');
    await safeAddColumn(db, 'konkur_topics', 'orderIndex', 'INTEGER NOT NULL DEFAULT 0');

    await safeAddColumn(db, 'konkur_mock_exams', 'provider', 'TEXT');
    await safeAddColumn(db, 'konkur_mock_exams', 'note', 'TEXT');

    await safeAddColumn(db, 'konkur_mock_exam_results', 'totalQuestions', 'INTEGER NOT NULL DEFAULT 0');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'konkur_field': 'UNSET',
      'konkur_exam_date': '',
      'konkur_setup_done': 'false',
      'konkur_daily_target_minutes': '180',
      'konkur_show_in_dashboard': 'true',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS konkur_study_sessions;');
    await db.execute('DROP TABLE IF EXISTS konkur_plan_items;');
  }
}

class MigrationV16 extends Migration {
  @override
  int get version => 16;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'goals', 'progressCache', 'REAL NOT NULL DEFAULT 0');

    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {
        'key': 'module_goals_enabled',
        'value': 'false',
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV17 extends Migration {
  @override
  int get version => 17;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS mood_logs (
          id TEXT PRIMARY KEY,
          mood TEXT NOT NULL,
          valence INTEGER NOT NULL DEFAULT 3,
          note TEXT,
          loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_mood_logs_loggedAt ON mood_logs(loggedAt);');

    await safeAddColumn(db, 'bedtime_diagnostics', 'bedtimeAt', 'INTEGER');
    await safeAddColumn(db, 'bedtime_diagnostics', 'wakeAt', 'INTEGER');
    await safeAddColumn(db, 'bedtime_diagnostics', 'durationMinutes', 'INTEGER');
    await safeAddColumn(db, 'bedtime_diagnostics', 'quality', 'INTEGER NOT NULL DEFAULT 3');
    await safeAddColumn(db, 'bedtime_diagnostics', 'awakenings', 'INTEGER NOT NULL DEFAULT 0');

    final now = DateTime.now().millisecondsSinceEpoch;
    final sleepSettings = {
      'module_energy_enabled': 'false',
      'module_sleep_enabled': 'false',
      'sleep_target_bedtime': '23:30',
      'sleep_target_wake': '07:00',
      'sleep_target_duration_minutes': '450',
      'sleep_winddown_reminder': 'false',
      'sleep_winddown_minutes': '30',
      'sleep_setup_done': 'false',
    };

    for (final entry in sleepSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS mood_logs;');
  }
}

class MigrationV18 extends Migration {
  @override
  int get version => 18;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'assistant_chats', 'actionsJson', 'TEXT');
    await safeAddColumn(db, 'assistant_chats', 'meta', 'TEXT');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'assistant_briefing_enabled': 'true',
      'assistant_proactive_enabled': 'true',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV19 extends Migration {
  @override
  int get version => 19;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS fasting_debt (
        id TEXT PRIMARY KEY,
        dateIso TEXT NOT NULL,
        daysOwed INTEGER NOT NULL DEFAULT 1,
        reason TEXT,
        isResolved INTEGER NOT NULL DEFAULT 0,
        createdAt INTEGER,
        updatedAt INTEGER
      );
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;
    final avgLengthQuery = await db.query('app_settings', where: 'key = ?', whereArgs: ['cycle_avg_length']);
    final avgPeriodQuery = await db.query('app_settings', where: 'key = ?', whereArgs: ['cycle_avg_period']);
    final avgLength = avgLengthQuery.isNotEmpty ? (avgLengthQuery.first['value'] as String? ?? '28') : '28';
    final avgPeriod = avgPeriodQuery.isNotEmpty ? (avgPeriodQuery.first['value'] as String? ?? '6') : '6';

    final newSettings = {
      'cycle_consent_sleep': 'false',
      'cycle_fertility_visible': 'false',
      'cycle_pms_window_days': '4',
      'cycle_length_days': avgLength,
      'period_duration_days': avgPeriod,
      'reflection_reminder_enabled': 'true',
      'reflection_prompt_style': 'structured',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS fasting_debt;');
  }
}

class MigrationV20 extends Migration {
  @override
  int get version => 20;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'daily_reflections', 'gratitude', 'TEXT');
    await safeAddColumn(db, 'daily_reflections', 'wins', 'TEXT');
    await safeAddColumn(db, 'daily_reflections', 'challenges', 'TEXT');
    await safeAddColumn(db, 'daily_reflections', 'tomorrowFocus', 'TEXT');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'reflection_reminder_enabled': 'true',
      'reflection_prompt_style': 'structured',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV21 extends Migration {
  @override
  int get version => 21;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS medication_logs (
          id TEXT PRIMARY KEY,
          routineId TEXT NOT NULL,
          scheduledTime INTEGER,
          takenTime INTEGER,
          status TEXT NOT NULL DEFAULT 'TAKEN',
          note TEXT,
          createdAt INTEGER NOT NULL,
          FOREIGN KEY(routineId) REFERENCES routines(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medlog_routine ON medication_logs(routineId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_medlog_time ON medication_logs(scheduledTime);');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'health_adherence_enabled': 'true',
      'health_trend_window_days': '30',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS medication_logs;');
  }
}

class MigrationV22 extends Migration {
  @override
  int get version => 22;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS devices (
          id TEXT PRIMARY KEY,
          deviceName TEXT,
          platform TEXT,
          model TEXT,
          firstSeenAt INTEGER,
          lastActiveAt INTEGER,
          isCurrent INTEGER DEFAULT 1
      );
    ''');

    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'is_premium': 'false',
      'premium_plan': '',
      'premium_activated_at': '',
      'premium_license': '',
      'app_lock_enabled': 'false',
      'app_biometric_enabled': 'false',
      'notif_master_enabled': 'true',
      'notif_quiet_enabled': 'false',
      'notif_quiet_start': '00:00',
      'notif_quiet_end': '07:00',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS devices;');
  }
}

class MigrationV23 extends Migration {
  @override
  int get version => 23;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final newSettings = {
      'cycle_pregnancy_mode': 'false',
      'cycle_pregnancy_start_date': '',
      'cycle_pregnancy_due_date': '',
    };

    for (final entry in newSettings.entries) {
      await db.insert(
        'app_settings',
        {
          'key': entry.key,
          'value': entry.value,
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV24 extends Migration {
  @override
  int get version => 24;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE worship_practices ADD COLUMN allowQada INTEGER DEFAULT 0;');
    } catch (_) {}
    await SeedService.seedIranCities(db);
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV25 extends Migration {
  @override
  int get version => 25;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute("ALTER TABLE worship_practices ADD COLUMN reminderFrequency TEXT DEFAULT 'DAILY';");
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV26 extends Migration {
  @override
  int get version => 26;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inbox_items (
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
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inbox_status ON inbox_items(status);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_inbox_createdAt ON inbox_items(createdAt);');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_inbox_dedupe ON inbox_items(dedupeKey);');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS inbox_items;');
  }
}

class MigrationV27 extends Migration {
  @override
  int get version => 27;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_audit_log (
        id TEXT PRIMARY KEY,
        actionType TEXT NOT NULL,
        targetKey TEXT,
        oldValue TEXT,
        newValue TEXT,
        appliedAt INTEGER NOT NULL
      );
    ''');
    await safeAddColumn(db, 'goals', 'isPrivate', 'INTEGER NOT NULL DEFAULT 0');
    await safeAddColumn(db, 'daily_reflections', 'isPrivate', 'INTEGER NOT NULL DEFAULT 0');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS assistant_audit_log;');
  }
}

class MigrationV28 extends Migration {
  @override
  int get version => 28;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS assistant_threads (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      );
    ''');
    await safeAddColumn(db, 'assistant_chats', 'threadId', 'TEXT');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS assistant_threads;');
  }
}

class MigrationV29 extends Migration {
  @override
  int get version => 29;

  @override
  Future<void> up(Database db) async {
    await db.execute("UPDATE worship_practices SET isActive = 0 WHERE id IN ('wp_asr', 'wp_isha');");
    await db.execute("UPDATE worship_practices SET title = 'نماز ظهر و عصر' WHERE id = 'wp_dhuhr';");
    await db.execute("UPDATE worship_practices SET title = 'نماز مغرب و عشا' WHERE id = 'wp_maghrib';");
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV30 extends Migration {
  @override
  int get version => 30;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_logs (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        durationMinutes INTEGER NOT NULL DEFAULT 0,
        intensity TEXT NOT NULL DEFAULT 'MEDIUM',
        note TEXT,
        loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_workout_logs_loggedAt ON workout_logs(loggedAt);');
    
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('app_settings',
      {'key': 'module_sports_enabled', 'value': 'false', 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS workout_logs;');
  }
}

class MigrationV31 extends Migration {
  @override
  int get version => 31;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'workout_logs', 'tier', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'muscleGroups', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'feeling', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'location', 'TEXT');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_split_days (
        weekday INTEGER PRIMARY KEY,
        muscleGroups TEXT NOT NULL DEFAULT '',
        isRest INTEGER NOT NULL DEFAULT 0,
        updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_recovery_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        soreness INTEGER NOT NULL DEFAULT 0,
        fatigue INTEGER NOT NULL DEFAULT 0,
        hydration INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_recovery_date ON workout_recovery_logs(date);');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS workout_split_days;');
    await db.execute('DROP TABLE IF EXISTS workout_recovery_logs;');
  }
}

class MigrationV32 extends Migration {
  @override
  int get version => 32;

  @override
  Future<void> up(Database db) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert('app_settings',
      {'key': 'show_cycle_in_calendar', 'value': 'false', 'updatedAt': now},
      conflictAlgorithm: ConflictAlgorithm.ignore);
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV33 extends Migration {
  @override
  int get version => 33;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'worship_practices', 'reminderAnchor', "TEXT DEFAULT 'NONE'");
    await safeAddColumn(db, 'worship_practices', 'reminderDaysOfWeek', 'TEXT');
    await safeAddColumn(db, 'worship_practices', 'reminderTimes', 'TEXT');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV34 extends Migration {
  @override
  int get version => 34;

  @override
  Future<void> up(Database db) async {
    await safeAddColumn(db, 'prayer_times_cache', 'sunset', "TEXT NOT NULL DEFAULT ''");
    await db.update(
      'worship_practices',
      {'reminderEnabled': 0},
      where: "practiceType = 'QURAN' OR practiceType = 'DHIKR'",
    );
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV35 extends Migration {
  @override
  int get version => 35;

  @override
  Future<void> up(Database db) async {
    // 1. Create exercises library table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS exercises_library (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        equipment TEXT,
        instructions TEXT,
        isCustom INTEGER DEFAULT 0
      );
    ''');

    // 2. Create workout set logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_set_logs (
        id TEXT PRIMARY KEY,
        workoutLogId TEXT NOT NULL,
        exerciseId TEXT NOT NULL,
        setIndex INTEGER NOT NULL,
        weight REAL,
        reps INTEGER,
        isCompleted INTEGER DEFAULT 1,
        FOREIGN KEY(workoutLogId) REFERENCES workout_logs(id) ON DELETE CASCADE
      );
    ''');

    // 3. Add soreMuscleGroups to recovery logs
    await safeAddColumn(db, 'workout_recovery_logs', 'soreMuscleGroups', "TEXT DEFAULT ''");

    // 4. Seed exercises
    final defaultExercises = [
      {'id': 'ex_chest_pushups', 'name': 'شنا سوئدی', 'category': 'CHEST', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_chest_knee_pushups', 'name': 'شنا روی زانو', 'category': 'CHEST', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_chest_close_pushups', 'name': 'شنا دستجمع', 'category': 'CHEST', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_chest_chair_dips', 'name': 'دیپ روی صندلی', 'category': 'CHEST', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_chest_bench_press', 'name': 'پرس سینه هالتر', 'category': 'CHEST', 'equipment': 'BARBELL'},
      {'id': 'ex_chest_db_press', 'name': 'پرس سینه دمبل', 'category': 'CHEST', 'equipment': 'DUMBBELL'},
      {'id': 'ex_chest_fly', 'name': 'قفسه سینه', 'category': 'CHEST', 'equipment': 'DUMBBELL'},
      {'id': 'ex_chest_incline_press', 'name': 'پرس بالاسینه', 'category': 'CHEST', 'equipment': 'BARBELL'},
      
      {'id': 'ex_back_band_row', 'name': 'زیربغل با کش', 'category': 'BACK', 'equipment': 'BAND'},
      {'id': 'ex_back_superman', 'name': 'سوپرمن', 'category': 'BACK', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_back_bottle_row', 'name': 'پارویی خم با بطری آب', 'category': 'BACK', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_back_lat_pulldown', 'name': 'زیربغل سیمکش', 'category': 'BACK', 'equipment': 'MACHINE'},
      {'id': 'ex_back_pullups', 'name': 'بارفیکس', 'category': 'BACK', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_back_bb_row', 'name': 'پارویی هالتر', 'category': 'BACK', 'equipment': 'BARBELL'},
      {'id': 'ex_back_deadlift', 'name': 'ددلیفت', 'category': 'BACK', 'equipment': 'BARBELL'},

      {'id': 'ex_shoulders_band_raise', 'name': 'نشر جانب با کش', 'category': 'SHOULDERS', 'equipment': 'BAND'},
      {'id': 'ex_shoulders_bottle_press', 'name': 'پرس سرشانه با بطری', 'category': 'SHOULDERS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_shoulders_pike_pushup', 'name': 'شنا پایک', 'category': 'SHOULDERS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_shoulders_db_press', 'name': 'پرس سرشانه دمبل', 'category': 'SHOULDERS', 'equipment': 'DUMBBELL'},
      {'id': 'ex_shoulders_lateral_raise', 'name': 'نشر جانب', 'category': 'SHOULDERS', 'equipment': 'DUMBBELL'},
      {'id': 'ex_shoulders_rear_delt_fly', 'name': 'نشر خم', 'category': 'SHOULDERS', 'equipment': 'DUMBBELL'},
      {'id': 'ex_shoulders_military_press', 'name': 'پرس نظامی', 'category': 'SHOULDERS', 'equipment': 'BARBELL'},

      {'id': 'ex_biceps_band_curl', 'name': 'جلو بازو با کش', 'category': 'BICEPS', 'equipment': 'BAND'},
      {'id': 'ex_biceps_bottle_curl', 'name': 'جلو بازو با بطری آب', 'category': 'BICEPS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_biceps_isometric', 'name': 'کشش ایزومتریک', 'category': 'BICEPS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_biceps_bb_curl', 'name': 'جلو بازو هالتر', 'category': 'BICEPS', 'equipment': 'BARBELL'},
      {'id': 'ex_biceps_db_curl', 'name': 'جلو بازو دمبل', 'category': 'BICEPS', 'equipment': 'DUMBBELL'},
      {'id': 'ex_biceps_cable_curl', 'name': 'لاری سیمکش', 'category': 'BICEPS', 'equipment': 'MACHINE'},
      {'id': 'ex_biceps_hammer_curl', 'name': 'چکشی', 'category': 'BICEPS', 'equipment': 'DUMBBELL'},

      {'id': 'ex_triceps_chair_dips', 'name': 'دیپ روی صندلی', 'category': 'TRICEPS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_triceps_close_pushups', 'name': 'شنا دستجمع', 'category': 'TRICEPS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_triceps_band_pushdown', 'name': 'پشت بازو با کش', 'category': 'TRICEPS', 'equipment': 'BAND'},
      {'id': 'ex_triceps_cable_pushdown', 'name': 'پشت بازو سیمکش', 'category': 'TRICEPS', 'equipment': 'MACHINE'},
      {'id': 'ex_triceps_parallel_dips', 'name': 'دیپ پارالل', 'category': 'TRICEPS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_triceps_close_bench', 'name': 'پرس دستجمع', 'category': 'TRICEPS', 'equipment': 'BARBELL'},

      {'id': 'ex_legs_squat', 'name': 'اسکوات با وزن بدن', 'category': 'LEGS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_legs_lunges', 'name': 'لانگز', 'category': 'LEGS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_legs_glute_bridge', 'name': 'پل باسن', 'category': 'LEGS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_legs_calf_raise', 'name': 'ساق ایستاده', 'category': 'LEGS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_legs_bb_squat', 'name': 'اسکوات هالتر', 'category': 'LEGS', 'equipment': 'BARBELL'},
      {'id': 'ex_legs_leg_press', 'name': 'پرس پا', 'category': 'LEGS', 'equipment': 'MACHINE'},
      {'id': 'ex_legs_db_lunges', 'name': 'لانگز دمبل', 'category': 'LEGS', 'equipment': 'DUMBBELL'},
      {'id': 'ex_legs_calf_machine', 'name': 'ساق دستگاه', 'category': 'LEGS', 'equipment': 'MACHINE'},

      {'id': 'ex_abs_crunches', 'name': 'کرانچ', 'category': 'ABS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_abs_plank', 'name': 'پلانک', 'category': 'ABS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_abs_mountain_climber', 'name': 'کوهنورد', 'category': 'ABS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_abs_leg_raise', 'name': 'زیرشکم خوابیده', 'category': 'ABS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_abs_cable_crunch', 'name': 'کرانچ سیمکش', 'category': 'ABS', 'equipment': 'MACHINE'},
      {'id': 'ex_abs_hanging_raise', 'name': 'زیرشکم آویزان', 'category': 'ABS', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_abs_russian_twist', 'name': 'چرخش روسی', 'category': 'ABS', 'equipment': 'BODYWEIGHT'},

      {'id': 'ex_fb_burpee', 'name': 'برپی', 'category': 'FULLBODY', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_fb_jumping_jack', 'name': 'جامپینگجک', 'category': 'FULLBODY', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_fb_squat_press', 'name': 'اسکوات+پرس', 'category': 'FULLBODY', 'equipment': 'DUMBBELL'},
      {'id': 'ex_fb_clean_press', 'name': 'کلین و پرس', 'category': 'FULLBODY', 'equipment': 'BARBELL'},
      {'id': 'ex_fb_kb_swing', 'name': 'کتلبل سوینگ', 'category': 'FULLBODY', 'equipment': 'DUMBBELL'},

      {'id': 'ex_cardio_rope', 'name': 'طنابزنی', 'category': 'CARDIO', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_cardio_run_in_place', 'name': 'دویدن درجا', 'category': 'CARDIO', 'equipment': 'BODYWEIGHT'},
      {'id': 'ex_cardio_treadmill', 'name': 'تردمیل', 'category': 'CARDIO', 'equipment': 'MACHINE'},
      {'id': 'ex_cardio_bike', 'name': 'دوچرخهثابت', 'category': 'CARDIO', 'equipment': 'MACHINE'},
      {'id': 'ex_cardio_elliptical', 'name': 'الپتیکال', 'category': 'CARDIO', 'equipment': 'MACHINE'},
      {'id': 'ex_cardio_rowing', 'name': 'روئینگ', 'category': 'CARDIO', 'equipment': 'MACHINE'},
    ];

    final batch = db.batch();
    for (final ex in defaultExercises) {
      batch.insert('exercises_library', {
        'id': ex['id'],
        'name': ex['name'],
        'category': ex['category'],
        'equipment': ex['equipment'],
        'isCustom': 0,
      }, conflictAlgorithm: ConflictAlgorithm.ignore);
    }
    await batch.commit(noResult: true);
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV36 extends Migration {
  @override
  int get version => 36;

  @override
  Future<void> up(Database db) async {
    // 1. Create workout_exercise_logs table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_exercise_logs (
        id TEXT PRIMARY KEY,
        workoutLogId TEXT NOT NULL,
        exerciseId TEXT NOT NULL,
        feeling TEXT,
        isCompleted INTEGER DEFAULT 1,
        FOREIGN KEY(workoutLogId) REFERENCES workout_logs(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_workout_exercise_logs_workoutLogId ON workout_exercise_logs(workoutLogId);');

    // 2. Create workout_plan_versions table
    await db.execute('''
      CREATE TABLE IF NOT EXISTS workout_plan_versions (
        id TEXT PRIMARY KEY,
        versionDate TEXT NOT NULL,
        serializedPlan TEXT NOT NULL,
        createdAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_plan_versions_date ON workout_plan_versions(versionDate);');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV37 extends Migration {
  @override
  int get version => 37;

  @override
  Future<void> up(Database db) async {
    // 1. Create all supplementary sports tables
    await SupplementarySportsTables.create(db);

    // 2. Add module_supplementary_sports_enabled setting key
    final now = DateTime.now().millisecondsSinceEpoch;
    await db.insert(
      'app_settings',
      {
        'key': 'module_supplementary_sports_enabled',
        'value': 'false',
        'updatedAt': now,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV38 extends Migration {
  @override
  int get version => 38;

  @override
  Future<void> up(Database db) async {
    final columns = {
      'durationSeconds': 'INTEGER DEFAULT 0',
      'defaultReps': 'INTEGER DEFAULT 0',
      'repsHint': 'TEXT',
      'toolsRequired': "TEXT DEFAULT '[]'",
      'constraintNegative': 'TEXT',
      'weightSupported': 'INTEGER DEFAULT 0',
      'weightPerHand': 'INTEGER DEFAULT 0',
      'muscleIntensity': "TEXT DEFAULT '{}'",
      'skillRequired': 'INTEGER DEFAULT 0',
      'strengthVsCardio': 'REAL DEFAULT 0',
      'machineVsFreeweight': 'REAL DEFAULT 0',
      'looksCool': 'INTEGER DEFAULT 0',
      'stance': 'TEXT',
    };

    for (final entry in columns.entries) {
      try {
        await db.execute('ALTER TABLE ss_exercise ADD COLUMN ${entry.key} ${entry.value};');
      } catch (e) {
        // Column might already exist
      }
    }

    try {
      await db.execute('ALTER TABLE ss_user_profile ADD COLUMN neighborFriendly INTEGER DEFAULT 0;');
    } catch (e) {
      // Column might already exist
    }

    final now = DateTime.now().millisecondsSinceEpoch;
    try {
      await db.insert(
        'app_settings',
        {
          'key': 'ss_reseed_v38',
          'value': 'true',
          'updatedAt': now,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      try {
        await db.update(
          'app_settings',
          {'value': 'true', 'updatedAt': now},
          where: 'key = ?',
          whereArgs: ['ss_reseed_v38'],
        );
      } catch (_) {}
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV39 extends Migration {
  @override
  int get version => 39;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE routine_completions ADD COLUMN actual_duration_minutes INTEGER;');
    } catch (e) {
      // Column might already exist
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV40 extends Migration {
  @override
  int get version => 40;

  @override
  Future<void> up(Database db) async {
    final columnsToAdd = <String>[
      'ALTER TABLE ss_exercise ADD COLUMN code TEXT;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_cardio INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_plyometric INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_lower_body INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_upper_body INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_shoulder_and_back INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_core INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_stretching INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_yoga INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_balance INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN cat_warmup INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN skill_max INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN sexyness_m INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN sexyness_f INTEGER DEFAULT 0;',
      'ALTER TABLE ss_exercise ADD COLUMN animation_asset TEXT;',
    ];

    for (final sql in columnsToAdd) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    try {
      await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_ss_exercise_code ON ss_exercise(code);');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_workout_set (
        id TEXT PRIMARY KEY,
        code TEXT NOT NULL UNIQUE,
        title_fa TEXT NOT NULL,
        description_fa TEXT,
        icon TEXT,
        focus TEXT,
        difficulty_levels INTEGER,
        is_female_oriented INTEGER DEFAULT 0,
        sort_order INTEGER
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_exercise_set_suitability (
        exercise_id TEXT NOT NULL,
        set_code TEXT NOT NULL,
        suitability INTEGER NOT NULL,
        suitability_lowerbody INTEGER DEFAULT -1,
        suitability_abscore INTEGER DEFAULT -1,
        suitability_back INTEGER DEFAULT -1,
        suitability_upperbody INTEGER DEFAULT -1,
        difficulty INTEGER NOT NULL,
        sort_order INTEGER NOT NULL,
        skill_required INTEGER DEFAULT -1,
        skill_max INTEGER DEFAULT -1,
        PRIMARY KEY(exercise_id, set_code)
      );
    ''');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV41 extends Migration {
  @override
  int get version => 41;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_workout_set_log (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        exercise_id TEXT NOT NULL,
        set_index INTEGER NOT NULL,
        weight REAL NOT NULL,
        reps INTEGER NOT NULL,
        feeling TEXT,
        FOREIGN KEY(session_id) REFERENCES ss_workout_session_log(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_ss_workout_set_log_session '
      'ON ss_workout_set_log(session_id);',
    );
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV42 extends Migration {
  @override
  int get version => 42;

  @override
  Future<void> up(Database db) async {
    final columns = [
      'ALTER TABLE konkur_topics ADD COLUMN prerequisiteTopicIds TEXT;',
      'ALTER TABLE konkur_topics ADD COLUMN conceptCompletedMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN practiceCompletedMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN reviewCompletedMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN conceptTargetMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN practiceTargetMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN reviewTargetMinutes INTEGER NOT NULL DEFAULT 0;',
    ];

    for (final sql in columns) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    await safeAddColumn(db, 'routine_completions', 'actual_duration_minutes', 'INTEGER');

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS konkur_plan_items (
          id TEXT PRIMARY KEY,
          dateIso TEXT NOT NULL,
          subjectId TEXT,
          topicId TEXT,
          plannedMinutes INTEGER NOT NULL DEFAULT 0,
          status TEXT NOT NULL DEFAULT 'PENDING',
          createdAt INTEGER NOT NULL
        );
      ''');
      await db.execute('''
        CREATE TABLE IF NOT EXISTS konkur_study_sessions (
          id TEXT PRIMARY KEY,
          topicId TEXT,
          subjectId TEXT,
          dateIso TEXT NOT NULL,
          durationMinutes INTEGER NOT NULL DEFAULT 0,
          mode TEXT NOT NULL DEFAULT 'STUDY',
          testsTotal INTEGER NOT NULL DEFAULT 0,
          testsCorrect INTEGER NOT NULL DEFAULT 0,
          testsWrong INTEGER NOT NULL DEFAULT 0,
          testsBlank INTEGER NOT NULL DEFAULT 0,
          note TEXT,
          createdAt INTEGER NOT NULL
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_konkur_plan_date_status ON konkur_plan_items(dateIso, status);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_konkur_sessions_date ON konkur_study_sessions(dateIso);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_konkur_topics_subjectId ON konkur_topics(subjectId);');
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV43 extends Migration {
  @override
  int get version => 43;

  @override
  Future<void> up(Database db) async {
    await db.execute('DROP TABLE IF EXISTS assistant_chats;');
    await db.execute('DROP TABLE IF EXISTS assistant_threads;');
    await db.execute("DELETE FROM app_settings WHERE key = 'assistant_memory_summary';");
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_sessions (
        id TEXT PRIMARY KEY,
        title TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        last_message_at INTEGER NOT NULL,
        summary TEXT,
        message_count INTEGER NOT NULL DEFAULT 0,
        chat_type TEXT DEFAULT 'assistant'
      );
    ''');
    try {
      await db.execute("ALTER TABLE chat_sessions ADD COLUMN chat_type TEXT DEFAULT 'assistant';");
    } catch (_) {}
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_sessions_last '
      'ON chat_sessions(last_message_at DESC);',
    );
    await db.execute('''
      CREATE TABLE IF NOT EXISTS chat_messages (
        id TEXT PRIMARY KEY,
        session_id TEXT NOT NULL,
        role TEXT NOT NULL,
        content TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        tokens_used INTEGER,
        actions TEXT,
        FOREIGN KEY(session_id) REFERENCES chat_sessions(id) ON DELETE CASCADE
      );
    ''');
    await db.execute(
      'CREATE INDEX IF NOT EXISTS idx_chat_session_time '
      'ON chat_messages(session_id, timestamp);',
    );
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV44 extends Migration {
  @override
  int get version => 44;

  @override
  Future<void> up(Database db) async {
    await db.execute('DROP TABLE IF EXISTS ss_ai_memory;');
    await AiTables.ensureSchema(db);
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV45 extends Migration {
  @override
  int get version => 45;

  @override
  Future<void> up(Database db) async {
    await DayPlanTables.ensureSchema(db);
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV46 extends Migration {
  @override
  int get version => 46;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE routines ADD COLUMN reminderOffsetMinutes INTEGER DEFAULT 0;');
    } catch (_) {}
    try {
      await db.execute('ALTER TABLE workout_set_logs ADD COLUMN rpe REAL;');
    } catch (_) {}

    final indexQueries = [
      'CREATE INDEX IF NOT EXISTS idx_perf_completions_routine_date ON routine_completions(routineId, completionDate);',
      'CREATE INDEX IF NOT EXISTS idx_perf_occurrences_routine_date ON routine_occurrences(routine_id, date);',
      'CREATE INDEX IF NOT EXISTS idx_perf_occurrences_date_status ON routine_occurrences(date, status);',
      'CREATE INDEX IF NOT EXISTS idx_perf_wp_type_active ON worship_practices(practiceType, isActive);',
      'CREATE INDEX IF NOT EXISTS idx_perf_reminders_routine_state ON pending_reminders(routineId, state);',
    ];

    for (final sql in indexQueries) {
      try {
        await db.execute(sql);
      } catch (e) {
        debugPrint('[MIGRATION_V46] Note executing index statement: $e');
      }
    }
  }

  @override
  Future<void> down(Database db) async {}
}



class MigrationV47 extends Migration {
  @override
  int get version => 47;

  @override
  Future<void> up(Database db) async {
    // Add sessionOutcome to study sessions
    try {
      await db.execute('ALTER TABLE konkur_study_sessions ADD COLUMN sessionOutcome TEXT;');
    } catch (_) {}

    // Add phase target/completed columns to konkur_topics (in case they weren't applied)
    for (final col in [
      'ALTER TABLE konkur_topics ADD COLUMN conceptTargetMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN conceptCompletedMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN practiceTargetMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN practiceCompletedMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN reviewTargetMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN reviewCompletedMinutes INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_topics ADD COLUMN chapter TEXT;',
    ]) {
      try {
        await db.execute(col);
      } catch (_) {}
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV48 extends Migration {
  @override
  int get version => 48;

  @override
  Future<void> up(Database db) async {
    final columns = [
      'ALTER TABLE konkur_plan_items ADD COLUMN plannedMode TEXT;',
      'ALTER TABLE konkur_plan_items ADD COLUMN priorityScore REAL;',
      'ALTER TABLE konkur_plan_items ADD COLUMN planningReason TEXT;',
      'ALTER TABLE konkur_plan_items ADD COLUMN isLocked INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_plan_items ADD COLUMN isUserEdited INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE konkur_plan_items ADD COLUMN carryOverCount INTEGER NOT NULL DEFAULT 0;',
      "ALTER TABLE konkur_plan_items ADD COLUMN sourceType TEXT DEFAULT 'AUTO';",
      'ALTER TABLE konkur_plan_items ADD COLUMN recommendedEnergy TEXT;',
    ];

    for (final sql in columns) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV49 extends Migration {
  @override
  int get version => 49;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE konkur_plan_items ADD COLUMN energyNote TEXT;');
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV50 extends Migration {
  @override
  int get version => 50;

  @override
  Future<void> up(Database db) async {
    // 1. New columns for course_sessions
    final sessionColumns = [
      'ALTER TABLE course_sessions ADD COLUMN completedAt INTEGER;',
      'ALTER TABLE course_sessions ADD COLUMN isUserScheduled INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE course_sessions ADD COLUMN plannedStartTime TEXT;',
      'ALTER TABLE course_sessions ADD COLUMN estimatedDurationMinutes INTEGER;',
      'ALTER TABLE course_sessions ADD COLUMN sectionTitle TEXT;',
      'ALTER TABLE course_sessions ADD COLUMN learningObjective TEXT;',
      'ALTER TABLE course_sessions ADD COLUMN difficulty INTEGER;',
      "ALTER TABLE course_sessions ADD COLUMN activityKind TEXT NOT NULL DEFAULT 'LEARN';",
      'ALTER TABLE course_sessions ADD COLUMN understandingScore INTEGER;',
      'ALTER TABLE course_sessions ADD COLUMN needsReview INTEGER NOT NULL DEFAULT 0;',
      'ALTER TABLE course_sessions ADD COLUMN keyTakeaway TEXT;',
      'ALTER TABLE course_sessions ADD COLUMN openQuestion TEXT;',
      'ALTER TABLE course_sessions ADD COLUMN sourceSessionId TEXT;',
      'ALTER TABLE course_sessions ADD COLUMN displayOrder INTEGER NOT NULL DEFAULT 0;',
    ];

    for (final sql in sessionColumns) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    // 2. New columns for courses
    final courseColumns = [
      'ALTER TABLE courses ADD COLUMN adaptiveLastAppliedAt INTEGER;',
      'ALTER TABLE courses ADD COLUMN masteryScore REAL NOT NULL DEFAULT 0;',
      'ALTER TABLE courses ADD COLUMN reviewEnabled INTEGER NOT NULL DEFAULT 0;',
    ];

    for (final sql in courseColumns) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }

    // 3. New table for active study timers
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS course_active_timers (
            courseSessionId TEXT PRIMARY KEY,
            courseId TEXT NOT NULL,
            startedAt INTEGER NOT NULL,
            pausedAccumulatedMs INTEGER NOT NULL DEFAULT 0,
            state TEXT NOT NULL DEFAULT 'RUNNING',
            targetDurationMinutes INTEGER,
            updatedAt INTEGER NOT NULL,
            FOREIGN KEY(courseSessionId) REFERENCES course_sessions(id) ON DELETE CASCADE
        );
      ''');
    } catch (_) {}

    // 4. Mandatory backfills
    try {
      await db.execute('''
        UPDATE course_sessions
        SET completedAt = updatedAt
        WHERE completionStatus = 'COMPLETED' AND completedAt IS NULL;
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        UPDATE course_sessions
        SET displayOrder = sessionNumber
        WHERE displayOrder = 0;
      ''');
    } catch (_) {}

    // 5. Indexes
    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_course_sessions_planned ON course_sessions(plannedDate, completionStatus);',
      'CREATE INDEX IF NOT EXISTS idx_course_sessions_course_status ON course_sessions(courseId, completionStatus);',
      'CREATE INDEX IF NOT EXISTS idx_course_sessions_completedAt ON course_sessions(completedAt);',
      'CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status, isArchived);',
      'CREATE INDEX IF NOT EXISTS idx_courses_linkedGoalId ON courses(linkedGoalId);',
    ];

    for (final sql in indexes) {
      try {
        await db.execute(sql);
      } catch (_) {}
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV51 extends Migration {
  @override
  int get version => 51;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS station_bundles (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          description TEXT,
          category TEXT NOT NULL,
          itemsJson TEXT NOT NULL,
          isUserTemplate INTEGER NOT NULL DEFAULT 0,
          usageCount INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV52 extends Migration {
  @override
  int get version => 52;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('ALTER TABLE ss_workout_plan ADD COLUMN week INTEGER NOT NULL DEFAULT 1;');
    } catch (_) {}

    try {
      await db.execute("ALTER TABLE ss_workout_plan ADD COLUMN executionMode TEXT NOT NULL DEFAULT 'LINEAR';");
    } catch (_) {}

    try {
      await db.execute('ALTER TABLE ss_user_profile ADD COLUMN programStartDate TEXT;');
    } catch (_) {}

    try {
      await db.execute('ALTER TABLE ss_user_profile ADD COLUMN deloadEveryNWeeks INTEGER NOT NULL DEFAULT 4;');
    } catch (_) {}

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_plan_schedule (
          id TEXT PRIMARY KEY,
          planId TEXT NOT NULL,
          scheduledDate TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'PENDING',
          sessionId TEXT,
          shiftedFromDate TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(planId) REFERENCES ss_workout_plan(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS idx_ss_plan_schedule_date ON ss_plan_schedule(scheduledDate);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ss_plan_schedule_plan ON ss_plan_schedule(planId);');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_exercise_pr (
          id TEXT PRIMARY KEY,
          exerciseId TEXT NOT NULL,
          prType TEXT NOT NULL,
          value REAL NOT NULL,
          sessionId TEXT,
          achievedAt INTEGER NOT NULL,
          UNIQUE(exerciseId, prType)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS ss_session_set_log (
          id TEXT PRIMARY KEY,
          sessionId TEXT NOT NULL,
          exerciseId TEXT NOT NULL,
          setNumber INTEGER NOT NULL,
          weight REAL,
          reps INTEGER,
          rir INTEGER,
          durationSeconds INTEGER,
          isCompleted INTEGER NOT NULL DEFAULT 1,
          loggedAt INTEGER NOT NULL,
          FOREIGN KEY(sessionId) REFERENCES ss_workout_session_log(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ss_set_log_session ON ss_session_set_log(sessionId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_ss_set_log_exercise ON ss_session_set_log(exerciseId);');
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV53 extends Migration {
  @override
  int get version => 53;

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS movement_kinds (
          code TEXT PRIMARY KEY,
          titleFa TEXT NOT NULL,
          emoji TEXT NOT NULL,
          family TEXT NOT NULL,
          baseMet REAL NOT NULL,
          metLow REAL NOT NULL,
          metHigh REAL NOT NULL,
          primaryMetric TEXT,
          secondaryMetric TEXT,
          isOutdoor INTEGER NOT NULL DEFAULT 0,
          isSocial INTEGER NOT NULL DEFAULT 0,
          needsVenue INTEGER NOT NULL DEFAULT 0,
          seasonMask TEXT,
          jointImpact INTEGER NOT NULL DEFAULT 1,
          aliasesFa TEXT,
          isCustom INTEGER NOT NULL DEFAULT 0,
          isEnabled INTEGER NOT NULL DEFAULT 1,
          usageCount INTEGER NOT NULL DEFAULT 0,
          lastUsedAt INTEGER,
          sortOrder INTEGER NOT NULL DEFAULT 0,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_movement_kinds_family ON movement_kinds(family);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_movement_kinds_usage ON movement_kinds(usageCount DESC);');

    await safeAddColumn(db, 'workout_logs', 'kind', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'distanceMeters', 'REAL');
    await safeAddColumn(db, 'workout_logs', 'elevationMeters', 'REAL');
    await safeAddColumn(db, 'workout_logs', 'laps', 'INTEGER');
    await safeAddColumn(db, 'workout_logs', 'steps', 'INTEGER');
    await safeAddColumn(db, 'workout_logs', 'avgHeartRate', 'INTEGER');
    await safeAddColumn(db, 'workout_logs', 'metMinutes', 'REAL');
    await safeAddColumn(db, 'workout_logs', 'caloriesKcal', 'REAL');
    await safeAddColumn(db, 'workout_logs', 'venue', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'companions', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'sourceModule', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'metricsJson', 'TEXT');
    await safeAddColumn(db, 'workout_logs', 'endedAt', 'INTEGER');

    await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_logs_kind ON workout_logs(kind);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_workout_logs_met ON workout_logs(loggedAt, metMinutes);');

    await safeAddColumn(db, 'routines', 'movementKind', 'TEXT');
    await safeAddColumn(db, 'routines', 'movementTargetMetric', 'TEXT');
    await safeAddColumn(db, 'routines', 'movementTargetValue', 'REAL');
    await safeAddColumn(db, 'routines', 'movementVenue', 'TEXT');
    await safeAddColumn(db, 'routines', 'movementIsMeetup', 'INTEGER DEFAULT 0');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS movement_budget (
          id TEXT PRIMARY KEY DEFAULT 'default',
          weeklyMetMinutesTarget REAL NOT NULL DEFAULT 500,
          weeklyActiveDaysTarget INTEGER NOT NULL DEFAULT 4,
          isAutoAdjusted INTEGER NOT NULL DEFAULT 1,
          updatedAt INTEGER NOT NULL
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS movement_pr (
          id TEXT PRIMARY KEY,
          kind TEXT NOT NULL,
          prType TEXT NOT NULL,
          value REAL NOT NULL,
          logId TEXT,
          achievedAt INTEGER NOT NULL,
          UNIQUE(kind, prType)
      );
    ''');

    // T7: Migrate legacy workout_logs.type -> kind and compute metMinutes + caloriesKcal
    try {
      final legacyRows = await db.query('workout_logs', where: 'kind IS NULL OR kind = ""');
      for (final row in legacyRows) {
        final id = row['id'] as String;
        final rawType = (row['type'] as String? ?? '').toUpperCase();
        final duration = (row['durationMinutes'] as num? ?? 0).toInt();

        String newKind = 'OTHER';
        double met = 4.0;

        if (rawType == 'SWIMMING') {
          newKind = 'SWIMMING';
          met = 7.0;
        } else if (rawType == 'CYCLING') {
          newKind = 'CYCLING';
          met = 7.5;
        } else if (rawType == 'RUNNING') {
          newKind = 'RUNNING';
          met = 9.0;
        } else if (rawType == 'WALKING') {
          newKind = 'WALKING';
          met = 3.5;
        } else if (rawType == 'CARDIO') {
          newKind = 'CARDIO_GENERIC';
          met = 6.0;
        } else if (rawType == 'STRENGTH' ||
            ['CHEST', 'BACK', 'LEGS', 'ABS', 'FULLBODY', 'SHOULDERS', 'ARMS'].contains(rawType)) {
          newKind = 'STRENGTH_GYM';
          met = 5.0;
        }

        final metMins = met * duration;
        final calories = (met * 3.5 * 70.0 / 200.0) * duration;

        await db.update(
          'workout_logs',
          {
            'kind': newKind,
            'metMinutes': metMins,
            'caloriesKcal': calories,
            'sourceModule': 'MOVEMENT',
          },
          where: 'id = ?',
          whereArgs: [id],
        );
      }
    } catch (_) {}

    try {
      await db.execute("UPDATE routine_completions SET resultType = 'FULL' WHERE resultType = 'COMPLETED';");
    } catch (_) {}

    try {
      await db.execute('ALTER TABLE routine_completions ADD COLUMN partialRatio REAL;');
    } catch (_) {}

    try {
      await db.execute('''
        UPDATE routines
        SET lightDurationMinutes   = MAX(5, MIN(CAST(ROUND(targetDurationMinutes * 0.5) AS INTEGER), targetDurationMinutes - 1)),
            minimalDurationMinutes = MAX(2, MIN(CAST(ROUND(targetDurationMinutes * 0.15) AS INTEGER), 10))
        WHERE targetDurationMinutes > 5
          AND (category IS NULL OR category != 'medical')
          AND (lightDurationMinutes IS NULL OR lightDurationMinutes = 0);
      ''');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS skip_reasons (
          id TEXT PRIMARY KEY,
          itemId TEXT,
          domain TEXT,
          dateStr TEXT,
          reason TEXT,
          note TEXT,
          createdAt INTEGER
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_skip_reasons_item ON skip_reasons(itemId);');
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV54 extends Migration {
  @override
  int get version => 54;

  @override
  Future<void> up(Database db) async {
    // 1. Data Migration from legacy workout_split_days to ss_user_profile
    try {
      final legacySplitRows = await db.query('workout_split_days');
      if (legacySplitRows.isNotEmpty) {
        final daysCount = legacySplitRows.where((r) => (r['isRest'] as int? ?? 0) == 0).length;
        if (daysCount > 0) {
          await db.execute('''
            UPDATE ss_user_profile 
            SET workoutDaysPerWeek = ? 
            WHERE id = 'default' AND (workoutDaysPerWeek IS NULL OR workoutDaysPerWeek = 0);
          ''', [daysCount]);
        }
      }
    } catch (_) {}

    // 2. Drop obsolete workout_split_days table
    try {
      await db.execute('DROP TABLE IF EXISTS workout_split_days;');
    } catch (_) {}

    // 3. Drop duplicate set log table ss_workout_set_log if exists
    try {
      await db.execute('DROP TABLE IF EXISTS ss_workout_set_log;');
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV55 extends Migration {
  @override
  int get version => 55;

  @override
  Future<void> up(Database db) async {
    try {
      final corruptOverRows = await db.query(
        'routines',
        columns: ['id', 'title', 'targetDurationMinutes'],
        where: 'targetDurationMinutes > 480',
      );
      if (corruptOverRows.isNotEmpty) {
        debugPrint('[MigrationV55] Found ${corruptOverRows.length} routines with targetDurationMinutes > 480: $corruptOverRows');
        await db.execute('UPDATE routines SET targetDurationMinutes = 480 WHERE targetDurationMinutes > 480;');
      }

      final corruptUnderRows = await db.query(
        'routines',
        columns: ['id', 'title', 'targetDurationMinutes'],
        where: 'targetDurationMinutes <= 0',
      );
      if (corruptUnderRows.isNotEmpty) {
        debugPrint('[MigrationV55] Found ${corruptUnderRows.length} routines with targetDurationMinutes <= 0: $corruptUnderRows');
        await db.execute('UPDATE routines SET targetDurationMinutes = NULL WHERE targetDurationMinutes <= 0;');
      }
    } catch (e) {
      debugPrint('[MigrationV55] Error during corrupt data cleanup: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV56 extends Migration {
  @override
  int get version => 56;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS skip_reasons (
          id TEXT PRIMARY KEY,
          itemId TEXT NOT NULL,
          domain TEXT NOT NULL,
          dateStr TEXT NOT NULL,
          reason TEXT NOT NULL,
          note TEXT,
          createdAt INTEGER NOT NULL
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_skip_reasons_item ON skip_reasons(itemId, dateStr);');
    } catch (e) {
      debugPrint('[MigrationV56] Error creating skip_reasons table: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV57 extends Migration {
  @override
  int get version => 57;

  @override
  Future<void> up(Database db) async {
    int backfilledCompletions = 0;
    int matchedDebts = 0;
    int unmatchedDebts = 0;

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS worship_completions (
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

      await db.execute('CREATE INDEX IF NOT EXISTS idx_worship_completions_date ON worship_completions(dateStr);');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_worship_completions_practice ON worship_completions(practiceId, dateStr);');

      // Add columns to worship_debts if not existing
      final debtColumns = await db.rawQuery("PRAGMA table_info(worship_debts)");
      final colNames = debtColumns.map((c) => c['name'] as String).toSet();

      if (!colNames.contains('practiceId')) {
        await db.execute('ALTER TABLE worship_debts ADD COLUMN practiceId TEXT;');
        await db.execute('CREATE INDEX IF NOT EXISTS idx_worship_debts_practiceId ON worship_debts(practiceId);');
      }

      if (!colNames.contains('sourceKind')) {
        await db.execute("ALTER TABLE worship_debts ADD COLUMN sourceKind TEXT DEFAULT 'MANUAL';");
      }

      // Backfill worship_completions from worship_practices
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final practicesToBackfill = await db.query(
        'worship_practices',
        where: 'dailyDoneDate IS NOT NULL AND dailyDoneDate != "" AND dailyDone != 0',
      );

      for (final p in practicesToBackfill) {
        final practiceId = p['id'] as String;
        final dateStr = p['dailyDoneDate'] as String;
        final practiceType = p['practiceType'] as String? ?? 'PRAYER';
        final dailyDone = p['dailyDone'] as int? ?? 0;
        final resultType = dailyDone == -1 ? 'SKIPPED' : 'DONE';
        final countDone = dailyDone > 0 ? dailyDone : 1;
        final countTarget = p['dailyTarget'] as int?;
        final id = 'wc_backfill_${practiceId}_$dateStr';

        try {
          await db.insert(
            'worship_completions',
            {
              'id': id,
              'practiceId': practiceId,
              'dateStr': dateStr,
              'practiceType': practiceType,
              'resultType': resultType,
              'countDone': countDone,
              'countTarget': countTarget,
              'loggedAt': nowMs,
              'createdAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          backfilledCompletions++;
        } catch (_) {}
      }

      // Backfill practiceId on worship_debts
      final debtsToMatch = await db.query(
        'worship_debts',
        where: 'autoCreated = 1 AND (practiceId IS NULL OR practiceId = "")',
      );

      for (final debt in debtsToMatch) {
        final debtId = debt['id'] as String;
        final title = debt['title'] as String;

        final matches = await db.query(
          'worship_practices',
          where: 'title = ?',
          whereArgs: [title],
        );

        if (matches.length == 1) {
          final practiceId = matches.first['id'] as String;
          await db.update(
            'worship_debts',
            {'practiceId': practiceId},
            where: 'id = ?',
            whereArgs: [debtId],
          );
          matchedDebts++;
        } else {
          unmatchedDebts++;
        }
      }

      debugPrint('[MigrationV57] Completed. Backfilled completions count: $backfilledCompletions, matched debts: $matchedDebts, unmatched debts: $unmatchedDebts');
    } catch (e) {
      debugPrint('[MigrationV57] Error during migration V57: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV58 extends Migration {
  @override
  int get version => 58;

  @override
  Future<void> up(Database db) async {
    try {
      final nowMs = DateTime.now().millisecondsSinceEpoch;

      final onboardingRows = await db.query(
        'app_settings',
        where: "key = 'onboarding_completed'",
        limit: 1,
      );

      final isCompleted = onboardingRows.isNotEmpty && onboardingRows.first['value'] == 'true';

      if (!isCompleted) {
        final homeCityRows = await db.query(
          'app_settings',
          where: "key = 'home_city_id'",
          limit: 1,
        );
        final userNameRows = await db.query(
          'app_settings',
          where: "key = 'user_name'",
          limit: 1,
        );
        final routineCount = Sqflite.firstIntValue(
          await db.rawQuery('SELECT COUNT(*) FROM routines'),
        ) ?? 0;

        if (homeCityRows.isNotEmpty || userNameRows.isNotEmpty || routineCount > 0) {
          await db.insert(
            'app_settings',
            {
              'key': 'onboarding_completed',
              'value': 'true',
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          await db.insert(
            'app_settings',
            {
              'key': 'onboarding_version',
              'value': '1',
              'updatedAt': nowMs,
            },
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
          debugPrint('[MigrationV58] Rescued user from onboarding loop.');
        }
      }

      final onboardingRoutines = await db.query(
        'routines',
        where: "description = 'اولین روتین ثبت‌شده در آنبوردینگ'",
      );

      if (onboardingRoutines.length > 1) {
        final grouped = <String, List<Map<String, dynamic>>>{};
        for (final r in onboardingRoutines) {
          final title = r['title']! as String;
          grouped.putIfAbsent(title, () => []).add(r);
        }

        int purgedCount = 0;
        for (final entries in grouped.values) {
          if (entries.length > 1) {
            entries.sort((a, b) => (a['createdAt'] as int? ?? 0).compareTo(b['createdAt'] as int? ?? 0));
            for (int i = 1; i < entries.length; i++) {
              final dupId = entries[i]['id']! as String;
              await db.delete('routines', where: 'id = ?', whereArgs: [dupId]);
              await db.delete('routine_schedules', where: 'routineId = ?', whereArgs: [dupId]);
              await db.delete('routine_occurrences', where: 'routineId = ?', whereArgs: [dupId]);
              purgedCount++;
            }
          }
        }
        debugPrint('[MigrationV58] Purged $purgedCount duplicate onboarding routines.');
      }
    } catch (e) {
      debugPrint('[MigrationV58] Error during migration V58: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV59 extends Migration {
  @override
  int get version => 59;

  @override
  Future<void> up(Database db) async {
    try {
      final schedules = await db.query('routine_schedules');
      int updatedRuleCount = 0;
      for (final sched in schedules) {
        final id = sched['id'] as String;
        final timeOfDay = sched['timeOfDay'] as String? ?? '08:00';
        final ruleStr = sched['recurrenceRule'] as String?;
        if (ruleStr != null && ruleStr.isNotEmpty) {
          try {
            final ruleMap = jsonDecode(ruleStr) as Map<String, dynamic>;
            final times = ruleMap['reminderTimes'] as List<dynamic>?;
            if (times == null || times.isEmpty) {
              ruleMap['reminderTimes'] = [timeOfDay];
              await db.update(
                'routine_schedules',
                {'recurrenceRule': jsonEncode(ruleMap)},
                where: 'id = ?',
                whereArgs: [id],
              );
              updatedRuleCount++;
            }
          } catch (_) {}
        }
      }

      final nowStr = DateTime.now().toIso8601String().split('T').first;
      int syncedOccurrencesCount = 0;
      for (final sched in schedules) {
        final rId = sched['routineId'] as String?;
        final timeOfDay = sched['timeOfDay'] as String?;
        if (rId != null && timeOfDay != null && timeOfDay.isNotEmpty && timeOfDay != '08:00') {
          final count = await db.update(
            'routine_occurrences',
            {'scheduled_time': timeOfDay},
            where: "routine_id = ? AND date >= ? AND status = 'pending' AND (scheduled_time = '08:00' OR scheduled_time IS NULL)",
            whereArgs: [rId, nowStr],
          );
          syncedOccurrencesCount += count;
        }
      }

      final cancelledCount = await db.update(
        'pending_reminders',
        {'state': 'cancelled'},
        where: "state = 'CANCELLED'",
      );

      final routines = await db.query('routines', where: 'targetDurationMinutes > 0');
      int backfilledDurationCount = 0;
      for (final r in routines) {
        final id = r['id'] as String;
        final target = r['targetDurationMinutes'] as int? ?? 0;
        final light = r['lightDurationMinutes'] as int? ?? 0;
        final minimal = r['minimalDurationMinutes'] as int? ?? 0;

        if (light == 0 || minimal == 0) {
          final computedLight = (target * 0.75).round().clamp(5, 1440);
          final computedMinimal = (target * 0.50).round().clamp(5, 1440);
          await db.update(
            'routines',
            {
              'lightDurationMinutes': light == 0 ? computedLight : light,
              'minimalDurationMinutes': minimal == 0 ? computedMinimal : minimal,
            },
            where: 'id = ?',
            whereArgs: [id],
          );
          backfilledDurationCount++;
        }
      }

      debugPrint('[MigrationV59] Applied: rules=$updatedRuleCount, occurrences=$syncedOccurrencesCount, cancelledState=$cancelledCount, durations=$backfilledDurationCount');
    } catch (e) {
      debugPrint('[MigrationV59] Error during migration V59: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV60 extends Migration {
  @override
  int get version => 60;

  @override
  Future<void> up(Database db) async {
    try {
      // 1. De-duplicate routine_completions keeping the latest record
      await db.execute('''
        DELETE FROM routine_completions
        WHERE id NOT IN (
          SELECT id FROM (
            SELECT id, ROW_NUMBER() OVER (
              PARTITION BY routineId, completionDate, resultType
              ORDER BY createdAt DESC, id DESC
            ) as row_num
            FROM routine_completions
          ) WHERE row_num = 1
        );
      ''');

      // 2. Create unique index on routine_completions
      await db.execute('''
        CREATE UNIQUE INDEX IF NOT EXISTS idx_uniq_routine_completions_routine_date_result
        ON routine_completions(routineId, completionDate, resultType);
      ''');

      // 3. Create routine_actual_completions view
      await db.execute('''
        CREATE VIEW IF NOT EXISTS routine_actual_completions AS
        SELECT * FROM routine_completions
        WHERE resultType IN ('FULL', 'PARTIAL', 'MINIMAL', 'DONE', 'LIGHT', 'COMPLETED');
      ''');

      debugPrint('[MigrationV60] Applied unique index and routine_actual_completions view');
    } catch (e) {
      debugPrint('[MigrationV60] Error applying migration V60: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV61 extends Migration {
  @override
  int get version => 61;

  @override
  Future<void> up(Database db) async {
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS active_timers (
            id TEXT PRIMARY KEY,
            domain TEXT,
            itemId TEXT,
            mode TEXT,
            direction TEXT,
            targetTimestamp INTEGER,
            durationSeconds INTEGER,
            createdAt INTEGER,
            routineId TEXT,
            startedAt INTEGER,
            plannedDurationMinutes INTEGER,
            pausedAccumulatedMs INTEGER DEFAULT 0,
            state TEXT DEFAULT 'RUNNING'
        );
      ''');

      final columns = <String>{};
      final info = await db.rawQuery('PRAGMA table_info(active_timers);');
      for (final col in info) {
        final name = col['name'] as String?;
        if (name != null) columns.add(name);
      }

      if (!columns.contains('domain')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN domain TEXT;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }
      if (!columns.contains('itemId')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN itemId TEXT;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }
      if (!columns.contains('mode')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN mode TEXT;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }
      if (!columns.contains('direction')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN direction TEXT;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }
      if (!columns.contains('targetTimestamp')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN targetTimestamp INTEGER;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }
      if (!columns.contains('durationSeconds')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN durationSeconds INTEGER;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }
      if (!columns.contains('createdAt')) {
        try { await db.execute('ALTER TABLE active_timers ADD COLUMN createdAt INTEGER;'); } catch (e) { debugPrint('[MigrationV61] $e'); }
      }

      debugPrint('[MigrationV61] Successfully aligned active_timers table schema');
    } catch (e) {
      debugPrint('[MigrationV61] Error applying migration V61: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

/// T3 (prompt-045): Deduplicate routine_completions for non-interval routines.
/// Keeps the most recent row per (routineId, completionDate); removes older duplicates.
/// Interval routines (routineId with intervalHours > 0 in routine_schedules) are
/// excluded because multiple completions in one day are intentional for them.
class MigrationV62 extends Migration {
  @override
  int get version => 62;

  @override
  Future<void> up(Database db) async {
    try {
      // 1. Find all non-interval routineIds
      final intervalIds = (await db.rawQuery(
        'SELECT DISTINCT routineId FROM routine_schedules WHERE intervalHours > 0',
      )).map((r) => r['routineId'] as String).toSet();

      // 2. Find duplicate (routineId, completionDate) groups among non-interval routines
      final duplicates = await db.rawQuery('''
        SELECT routineId, completionDate, COUNT(*) as c
          FROM routine_completions
         GROUP BY routineId, completionDate
        HAVING c > 1
      ''');

      var mergedCount = 0;

      for (final dup in duplicates) {
        final rid = dup['routineId'] as String;
        final dateStr = dup['completionDate'] as String;

        // Skip interval routines — multiple completions per day is correct
        if (intervalIds.contains(rid)) continue;

        // Find the most recent row's id
        final rows = await db.rawQuery(
          'SELECT id FROM routine_completions WHERE routineId = ? AND completionDate = ? ORDER BY completionTime DESC',
          [rid, dateStr],
        );

        if (rows.length <= 1) continue;

        // Keep the first (most recent) id, delete the rest
        final deleteIds = rows.skip(1).map((r) => r['id'] as String).toList();

        for (final delId in deleteIds) {
          await db.delete(
            'routine_completions',
            where: 'id = ?',
            whereArgs: [delId],
          );
          mergedCount++;
        }
      }

      debugPrint('[MigrationV62] Merged $mergedCount duplicate completion rows for non-interval routines.');
    } catch (e) {
      debugPrint('[MigrationV62] Error: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

/// MigrationV63: Ensure active_timers table columns are safely aligned
/// and compatible with both legacy and new RitmoTimerService inserts.
class MigrationV63 extends Migration {
  @override
  int get version => 63;

  @override
  Future<void> up(Database db) async {
    try {
      await safeAddColumn(db, 'active_timers', 'domain', 'TEXT');
      await safeAddColumn(db, 'active_timers', 'itemId', 'TEXT');
      await safeAddColumn(db, 'active_timers', 'mode', 'TEXT');
      await safeAddColumn(db, 'active_timers', 'direction', 'TEXT');
      await safeAddColumn(db, 'active_timers', 'targetTimestamp', 'INTEGER');
      await safeAddColumn(db, 'active_timers', 'durationSeconds', 'INTEGER');
      await safeAddColumn(db, 'active_timers', 'createdAt', 'INTEGER');
      await safeAddColumn(db, 'active_timers', 'routineId', 'TEXT');
      await safeAddColumn(db, 'active_timers', 'startedAt', 'INTEGER');
      await safeAddColumn(db, 'active_timers', 'plannedDurationMinutes', 'INTEGER');
      debugPrint('[MigrationV63] Successfully aligned active_timers schema.');
    } catch (e) {
      debugPrint('[MigrationV63] Error: $e');
    }
  }

  @override
  Future<void> down(Database db) async {}
}

class MigrationV64 extends Migration {
  @override
  int get version => 64;

  @override
  Future<void> up(Database db) async {
    // M1: goal_steps columns
    final stepCols = [
      'ALTER TABLE goal_steps ADD COLUMN completedAt INTEGER;',
      "ALTER TABLE goal_steps ADD COLUMN completionRule TEXT DEFAULT 'MANUAL';",
      'ALTER TABLE goal_steps ADD COLUMN ruleConfig TEXT;',
      'ALTER TABLE goal_steps ADD COLUMN dependsOnStepId TEXT;',
      'ALTER TABLE goal_steps ADD COLUMN reminderEnabled INTEGER DEFAULT 0;',
      'ALTER TABLE goal_steps ADD COLUMN reminderTime TEXT;',
      'ALTER TABLE goal_steps ADD COLUMN estimatedMinutes INTEGER;',
      'ALTER TABLE goal_steps ADD COLUMN notes TEXT;',
    ];
    for (final sql in stepCols) {
      try { await db.execute(sql); } catch (_) {}
    }

    try {
      await db.execute('''
        UPDATE goal_steps
           SET completedAt = COALESCE(
                 CASE WHEN scheduledDate IS NOT NULL AND scheduledDate != ''
                      THEN CAST(strftime('%s', scheduledDate) AS INTEGER) * 1000 END,
                 createdAt)
         WHERE isCompleted = 1 AND completedAt IS NULL;
      ''');
    } catch (_) {}

    try {
      await db.execute("UPDATE goal_steps SET completionRule = 'MANUAL' WHERE completionRule IS NULL;");
    } catch (_) {}

    // M2: goals columns
    final goalCols = [
      'ALTER TABLE goals ADD COLUMN completedAt INTEGER;',
      'ALTER TABLE goals ADD COLUMN completionSource TEXT;',
      'ALTER TABLE goals ADD COLUMN lastActivityAt INTEGER;',
      'ALTER TABLE goals ADD COLUMN weight REAL DEFAULT 1.0;',
      'ALTER TABLE goals ADD COLUMN whyItMatters TEXT;',
      'ALTER TABLE goals ADD COLUMN pastFailure TEXT;',
      'ALTER TABLE goals ADD COLUMN selfPromise TEXT;',
      'ALTER TABLE goals ADD COLUMN metricUnit TEXT;',
      'ALTER TABLE goals ADD COLUMN metricTarget REAL;',
      'ALTER TABLE goals ADD COLUMN metricStart REAL;',
      'ALTER TABLE goals ADD COLUMN pausedAt INTEGER;',
      'ALTER TABLE goals ADD COLUMN abandonedAt INTEGER;',
      'ALTER TABLE goals ADD COLUMN abandonReason TEXT;',
      'ALTER TABLE goals ADD COLUMN iconKey TEXT;',
      'ALTER TABLE goals ADD COLUMN isPrivate INTEGER DEFAULT 0;',
    ];
    for (final sql in goalCols) {
      try { await db.execute(sql); } catch (_) {}
    }

    try {
      await db.execute("UPDATE goals SET completionSource = 'MANUAL' WHERE status = 'COMPLETED' AND completionSource IS NULL;");
    } catch (_) {}

    // M3: Orphan cleanup, direct self-loops, and indexes
    try {
      await db.execute('DELETE FROM goal_steps WHERE goalId NOT IN (SELECT id FROM goals);');
    } catch (_) {}

    try {
      await db.execute("UPDATE goals SET parentGoalId = NULL WHERE parentGoalId IS NOT NULL AND parentGoalId != '' AND parentGoalId NOT IN (SELECT id FROM goals);");
    } catch (_) {}

    try {
      await db.execute('UPDATE goals SET parentGoalId = NULL WHERE parentGoalId = id;');
    } catch (_) {}

    final indexes = [
      'CREATE INDEX IF NOT EXISTS idx_goal_steps_goalId ON goal_steps(goalId);',
      'CREATE INDEX IF NOT EXISTS idx_goal_steps_scheduled ON goal_steps(scheduledDate);',
      'CREATE INDEX IF NOT EXISTS idx_goal_steps_routine ON goal_steps(linkedRoutineId);',
      'CREATE INDEX IF NOT EXISTS idx_goals_parent ON goals(parentGoalId);',
      'CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);',
      'CREATE INDEX IF NOT EXISTS idx_rc_routine_date ON routine_completions(routineId, completionDate);',
    ];
    for (final sql in indexes) {
      try { await db.execute(sql); } catch (_) {}
    }

    // M4: New tables goal_checkins and goal_reviews
    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goal_checkins (
          id TEXT PRIMARY KEY,
          goalId TEXT NOT NULL REFERENCES goals(id) ON DELETE CASCADE,
          dateIso TEXT NOT NULL,
          kind TEXT NOT NULL,
          value REAL,
          note TEXT,
          createdAt INTEGER NOT NULL
        );
      ''');
      await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_checkins_goal_date ON goal_checkins(goalId, dateIso);');
    } catch (_) {}

    try {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS goal_reviews (
          id TEXT PRIMARY KEY,
          weekStartIso TEXT NOT NULL UNIQUE,
          completedStepCount INTEGER NOT NULL DEFAULT 0,
          rescheduledStepCount INTEGER NOT NULL DEFAULT 0,
          answers TEXT,
          createdAt INTEGER NOT NULL
        );
      ''');
    } catch (_) {}
  }

  @override
  Future<void> down(Database db) async {}
}


