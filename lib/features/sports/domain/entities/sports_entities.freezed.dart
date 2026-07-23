// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sports_entities.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Exercise {

 String get id; String get name; String get nameFa; MuscleGroup get primaryMuscle; ExerciseCategory get category; DifficultyLevel get difficulty; int get createdAt; int get updatedAt; List<MuscleGroup> get secondaryMuscles; List<Equipment> get equipment; String? get description; String? get videoUrl; String? get imageUrl; List<String> get cues; bool get isCompound; bool get isUserCreated; int get usageCount;
/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExerciseCopyWith<Exercise> get copyWith => _$ExerciseCopyWithImpl<Exercise>(this as Exercise, _$identity);

  /// Serializes this Exercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Exercise&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameFa, nameFa) || other.nameFa == nameFa)&&(identical(other.primaryMuscle, primaryMuscle) || other.primaryMuscle == primaryMuscle)&&(identical(other.category, category) || other.category == category)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other.secondaryMuscles, secondaryMuscles)&&const DeepCollectionEquality().equals(other.equipment, equipment)&&(identical(other.description, description) || other.description == description)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other.cues, cues)&&(identical(other.isCompound, isCompound) || other.isCompound == isCompound)&&(identical(other.isUserCreated, isUserCreated) || other.isUserCreated == isUserCreated)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameFa,primaryMuscle,category,difficulty,createdAt,updatedAt,const DeepCollectionEquality().hash(secondaryMuscles),const DeepCollectionEquality().hash(equipment),description,videoUrl,imageUrl,const DeepCollectionEquality().hash(cues),isCompound,isUserCreated,usageCount);

@override
String toString() {
  return 'Exercise(id: $id, name: $name, nameFa: $nameFa, primaryMuscle: $primaryMuscle, category: $category, difficulty: $difficulty, createdAt: $createdAt, updatedAt: $updatedAt, secondaryMuscles: $secondaryMuscles, equipment: $equipment, description: $description, videoUrl: $videoUrl, imageUrl: $imageUrl, cues: $cues, isCompound: $isCompound, isUserCreated: $isUserCreated, usageCount: $usageCount)';
}


}

/// @nodoc
abstract mixin class $ExerciseCopyWith<$Res>  {
  factory $ExerciseCopyWith(Exercise value, $Res Function(Exercise) _then) = _$ExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String name, String nameFa, MuscleGroup primaryMuscle, ExerciseCategory category, DifficultyLevel difficulty, int createdAt, int updatedAt, List<MuscleGroup> secondaryMuscles, List<Equipment> equipment, String? description, String? videoUrl, String? imageUrl, List<String> cues, bool isCompound, bool isUserCreated, int usageCount
});




}
/// @nodoc
class _$ExerciseCopyWithImpl<$Res>
    implements $ExerciseCopyWith<$Res> {
  _$ExerciseCopyWithImpl(this._self, this._then);

  final Exercise _self;
  final $Res Function(Exercise) _then;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? nameFa = null,Object? primaryMuscle = null,Object? category = null,Object? difficulty = null,Object? createdAt = null,Object? updatedAt = null,Object? secondaryMuscles = null,Object? equipment = null,Object? description = freezed,Object? videoUrl = freezed,Object? imageUrl = freezed,Object? cues = null,Object? isCompound = null,Object? isUserCreated = null,Object? usageCount = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameFa: null == nameFa ? _self.nameFa : nameFa // ignore: cast_nullable_to_non_nullable
as String,primaryMuscle: null == primaryMuscle ? _self.primaryMuscle : primaryMuscle // ignore: cast_nullable_to_non_nullable
as MuscleGroup,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExerciseCategory,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as DifficultyLevel,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,secondaryMuscles: null == secondaryMuscles ? _self.secondaryMuscles : secondaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,equipment: null == equipment ? _self.equipment : equipment // ignore: cast_nullable_to_non_nullable
as List<Equipment>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,cues: null == cues ? _self.cues : cues // ignore: cast_nullable_to_non_nullable
as List<String>,isCompound: null == isCompound ? _self.isCompound : isCompound // ignore: cast_nullable_to_non_nullable
as bool,isUserCreated: null == isUserCreated ? _self.isUserCreated : isUserCreated // ignore: cast_nullable_to_non_nullable
as bool,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [Exercise].
extension ExercisePatterns on Exercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Exercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Exercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Exercise value)  $default,){
final _that = this;
switch (_that) {
case _Exercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Exercise value)?  $default,){
final _that = this;
switch (_that) {
case _Exercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  String nameFa,  MuscleGroup primaryMuscle,  ExerciseCategory category,  DifficultyLevel difficulty,  int createdAt,  int updatedAt,  List<MuscleGroup> secondaryMuscles,  List<Equipment> equipment,  String? description,  String? videoUrl,  String? imageUrl,  List<String> cues,  bool isCompound,  bool isUserCreated,  int usageCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Exercise() when $default != null:
return $default(_that.id,_that.name,_that.nameFa,_that.primaryMuscle,_that.category,_that.difficulty,_that.createdAt,_that.updatedAt,_that.secondaryMuscles,_that.equipment,_that.description,_that.videoUrl,_that.imageUrl,_that.cues,_that.isCompound,_that.isUserCreated,_that.usageCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  String nameFa,  MuscleGroup primaryMuscle,  ExerciseCategory category,  DifficultyLevel difficulty,  int createdAt,  int updatedAt,  List<MuscleGroup> secondaryMuscles,  List<Equipment> equipment,  String? description,  String? videoUrl,  String? imageUrl,  List<String> cues,  bool isCompound,  bool isUserCreated,  int usageCount)  $default,) {final _that = this;
switch (_that) {
case _Exercise():
return $default(_that.id,_that.name,_that.nameFa,_that.primaryMuscle,_that.category,_that.difficulty,_that.createdAt,_that.updatedAt,_that.secondaryMuscles,_that.equipment,_that.description,_that.videoUrl,_that.imageUrl,_that.cues,_that.isCompound,_that.isUserCreated,_that.usageCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  String nameFa,  MuscleGroup primaryMuscle,  ExerciseCategory category,  DifficultyLevel difficulty,  int createdAt,  int updatedAt,  List<MuscleGroup> secondaryMuscles,  List<Equipment> equipment,  String? description,  String? videoUrl,  String? imageUrl,  List<String> cues,  bool isCompound,  bool isUserCreated,  int usageCount)?  $default,) {final _that = this;
switch (_that) {
case _Exercise() when $default != null:
return $default(_that.id,_that.name,_that.nameFa,_that.primaryMuscle,_that.category,_that.difficulty,_that.createdAt,_that.updatedAt,_that.secondaryMuscles,_that.equipment,_that.description,_that.videoUrl,_that.imageUrl,_that.cues,_that.isCompound,_that.isUserCreated,_that.usageCount);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Exercise implements Exercise {
  const _Exercise({required this.id, required this.name, required this.nameFa, required this.primaryMuscle, required this.category, required this.difficulty, required this.createdAt, required this.updatedAt, final  List<MuscleGroup> secondaryMuscles = const [], final  List<Equipment> equipment = const [], this.description, this.videoUrl, this.imageUrl, final  List<String> cues = const [], this.isCompound = true, this.isUserCreated = false, this.usageCount = 0}): _secondaryMuscles = secondaryMuscles,_equipment = equipment,_cues = cues;
  factory _Exercise.fromJson(Map<String, dynamic> json) => _$ExerciseFromJson(json);

@override final  String id;
@override final  String name;
@override final  String nameFa;
@override final  MuscleGroup primaryMuscle;
@override final  ExerciseCategory category;
@override final  DifficultyLevel difficulty;
@override final  int createdAt;
@override final  int updatedAt;
 final  List<MuscleGroup> _secondaryMuscles;
@override@JsonKey() List<MuscleGroup> get secondaryMuscles {
  if (_secondaryMuscles is EqualUnmodifiableListView) return _secondaryMuscles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_secondaryMuscles);
}

 final  List<Equipment> _equipment;
@override@JsonKey() List<Equipment> get equipment {
  if (_equipment is EqualUnmodifiableListView) return _equipment;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_equipment);
}

@override final  String? description;
@override final  String? videoUrl;
@override final  String? imageUrl;
 final  List<String> _cues;
@override@JsonKey() List<String> get cues {
  if (_cues is EqualUnmodifiableListView) return _cues;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_cues);
}

@override@JsonKey() final  bool isCompound;
@override@JsonKey() final  bool isUserCreated;
@override@JsonKey() final  int usageCount;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExerciseCopyWith<_Exercise> get copyWith => __$ExerciseCopyWithImpl<_Exercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Exercise&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.nameFa, nameFa) || other.nameFa == nameFa)&&(identical(other.primaryMuscle, primaryMuscle) || other.primaryMuscle == primaryMuscle)&&(identical(other.category, category) || other.category == category)&&(identical(other.difficulty, difficulty) || other.difficulty == difficulty)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&const DeepCollectionEquality().equals(other._secondaryMuscles, _secondaryMuscles)&&const DeepCollectionEquality().equals(other._equipment, _equipment)&&(identical(other.description, description) || other.description == description)&&(identical(other.videoUrl, videoUrl) || other.videoUrl == videoUrl)&&(identical(other.imageUrl, imageUrl) || other.imageUrl == imageUrl)&&const DeepCollectionEquality().equals(other._cues, _cues)&&(identical(other.isCompound, isCompound) || other.isCompound == isCompound)&&(identical(other.isUserCreated, isUserCreated) || other.isUserCreated == isUserCreated)&&(identical(other.usageCount, usageCount) || other.usageCount == usageCount));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,nameFa,primaryMuscle,category,difficulty,createdAt,updatedAt,const DeepCollectionEquality().hash(_secondaryMuscles),const DeepCollectionEquality().hash(_equipment),description,videoUrl,imageUrl,const DeepCollectionEquality().hash(_cues),isCompound,isUserCreated,usageCount);

@override
String toString() {
  return 'Exercise(id: $id, name: $name, nameFa: $nameFa, primaryMuscle: $primaryMuscle, category: $category, difficulty: $difficulty, createdAt: $createdAt, updatedAt: $updatedAt, secondaryMuscles: $secondaryMuscles, equipment: $equipment, description: $description, videoUrl: $videoUrl, imageUrl: $imageUrl, cues: $cues, isCompound: $isCompound, isUserCreated: $isUserCreated, usageCount: $usageCount)';
}


}

