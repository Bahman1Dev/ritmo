// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sports_providers.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SportsDashboardState {

 bool get isSetupDone; bool get isLoading; TodayWorkoutPlan? get todayPlan; WorkoutSession? get todaysSession; ReadinessScore? get readiness; SportsLocation get location; WorkoutGoal get goal; List<ProgressionRecord>? get recentPrs; List<ReadinessScore>? get readinessHistory; WeeklyVolumeReport? get weeklyVolume; int get currentStreak; String? get error;
/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SportsDashboardStateCopyWith<SportsDashboardState> get copyWith => _$SportsDashboardStateCopyWithImpl<SportsDashboardState>(this as SportsDashboardState, _$identity);

  /// Serializes this SportsDashboardState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SportsDashboardState&&(identical(other.isSetupDone, isSetupDone) || other.isSetupDone == isSetupDone)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.todayPlan, todayPlan) || other.todayPlan == todayPlan)&&(identical(other.todaysSession, todaysSession) || other.todaysSession == todaysSession)&&(identical(other.readiness, readiness) || other.readiness == readiness)&&(identical(other.location, location) || other.location == location)&&(identical(other.goal, goal) || other.goal == goal)&&const DeepCollectionEquality().equals(other.recentPrs, recentPrs)&&const DeepCollectionEquality().equals(other.readinessHistory, readinessHistory)&&(identical(other.weeklyVolume, weeklyVolume) || other.weeklyVolume == weeklyVolume)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSetupDone,isLoading,todayPlan,todaysSession,readiness,location,goal,const DeepCollectionEquality().hash(recentPrs),const DeepCollectionEquality().hash(readinessHistory),weeklyVolume,currentStreak,error);

@override
String toString() {
  return 'SportsDashboardState(isSetupDone: $isSetupDone, isLoading: $isLoading, todayPlan: $todayPlan, todaysSession: $todaysSession, readiness: $readiness, location: $location, goal: $goal, recentPrs: $recentPrs, readinessHistory: $readinessHistory, weeklyVolume: $weeklyVolume, currentStreak: $currentStreak, error: $error)';
}


}

