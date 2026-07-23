// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_suggester.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TodayWorkoutPlan _$TodayWorkoutPlanFromJson(Map<String, dynamic> json) =>
    _TodayWorkoutPlan(
      splitDay: WorkoutSplitDay.fromJson(
        json['splitDay'] as Map<String, dynamic>,
      ),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => SplitExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      suggestedTier: $enumDecode(_$WorkoutTierEnumMap, json['suggestedTier']),
      tierReason: json['tierReason'] as String,
      isRestDay: json['isRestDay'] as bool,
      hasNoPlan: json['hasNoPlan'] as bool,
    );

Map<String, dynamic> _$TodayWorkoutPlanToJson(_TodayWorkoutPlan instance) =>
    <String, dynamic>{
      'splitDay': instance.splitDay,
      'exercises': instance.exercises,
      'suggestedTier': _$WorkoutTierEnumMap[instance.suggestedTier]!,
      'tierReason': instance.tierReason,
      'isRestDay': instance.isRestDay,
      'hasNoPlan': instance.hasNoPlan,
    };

const _$WorkoutTierEnumMap = {
  WorkoutTier.minimal: 'minimal',
  WorkoutTier.light: 'light',
  WorkoutTier.full: 'full',
};

_ExerciseWithDetails _$ExerciseWithDetailsFromJson(Map<String, dynamic> json) =>
    _ExerciseWithDetails(
      exercise: Exercise.fromJson(json['exercise'] as Map<String, dynamic>),
      splitExercises: (json['splitExercises'] as List<dynamic>)
          .map((e) => SplitExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      previousBestWeight: (json['previousBestWeight'] as num?)?.toDouble(),
      previousBestReps: (json['previousBestReps'] as num?)?.toInt(),
      previousBestVolume: (json['previousBestVolume'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$ExerciseWithDetailsToJson(
  _ExerciseWithDetails instance,
) => <String, dynamic>{
  'exercise': instance.exercise,
  'splitExercises': instance.splitExercises,
  'previousBestWeight': instance.previousBestWeight,
  'previousBestReps': instance.previousBestReps,
  'previousBestVolume': instance.previousBestVolume,
};