/// @nodoc
abstract mixin class _$ExerciseCopyWith<$Res> implements $ExerciseCopyWith<$Res> {
  factory _$ExerciseCopyWith(_Exercise value, $Res Function(_Exercise) _then) = __$ExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, String nameFa, MuscleGroup primaryMuscle, ExerciseCategory category, DifficultyLevel difficulty, int createdAt, int updatedAt, List<MuscleGroup> secondaryMuscles, List<Equipment> equipment, String? description, String? videoUrl, String? imageUrl, List<String> cues, bool isCompound, bool isUserCreated, int usageCount
});




}
/// @nodoc
class __$ExerciseCopyWithImpl<$Res>
    implements _$ExerciseCopyWith<$Res> {
  __$ExerciseCopyWithImpl(this._self, this._then);

  final _Exercise _self;
  final $Res Function(_Exercise) _then;

/// Create a copy of Exercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? nameFa = null,Object? primaryMuscle = null,Object? category = null,Object? difficulty = null,Object? createdAt = null,Object? updatedAt = null,Object? secondaryMuscles = null,Object? equipment = null,Object? description = freezed,Object? videoUrl = freezed,Object? imageUrl = freezed,Object? cues = null,Object? isCompound = null,Object? isUserCreated = null,Object? usageCount = null,}) {
  return _then(_Exercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,nameFa: null == nameFa ? _self.nameFa : nameFa // ignore: cast_nullable_to_non_nullable
as String,primaryMuscle: null == primaryMuscle ? _self.primaryMuscle : primaryMuscle // ignore: cast_nullable_to_non_nullable
as MuscleGroup,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as ExerciseCategory,difficulty: null == difficulty ? _self.difficulty : difficulty // ignore: cast_nullable_to_non_nullable
as DifficultyLevel,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,secondaryMuscles: null == secondaryMuscles ? _self._secondaryMuscles : secondaryMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,equipment: null == equipment ? _self._equipment : equipment // ignore: cast_nullable_to_non_nullable
as List<Equipment>,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,videoUrl: freezed == videoUrl ? _self.videoUrl : videoUrl // ignore: cast_nullable_to_non_nullable
as String?,imageUrl: freezed == imageUrl ? _self.imageUrl : imageUrl // ignore: cast_nullable_to_non_nullable
as String?,cues: null == cues ? _self._cues : cues // ignore: cast_nullable_to_non_nullable
as List<String>,isCompound: null == isCompound ? _self.isCompound : isCompound // ignore: cast_nullable_to_non_nullable
as bool,isUserCreated: null == isUserCreated ? _self.isUserCreated : isUserCreated // ignore: cast_nullable_to_non_nullable
as bool,usageCount: null == usageCount ? _self.usageCount : usageCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$WorkoutPlan {

 String get id; String get name; WorkoutGoal get goal; int get frequency; ProgressionType get progressionType; int get createdAt; int get updatedAt;// days per week
 int get mesocycleLengthWeeks; int get currentWeek; int get deloadFrequencyWeeks; bool get isActive;
/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutPlanCopyWith<WorkoutPlan> get copyWith => _$WorkoutPlanCopyWithImpl<WorkoutPlan>(this as WorkoutPlan, _$identity);

  /// Serializes this WorkoutPlan to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.progressionType, progressionType) || other.progressionType == progressionType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mesocycleLengthWeeks, mesocycleLengthWeeks) || other.mesocycleLengthWeeks == mesocycleLengthWeeks)&&(identical(other.currentWeek, currentWeek) || other.currentWeek == currentWeek)&&(identical(other.deloadFrequencyWeeks, deloadFrequencyWeeks) || other.deloadFrequencyWeeks == deloadFrequencyWeeks)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,goal,frequency,progressionType,createdAt,updatedAt,mesocycleLengthWeeks,currentWeek,deloadFrequencyWeeks,isActive);

@override
String toString() {
  return 'WorkoutPlan(id: $id, name: $name, goal: $goal, frequency: $frequency, progressionType: $progressionType, createdAt: $createdAt, updatedAt: $updatedAt, mesocycleLengthWeeks: $mesocycleLengthWeeks, currentWeek: $currentWeek, deloadFrequencyWeeks: $deloadFrequencyWeeks, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class $WorkoutPlanCopyWith<$Res>  {
  factory $WorkoutPlanCopyWith(WorkoutPlan value, $Res Function(WorkoutPlan) _then) = _$WorkoutPlanCopyWithImpl;
@useResult
$Res call({
 String id, String name, WorkoutGoal goal, int frequency, ProgressionType progressionType, int createdAt, int updatedAt, int mesocycleLengthWeeks, int currentWeek, int deloadFrequencyWeeks, bool isActive
});




}
/// @nodoc
class _$WorkoutPlanCopyWithImpl<$Res>
    implements $WorkoutPlanCopyWith<$Res> {
  _$WorkoutPlanCopyWithImpl(this._self, this._then);

  final WorkoutPlan _self;
  final $Res Function(WorkoutPlan) _then;

/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,Object? goal = null,Object? frequency = null,Object? progressionType = null,Object? createdAt = null,Object? updatedAt = null,Object? mesocycleLengthWeeks = null,Object? currentWeek = null,Object? deloadFrequencyWeeks = null,Object? isActive = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as WorkoutGoal,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as int,progressionType: null == progressionType ? _self.progressionType : progressionType // ignore: cast_nullable_to_non_nullable
as ProgressionType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,mesocycleLengthWeeks: null == mesocycleLengthWeeks ? _self.mesocycleLengthWeeks : mesocycleLengthWeeks // ignore: cast_nullable_to_non_nullable
as int,currentWeek: null == currentWeek ? _self.currentWeek : currentWeek // ignore: cast_nullable_to_non_nullable
as int,deloadFrequencyWeeks: null == deloadFrequencyWeeks ? _self.deloadFrequencyWeeks : deloadFrequencyWeeks // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutPlan].
extension WorkoutPlanPatterns on WorkoutPlan {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutPlan value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutPlan value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutPlan():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutPlan value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String name,  WorkoutGoal goal,  int frequency,  ProgressionType progressionType,  int createdAt,  int updatedAt,  int mesocycleLengthWeeks,  int currentWeek,  int deloadFrequencyWeeks,  bool isActive)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
return $default(_that.id,_that.name,_that.goal,_that.frequency,_that.progressionType,_that.createdAt,_that.updatedAt,_that.mesocycleLengthWeeks,_that.currentWeek,_that.deloadFrequencyWeeks,_that.isActive);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String name,  WorkoutGoal goal,  int frequency,  ProgressionType progressionType,  int createdAt,  int updatedAt,  int mesocycleLengthWeeks,  int currentWeek,  int deloadFrequencyWeeks,  bool isActive)  $default,) {final _that = this;
switch (_that) {
case _WorkoutPlan():
return $default(_that.id,_that.name,_that.goal,_that.frequency,_that.progressionType,_that.createdAt,_that.updatedAt,_that.mesocycleLengthWeeks,_that.currentWeek,_that.deloadFrequencyWeeks,_that.isActive);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String name,  WorkoutGoal goal,  int frequency,  ProgressionType progressionType,  int createdAt,  int updatedAt,  int mesocycleLengthWeeks,  int currentWeek,  int deloadFrequencyWeeks,  bool isActive)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutPlan() when $default != null:
return $default(_that.id,_that.name,_that.goal,_that.frequency,_that.progressionType,_that.createdAt,_that.updatedAt,_that.mesocycleLengthWeeks,_that.currentWeek,_that.deloadFrequencyWeeks,_that.isActive);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutPlan implements WorkoutPlan {
  const _WorkoutPlan({required this.id, required this.name, required this.goal, required this.frequency, required this.progressionType, required this.createdAt, required this.updatedAt, this.mesocycleLengthWeeks = 6, this.currentWeek = 1, this.deloadFrequencyWeeks = 4, this.isActive = true});
  factory _WorkoutPlan.fromJson(Map<String, dynamic> json) => _$WorkoutPlanFromJson(json);

@override final  String id;
@override final  String name;
@override final  WorkoutGoal goal;
@override final  int frequency;
@override final  ProgressionType progressionType;
@override final  int createdAt;
@override final  int updatedAt;
// days per week
@override@JsonKey() final  int mesocycleLengthWeeks;
@override@JsonKey() final  int currentWeek;
@override@JsonKey() final  int deloadFrequencyWeeks;
@override@JsonKey() final  bool isActive;

/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutPlanCopyWith<_WorkoutPlan> get copyWith => __$WorkoutPlanCopyWithImpl<_WorkoutPlan>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutPlanToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutPlan&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name)&&(identical(other.goal, goal) || other.goal == goal)&&(identical(other.frequency, frequency) || other.frequency == frequency)&&(identical(other.progressionType, progressionType) || other.progressionType == progressionType)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.mesocycleLengthWeeks, mesocycleLengthWeeks) || other.mesocycleLengthWeeks == mesocycleLengthWeeks)&&(identical(other.currentWeek, currentWeek) || other.currentWeek == currentWeek)&&(identical(other.deloadFrequencyWeeks, deloadFrequencyWeeks) || other.deloadFrequencyWeeks == deloadFrequencyWeeks)&&(identical(other.isActive, isActive) || other.isActive == isActive));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name,goal,frequency,progressionType,createdAt,updatedAt,mesocycleLengthWeeks,currentWeek,deloadFrequencyWeeks,isActive);

@override
String toString() {
  return 'WorkoutPlan(id: $id, name: $name, goal: $goal, frequency: $frequency, progressionType: $progressionType, createdAt: $createdAt, updatedAt: $updatedAt, mesocycleLengthWeeks: $mesocycleLengthWeeks, currentWeek: $currentWeek, deloadFrequencyWeeks: $deloadFrequencyWeeks, isActive: $isActive)';
}


}

/// @nodoc
abstract mixin class _$WorkoutPlanCopyWith<$Res> implements $WorkoutPlanCopyWith<$Res> {
  factory _$WorkoutPlanCopyWith(_WorkoutPlan value, $Res Function(_WorkoutPlan) _then) = __$WorkoutPlanCopyWithImpl;
@override @useResult
$Res call({
 String id, String name, WorkoutGoal goal, int frequency, ProgressionType progressionType, int createdAt, int updatedAt, int mesocycleLengthWeeks, int currentWeek, int deloadFrequencyWeeks, bool isActive
});




}
/// @nodoc
class __$WorkoutPlanCopyWithImpl<$Res>
    implements _$WorkoutPlanCopyWith<$Res> {
  __$WorkoutPlanCopyWithImpl(this._self, this._then);

  final _WorkoutPlan _self;
  final $Res Function(_WorkoutPlan) _then;

/// Create a copy of WorkoutPlan
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,Object? goal = null,Object? frequency = null,Object? progressionType = null,Object? createdAt = null,Object? updatedAt = null,Object? mesocycleLengthWeeks = null,Object? currentWeek = null,Object? deloadFrequencyWeeks = null,Object? isActive = null,}) {
  return _then(_WorkoutPlan(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,goal: null == goal ? _self.goal : goal // ignore: cast_nullable_to_non_nullable
as WorkoutGoal,frequency: null == frequency ? _self.frequency : frequency // ignore: cast_nullable_to_non_nullable
as int,progressionType: null == progressionType ? _self.progressionType : progressionType // ignore: cast_nullable_to_non_nullable
as ProgressionType,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,mesocycleLengthWeeks: null == mesocycleLengthWeeks ? _self.mesocycleLengthWeeks : mesocycleLengthWeeks // ignore: cast_nullable_to_non_nullable
as int,currentWeek: null == currentWeek ? _self.currentWeek : currentWeek // ignore: cast_nullable_to_non_nullable
as int,deloadFrequencyWeeks: null == deloadFrequencyWeeks ? _self.deloadFrequencyWeeks : deloadFrequencyWeeks // ignore: cast_nullable_to_non_nullable
as int,isActive: null == isActive ? _self.isActive : isActive // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$WorkoutSplitDay {

 String get id; String get splitId; int get weekday; int get createdAt; int get updatedAt;// 1=Mon .. 7=Sun
 int get weekInMesocycle; String? get dayName;// "Upper A", "Lower B"
 bool get isRest; List<MuscleGroup> get targetMuscles; String? get notes;
/// Create a copy of WorkoutSplitDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSplitDayCopyWith<WorkoutSplitDay> get copyWith => _$WorkoutSplitDayCopyWithImpl<WorkoutSplitDay>(this as WorkoutSplitDay, _$identity);

  /// Serializes this WorkoutSplitDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSplitDay&&(identical(other.id, id) || other.id == id)&&(identical(other.splitId, splitId) || other.splitId == splitId)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.weekInMesocycle, weekInMesocycle) || other.weekInMesocycle == weekInMesocycle)&&(identical(other.dayName, dayName) || other.dayName == dayName)&&(identical(other.isRest, isRest) || other.isRest == isRest)&&const DeepCollectionEquality().equals(other.targetMuscles, targetMuscles)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,splitId,weekday,createdAt,updatedAt,weekInMesocycle,dayName,isRest,const DeepCollectionEquality().hash(targetMuscles),notes);

@override
String toString() {
  return 'WorkoutSplitDay(id: $id, splitId: $splitId, weekday: $weekday, createdAt: $createdAt, updatedAt: $updatedAt, weekInMesocycle: $weekInMesocycle, dayName: $dayName, isRest: $isRest, targetMuscles: $targetMuscles, notes: $notes)';
}


}

/// @nodoc
abstract mixin class $WorkoutSplitDayCopyWith<$Res>  {
  factory $WorkoutSplitDayCopyWith(WorkoutSplitDay value, $Res Function(WorkoutSplitDay) _then) = _$WorkoutSplitDayCopyWithImpl;
@useResult
$Res call({
 String id, String splitId, int weekday, int createdAt, int updatedAt, int weekInMesocycle, String? dayName, bool isRest, List<MuscleGroup> targetMuscles, String? notes
});




}
/// @nodoc
class _$WorkoutSplitDayCopyWithImpl<$Res>
    implements $WorkoutSplitDayCopyWith<$Res> {
  _$WorkoutSplitDayCopyWithImpl(this._self, this._then);

  final WorkoutSplitDay _self;
  final $Res Function(WorkoutSplitDay) _then;

/// Create a copy of WorkoutSplitDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? splitId = null,Object? weekday = null,Object? createdAt = null,Object? updatedAt = null,Object? weekInMesocycle = null,Object? dayName = freezed,Object? isRest = null,Object? targetMuscles = null,Object? notes = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,splitId: null == splitId ? _self.splitId : splitId // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,weekInMesocycle: null == weekInMesocycle ? _self.weekInMesocycle : weekInMesocycle // ignore: cast_nullable_to_non_nullable
as int,dayName: freezed == dayName ? _self.dayName : dayName // ignore: cast_nullable_to_non_nullable
as String?,isRest: null == isRest ? _self.isRest : isRest // ignore: cast_nullable_to_non_nullable
as bool,targetMuscles: null == targetMuscles ? _self.targetMuscles : targetMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSplitDay].
extension WorkoutSplitDayPatterns on WorkoutSplitDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSplitDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSplitDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSplitDay value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSplitDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSplitDay value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSplitDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String splitId,  int weekday,  int createdAt,  int updatedAt,  int weekInMesocycle,  String? dayName,  bool isRest,  List<MuscleGroup> targetMuscles,  String? notes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSplitDay() when $default != null:
return $default(_that.id,_that.splitId,_that.weekday,_that.createdAt,_that.updatedAt,_that.weekInMesocycle,_that.dayName,_that.isRest,_that.targetMuscles,_that.notes);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String splitId,  int weekday,  int createdAt,  int updatedAt,  int weekInMesocycle,  String? dayName,  bool isRest,  List<MuscleGroup> targetMuscles,  String? notes)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSplitDay():
return $default(_that.id,_that.splitId,_that.weekday,_that.createdAt,_that.updatedAt,_that.weekInMesocycle,_that.dayName,_that.isRest,_that.targetMuscles,_that.notes);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String splitId,  int weekday,  int createdAt,  int updatedAt,  int weekInMesocycle,  String? dayName,  bool isRest,  List<MuscleGroup> targetMuscles,  String? notes)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSplitDay() when $default != null:
return $default(_that.id,_that.splitId,_that.weekday,_that.createdAt,_that.updatedAt,_that.weekInMesocycle,_that.dayName,_that.isRest,_that.targetMuscles,_that.notes);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutSplitDay implements WorkoutSplitDay {
  const _WorkoutSplitDay({required this.id, required this.splitId, required this.weekday, required this.createdAt, required this.updatedAt, this.weekInMesocycle = 1, this.dayName, this.isRest = false, final  List<MuscleGroup> targetMuscles = const [], this.notes}): _targetMuscles = targetMuscles;
  factory _WorkoutSplitDay.fromJson(Map<String, dynamic> json) => _$WorkoutSplitDayFromJson(json);

@override final  String id;
@override final  String splitId;
@override final  int weekday;
@override final  int createdAt;
@override final  int updatedAt;
// 1=Mon .. 7=Sun
@override@JsonKey() final  int weekInMesocycle;
@override final  String? dayName;
// "Upper A", "Lower B"
@override@JsonKey() final  bool isRest;
 final  List<MuscleGroup> _targetMuscles;
@override@JsonKey() List<MuscleGroup> get targetMuscles {
  if (_targetMuscles is EqualUnmodifiableListView) return _targetMuscles;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_targetMuscles);
}

@override final  String? notes;

/// Create a copy of WorkoutSplitDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSplitDayCopyWith<_WorkoutSplitDay> get copyWith => __$WorkoutSplitDayCopyWithImpl<_WorkoutSplitDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSplitDayToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSplitDay&&(identical(other.id, id) || other.id == id)&&(identical(other.splitId, splitId) || other.splitId == splitId)&&(identical(other.weekday, weekday) || other.weekday == weekday)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.weekInMesocycle, weekInMesocycle) || other.weekInMesocycle == weekInMesocycle)&&(identical(other.dayName, dayName) || other.dayName == dayName)&&(identical(other.isRest, isRest) || other.isRest == isRest)&&const DeepCollectionEquality().equals(other._targetMuscles, _targetMuscles)&&(identical(other.notes, notes) || other.notes == notes));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,splitId,weekday,createdAt,updatedAt,weekInMesocycle,dayName,isRest,const DeepCollectionEquality().hash(_targetMuscles),notes);

