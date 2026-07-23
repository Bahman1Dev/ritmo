import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sports_entities.freezed.dart';
part 'sports_entities.g.dart';

// ──────────────────────────────────────────────────────────────
// Enums
// ──────────────────────────────────────────────────────────────

enum MuscleGroup {
  chest('CHEST', 'سینه', '🫀', 0xFFEF4444),
  back('BACK', 'پشت', '🔺', 0xFF3B82F6),
  shoulders('SHOULDERS', 'سرشانه', '🤸', 0xFFF59E0B),
  biceps('BICEPS', 'بازو جلو', '💪', 0xFF8B5CF6),
  triceps('TRICEPS', 'بازو پشت', '🦾', 0xFFEC4899),
  legs('LEGS', 'پا', '🦵', 0xFF10B981),
  abs('ABS', 'شکم', '🧱', 0xFFFBBF24),
  fullBody('FULL_BODY', 'تمام بدنه', '🏋️', 0xFF14B8A6),
  cardio('CARDIO', 'هوازی', '🏃', 0xFF22B8CF),
  rest('REST', 'استراحت', '😴', 0xFF64748B);

  const MuscleGroup(this.code, this.label, this.emoji, this.colorValue);
  final String code;
  final String label;
  final String emoji;
  final int colorValue;

  Color get color => Color(colorValue);

  static MuscleGroup fromCode(String code) => MuscleGroup.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => MuscleGroup.rest,
  );
}

enum Equipment {
  bodyweight('BODYWEIGHT', 'وزن بدن', '🏠'),
  dumbbell('DUMBBELL', 'دمبل', '🏋️'),
  barbell('BARBELL', 'هالتر', '🏋️‍♂️'),
  machine('MACHINE', 'دستگاه', '🏟️'),
  cable('CABLE', 'سیم‌کش', '🔗'),
  band('BAND', 'کمربند/بند', '🎯'),
  kettlebell('KETTLEBELL', 'کتلبل', '⚖️'),
  other('OTHER', 'سایر', '🤸');

  const Equipment(this.code, this.label, this.emoji);
  final String code;
  final String label;
  final String emoji;

  static Equipment fromCode(String code) => Equipment.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => Equipment.bodyweight,
  );
}

enum ExerciseCategory {
  compound('COMPOUND', 'ترکیبی', '🔄'),
  isolation('ISOLATION', 'تفریدی', '🎯'),
  cardio('CARDIO', 'هوازی', '🏃'),
  mobility('MOBILITY', 'موبیلیتی', '🧘');

  const ExerciseCategory(this.code, this.label, this.emoji);
  final String code;
  final String label;
  final String emoji;

  static ExerciseCategory fromCode(String code) => ExerciseCategory.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => ExerciseCategory.compound,
  );
}

enum DifficultyLevel {
  beginner('BEGINNER', 'مبتدی', 1),
  intermediate('INTERMEDIATE', 'متوسط', 2),
  advanced('ADVANCED', 'پیشرفته', 3);

  const DifficultyLevel(this.code, this.label, this.order);
  final String code;
  final String label;
  final int order;

  static DifficultyLevel fromCode(String code) => DifficultyLevel.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => DifficultyLevel.beginner,
  );
}

enum WorkoutTier {
  minimal('MINIMAL', 'حداقلی', 10, '🔸'),
  light('LIGHT', 'سبک', 25, '🔹'),
  full('FULL', 'کامل', 50, '🔶');

  const WorkoutTier(this.code, this.label, this.defaultMinutes, this.emoji);
  final String code;
  final String label;
  final int defaultMinutes;
  final String emoji;

  static WorkoutTier fromCode(String code) => WorkoutTier.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => WorkoutTier.full,
  );

  Color get color {
    switch (this) {
      case WorkoutTier.minimal: return const Color(0xFFF59E0B);
      case WorkoutTier.light:   return const Color(0xFF38BDF8);
      case WorkoutTier.full:    return const Color(0xFF10B981);
    }
  }
}

enum ProgressionType {
  doubleProgression('DOUBLE_PROGRESSION', 'پیشرفت دوگانه (تکرار → وزن)'),
  linear('LINEAR', 'خطی (افزایش هفتگی وزن)'),
  rpeBased('RPE_BASED', 'مبتنی بر RPE'),
  custom('CUSTOM', 'سفارشی');

  const ProgressionType(this.code, this.label);
  final String code;
  final String label;

