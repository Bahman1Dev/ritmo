import 'dart:math' as math;

class SM2Result {
  SM2Result({
    required this.repetitions,
    required this.intervalDays,
    required this.easinessFactor,
    required this.nextReviewDate,
  });

  final int repetitions;
  final int intervalDays;
  final double easinessFactor;
  final DateTime nextReviewDate;
}

class SM2ReviewEngine {
  /// Calculates next review date based on SuperMemo-2 (SM-2) algorithm.
  /// qualityScore: 0 to 5 (0=total blackout, 5=perfect recall)
  static SM2Result calculateNextReview({
    required int qualityScore,
    int previousRepetitions = 0,
    int previousIntervalDays = 1,
    double previousEasinessFactor = 2.5,
    required DateTime fromDate,
  }) {
    final q = qualityScore.clamp(0, 5);

    // Calculate new Easiness Factor (EF)
    var ef = previousEasinessFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02));
    if (ef < 1.3) ef = 1.3;

    int reps;
    int interval;

    if (q < 3) {
      reps = 0;
      interval = 1;
    } else {
      reps = previousRepetitions + 1;
      if (reps == 1) {
        interval = 1;
      } else if (reps == 2) {
        interval = 6;
      } else {
        interval = (previousIntervalDays * ef).round();
      }
    }

    final nextDate = fromDate.add(Duration(days: math.max(1, interval)));

    return SM2Result(
      repetitions: reps,
      intervalDays: interval,
      easinessFactor: ef,
      nextReviewDate: nextDate,
    );
  }
}