@override
String toString() {
  return 'WorkoutSplitDay(id: $id, splitId: $splitId, weekday: $weekday, createdAt: $createdAt, updatedAt: $updatedAt, weekInMesocycle: $weekInMesocycle, dayName: $dayName, isRest: $isRest, targetMuscles: $targetMuscles, notes: $notes)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSplitDayCopyWith<$Res> implements $WorkoutSplitDayCopyWith<$Res> {
  factory _$WorkoutSplitDayCopyWith(_WorkoutSplitDay value, $Res Function(_WorkoutSplitDay) _then) = __$WorkoutSplitDayCopyWithImpl;
@override @useResult
$Res call({
 String id, String splitId, int weekday, int createdAt, int updatedAt, int weekInMesocycle, String? dayName, bool isRest, List<MuscleGroup> targetMuscles, String? notes
});




}
/// @nodoc
class __$WorkoutSplitDayCopyWithImpl<$Res>
    implements _$WorkoutSplitDayCopyWith<$Res> {
  __$WorkoutSplitDayCopyWithImpl(this._self, this._then);

  final _WorkoutSplitDay _self;
  final $Res Function(_WorkoutSplitDay) _then;

/// Create a copy of WorkoutSplitDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? splitId = null,Object? weekday = null,Object? createdAt = null,Object? updatedAt = null,Object? weekInMesocycle = null,Object? dayName = freezed,Object? isRest = null,Object? targetMuscles = null,Object? notes = freezed,}) {
  return _then(_WorkoutSplitDay(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,splitId: null == splitId ? _self.splitId : splitId // ignore: cast_nullable_to_non_nullable
as String,weekday: null == weekday ? _self.weekday : weekday // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,weekInMesocycle: null == weekInMesocycle ? _self.weekInMesocycle : weekInMesocycle // ignore: cast_nullable_to_non_nullable
as int,dayName: freezed == dayName ? _self.dayName : dayName // ignore: cast_nullable_to_non_nullable
as String?,isRest: null == isRest ? _self.isRest : isRest // ignore: cast_nullable_to_non_nullable
as bool,targetMuscles: null == targetMuscles ? _self._targetMuscles : targetMuscles // ignore: cast_nullable_to_non_nullable
as List<MuscleGroup>,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$SplitExercise {

 String get id; String get splitDayId; String get exerciseId; int get exerciseOrder; int get targetSets; int get targetRepsMin; int get targetRepsMax; int get createdAt; int get updatedAt; double? get targetRpe; int get restSeconds; bool get isSuperset; String? get supersetGroupId; String? get exerciseName;
/// Create a copy of SplitExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplitExerciseCopyWith<SplitExercise> get copyWith => _$SplitExerciseCopyWithImpl<SplitExercise>(this as SplitExercise, _$identity);

  /// Serializes this SplitExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplitExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.splitDayId, splitDayId) || other.splitDayId == splitDayId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseOrder, exerciseOrder) || other.exerciseOrder == exerciseOrder)&&(identical(other.targetSets, targetSets) || other.targetSets == targetSets)&&(identical(other.targetRepsMin, targetRepsMin) || other.targetRepsMin == targetRepsMin)&&(identical(other.targetRepsMax, targetRepsMax) || other.targetRepsMax == targetRepsMax)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.targetRpe, targetRpe) || other.targetRpe == targetRpe)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.isSuperset, isSuperset) || other.isSuperset == isSuperset)&&(identical(other.supersetGroupId, supersetGroupId) || other.supersetGroupId == supersetGroupId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,splitDayId,exerciseId,exerciseOrder,targetSets,targetRepsMin,targetRepsMax,createdAt,updatedAt,targetRpe,restSeconds,isSuperset,supersetGroupId,exerciseName);

@override
String toString() {
  return 'SplitExercise(id: $id, splitDayId: $splitDayId, exerciseId: $exerciseId, exerciseOrder: $exerciseOrder, targetSets: $targetSets, targetRepsMin: $targetRepsMin, targetRepsMax: $targetRepsMax, createdAt: $createdAt, updatedAt: $updatedAt, targetRpe: $targetRpe, restSeconds: $restSeconds, isSuperset: $isSuperset, supersetGroupId: $supersetGroupId, exerciseName: $exerciseName)';
}


}

/// @nodoc
abstract mixin class $SplitExerciseCopyWith<$Res>  {
  factory $SplitExerciseCopyWith(SplitExercise value, $Res Function(SplitExercise) _then) = _$SplitExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String splitDayId, String exerciseId, int exerciseOrder, int targetSets, int targetRepsMin, int targetRepsMax, int createdAt, int updatedAt, double? targetRpe, int restSeconds, bool isSuperset, String? supersetGroupId, String? exerciseName
});




}
/// @nodoc
class _$SplitExerciseCopyWithImpl<$Res>
    implements $SplitExerciseCopyWith<$Res> {
  _$SplitExerciseCopyWithImpl(this._self, this._then);

  final SplitExercise _self;
  final $Res Function(SplitExercise) _then;

/// Create a copy of SplitExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? splitDayId = null,Object? exerciseId = null,Object? exerciseOrder = null,Object? targetSets = null,Object? targetRepsMin = null,Object? targetRepsMax = null,Object? createdAt = null,Object? updatedAt = null,Object? targetRpe = freezed,Object? restSeconds = null,Object? isSuperset = null,Object? supersetGroupId = freezed,Object? exerciseName = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,splitDayId: null == splitDayId ? _self.splitDayId : splitDayId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseOrder: null == exerciseOrder ? _self.exerciseOrder : exerciseOrder // ignore: cast_nullable_to_non_nullable
as int,targetSets: null == targetSets ? _self.targetSets : targetSets // ignore: cast_nullable_to_non_nullable
as int,targetRepsMin: null == targetRepsMin ? _self.targetRepsMin : targetRepsMin // ignore: cast_nullable_to_non_nullable
as int,targetRepsMax: null == targetRepsMax ? _self.targetRepsMax : targetRepsMax // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,targetRpe: freezed == targetRpe ? _self.targetRpe : targetRpe // ignore: cast_nullable_to_non_nullable
as double?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,isSuperset: null == isSuperset ? _self.isSuperset : isSuperset // ignore: cast_nullable_to_non_nullable
as bool,supersetGroupId: freezed == supersetGroupId ? _self.supersetGroupId : supersetGroupId // ignore: cast_nullable_to_non_nullable
as String?,exerciseName: freezed == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [SplitExercise].
extension SplitExercisePatterns on SplitExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SplitExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SplitExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SplitExercise value)  $default,){
final _that = this;
switch (_that) {
case _SplitExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SplitExercise value)?  $default,){
final _that = this;
switch (_that) {
case _SplitExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String splitDayId,  String exerciseId,  int exerciseOrder,  int targetSets,  int targetRepsMin,  int targetRepsMax,  int createdAt,  int updatedAt,  double? targetRpe,  int restSeconds,  bool isSuperset,  String? supersetGroupId,  String? exerciseName)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SplitExercise() when $default != null:
return $default(_that.id,_that.splitDayId,_that.exerciseId,_that.exerciseOrder,_that.targetSets,_that.targetRepsMin,_that.targetRepsMax,_that.createdAt,_that.updatedAt,_that.targetRpe,_that.restSeconds,_that.isSuperset,_that.supersetGroupId,_that.exerciseName);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String splitDayId,  String exerciseId,  int exerciseOrder,  int targetSets,  int targetRepsMin,  int targetRepsMax,  int createdAt,  int updatedAt,  double? targetRpe,  int restSeconds,  bool isSuperset,  String? supersetGroupId,  String? exerciseName)  $default,) {final _that = this;
switch (_that) {
case _SplitExercise():
return $default(_that.id,_that.splitDayId,_that.exerciseId,_that.exerciseOrder,_that.targetSets,_that.targetRepsMin,_that.targetRepsMax,_that.createdAt,_that.updatedAt,_that.targetRpe,_that.restSeconds,_that.isSuperset,_that.supersetGroupId,_that.exerciseName);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String splitDayId,  String exerciseId,  int exerciseOrder,  int targetSets,  int targetRepsMin,  int targetRepsMax,  int createdAt,  int updatedAt,  double? targetRpe,  int restSeconds,  bool isSuperset,  String? supersetGroupId,  String? exerciseName)?  $default,) {final _that = this;
switch (_that) {
case _SplitExercise() when $default != null:
return $default(_that.id,_that.splitDayId,_that.exerciseId,_that.exerciseOrder,_that.targetSets,_that.targetRepsMin,_that.targetRepsMax,_that.createdAt,_that.updatedAt,_that.targetRpe,_that.restSeconds,_that.isSuperset,_that.supersetGroupId,_that.exerciseName);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SplitExercise implements SplitExercise {
  const _SplitExercise({required this.id, required this.splitDayId, required this.exerciseId, required this.exerciseOrder, required this.targetSets, required this.targetRepsMin, required this.targetRepsMax, required this.createdAt, required this.updatedAt, this.targetRpe, this.restSeconds = 120, this.isSuperset = false, this.supersetGroupId, this.exerciseName});
  factory _SplitExercise.fromJson(Map<String, dynamic> json) => _$SplitExerciseFromJson(json);

@override final  String id;
@override final  String splitDayId;
@override final  String exerciseId;
@override final  int exerciseOrder;
@override final  int targetSets;
@override final  int targetRepsMin;
@override final  int targetRepsMax;
@override final  int createdAt;
@override final  int updatedAt;
@override final  double? targetRpe;
@override@JsonKey() final  int restSeconds;
@override@JsonKey() final  bool isSuperset;
@override final  String? supersetGroupId;
@override final  String? exerciseName;

/// Create a copy of SplitExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SplitExerciseCopyWith<_SplitExercise> get copyWith => __$SplitExerciseCopyWithImpl<_SplitExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SplitExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SplitExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.splitDayId, splitDayId) || other.splitDayId == splitDayId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseOrder, exerciseOrder) || other.exerciseOrder == exerciseOrder)&&(identical(other.targetSets, targetSets) || other.targetSets == targetSets)&&(identical(other.targetRepsMin, targetRepsMin) || other.targetRepsMin == targetRepsMin)&&(identical(other.targetRepsMax, targetRepsMax) || other.targetRepsMax == targetRepsMax)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.targetRpe, targetRpe) || other.targetRpe == targetRpe)&&(identical(other.restSeconds, restSeconds) || other.restSeconds == restSeconds)&&(identical(other.isSuperset, isSuperset) || other.isSuperset == isSuperset)&&(identical(other.supersetGroupId, supersetGroupId) || other.supersetGroupId == supersetGroupId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,splitDayId,exerciseId,exerciseOrder,targetSets,targetRepsMin,targetRepsMax,createdAt,updatedAt,targetRpe,restSeconds,isSuperset,supersetGroupId,exerciseName);

@override
String toString() {
  return 'SplitExercise(id: $id, splitDayId: $splitDayId, exerciseId: $exerciseId, exerciseOrder: $exerciseOrder, targetSets: $targetSets, targetRepsMin: $targetRepsMin, targetRepsMax: $targetRepsMax, createdAt: $createdAt, updatedAt: $updatedAt, targetRpe: $targetRpe, restSeconds: $restSeconds, isSuperset: $isSuperset, supersetGroupId: $supersetGroupId, exerciseName: $exerciseName)';
}


}

/// @nodoc
abstract mixin class _$SplitExerciseCopyWith<$Res> implements $SplitExerciseCopyWith<$Res> {
  factory _$SplitExerciseCopyWith(_SplitExercise value, $Res Function(_SplitExercise) _then) = __$SplitExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String splitDayId, String exerciseId, int exerciseOrder, int targetSets, int targetRepsMin, int targetRepsMax, int createdAt, int updatedAt, double? targetRpe, int restSeconds, bool isSuperset, String? supersetGroupId, String? exerciseName
});




}
/// @nodoc
class __$SplitExerciseCopyWithImpl<$Res>
    implements _$SplitExerciseCopyWith<$Res> {
  __$SplitExerciseCopyWithImpl(this._self, this._then);

  final _SplitExercise _self;
  final $Res Function(_SplitExercise) _then;

/// Create a copy of SplitExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? splitDayId = null,Object? exerciseId = null,Object? exerciseOrder = null,Object? targetSets = null,Object? targetRepsMin = null,Object? targetRepsMax = null,Object? createdAt = null,Object? updatedAt = null,Object? targetRpe = freezed,Object? restSeconds = null,Object? isSuperset = null,Object? supersetGroupId = freezed,Object? exerciseName = freezed,}) {
  return _then(_SplitExercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,splitDayId: null == splitDayId ? _self.splitDayId : splitDayId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseOrder: null == exerciseOrder ? _self.exerciseOrder : exerciseOrder // ignore: cast_nullable_to_non_nullable
as int,targetSets: null == targetSets ? _self.targetSets : targetSets // ignore: cast_nullable_to_non_nullable
as int,targetRepsMin: null == targetRepsMin ? _self.targetRepsMin : targetRepsMin // ignore: cast_nullable_to_non_nullable
as int,targetRepsMax: null == targetRepsMax ? _self.targetRepsMax : targetRepsMax // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,targetRpe: freezed == targetRpe ? _self.targetRpe : targetRpe // ignore: cast_nullable_to_non_nullable
as double?,restSeconds: null == restSeconds ? _self.restSeconds : restSeconds // ignore: cast_nullable_to_non_nullable
as int,isSuperset: null == isSuperset ? _self.isSuperset : isSuperset // ignore: cast_nullable_to_non_nullable
as bool,supersetGroupId: freezed == supersetGroupId ? _self.supersetGroupId : supersetGroupId // ignore: cast_nullable_to_non_nullable
as String?,exerciseName: freezed == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}


/// @nodoc
mixin _$WorkoutSession {

 String get id; int get startedAt; WorkoutTier get plannedTier; WorkoutTier get completedTier; int get createdAt; int get updatedAt; int? get completedAt; String? get splitDayId; double get totalVolumeKg; int get totalSets; int get totalReps; int get actualDurationSeconds; double? get sessionRpe;// 1-10
 String? get notes; bool get wasAutoAdjusted;
/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WorkoutSessionCopyWith<WorkoutSession> get copyWith => _$WorkoutSessionCopyWithImpl<WorkoutSession>(this as WorkoutSession, _$identity);

  /// Serializes this WorkoutSession to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WorkoutSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.plannedTier, plannedTier) || other.plannedTier == plannedTier)&&(identical(other.completedTier, completedTier) || other.completedTier == completedTier)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.splitDayId, splitDayId) || other.splitDayId == splitDayId)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalReps, totalReps) || other.totalReps == totalReps)&&(identical(other.actualDurationSeconds, actualDurationSeconds) || other.actualDurationSeconds == actualDurationSeconds)&&(identical(other.sessionRpe, sessionRpe) || other.sessionRpe == sessionRpe)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.wasAutoAdjusted, wasAutoAdjusted) || other.wasAutoAdjusted == wasAutoAdjusted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startedAt,plannedTier,completedTier,createdAt,updatedAt,completedAt,splitDayId,totalVolumeKg,totalSets,totalReps,actualDurationSeconds,sessionRpe,notes,wasAutoAdjusted);

@override
String toString() {
  return 'WorkoutSession(id: $id, startedAt: $startedAt, plannedTier: $plannedTier, completedTier: $completedTier, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt, splitDayId: $splitDayId, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, totalReps: $totalReps, actualDurationSeconds: $actualDurationSeconds, sessionRpe: $sessionRpe, notes: $notes, wasAutoAdjusted: $wasAutoAdjusted)';
}


}

/// @nodoc
abstract mixin class $WorkoutSessionCopyWith<$Res>  {
  factory $WorkoutSessionCopyWith(WorkoutSession value, $Res Function(WorkoutSession) _then) = _$WorkoutSessionCopyWithImpl;
@useResult
$Res call({
 String id, int startedAt, WorkoutTier plannedTier, WorkoutTier completedTier, int createdAt, int updatedAt, int? completedAt, String? splitDayId, double totalVolumeKg, int totalSets, int totalReps, int actualDurationSeconds, double? sessionRpe, String? notes, bool wasAutoAdjusted
});




}
/// @nodoc
class _$WorkoutSessionCopyWithImpl<$Res>
    implements $WorkoutSessionCopyWith<$Res> {
  _$WorkoutSessionCopyWithImpl(this._self, this._then);

  final WorkoutSession _self;
  final $Res Function(WorkoutSession) _then;

/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? plannedTier = null,Object? completedTier = null,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,Object? splitDayId = freezed,Object? totalVolumeKg = null,Object? totalSets = null,Object? totalReps = null,Object? actualDurationSeconds = null,Object? sessionRpe = freezed,Object? notes = freezed,Object? wasAutoAdjusted = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int,plannedTier: null == plannedTier ? _self.plannedTier : plannedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,completedTier: null == completedTier ? _self.completedTier : completedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int?,splitDayId: freezed == splitDayId ? _self.splitDayId : splitDayId // ignore: cast_nullable_to_non_nullable
as String?,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalReps: null == totalReps ? _self.totalReps : totalReps // ignore: cast_nullable_to_non_nullable
as int,actualDurationSeconds: null == actualDurationSeconds ? _self.actualDurationSeconds : actualDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,sessionRpe: freezed == sessionRpe ? _self.sessionRpe : sessionRpe // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,wasAutoAdjusted: null == wasAutoAdjusted ? _self.wasAutoAdjusted : wasAutoAdjusted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WorkoutSession].
extension WorkoutSessionPatterns on WorkoutSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WorkoutSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WorkoutSession value)  $default,){
final _that = this;
switch (_that) {
case _WorkoutSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WorkoutSession value)?  $default,){
final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  int startedAt,  WorkoutTier plannedTier,  WorkoutTier completedTier,  int createdAt,  int updatedAt,  int? completedAt,  String? splitDayId,  double totalVolumeKg,  int totalSets,  int totalReps,  int actualDurationSeconds,  double? sessionRpe,  String? notes,  bool wasAutoAdjusted)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
return $default(_that.id,_that.startedAt,_that.plannedTier,_that.completedTier,_that.createdAt,_that.updatedAt,_that.completedAt,_that.splitDayId,_that.totalVolumeKg,_that.totalSets,_that.totalReps,_that.actualDurationSeconds,_that.sessionRpe,_that.notes,_that.wasAutoAdjusted);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  int startedAt,  WorkoutTier plannedTier,  WorkoutTier completedTier,  int createdAt,  int updatedAt,  int? completedAt,  String? splitDayId,  double totalVolumeKg,  int totalSets,  int totalReps,  int actualDurationSeconds,  double? sessionRpe,  String? notes,  bool wasAutoAdjusted)  $default,) {final _that = this;
switch (_that) {
case _WorkoutSession():
return $default(_that.id,_that.startedAt,_that.plannedTier,_that.completedTier,_that.createdAt,_that.updatedAt,_that.completedAt,_that.splitDayId,_that.totalVolumeKg,_that.totalSets,_that.totalReps,_that.actualDurationSeconds,_that.sessionRpe,_that.notes,_that.wasAutoAdjusted);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  int startedAt,  WorkoutTier plannedTier,  WorkoutTier completedTier,  int createdAt,  int updatedAt,  int? completedAt,  String? splitDayId,  double totalVolumeKg,  int totalSets,  int totalReps,  int actualDurationSeconds,  double? sessionRpe,  String? notes,  bool wasAutoAdjusted)?  $default,) {final _that = this;
switch (_that) {
case _WorkoutSession() when $default != null:
return $default(_that.id,_that.startedAt,_that.plannedTier,_that.completedTier,_that.createdAt,_that.updatedAt,_that.completedAt,_that.splitDayId,_that.totalVolumeKg,_that.totalSets,_that.totalReps,_that.actualDurationSeconds,_that.sessionRpe,_that.notes,_that.wasAutoAdjusted);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WorkoutSession implements WorkoutSession {
  const _WorkoutSession({required this.id, required this.startedAt, required this.plannedTier, required this.completedTier, required this.createdAt, required this.updatedAt, this.completedAt, this.splitDayId, this.totalVolumeKg = 0.0, this.totalSets = 0, this.totalReps = 0, this.actualDurationSeconds = 0, this.sessionRpe, this.notes, this.wasAutoAdjusted = false});
  factory _WorkoutSession.fromJson(Map<String, dynamic> json) => _$WorkoutSessionFromJson(json);

@override final  String id;
@override final  int startedAt;
@override final  WorkoutTier plannedTier;
@override final  WorkoutTier completedTier;
@override final  int createdAt;
@override final  int updatedAt;
@override final  int? completedAt;
@override final  String? splitDayId;
@override@JsonKey() final  double totalVolumeKg;
@override@JsonKey() final  int totalSets;
@override@JsonKey() final  int totalReps;
@override@JsonKey() final  int actualDurationSeconds;
@override final  double? sessionRpe;
// 1-10
@override final  String? notes;
@override@JsonKey() final  bool wasAutoAdjusted;

/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WorkoutSessionCopyWith<_WorkoutSession> get copyWith => __$WorkoutSessionCopyWithImpl<_WorkoutSession>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WorkoutSessionToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WorkoutSession&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.plannedTier, plannedTier) || other.plannedTier == plannedTier)&&(identical(other.completedTier, completedTier) || other.completedTier == completedTier)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.completedAt, completedAt) || other.completedAt == completedAt)&&(identical(other.splitDayId, splitDayId) || other.splitDayId == splitDayId)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalReps, totalReps) || other.totalReps == totalReps)&&(identical(other.actualDurationSeconds, actualDurationSeconds) || other.actualDurationSeconds == actualDurationSeconds)&&(identical(other.sessionRpe, sessionRpe) || other.sessionRpe == sessionRpe)&&(identical(other.notes, notes) || other.notes == notes)&&(identical(other.wasAutoAdjusted, wasAutoAdjusted) || other.wasAutoAdjusted == wasAutoAdjusted));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,startedAt,plannedTier,completedTier,createdAt,updatedAt,completedAt,splitDayId,totalVolumeKg,totalSets,totalReps,actualDurationSeconds,sessionRpe,notes,wasAutoAdjusted);

