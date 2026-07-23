// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sports_providers.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SportsDashboardState _$SportsDashboardStateFromJson(
  Map<String, dynamic> json,
) => _SportsDashboardState(
  isSetupDone: json['isSetupDone'] as bool? ?? false,
  isLoading: json['isLoading'] as bool? ?? true,
  todayPlan: json['todayPlan'] == null
      ? null
      : TodayWorkoutPlan.fromJson(json['todayPlan'] as Map<String, dynamic>),
  todaysSession: json['todaysSession'] == null
      ? null
      : WorkoutSession.fromJson(json['todaysSession'] as Map<String, dynamic>),
  readiness: json['readiness'] == null
      ? null
      : ReadinessScore.fromJson(json['readiness'] as Map<String, dynamic>),
  location:
      $enumDecodeNullable(_$SportsLocationEnumMap, json['location']) ??
      SportsLocation.home,
  goal:
      $enumDecodeNullable(_$WorkoutGoalEnumMap, json['goal']) ??
      WorkoutGoal.hypertrophy,
  recentPrs: (json['recentPrs'] as List<dynamic>?)
      ?.map((e) => ProgressionRecord.fromJson(e as Map<String, dynamic>))
      .toList(),
  readinessHistory: (json['readinessHistory'] as List<dynamic>?)
      ?.map((e) => ReadinessScore.fromJson(e as Map<String, dynamic>))
      .toList(),
  weeklyVolume: json['weeklyVolume'] == null
      ? null
      : WeeklyVolumeReport.fromJson(
          json['weeklyVolume'] as Map<String, dynamic>,
        ),
  currentStreak: (json['currentStreak'] as num?)?.toInt() ?? 0,
  error: json['error'] as String?,
);

Map<String, dynamic> _$SportsDashboardStateToJson(
  _SportsDashboardState instance,
) => <String, dynamic>{
  'isSetupDone': instance.isSetupDone,
  'isLoading': instance.isLoading,
  'todayPlan': instance.todayPlan,
  'todaysSession': instance.todaysSession,
  'readiness': instance.readiness,
  'location': _$SportsLocationEnumMap[instance.location]!,
  'goal': _$WorkoutGoalEnumMap[instance.goal]!,
  'recentPrs': instance.recentPrs,
  'readinessHistory': instance.readinessHistory,
  'weeklyVolume': instance.weeklyVolume,
  'currentStreak': instance.currentStreak,
  'error': instance.error,
};

const _$SportsLocationEnumMap = {
  SportsLocation.home: 'home',
  SportsLocation.gym: 'gym',
};

const _$WorkoutGoalEnumMap = {
  WorkoutGoal.hypertrophy: 'hypertrophy',
  WorkoutGoal.strength: 'strength',
  WorkoutGoal.power: 'power',
  WorkoutGoal.fitness: 'fitness',
  WorkoutGoal.fatLoss: 'fatLoss',
};

