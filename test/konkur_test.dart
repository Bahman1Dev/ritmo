import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/konkur_engine.dart';
import 'package:ritmo/features/konkur/data/konkur_presets.dart';
import 'package:ritmo/features/konkur/logic/konkur_planner.dart';
import 'package:ritmo/features/konkur/models/konkur_models.dart';
import 'package:sqflite/sqflite.dart';

class MockDatabase implements Database {
  final List<Map<String, dynamic>> insertedSubjects = [];
  final List<Map<String, dynamic>> insertedTopics = [];

  @override
  Future<T> transaction<T>(Future<T> Function(Transaction txn) action, {bool? exclusive}) async {
    final mockTxn = MockTransaction(this);
    return action(mockTxn as Transaction);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return null;
  }
}

class MockTransaction implements Transaction {

  MockTransaction(this.db);
  final MockDatabase db;

  @override
  Future<int> insert(String table, Map<String, Object?> values, {String? nullColumnHack, ConflictAlgorithm? conflictAlgorithm}) async {
    if (table == 'konkur_subjects') {
      db.insertedSubjects.add(values);
    } else if (table == 'konkur_topics') {
      db.insertedTopics.add(values);
    }
    return 1;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    if (invocation.memberName == #insert) {
      return insert(
        invocation.positionalArguments[0] as String,
        invocation.positionalArguments[1] as Map<String, Object?>,
      );
    }
    return null;
  }
}