@override
String toString() {
  return 'WorkoutSession(id: $id, startedAt: $startedAt, plannedTier: $plannedTier, completedTier: $completedTier, createdAt: $createdAt, updatedAt: $updatedAt, completedAt: $completedAt, splitDayId: $splitDayId, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, totalReps: $totalReps, actualDurationSeconds: $actualDurationSeconds, sessionRpe: $sessionRpe, notes: $notes, wasAutoAdjusted: $wasAutoAdjusted)';
}


}

/// @nodoc
abstract mixin class _$WorkoutSessionCopyWith<$Res> implements $WorkoutSessionCopyWith<$Res> {
  factory _$WorkoutSessionCopyWith(_WorkoutSession value, $Res Function(_WorkoutSession) _then) = __$WorkoutSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, int startedAt, WorkoutTier plannedTier, WorkoutTier completedTier, int createdAt, int updatedAt, int? completedAt, String? splitDayId, double totalVolumeKg, int totalSets, int totalReps, int actualDurationSeconds, double? sessionRpe, String? notes, bool wasAutoAdjusted
});




}
/// @nodoc
class __$WorkoutSessionCopyWithImpl<$Res>
    implements _$WorkoutSessionCopyWith<$Res> {
  __$WorkoutSessionCopyWithImpl(this._self, this._then);

  final _WorkoutSession _self;
  final $Res Function(_WorkoutSession) _then;

/// Create a copy of WorkoutSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? plannedTier = null,Object? completedTier = null,Object? createdAt = null,Object? updatedAt = null,Object? completedAt = freezed,Object? splitDayId = freezed,Object? totalVolumeKg = null,Object? totalSets = null,Object? totalReps = null,Object? actualDurationSeconds = null,Object? sessionRpe = freezed,Object? notes = freezed,Object? wasAutoAdjusted = null,}) {
  return _then(_WorkoutSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as int,plannedTier: null == plannedTier ? _self.plannedTier : plannedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,completedTier: null == completedTier ? _self.completedTier : completedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as int,completedAt: freezed == completedAt ? _self.completedAt : completedAt // ignore: cast_nullable_to_non_nullable
as int?,splitDayId: freezed == splitDayId ? _self.splitDayId : splitDayId // ignore: cast_nullable_to_non_nullable
as String?,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalReps: null == totalReps ? _self.totalReps : totalReps // ignore: cast_nullable_to_non_nullable
as int,actualDurationSeconds: null == actualDurationSeconds ? _self.actualDurationSeconds : actualDurationSeconds // ignore: cast_nullable_to_non_nullable
as int,sessionRpe: freezed == sessionRpe ? _self.sessionRpe : sessionRpe // ignore: cast_nullable_to_non_nullable
as double?,notes: freezed == notes ? _self.notes : notes // ignore: cast_nullable_to_non_nullable
as String?,wasAutoAdjusted: null == wasAutoAdjusted ? _self.wasAutoAdjusted : wasAutoAdjusted // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PerformedExercise {

 String get id; String get sessionId; String get exerciseId; String get exerciseName; MuscleGroup get primaryMuscle; int get setOrder; int get createdAt; double get totalVolumeKg; double? get previousBestWeight; int? get previousBestReps; bool get isPr;
/// Create a copy of PerformedExercise
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerformedExerciseCopyWith<PerformedExercise> get copyWith => _$PerformedExerciseCopyWithImpl<PerformedExercise>(this as PerformedExercise, _$identity);

  /// Serializes this PerformedExercise to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerformedExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.primaryMuscle, primaryMuscle) || other.primaryMuscle == primaryMuscle)&&(identical(other.setOrder, setOrder) || other.setOrder == setOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.previousBestWeight, previousBestWeight) || other.previousBestWeight == previousBestWeight)&&(identical(other.previousBestReps, previousBestReps) || other.previousBestReps == previousBestReps)&&(identical(other.isPr, isPr) || other.isPr == isPr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,exerciseId,exerciseName,primaryMuscle,setOrder,createdAt,totalVolumeKg,previousBestWeight,previousBestReps,isPr);

@override
String toString() {
  return 'PerformedExercise(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, exerciseName: $exerciseName, primaryMuscle: $primaryMuscle, setOrder: $setOrder, createdAt: $createdAt, totalVolumeKg: $totalVolumeKg, previousBestWeight: $previousBestWeight, previousBestReps: $previousBestReps, isPr: $isPr)';
}


}

/// @nodoc
abstract mixin class $PerformedExerciseCopyWith<$Res>  {
  factory $PerformedExerciseCopyWith(PerformedExercise value, $Res Function(PerformedExercise) _then) = _$PerformedExerciseCopyWithImpl;
@useResult
$Res call({
 String id, String sessionId, String exerciseId, String exerciseName, MuscleGroup primaryMuscle, int setOrder, int createdAt, double totalVolumeKg, double? previousBestWeight, int? previousBestReps, bool isPr
});




}
/// @nodoc
class _$PerformedExerciseCopyWithImpl<$Res>
    implements $PerformedExerciseCopyWith<$Res> {
  _$PerformedExerciseCopyWithImpl(this._self, this._then);

  final PerformedExercise _self;
  final $Res Function(PerformedExercise) _then;

/// Create a copy of PerformedExercise
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? sessionId = null,Object? exerciseId = null,Object? exerciseName = null,Object? primaryMuscle = null,Object? setOrder = null,Object? createdAt = null,Object? totalVolumeKg = null,Object? previousBestWeight = freezed,Object? previousBestReps = freezed,Object? isPr = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,primaryMuscle: null == primaryMuscle ? _self.primaryMuscle : primaryMuscle // ignore: cast_nullable_to_non_nullable
as MuscleGroup,setOrder: null == setOrder ? _self.setOrder : setOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,previousBestWeight: freezed == previousBestWeight ? _self.previousBestWeight : previousBestWeight // ignore: cast_nullable_to_non_nullable
as double?,previousBestReps: freezed == previousBestReps ? _self.previousBestReps : previousBestReps // ignore: cast_nullable_to_non_nullable
as int?,isPr: null == isPr ? _self.isPr : isPr // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [PerformedExercise].
extension PerformedExercisePatterns on PerformedExercise {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerformedExercise value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformedExercise() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerformedExercise value)  $default,){
final _that = this;
switch (_that) {
case _PerformedExercise():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerformedExercise value)?  $default,){
final _that = this;
switch (_that) {
case _PerformedExercise() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String sessionId,  String exerciseId,  String exerciseName,  MuscleGroup primaryMuscle,  int setOrder,  int createdAt,  double totalVolumeKg,  double? previousBestWeight,  int? previousBestReps,  bool isPr)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformedExercise() when $default != null:
return $default(_that.id,_that.sessionId,_that.exerciseId,_that.exerciseName,_that.primaryMuscle,_that.setOrder,_that.createdAt,_that.totalVolumeKg,_that.previousBestWeight,_that.previousBestReps,_that.isPr);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String sessionId,  String exerciseId,  String exerciseName,  MuscleGroup primaryMuscle,  int setOrder,  int createdAt,  double totalVolumeKg,  double? previousBestWeight,  int? previousBestReps,  bool isPr)  $default,) {final _that = this;
switch (_that) {
case _PerformedExercise():
return $default(_that.id,_that.sessionId,_that.exerciseId,_that.exerciseName,_that.primaryMuscle,_that.setOrder,_that.createdAt,_that.totalVolumeKg,_that.previousBestWeight,_that.previousBestReps,_that.isPr);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String sessionId,  String exerciseId,  String exerciseName,  MuscleGroup primaryMuscle,  int setOrder,  int createdAt,  double totalVolumeKg,  double? previousBestWeight,  int? previousBestReps,  bool isPr)?  $default,) {final _that = this;
switch (_that) {
case _PerformedExercise() when $default != null:
return $default(_that.id,_that.sessionId,_that.exerciseId,_that.exerciseName,_that.primaryMuscle,_that.setOrder,_that.createdAt,_that.totalVolumeKg,_that.previousBestWeight,_that.previousBestReps,_that.isPr);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerformedExercise implements PerformedExercise {
  const _PerformedExercise({required this.id, required this.sessionId, required this.exerciseId, required this.exerciseName, required this.primaryMuscle, required this.setOrder, required this.createdAt, this.totalVolumeKg = 0.0, this.previousBestWeight, this.previousBestReps, this.isPr = false});
  factory _PerformedExercise.fromJson(Map<String, dynamic> json) => _$PerformedExerciseFromJson(json);

@override final  String id;
@override final  String sessionId;
@override final  String exerciseId;
@override final  String exerciseName;
@override final  MuscleGroup primaryMuscle;
@override final  int setOrder;
@override final  int createdAt;
@override@JsonKey() final  double totalVolumeKg;
@override final  double? previousBestWeight;
@override final  int? previousBestReps;
@override@JsonKey() final  bool isPr;

/// Create a copy of PerformedExercise
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformedExerciseCopyWith<_PerformedExercise> get copyWith => __$PerformedExerciseCopyWithImpl<_PerformedExercise>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerformedExerciseToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformedExercise&&(identical(other.id, id) || other.id == id)&&(identical(other.sessionId, sessionId) || other.sessionId == sessionId)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.primaryMuscle, primaryMuscle) || other.primaryMuscle == primaryMuscle)&&(identical(other.setOrder, setOrder) || other.setOrder == setOrder)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.previousBestWeight, previousBestWeight) || other.previousBestWeight == previousBestWeight)&&(identical(other.previousBestReps, previousBestReps) || other.previousBestReps == previousBestReps)&&(identical(other.isPr, isPr) || other.isPr == isPr));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,sessionId,exerciseId,exerciseName,primaryMuscle,setOrder,createdAt,totalVolumeKg,previousBestWeight,previousBestReps,isPr);

