// ignore_for_file: always_use_package_imports
import '../models/ss_plan_models.dart';
import '../models/ss_user_profile_model.dart';

/// Abstract repository interface for Supplementary Sports plans
/// and user profile.
abstract class SSPlanRepository {
  /// Fetches the user's supplementary sports profile.
  Future<SsUserProfile?> getUserProfile();

  /// Saves or updates the user's supplementary sports profile.
  Future<void> saveUserProfile(SsUserProfile profile);

  /// Retrieves the weekly workout plan list.
  Future<List<WorkoutPlan>> getWeeklyPlan();

  /// Retrieves today's active workout plan.
  Future<WorkoutPlan?> getTodayPlan();

  /// Retrieves exercises assigned to a specific plan ID.
  Future<List<WorkoutExerciseCrossRef>> getPlanExercises(String planId);

  /// Updates exercise details within a plan.
  Future<void> updateExerciseInPlan(WorkoutExerciseCrossRef updated);

  /// Adds an exercise to a plan.
  Future<void> addExerciseToPlan(
    String planId,
    WorkoutExerciseCrossRef exercise,
  );

  /// Removes an exercise from a plan by ID.
  Future<void> removeExerciseFromPlan(String planId, String exerciseId);

  /// Saves a snapshot of current plan version history.
  Future<void> savePlanVersionSnapshot(String reason);

  /// Gets the complete plan version history list.
  Future<List<PlanVersionHistory>> getPlanVersionHistory();

  /// Restores a specific plan version by ID.
  Future<void> restorePlanVersion(String versionId);
}