/// @nodoc
abstract mixin class $SportsDashboardStateCopyWith<$Res>  {
  factory $SportsDashboardStateCopyWith(SportsDashboardState value, $Res Function(SportsDashboardState) _then) = _$SportsDashboardStateCopyWithImpl;
@useResult
$Res call({
 bool isSetupDone, bool isLoading, TodayWorkoutPlan? todayPlan, WorkoutSession? todaysSession, ReadinessScore? readiness, SportsLocation location, WorkoutGoal goal, List<ProgressionRecord>? recentPrs, List<ReadinessScore>? readinessHistory, WeeklyVolumeReport? weeklyVolume, int currentStreak, String? error
});


$TodayWorkoutPlanCopyWith<$Res>? get todayPlan;$WorkoutSessionCopyWith<$Res>? get todaysSession;$ReadinessScoreCopyWith<$Res>? get readiness;$WeeklyVolumeReportCopyWith<$Res>? get weeklyVolume;

}
/// @nodoc
class _$SportsDashboardStateCopyWithImpl<$Res>
    implements $SportsDashboardStateCopyWith<$Res> {
  _$SportsDashboardStateCopyWithImpl(this._self, this._then);

  final SportsDashboardState _self;
  final $Res Function(SportsDashboardState) _then;

/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? isSetupDone = null,Object? isLoading = null,Object? todayPlan = freezed,Object? todaysSession = freezed,Object? readiness = freezed,Object? location = null,Object? goal = null,Object? recentPrs = freezed,Object? readinessHistory = freezed,Object? weeklyVolume = freezed,Object? currentStreak = null,Object? error = freezed,}) {
  return _then(_self.copyWith(
isSetupDone: null == isSetupDone ? _self.isSetupDone : isSetupDone // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,todayPlan: freezed == todayPlan ? _self.todayPlan : todayPlan // ignore: cast_nullable_to_non_nullable
as TodayWorkoutPlan?,todaysSession: freezed == todaysSession ? _self.todaysSession : todaysSession // ignore: cast_nullable_to_non_nullable
as WorkoutSession?,readiness: freezed == readiness ? _self.readiness : readiness // ignore: cast_nullable_to_non_nullable
as ReadinessScore?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as SportsLocation,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as WorkoutGoal,recentPrs: freezed == recentPrs ? _self.recentPrs : recentPrs // ignore: cast_nullable_to_non_nullable
as List<ProgressionRecord>?,readinessHistory: freezed == readinessHistory ? _self.readinessHistory : readinessHistory // ignore: cast_nullable_to_non_nullable
as List<ReadinessScore>?,weeklyVolume: freezed == weeklyVolume ? _self.weeklyVolume : weeklyVolume // ignore: cast_nullable_to_non_nullable
as WeeklyVolumeReport?,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}
/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TodayWorkoutPlanCopyWith<$Res>? get todayPlan {
    if (_self.todayPlan == null) {
    return null;
  }

  return $TodayWorkoutPlanCopyWith<$Res>(_self.todayPlan!, (value) {
    return _then(_self.copyWith(todayPlan: value));
  });
}/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutSessionCopyWith<$Res>? get todaysSession {
    if (_self.todaysSession == null) {
    return null;
  }

  return $WorkoutSessionCopyWith<$Res>(_self.todaysSession!, (value) {
    return _then(_self.copyWith(todaysSession: value));
  });
}/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadinessScoreCopyWith<$Res>? get readiness {
    if (_self.readiness == null) {
    return null;
  }

  return $ReadinessScoreCopyWith<$Res>(_self.readiness!, (value) {
    return _then(_self.copyWith(readiness: value));
  });
}/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklyVolumeReportCopyWith<$Res>? get weeklyVolume {
    if (_self.weeklyVolume == null) {
    return null;
  }

  return $WeeklyVolumeReportCopyWith<$Res>(_self.weeklyVolume!, (value) {
    return _then(_self.copyWith(weeklyVolume: value));
  });
}
}


/// Adds pattern-matching-related methods to [SportsDashboardState].
extension SportsDashboardStatePatterns on SportsDashboardState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SportsDashboardState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SportsDashboardState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SportsDashboardState value)  $default,){
final _that = this;
switch (_that) {
case _SportsDashboardState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SportsDashboardState value)?  $default,){
final _that = this;
switch (_that) {
case _SportsDashboardState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool isSetupDone,  bool isLoading,  TodayWorkoutPlan? todayPlan,  WorkoutSession? todaysSession,  ReadinessScore? readiness,  SportsLocation location,  WorkoutGoal goal,  List<ProgressionRecord>? recentPrs,  List<ReadinessScore>? readinessHistory,  WeeklyVolumeReport? weeklyVolume,  int currentStreak,  String? error)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SportsDashboardState() when $default != null:
return $default(_that.isSetupDone,_that.isLoading,_that.todayPlan,_that.todaysSession,_that.readiness,_that.location,_that.goal,_that.recentPrs,_that.readinessHistory,_that.weeklyVolume,_that.currentStreak,_that.error);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool isSetupDone,  bool isLoading,  TodayWorkoutPlan? todayPlan,  WorkoutSession? todaysSession,  ReadinessScore? readiness,  SportsLocation location,  WorkoutGoal goal,  List<ProgressionRecord>? recentPrs,  List<ReadinessScore>? readinessHistory,  WeeklyVolumeReport? weeklyVolume,  int currentStreak,  String? error)  $default,) {final _that = this;
switch (_that) {
case _SportsDashboardState():
return $default(_that.isSetupDone,_that.isLoading,_that.todayPlan,_that.todaysSession,_that.readiness,_that.location,_that.goal,_that.recentPrs,_that.readinessHistory,_that.weeklyVolume,_that.currentStreak,_that.error);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool isSetupDone,  bool isLoading,  TodayWorkoutPlan? todayPlan,  WorkoutSession? todaysSession,  ReadinessScore? readiness,  SportsLocation location,  WorkoutGoal goal,  List<ProgressionRecord>? recentPrs,  List<ReadinessScore>? readinessHistory,  WeeklyVolumeReport? weeklyVolume,  int currentStreak,  String? error)?  $default,) {final _that = this;
switch (_that) {
case _SportsDashboardState() when $default != null:
return $default(_that.isSetupDone,_that.isLoading,_that.todayPlan,_that.todaysSession,_that.readiness,_that.location,_that.goal,_that.recentPrs,_that.readinessHistory,_that.weeklyVolume,_that.currentStreak,_that.error);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SportsDashboardState implements SportsDashboardState {
  const _SportsDashboardState({this.isSetupDone = false, this.isLoading = true, this.todayPlan, this.todaysSession, this.readiness, this.location = SportsLocation.home, this.goal = WorkoutGoal.hypertrophy, final  List<ProgressionRecord>? recentPrs, final  List<ReadinessScore>? readinessHistory, this.weeklyVolume, this.currentStreak = 0, this.error}): _recentPrs = recentPrs,_readinessHistory = readinessHistory;
  factory _SportsDashboardState.fromJson(Map<String, dynamic> json) => _$SportsDashboardStateFromJson(json);

@override@JsonKey() final  bool isSetupDone;
@override@JsonKey() final  bool isLoading;
@override final  TodayWorkoutPlan? todayPlan;
@override final  WorkoutSession? todaysSession;
@override final  ReadinessScore? readiness;
@override@JsonKey() final  SportsLocation location;
@override@JsonKey() final  WorkoutGoal goal;
 final  List<ProgressionRecord>? _recentPrs;
@override List<ProgressionRecord>? get recentPrs {
  final value = _recentPrs;
  if (value == null) return null;
  if (_recentPrs is EqualUnmodifiableListView) return _recentPrs;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

 final  List<ReadinessScore>? _readinessHistory;
@override List<ReadinessScore>? get readinessHistory {
  final value = _readinessHistory;
  if (value == null) return null;
  if (_readinessHistory is EqualUnmodifiableListView) return _readinessHistory;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}

@override final  WeeklyVolumeReport? weeklyVolume;
@override@JsonKey() final  int currentStreak;
@override final  String? error;

/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SportsDashboardStateCopyWith<_SportsDashboardState> get copyWith => __$SportsDashboardStateCopyWithImpl<_SportsDashboardState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SportsDashboardStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SportsDashboardState&&(identical(other.isSetupDone, isSetupDone) || other.isSetupDone == isSetupDone)&&(identical(other.isLoading, isLoading) || other.isLoading == isLoading)&&(identical(other.todayPlan, todayPlan) || other.todayPlan == todayPlan)&&(identical(other.todaysSession, todaysSession) || other.todaysSession == todaysSession)&&(identical(other.readiness, readiness) || other.readiness == readiness)&&(identical(other.location, location) || other.location == location)&&(identical(other.goal, goal) || other.goal == goal)&&const DeepCollectionEquality().equals(other._recentPrs, _recentPrs)&&const DeepCollectionEquality().equals(other._readinessHistory, _readinessHistory)&&(identical(other.weeklyVolume, weeklyVolume) || other.weeklyVolume == weeklyVolume)&&(identical(other.currentStreak, currentStreak) || other.currentStreak == currentStreak)&&(identical(other.error, error) || other.error == error));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,isSetupDone,isLoading,todayPlan,todaysSession,readiness,location,goal,const DeepCollectionEquality().hash(_recentPrs),const DeepCollectionEquality().hash(_readinessHistory),weeklyVolume,currentStreak,error);

@override
String toString() {
  return 'SportsDashboardState(isSetupDone: $isSetupDone, isLoading: $isLoading, todayPlan: $todayPlan, todaysSession: $todaysSession, readiness: $readiness, location: $location, goal: $goal, recentPrs: $recentPrs, readinessHistory: $readinessHistory, weeklyVolume: $weeklyVolume, currentStreak: $currentStreak, error: $error)';
}


}

/// @nodoc
abstract mixin class _$SportsDashboardStateCopyWith<$Res> implements $SportsDashboardStateCopyWith<$Res> {
  factory _$SportsDashboardStateCopyWith(_SportsDashboardState value, $Res Function(_SportsDashboardState) _then) = __$SportsDashboardStateCopyWithImpl;
@override @useResult
$Res call({
 bool isSetupDone, bool isLoading, TodayWorkoutPlan? todayPlan, WorkoutSession? todaysSession, ReadinessScore? readiness, SportsLocation location, WorkoutGoal goal, List<ProgressionRecord>? recentPrs, List<ReadinessScore>? readinessHistory, WeeklyVolumeReport? weeklyVolume, int currentStreak, String? error
});


@override $TodayWorkoutPlanCopyWith<$Res>? get todayPlan;@override $WorkoutSessionCopyWith<$Res>? get todaysSession;@override $ReadinessScoreCopyWith<$Res>? get readiness;@override $WeeklyVolumeReportCopyWith<$Res>? get weeklyVolume;

}
/// @nodoc
class __$SportsDashboardStateCopyWithImpl<$Res>
    implements _$SportsDashboardStateCopyWith<$Res> {
  __$SportsDashboardStateCopyWithImpl(this._self, this._then);

  final _SportsDashboardState _self;
  final $Res Function(_SportsDashboardState) _then;

/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? isSetupDone = null,Object? isLoading = null,Object? todayPlan = freezed,Object? todaysSession = freezed,Object? readiness = freezed,Object? location = null,Object? goal = null,Object? recentPrs = freezed,Object? readinessHistory = freezed,Object? weeklyVolume = freezed,Object? currentStreak = null,Object? error = freezed,}) {
  return _then(_SportsDashboardState(
isSetupDone: null == isSetupDone ? _self.isSetupDone : isSetupDone // ignore: cast_nullable_to_non_nullable
as bool,isLoading: null == isLoading ? _self.isLoading : isLoading // ignore: cast_nullable_to_non_nullable
as bool,todayPlan: freezed == todayPlan ? _self.todayPlan : todayPlan // ignore: cast_nullable_to_non_nullable
as TodayWorkoutPlan?,todaysSession: freezed == todaysSession ? _self.todaysSession : todaysSession // ignore: cast_nullable_to_non_nullable
as WorkoutSession?,readiness: freezed == readiness ? _self.readiness : readiness // ignore: cast_nullable_to_non_nullable
as ReadinessScore?,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as SportsLocation,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as WorkoutGoal,recentPrs: freezed == recentPrs ? _self._recentPrs : recentPrs // ignore: cast_nullable_to_non_nullable
as List<ProgressionRecord>?,readinessHistory: freezed == readinessHistory ? _self._readinessHistory : readinessHistory // ignore: cast_nullable_to_non_nullable
as List<ReadinessScore>?,weeklyVolume: freezed == weeklyVolume ? _self.weeklyVolume : weeklyVolume // ignore: cast_nullable_to_non_nullable
as WeeklyVolumeReport?,currentStreak: null == currentStreak ? _self.currentStreak : currentStreak // ignore: cast_nullable_to_non_nullable
as int,error: freezed == error ? _self.error : error // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TodayWorkoutPlanCopyWith<$Res>? get todayPlan {
    if (_self.todayPlan == null) {
    return null;
  }

  return $TodayWorkoutPlanCopyWith<$Res>(_self.todayPlan!, (value) {
    return _then(_self.copyWith(todayPlan: value));
  });
}/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutSessionCopyWith<$Res>? get todaysSession {
    if (_self.todaysSession == null) {
    return null;
  }

  return $WorkoutSessionCopyWith<$Res>(_self.todaysSession!, (value) {
    return _then(_self.copyWith(todaysSession: value));
  });
}/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ReadinessScoreCopyWith<$Res>? get readiness {
    if (_self.readiness == null) {
    return null;
  }

  return $ReadinessScoreCopyWith<$Res>(_self.readiness!, (value) {
    return _then(_self.copyWith(readiness: value));
  });
}/// Create a copy of SportsDashboardState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WeeklyVolumeReportCopyWith<$Res>? get weeklyVolume {
    if (_self.weeklyVolume == null) {
    return null;
  }

  return $WeeklyVolumeReportCopyWith<$Res>(_self.weeklyVolume!, (value) {
    return _then(_self.copyWith(weeklyVolume: value));
  });
}
}


