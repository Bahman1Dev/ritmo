import 'package:sqflite/sqflite.dart';

class CourseTables {
  static Future<void> create(Database db) async {
    // 9. courses table
    await db.execute('''
      CREATE TABLE courses (
          id TEXT PRIMARY KEY,
          title TEXT NOT NULL,
          totalSessions INTEGER NOT NULL,
          sessionDurationMinutes INTEGER NOT NULL,
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
          weeklyTargetSessions INTEGER NOT NULL DEFAULT 3,
          isAdaptive INTEGER NOT NULL DEFAULT 0,
          preferredDays TEXT,
          preferredTime TEXT,
          reminderEnabled INTEGER NOT NULL DEFAULT 0,
          linkedGoalId TEXT,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          completedAt INTEGER,
          targetEndDate TEXT,
          FOREIGN KEY(zoneId) REFERENCES zones(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX index_courses_zoneId ON courses(zoneId);');

    // 10. course_sessions table
    await db.execute('''
      CREATE TABLE course_sessions (
          id TEXT PRIMARY KEY,
          courseId TEXT NOT NULL,
          sessionNumber INTEGER NOT NULL,
          plannedDate TEXT,
          completionStatus TEXT NOT NULL,
          actualDurationMinutes INTEGER,
          note TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          sessionTitle TEXT,
          FOREIGN KEY(courseId) REFERENCES courses(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE UNIQUE INDEX index_course_sessions_courseId_sessionNumber ON course_sessions(courseId, sessionNumber);');
  }
}
