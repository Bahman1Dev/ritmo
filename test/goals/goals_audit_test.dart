import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/goals_engine.dart';
import 'package:ritmo/features/goals/logic/goal_progress_calculator.dart';
import 'package:ritmo/features/goals/logic/goals_repository.dart';
import 'package:ritmo/features/goals/models/goal_models.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:ritmo/core/database/database_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  group('Goals Audit & Prompt 046 Fixes Tests', () {
    late Database db;

    setUp(() async {
      databaseFactory = databaseFactoryFfi;
      db = await openDatabase(inMemoryDatabasePath, version: 1, onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE goals (
            id TEXT PRIMARY KEY,
            parentGoalId TEXT,
            title TEXT NOT NULL,
            description TEXT,
            goalType TEXT NOT NULL,
            status TEXT NOT NULL DEFAULT 'ACTIVE',
            targetDate TEXT,
            progressCache REAL DEFAULT 0.0,
            isPrivate INTEGER DEFAULT 0,
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
            createdAt INTEGER NOT NULL,
            updatedAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE goal_steps (
            id TEXT PRIMARY KEY,
            goalId TEXT NOT NULL,
            title TEXT NOT NULL,
            isCompleted INTEGER DEFAULT 0,
            displayOrder INTEGER DEFAULT 0,
            createdAt INTEGER NOT NULL,
            completedAt INTEGER,
            scheduledDate TEXT,
            linkedRoutineId TEXT,
            completionRule TEXT DEFAULT 'MANUAL',
            ruleConfig TEXT,
            dependsOnStepId TEXT,
            reminderEnabled INTEGER DEFAULT 0,
            reminderTime TEXT,
            estimatedMinutes INTEGER,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE goal_checkins (
            id TEXT PRIMARY KEY,
            goalId TEXT NOT NULL,
            dateIso TEXT NOT NULL,
            kind TEXT NOT NULL,
            value REAL,
            note TEXT,
            createdAt INTEGER NOT NULL
          )
        ''');
        await db.execute('''
          CREATE TABLE routine_completions (
            id TEXT PRIMARY KEY,
            routineId TEXT NOT NULL,
            completionDate TEXT NOT NULL,
            resultType TEXT NOT NULL,
            createdAt INTEGER NOT NULL
          )
        ''');
      });
      DatabaseHelper.instance.overrideDatabaseForTesting(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('TimelineItem populated with real goalId (Fixes ه-01)', () async {
      final goal = Goal(
        id: 'GOAL_1',
        title: 'تست هدف اصلی',
        goalType: GoalLevel.monthly,
        createdAt: 100,
        updatedAt: 100,
      );
      final step = GoalStep(
        id: 'STEP_1',
        goalId: 'GOAL_1',
        title: 'گام ۱',
        isCompleted: false,
        displayOrder: 0,
        createdAt: 100,
        scheduledDate: '2026-08-07',
      );

      final engine = GoalsEngine();
      final output = await engine.calculate(GoalsEngineInput(
        goals: [goal],
        stepsByGoal: {'GOAL_1': [step]},
        courses: [],
        courseSessions: [],
        konkurSubjects: [],
        konkurTopics: [],
        konkurPlanItems: [],
        routineCompletions: [],
        today: DateTime(2026, 8, 6),
      ));

      expect(output.upcomingTimeline.length, equals(1));
      expect(output.upcomingTimeline.first.goalId, equals('GOAL_1'));
      expect(output.upcomingTimeline.first.sourceId, equals('STEP_1'));
    });

    test('Step toggle updates parent goal progress & lastActivityAt', () async {
      await db.insert('goals', {
        'id': 'G1',
        'title': 'هدف ۱',
        'goalType': 'MONTHLY',
        'status': 'ACTIVE',
        'createdAt': 100,
        'updatedAt': 100,
      });
      await db.insert('goal_steps', {
        'id': 'S1',
        'goalId': 'G1',
        'title': 'گام ۱',
        'isCompleted': 0,
        'displayOrder': 0,
        'createdAt': 100,
        'scheduledDate': '2026-08-07',
      });

      await GoalsRepository.instance.toggleStep('S1', false, 'G1');

      final gRow = (await db.query('goals', where: "id = 'G1'")).first;
      expect(gRow['status'], equals('COMPLETED'));
      expect(gRow['progressCache'], equals(1.0));
      expect(gRow['lastActivityAt'], isNotNull);
    });

    test('addCheckin updates metric goal progress cleanly (Fixes ه-06 & ط10)', () async {
      await db.insert('goals', {
        'id': 'G_METRIC',
        'title': 'کاهش وزن',
        'goalType': 'MONTHLY',
        'status': 'ACTIVE',
        'metricUnit': 'کیلوگرم',
        'metricStart': 80.0,
        'metricTarget': 70.0,
        'createdAt': 100,
        'updatedAt': 100,
      });

      await GoalsRepository.instance.addCheckin(
        goalId: 'G_METRIC',
        value: 75.0,
        note: 'پیشرفت خوب هفته دوم',
      );

      final gRow = (await db.query('goals', where: "id = 'G_METRIC'")).first;
      expect(gRow['progressCache'], equals(75.0));

      final checkins = await db.query('goal_checkins', where: "goalId = 'G_METRIC'");
      expect(checkins.length, equals(1));
      expect(checkins.first['value'], equals(75.0));
    });
  });
}
