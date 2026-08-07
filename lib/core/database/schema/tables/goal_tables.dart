import 'package:sqflite/sqflite.dart';

class GoalTables {
  static Future<void> create(Database db) async {
    // 27. goals (V2 table)
    await db.execute('''
      CREATE TABLE goals (
          id TEXT PRIMARY KEY,
          parentGoalId TEXT,
          title TEXT NOT NULL,
          description TEXT,
          goalType TEXT NOT NULL,
          status TEXT NOT NULL DEFAULT 'ACTIVE',
          targetDate TEXT,
          progressCache REAL NOT NULL DEFAULT 0,
          isPrivate INTEGER NOT NULL DEFAULT 0,
          completedAt INTEGER,
          completionSource TEXT,
          lastActivityAt INTEGER,
          weight REAL DEFAULT 1.0,
          whyItMatters TEXT,
          pastFailure TEXT,
          selfPromise TEXT,
          metricUnit TEXT,
          metricTarget REAL,
          metricStart REAL,
          pausedAt INTEGER,
          abandonedAt INTEGER,
          abandonReason TEXT,
          iconKey TEXT,
          identityStatement TEXT,
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(parentGoalId) REFERENCES goals(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_goals_parentGoalId ON goals(parentGoalId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_parent ON goals(parentGoalId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goals_status ON goals(status);');

    // 28. goal_steps (V2 table)
    await db.execute('''
      CREATE TABLE goal_steps (
          id TEXT PRIMARY KEY,
          goalId TEXT NOT NULL,
          title TEXT NOT NULL,
          isCompleted INTEGER NOT NULL DEFAULT 0,
          displayOrder INTEGER NOT NULL,
          createdAt INTEGER NOT NULL,
          completedAt INTEGER,
          scheduledDate TEXT,
          linkedRoutineId TEXT,
          completionRule TEXT NOT NULL DEFAULT 'MANUAL',
          ruleConfig TEXT,
          dependsOnStepId TEXT,
          reminderEnabled INTEGER NOT NULL DEFAULT 0,
          reminderTime TEXT,
          estimatedMinutes INTEGER,
          notes TEXT,
          FOREIGN KEY(goalId) REFERENCES goals(id) ON DELETE CASCADE,
          FOREIGN KEY(dependsOnStepId) REFERENCES goal_steps(id) ON DELETE SET NULL
      );
    ''');
    await db.execute('CREATE INDEX IF NOT EXISTS index_goal_steps_goalId ON goal_steps(goalId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_steps_goalId ON goal_steps(goalId);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_steps_scheduled ON goal_steps(scheduledDate);');
    await db.execute('CREATE INDEX IF NOT EXISTS idx_goal_steps_routine ON goal_steps(linkedRoutineId);');

    // 29. goal_checkins
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

    // 30. goal_reviews
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
  }
}