/// @nodoc
mixin _$WorkoutSessionState {

 WorkoutSession get session; List<PerformedExercise> get exercises; int get currentExerciseIndex; bool get isComplete;
/// Create a copy of WorkoutSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSessionStateCopyWith<WorkoutSessionState> get copyWith => _$WorkoutSessionStateCopyWithImpl<WorkoutSessionState>(this as WorkoutSessionState, _$identity);

  /// Serializes this WorkoutSessionState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSessionState&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.currentExerciseIndex, currentExerciseIndex) || other.currentExerciseIndex == currentExerciseIndex)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(exercises),currentExerciseIndex,isComplete);

@override
String toString() {
  return 'WorkoutSessionState(session: $session, exercises: $exercises, currentExerciseIndex: $currentExerciseIndex, isComplete: $isComplete)';
}


}

/// @nodoc
abstract mixin class $WorkoutSessionStateCopyWith<$Res>  {
  factory $WorkoutSessionStateCopyWith(WorkoutSessionState value, $Res Function(WorkoutSessionState) _then) = _$WorkoutSessionStateCopyWithImpl;
@useResult
$Res call({
 WorkoutSession session, List<PerformedExercise> exercises, int currentExerciseIndex, bool isComplete
});


$WorkoutSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$WorkoutSessionStateCopyWithImpl<$Res>
    implements $WorkoutSessionStateCopyWith<$Res> {
  _$WorkoutSessionStateCopyWithImpl(this._self, this._then);

  final WorkoutSessionState _self;
  final $Res Function(WorkoutSessionState) _then;

/// Create a copy of WorkoutSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? session = null,Object? exercises = null,Object? currentExerciseIndex = null,Object? isComplete = null,}) {
  return _then(_self.copyWith(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WorkoutSession,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<PerformedExercise>,currentExerciseIndex: null == currentExerciseIndex ? _self.currentExerciseIndex : currentExerciseIndex // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of WorkoutSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutSessionCopyWith<$Res> get session {
  
  return $WorkoutSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [WorkoutSessionState].
extension WorkoutSessionStatePatterns on WorkoutSessionState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSessionState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSessionState value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSessionState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSessionState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkoutSession session,  List<PerformedExercise> exercises,  int currentExerciseIndex,  bool isComplete)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSessionState() when $default != null:
return $default(_that.session,_that.exercises,_that.currentExerciseIndex,_that.isComplete);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkoutSession session,  List<PerformedExercise> exercises,  int currentExerciseIndex,  bool isComplete)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSessionState():
return $default(_that.session,_that.exercises,_that.currentExerciseIndex,_that.isComplete);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkoutSession session,  List<PerformedExercise> exercises,  int currentExerciseIndex,  bool isComplete)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSessionState() when $default != null:
return $default(_that.session,_that.exercises,_that.currentExerciseIndex,_that.isComplete);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutSessionState implements WorkoutSessionState {
  const _WorkoutSessionState({required this.session, required final  List<PerformedExercise> exercises, this.currentExerciseIndex = 0, this.isComplete = false}): _exercises = exercises;
  factory _WorkoutSessionState.fromJson(Map<String, dynamic> json) => _$WorkoutSessionStateFromJson(json);

@override final  WorkoutSession session;
 final  List<PerformedExercise> _exercises;
@override List<PerformedExercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override@JsonKey() final  int currentExerciseIndex;
@override@JsonKey() final  bool isComplete;

/// Create a copy of WorkoutSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSessionStateCopyWith<_WorkoutSessionState> get copyWith => __$WorkoutSessionStateCopyWithImpl<_WorkoutSessionState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSessionStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSessionState&&(identical(other.session, session) || other.session == session)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.currentExerciseIndex, currentExerciseIndex) || other.currentExerciseIndex == currentExerciseIndex)&&(identical(other.isComplete, isComplete) || other.isComplete == isComplete));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,session,const DeepCollectionEquality().hash(_exercises),currentExerciseIndex,isComplete);

@override
String toString() {
  return 'WorkoutSessionState(session: $session, exercises: $exercises, currentExerciseIndex: $currentExerciseIndex, isComplete: $isComplete)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSessionStateCopyWith<$Res> implements $WorkoutSessionStateCopyWith<$Res> {
  factory _$WorkoutSessionStateCopyWith(_WorkoutSessionState value, $Res Function(_WorkoutSessionState) _then) = __$WorkoutSessionStateCopyWithImpl;
@override @useResult
$Res call({
 WorkoutSession session, List<PerformedExercise> exercises, int currentExerciseIndex, bool isComplete
});


@override $WorkoutSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$WorkoutSessionStateCopyWithImpl<$Res>
    implements _$WorkoutSessionStateCopyWith<$Res> {
  __$WorkoutSessionStateCopyWithImpl(this._self, this._then);

  final _WorkoutSessionState _self;
  final $Res Function(_WorkoutSessionState) _then;

/// Create a copy of WorkoutSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? session = null,Object? exercises = null,Object? currentExerciseIndex = null,Object? isComplete = null,}) {
  return _then(_WorkoutSessionState(
session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as WorkoutSession,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<PerformedExercise>,currentExerciseIndex: null == currentExerciseIndex ? _self.currentExerciseIndex : currentExerciseIndex // ignore: cast_nullable_to_non_nullable
as int,isComplete: null == isComplete ? _self.isComplete : isComplete // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of WorkoutSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutSessionCopyWith<$Res> get session {
  
  return $WorkoutSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// @nodoc
mixin _$SplitBuilderState {

 WorkoutGoal get goal; int get frequency; SportsLocation get location; List<int> get selectedDays; Map<String, List<MuscleGroup>> get splits; int get currentWeek; int get mesocycleWeeks; ProgressionType get progressionType; int get deloadFrequency; SplitBuilderStep get currentStep;
/// Create a copy of SplitBuilderState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitBuilderStateCopyWith<SplitBuilderState> get copyWith => _$SplitBuilderStateCopyWithImpl<SplitBuilderState>(this as SplitBuilderState, _$identity);

  /// Serializes this SplitBuilderState to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitBuilderState&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other.selectedDays, selectedDays)&&const DeepCollectionEquality().equals(other.splits, splits)&&(identical(other.currentWeek, currentWeek) || other.currentWeek == currentWeek)&&(identical(other.mesocycleWeeks, mesocycleWeeks) || other.mesocycleWeeks == mesocycleWeeks)&&(identical(other.progressionType, progressionType) || other.progressionType == progressionType)&&(identical(other.deloadFrequency, deloadFrequency) || other.deloadFrequency == deloadFrequency)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,goal,frequency,location,const DeepCollectionEquality().hash(selectedDays),const DeepCollectionEquality().hash(splits),currentWeek,mesocycleWeeks,progressionType,deloadFrequency,currentStep);

@override
String toString() {
  return 'SplitBuilderState(goal: $goal, frequency: $frequency, location: $location, selectedDays: $selectedDays, splits: $splits, currentWeek: $currentWeek, mesocycleWeeks: $mesocycleWeeks, progressionType: $progressionType, deloadFrequency: $deloadFrequency, currentStep: $currentStep)';
}


}

/// @nodoc
abstract mixin class $SplitBuilderStateCopyWith<$Res>  {
  factory $SplitBuilderStateCopyWith(SplitBuilderState value, $Res Function(SplitBuilderState) _then) = _$SplitBuilderStateCopyWithImpl;
@useResult
$Res call({
 WorkoutGoal goal, int frequency, SportsLocation location, List<int> selectedDays, Map<String, List<MuscleGroup>> splits, int currentWeek, int mesocycleWeeks, ProgressionType progressionType, int deloadFrequency, SplitBuilderStep currentStep
});




}
/// @nodoc
class _$SplitBuilderStateCopyWithImpl<$Res>
    implements $SplitBuilderStateCopyWith<$Res> {
  _$SplitBuilderStateCopyWithImpl(this._self, this._then);

  final SplitBuilderState _self;
  final $Res Function(SplitBuilderState) _then;

/// Create a copy of SplitBuilderState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? goal = null,Object? frequency = null,Object? location = null,Object? selectedDays = null,Object? splits = null,Object? currentWeek = null,Object? mesocycleWeeks = null,Object? progressionType = null,Object? deloadFrequency = null,Object? currentStep = null,}) {
  return _then(_self.copyWith(
goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as WorkoutGoal,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as int,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as SportsLocation,selectedDays: null == selectedDays ? _self.selectedDays : selectedDays // ignore: cast_nullable_to_non_nullable
as List<int>,splits: null == splits ? _self.splits : splits // ignore: cast_nullable_to_non_nullable
as Map<String, List<MuscleGroup>>,currentWeek: null == currentWeek ? _self.currentWeek : currentWeek // ignore: cast_nullable_to_non_nullable
as int,mesocycleWeeks: null == mesocycleWeeks ? _self.mesocycleWeeks : mesocycleWeeks // ignore: cast_nullable_to_non_nullable
as int,progressionType: null == progressionType ? _self.progressionType : progressionType // ignore: cast_nullable_to_non_nullable
as ProgressionType,deloadFrequency: null == deloadFrequency ? _self.deloadFrequency : deloadFrequency // ignore: cast_nullable_to_non_nullable
as int,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as SplitBuilderStep,
  ));
}

}


/// Adds pattern-matching-related methods to [SplitBuilderState].
extension SplitBuilderStatePatterns on SplitBuilderState {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SplitBuilderState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SplitBuilderState() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SplitBuilderState value)  $default,){
final _that = this;
switch (_that) {
case _SplitBuilderState():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SplitBuilderState value)?  $default,){
final _that = this;
switch (_that) {
case _SplitBuilderState() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkoutGoal goal,  int frequency,  SportsLocation location,  List<int> selectedDays,  Map<String, List<MuscleGroup>> splits,  int currentWeek,  int mesocycleWeeks,  ProgressionType progressionType,  int deloadFrequency,  SplitBuilderStep currentStep)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SplitBuilderState() when $default != null:
return $default(_that.goal,_that.frequency,_that.location,_that.selectedDays,_that.splits,_that.currentWeek,_that.mesocycleWeeks,_that.progressionType,_that.deloadFrequency,_that.currentStep);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkoutGoal goal,  int frequency,  SportsLocation location,  List<int> selectedDays,  Map<String, List<MuscleGroup>> splits,  int currentWeek,  int mesocycleWeeks,  ProgressionType progressionType,  int deloadFrequency,  SplitBuilderStep currentStep)  $default,) {final _that = this;
switch (_that) {
case _SplitBuilderState():
return $default(_that.goal,_that.frequency,_that.location,_that.selectedDays,_that.splits,_that.currentWeek,_that.mesocycleWeeks,_that.progressionType,_that.deloadFrequency,_that.currentStep);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkoutGoal goal,  int frequency,  SportsLocation location,  List<int> selectedDays,  Map<String, List<MuscleGroup>> splits,  int currentWeek,  int mesocycleWeeks,  ProgressionType progressionType,  int deloadFrequency,  SplitBuilderStep currentStep)?  $default,) {final _that = this;
switch (_that) {
case _SplitBuilderState() when $default != null:
return $default(_that.goal,_that.frequency,_that.location,_that.selectedDays,_that.splits,_that.currentWeek,_that.mesocycleWeeks,_that.progressionType,_that.deloadFrequency,_that.currentStep);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SplitBuilderState implements SplitBuilderState {
  const _SplitBuilderState({required this.goal, required this.frequency, required this.location, required final  List<int> selectedDays, required final  Map<String, List<MuscleGroup>> splits, required this.currentWeek, required this.mesocycleWeeks, required this.progressionType, required this.deloadFrequency, this.currentStep = SplitBuilderStep.goal}): _selectedDays = selectedDays,_splits = splits;
  factory _SplitBuilderState.fromJson(Map<String, dynamic> json) => _$SplitBuilderStateFromJson(json);

@override final  WorkoutGoal goal;
@override final  int frequency;
@override final  SportsLocation location;
 final  List<int> _selectedDays;
@override List<int> get selectedDays {
  if (_selectedDays is EqualUnmodifiableListView) return _selectedDays;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_selectedDays);
}

 final  Map<String, List<MuscleGroup>> _splits;
@override Map<String, List<MuscleGroup>> get splits {
  if (_splits is EqualUnmodifiableMapView) return _splits;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_splits);
}

@override final  int currentWeek;
@override final  int mesocycleWeeks;
@override final  ProgressionType progressionType;
@override final  int deloadFrequency;
@override@JsonKey() final  SplitBuilderStep currentStep;

/// Create a copy of SplitBuilderState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitBuilderStateCopyWith<_SplitBuilderState> get copyWith => __$SplitBuilderStateCopyWithImpl<_SplitBuilderState>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitBuilderStateToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SplitBuilderState&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.location, location) || other.location == location)&&const DeepCollectionEquality().equals(other._selectedDays, _selectedDays)&&const DeepCollectionEquality().equals(other._splits, _splits)&&(identical(other.currentWeek, currentWeek) || other.currentWeek == currentWeek)&&(identical(other.mesocycleWeeks, mesocycleWeeks) || other.mesocycleWeeks == mesocycleWeeks)&&(identical(other.progressionType, progressionType) || other.progressionType == progressionType)&&(identical(other.deloadFrequency, deloadFrequency) || other.deloadFrequency == deloadFrequency)&&(identical(other.currentStep, currentStep) || other.currentStep == currentStep));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,goal,frequency,location,const DeepCollectionEquality().hash(_selectedDays),const DeepCollectionEquality().hash(_splits),currentWeek,mesocycleWeeks,progressionType,deloadFrequency,currentStep);

@override
String toString() {
  return 'SplitBuilderState(goal: $goal, frequency: $frequency, location: $location, selectedDays: $selectedDays, splits: $splits, currentWeek: $currentWeek, mesocycleWeeks: $mesocycleWeeks, progressionType: $progressionType, deloadFrequency: $deloadFrequency, currentStep: $currentStep)';
}


}

/// @nodoc
abstract mixin class _$SplitBuilderStateCopyWith<$Res> implements $SplitBuilderStateCopyWith<$Res> {
  factory _$SplitBuilderStateCopyWith(_SplitBuilderState value, $Res Function(_SplitBuilderState) _then) = __$SplitBuilderStateCopyWithImpl;
@override @useResult
$Res call({
 WorkoutGoal goal, int frequency, SportsLocation location, List<int> selectedDays, Map<String, List<MuscleGroup>> splits, int currentWeek, int mesocycleWeeks, ProgressionType progressionType, int deloadFrequency, SplitBuilderStep currentStep
});




}
/// @nodoc
class __$SplitBuilderStateCopyWithImpl<$Res>
    implements _$SplitBuilderStateCopyWith<$Res> {
  __$SplitBuilderStateCopyWithImpl(this._self, this._then);

  final _SplitBuilderState _self;
  final $Res Function(_SplitBuilderState) _then;

/// Create a copy of SplitBuilderState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? goal = null,Object? frequency = null,Object? location = null,Object? selectedDays = null,Object? splits = null,Object? currentWeek = null,Object? mesocycleWeeks = null,Object? progressionType = null,Object? deloadFrequency = null,Object? currentStep = null,}) {
  return _then(_SplitBuilderState(
goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as WorkoutGoal,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as int,location: null == location ? _self.location : location // ignore: cast_nullable_to_non_nullable
as SportsLocation,selectedDays: null == selectedDays ? _self._selectedDays : selectedDays // ignore: cast_nullable_to_non_nullable
as List<int>,splits: null == splits ? _self._splits : splits // ignore: cast_nullable_to_non_nullable
as Map<String, List<MuscleGroup>>,currentWeek: null == currentWeek ? _self.currentWeek : currentWeek // ignore: cast_nullable_to_non_nullable
as int,mesocycleWeeks: null == mesocycleWeeks ? _self.mesocycleWeeks : mesocycleWeeks // ignore: cast_nullable_to_non_nullable
as int,progressionType: null == progressionType ? _self.progressionType : progressionType // ignore: cast_nullable_to_non_nullable
as ProgressionType,deloadFrequency: null == deloadFrequency ? _self.deloadFrequency : deloadFrequency // ignore: cast_nullable_to_non_nullable
as int,currentStep: null == currentStep ? _self.currentStep : currentStep // ignore: cast_nullable_to_non_nullable
as SplitBuilderStep,
  ));
}


}

// dart format on
