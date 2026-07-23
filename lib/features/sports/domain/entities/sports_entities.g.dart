// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sports_entities.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Exercise _$ExerciseFromJson(Map<String, dynamic> json) => _Exercise(
  id: json['id'] as String,
  name: json['name'] as String,
  nameFa: json['nameFa'] as String,
  primaryMuscle: $enumDecode(_$MuscleGroupEnumMap, json['primaryMuscle']),
  category: $enumDecode(_$ExerciseCategoryEnumMap, json['category']),
  difficulty: $enumDecode(_$DifficultyLevelEnumMap, json['difficulty']),
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num).toInt(),
  secondaryMuscles:
      (json['secondaryMuscles'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
          .toList() ??
      const [],
  equipment:
      (json['equipment'] as List<dynamic>?)
          ?.map((e) => $enumDecode(_$EquipmentEnumMap, e))
          .toList() ??
      const [],
  description: json['description'] as String?,
  videoUrl: json['videoUrl'] as String?,
  imageUrl: json['imageUrl'] as String?,
  cues:
      (json['cues'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  isCompound: json['isCompound'] as bool? ?? true,
  isUserCreated: json['isUserCreated'] as bool? ?? false,
  usageCount: (json['usageCount'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$ExerciseToJson(_Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'nameFa': instance.nameFa,
  'primaryMuscle': _$MuscleGroupEnumMap[instance.primaryMuscle]!,
  'category': _$ExerciseCategoryEnumMap[instance.category]!,
  'difficulty': _$DifficultyLevelEnumMap[instance.difficulty]!,
  'createdAt': instance.createdAt,
  'updatedAt': instance.updatedAt,
  'secondaryMuscles': instance.secondaryMuscles
      .map((e) => _$MuscleGroupEnumMap[e]!)
      .toList(),
  'equipment': instance.equipment.map((e) => _$EquipmentEnumMap[e]!).toList(),
  'description': instance.description,
  'videoUrl': instance.videoUrl,
  'imageUrl': instance.imageUrl,
  'cues': instance.cues,
  'isCompound': instance.isCompound,
  'isUserCreated': instance.isUserCreated,
  'usageCount': instance.usageCount,
};

const _$MuscleGroupEnumMap = {
  MuscleGroup.chest: 'chest',
  MuscleGroup.back: 'back',
  MuscleGroup.shoulders: 'shoulders',
  MuscleGroup.biceps: 'biceps',
  MuscleGroup.triceps: 'triceps',
  MuscleGroup.legs: 'legs',
  MuscleGroup.abs: 'abs',
  MuscleGroup.fullBody: 'fullBody',
  MuscleGroup.cardio: 'cardio',
  MuscleGroup.rest: 'rest',
};

const _$ExerciseCategoryEnumMap = {
  ExerciseCategory.compound: 'compound',
  ExerciseCategory.isolation: 'isolation',
  ExerciseCategory.cardio: 'cardio',
  ExerciseCategory.mobility: 'mobility',
};

const _$DifficultyLevelEnumMap = {
  DifficultyLevel.beginner: 'beginner',
  DifficultyLevel.intermediate: 'intermediate',
  DifficultyLevel.advanced: 'advanced',
};

const _$EquipmentEnumMap = {
  Equipment.bodyweight: 'bodyweight',
  Equipment.dumbbell: 'dumbbell',
  Equipment.barbell: 'barbell',
  Equipment.machine: 'machine',
  Equipment.cable: 'cable',
  Equipment.band: 'band',
  Equipment.kettlebell: 'kettlebell',
  Equipment.other: 'other',
};

_WorkoutPlan _$WorkoutPlanFromJson(Map<String, dynamic> json) => _WorkoutPlan(
  id: json['id'] as String,
  name: json['name'] as String,
  goal: $enumDecode(_$WorkoutGoalEnumMap, json['goal']),
  frequency: (json['frequency'] as num).toInt(),
  progressionType: $enumDecode(
    _$ProgressionTypeEnumMap,
    json['progressionType'],
  ),
  createdAt: (json['createdAt'] as num).toInt(),
  updatedAt: (json['updatedAt'] as num).toInt(),
  mesocycleLengthWeeks: (json['mesocycleLengthWeeks'] as num?)?.toInt() ?? 6,
  currentWeek: (json['currentWeek'] as num?)?.toInt() ?? 1,
  deloadFrequencyWeeks: (json['deloadFrequencyWeeks'] as num?)?.toInt() ?? 4,
  isActive: json['isActive'] as bool? ?? true,
);

Map<String, dynamic> _$WorkoutPlanToJson(_WorkoutPlan instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'goal': _$WorkoutGoalEnumMap[instance.goal]!,
      'frequency': instance.frequency,
      'progressionType': _$ProgressionTypeEnumMap[instance.progressionType]!,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'mesocycleLengthWeeks': instance.mesocycleLengthWeeks,
      'currentWeek': instance.currentWeek,
      'deloadFrequencyWeeks': instance.deloadFrequencyWeeks,
      'isActive': instance.isActive,
    };

const _$WorkoutGoalEnumMap = {
  WorkoutGoal.hypertrophy: 'hypertrophy',
  WorkoutGoal.strength: 'strength',
  WorkoutGoal.power: 'power',
  WorkoutGoal.fitness: 'fitness',
  WorkoutGoal.fatLoss: 'fatLoss',
};

const _$ProgressionTypeEnumMap = {
  ProgressionType.doubleProgression: 'doubleProgression',
  ProgressionType.linear: 'linear',
  ProgressionType.rpeBased: 'rpeBased',
  ProgressionType.custom: 'custom',
};

_WorkoutSplitDay _$WorkoutSplitDayFromJson(Map<String, dynamic> json) =>
    _WorkoutSplitDay(
      id: json['id'] as String,
      splitId: json['splitId'] as String,
      weekday: (json['weekday'] as num).toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      weekInMesocycle: (json['weekInMesocycle'] as num?)?.toInt() ?? 1,
      dayName: json['dayName'] as String?,
      isRest: json['isRest'] as bool? ?? false,
      targetMuscles:
          (json['targetMuscles'] as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList() ??
          const [],
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$WorkoutSplitDayToJson(_WorkoutSplitDay instance) =>
    <String, dynamic>{
      'id': instance.id,
      'splitId': instance.splitId,
      'weekday': instance.weekday,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'weekInMesocycle': instance.weekInMesocycle,
      'dayName': instance.dayName,
      'isRest': instance.isRest,
      'targetMuscles': instance.targetMuscles
          .map((e) => _$MuscleGroupEnumMap[e]!)
          .toList(),
      'notes': instance.notes,
    };

_SplitExercise _$SplitExerciseFromJson(Map<String, dynamic> json) =>
    _SplitExercise(
      id: json['id'] as String,
      splitDayId: json['splitDayId'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseOrder: (json['exerciseOrder'] as num).toInt(),
      targetSets: (json['targetSets'] as num).toInt(),
      targetRepsMin: (json['targetRepsMin'] as num).toInt(),
      targetRepsMax: (json['targetRepsMax'] as num).toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      targetRpe: (json['targetRpe'] as num?)?.toDouble(),
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 120,
      isSuperset: json['isSuperset'] as bool? ?? false,
      supersetGroupId: json['supersetGroupId'] as String?,
      exerciseName: json['exerciseName'] as String?,
    );

Map<String, dynamic> _$SplitExerciseToJson(_SplitExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'splitDayId': instance.splitDayId,
      'exerciseId': instance.exerciseId,
      'exerciseOrder': instance.exerciseOrder,
      'targetSets': instance.targetSets,
      'targetRepsMin': instance.targetRepsMin,
      'targetRepsMax': instance.targetRepsMax,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'targetRpe': instance.targetRpe,
      'restSeconds': instance.restSeconds,
      'isSuperset': instance.isSuperset,
      'supersetGroupId': instance.supersetGroupId,
      'exerciseName': instance.exerciseName,
    };

_WorkoutSession _$WorkoutSessionFromJson(Map<String, dynamic> json) =>
    _WorkoutSession(
      id: json['id'] as String,
      startedAt: (json['startedAt'] as num).toInt(),
      plannedTier: $enumDecode(_$WorkoutTierEnumMap, json['plannedTier']),
      completedTier: $enumDecode(_$WorkoutTierEnumMap, json['completedTier']),
      createdAt: (json['createdAt'] as num).toInt(),
      updatedAt: (json['updatedAt'] as num).toInt(),
      completedAt: (json['completedAt'] as num?)?.toInt(),
      splitDayId: json['splitDayId'] as String?,
      totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      totalSets: (json['totalSets'] as num?)?.toInt() ?? 0,
      totalReps: (json['totalReps'] as num?)?.toInt() ?? 0,
      actualDurationSeconds:
          (json['actualDurationSeconds'] as num?)?.toInt() ?? 0,
      sessionRpe: (json['sessionRpe'] as num?)?.toDouble(),
      notes: json['notes'] as String?,
      wasAutoAdjusted: json['wasAutoAdjusted'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkoutSessionToJson(_WorkoutSession instance) =>
    <String, dynamic>{
      'id': instance.id,
      'startedAt': instance.startedAt,
      'plannedTier': _$WorkoutTierEnumMap[instance.plannedTier]!,
      'completedTier': _$WorkoutTierEnumMap[instance.completedTier]!,
      'createdAt': instance.createdAt,
      'updatedAt': instance.updatedAt,
      'completedAt': instance.completedAt,
      'splitDayId': instance.splitDayId,
      'totalVolumeKg': instance.totalVolumeKg,
      'totalSets': instance.totalSets,
      'totalReps': instance.totalReps,
      'actualDurationSeconds': instance.actualDurationSeconds,
      'sessionRpe': instance.sessionRpe,
      'notes': instance.notes,
      'wasAutoAdjusted': instance.wasAutoAdjusted,
    };

const _$WorkoutTierEnumMap = {
  WorkoutTier.minimal: 'minimal',
  WorkoutTier.light: 'light',
  WorkoutTier.full: 'full',
};

_PerformedExercise _$PerformedExerciseFromJson(Map<String, dynamic> json) =>
    _PerformedExercise(
      id: json['id'] as String,
      sessionId: json['sessionId'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      primaryMuscle: $enumDecode(_$MuscleGroupEnumMap, json['primaryMuscle']),
      setOrder: (json['setOrder'] as num).toInt(),
      createdAt: (json['createdAt'] as num).toInt(),
      totalVolumeKg: (json['totalVolumeKg'] as num?)?.toDouble() ?? 0.0,
      previousBestWeight: (json['previousBestWeight'] as num?)?.toDouble(),
      previousBestReps: (json['previousBestReps'] as num?)?.toInt(),
      isPr: json['isPr'] as bool? ?? false,
    );

Map<String, dynamic> _$PerformedExerciseToJson(_PerformedExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'primaryMuscle': _$MuscleGroupEnumMap[instance.primaryMuscle]!,
      'setOrder': instance.setOrder,
      'createdAt': instance.createdAt,
      'totalVolumeKg': instance.totalVolumeKg,
      'previousBestWeight': instance.previousBestWeight,
      'previousBestReps': instance.previousBestReps,
      'isPr': instance.isPr,
    };

_PerformedSet _$PerformedSetFromJson(Map<String, dynamic> json) =>
    _PerformedSet(
      id: json['id'] as String,
      performedExerciseId: json['performedExerciseId'] as String,
      setNumber: (json['setNumber'] as num).toInt(),
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      rpe: (json['rpe'] as num).toDouble(),
      createdAt: (json['createdAt'] as num).toInt(),
      isWarmup: json['isWarmup'] as bool? ?? false,
      isDropSet: json['isDropSet'] as bool? ?? false,
      isCompleted: json['isCompleted'] as bool? ?? true,
      restSecondsTaken: (json['restSecondsTaken'] as num?)?.toInt(),
    );

Map<String, dynamic> _$PerformedSetToJson(_PerformedSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'performedExerciseId': instance.performedExerciseId,
      'setNumber': instance.setNumber,
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'rpe': instance.rpe,
      'createdAt': instance.createdAt,
      'isWarmup': instance.isWarmup,
      'isDropSet': instance.isDropSet,
      'isCompleted': instance.isCompleted,
      'restSecondsTaken': instance.restSecondsTaken,
    };

_ProgressionRecord _$ProgressionRecordFromJson(Map<String, dynamic> json) =>
    _ProgressionRecord(
      id: json['id'] as String,
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      muscleGroup: $enumDecode(_$MuscleGroupEnumMap, json['muscleGroup']),
      weightKg: (json['weightKg'] as num).toDouble(),
      reps: (json['reps'] as num).toInt(),
      setCount: (json['setCount'] as num).toInt(),
      achievedAt: (json['achievedAt'] as num).toInt(),
      progressionType: json['progressionType'] as String,
      previousBestWeight: (json['previousBestWeight'] as num?)?.toDouble(),
      previousBestReps: (json['previousBestReps'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ProgressionRecordToJson(_ProgressionRecord instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'muscleGroup': _$MuscleGroupEnumMap[instance.muscleGroup]!,
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'setCount': instance.setCount,
      'achievedAt': instance.achievedAt,
      'progressionType': instance.progressionType,
      'previousBestWeight': instance.previousBestWeight,
      'previousBestReps': instance.previousBestReps,
    };

_ReadinessScore _$ReadinessScoreFromJson(Map<String, dynamic> json) =>
    _ReadinessScore(
      date: json['date'] as String,
      score: (json['score'] as num).toInt(),
      suggestedTier: $enumDecode(_$WorkoutTierEnumMap, json['suggestedTier']),
      reason: json['reason'] as String,
      createdAt: (json['createdAt'] as num).toInt(),
      sleepMinutes: (json['sleepMinutes'] as num?)?.toInt(),
      sleepQuality: (json['sleepQuality'] as num?)?.toInt(),
      hrvRmssd: (json['hrvRmssd'] as num?)?.toInt(),
      restingHr: (json['restingHr'] as num?)?.toInt(),
      sorenessScore: (json['sorenessScore'] as num?)?.toInt(),
      fatigueScore: (json['fatigueScore'] as num?)?.toInt(),
      moodScore: (json['moodScore'] as num?)?.toInt(),
      isMenstrualPhase: json['isMenstrualPhase'] as bool? ?? false,
      factorsJson: (json['factorsJson'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, (e as num).toInt()),
      ),
    );

Map<String, dynamic> _$ReadinessScoreToJson(_ReadinessScore instance) =>
    <String, dynamic>{
      'date': instance.date,
      'score': instance.score,
      'suggestedTier': _$WorkoutTierEnumMap[instance.suggestedTier]!,
      'reason': instance.reason,
      'createdAt': instance.createdAt,
      'sleepMinutes': instance.sleepMinutes,
      'sleepQuality': instance.sleepQuality,
      'hrvRmssd': instance.hrvRmssd,
      'restingHr': instance.restingHr,
      'sorenessScore': instance.sorenessScore,
      'fatigueScore': instance.fatigueScore,
      'moodScore': instance.moodScore,
      'isMenstrualPhase': instance.isMenstrualPhase,
      'factorsJson': instance.factorsJson,
    };

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

_WeeklyVolumeReport _$WeeklyVolumeReportFromJson(
  Map<String, dynamic> json,
) => _WeeklyVolumeReport(
  volumePerMuscle: (json['volumePerMuscle'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$MuscleGroupEnumMap, k), (e as num).toDouble()),
  ),
  setsPerMuscle: (json['setsPerMuscle'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$MuscleGroupEnumMap, k), (e as num).toInt()),
  ),
  sessionsPerMuscle: (json['sessionsPerMuscle'] as Map<String, dynamic>).map(
    (k, e) =>
        MapEntry($enumDecode(_$MuscleGroupEnumMap, k), (e as num).toInt()),
  ),
  totalVolumeKg: (json['totalVolumeKg'] as num).toDouble(),
  totalSets: (json['totalSets'] as num).toInt(),
  totalSessions: (json['totalSessions'] as num).toInt(),
  weekStartDate: (json['weekStartDate'] as num).toInt(),
);

Map<String, dynamic> _$WeeklyVolumeReportToJson(_WeeklyVolumeReport instance) =>
    <String, dynamic>{
      'volumePerMuscle': instance.volumePerMuscle.map(
        (k, e) => MapEntry(_$MuscleGroupEnumMap[k]!, e),
      ),
      'setsPerMuscle': instance.setsPerMuscle.map(
        (k, e) => MapEntry(_$MuscleGroupEnumMap[k]!, e),
      ),
      'sessionsPerMuscle': instance.sessionsPerMuscle.map(
        (k, e) => MapEntry(_$MuscleGroupEnumMap[k]!, e),
      ),
      'totalVolumeKg': instance.totalVolumeKg,
      'totalSets': instance.totalSets,
      'totalSessions': instance.totalSessions,
      'weekStartDate': instance.weekStartDate,
    };

_StrengthStandard _$StrengthStandardFromJson(Map<String, dynamic> json) =>
    _StrengthStandard(
      exerciseId: json['exerciseId'] as String,
      exerciseName: json['exerciseName'] as String,
      muscleGroup: $enumDecode(_$MuscleGroupEnumMap, json['muscleGroup']),
      beginnerWeight: (json['beginnerWeight'] as num).toDouble(),
      intermediateWeight: (json['intermediateWeight'] as num).toDouble(),
      advancedWeight: (json['advancedWeight'] as num).toDouble(),
      eliteWeight: (json['eliteWeight'] as num).toDouble(),
    );

Map<String, dynamic> _$StrengthStandardToJson(_StrengthStandard instance) =>
    <String, dynamic>{
      'exerciseId': instance.exerciseId,
      'exerciseName': instance.exerciseName,
      'muscleGroup': _$MuscleGroupEnumMap[instance.muscleGroup]!,
      'beginnerWeight': instance.beginnerWeight,
      'intermediateWeight': instance.intermediateWeight,
      'advancedWeight': instance.advancedWeight,
      'eliteWeight': instance.eliteWeight,
    };

SaveSuccess<T> _$SaveSuccessFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => SaveSuccess<T>(
  fromJsonT(json['data']),
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SaveSuccessToJson<T>(
  SaveSuccess<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'data': toJsonT(instance.data),
  'runtimeType': instance.$type,
};

SaveFailure<T> _$SaveFailureFromJson<T>(
  Map<String, dynamic> json,
  T Function(Object? json) fromJsonT,
) => SaveFailure<T>(
  json['message'] as String,
  $type: json['runtimeType'] as String?,
);

Map<String, dynamic> _$SaveFailureToJson<T>(
  SaveFailure<T> instance,
  Object? Function(T value) toJsonT,
) => <String, dynamic>{
  'message': instance.message,
  'runtimeType': instance.$type,
};
