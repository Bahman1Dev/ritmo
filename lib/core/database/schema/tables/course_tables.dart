import 'package:sqflite/sqflite.dart';

class CourseTables {
  static Future<void> create(Database db) async {
    // 9. courses table
    await db.execute('''
      CREATE TABLE courses (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          totalSessions INTEGER NOT NULL CHECK(totalSessions > 0),
          sessionDurationMinutes INTEGER NOT NULL CHECK(sessionDurationMinutes BETWEEN 1 AND 600),
          activityType TEXT NOT NULL,
          zoneId TEXT,
          isArchived INTEGER NOT NULL DEFAULT 0,
          energyRule TEXT NOT NULL DEFAULT 'NONE',
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          courseType TEXT NOT NULL DEFAULT 'VIDEO',
          unitLabel TEXT,
          emoji TEXT,
          colorHex TEXT,
          provider TEXT,
          weeklyTargetSessions INTEGER NOT NULL DEFAULT 3 CHECK(weeklyTargetSessions BETWEEN 1 AND 21),
          isAdaptive INTEGER NOT NULL DEFAULT 0,
          preferredDays TEXT,
          preferredTime TEXT,
          reminderEnabled INTEGER NOT NULL DEFAULT 0,
          linkedGoalId TEXT,
          status TEXT NOT NULL DEFAULT 'ACTIVE' CHECK(status IN ('ACTIVE','PAUSED','COMPLETED')),
          completedAt INTEGER,
          targetEndDate TEXT,
          adaptiveLastAppliedAt INTEGER,
          masteryScore REAL NOT NULL DEFAULT 0,
          reviewEnabled INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(zoneId) REFERENCES zones(id) ON DELETE SET NULL,
          FOREIGN KEY(linkedGoalId) REFERENCES goals(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_courses_zoneId ON courses(zoneId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_courses_status ON courses(status, isArchived);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_courses_linkedGoalId ON courses(linkedGoalId);');

    // 10. course_sessions table
    await db.execute('''
      CREATE TABLE course_sessions (
          id TEXT PRIMARY KEY,
          courseId TEXT NOT NULL,
          sessionNumber INTEGER NOT NULL,
          plannedDate TEXT,
          completionStatus TEXT NOT NULL CHECK(completionStatus IN ('PENDING','COMPLETED','SKIPPED')),
          actualDurationMinutes INTEGER,
          note TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          sessionTitle TEXT,
          completedAt INTEGER,
          isUserScheduled INTEGER NOT NULL DEFAULT 0,
          plannedStartTime TEXT,
          estimatedDurationMinutes INTEGER,
          sectionTitle TEXT,
          learningObjective TEXT,
          difficulty INTEGER CHECK(difficulty IS NULL OR difficulty BETWEEN 1 AND 5),
          activityKind TEXT NOT NULL DEFAULT 'LEARN' CHECK(activityKind IN ('LEARN','PRACTICE','REVIEW','PROJECT','EXAM')),
          understandingScore INTEGER CHECK(understandingScore IS NULL OR understandingScore BETWEEN 1 AND 5),
          needsReview INTEGER NOT NULL DEFAULT 0,
          keyTakeaway TEXT,
          openQuestion TEXT,
          sourceSessionId TEXT,
          displayOrder INTEGER NOT NULL DEFAULT 0,
          FOREIGN KEY(courseId) REFERENCES courses(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE UNIQUE INDEX IF NOT EXISTS index_course_sessions_courseId_sessionNumber ON course_sessions(courseId, sessionNumber);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_course_sessions_planned ON course_sessions(plannedDate, completionStatus);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_course_sessions_course_status ON course_sessions(courseId, completionStatus);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_course_sessions_completedAt ON course_sessions(completedAt);');

    // 11. course_active_timers table
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
  }
}