@override
String toString() {
  return 'PerformedExercise(id: $id, sessionId: $sessionId, exerciseId: $exerciseId, exerciseName: $exerciseName, primaryMuscle: $primaryMuscle, setOrder: $setOrder, createdAt: $createdAt, totalVolumeKg: $totalVolumeKg, previousBestWeight: $previousBestWeight, previousBestReps: $previousBestReps, isPr: $isPr)';
}


}

/// @nodoc
abstract mixin class _$PerformedExerciseCopyWith<$Res> implements $PerformedExerciseCopyWith<$Res> {
  factory _$PerformedExerciseCopyWith(_PerformedExercise value, $Res Function(_PerformedExercise) _then) = __$PerformedExerciseCopyWithImpl;
@override @useResult
$Res call({
 String id, String sessionId, String exerciseId, String exerciseName, MuscleGroup primaryMuscle, int setOrder, int createdAt, double totalVolumeKg, double? previousBestWeight, int? previousBestReps, bool isPr
});




}
/// @nodoc
class __$PerformedExerciseCopyWithImpl<$Res>
    implements _$PerformedExerciseCopyWith<$Res> {
  __$PerformedExerciseCopyWithImpl(this._self, this._then);

  final _PerformedExercise _self;
  final $Res Function(_PerformedExercise) _then;

/// Create a copy of PerformedExercise
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? sessionId = null,Object? exerciseId = null,Object? exerciseName = null,Object? primaryMuscle = null,Object? setOrder = null,Object? createdAt = null,Object? totalVolumeKg = null,Object? previousBestWeight = freezed,Object? previousBestReps = freezed,Object? isPr = null,}) {
  return _then(_PerformedExercise(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,sessionId: null == sessionId ? _self.sessionId : sessionId // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,primaryMuscle: null == primaryMuscle ? _self.primaryMuscle : primaryMuscle // ignore: cast_nullable_to_non_nullable
as MuscleGroup,setOrder: null == setOrder ? _self.setOrder : setOrder // ignore: cast_nullable_to_non_nullable
as int,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,previousBestWeight: freezed == previousBestWeight ? _self.previousBestWeight : previousBestWeight // ignore: cast_nullable_to_non_nullable
as double?,previousBestReps: freezed == previousBestReps ? _self.previousBestReps : previousBestReps // ignore: cast_nullable_to_non_nullable
as int?,isPr: null == isPr ? _self.isPr : isPr // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}


/// @nodoc
mixin _$PerformedSet {

 String get id; String get performedExerciseId; int get setNumber; double get weightKg; int get reps; double get rpe; int get createdAt;// 6.0 - 10.0
 bool get isWarmup; bool get isDropSet; bool get isCompleted; int? get restSecondsTaken;
/// Create a copy of PerformedSet
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PerformedSetCopyWith<PerformedSet> get copyWith => _$PerformedSetCopyWithImpl<PerformedSet>(this as PerformedSet, _$identity);

  /// Serializes this PerformedSet to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PerformedSet&&(identical(other.id, id) || other.id == id)&&(identical(other.performedExerciseId, performedExerciseId) || other.performedExerciseId == performedExerciseId)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup)&&(identical(other.isDropSet, isDropSet) || other.isDropSet == isDropSet)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.restSecondsTaken, restSecondsTaken) || other.restSecondsTaken == restSecondsTaken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,performedExerciseId,setNumber,weightKg,reps,rpe,createdAt,isWarmup,isDropSet,isCompleted,restSecondsTaken);

@override
String toString() {
  return 'PerformedSet(id: $id, performedExerciseId: $performedExerciseId, setNumber: $setNumber, weightKg: $weightKg, reps: $reps, rpe: $rpe, createdAt: $createdAt, isWarmup: $isWarmup, isDropSet: $isDropSet, isCompleted: $isCompleted, restSecondsTaken: $restSecondsTaken)';
}


}

/// @nodoc
abstract mixin class $PerformedSetCopyWith<$Res>  {
  factory $PerformedSetCopyWith(PerformedSet value, $Res Function(PerformedSet) _then) = _$PerformedSetCopyWithImpl;
@useResult
$Res call({
 String id, String performedExerciseId, int setNumber, double weightKg, int reps, double rpe, int createdAt, bool isWarmup, bool isDropSet, bool isCompleted, int? restSecondsTaken
});




}
/// @nodoc
class _$PerformedSetCopyWithImpl<$Res>
    implements $PerformedSetCopyWith<$Res> {
  _$PerformedSetCopyWithImpl(this._self, this._then);

  final PerformedSet _self;
  final $Res Function(PerformedSet) _then;

/// Create a copy of PerformedSet
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? performedExerciseId = null,Object? setNumber = null,Object? weightKg = null,Object? reps = null,Object? rpe = null,Object? createdAt = null,Object? isWarmup = null,Object? isDropSet = null,Object? isCompleted = null,Object? restSecondsTaken = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,performedExerciseId: null == performedExerciseId ? _self.performedExerciseId : performedExerciseId // ignore: cast_nullable_to_non_nullable
as String,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,rpe: null == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,isDropSet: null == isDropSet ? _self.isDropSet : isDropSet // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,restSecondsTaken: freezed == restSecondsTaken ? _self.restSecondsTaken : restSecondsTaken // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [PerformedSet].
extension PerformedSetPatterns on PerformedSet {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PerformedSet value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PerformedSet() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PerformedSet value)  $default,){
final _that = this;
switch (_that) {
case _PerformedSet():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PerformedSet value)?  $default,){
final _that = this;
switch (_that) {
case _PerformedSet() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String performedExerciseId,  int setNumber,  double weightKg,  int reps,  double rpe,  int createdAt,  bool isWarmup,  bool isDropSet,  bool isCompleted,  int? restSecondsTaken)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PerformedSet() when $default != null:
return $default(_that.id,_that.performedExerciseId,_that.setNumber,_that.weightKg,_that.reps,_that.rpe,_that.createdAt,_that.isWarmup,_that.isDropSet,_that.isCompleted,_that.restSecondsTaken);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String performedExerciseId,  int setNumber,  double weightKg,  int reps,  double rpe,  int createdAt,  bool isWarmup,  bool isDropSet,  bool isCompleted,  int? restSecondsTaken)  $default,) {final _that = this;
switch (_that) {
case _PerformedSet():
return $default(_that.id,_that.performedExerciseId,_that.setNumber,_that.weightKg,_that.reps,_that.rpe,_that.createdAt,_that.isWarmup,_that.isDropSet,_that.isCompleted,_that.restSecondsTaken);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String performedExerciseId,  int setNumber,  double weightKg,  int reps,  double rpe,  int createdAt,  bool isWarmup,  bool isDropSet,  bool isCompleted,  int? restSecondsTaken)?  $default,) {final _that = this;
switch (_that) {
case _PerformedSet() when $default != null:
return $default(_that.id,_that.performedExerciseId,_that.setNumber,_that.weightKg,_that.reps,_that.rpe,_that.createdAt,_that.isWarmup,_that.isDropSet,_that.isCompleted,_that.restSecondsTaken);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PerformedSet implements PerformedSet {
  const _PerformedSet({required this.id, required this.performedExerciseId, required this.setNumber, required this.weightKg, required this.reps, required this.rpe, required this.createdAt, this.isWarmup = false, this.isDropSet = false, this.isCompleted = true, this.restSecondsTaken});
  factory _PerformedSet.fromJson(Map<String, dynamic> json) => _$PerformedSetFromJson(json);

@override final  String id;
@override final  String performedExerciseId;
@override final  int setNumber;
@override final  double weightKg;
@override final  int reps;
@override final  double rpe;
@override final  int createdAt;
// 6.0 - 10.0
@override@JsonKey() final  bool isWarmup;
@override@JsonKey() final  bool isDropSet;
@override@JsonKey() final  bool isCompleted;
@override final  int? restSecondsTaken;

/// Create a copy of PerformedSet
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PerformedSetCopyWith<_PerformedSet> get copyWith => __$PerformedSetCopyWithImpl<_PerformedSet>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PerformedSetToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PerformedSet&&(identical(other.id, id) || other.id == id)&&(identical(other.performedExerciseId, performedExerciseId) || other.performedExerciseId == performedExerciseId)&&(identical(other.setNumber, setNumber) || other.setNumber == setNumber)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.rpe, rpe) || other.rpe == rpe)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.isWarmup, isWarmup) || other.isWarmup == isWarmup)&&(identical(other.isDropSet, isDropSet) || other.isDropSet == isDropSet)&&(identical(other.isCompleted, isCompleted) || other.isCompleted == isCompleted)&&(identical(other.restSecondsTaken, restSecondsTaken) || other.restSecondsTaken == restSecondsTaken));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,performedExerciseId,setNumber,weightKg,reps,rpe,createdAt,isWarmup,isDropSet,isCompleted,restSecondsTaken);

@override
String toString() {
  return 'PerformedSet(id: $id, performedExerciseId: $performedExerciseId, setNumber: $setNumber, weightKg: $weightKg, reps: $reps, rpe: $rpe, createdAt: $createdAt, isWarmup: $isWarmup, isDropSet: $isDropSet, isCompleted: $isCompleted, restSecondsTaken: $restSecondsTaken)';
}


}

