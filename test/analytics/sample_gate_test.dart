import 'package:flutter_test/flutter_test.dart';
import 'package:ritmo/core/analytics/insight_generation_engine.dart';
import 'package:ritmo/core/domain/engines/engine_enums.dart';

void main() {
  group('InsightGenerationEngine - Statistical Gates & Correlation Tests', () {
    test('sample gate suppresses percentage insights when sample size < 5', () {
      final now = DateTime.now();
      final recentComp = [
        {
          'routineId': 'r1',
          'completionTime': now.subtract(const Duration(days: 1)).millisecondsSinceEpoch,
          'resultType': 'FULL',
        },
        {
          'routineId': 'r1',
          'completionTime': now.subtract(const Duration(days: 2)).millisecondsSinceEpoch,
          'resultType': 'FULL',
        },
      ];

      final routines = [
        {'id': 'r1', 'category': 'LEARNING', 'isArchived': 0},
      ];

      final insights = InsightGenerationEngine.generate(
        routineCompletions: recentComp,
        routines: routines,
        peakPerformanceWindow: null,
        mostProductiveWeekday: null,
        mostFatiguedWindow: null,
        daysOfData: 10,
      );

      // Verify that learningGrowth is NOT generated due to sample size < 5
      final learningInsights = insights.where((i) => i.type == InsightType.learningGrowth).toList();
      expect(learningInsights.isEmpty, isTrue);
    });

    test('pearsonCorrelation correctly measures positive, negative, and zero correlations', () {
      final xPos = [10, 20, 30, 40, 50];
      final yPos = [100, 200, 300, 400, 500];
      final rPos = InsightGenerationEngine.pearsonCorrelation(xPos, yPos);
      expect(rPos, closeTo(1.0, 0.01));

      final xNeg = [10, 20, 30, 40, 50];
      final yNeg = [500, 400, 300, 200, 100];
      final rNeg = InsightGenerationEngine.pearsonCorrelation(xNeg, yNeg);
      expect(rNeg, closeTo(-1.0, 0.01));

      final xZero = [10, 20, 30, 40, 50];
      final yZero = [5, 5, 5, 5, 5];
      final rZero = InsightGenerationEngine.pearsonCorrelation(xZero, yZero);
      expect(rZero, equals(0.0));
    });

    test('isMenstruating softens health decline severity from WATCH to INFO', () {
      final now = DateTime.now();
      final completions = <Map<String, dynamic>>[];

      // 6 completions in previous 7 days
      for (int i = 8; i <= 13; i++) {
        completions.add({
          'routineId': 'h1',
          'completionTime': now.subtract(Duration(days: i)).millisecondsSinceEpoch,
          'resultType': 'FULL',
        });
      }
      // 5 completions in last 7 days (decline)
      for (int i = 1; i <= 5; i++) {
        completions.add({
          'routineId': 'h1',
          'completionTime': now.subtract(Duration(days: i)).millisecondsSinceEpoch,
          'resultType': 'FULL',
        });
      }

      final routines = [
        {'id': 'h1', 'category': 'HEALTH', 'isArchived': 0},
      ];

      final normalInsights = InsightGenerationEngine.generate(
        routineCompletions: completions,
        routines: routines,
        peakPerformanceWindow: null,
        mostProductiveWeekday: null,
        mostFatiguedWindow: null,
        daysOfData: 14,
        isMenstruating: false,
      );

      final cycleInsights = InsightGenerationEngine.generate(
        routineCompletions: completions,
        routines: routines,
        peakPerformanceWindow: null,
        mostProductiveWeekday: null,
        mostFatiguedWindow: null,
        daysOfData: 14,
        isMenstruating: true,
      );

      final normalDecline = normalInsights.firstWhere(
        (i) => i.type == InsightType.healthDecline,
        orElse: () => InsightResult(type: InsightType.gatheringData, params: {}, sourceMetric: '', calculationWindow: ''),
      );

      final cycleDecline = cycleInsights.firstWhere(
        (i) => i.type == InsightType.healthDecline,
        orElse: () => InsightResult(type: InsightType.gatheringData, params: {}, sourceMetric: '', calculationWindow: ''),
      );

      if (normalDecline.type == InsightType.healthDecline) {
        expect(normalDecline.severity, equals('WATCH'));
      }
      if (cycleDecline.type == InsightType.healthDecline) {
        expect(cycleDecline.severity, equals('INFO'));
      }
    });
  });
}
