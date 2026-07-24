// lib/features/sports/movement/domain/endurance_progression.dart

import 'package:ritmo/features/sports/movement/domain/movement_kind.dart';

class EnduranceProgressionResult {
  const EnduranceProgressionResult({
    required this.kindCode,
    required this.currentWeeklyValue,
    required this.suggestedWeeklyValue,
    required this.metric,
    required this.isInjuryRisk,
    required this.messageFa,
  });

  final String kindCode;
  final double currentWeeklyValue;
  final double suggestedWeeklyValue;
  final MovementMetric metric;
  final bool isInjuryRisk;
  final String messageFa;
}

class EnduranceProgressionEngine {
  /// Evaluated the 10% progression rule for endurance activities.
  static EnduranceProgressionResult evaluateProgression({
    required String kindCode,
    required double lastWeekValue,
    required double previousWeekValue,
    MovementMetric metric = MovementMetric.distance,
  }) {
    if (previousWeekValue > 0) {
      final percentageIncrease = (lastWeekValue - previousWeekValue) / previousWeekValue;
      if (percentageIncrease > 0.15) {
        return EnduranceProgressionResult(
          kindCode: kindCode,
          currentWeeklyValue: lastWeekValue,
          suggestedWeeklyValue: lastWeekValue,
          metric: metric,
          isInjuryRisk: true,
          messageFa: 'هشدار: هفته قبل ${(percentageIncrease * 100).round()}% بیشتر فعالیت کردی. ریسک آسیب بالاست — این هفته همان حجم را حفظ کن.',
        );
      }
    }

    final suggested = lastWeekValue > 0 ? lastWeekValue * 1.10 : 5.0; // Max +10%

    return EnduranceProgressionResult(
      kindCode: kindCode,
      currentWeeklyValue: lastWeekValue,
      suggestedWeeklyValue: suggested,
      metric: metric,
      isInjuryRisk: false,
      messageFa: 'پیشنهاد پیشرفت ایمن: حجم این هفته را حداکثر ۱۰٪ افزایش بده (+${(suggested - lastWeekValue).toStringAsFixed(1)}).',
    );
  }
}