  static ProgressionType fromCode(String code) => ProgressionType.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => ProgressionType.doubleProgression,
  );
}

enum WorkoutGoal {
  hypertrophy('HYPERTROPHY', 'بزرگی عضله'),
  strength('STRENGTH', 'قدرت'),
  power('POWER', 'قدرت انفجاری'),
  fitness('FITNESS', 'فیتنس عمومی'),
  fatLoss('FAT_LOSS', 'کاهش چربی + حفظ عضله');

  const WorkoutGoal(this.code, this.label);
  final String code;
  final String label;

  static WorkoutGoal fromCode(String code) => WorkoutGoal.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => WorkoutGoal.hypertrophy,
  );
}

enum Feeling {
  great('GREAT', '🔥 عالی'),
  good('GOOD', '👍 خوب'),
  tired('TIRED', '😓 خسته'),
  hard('HARD', '💪 سخت بود');

  const Feeling(this.code, this.label);
  final String code;
  final String label;

  static Feeling fromCode(String code) => Feeling.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => Feeling.good,
  );
}

enum SportsLocation {
  home('HOME', 'خانه', '🏠'),
  gym('GYM', 'باشگاه', '🏟️');

  const SportsLocation(this.code, this.label, this.emoji);
  final String code;
  final String label;
  final String emoji;

  static SportsLocation fromCode(String code) => SportsLocation.values.firstWhere(
    (e) => e.code == code.toUpperCase(),
    orElse: () => SportsLocation.home,
  );
}

// ──────────────────────────────────────────────────────────────
// Core Entities
// ──────────────────────────────────────────────────────────────

@freezed
abstract class Exercise with _$Exercise {
  const factory Exercise({
    required String id,
    required String name,
    required String nameFa,
    required MuscleGroup primaryMuscle,
    required ExerciseCategory category, required DifficultyLevel difficulty, required int createdAt, required int updatedAt, @Default([]) List<MuscleGroup> secondaryMuscles,
    @Default([]) List<Equipment> equipment,
    String? description,
    String? videoUrl,
    String? imageUrl,
    @Default([]) List<String> cues,
    @Default(true) bool isCompound,
    @Default(false) bool isUserCreated,
    @Default(0) int usageCount,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);
}

@freezed
abstract class WorkoutPlan with _$WorkoutPlan {
  const factory WorkoutPlan({
    required String id,
    required String name,
    required WorkoutGoal goal,
    required int frequency, required ProgressionType progressionType, required int createdAt, required int updatedAt, // days per week
    @Default(6) int mesocycleLengthWeeks,
    @Default(1) int currentWeek,
    @Default(4) int deloadFrequencyWeeks,
    @Default(true) bool isActive,
  }) = _WorkoutPlan;

  factory WorkoutPlan.fromJson(Map<String, dynamic> json) => _$WorkoutPlanFromJson(json);
}

@freezed
abstract class WorkoutSplitDay with _$WorkoutSplitDay {
  const factory WorkoutSplitDay({
    required String id,
    required String splitId,
    required int weekday, required int createdAt, required int updatedAt, // 1=Mon .. 7=Sun
    @Default(1) int weekInMesocycle,
    String? dayName, // "Upper A", "Lower B"
    @Default(false) bool isRest,
    @Default([]) List<MuscleGroup> targetMuscles,
    String? notes,
  }) = _WorkoutSplitDay;

  factory WorkoutSplitDay.fromJson(Map<String, dynamic> json) => _$WorkoutSplitDayFromJson(json);
}

@freezed
abstract class SplitExercise with _$SplitExercise {
  const factory SplitExercise({
    required String id,
    required String splitDayId,
    required String exerciseId,
    required int exerciseOrder,
    required int targetSets,
    required int targetRepsMin,
    required int targetRepsMax,
    required int createdAt, required int updatedAt, double? targetRpe,
    @Default(120) int restSeconds,
    @Default(false) bool isSuperset,
    String? supersetGroupId,
    String? exerciseName,
  }) = _SplitExercise;

  factory SplitExercise.fromJson(Map<String, dynamic> json) => _$SplitExerciseFromJson(json);
}

@freezed
abstract class WorkoutSession with _$WorkoutSession {
  const factory WorkoutSession({
    required String id,
    required int startedAt,
    required WorkoutTier plannedTier, required WorkoutTier completedTier, required int createdAt, required int updatedAt, int? completedAt,
    String? splitDayId,
    @Default(0.0) double totalVolumeKg,
    @Default(0) int totalSets,
    @Default(0) int totalReps,
    @Default(0) int actualDurationSeconds,
    double? sessionRpe, // 1-10
    String? notes,
    @Default(false) bool wasAutoAdjusted,
  }) = _WorkoutSession;

