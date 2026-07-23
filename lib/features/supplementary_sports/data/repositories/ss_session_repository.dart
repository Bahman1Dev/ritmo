import 'package:ritmo/features/supplementary_sports/data/models/ss_session_models.dart';
import 'package:ritmo/features/supplementary_sports/data/models/ss_user_profile_model.dart';

abstract class SSSessionRepository {
  Future<String> startSession(String planId);
  Future<void> logExerciseFeeling(String sessionId, String exerciseId, Feeling feeling);
  Future<void> finishSession(String sessionId, {required int completedCount, required int totalCount, String? overallFeeling});
  Future<bool> isTodaySessionLogged();
  Future<int> getCurrentStreak();
  Future<List<bool>> getLast7DaysActivity();
  Future<int> getTotalSessionCount();
  Future<double> getMonthContinuityPercent();
  Future<List<ExerciseFeelingLog>> getRecentFeelings(int sessionCount);
  Future<List<ExerciseReadyForIncrease>> getExercisesReadyForProgression();
}
