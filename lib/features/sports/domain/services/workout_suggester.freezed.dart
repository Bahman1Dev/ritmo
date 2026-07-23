// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'workout_suggester.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TodayWorkoutPlan {

 WorkoutSplitDay get splitDay; List<SplitExercise> get exercises; WorkoutTier get suggestedTier; String get tierReason; bool get isRestDay; bool get hasNoPlan;
/// Create a copy of TodayWorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TodayWorkoutPlanCopyWith<TodayWorkoutPlan> get copyWith => _$TodayWorkoutPlanCopyWithImpl<TodayWorkoutPlan>(this as TodayWorkoutPlan, _$identity);

  /// Serializes this TodayWorkoutPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TodayWorkoutPlan&&(identical(other.splitDay, splitDay) || other.splitDay == splitDay)&&const DeepCollectionEquality().equals(other.exercises, exercises)&&(identical(other.suggestedTier, suggestedTier) || other.suggestedTier == suggestedTier)&&(identical(other.tierReason, tierReason) || other.tierReason == tierReason)&&(identical(other.isRestDay, isRestDay) || other.isRestDay == isRestDay)&&(identical(other.hasNoPlan, hasNoPlan) || other.hasNoPlan == hasNoPlan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,splitDay,const DeepCollectionEquality().hash(exercises),suggestedTier,tierReason,isRestDay,hasNoPlan);

@override
String toString() {
  return 'TodayWorkoutPlan(splitDay: $splitDay, exercises: $exercises, suggestedTier: $suggestedTier, tierReason: $tierReason, isRestDay: $isRestDay, hasNoPlan: $hasNoPlan)';
}


}

