// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'progression_engine.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ProgressionRecommendation {

 double get nextWeightKg; int get nextRepsMin; int get nextRepsMax; String get reason;
/// Create a copy of ProgressionRecommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ProgressionRecommendationCopyWith<ProgressionRecommendation> get copyWith => _$ProgressionRecommendationCopyWithImpl<ProgressionRecommendation>(this as ProgressionRecommendation, _$identity);

  /// Serializes this ProgressionRecommendation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ProgressionRecommendation&&(identical(other.nextWeightKg, nextWeightKg) || other.nextWeightKg == nextWeightKg)&&(identical(other.nextRepsMin, nextRepsMin) || other.nextRepsMin == nextRepsMin)&&(identical(other.nextRepsMax, nextRepsMax) || other.nextRepsMax == nextRepsMax)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nextWeightKg,nextRepsMin,nextRepsMax,reason);

@override
String toString() {
  return 'ProgressionRecommendation(nextWeightKg: $nextWeightKg, nextRepsMin: $nextRepsMin, nextRepsMax: $nextRepsMax, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $ProgressionRecommendationCopyWith<$Res>  {
  factory $ProgressionRecommendationCopyWith(ProgressionRecommendation value, $Res Function(ProgressionRecommendation) _then) = _$ProgressionRecommendationCopyWithImpl;
@useResult
$Res call({
 double nextWeightKg, int nextRepsMin, int nextRepsMax, String reason
});




}
/// @nodoc
class _$ProgressionRecommendationCopyWithImpl<$Res>
    implements $ProgressionRecommendationCopyWith<$Res> {
  _$ProgressionRecommendationCopyWithImpl(this._self, this._then);

  final ProgressionRecommendation _self;
  final $Res Function(ProgressionRecommendation) _then;

/// Create a copy of ProgressionRecommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? nextWeightKg = null,Object? nextRepsMin = null,Object? nextRepsMax = null,Object? reason = null,}) {
  return _then(_self.copyWith(
nextWeightKg: null == nextWeightKg ? _self.nextWeightKg : nextWeightKg // ignore: cast_nullable_to_non_nullable
as double,nextRepsMin: null == nextRepsMin ? _self.nextRepsMin : nextRepsMin // ignore: cast_nullable_to_non_nullable
as int,nextRepsMax: null == nextRepsMax ? _self.nextRepsMax : nextRepsMax // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ProgressionRecommendation].
extension ProgressionRecommendationPatterns on ProgressionRecommendation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ProgressionRecommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ProgressionRecommendation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ProgressionRecommendation value)  $default,){
final _that = this;
switch (_that) {
case _ProgressionRecommendation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ProgressionRecommendation value)?  $default,){
final _that = this;
switch (_that) {
case _ProgressionRecommendation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double nextWeightKg,  int nextRepsMin,  int nextRepsMax,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ProgressionRecommendation() when $default != null:
return $default(_that.nextWeightKg,_that.nextRepsMin,_that.nextRepsMax,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double nextWeightKg,  int nextRepsMin,  int nextRepsMax,  String reason)  $default,) {final _that = this;
switch (_that) {
case _ProgressionRecommendation():
return $default(_that.nextWeightKg,_that.nextRepsMin,_that.nextRepsMax,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double nextWeightKg,  int nextRepsMin,  int nextRepsMax,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _ProgressionRecommendation() when $default != null:
return $default(_that.nextWeightKg,_that.nextRepsMin,_that.nextRepsMax,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _ProgressionRecommendation implements ProgressionRecommendation {
  const _ProgressionRecommendation({required this.nextWeightKg, required this.nextRepsMin, required this.nextRepsMax, required this.reason});
  factory _ProgressionRecommendation.fromJson(Map<String, dynamic> json) => _$ProgressionRecommendationFromJson(json);

@override final  double nextWeightKg;
@override final  int nextRepsMin;
@override final  int nextRepsMax;
@override final  String reason;

/// Create a copy of ProgressionRecommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ProgressionRecommendationCopyWith<_ProgressionRecommendation> get copyWith => __$ProgressionRecommendationCopyWithImpl<_ProgressionRecommendation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$ProgressionRecommendationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ProgressionRecommendation&&(identical(other.nextWeightKg, nextWeightKg) || other.nextWeightKg == nextWeightKg)&&(identical(other.nextRepsMin, nextRepsMin) || other.nextRepsMin == nextRepsMin)&&(identical(other.nextRepsMax, nextRepsMax) || other.nextRepsMax == nextRepsMax)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,nextWeightKg,nextRepsMin,nextRepsMax,reason);

@override
String toString() {
  return 'ProgressionRecommendation(nextWeightKg: $nextWeightKg, nextRepsMin: $nextRepsMin, nextRepsMax: $nextRepsMax, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$ProgressionRecommendationCopyWith<$Res> implements $ProgressionRecommendationCopyWith<$Res> {
  factory _$ProgressionRecommendationCopyWith(_ProgressionRecommendation value, $Res Function(_ProgressionRecommendation) _then) = __$ProgressionRecommendationCopyWithImpl;
@override @useResult
$Res call({
 double nextWeightKg, int nextRepsMin, int nextRepsMax, String reason
});




}
/// @nodoc
class __$ProgressionRecommendationCopyWithImpl<$Res>
    implements _$ProgressionRecommendationCopyWith<$Res> {
  __$ProgressionRecommendationCopyWithImpl(this._self, this._then);

  final _ProgressionRecommendation _self;
  final $Res Function(_ProgressionRecommendation) _then;

/// Create a copy of ProgressionRecommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? nextWeightKg = null,Object? nextRepsMin = null,Object? nextRepsMax = null,Object? reason = null,}) {
  return _then(_ProgressionRecommendation(
nextWeightKg: null == nextWeightKg ? _self.nextWeightKg : nextWeightKg // ignore: cast_nullable_to_non_nullable
as double,nextRepsMin: null == nextRepsMin ? _self.nextRepsMin : nextRepsMin // ignore: cast_nullable_to_non_nullable
as int,nextRepsMax: null == nextRepsMax ? _self.nextRepsMax : nextRepsMax // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$DeloadRecommendation {

 double get weightMultiplier; double get setsMultiplier; int get repsMin; int get repsMax; String get reason;
/// Create a copy of DeloadRecommendation
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DeloadRecommendationCopyWith<DeloadRecommendation> get copyWith => _$DeloadRecommendationCopyWithImpl<DeloadRecommendation>(this as DeloadRecommendation, _$identity);

  /// Serializes this DeloadRecommendation to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DeloadRecommendation&&(identical(other.weightMultiplier, weightMultiplier) || other.weightMultiplier == weightMultiplier)&&(identical(other.setsMultiplier, setsMultiplier) || other.setsMultiplier == setsMultiplier)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightMultiplier,setsMultiplier,repsMin,repsMax,reason);

@override
String toString() {
  return 'DeloadRecommendation(weightMultiplier: $weightMultiplier, setsMultiplier: $setsMultiplier, repsMin: $repsMin, repsMax: $repsMax, reason: $reason)';
}


}

/// @nodoc
abstract mixin class $DeloadRecommendationCopyWith<$Res>  {
  factory $DeloadRecommendationCopyWith(DeloadRecommendation value, $Res Function(DeloadRecommendation) _then) = _$DeloadRecommendationCopyWithImpl;
@useResult
$Res call({
 double weightMultiplier, double setsMultiplier, int repsMin, int repsMax, String reason
});




}
/// @nodoc
class _$DeloadRecommendationCopyWithImpl<$Res>
    implements $DeloadRecommendationCopyWith<$Res> {
  _$DeloadRecommendationCopyWithImpl(this._self, this._then);

  final DeloadRecommendation _self;
  final $Res Function(DeloadRecommendation) _then;

/// Create a copy of DeloadRecommendation
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weightMultiplier = null,Object? setsMultiplier = null,Object? repsMin = null,Object? repsMax = null,Object? reason = null,}) {
  return _then(_self.copyWith(
weightMultiplier: null == weightMultiplier ? _self.weightMultiplier : weightMultiplier // ignore: cast_nullable_to_non_nullable
as double,setsMultiplier: null == setsMultiplier ? _self.setsMultiplier : setsMultiplier // ignore: cast_nullable_to_non_nullable
as double,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [DeloadRecommendation].
extension DeloadRecommendationPatterns on DeloadRecommendation {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DeloadRecommendation value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DeloadRecommendation() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DeloadRecommendation value)  $default,){
final _that = this;
switch (_that) {
case _DeloadRecommendation():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DeloadRecommendation value)?  $default,){
final _that = this;
switch (_that) {
case _DeloadRecommendation() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double weightMultiplier,  double setsMultiplier,  int repsMin,  int repsMax,  String reason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DeloadRecommendation() when $default != null:
return $default(_that.weightMultiplier,_that.setsMultiplier,_that.repsMin,_that.repsMax,_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double weightMultiplier,  double setsMultiplier,  int repsMin,  int repsMax,  String reason)  $default,) {final _that = this;
switch (_that) {
case _DeloadRecommendation():
return $default(_that.weightMultiplier,_that.setsMultiplier,_that.repsMin,_that.repsMax,_that.reason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double weightMultiplier,  double setsMultiplier,  int repsMin,  int repsMax,  String reason)?  $default,) {final _that = this;
switch (_that) {
case _DeloadRecommendation() when $default != null:
return $default(_that.weightMultiplier,_that.setsMultiplier,_that.repsMin,_that.repsMax,_that.reason);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DeloadRecommendation implements DeloadRecommendation {
  const _DeloadRecommendation({required this.weightMultiplier, required this.setsMultiplier, required this.repsMin, required this.repsMax, required this.reason});
  factory _DeloadRecommendation.fromJson(Map<String, dynamic> json) => _$DeloadRecommendationFromJson(json);

@override final  double weightMultiplier;
@override final  double setsMultiplier;
@override final  int repsMin;
@override final  int repsMax;
@override final  String reason;

/// Create a copy of DeloadRecommendation
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DeloadRecommendationCopyWith<_DeloadRecommendation> get copyWith => __$DeloadRecommendationCopyWithImpl<_DeloadRecommendation>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DeloadRecommendationToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DeloadRecommendation&&(identical(other.weightMultiplier, weightMultiplier) || other.weightMultiplier == weightMultiplier)&&(identical(other.setsMultiplier, setsMultiplier) || other.setsMultiplier == setsMultiplier)&&(identical(other.repsMin, repsMin) || other.repsMin == repsMin)&&(identical(other.repsMax, repsMax) || other.repsMax == repsMax)&&(identical(other.reason, reason) || other.reason == reason));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weightMultiplier,setsMultiplier,repsMin,repsMax,reason);

@override
String toString() {
  return 'DeloadRecommendation(weightMultiplier: $weightMultiplier, setsMultiplier: $setsMultiplier, repsMin: $repsMin, repsMax: $repsMax, reason: $reason)';
}


}

/// @nodoc
abstract mixin class _$DeloadRecommendationCopyWith<$Res> implements $DeloadRecommendationCopyWith<$Res> {
  factory _$DeloadRecommendationCopyWith(_DeloadRecommendation value, $Res Function(_DeloadRecommendation) _then) = __$DeloadRecommendationCopyWithImpl;
@override @useResult
$Res call({
 double weightMultiplier, double setsMultiplier, int repsMin, int repsMax, String reason
});




}
/// @nodoc
class __$DeloadRecommendationCopyWithImpl<$Res>
    implements _$DeloadRecommendationCopyWith<$Res> {
  __$DeloadRecommendationCopyWithImpl(this._self, this._then);

  final _DeloadRecommendation _self;
  final $Res Function(_DeloadRecommendation) _then;

/// Create a copy of DeloadRecommendation
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weightMultiplier = null,Object? setsMultiplier = null,Object? repsMin = null,Object? repsMax = null,Object? reason = null,}) {
  return _then(_DeloadRecommendation(
weightMultiplier: null == weightMultiplier ? _self.weightMultiplier : weightMultiplier // ignore: cast_nullable_to_non_nullable
as double,setsMultiplier: null == setsMultiplier ? _self.setsMultiplier : setsMultiplier // ignore: cast_nullable_to_non_nullable
as double,repsMin: null == repsMin ? _self.repsMin : repsMin // ignore: cast_nullable_to_non_nullable
as int,repsMax: null == repsMax ? _self.repsMax : repsMax // ignore: cast_nullable_to_non_nullable
as int,reason: null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
