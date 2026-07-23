import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';

part 'progression_engine.freezed.dart';
part 'progression_engine.g.dart';

/// Handles auto-progression logic for workout plans.
/// Pure logic - no I/O.
class ProgressionEngine {
  /// Compute next week's weight/reps based on progression strategy.
  static ProgressionRecommendation calculateNext({
    required ProgressionType type,
    required List<PerformedSet> completedSets,
    required double currentWeightKg,
    required int targetRepsMin,
    required int targetRepsMax,
    required double targetRpe,
    double? lastWeekWeightKg,
    int? lastWeekReps,
  }) {
    switch (type) {
      case ProgressionType.doubleProgression:
        return _doubleProgression(
          completedSets: completedSets,
          currentWeight: currentWeightKg,
          targetRepsMin: targetRepsMin,
          targetRepsMax: targetRepsMax,
          targetRpe: targetRpe,
        );
      case ProgressionType.linear:
        return _linearProgression(
          currentWeight: currentWeightKg,
          lastWeekWeight: lastWeekWeightKg ?? currentWeightKg,
        );
      case ProgressionType.rpeBased:
        return _rpeBasedProgression(
          completedSets: completedSets,
          currentWeight: currentWeightKg,
          targetRpe: targetRpe,
        );
      case ProgressionType.custom:
        return ProgressionRecommendation(
          nextWeightKg: currentWeightKg,
          nextRepsMin: targetRepsMin,
          nextRepsMax: targetRepsMax,
          reason: 'پیشرفت سفارشی — تنظیم دستی',
        );
    }
  }

  /// Double Progression: Increase reps until hitting top of range, then increase weight.
  static ProgressionRecommendation _doubleProgression({
    required List<PerformedSet> completedSets,
    required double currentWeight,
    required int targetRepsMin,
    required int targetRepsMax,
    required double targetRpe,
  }) {
    if (completedSets.isEmpty) {
      return ProgressionRecommendation(
        nextWeightKg: currentWeight,
        nextRepsMin: targetRepsMin,
        nextRepsMax: targetRepsMax,
        reason: 'هنوز ست ثبت نشده',
      );
    }

    // Filter working sets (completed, non-warmup)
    final workingSets = completedSets.where((s) => s.isCompleted && !s.isWarmup).toList();
    if (workingSets.isEmpty) {
      return ProgressionRecommendation(
        nextWeightKg: currentWeight,
        nextRepsMin: targetRepsMin,
        nextRepsMax: targetRepsMax,
        reason: 'ست اصلی ثبت نشده',
      );
    }

    // Check if ALL working sets hit top of rep range with good RPE
    final allHitTop = workingSets.every(
      (s) => s.reps >= targetRepsMax && s.rpe <= targetRpe + 0.5,
    );

    if (allHitTop) {
      // Increase weight by ~2.5% or 2.5kg (whichever is smaller for light weights)
      final increment = currentWeight < 50 ? 1.25 : 2.5;
      final nextWeight = (currentWeight + increment).clamp(0, 500);
      return ProgressionRecommendation(
        nextWeightKg: nextWeight.toDouble(),
        nextRepsMin: targetRepsMin,
        nextRepsMax: targetRepsMax,
        reason: 'تمام ست‌ها به سقف تکرار رسیدند — وزن ${increment.toStringAsFixed(1)}kg افزایش یافت 📈',
      );
    }

    // Check if any set failed (RPE too high or reps too low)
    final anyFailed = workingSets.any(
      (s) => s.rpe > targetRpe + 1 || s.reps < targetRepsMin,
    );

    if (anyFailed) {
      return ProgressionRecommendation(
        nextWeightKg: currentWeight,
        nextRepsMin: targetRepsMin,
        nextRepsMax: targetRepsMax,
        reason: 'برخی ست‌ها سخت بود — وزن ثابت بماند تا تکرارها بالا برود ⏳',
      );
    }

    // In between: keep weight, aim for more reps
    return ProgressionRecommendation(
      nextWeightKg: currentWeight,
      nextRepsMin: targetRepsMin,
      nextRepsMax: targetRepsMax,
      reason: 'در حال پیشرفت به سمت سقف تکرار — وزن ثابت ⏳',
    );
  }

  /// Linear Periodization: Fixed weekly weight increase.
  static ProgressionRecommendation _linearProgression({
    required double currentWeight,
    required double lastWeekWeight,
  }) {
    // Typical: +1.25kg upper, +2.5kg lower per week
    final increment = currentWeight < 50 ? 1.25 : 2.5;
    final nextWeight = (lastWeekWeight + increment).clamp(0, 500);

    return ProgressionRecommendation(
      nextWeightKg: nextWeight.toDouble(),
      nextRepsMin: 6,
      nextRepsMax: 10,
      reason: 'پیریودیزیشن خطی — افزایش هفتگی ${increment.toStringAsFixed(1)}kg 📈',
    );
  }

