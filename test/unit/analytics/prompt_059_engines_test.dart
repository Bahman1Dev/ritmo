import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/cognitive_routing_engine.dart';
import 'package:ritmo/core/analytics/daily_budget_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/fresh_start_engine.dart';
import 'package:ritmo/core/analytics/motivation_diagnosis_engine.dart';
import 'package:ritmo/core/analytics/spaced_repetition_engine.dart';

void main() {
  group('Prompt 059 Engines Unit Tests', () {
    final now = DateTime(2026, 8, 8, 10, 0); // Saturday (Saturday = weekday 6 in Dart DateTime)

    test('MotivationDiagnosisEngine: < 10 samples returns insufficientData', () async {
      final engine = MotivationDiagnosisEngine();
      final input = MotivationDiagnosisInput(
        routineId: 'r1',
        routineCompletions: List.generate(4, (i) => {
          'resultType': 'COMPLETED',
          'completionTime': now.subtract(Duration(days: i)).millisecondsSinceEpoch,
        }),
        now: now,
      );

      final output = await engine.calculate(input);
      expect(output.sufficientData, isFalse);
      expect(output.weakestTerm, equals(MotivationWeakestTerm.none));
    });

    test('MotivationDiagnosisEngine: low success rate identifies expectation term', () async {
      final engine = MotivationDiagnosisEngine();
      final completions = <Map<String, dynamic>>[];
      // 10 samples: 3 completed, 7 missed
      for (int i = 0; i < 10; i++) {
        completions.add({
          'resultType': i < 3 ? 'COMPLETED' : 'SKIPPED',
          'completionTime': now.subtract(Duration(days: i)).millisecondsSinceEpoch,
        });
      }

      final input = MotivationDiagnosisInput(
        routineId: 'r1',
        routineCompletions: completions,
        deferCount: 0,
        now: now,
      );

      final output = await engine.calculate(input);
      expect(output.sufficientData, isTrue);
      expect(output.weakestTerm, equals(MotivationWeakestTerm.expectation));
      expect(output.prescriptionKey, equals('shrink_to_success'));
    });

    test('MotivationDiagnosisEngine: high defer count identifies impulsivity term', () async {
      final engine = MotivationDiagnosisEngine();
      final completions = <Map<String, dynamic>>[];
      // 10 samples: all completed
      for (int i = 0; i < 10; i++) {
        completions.add({
          'resultType': 'COMPLETED',
          'completionTime': now.subtract(Duration(days: i)).millisecondsSinceEpoch,
        });
      }

      final input = MotivationDiagnosisInput(
        routineId: 'r1',
        routineCompletions: completions,
        deferCount: 8,
        snoozeCount: 4,
        now: now,
      );

      final output = await engine.calculate(input);
      expect(output.sufficientData, isTrue);
      expect(output.weakestTerm, equals(MotivationWeakestTerm.impulsivity));
      expect(output.prescriptionKey, equals('change_cue'));
    });

    test('DailyBudgetEngine: planned > capacity flags overBudget', () async {
      final engine = DailyBudgetEngine();
      final input = DailyBudgetInput(
        dateStr: '2026-08-08',
        plannedItems: [
          {'id': '1', 'title': 'کار ۱', 'targetDurationMinutes': 240, 'isEssential': 0, 'category': 'work', 'priority': 1.0},
          {'id': '2', 'title': 'کار ۲', 'targetDurationMinutes': 300, 'isEssential': 0, 'category': 'learning', 'priority': 2.0},
          {'id': '3', 'title': 'کار ۳', 'targetDurationMinutes': 300, 'isEssential': 0, 'category': 'personal', 'priority': 3.0},
        ],
        loggedSleepHours: 8.0, // 24-8=16 awake, -0.75 worship = 15.25h * 0.8 friction = ~12.2h capacity
        frictionCoefficient: 0.20,
      );

      final output = await engine.calculate(input);
      expect(output.plannedHours, equals(14.0));
      expect(output.isOverBudget, isTrue);
      expect(output.removableSuggestions.length, greaterThan(0));
    });

    test('CognitiveRoutingEngine: stays inactive when energy samples < 14', () async {
      final engine = CognitiveRoutingEngine();
      final energyOutput = EnergyAnalyticsOutput(
        peakPerformanceWindow: '09:00-12:00',
        mostProductiveWeekday: 'Saturday',
        mostFatiguedWindow: '14:00-16:00',
        currentDynamicEnergy: 2.5,
        currentDynamicEnergyExplanations: [],
        sampleCount: 5, // < 14
        avgLevel: 2.5,
        isAiDerived: false,
      );

      final input = CognitiveRoutingInput(
        dateStr: '2026-08-08',
        routines: [
          {'id': 'r1', 'title': 'تست کنکور', 'category': 'konkur', 'cognitiveLoad': 'ANALYTICAL', 'isEssential': 0},
        ],
        energyOutput: energyOutput,
      );

      final output = await engine.calculate(input);
      expect(output.isActive, isFalse);
    });

    test('CognitiveRoutingEngine: skips religious/medical/isEssential routines', () async {
      final engine = CognitiveRoutingEngine();
      final energyOutput = EnergyAnalyticsOutput(
        peakPerformanceWindow: '09:00-12:00',
        mostProductiveWeekday: 'Saturday',
        mostFatiguedWindow: '14:00-16:00',
        currentDynamicEnergy: 2.5,
        currentDynamicEnergyExplanations: [],
        sampleCount: 20, // >= 14
        avgLevel: 2.5,
        isAiDerived: false,
      );

      final input = CognitiveRoutingInput(
        dateStr: '2026-08-08',
        routines: [
          {'id': 'r1', 'title': 'نماز اول وقت', 'category': 'religious', 'cognitiveLoad': 'ANALYTICAL', 'isEssential': 1},
          {'id': 'r2', 'title': 'مصرف داروی ظهر', 'category': 'medical', 'cognitiveLoad': 'ADMINISTRATIVE', 'isEssential': 1},
        ],
        energyOutput: energyOutput,
      );

      final output = await engine.calculate(input);
      expect(output.isActive, isTrue);
      expect(output.suggestion, isNull);
    });

    test('FreshStartEngine: detects Saturday landmark', () async {
      final engine = FreshStartEngine();
      final input = FreshStartInput(
        now: now, // Saturday
        stagnantGoals: [{'id': 'g1', 'title': 'هدف سالانه'}],
        deadRoutines: [{'id': 'r1', 'title': 'ورزش صبحگاهی'}],
      );

      final output = await engine.calculate(input);
      expect(output.isLandmarkDay, isTrue);
      expect(output.stagnantGoalProposals.length, equals(1));
      expect(output.deadRoutineProposals.length, equals(1));
    });

    test('SpacedRepetitionEngine: calculates review intervals and mastery decay', () async {
      final engine = SpacedRepetitionEngine();
      final input = SpacedRepetitionInput(
        topics: [
          {
            'id': 't1',
            'name': 'دیفراسیل',
            'subjectId': 'math',
            'masteryLevel': 'MASTERED',
            'lastStudiedAt': now.subtract(const Duration(days: 70)).millisecondsSinceEpoch, // > 60 days
            'lastIntervalDays': 7,
            'lastReviewScore': 85.0,
          },
          {
            'id': 't2',
            'name': 'فیزیک حرکت',
            'subjectId': 'physics',
            'masteryLevel': 'IN_PROGRESS',
            'lastStudiedAt': now.subtract(const Duration(days: 3)).millisecondsSinceEpoch,
            'lastIntervalDays': 3,
            'lastReviewScore': 90.0,
          },
        ],
        now: now,
      );

      final output = await engine.calculate(input);
      expect(output.decayedTopicsCount, equals(1));
      expect(output.scheduledReviews.length, equals(2));
      expect(output.scheduledReviews.firstWhere((r) => r.topicId == 't1').isDecayed, isTrue);
    });
  });
}