/// @nodoc
abstract mixin class _$PerformedSetCopyWith<$Res> implements $PerformedSetCopyWith<$Res> {
  factory _$PerformedSetCopyWith(_PerformedSet value, $Res Function(_PerformedSet) _then) = __$PerformedSetCopyWithImpl;
@override @useResult
$Res call({
 String id, String performedExerciseId, int setNumber, double weightKg, int reps, double rpe, int createdAt, bool isWarmup, bool isDropSet, bool isCompleted, int? restSecondsTaken
});




}
/// @nodoc
class __$PerformedSetCopyWithImpl<$Res>
    implements _$PerformedSetCopyWith<$Res> {
  __$PerformedSetCopyWithImpl(this._self, this._then);

  final _PerformedSet _self;
  final $Res Function(_PerformedSet) _then;

/// Create a copy of PerformedSet
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? performedExerciseId = null,Object? setNumber = null,Object? weightKg = null,Object? reps = null,Object? rpe = null,Object? createdAt = null,Object? isWarmup = null,Object? isDropSet = null,Object? isCompleted = null,Object? restSecondsTaken = freezed,}) {
  return _then(_PerformedSet(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,performedExerciseId: null == performedExerciseId ? _self.performedExerciseId : performedExerciseId // ignore: cast_nullable_to_non_nullable
as String,setNumber: null == setNumber ? _self.setNumber : setNumber // ignore: cast_nullable_to_non_nullable
as int,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,rpe: null == rpe ? _self.rpe : rpe // ignore: cast_nullable_to_non_nullable
as double,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,isWarmup: null == isWarmup ? _self.isWarmup : isWarmup // ignore: cast_nullable_to_non_nullable
as bool,isDropSet: null == isDropSet ? _self.isDropSet : isDropSet // ignore: cast_nullable_to_non_nullable
as bool,isCompleted: null == isCompleted ? _self.isCompleted : isCompleted // ignore: cast_nullable_to_non_nullable
as bool,restSecondsTaken: freezed == restSecondsTaken ? _self.restSecondsTaken : restSecondsTaken // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ProgressionRecord {

 String get id; String get exerciseId; String get exerciseName; MuscleGroup get muscleGroup; double get weightKg; int get reps; int get setCount; int get achievedAt; String get progressionType;// weight_increase, rep_increase, volume_increase, rpe_decrease
 double? get previousBestWeight; int? get previousBestReps;
/// Create a copy of ProgressionRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressionRecordCopyWith<ProgressionRecord> get copyWith => _$ProgressionRecordCopyWithImpl<ProgressionRecord>(this as ProgressionRecord, _$identity);

  /// Serializes this ProgressionRecord to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.setCount, setCount) || other.setCount == setCount)&&(identical(other.achievedAt, achievedAt) || other.achievedAt == achievedAt)&&(identical(other.progressionType, progressionType) || other.progressionType == progressionType)&&(identical(other.previousBestWeight, previousBestWeight) || other.previousBestWeight == previousBestWeight)&&(identical(other.previousBestReps, previousBestReps) || other.previousBestReps == previousBestReps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,exerciseName,muscleGroup,weightKg,reps,setCount,achievedAt,progressionType,previousBestWeight,previousBestReps);

@override
String toString() {
  return 'ProgressionRecord(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, weightKg: $weightKg, reps: $reps, setCount: $setCount, achievedAt: $achievedAt, progressionType: $progressionType, previousBestWeight: $previousBestWeight, previousBestReps: $previousBestReps)';
}


}

/// @nodoc
abstract mixin class $ProgressionRecordCopyWith<$Res>  {
  factory $ProgressionRecordCopyWith(ProgressionRecord value, $Res Function(ProgressionRecord) _then) = _$ProgressionRecordCopyWithImpl;
@useResult
$Res call({
 String id, String exerciseId, String exerciseName, MuscleGroup muscleGroup, double weightKg, int reps, int setCount, int achievedAt, String progressionType, double? previousBestWeight, int? previousBestReps
});




}
/// @nodoc
class _$ProgressionRecordCopyWithImpl<$Res>
    implements $ProgressionRecordCopyWith<$Res> {
  _$ProgressionRecordCopyWithImpl(this._self, this._then);

  final ProgressionRecord _self;
  final $Res Function(ProgressionRecord) _then;

/// Create a copy of ProgressionRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? exerciseId = null,Object? exerciseName = null,Object? muscleGroup = null,Object? weightKg = null,Object? reps = null,Object? setCount = null,Object? achievedAt = null,Object? progressionType = null,Object? previousBestWeight = freezed,Object? previousBestReps = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,setCount: null == setCount ? _self.setCount : setCount // ignore: cast_nullable_to_non_nullable
as int,achievedAt: null == achievedAt ? _self.achievedAt : achievedAt // ignore: cast_nullable_to_non_nullable
as int,progressionType: null == progressionType ? _self.progressionType : progressionType // ignore: cast_nullable_to_non_nullable
as String,previousBestWeight: freezed == previousBestWeight ? _self.previousBestWeight : previousBestWeight // ignore: cast_nullable_to_non_nullable
as double?,previousBestReps: freezed == previousBestReps ? _self.previousBestReps : previousBestReps // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressionRecord].
extension ProgressionRecordPatterns on ProgressionRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressionRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressionRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressionRecord value)  $default,){
final _that = this;
switch (_that) {
case _ProgressionRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressionRecord value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressionRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  String exerciseId,  String exerciseName,  MuscleGroup muscleGroup,  double weightKg,  int reps,  int setCount,  int achievedAt,  String progressionType,  double? previousBestWeight,  int? previousBestReps)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressionRecord() when $default != null:
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.weightKg,_that.reps,_that.setCount,_that.achievedAt,_that.progressionType,_that.previousBestWeight,_that.previousBestReps);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  String exerciseId,  String exerciseName,  MuscleGroup muscleGroup,  double weightKg,  int reps,  int setCount,  int achievedAt,  String progressionType,  double? previousBestWeight,  int? previousBestReps)  $default,) {final _that = this;
switch (_that) {
case _ProgressionRecord():
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.weightKg,_that.reps,_that.setCount,_that.achievedAt,_that.progressionType,_that.previousBestWeight,_that.previousBestReps);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  String exerciseId,  String exerciseName,  MuscleGroup muscleGroup,  double weightKg,  int reps,  int setCount,  int achievedAt,  String progressionType,  double? previousBestWeight,  int? previousBestReps)?  $default,) {final _that = this;
switch (_that) {
case _ProgressionRecord() when $default != null:
return $default(_that.id,_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.weightKg,_that.reps,_that.setCount,_that.achievedAt,_that.progressionType,_that.previousBestWeight,_that.previousBestReps);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressionRecord implements ProgressionRecord {
  const _ProgressionRecord({required this.id, required this.exerciseId, required this.exerciseName, required this.muscleGroup, required this.weightKg, required this.reps, required this.setCount, required this.achievedAt, required this.progressionType, this.previousBestWeight, this.previousBestReps});
  factory _ProgressionRecord.fromJson(Map<String, dynamic> json) => _$ProgressionRecordFromJson(json);

@override final  String id;
@override final  String exerciseId;
@override final  String exerciseName;
@override final  MuscleGroup muscleGroup;
@override final  double weightKg;
@override final  int reps;
@override final  int setCount;
@override final  int achievedAt;
@override final  String progressionType;
// weight_increase, rep_increase, volume_increase, rpe_decrease
@override final  double? previousBestWeight;
@override final  int? previousBestReps;

/// Create a copy of ProgressionRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressionRecordCopyWith<_ProgressionRecord> get copyWith => __$ProgressionRecordCopyWithImpl<_ProgressionRecord>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressionRecordToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressionRecord&&(identical(other.id, id) || other.id == id)&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg)&&(identical(other.reps, reps) || other.reps == reps)&&(identical(other.setCount, setCount) || other.setCount == setCount)&&(identical(other.achievedAt, achievedAt) || other.achievedAt == achievedAt)&&(identical(other.progressionType, progressionType) || other.progressionType == progressionType)&&(identical(other.previousBestWeight, previousBestWeight) || other.previousBestWeight == previousBestWeight)&&(identical(other.previousBestReps, previousBestReps) || other.previousBestReps == previousBestReps));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,exerciseId,exerciseName,muscleGroup,weightKg,reps,setCount,achievedAt,progressionType,previousBestWeight,previousBestReps);

@override
String toString() {
  return 'ProgressionRecord(id: $id, exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, weightKg: $weightKg, reps: $reps, setCount: $setCount, achievedAt: $achievedAt, progressionType: $progressionType, previousBestWeight: $previousBestWeight, previousBestReps: $previousBestReps)';
}


}

/// @nodoc
abstract mixin class _$ProgressionRecordCopyWith<$Res> implements $ProgressionRecordCopyWith<$Res> {
  factory _$ProgressionRecordCopyWith(_ProgressionRecord value, $Res Function(_ProgressionRecord) _then) = __$ProgressionRecordCopyWithImpl;
@override @useResult
$Res call({
 String id, String exerciseId, String exerciseName, MuscleGroup muscleGroup, double weightKg, int reps, int setCount, int achievedAt, String progressionType, double? previousBestWeight, int? previousBestReps
});




}
/// @nodoc
class __$ProgressionRecordCopyWithImpl<$Res>
    implements _$ProgressionRecordCopyWith<$Res> {
  __$ProgressionRecordCopyWithImpl(this._self, this._then);

  final _ProgressionRecord _self;
  final $Res Function(_ProgressionRecord) _then;

/// Create a copy of ProgressionRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? exerciseId = null,Object? exerciseName = null,Object? muscleGroup = null,Object? weightKg = null,Object? reps = null,Object? setCount = null,Object? achievedAt = null,Object? progressionType = null,Object? previousBestWeight = freezed,Object? previousBestReps = freezed,}) {
  return _then(_ProgressionRecord(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,weightKg: null == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double,reps: null == reps ? _self.reps : reps // ignore: cast_nullable_to_non_nullable
as int,setCount: null == setCount ? _self.setCount : setCount // ignore: cast_nullable_to_non_nullable
as int,achievedAt: null == achievedAt ? _self.achievedAt : achievedAt // ignore: cast_nullable_to_non_nullable
as int,progressionType: null == progressionType ? _self.progressionType : progressionType // ignore: cast_nullable_to_non_nullable
as String,previousBestWeight: freezed == previousBestWeight ? _self.previousBestWeight : previousBestWeight // ignore: cast_nullable_to_non_nullable
as double?,previousBestReps: freezed == previousBestReps ? _self.previousBestReps : previousBestReps // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}


/// @nodoc
mixin _$ReadinessScore {

 String get date;// YYYY-MM-DD
 int get score; WorkoutTier get suggestedTier; String get reason; int get createdAt;// 0-100
 int? get sleepMinutes; int? get sleepQuality;// 1-5
 int? get hrvRmssd; int? get restingHr; int? get sorenessScore;// 0-10
 int? get fatigueScore;// 0-10
 int? get moodScore;// 1-5
 bool get isMenstrualPhase; Map<String, int>? get factorsJson;
/// Create a copy of ReadinessScore
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ReadinessScoreCopyWith<ReadinessScore> get copyWith => _$ReadinessScoreCopyWithImpl<ReadinessScore>(this as ReadinessScore, _$identity);

  /// Serializes this ReadinessScore to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ReadinessScore&&(identical(other.date, date) || other.date == date)&&(identical(other.score, score) || other.score == score)&&(identical(other.suggestedTier, suggestedTier) || other.suggestedTier == suggestedTier)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sleepMinutes, sleepMinutes) || other.sleepMinutes == sleepMinutes)&&(identical(other.sleepQuality, sleepQuality) || other.sleepQuality == sleepQuality)&&(identical(other.hrvRmssd, hrvRmssd) || other.hrvRmssd == hrvRmssd)&&(identical(other.restingHr, restingHr) || other.restingHr == restingHr)&&(identical(other.sorenessScore, sorenessScore) || other.sorenessScore == sorenessScore)&&(identical(other.fatigueScore, fatigueScore) || other.fatigueScore == fatigueScore)&&(identical(other.moodScore, moodScore) || other.moodScore == moodScore)&&(identical(other.isMenstrualPhase, isMenstrualPhase) || other.isMenstrualPhase == isMenstrualPhase)&&const DeepCollectionEquality().equals(other.factorsJson, factorsJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,score,suggestedTier,reason,createdAt,sleepMinutes,sleepQuality,hrvRmssd,restingHr,sorenessScore,fatigueScore,moodScore,isMenstrualPhase,const DeepCollectionEquality().hash(factorsJson));

@override
String toString() {
  return 'ReadinessScore(date: $date, score: $score, suggestedTier: $suggestedTier, reason: $reason, createdAt: $createdAt, sleepMinutes: $sleepMinutes, sleepQuality: $sleepQuality, hrvRmssd: $hrvRmssd, restingHr: $restingHr, sorenessScore: $sorenessScore, fatigueScore: $fatigueScore, moodScore: $moodScore, isMenstrualPhase: $isMenstrualPhase, factorsJson: $factorsJson)';
}


}

/// @nodoc
abstract mixin class $ReadinessScoreCopyWith<$Res>  {
  factory $ReadinessScoreCopyWith(ReadinessScore value, $Res Function(ReadinessScore) _then) = _$ReadinessScoreCopyWithImpl;
@useResult
$Res call({
 String date, int score, WorkoutTier suggestedTier, String reason, int createdAt, int? sleepMinutes, int? sleepQuality, int? hrvRmssd, int? restingHr, int? sorenessScore, int? fatigueScore, int? moodScore, bool isMenstrualPhase, Map<String, int>? factorsJson
});




}
/// @nodoc
class _$ReadinessScoreCopyWithImpl<$Res>
    implements $ReadinessScoreCopyWith<$Res> {
  _$ReadinessScoreCopyWithImpl(this._self, this._then);

  final ReadinessScore _self;
  final $Res Function(ReadinessScore) _then;

/// Create a copy of ReadinessScore
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? score = null,Object? suggestedTier = null,Object? reason = null,Object? createdAt = null,Object? sleepMinutes = freezed,Object? sleepQuality = freezed,Object? hrvRmssd = freezed,Object? restingHr = freezed,Object? sorenessScore = freezed,Object? fatigueScore = freezed,Object? moodScore = freezed,Object? isMenstrualPhase = null,Object? factorsJson = freezed,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,suggestedTier: null == suggestedTier ? _self.suggestedTier : suggestedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,sleepMinutes: freezed == sleepMinutes ? _self.sleepMinutes : sleepMinutes // ignore: cast_nullable_to_non_nullable
as int?,sleepQuality: freezed == sleepQuality ? _self.sleepQuality : sleepQuality // ignore: cast_nullable_to_non_nullable
as int?,hrvRmssd: freezed == hrvRmssd ? _self.hrvRmssd : hrvRmssd // ignore: cast_nullable_to_non_nullable
as int?,restingHr: freezed == restingHr ? _self.restingHr : restingHr // ignore: cast_nullable_to_non_nullable
as int?,sorenessScore: freezed == sorenessScore ? _self.sorenessScore : sorenessScore // ignore: cast_nullable_to_non_nullable
as int?,fatigueScore: freezed == fatigueScore ? _self.fatigueScore : fatigueScore // ignore: cast_nullable_to_non_nullable
as int?,moodScore: freezed == moodScore ? _self.moodScore : moodScore // ignore: cast_nullable_to_non_nullable
as int?,isMenstrualPhase: null == isMenstrualPhase ? _self.isMenstrualPhase : isMenstrualPhase // ignore: cast_nullable_to_non_nullable
as bool,factorsJson: freezed == factorsJson ? _self.factorsJson : factorsJson // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,
  ));
}

}


/// Adds pattern-matching-related methods to [ReadinessScore].
extension ReadinessScorePatterns on ReadinessScore {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ReadinessScore value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ReadinessScore() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ReadinessScore value)  $default,){
final _that = this;
switch (_that) {
case _ReadinessScore():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ReadinessScore value)?  $default,){
final _that = this;
switch (_that) {
case _ReadinessScore() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date,  int score,  WorkoutTier suggestedTier,  String reason,  int createdAt,  int? sleepMinutes,  int? sleepQuality,  int? hrvRmssd,  int? restingHr,  int? sorenessScore,  int? fatigueScore,  int? moodScore,  bool isMenstrualPhase,  Map<String, int>? factorsJson)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ReadinessScore() when $default != null:
return $default(_that.date,_that.score,_that.suggestedTier,_that.reason,_that.createdAt,_that.sleepMinutes,_that.sleepQuality,_that.hrvRmssd,_that.restingHr,_that.sorenessScore,_that.fatigueScore,_that.moodScore,_that.isMenstrualPhase,_that.factorsJson);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date,  int score,  WorkoutTier suggestedTier,  String reason,  int createdAt,  int? sleepMinutes,  int? sleepQuality,  int? hrvRmssd,  int? restingHr,  int? sorenessScore,  int? fatigueScore,  int? moodScore,  bool isMenstrualPhase,  Map<String, int>? factorsJson)  $default,) {final _that = this;
switch (_that) {
case _ReadinessScore():
return $default(_that.date,_that.score,_that.suggestedTier,_that.reason,_that.createdAt,_that.sleepMinutes,_that.sleepQuality,_that.hrvRmssd,_that.restingHr,_that.sorenessScore,_that.fatigueScore,_that.moodScore,_that.isMenstrualPhase,_that.factorsJson);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date,  int score,  WorkoutTier suggestedTier,  String reason,  int createdAt,  int? sleepMinutes,  int? sleepQuality,  int? hrvRmssd,  int? restingHr,  int? sorenessScore,  int? fatigueScore,  int? moodScore,  bool isMenstrualPhase,  Map<String, int>? factorsJson)?  $default,) {final _that = this;
switch (_that) {
case _ReadinessScore() when $default != null:
return $default(_that.date,_that.score,_that.suggestedTier,_that.reason,_that.createdAt,_that.sleepMinutes,_that.sleepQuality,_that.hrvRmssd,_that.restingHr,_that.sorenessScore,_that.fatigueScore,_that.moodScore,_that.isMenstrualPhase,_that.factorsJson);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ReadinessScore implements ReadinessScore {
  const _ReadinessScore({required this.date, required this.score, required this.suggestedTier, required this.reason, required this.createdAt, this.sleepMinutes, this.sleepQuality, this.hrvRmssd, this.restingHr, this.sorenessScore, this.fatigueScore, this.moodScore, this.isMenstrualPhase = false, final  Map<String, int>? factorsJson}): _factorsJson = factorsJson;
  factory _ReadinessScore.fromJson(Map<String, dynamic> json) => _$ReadinessScoreFromJson(json);

@override final  String date;
// YYYY-MM-DD
@override final  int score;
@override final  WorkoutTier suggestedTier;
@override final  String reason;
@override final  int createdAt;
// 0-100
@override final  int? sleepMinutes;
@override final  int? sleepQuality;
// 1-5
@override final  int? hrvRmssd;
@override final  int? restingHr;
@override final  int? sorenessScore;
// 0-10
@override final  int? fatigueScore;
// 0-10
@override final  int? moodScore;
// 1-5
@override@JsonKey() final  bool isMenstrualPhase;
 final  Map<String, int>? _factorsJson;
@override Map<String, int>? get factorsJson {
  final value = _factorsJson;
  if (value == null) return null;
  if (_factorsJson is EqualUnmodifiableMapView) return _factorsJson;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(value);
}


/// Create a copy of ReadinessScore
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ReadinessScoreCopyWith<_ReadinessScore> get copyWith => __$ReadinessScoreCopyWithImpl<_ReadinessScore>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ReadinessScoreToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ReadinessScore&&(identical(other.date, date) || other.date == date)&&(identical(other.score, score) || other.score == score)&&(identical(other.suggestedTier, suggestedTier) || other.suggestedTier == suggestedTier)&&(identical(other.reason, reason) || other.reason == reason)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.sleepMinutes, sleepMinutes) || other.sleepMinutes == sleepMinutes)&&(identical(other.sleepQuality, sleepQuality) || other.sleepQuality == sleepQuality)&&(identical(other.hrvRmssd, hrvRmssd) || other.hrvRmssd == hrvRmssd)&&(identical(other.restingHr, restingHr) || other.restingHr == restingHr)&&(identical(other.sorenessScore, sorenessScore) || other.sorenessScore == sorenessScore)&&(identical(other.fatigueScore, fatigueScore) || other.fatigueScore == fatigueScore)&&(identical(other.moodScore, moodScore) || other.moodScore == moodScore)&&(identical(other.isMenstrualPhase, isMenstrualPhase) || other.isMenstrualPhase == isMenstrualPhase)&&const DeepCollectionEquality().equals(other._factorsJson, _factorsJson));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,score,suggestedTier,reason,createdAt,sleepMinutes,sleepQuality,hrvRmssd,restingHr,sorenessScore,fatigueScore,moodScore,isMenstrualPhase,const DeepCollectionEquality().hash(_factorsJson));

