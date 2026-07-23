import 'package:ritmo/features/supplementary_sports/data/models/ss_exercise_model.dart';

abstract class SSExerciseRepository {
  Future<List<SsExerciseModel>> getAllExercises();
  Future<List<SsExerciseModel>> getExercisesByCategory(String category);
  Future<List<SsExerciseModel>> getSimilarExercises(String exerciseId);
  Future<void> seedExercisesFromJson(String jsonString);
}
