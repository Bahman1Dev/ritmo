import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/data_maturity_engine.dart';
import 'package:ritmo/core/analytics/energy_analytics_engine.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/analytics/life_balance_engine.dart';
import 'package:ritmo/core/analytics/milestone_engine.dart';

void main() {
  group('DataMaturityEngine Tests', () {
    test('Should return notEnoughData for days < 14', () {
      final res = DataMaturityEngine.evaluate(daysOfData: 10, completionCount: 20, energyLogsCount: 5);
      expect(res, DataMaturity.notEnoughData);
    });

    test('Should return partialData for days between 14 and 29', () {
      final res = DataMaturityEngine.evaluate(daysOfData: 15, completionCount: 40, energyLogsCount: 15);
      expect(res, DataMaturity.partialData);
    });

    test('Should return fullData for days >= 30', () {
      final res = DataMaturityEngine.evaluate(daysOfData: 32, completionCount: 100, energyLogsCount: 45);
      expect(res, DataMaturity.fullData);
    });
  });

  group('EnergyAnalyticsEngine Tests', () {
    test('Timezone conversion to Iran Standard Time (+3:30)', () {
      // 1718972400000 ms is 2024-06-21 12:20:00 UTC
      // Iran time should be 2024-06-21 15:50:00
      final local = EnergyAnalyticsEngine.toIranLocal(1718972400000);
      expect(local.hour, 15);
      expect(local.minute, 50);
    });

    test('PeakPerformanceWindow returns null when completions < 5', () {
      final window = EnergyAnalyticsEngine.calculatePeakPerformanceWindow(
        energyLogs: [],
        routineCompletions: List.generate(4, (i) => {}),
        dailyRhythm: [],
      );
      expect(window, isNull);
    });

    test('MostProductiveWeekday returns null when any weekday has < 4 distinct days of samples', () {
      final comps = [
        {'completionTime': 1718972400000, 'completionDate': '2024-06-21', 'resultType': 'FULL'}, // Fri
        {'completionTime': 1718972400000, 'completionDate': '2024-06-21', 'resultType': 'FULL'}, // Fri
      ];
      final weekday = EnergyAnalyticsEngine.calculateMostProductiveWeekday(
        routineCompletions: comps,
        dailyRhythm: [],
      );
      expect(weekday, isNull);
    });

    test('MostFatiguedWindow returns null if max fatigue events is 0', () {
      final window = EnergyAnalyticsEngine.calculateMostFatiguedWindow(
        energyLogs: [],
        routineCompletions: [],
      );
      expect(window, isNull);
    });
  });

  group('LifeBalanceEngine Tests', () {
    test('LifeBalanceScore should be 100 for perfectly balanced completions', () {
      final routines = [
        {'id': 'r1', 'category': 'religious', 'isArchived': 0},
        {'id': 'r2', 'category': 'fitness', 'isArchived': 0},
      ];
      final completions = [
        {'routineId': 'r1', 'resultType': 'FULL'},
        {'routineId': 'r2', 'resultType': 'FULL'},
      ];
      final score = LifeBalanceEngine.calculateLifeBalanceScore(
        routines: routines,
        routineCompletions: completions,
      );
      expect(score, 100);
    });

    test('LifeBalanceScore should be low for heavily concentrated completions', () {
      final routines = [
        {'id': 'r1', 'category': 'religious', 'isArchived': 0},
        {'id': 'r2', 'category': 'fitness', 'isArchived': 0},
      ];
      // 9 completions for r1, 1 completion for r2
      final completions = [
        ...List.generate(9, (i) => {'routineId': 'r1', 'resultType': 'FULL'}),
        {'routineId': 'r2', 'resultType': 'FULL'},
      ];
      final score = LifeBalanceEngine.calculateLifeBalanceScore(
        routines: routines,
        routineCompletions: completions,
      );
      expect(score, lessThan(70));
    });

    test('Inactive domains should not penalize LifeBalanceScore', () {
      final routines = [
        {'id': 'r1', 'category': 'religious', 'isArchived': 0},
      ];
      // Only 1 active routine category (religious). No completions in fitness, medical, work.
      final completions = [
        {'routineId': 'r1', 'resultType': 'FULL'},
      ];
      final score = LifeBalanceEngine.calculateLifeBalanceScore(
        routines: routines,
        routineCompletions: completions,
      );
      // Since only RELIGION is active, balance score should default to 100
      expect(score, 100);
    });

    test('CategoryDistribution percentages should sum to 100%', () {
      final routines = [
        {'id': 'r1', 'category': 'religious', 'isArchived': 0},
        {'id': 'r2', 'category': 'fitness', 'isArchived': 0},
        {'id': 'r3', 'category': 'learning', 'isArchived': 0},
      ];
      final completions = [
        {'routineId': 'r1', 'resultType': 'FULL'},
        {'routineId': 'r2', 'resultType': 'FULL'},
        {'routineId': 'r3', 'resultType': 'FULL'},
      ];
      final dist = LifeBalanceEngine.calculateCategoryDistribution(
        routines: routines,
        routineCompletions: completions,
      );
      final sum = dist.values.reduce((a, b) => a + b);
      expect(sum, closeTo(100.0, 0.01));
    });
  });

  group('MilestoneEngine Tests', () {
    test('Evaluate unlock conditions and streak progress', () {
      final milestones = MilestoneEngine.evaluate(
        currentStreak: 8,
        longestStreak: 8,
        routineCompletions: [],
        routines: [],
        courses: [],
        courseSessions: [],
        konkurSubjects: [],
        unlockedMilestonesMap: {},
      );

      final streak7 = milestones.firstWhere((m) => m.id == 'streak_7');
      expect(streak7.isUnlocked, isTrue);
      expect(streak7.progress, 1.0);

      final streak30 = milestones.firstWhere((m) => m.id == 'streak_30');
      expect(streak30.isUnlocked, isFalse);
      expect(streak30.progress, closeTo(8 / 30.0, 0.01));
    });

    test('Continuous prayer and exercise consecutive days evaluation', () {
      final routines = [
        {'id': 'pray1', 'category': 'religious', 'isArchived': 0},
      ];
      
      // completions spanning 3 consecutive days
      final completions = [
        {'routineId': 'pray1', 'completionDate': '2026-06-01', 'resultType': 'FULL'},
        {'routineId': 'pray1', 'completionDate': '2026-06-02', 'resultType': 'FULL'},
        {'routineId': 'pray1', 'completionDate': '2026-06-03', 'resultType': 'LIGHT'},
      ];

      final milestones = MilestoneEngine.evaluate(
        currentStreak: 3,
        longestStreak: 3,
        routineCompletions: completions,
        routines: routines,
        courses: [],
        courseSessions: [],
        konkurSubjects: [],
        unlockedMilestonesMap: {},
      );

      final continuousPrayer = milestones.firstWhere((m) => m.id == 'continuous_prayer_30');
      expect(continuousPrayer.isUnlocked, isFalse);
      expect(continuousPrayer.progress, closeTo(3 / 30.0, 0.01));
    });
  });

  group('InsightGenerationEngine Tests', () {
    test('Traceability metadata fields should be populated', () {
      final insights = InsightGenerationEngine.generate(
        routineCompletions: [],
        routines: [],
        peakPerformanceWindow: '09:00 - 12:00',
        mostProductiveWeekday: 'شنبه',
        mostFatiguedWindow: '15:00 - 18:00',
        daysOfData: 10,
      );

      expect(insights.isNotEmpty, isTrue);
      for (final card in insights) {
        expect(card.sourceMetric.isNotEmpty, isTrue);
        expect(card.calculationWindow.isNotEmpty, isTrue);
      }
    });
  });
}
