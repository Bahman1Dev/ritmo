import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:ritmo/features/sports/domain/entities/sports_entities.dart';
import 'package:ritmo/features/sports/domain/repositories/sports_repository.dart';

part 'workout_suggester.freezed.dart';
part 'workout_suggester.g.dart';

/// Pure domain service for generating today's workout suggestion.
/// No DB access — uses Repository interface.
class WorkoutSuggester {

  WorkoutSuggester(this._repo);
  final SportsRepository _repo;

  /// Build today's complete workout suggestion
  Future<TodayWorkoutPlan> buildToday() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    // 1. Check if setup done
    final setupDone = await _repo.isSetupDone();
    if (!setupDone) {
      return TodayWorkoutPlan(
        splitDay: WorkoutSplitDay(
          id: '',
          splitId: '',
          weekday: DateTime.now().weekday,
          isRest: true,
          targetMuscles: [],
          createdAt: now,
          updatedAt: now,
        ),
        exercises: [],
        suggestedTier: WorkoutTier.light,
        tierReason: 'ابتدا برنامه هفتگی رو در بخش «برنامه» بساز',
        isRestDay: true,
        hasNoPlan: true,
      );
    }

    // 2. Get active plan and today's split day
    final plan = await _repo.getActivePlan();
    if (plan == null) {
      return TodayWorkoutPlan(
        splitDay: WorkoutSplitDay(
          id: '',
          splitId: '',
          weekday: DateTime.now().weekday,
          isRest: true,
          targetMuscles: [],
          createdAt: now,
          updatedAt: now,
        ),
        exercises: [],
        suggestedTier: WorkoutTier.light,
        tierReason: 'برنامه فعالی وجود نداره',
        isRestDay: true,
        hasNoPlan: true,
      );
    }

    final today = DateTime.now();
    final weekday = today.weekday; // 1=Mon..7=Sun
    final splitDay = await _repo.getSplitDay(plan.id, weekday, 1);

    if (splitDay == null || splitDay.isRest || splitDay.targetMuscles.isEmpty) {
      final tier = await _getSuggestedTier();
      return TodayWorkoutPlan(
        splitDay: splitDay ??
            WorkoutSplitDay(
              id: '',
              splitId: plan.id,
              weekday: weekday,
              isRest: true,
              targetMuscles: [],
              createdAt: now,
              updatedAt: now,
            ),
        exercises: [],
        suggestedTier: tier,
        tierReason: splitDay?.isRest == true
            ? 'امروز روز استراحته — ریکاوری و کشش سبک'
            : 'برای امروز برنامه‌ای تعریف نشده',
        isRestDay: true,
        hasNoPlan: splitDay == null || splitDay.targetMuscles.isEmpty,
      );
    }

    // 3. Get exercises for today
    final splitExercises = await _repo.getSplitExercises(splitDay.id);

    // 4. Get suggested tier from readiness
    final tier = await _getSuggestedTier();
    final reason = _generateTierReason(tier);

    // 5. Build exercise details with previous bests
    final exercisesWithDetails = <ExerciseWithDetails>[];
    for (final se in splitExercises) {
      final exercise = await _repo.getExerciseById(se.exerciseId);
      if (exercise != null) {
        // Get previous bests from progression records
        final records = await _repo.getProgressionRecords(exerciseId: exercise.id);
        final lastRecord = records.isNotEmpty ? records.first : null;

        exercisesWithDetails.add(ExerciseWithDetails(
          exercise: exercise,
          splitExercises: [se],
          previousBestWeight: lastRecord?.weightKg,
          previousBestReps: lastRecord?.reps,
          previousBestVolume: lastRecord != null ? lastRecord.weightKg * lastRecord.reps : null,
        ));
      }
    }

    return TodayWorkoutPlan(
      splitDay: splitDay,
      exercises: splitExercises,
      suggestedTier: tier,
      tierReason: reason,
      isRestDay: false,
      hasNoPlan: false,
    );
  }

  Future<WorkoutTier> _getSuggestedTier() async {
    // Get today's readiness
    final readiness = await _repo.getTodaysReadiness();
    if (readiness != null) {
      return readiness.suggestedTier;
    }

    // Fallback: check sleep from bedtime_diagnostics
    // This would need a SleepRepository - fallback to FULL
    return WorkoutTier.full;
  }

  String _generateTierReason(WorkoutTier tier) {
    switch (tier) {
      case WorkoutTier.minimal:
        return 'خستگی بالا یا خواب کم — فقط حداقلی برای حفظ زنجیره ⚡';
      case WorkoutTier.light:
        return 'خستگی متوسط — تمرین سبک و کنترل شده 🟡';
      case WorkoutTier.full:
        return 'آمادگی بالا — تمرین کامل با حداکثر کیفیت 🔥';
    }
  }
}

// ──────────────────────────────────────────────────────────────
// Today Workout Plan (Extended)
// ──────────────────────────────────────────────────────────────

@freezed
abstract class TodayWorkoutPlan with _$TodayWorkoutPlan {
  const factory TodayWorkoutPlan({
    required WorkoutSplitDay splitDay,
    required List<SplitExercise> exercises,
    required WorkoutTier suggestedTier,
    required String tierReason,
    required bool isRestDay,
    required bool hasNoPlan,
  }) = _TodayWorkoutPlan;

  factory TodayWorkoutPlan.fromJson(Map<String, dynamic> json) => _$TodayWorkoutPlanFromJson(json);
}

@freezed
abstract class ExerciseWithDetails with _$ExerciseWithDetails {
  const factory ExerciseWithDetails({
    required Exercise exercise,
    required List<SplitExercise> splitExercises,
    double? previousBestWeight,
    int? previousBestReps,
    double? previousBestVolume,
  }) = _ExerciseWithDetails;

  factory ExerciseWithDetails.fromJson(Map<String, dynamic> json) => _$ExerciseWithDetailsFromJson(json);
}