@override
String toString() {
  return 'ReadinessScore(date: $date, score: $score, suggestedTier: $suggestedTier, reason: $reason, createdAt: $createdAt, sleepMinutes: $sleepMinutes, sleepQuality: $sleepQuality, hrvRmssd: $hrvRmssd, restingHr: $restingHr, sorenessScore: $sorenessScore, fatigueScore: $fatigueScore, moodScore: $moodScore, isMenstrualPhase: $isMenstrualPhase, factorsJson: $factorsJson)';
}


}

/// @nodoc
abstract mixin class _$ReadinessScoreCopyWith<$Res> implements $ReadinessScoreCopyWith<$Res> {
  factory _$ReadinessScoreCopyWith(_ReadinessScore value, $Res Function(_ReadinessScore) _then) = __$ReadinessScoreCopyWithImpl;
@override @useResult
$Res call({
 String date, int score, WorkoutTier suggestedTier, String reason, int createdAt, int? sleepMinutes, int? sleepQuality, int? hrvRmssd, int? restingHr, int? sorenessScore, int? fatigueScore, int? moodScore, bool isMenstrualPhase, Map<String, int>? factorsJson
});




}
/// @nodoc
class __$ReadinessScoreCopyWithImpl<$Res>
    implements _$ReadinessScoreCopyWith<$Res> {
  __$ReadinessScoreCopyWithImpl(this._self, this._then);

  final _ReadinessScore _self;
  final $Res Function(_ReadinessScore) _then;

/// Create a copy of ReadinessScore
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? score = null,Object? suggestedTier = null,Object? reason = null,Object? createdAt = null,Object? sleepMinutes = freezed,Object? sleepQuality = freezed,Object? hrvRmssd = freezed,Object? restingHr = freezed,Object? sorenessScore = freezed,Object? fatigueScore = freezed,Object? moodScore = freezed,Object? isMenstrualPhase = null,Object? factorsJson = freezed,}) {
  return _then(_ReadinessScore(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,score: null == score ? _self.score : score // ignore: cast_nullable_to_non_nullable
as int,suggestedTier: null == suggestedTier ? _self.suggestedTier : suggestedTier // ignore: cast_nullable_to_non_nullable
as WorkoutTier,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as int,sleepMinutes: freezed == sleepMinutes ? _self.sleepMinutes : sleepMinutes // ignore: cast_nullable_to_non_nullable
as int?,sleepQuality: freezed == sleepQuality ? _self.sleepQuality : sleepQuality // ignore: cast_nullable_to_non_nullable
as int?,hrvRmssd: freezed == hrvRmssd ? _self.hrvRmssd : hrvRmssd // ignore: cast_nullable_to_non_nullable
as int?,restingHr: freezed == restingHr ? _self.restingHr : restingHr // ignore: cast_nullable_to_non_nullable
as int?,sorenessScore: freezed == sorenessScore ? _self.sorenessScore : sorenessScore // ignore: cast_nullable_to_non_nullable
as int?,fatigueScore: freezed == fatigueScore ? _self.fatigueScore : fatigueScore // ignore: cast_nullable_to_non_nullable
as int?,moodScore: freezed == moodScore ? _self.moodScore : moodScore // ignore: cast_nullable_to_non_nullable
as int?,isMenstrualPhase: null == isMenstrualPhase ? _self.isMenstrualPhase : isMenstrualPhase // ignore: cast_nullable_to_non_nullable
as bool,factorsJson: freezed == factorsJson ? _self._factorsJson : factorsJson // ignore: cast_nullable_to_non_nullable
as Map<String, int>?,
  ));
}


}


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


/// @nodoc
mixin _$WeeklyVolumeReport {

 Map<MuscleGroup, double> get volumePerMuscle; Map<MuscleGroup, int> get setsPerMuscle; Map<MuscleGroup, int> get sessionsPerMuscle; double get totalVolumeKg; int get totalSets; int get totalSessions; int get weekStartDate;
/// Create a copy of WeeklyVolumeReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyVolumeReportCopyWith<WeeklyVolumeReport> get copyWith => _$WeeklyVolumeReportCopyWithImpl<WeeklyVolumeReport>(this as WeeklyVolumeReport, _$identity);

  /// Serializes this WeeklyVolumeReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyVolumeReport&&const DeepCollectionEquality().equals(other.volumePerMuscle, volumePerMuscle)&&const DeepCollectionEquality().equals(other.setsPerMuscle, setsPerMuscle)&&const DeepCollectionEquality().equals(other.sessionsPerMuscle, sessionsPerMuscle)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.weekStartDate, weekStartDate) || other.weekStartDate == weekStartDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(volumePerMuscle),const DeepCollectionEquality().hash(setsPerMuscle),const DeepCollectionEquality().hash(sessionsPerMuscle),totalVolumeKg,totalSets,totalSessions,weekStartDate);

@override
String toString() {
  return 'WeeklyVolumeReport(volumePerMuscle: $volumePerMuscle, setsPerMuscle: $setsPerMuscle, sessionsPerMuscle: $sessionsPerMuscle, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, totalSessions: $totalSessions, weekStartDate: $weekStartDate)';
}


}