  factory WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);
}

@freezed
abstract class PerformedExercise with _$PerformedExercise {
  const factory PerformedExercise({
    required String id,
    required String sessionId,
    required String exerciseId,
    required String exerciseName,
    required MuscleGroup primaryMuscle,
    required int setOrder,
    required int createdAt, @Default(0.0) double totalVolumeKg,
    double? previousBestWeight,
    int? previousBestReps,
    @Default(false) bool isPr,
  }) = _PerformedExercise;

  factory PerformedExercise.fromJson(Map<String, dynamic> json) => _$PerformedExerciseFromJson(json);
}

@freezed
abstract class PerformedSet with _$PerformedSet {
  const factory PerformedSet({
    required String id,
    required String performedExerciseId,
    required int setNumber,
    required double weightKg,
    required int reps,
    required double rpe, required int createdAt, // 6.0 - 10.0
    @Default(false) bool isWarmup,
    @Default(false) bool isDropSet,
    @Default(true) bool isCompleted,
    int? restSecondsTaken,
  }) = _PerformedSet;

  factory PerformedSet.fromJson(Map<String, dynamic> json) => _$PerformedSetFromJson(json);
}

@freezed
abstract class ProgressionRecord with _$ProgressionRecord {
  const factory ProgressionRecord({
    required String id,
    required String exerciseId,
    required String exerciseName,
    required MuscleGroup muscleGroup,
    required double weightKg,
    required int reps,
    required int setCount,
    required int achievedAt,
    required String progressionType, // weight_increase, rep_increase, volume_increase, rpe_decrease
    double? previousBestWeight,
    int? previousBestReps,
  }) = _ProgressionRecord;

  factory ProgressionRecord.fromJson(Map<String, dynamic> json) => _$ProgressionRecordFromJson(json);
}

@freezed
abstract class ReadinessScore with _$ReadinessScore {
  const factory ReadinessScore({
    required String date, // YYYY-MM-DD
    required int score, required WorkoutTier suggestedTier, required String reason, required int createdAt, // 0-100
    int? sleepMinutes,
    int? sleepQuality, // 1-5
    int? hrvRmssd,
    int? restingHr,
    int? sorenessScore, // 0-10
    int? fatigueScore, // 0-10
    int? moodScore, // 1-5
    @Default(false) bool isMenstrualPhase,
    Map<String, int>? factorsJson, // individual factor scores
  }) = _ReadinessScore;

  factory ReadinessScore.fromJson(Map<String, dynamic> json) => _$ReadinessScoreFromJson(json);
}

// ──────────────────────────────────────────────────────────────
// Query/Input Models
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

@freezed
abstract class WeeklyVolumeReport with _$WeeklyVolumeReport {
  const factory WeeklyVolumeReport({
    required Map<MuscleGroup, double> volumePerMuscle,
    required Map<MuscleGroup, int> setsPerMuscle,
    required Map<MuscleGroup, int> sessionsPerMuscle,
    required double totalVolumeKg,
    required int totalSets,
    required int totalSessions,
    required int weekStartDate,
  }) = _WeeklyVolumeReport;

  factory WeeklyVolumeReport.fromJson(Map<String, dynamic> json) => _$WeeklyVolumeReportFromJson(json);
}

@freezed
abstract class StrengthStandard with _$StrengthStandard {
  const factory StrengthStandard({
    required String exerciseId,
    required String exerciseName,
    required MuscleGroup muscleGroup,
    required double beginnerWeight,
    required double intermediateWeight,
    required double advancedWeight,
    required double eliteWeight,
  }) = _StrengthStandard;

  factory StrengthStandard.fromJson(Map<String, dynamic> json) => _$StrengthStandardFromJson(json);
}

// ──────────────────────────────────────────────────────────────
// Result Types
// ──────────────────────────────────────────────────────────────

@Freezed(genericArgumentFactories: true)
abstract class SaveResult<T> with _$SaveResult<T> {
  const factory SaveResult.success(T data) = SaveSuccess<T>;
  const factory SaveResult.failure(String message) = SaveFailure<T>;

  factory SaveResult.fromJson(Map<String, dynamic> json, T Function(Object?) fromJsonT) =>
      _$SaveResultFromJson(json, fromJsonT);
}