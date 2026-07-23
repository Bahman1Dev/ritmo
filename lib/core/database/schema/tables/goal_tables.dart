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
          createdAt INTEGER NOT NULL,
          updatedAt INTEGER NOT NULL,
          FOREIGN KEY(parentGoalId) REFERENCES goals(id) ON DELETE CASCADE
      );
    ''');
    await db.execute('CREATE INDEX index_goals_parentGoalId ON goals(parentGoalId);');

    // 28. goal_steps (V2 table)
    await db.execute('''
      CREATE TABLE goal_steps (
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
    await db.execute('CREATE INDEX index_goal_steps_goalId ON goal_steps(goalId);');
  }
}