void main() {
  group('Konkur Model Tests - computeNetPercent', () {
    test('calculate percentage correctly with no wrong answers', () {
      final percentage = KonkurMockResult.computeNetPercent(10, 0, 10);
      expect(percentage, 100.0);
    });

    test('calculate percentage correctly with some wrong answers', () {
      final percentage = KonkurMockResult.computeNetPercent(10, 3, 15);
      expect(percentage, closeTo(60.0, 0.001));
    });

    test('allow negative percentage when wrong answers outweigh correct ones', () {
      final percentage = KonkurMockResult.computeNetPercent(1, 6, 10);
      expect(percentage, closeTo(-10.0, 0.001));
    });

    test('clamp maximum to 100.0 if somehow inputs are abnormal', () {
      final percentage = KonkurMockResult.computeNetPercent(15, 0, 10);
      expect(percentage, 100.0);
    });

    test('return 0.0 when total is 0 to prevent division by zero', () {
      final percentage = KonkurMockResult.computeNetPercent(0, 0, 0);
      expect(percentage, 0.0);
    });
  });

  group('Konkur Seeding Tests', () {
    test('seedFieldIntoDb inserts correct subjects and topics for RIYAZI', () async {
      final mockDb = MockDatabase();
      await KonkurPresets.seedFieldIntoDb(mockDb, KonkurField.riyazi);

      expect(mockDb.insertedSubjects.length, 3); // حسابان، فیزیک، شیمی
      expect(mockDb.insertedTopics.length, 3 + 4 + 2); // 3 for math, 4 for physics, 2 for chemistry

      // Verify fields of first subject
      final sub = mockDb.insertedSubjects.first;
      expect(sub['name'], contains('ریاضیات'));
      expect(sub['importanceFactor'], 12.0);
      expect(sub['examQuestionCount'], 40);
      expect(sub['isPreset'], 1);

      // Verify fields of first topic
      final topic = mockDb.insertedTopics.first;
      expect(topic['name'], contains('حسابان'));
      expect(topic['examQuestionCount'], 15);
      expect(topic['masteryLevel'], 'NOT_STARTED');
    });

    test('seedFieldIntoDb includes general subjects when flag is true', () async {
      final mockDb = MockDatabase();
      await KonkurPresets.seedFieldIntoDb(mockDb, KonkurField.riyazi, includeGeneral: true);

      // 3 specialized + 4 general = 7 subjects
      expect(mockDb.insertedSubjects.length, 7);
      // General subjects should be first or included
      final generalSub = mockDb.insertedSubjects.firstWhere((s) => s['subjectGroup'] == 'GENERAL');
      expect(generalSub['name'], contains('ادبیات'));
    });
  });

  group('Konkur Planner Tests', () {
    final subjectMath = KonkurSubject(
      id: 'sub_math',
      name: 'ریاضیات',
      importanceFactor: 12,
      createdAt: 0,
      updatedAt: 0,
    );
    final subjectPhysics = KonkurSubject(
      id: 'sub_phys',
      name: 'فیزیک',
      importanceFactor: 9,
      createdAt: 0,
      updatedAt: 0,
    );

    final topic1 = KonkurTopic(
      id: 't1',
      subjectId: 'sub_math',
      name: 'مشتق',
      examQuestionCount: 5,
      studyTargetMinutes: 180,
      masteryLevel: MasteryLevel.learning,
      createdAt: 0,
      updatedAt: 0,
    );
    final topic2 = KonkurTopic(
      id: 't2',
      subjectId: 'sub_phys',
      name: 'حرکت‌شناسی',
      examQuestionCount: 4,
      studyTargetMinutes: 120,
      createdAt: 0,
      updatedAt: 0,
    );
    final topic3 = KonkurTopic(
      id: 't3',
      subjectId: 'sub_math',
      name: 'ماتریس',
      examQuestionCount: 2,
      studyTargetMinutes: 60,
      masteryLevel: MasteryLevel.mastered, // Mastered! Should not be in main plan
      createdAt: 0,
      updatedAt: 0,
    );

    test('buildPlan distributes only non-mastered topics sorted by priority', () {
      final today = DateTime(2026, 6, 24);
      final examDate = DateTime(2026, 6, 26); // 3 days: 24, 25, 26

      final plan = KonkurPlanner.buildPlan(
        subjects: [subjectMath, subjectPhysics],
        topics: [topic1, topic2, topic3],
        examDate: examDate,
        from: today,
        dailyTargetMinutes: 90,
      );

      // We should only schedule non-mastered: t1 (math, importance 12 * count 5 * learning boost = 78), t2 (physics, importance 9 * count 4 = 36)
      // t1 has higher priority and should be scheduled first
      expect(plan.length, 2);
      expect(plan[0].topicId, 't1');
      expect(plan[0].dateIso, '2026-06-24');
      expect(plan[1].topicId, 't2');
      expect(plan[1].dateIso, '2026-06-25');
    });

    test('buildReviewSlots creates review items for mastered topics due for review', () {
      final today = DateTime(2026, 6, 24);
      
      final masteredTopic = KonkurTopic(
        id: 't_m',
        subjectId: 'sub_math',
        name: 'حد',
        masteryLevel: MasteryLevel.mastered,
        nextReviewDate: '2026-06-23', // Due!
        createdAt: 0,
        updatedAt: 0,
      );

      final reviews = KonkurPlanner.buildReviewSlots(
        mastered: [masteredTopic],
        from: today,
      );

      expect(reviews.length, 1);
      expect(reviews[0].topicId, 't_m');
      expect(reviews[0].plannedMinutes, 30);
    });

    test('daysBehind calculates correct number of pending items in the past', () {
      final today = DateTime(2026, 6, 24);
      
      final items = [
        KonkurPlanItem(id: '1', dateIso: '2026-06-22', createdAt: 0), // Behind
        KonkurPlanItem(id: '2', dateIso: '2026-06-23', status: 'DONE', createdAt: 0),
        KonkurPlanItem(id: '3', dateIso: '2026-06-24', createdAt: 0), // Today
        KonkurPlanItem(id: '4', dateIso: '2026-06-25', createdAt: 0), // Future
      ];

      final behind = KonkurPlanner.daysBehind(planItems: items, today: today);
      expect(behind, 1);
    });
  });

  group('Konkur Engine Tests', () {
    final sub1 = KonkurSubject(id: 's1', name: 'ریاضی', importanceFactor: 12, createdAt: 0, updatedAt: 0);
    final sub2 = KonkurSubject(id: 's2', name: 'فیزیک', importanceFactor: 9, createdAt: 0, updatedAt: 0);

    final topicA = KonkurTopic(
      id: 'ta',
      subjectId: 's1',
      name: 'تابع',
      examQuestionCount: 10,
      masteryLevel: MasteryLevel.mastered, // score 1.0
      createdAt: 0,
      updatedAt: 0,
    );
    final topicB = KonkurTopic(
      id: 'tb',
      subjectId: 's2',
      name: 'حرکت',
      examQuestionCount: 5,
      masteryLevel: MasteryLevel.learning, // score 0.5
      createdAt: 0,
      updatedAt: 0,
    );

    test('calculate engine output correctly', () async {
      final today = DateTime(2026, 6, 24); // Wednesday
      final engine = KonkurEngine();

      final input = KonkurEngineInput(
        subjects: [sub1, sub2],
        topics: [topicA, topicB],
        sessions: [
          KonkurStudySession(id: 's_1', dateIso: '2026-06-23', durationMinutes: 60, createdAt: 0), // Tuesday
          KonkurStudySession(id: 's_2', dateIso: '2026-06-24', durationMinutes: 45, createdAt: 0), // Wednesday (today)
        ],
        mockExams: [
          KonkurMockExam(id: 'e1', title: 'آزمون ۱', examDate: '2026-06-20', createdAt: 0),
        ],
        mockResults: [
          KonkurMockResult(id: 'r1', mockExamId: 'e1', subjectId: 's1', percentage: 75, createdAt: 0),
        ],
        examDateIso: '2026-06-26', // 2 days away
        today: today,
        planItems: [
          KonkurPlanItem(id: 'p1', dateIso: '2026-06-24', createdAt: 0),
        ],
      );

      final output = await engine.calculate(input);

      // Verify daysUntilExam
      expect(output.daysUntilExam, 2);

      // Verify perSubjectReadiness
      // s1 has topicA (10 count, mastered score 1.0) -> readiness = (1.0 * 10) / 10 = 1.0
      expect(output.perSubjectReadiness['s1'], 1.0);
      // s2 has topicB (5 count, learning score 0.5) -> readiness = (0.5 * 5) / 5 = 0.5
      expect(output.perSubjectReadiness['s2'], 0.5);

      // Verify overallReadiness
      // ((1.0 * 12) + (0.5 * 9)) / (12 + 9) = (12 + 4.5) / 21 = 16.5 / 21 = 0.7857
      expect(output.overallReadiness, closeTo(0.7857, 0.001));

      // Verify minutes
      expect(output.studyMinutesTotal, 105);
      expect(output.studyMinutesThisWeek, 105);

      // Verify streak
      expect(output.studyStreakDays, 2);

      // Verify perSubjectTrend
      expect(output.perSubjectTrend['s1'], [75.0]);

      // Verify budgetCoverage
      // both topics ta and tb are != NOT_STARTED. Total budget = 10 + 5 = 15. Covered = 15 -> 1.0
      expect(output.budgetCoverage, 1.0);

      // Verify today plan items
      expect(output.todayPlanItems.length, 1);
    });
  });
}