_WorkoutSessionState _$WorkoutSessionStateFromJson(Map<String, dynamic> json) =>
    _WorkoutSessionState(
      session: WorkoutSession.fromJson(json['session'] as Map<String, dynamic>),
      exercises: (json['exercises'] as List<dynamic>)
          .map((e) => PerformedExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
      currentExerciseIndex:
          (json['currentExerciseIndex'] as num?)?.toInt() ?? 0,
      isComplete: json['isComplete'] as bool? ?? false,
    );

Map<String, dynamic> _$WorkoutSessionStateToJson(
  _WorkoutSessionState instance,
) => <String, dynamic>{
  'session': instance.session,
  'exercises': instance.exercises,
  'currentExerciseIndex': instance.currentExerciseIndex,
  'isComplete': instance.isComplete,
};

_SplitBuilderState _$SplitBuilderStateFromJson(Map<String, dynamic> json) =>
    _SplitBuilderState(
      goal: $enumDecode(_$WorkoutGoalEnumMap, json['goal']),
      frequency: (json['frequency'] as num).toInt(),
      location: $enumDecode(_$SportsLocationEnumMap, json['location']),
      selectedDays: (json['selectedDays'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      splits: (json['splits'] as Map<String, dynamic>).map(
        (k, e) => MapEntry(
          k,
          (e as List<dynamic>)
              .map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList(),
        ),
      ),
      currentWeek: (json['currentWeek'] as num).toInt(),
      mesocycleWeeks: (json['mesocycleWeeks'] as num).toInt(),
      progressionType: $enumDecode(
        _$ProgressionTypeEnumMap,
        json['progressionType'],
      ),
      deloadFrequency: (json['deloadFrequency'] as num).toInt(),
      currentStep:
          $enumDecodeNullable(_$SplitBuilderStepEnumMap, json['currentStep']) ??
          SplitBuilderStep.goal,
    );

Map<String, dynamic> _$SplitBuilderStateToJson(_SplitBuilderState instance) =>
    <String, dynamic>{
      'goal': _$WorkoutGoalEnumMap[instance.goal]!,
      'frequency': instance.frequency,
      'location': _$SportsLocationEnumMap[instance.location]!,
      'selectedDays': instance.selectedDays,
      'splits': instance.splits.map(
        (k, e) => MapEntry(k, e.map((e) => _$MuscleGroupEnumMap[e]!).toList()),
      ),
      'currentWeek': instance.currentWeek,
      'mesocycleWeeks': instance.mesocycleWeeks,
      'progressionType': _$ProgressionTypeEnumMap[instance.progressionType]!,
      'deloadFrequency': instance.deloadFrequency,
      'currentStep': _$SplitBuilderStepEnumMap[instance.currentStep]!,
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

const _$ProgressionTypeEnumMap = {
  ProgressionType.doubleProgression: 'doubleProgression',
  ProgressionType.linear: 'linear',
  ProgressionType.rpeBased: 'rpeBased',
  ProgressionType.custom: 'custom',
};

const _$SplitBuilderStepEnumMap = {
  SplitBuilderStep.goal: 'goal',
  SplitBuilderStep.frequency: 'frequency',
  SplitBuilderStep.days: 'days',
  SplitBuilderStep.location: 'location',
  SplitBuilderStep.advanced: 'advanced',
  SplitBuilderStep.review: 'review',
};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(SportsDashboardController)
final sportsDashboardControllerProvider = SportsDashboardControllerProvider._();

final class SportsDashboardControllerProvider
    extends
        $AsyncNotifierProvider<
          SportsDashboardController,
          SportsDashboardState
        > {
  SportsDashboardControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'sportsDashboardControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sportsDashboardControllerHash();

  @$internal
  @override
  SportsDashboardController create() => SportsDashboardController();
}

String _$sportsDashboardControllerHash() =>
    r'1c74cba47803adf343c9beb7ec92af7fc34abd44';

abstract class _$SportsDashboardController
    extends $AsyncNotifier<SportsDashboardState> {
  FutureOr<SportsDashboardState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref
            as $Ref<AsyncValue<SportsDashboardState>, SportsDashboardState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                AsyncValue<SportsDashboardState>,
                SportsDashboardState
              >,
              AsyncValue<SportsDashboardState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}

@ProviderFor(WorkoutSessionController)
final workoutSessionControllerProvider = WorkoutSessionControllerFamily._();

final class WorkoutSessionControllerProvider
    extends
        $AsyncNotifierProvider<WorkoutSessionController, WorkoutSessionState> {
  WorkoutSessionControllerProvider._({
    required WorkoutSessionControllerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'workoutSessionControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$workoutSessionControllerHash();

  @override
  String toString() {
    return r'workoutSessionControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WorkoutSessionController create() => WorkoutSessionController();

  @override
  bool operator ==(Object other) {
    return other is WorkoutSessionControllerProvider &&
        other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$workoutSessionControllerHash() =>
    r'cbaae39ee41b529bd27cff5628ef1727aa0f01b1';

final class WorkoutSessionControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          WorkoutSessionController,
          AsyncValue<WorkoutSessionState>,
          WorkoutSessionState,
          FutureOr<WorkoutSessionState>,
          String
        > {
  WorkoutSessionControllerFamily._()
    : super(
        retry: null,
        name: r'workoutSessionControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  WorkoutSessionControllerProvider call(String sessionId) =>
      WorkoutSessionControllerProvider._(argument: sessionId, from: this);

  @override
  String toString() => r'workoutSessionControllerProvider';
}

abstract class _$WorkoutSessionController
    extends $AsyncNotifier<WorkoutSessionState> {
  late final _$args = ref.$arg as String;
  String get sessionId => _$args;

  FutureOr<WorkoutSessionState> build(String sessionId);
  @$mustCallSuper
  @override
  void runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<WorkoutSessionState>, WorkoutSessionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WorkoutSessionState>, WorkoutSessionState>,
              AsyncValue<WorkoutSessionState>,
              Object?,
              Object?
            >;
    element.handleCreate(ref, () => build(_$args));
  }
}

@ProviderFor(SplitBuilderController)
final splitBuilderControllerProvider = SplitBuilderControllerProvider._();

final class SplitBuilderControllerProvider
    extends $NotifierProvider<SplitBuilderController, SplitBuilderState> {
  SplitBuilderControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'splitBuilderControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$splitBuilderControllerHash();

  @$internal
  @override
  SplitBuilderController create() => SplitBuilderController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SplitBuilderState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SplitBuilderState>(value),
    );
  }
}

String _$splitBuilderControllerHash() =>
    r'f8502df0b364d39bc237bf1ac9d77c5fdcf81971';

abstract class _$SplitBuilderController extends $Notifier<SplitBuilderState> {
  SplitBuilderState build();
  @$mustCallSuper
  @override
  void runBuild() {
    final ref = this.ref as $Ref<SplitBuilderState, SplitBuilderState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SplitBuilderState, SplitBuilderState>,
              SplitBuilderState,
              Object?,
              Object?
            >;
    element.handleCreate(ref, build);
  }
}