/// @nodoc
abstract mixin class $TodayWorkoutPlanCopyWith<$Res>  {
  factory $TodayWorkoutPlanCopyWith(TodayWorkoutPlan value, $Res Function(TodayWorkoutPlan) _then) = _$TodayWorkoutPlanCopyWithImpl;
@useResult
$Res call({
 WorkoutSplitDay splitDay, List<SplitExercise> exercises, WorkoutTier suggestedTier, String tierReason, bool isRestDay, bool hasNoPlan
});


$WorkoutSplitDayCopyWith<$Res> get splitDay;

}
/// @nodoc
class _$TodayWorkoutPlanCopyWithImpl<$Res>
    implements $TodayWorkoutPlanCopyWith<$Res> {
  _$TodayWorkoutPlanCopyWithImpl(this._self, this._then);

  final TodayWorkoutPlan _self;
  final $Res Function(TodayWorkoutPlan) _then;

/// Create a copy of TodayWorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? splitDay = null,Object? exercises = null,Object? suggestedTier = null,Object? tierReason = null,Object? isRestDay = null,Object? hasNoPlan = null,}) {
  return _then(_self.copyWith(
splitDay: null == splitDay ? _self.splitDay : splitDay // ignore: cast_nullable_to_non_nullable
as WorkoutSplitDay,exercises: null == exercises ? _self.exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<SplitExercise>,suggestedTier: null == suggestedTier ? _self.suggestedTier : suggestedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,tierReason: null == tierReason ? _self.tierReason : tierReason // ignore: cast_nullable_to_non_nullable
as String,isRestDay: null == isRestDay ? _self.isRestDay : isRestDay // ignore: cast_nullable_to_non_nullable
as bool,hasNoPlan: null == hasNoPlan ? _self.hasNoPlan : hasNoPlan // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of TodayWorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutSplitDayCopyWith<$Res> get splitDay {
  
  return $WorkoutSplitDayCopyWith<$Res>(_self.splitDay, (value) {
    return _then(_self.copyWith(splitDay: value));
  });
}
}


/// Adds pattern-matching-related methods to [TodayWorkoutPlan].
extension TodayWorkoutPlanPatterns on TodayWorkoutPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TodayWorkoutPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TodayWorkoutPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TodayWorkoutPlan value)  $default,){
final _that = this;
switch (_that) {
case _TodayWorkoutPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TodayWorkoutPlan value)?  $default,){
final _that = this;
switch (_that) {
case _TodayWorkoutPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( WorkoutSplitDay splitDay,  List<SplitExercise> exercises,  WorkoutTier suggestedTier,  String tierReason,  bool isRestDay,  bool hasNoPlan)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TodayWorkoutPlan() when $default != null:
return $default(_that.splitDay,_that.exercises,_that.suggestedTier,_that.tierReason,_that.isRestDay,_that.hasNoPlan);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( WorkoutSplitDay splitDay,  List<SplitExercise> exercises,  WorkoutTier suggestedTier,  String tierReason,  bool isRestDay,  bool hasNoPlan)  $default,) {final _that = this;
switch (_that) {
case _TodayWorkoutPlan():
return $default(_that.splitDay,_that.exercises,_that.suggestedTier,_that.tierReason,_that.isRestDay,_that.hasNoPlan);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( WorkoutSplitDay splitDay,  List<SplitExercise> exercises,  WorkoutTier suggestedTier,  String tierReason,  bool isRestDay,  bool hasNoPlan)?  $default,) {final _that = this;
switch (_that) {
case _TodayWorkoutPlan() when $default != null:
return $default(_that.splitDay,_that.exercises,_that.suggestedTier,_that.tierReason,_that.isRestDay,_that.hasNoPlan);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _TodayWorkoutPlan implements TodayWorkoutPlan {
  const _TodayWorkoutPlan({required this.splitDay, required final  List<SplitExercise> exercises, required this.suggestedTier, required this.tierReason, required this.isRestDay, required this.hasNoPlan}): _exercises = exercises;
  factory _TodayWorkoutPlan.fromJson(Map<String, dynamic> json) => _$TodayWorkoutPlanFromJson(json);

@override final  WorkoutSplitDay splitDay;
 final  List<SplitExercise> _exercises;
@override List<SplitExercise> get exercises {
  if (_exercises is EqualUnmodifiableListView) return _exercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_exercises);
}

@override final  WorkoutTier suggestedTier;
@override final  String tierReason;
@override final  bool isRestDay;
@override final  bool hasNoPlan;

/// Create a copy of TodayWorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TodayWorkoutPlanCopyWith<_TodayWorkoutPlan> get copyWith => __$TodayWorkoutPlanCopyWithImpl<_TodayWorkoutPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$TodayWorkoutPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TodayWorkoutPlan&&(identical(other.splitDay, splitDay) || other.splitDay == splitDay)&&const DeepCollectionEquality().equals(other._exercises, _exercises)&&(identical(other.suggestedTier, suggestedTier) || other.suggestedTier == suggestedTier)&&(identical(other.tierReason, tierReason) || other.tierReason == tierReason)&&(identical(other.isRestDay, isRestDay) || other.isRestDay == isRestDay)&&(identical(other.hasNoPlan, hasNoPlan) || other.hasNoPlan == hasNoPlan));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,splitDay,const DeepCollectionEquality().hash(_exercises),suggestedTier,tierReason,isRestDay,hasNoPlan);

@override
String toString() {
  return 'TodayWorkoutPlan(splitDay: $splitDay, exercises: $exercises, suggestedTier: $suggestedTier, tierReason: $tierReason, isRestDay: $isRestDay, hasNoPlan: $hasNoPlan)';
}


}

/// @nodoc
abstract mixin class _$TodayWorkoutPlanCopyWith<$Res> implements $TodayWorkoutPlanCopyWith<$Res> {
  factory _$TodayWorkoutPlanCopyWith(_TodayWorkoutPlan value, $Res Function(_TodayWorkoutPlan) _then) = __$TodayWorkoutPlanCopyWithImpl;
@override @useResult
$Res call({
 WorkoutSplitDay splitDay, List<SplitExercise> exercises, WorkoutTier suggestedTier, String tierReason, bool isRestDay, bool hasNoPlan
});


@override $WorkoutSplitDayCopyWith<$Res> get splitDay;

}
/// @nodoc
class __$TodayWorkoutPlanCopyWithImpl<$Res>
    implements _$TodayWorkoutPlanCopyWith<$Res> {
  __$TodayWorkoutPlanCopyWithImpl(this._self, this._then);

  final _TodayWorkoutPlan _self;
  final $Res Function(_TodayWorkoutPlan) _then;

/// Create a copy of TodayWorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? splitDay = null,Object? exercises = null,Object? suggestedTier = null,Object? tierReason = null,Object? isRestDay = null,Object? hasNoPlan = null,}) {
  return _then(_TodayWorkoutPlan(
splitDay: null == splitDay ? _self.splitDay : splitDay // ignore: cast_nullable_to_non_nullable
as WorkoutSplitDay,exercises: null == exercises ? _self._exercises : exercises // ignore: cast_nullable_to_non_nullable
as List<SplitExercise>,suggestedTier: null == suggestedTier ? _self.suggestedTier : suggestedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,tierReason: null == tierReason ? _self.tierReason : tierReason // ignore: cast_nullable_to_non_nullable
as String,isRestDay: null == isRestDay ? _self.isRestDay : isRestDay // ignore: cast_nullable_to_non_nullable
as bool,hasNoPlan: null == hasNoPlan ? _self.hasNoPlan : hasNoPlan // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of TodayWorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$WorkoutSplitDayCopyWith<$Res> get splitDay {
  
  return $WorkoutSplitDayCopyWith<$Res>(_self.splitDay, (value) {
    return _then(_self.copyWith(splitDay: value));
  });
}
}


/// @nodoc
mixin _$ExerciseWithDetails {

 Exercise get exercise; List<SplitExercise> get splitExercises; double? get previousBestWeight; int? get previousBestReps; double? get previousBestVolume;
/// Create a copy of ExerciseWithDetails
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseWithDetailsCopyWith<ExerciseWithDetails> get copyWith => _$ExerciseWithDetailsCopyWithImpl<ExerciseWithDetails>(this as ExerciseWithDetails, _$identity);

  /// Serializes this ExerciseWithDetails to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExerciseWithDetails&&(identical(other.exercise, exercise) || other.exercise == exercise)&&const DeepCollectionEquality().equals(other.splitExercises, splitExercises)&&(identical(other.previousBestWeight, previousBestWeight) || other.previousBestWeight == previousBestWeight)&&(identical(other.previousBestReps, previousBestReps) || other.previousBestReps == previousBestReps)&&(identical(other.previousBestVolume, previousBestVolume) || other.previousBestVolume == previousBestVolume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exercise,const DeepCollectionEquality().hash(splitExercises),previousBestWeight,previousBestReps,previousBestVolume);

@override
String toString() {
  return 'ExerciseWithDetails(exercise: $exercise, splitExercises: $splitExercises, previousBestWeight: $previousBestWeight, previousBestReps: $previousBestReps, previousBestVolume: $previousBestVolume)';
}


}

/// @nodoc
abstract mixin class $ExerciseWithDetailsCopyWith<$Res>  {
  factory $ExerciseWithDetailsCopyWith(ExerciseWithDetails value, $Res Function(ExerciseWithDetails) _then) = _$ExerciseWithDetailsCopyWithImpl;
@useResult
$Res call({
 Exercise exercise, List<SplitExercise> splitExercises, double? previousBestWeight, int? previousBestReps, double? previousBestVolume
});


$ExerciseCopyWith<$Res> get exercise;

}
/// @nodoc
class _$ExerciseWithDetailsCopyWithImpl<$Res>
    implements $ExerciseWithDetailsCopyWith<$Res> {
  _$ExerciseWithDetailsCopyWithImpl(this._self, this._then);

  final ExerciseWithDetails _self;
  final $Res Function(ExerciseWithDetails) _then;

/// Create a copy of ExerciseWithDetails
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exercise = null,Object? splitExercises = null,Object? previousBestWeight = freezed,Object? previousBestReps = freezed,Object? previousBestVolume = freezed,}) {
  return _then(_self.copyWith(
exercise: null == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as Exercise,splitExercises: null == splitExercises ? _self.splitExercises : splitExercises // ignore: cast_nullable_to_non_nullable
as List<SplitExercise>,previousBestWeight: freezed == previousBestWeight ? _self.previousBestWeight : previousBestWeight // ignore: cast_nullable_to_non_nullable
as double?,previousBestReps: freezed == previousBestReps ? _self.previousBestReps : previousBestReps // ignore: cast_nullable_to_non_nullable
as int?,previousBestVolume: freezed == previousBestVolume ? _self.previousBestVolume : previousBestVolume // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}
/// Create a copy of ExerciseWithDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseCopyWith<$Res> get exercise {
  
  return $ExerciseCopyWith<$Res>(_self.exercise, (value) {
    return _then(_self.copyWith(exercise: value));
  });
}
}


/// Adds pattern-matching-related methods to [ExerciseWithDetails].
extension ExerciseWithDetailsPatterns on ExerciseWithDetails {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExerciseWithDetails value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExerciseWithDetails() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExerciseWithDetails value)  $default,){
final _that = this;
switch (_that) {
case _ExerciseWithDetails():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExerciseWithDetails value)?  $default,){
final _that = this;
switch (_that) {
case _ExerciseWithDetails() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Exercise exercise,  List<SplitExercise> splitExercises,  double? previousBestWeight,  int? previousBestReps,  double? previousBestVolume)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExerciseWithDetails() when $default != null:
return $default(_that.exercise,_that.splitExercises,_that.previousBestWeight,_that.previousBestReps,_that.previousBestVolume);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Exercise exercise,  List<SplitExercise> splitExercises,  double? previousBestWeight,  int? previousBestReps,  double? previousBestVolume)  $default,) {final _that = this;
switch (_that) {
case _ExerciseWithDetails():
return $default(_that.exercise,_that.splitExercises,_that.previousBestWeight,_that.previousBestReps,_that.previousBestVolume);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Exercise exercise,  List<SplitExercise> splitExercises,  double? previousBestWeight,  int? previousBestReps,  double? previousBestVolume)?  $default,) {final _that = this;
switch (_that) {
case _ExerciseWithDetails() when $default != null:
return $default(_that.exercise,_that.splitExercises,_that.previousBestWeight,_that.previousBestReps,_that.previousBestVolume);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ExerciseWithDetails implements ExerciseWithDetails {
  const _ExerciseWithDetails({required this.exercise, required final  List<SplitExercise> splitExercises, this.previousBestWeight, this.previousBestReps, this.previousBestVolume}): _splitExercises = splitExercises;
  factory _ExerciseWithDetails.fromJson(Map<String, dynamic> json) => _$ExerciseWithDetailsFromJson(json);

@override final  Exercise exercise;
 final  List<SplitExercise> _splitExercises;
@override List<SplitExercise> get splitExercises {
  if (_splitExercises is EqualUnmodifiableListView) return _splitExercises;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_splitExercises);
}

@override final  double? previousBestWeight;
@override final  int? previousBestReps;
@override final  double? previousBestVolume;

/// Create a copy of ExerciseWithDetails
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseWithDetailsCopyWith<_ExerciseWithDetails> get copyWith => __$ExerciseWithDetailsCopyWithImpl<_ExerciseWithDetails>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseWithDetailsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExerciseWithDetails&&(identical(other.exercise, exercise) || other.exercise == exercise)&&const DeepCollectionEquality().equals(other._splitExercises, _splitExercises)&&(identical(other.previousBestWeight, previousBestWeight) || other.previousBestWeight == previousBestWeight)&&(identical(other.previousBestReps, previousBestReps) || other.previousBestReps == previousBestReps)&&(identical(other.previousBestVolume, previousBestVolume) || other.previousBestVolume == previousBestVolume));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exercise,const DeepCollectionEquality().hash(_splitExercises),previousBestWeight,previousBestReps,previousBestVolume);

@override
String toString() {
  return 'ExerciseWithDetails(exercise: $exercise, splitExercises: $splitExercises, previousBestWeight: $previousBestWeight, previousBestReps: $previousBestReps, previousBestVolume: $previousBestVolume)';
}


}

/// @nodoc
abstract mixin class _$ExerciseWithDetailsCopyWith<$Res> implements $ExerciseWithDetailsCopyWith<$Res> {
  factory _$ExerciseWithDetailsCopyWith(_ExerciseWithDetails value, $Res Function(_ExerciseWithDetails) _then) = __$ExerciseWithDetailsCopyWithImpl;
@override @useResult
$Res call({
 Exercise exercise, List<SplitExercise> splitExercises, double? previousBestWeight, int? previousBestReps, double? previousBestVolume
});


@override $ExerciseCopyWith<$Res> get exercise;

}
/// @nodoc
class __$ExerciseWithDetailsCopyWithImpl<$Res>
    implements _$ExerciseWithDetailsCopyWith<$Res> {
  __$ExerciseWithDetailsCopyWithImpl(this._self, this._then);

  final _ExerciseWithDetails _self;
  final $Res Function(_ExerciseWithDetails) _then;

/// Create a copy of ExerciseWithDetails
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exercise = null,Object? splitExercises = null,Object? previousBestWeight = freezed,Object? previousBestReps = freezed,Object? previousBestVolume = freezed,}) {
  return _then(_ExerciseWithDetails(
exercise: null == exercise ? _self.exercise : exercise // ignore: cast_nullable_to_non_nullable
as Exercise,splitExercises: null == splitExercises ? _self._splitExercises : splitExercises // ignore: cast_nullable_to_non_nullable
as List<SplitExercise>,previousBestWeight: freezed == previousBestWeight ? _self.previousBestWeight : previousBestWeight // ignore: cast_nullable_to_non_nullable
as double?,previousBestReps: freezed == previousBestReps ? _self.previousBestReps : previousBestReps // ignore: cast_nullable_to_non_nullable
as int?,previousBestVolume: freezed == previousBestVolume ? _self.previousBestVolume : previousBestVolume // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

/// Create a copy of ExerciseWithDetails
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$ExerciseCopyWith<$Res> get exercise {
  
  return $ExerciseCopyWith<$Res>(_self.exercise, (value) {
    return _then(_self.copyWith(exercise: value));
  });
}
}

// dart format on