  /// RPE-Based Autoregulation: Adjust based on actual RPE vs target.
  static ProgressionRecommendation _rpeBasedProgression({
    required List<PerformedSet> completedSets,
    required double currentWeight,
    required double targetRpe,
  }) {
    if (completedSets.isEmpty) {
      return ProgressionRecommendation(
        nextWeightKg: currentWeight,
        nextRepsMin: 6,
        nextRepsMax: 10,
        reason: 'داده‌ای برای خودتنظیمی وجود ندارد',
      );
    }

    final workingSets = completedSets.where((s) => s.isCompleted && !s.isWarmup).toList();
    if (workingSets.isEmpty) {
      return ProgressionRecommendation(
        nextWeightKg: currentWeight,
        nextRepsMin: 6,
        nextRepsMax: 10,
        reason: 'ست اصلی انجام نشده',
      );
    }

    // Average RPE of last set (most indicative)
    final lastSet = workingSets.last;
    final rpeDiff = lastSet.rpe - 8.0; // Target RPE 8 for hypertrophy

    if (rpeDiff >= 1.5) {
      // Way too easy: increase weight
      final increment = currentWeight < 50 ? 2.5 : 5.0;
      return ProgressionRecommendation(
        nextWeightKg: (currentWeight + increment).clamp(0, 500),
        nextRepsMin: 6,
        nextRepsMax: 10,
        reason: 'RPE ${lastSet.rpe.toStringAsFixed(1)} — خیلی آسان، وزن ${(currentWeight < 50 ? 2.5 : 5.0).toStringAsFixed(1)}kg بیشتر 📈',
      );
    } else if (rpeDiff <= -1.0) {
      // Too hard: decrease weight
      final decrement = currentWeight < 50 ? 1.25 : 2.5;
      return ProgressionRecommendation(
        nextWeightKg: (currentWeight - decrement).clamp(0, 500),
        nextRepsMin: 6,
        nextRepsMax: 10,
        reason: 'RPE ${lastSet.rpe.toStringAsFixed(1)} — خیلی سخت، وزن ${(currentWeight < 50 ? 1.25 : 2.5).toStringAsFixed(1)}kg کمتر ⬇️',
      );
    }

    // Within ±1 RPE: keep weight
    return ProgressionRecommendation(
      nextWeightKg: currentWeight,
      nextRepsMin: 6,
      nextRepsMax: 10,
      reason: 'RPE در بازه هدف — وزن ثابت، تلاش برای تکرار بیشتر ⏳',
    );
  }

  /// Detect if deload week is needed based on cumulative fatigue
  static bool shouldDeload({
    required int weeksSinceLastDeload,
    required int deloadFrequencyWeeks,
    required List<ReadinessScore> recentReadiness,
  }) {
    if (weeksSinceLastDeload >= deloadFrequencyWeeks) return true;

    // Check if last 2 weeks readiness consistently low
    if (recentReadiness.length >= 2) {
      final avgScore = recentReadiness.map((r) => r.score).reduce((a, b) => a + b) / recentReadiness.length;
      if (avgScore < 50) return true;
    }

    return false;
  }

  /// Generate deload recommendation (reduce volume 40-50%, intensity 10-20%)
  static DeloadRecommendation generateDeload({
    required double currentWeight,
    required int targetSets,
    required int targetRepsMin,
    required int targetRepsMax,
  }) {
    return DeloadRecommendation(
      weightMultiplier: 0.6,        // 60% of working weight
      setsMultiplier: 0.5,          // 50% of sets
      repsMin: targetRepsMin,       // Keep reps same
      repsMax: targetRepsMax,
      reason: 'هفته دیلود: حجم ۵۰٪، شدت ۶۰٪ برای ریکاوری کامل 🛌',
    );
  }
}

@freezed
abstract class ProgressionRecommendation with _$ProgressionRecommendation {
  const factory ProgressionRecommendation({
    required double nextWeightKg,
    required int nextRepsMin,
    required int nextRepsMax,
    required String reason,
  }) = _ProgressionRecommendation;

  factory ProgressionRecommendation.fromJson(Map<String, dynamic> json) =>
      _$ProgressionRecommendationFromJson(json);
}

@freezed
abstract class DeloadRecommendation with _$DeloadRecommendation {
  const factory DeloadRecommendation({
    required double weightMultiplier,
    required double setsMultiplier,
    required int repsMin,
    required int repsMax,
    required String reason,
  }) = _DeloadRecommendation;

  factory DeloadRecommendation.fromJson(Map<String, dynamic> json) =>
      _$DeloadRecommendationFromJson(json);
}