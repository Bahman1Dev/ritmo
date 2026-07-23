import 'package:sqflite/sqflite.dart';

class SportsTables {
  static Future<void> create(Database db) async {
    // 11.5. workout_logs (V2 table)
    await db.execute('''
      CREATE TABLE workout_logs (
          id TEXT PRIMARY KEY,
          type TEXT NOT NULL,
          durationMinutes INTEGER NOT NULL DEFAULT 0,
          intensity TEXT NOT NULL DEFAULT 'MEDIUM',
          note TEXT,
          loggedAt INTEGER NOT NULL,
          tier TEXT,
          muscleGroups TEXT,
          feeling TEXT,
          location TEXT
      );
    ''');
    await db.execute('CREATE INDEX index_workout_logs_loggedAt ON workout_logs(loggedAt);');

    // 11.6. workout split + recovery (sports v2)
    await db.execute('''
      CREATE TABLE workout_split_days (
        weekday INTEGER PRIMARY KEY,
        muscleGroups TEXT NOT NULL DEFAULT '',
        isRest INTEGER NOT NULL DEFAULT 0,
        updatedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('''
      CREATE TABLE workout_recovery_logs (
        id TEXT PRIMARY KEY,
        date TEXT NOT NULL,
        soreness INTEGER NOT NULL DEFAULT 0,
        fatigue INTEGER NOT NULL DEFAULT 0,
        hydration INTEGER NOT NULL DEFAULT 0,
        note TEXT,
        soreMuscleGroups TEXT DEFAULT '',
        loggedAt INTEGER NOT NULL
      );
    ''');
    await db.execute('CREATE INDEX index_recovery_date ON workout_recovery_logs(date);');

    // 11.7. exercises_library (sports v3)
    await db.execute('''
      CREATE TABLE exercises_library (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        category TEXT NOT NULL,
        equipment TEXT,
        instructions TEXT,
        isCustom INTEGER DEFAULT 0
      );
    ''');

    // 11.8. workout_set_logs (sports v3)
    await db.execute('''
      CREATE TABLE workout_set_logs (
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

    // 11.9. workout_exercise_logs (sports v4 - w.md qualitative feedback)
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

    // 11.10. workout_plan_versions (sports v4 - plan history)
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
}