/// @nodoc
abstract mixin class $WeeklyVolumeReportCopyWith<$Res>  {
  factory $WeeklyVolumeReportCopyWith(WeeklyVolumeReport value, $Res Function(WeeklyVolumeReport) _then) = _$WeeklyVolumeReportCopyWithImpl;
@useResult
$Res call({
 Map<MuscleGroup, double> volumePerMuscle, Map<MuscleGroup, int> setsPerMuscle, Map<MuscleGroup, int> sessionsPerMuscle, double totalVolumeKg, int totalSets, int totalSessions, int weekStartDate
});




}
/// @nodoc
class _$WeeklyVolumeReportCopyWithImpl<$Res>
    implements $WeeklyVolumeReportCopyWith<$Res> {
  _$WeeklyVolumeReportCopyWithImpl(this._self, this._then);

  final WeeklyVolumeReport _self;
  final $Res Function(WeeklyVolumeReport) _then;

/// Create a copy of WeeklyVolumeReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volumePerMuscle = null,Object? setsPerMuscle = null,Object? sessionsPerMuscle = null,Object? totalVolumeKg = null,Object? totalSets = null,Object? totalSessions = null,Object? weekStartDate = null,}) {
  return _then(_self.copyWith(
volumePerMuscle: null == volumePerMuscle ? _self.volumePerMuscle : volumePerMuscle // ignore: cast_nullable_to_non_nullable
as Map<MuscleGroup, double>,setsPerMuscle: null == setsPerMuscle ? _self.setsPerMuscle : setsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<MuscleGroup, int>,sessionsPerMuscle: null == sessionsPerMuscle ? _self.sessionsPerMuscle : sessionsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<MuscleGroup, int>,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,weekStartDate: null == weekStartDate ? _self.weekStartDate : weekStartDate // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyVolumeReport].
extension WeeklyVolumeReportPatterns on WeeklyVolumeReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyVolumeReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyVolumeReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyVolumeReport value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyVolumeReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyVolumeReport value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyVolumeReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<MuscleGroup, double> volumePerMuscle,  Map<MuscleGroup, int> setsPerMuscle,  Map<MuscleGroup, int> sessionsPerMuscle,  double totalVolumeKg,  int totalSets,  int totalSessions,  int weekStartDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyVolumeReport() when $default != null:
return $default(_that.volumePerMuscle,_that.setsPerMuscle,_that.sessionsPerMuscle,_that.totalVolumeKg,_that.totalSets,_that.totalSessions,_that.weekStartDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<MuscleGroup, double> volumePerMuscle,  Map<MuscleGroup, int> setsPerMuscle,  Map<MuscleGroup, int> sessionsPerMuscle,  double totalVolumeKg,  int totalSets,  int totalSessions,  int weekStartDate)  $default,) {final _that = this;
switch (_that) {
case _WeeklyVolumeReport():
return $default(_that.volumePerMuscle,_that.setsPerMuscle,_that.sessionsPerMuscle,_that.totalVolumeKg,_that.totalSets,_that.totalSessions,_that.weekStartDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<MuscleGroup, double> volumePerMuscle,  Map<MuscleGroup, int> setsPerMuscle,  Map<MuscleGroup, int> sessionsPerMuscle,  double totalVolumeKg,  int totalSets,  int totalSessions,  int weekStartDate)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyVolumeReport() when $default != null:
return $default(_that.volumePerMuscle,_that.setsPerMuscle,_that.sessionsPerMuscle,_that.totalVolumeKg,_that.totalSets,_that.totalSessions,_that.weekStartDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyVolumeReport implements WeeklyVolumeReport {
  const _WeeklyVolumeReport({required final  Map<MuscleGroup, double> volumePerMuscle, required final  Map<MuscleGroup, int> setsPerMuscle, required final  Map<MuscleGroup, int> sessionsPerMuscle, required this.totalVolumeKg, required this.totalSets, required this.totalSessions, required this.weekStartDate}): _volumePerMuscle = volumePerMuscle,_setsPerMuscle = setsPerMuscle,_sessionsPerMuscle = sessionsPerMuscle;
  factory _WeeklyVolumeReport.fromJson(Map<String, dynamic> json) => _$WeeklyVolumeReportFromJson(json);

 final  Map<MuscleGroup, double> _volumePerMuscle;
@override Map<MuscleGroup, double> get volumePerMuscle {
  if (_volumePerMuscle is EqualUnmodifiableMapView) return _volumePerMuscle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_volumePerMuscle);
}

 final  Map<MuscleGroup, int> _setsPerMuscle;
@override Map<MuscleGroup, int> get setsPerMuscle {
  if (_setsPerMuscle is EqualUnmodifiableMapView) return _setsPerMuscle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_setsPerMuscle);
}

 final  Map<MuscleGroup, int> _sessionsPerMuscle;
@override Map<MuscleGroup, int> get sessionsPerMuscle {
  if (_sessionsPerMuscle is EqualUnmodifiableMapView) return _sessionsPerMuscle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessionsPerMuscle);
}

@override final  double totalVolumeKg;
@override final  int totalSets;
@override final  int totalSessions;
@override final  int weekStartDate;

/// Create a copy of WeeklyVolumeReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyVolumeReportCopyWith<_WeeklyVolumeReport> get copyWith => __$WeeklyVolumeReportCopyWithImpl<_WeeklyVolumeReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyVolumeReportToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyVolumeReport&&const DeepCollectionEquality().equals(other._volumePerMuscle, _volumePerMuscle)&&const DeepCollectionEquality().equals(other._setsPerMuscle, _setsPerMuscle)&&const DeepCollectionEquality().equals(other._sessionsPerMuscle, _sessionsPerMuscle)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.weekStartDate, weekStartDate) || other.weekStartDate == weekStartDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_volumePerMuscle),const DeepCollectionEquality().hash(_setsPerMuscle),const DeepCollectionEquality().hash(_sessionsPerMuscle),totalVolumeKg,totalSets,totalSessions,weekStartDate);

@override
String toString() {
  return 'WeeklyVolumeReport(volumePerMuscle: $volumePerMuscle, setsPerMuscle: $setsPerMuscle, sessionsPerMuscle: $sessionsPerMuscle, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, totalSessions: $totalSessions, weekStartDate: $weekStartDate)';
}


}

/// @nodoc
abstract mixin class _$WeeklyVolumeReportCopyWith<$Res> implements $WeeklyVolumeReportCopyWith<$Res> {
  factory _$WeeklyVolumeReportCopyWith(_WeeklyVolumeReport value, $Res Function(_WeeklyVolumeReport) _then) = __$WeeklyVolumeReportCopyWithImpl;
@override @useResult
$Res call({
 Map<MuscleGroup, double> volumePerMuscle, Map<MuscleGroup, int> setsPerMuscle, Map<MuscleGroup, int> sessionsPerMuscle, double totalVolumeKg, int totalSets, int totalSessions, int weekStartDate
});




}
/// @nodoc
class __$WeeklyVolumeReportCopyWithImpl<$Res>
    implements _$WeeklyVolumeReportCopyWith<$Res> {
  __$WeeklyVolumeReportCopyWithImpl(this._self, this._then);

  final _WeeklyVolumeReport _self;
  final $Res Function(_WeeklyVolumeReport) _then;

/// Create a copy of WeeklyVolumeReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? volumePerMuscle = null,Object? setsPerMuscle = null,Object? sessionsPerMuscle = null,Object? totalVolumeKg = null,Object? totalSets = null,Object? totalSessions = null,Object? weekStartDate = null,}) {
  return _then(_WeeklyVolumeReport(
volumePerMuscle: null == volumePerMuscle ? _self._volumePerMuscle : volumePerMuscle // ignore: cast_nullable_to_non_nullable
as Map<MuscleGroup, double>,setsPerMuscle: null == setsPerMuscle ? _self._setsPerMuscle : setsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<MuscleGroup, int>,sessionsPerMuscle: null == sessionsPerMuscle ? _self._sessionsPerMuscle : sessionsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<MuscleGroup, int>,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,weekStartDate: null == weekStartDate ? _self.weekStartDate : weekStartDate // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}


/// @nodoc
mixin _$StrengthStandard {

 String get exerciseId; String get exerciseName; MuscleGroup get muscleGroup; double get beginnerWeight; double get intermediateWeight; double get advancedWeight; double get eliteWeight;
/// Create a copy of StrengthStandard
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StrengthStandardCopyWith<StrengthStandard> get copyWith => _$StrengthStandardCopyWithImpl<StrengthStandard>(this as StrengthStandard, _$identity);

  /// Serializes this StrengthStandard to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StrengthStandard&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.beginnerWeight, beginnerWeight) || other.beginnerWeight == beginnerWeight)&&(identical(other.intermediateWeight, intermediateWeight) || other.intermediateWeight == intermediateWeight)&&(identical(other.advancedWeight, advancedWeight) || other.advancedWeight == advancedWeight)&&(identical(other.eliteWeight, eliteWeight) || other.eliteWeight == eliteWeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,muscleGroup,beginnerWeight,intermediateWeight,advancedWeight,eliteWeight);

@override
String toString() {
  return 'StrengthStandard(exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, beginnerWeight: $beginnerWeight, intermediateWeight: $intermediateWeight, advancedWeight: $advancedWeight, eliteWeight: $eliteWeight)';
}


}

/// @nodoc
abstract mixin class $StrengthStandardCopyWith<$Res>  {
  factory $StrengthStandardCopyWith(StrengthStandard value, $Res Function(StrengthStandard) _then) = _$StrengthStandardCopyWithImpl;
@useResult
$Res call({
 String exerciseId, String exerciseName, MuscleGroup muscleGroup, double beginnerWeight, double intermediateWeight, double advancedWeight, double eliteWeight
});




}
/// @nodoc
class _$StrengthStandardCopyWithImpl<$Res>
    implements $StrengthStandardCopyWith<$Res> {
  _$StrengthStandardCopyWithImpl(this._self, this._then);

  final StrengthStandard _self;
  final $Res Function(StrengthStandard) _then;

/// Create a copy of StrengthStandard
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? muscleGroup = null,Object? beginnerWeight = null,Object? intermediateWeight = null,Object? advancedWeight = null,Object? eliteWeight = null,}) {
  return _then(_self.copyWith(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,beginnerWeight: null == beginnerWeight ? _self.beginnerWeight : beginnerWeight // ignore: cast_nullable_to_non_nullable
as double,intermediateWeight: null == intermediateWeight ? _self.intermediateWeight : intermediateWeight // ignore: cast_nullable_to_non_nullable
as double,advancedWeight: null == advancedWeight ? _self.advancedWeight : advancedWeight // ignore: cast_nullable_to_non_nullable
as double,eliteWeight: null == eliteWeight ? _self.eliteWeight : eliteWeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StrengthStandard].
extension StrengthStandardPatterns on StrengthStandard {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StrengthStandard value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StrengthStandard() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StrengthStandard value)  $default,){
final _that = this;
switch (_that) {
case _StrengthStandard():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StrengthStandard value)?  $default,){
final _that = this;
switch (_that) {
case _StrengthStandard() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  MuscleGroup muscleGroup,  double beginnerWeight,  double intermediateWeight,  double advancedWeight,  double eliteWeight)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StrengthStandard() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.beginnerWeight,_that.intermediateWeight,_that.advancedWeight,_that.eliteWeight);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String exerciseId,  String exerciseName,  MuscleGroup muscleGroup,  double beginnerWeight,  double intermediateWeight,  double advancedWeight,  double eliteWeight)  $default,) {final _that = this;
switch (_that) {
case _StrengthStandard():
return $default(_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.beginnerWeight,_that.intermediateWeight,_that.advancedWeight,_that.eliteWeight);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String exerciseId,  String exerciseName,  MuscleGroup muscleGroup,  double beginnerWeight,  double intermediateWeight,  double advancedWeight,  double eliteWeight)?  $default,) {final _that = this;
switch (_that) {
case _StrengthStandard() when $default != null:
return $default(_that.exerciseId,_that.exerciseName,_that.muscleGroup,_that.beginnerWeight,_that.intermediateWeight,_that.advancedWeight,_that.eliteWeight);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StrengthStandard implements StrengthStandard {
  const _StrengthStandard({required this.exerciseId, required this.exerciseName, required this.muscleGroup, required this.beginnerWeight, required this.intermediateWeight, required this.advancedWeight, required this.eliteWeight});
  factory _StrengthStandard.fromJson(Map<String, dynamic> json) => _$StrengthStandardFromJson(json);

@override final  String exerciseId;
@override final  String exerciseName;
@override final  MuscleGroup muscleGroup;
@override final  double beginnerWeight;
@override final  double intermediateWeight;
@override final  double advancedWeight;
@override final  double eliteWeight;

/// Create a copy of StrengthStandard
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StrengthStandardCopyWith<_StrengthStandard> get copyWith => __$StrengthStandardCopyWithImpl<_StrengthStandard>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StrengthStandardToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StrengthStandard&&(identical(other.exerciseId, exerciseId) || other.exerciseId == exerciseId)&&(identical(other.exerciseName, exerciseName) || other.exerciseName == exerciseName)&&(identical(other.muscleGroup, muscleGroup) || other.muscleGroup == muscleGroup)&&(identical(other.beginnerWeight, beginnerWeight) || other.beginnerWeight == beginnerWeight)&&(identical(other.intermediateWeight, intermediateWeight) || other.intermediateWeight == intermediateWeight)&&(identical(other.advancedWeight, advancedWeight) || other.advancedWeight == advancedWeight)&&(identical(other.eliteWeight, eliteWeight) || other.eliteWeight == eliteWeight));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,exerciseId,exerciseName,muscleGroup,beginnerWeight,intermediateWeight,advancedWeight,eliteWeight);

@override
String toString() {
  return 'StrengthStandard(exerciseId: $exerciseId, exerciseName: $exerciseName, muscleGroup: $muscleGroup, beginnerWeight: $beginnerWeight, intermediateWeight: $intermediateWeight, advancedWeight: $advancedWeight, eliteWeight: $eliteWeight)';
}


}

/// @nodoc
abstract mixin class _$StrengthStandardCopyWith<$Res> implements $StrengthStandardCopyWith<$Res> {
  factory _$StrengthStandardCopyWith(_StrengthStandard value, $Res Function(_StrengthStandard) _then) = __$StrengthStandardCopyWithImpl;
@override @useResult
$Res call({
 String exerciseId, String exerciseName, MuscleGroup muscleGroup, double beginnerWeight, double intermediateWeight, double advancedWeight, double eliteWeight
});




}
/// @nodoc
class __$StrengthStandardCopyWithImpl<$Res>
    implements _$StrengthStandardCopyWith<$Res> {
  __$StrengthStandardCopyWithImpl(this._self, this._then);

  final _StrengthStandard _self;
  final $Res Function(_StrengthStandard) _then;

/// Create a copy of StrengthStandard
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exerciseId = null,Object? exerciseName = null,Object? muscleGroup = null,Object? beginnerWeight = null,Object? intermediateWeight = null,Object? advancedWeight = null,Object? eliteWeight = null,}) {
  return _then(_StrengthStandard(
exerciseId: null == exerciseId ? _self.exerciseId : exerciseId // ignore: cast_nullable_to_non_nullable
as String,exerciseName: null == exerciseName ? _self.exerciseName : exerciseName // ignore: cast_nullable_to_non_nullable
as String,muscleGroup: null == muscleGroup ? _self.muscleGroup : muscleGroup // ignore: cast_nullable_to_non_nullable
as MuscleGroup,beginnerWeight: null == beginnerWeight ? _self.beginnerWeight : beginnerWeight // ignore: cast_nullable_to_non_nullable
as double,intermediateWeight: null == intermediateWeight ? _self.intermediateWeight : intermediateWeight // ignore: cast_nullable_to_non_nullable
as double,advancedWeight: null == advancedWeight ? _self.advancedWeight : advancedWeight // ignore: cast_nullable_to_non_nullable
as double,eliteWeight: null == eliteWeight ? _self.eliteWeight : eliteWeight // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

SaveResult<T> _$SaveResultFromJson<T>(
  Map<String, dynamic> json,T Function(Object?) fromJsonT
) {
        switch (json['runtimeType']) {
                  case 'success':
          return SaveSuccess<T>.fromJson(
            json,fromJsonT
          );
                case 'failure':
          return SaveFailure<T>.fromJson(
            json,fromJsonT
          );
        
          default:
            throw CheckedFromJsonException(
  json,
  'runtimeType',
  'SaveResult',
  'Invalid union type "${json['runtimeType']}"!'
);
        }
      
}

/// @nodoc
mixin _$SaveResult<T> {



  /// Serializes this SaveResult to a JSON map.
  Map<String, dynamic> toJson(Object? Function(T) toJsonT);


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveResult<T>);
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SaveResult<$T>()';
}


}

/// @nodoc
class $SaveResultCopyWith<T,$Res>  {
$SaveResultCopyWith(SaveResult<T> _, $Res Function(SaveResult<T>) __);
}


/// Adds pattern-matching-related methods to [SaveResult].
extension SaveResultPatterns<T> on SaveResult<T> {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SaveSuccess<T> value)?  success,TResult Function( SaveFailure<T> value)?  failure,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SaveSuccess() when success != null:
return success(_that);case SaveFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SaveSuccess<T> value)  success,required TResult Function( SaveFailure<T> value)  failure,}){
final _that = this;
switch (_that) {
case SaveSuccess():
return success(_that);case SaveFailure():
return failure(_that);case _:
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SaveSuccess<T> value)?  success,TResult? Function( SaveFailure<T> value)?  failure,}){
final _that = this;
switch (_that) {
case SaveSuccess() when success != null:
return success(_that);case SaveFailure() when failure != null:
return failure(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( T data)?  success,TResult Function( String message)?  failure,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SaveSuccess() when success != null:
return success(_that.data);case SaveFailure() when failure != null:
return failure(_that.message);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( T data)  success,required TResult Function( String message)  failure,}) {final _that = this;
switch (_that) {
case SaveSuccess():
return success(_that.data);case SaveFailure():
return failure(_that.message);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( T data)?  success,TResult? Function( String message)?  failure,}) {final _that = this;
switch (_that) {
case SaveSuccess() when success != null:
return success(_that.data);case SaveFailure() when failure != null:
return failure(_that.message);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class SaveSuccess<T> implements SaveResult<T> {
  const SaveSuccess(this.data, {final  String? $type}): $type = $type ?? 'success';
  factory SaveSuccess.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$SaveSuccessFromJson(json,fromJsonT);

 final  T data;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SaveResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveSuccessCopyWith<T, SaveSuccess<T>> get copyWith => _$SaveSuccessCopyWithImpl<T, SaveSuccess<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$SaveSuccessToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveSuccess<T>&&const DeepCollectionEquality().equals(other.data, data));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(data));

@override
String toString() {
  return 'SaveResult<$T>.success(data: $data)';
}


}

/// @nodoc
abstract mixin class $SaveSuccessCopyWith<T,$Res> implements $SaveResultCopyWith<T, $Res> {
  factory $SaveSuccessCopyWith(SaveSuccess<T> value, $Res Function(SaveSuccess<T>) _then) = _$SaveSuccessCopyWithImpl;
@useResult
$Res call({
 T data
});




}
/// @nodoc
class _$SaveSuccessCopyWithImpl<T,$Res>
    implements $SaveSuccessCopyWith<T, $Res> {
  _$SaveSuccessCopyWithImpl(this._self, this._then);

  final SaveSuccess<T> _self;
  final $Res Function(SaveSuccess<T>) _then;

/// Create a copy of SaveResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? data = freezed,}) {
  return _then(SaveSuccess<T>(
freezed == data ? _self.data : data // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc
@JsonSerializable(genericArgumentFactories: true)

class SaveFailure<T> implements SaveResult<T> {
  const SaveFailure(this.message, {final  String? $type}): $type = $type ?? 'failure';
  factory SaveFailure.fromJson(Map<String, dynamic> json,T Function(Object?) fromJsonT) => _$SaveFailureFromJson(json,fromJsonT);

 final  String message;

@JsonKey(name: 'runtimeType')
final String $type;


/// Create a copy of SaveResult
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SaveFailureCopyWith<T, SaveFailure<T>> get copyWith => _$SaveFailureCopyWithImpl<T, SaveFailure<T>>(this, _$identity);

@override
Map<String, dynamic> toJson(Object? Function(T) toJsonT) {
  return _$SaveFailureToJson<T>(this, toJsonT);
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SaveFailure<T>&&(identical(other.message, message) || other.message == message));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,message);

@override
String toString() {
  return 'SaveResult<$T>.failure(message: $message)';
}


}

/// @nodoc
abstract mixin class $SaveFailureCopyWith<T,$Res> implements $SaveResultCopyWith<T, $Res> {
  factory $SaveFailureCopyWith(SaveFailure<T> value, $Res Function(SaveFailure<T>) _then) = _$SaveFailureCopyWithImpl;
@useResult
$Res call({
 String message
});




}
/// @nodoc
class _$SaveFailureCopyWithImpl<T,$Res>
    implements $SaveFailureCopyWith<T, $Res> {
  _$SaveFailureCopyWithImpl(this._self, this._then);

  final SaveFailure<T> _self;
  final $Res Function(SaveFailure<T>) _then;

/// Create a copy of SaveResult
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? message = null,}) {
  return _then(SaveFailure<T>(
null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
