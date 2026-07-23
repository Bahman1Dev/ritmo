// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sports_local_datasource.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$WeeklyVolumeReportData {

 Map<String, double> get volumePerMuscle; Map<String, int> get setsPerMuscle; Map<String, int> get sessionsPerMuscle; double get totalVolumeKg; int get totalSets; int get totalSessions; int get weekStartDate;
/// Create a copy of WeeklyVolumeReportData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyVolumeReportDataCopyWith<WeeklyVolumeReportData> get copyWith => _$WeeklyVolumeReportDataCopyWithImpl<WeeklyVolumeReportData>(this as WeeklyVolumeReportData, _$identity);

  /// Serializes this WeeklyVolumeReportData to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyVolumeReportData&&const DeepCollectionEquality().equals(other.volumePerMuscle, volumePerMuscle)&&const DeepCollectionEquality().equals(other.setsPerMuscle, setsPerMuscle)&&const DeepCollectionEquality().equals(other.sessionsPerMuscle, sessionsPerMuscle)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.weekStartDate, weekStartDate) || other.weekStartDate == weekStartDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(volumePerMuscle),const DeepCollectionEquality().hash(setsPerMuscle),const DeepCollectionEquality().hash(sessionsPerMuscle),totalVolumeKg,totalSets,totalSessions,weekStartDate);

@override
String toString() {
  return 'WeeklyVolumeReportData(volumePerMuscle: $volumePerMuscle, setsPerMuscle: $setsPerMuscle, sessionsPerMuscle: $sessionsPerMuscle, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, totalSessions: $totalSessions, weekStartDate: $weekStartDate)';
}


}

/// @nodoc
abstract mixin class $WeeklyVolumeReportDataCopyWith<$Res>  {
  factory $WeeklyVolumeReportDataCopyWith(WeeklyVolumeReportData value, $Res Function(WeeklyVolumeReportData) _then) = _$WeeklyVolumeReportDataCopyWithImpl;
@useResult
$Res call({
 Map<String, double> volumePerMuscle, Map<String, int> setsPerMuscle, Map<String, int> sessionsPerMuscle, double totalVolumeKg, int totalSets, int totalSessions, int weekStartDate
});




}
/// @nodoc
class _$WeeklyVolumeReportDataCopyWithImpl<$Res>
    implements $WeeklyVolumeReportDataCopyWith<$Res> {
  _$WeeklyVolumeReportDataCopyWithImpl(this._self, this._then);

  final WeeklyVolumeReportData _self;
  final $Res Function(WeeklyVolumeReportData) _then;

/// Create a copy of WeeklyVolumeReportData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? volumePerMuscle = null,Object? setsPerMuscle = null,Object? sessionsPerMuscle = null,Object? totalVolumeKg = null,Object? totalSets = null,Object? totalSessions = null,Object? weekStartDate = null,}) {
  return _then(_self.copyWith(
volumePerMuscle: null == volumePerMuscle ? _self.volumePerMuscle : volumePerMuscle // ignore: cast_nullable_to_non_nullable
as Map<String, double>,setsPerMuscle: null == setsPerMuscle ? _self.setsPerMuscle : setsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<String, int>,sessionsPerMuscle: null == sessionsPerMuscle ? _self.sessionsPerMuscle : sessionsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<String, int>,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,weekStartDate: null == weekStartDate ? _self.weekStartDate : weekStartDate // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyVolumeReportData].
extension WeeklyVolumeReportDataPatterns on WeeklyVolumeReportData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyVolumeReportData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyVolumeReportData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyVolumeReportData value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyVolumeReportData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyVolumeReportData value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyVolumeReportData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( Map<String, double> volumePerMuscle,  Map<String, int> setsPerMuscle,  Map<String, int> sessionsPerMuscle,  double totalVolumeKg,  int totalSets,  int totalSessions,  int weekStartDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyVolumeReportData() when $default != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( Map<String, double> volumePerMuscle,  Map<String, int> setsPerMuscle,  Map<String, int> sessionsPerMuscle,  double totalVolumeKg,  int totalSets,  int totalSessions,  int weekStartDate)  $default,) {final _that = this;
switch (_that) {
case _WeeklyVolumeReportData():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( Map<String, double> volumePerMuscle,  Map<String, int> setsPerMuscle,  Map<String, int> sessionsPerMuscle,  double totalVolumeKg,  int totalSets,  int totalSessions,  int weekStartDate)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyVolumeReportData() when $default != null:
return $default(_that.volumePerMuscle,_that.setsPerMuscle,_that.sessionsPerMuscle,_that.totalVolumeKg,_that.totalSets,_that.totalSessions,_that.weekStartDate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _WeeklyVolumeReportData implements WeeklyVolumeReportData {
  const _WeeklyVolumeReportData({required final  Map<String, double> volumePerMuscle, required final  Map<String, int> setsPerMuscle, required final  Map<String, int> sessionsPerMuscle, required this.totalVolumeKg, required this.totalSets, required this.totalSessions, required this.weekStartDate}): _volumePerMuscle = volumePerMuscle,_setsPerMuscle = setsPerMuscle,_sessionsPerMuscle = sessionsPerMuscle;
  factory _WeeklyVolumeReportData.fromJson(Map<String, dynamic> json) => _$WeeklyVolumeReportDataFromJson(json);

 final  Map<String, double> _volumePerMuscle;
@override Map<String, double> get volumePerMuscle {
  if (_volumePerMuscle is EqualUnmodifiableMapView) return _volumePerMuscle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_volumePerMuscle);
}

 final  Map<String, int> _setsPerMuscle;
@override Map<String, int> get setsPerMuscle {
  if (_setsPerMuscle is EqualUnmodifiableMapView) return _setsPerMuscle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_setsPerMuscle);
}

 final  Map<String, int> _sessionsPerMuscle;
@override Map<String, int> get sessionsPerMuscle {
  if (_sessionsPerMuscle is EqualUnmodifiableMapView) return _sessionsPerMuscle;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_sessionsPerMuscle);
}

@override final  double totalVolumeKg;
@override final  int totalSets;
@override final  int totalSessions;
@override final  int weekStartDate;

/// Create a copy of WeeklyVolumeReportData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyVolumeReportDataCopyWith<_WeeklyVolumeReportData> get copyWith => __$WeeklyVolumeReportDataCopyWithImpl<_WeeklyVolumeReportData>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$WeeklyVolumeReportDataToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyVolumeReportData&&const DeepCollectionEquality().equals(other._volumePerMuscle, _volumePerMuscle)&&const DeepCollectionEquality().equals(other._setsPerMuscle, _setsPerMuscle)&&const DeepCollectionEquality().equals(other._sessionsPerMuscle, _sessionsPerMuscle)&&(identical(other.totalVolumeKg, totalVolumeKg) || other.totalVolumeKg == totalVolumeKg)&&(identical(other.totalSets, totalSets) || other.totalSets == totalSets)&&(identical(other.totalSessions, totalSessions) || other.totalSessions == totalSessions)&&(identical(other.weekStartDate, weekStartDate) || other.weekStartDate == weekStartDate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_volumePerMuscle),const DeepCollectionEquality().hash(_setsPerMuscle),const DeepCollectionEquality().hash(_sessionsPerMuscle),totalVolumeKg,totalSets,totalSessions,weekStartDate);

@override
String toString() {
  return 'WeeklyVolumeReportData(volumePerMuscle: $volumePerMuscle, setsPerMuscle: $setsPerMuscle, sessionsPerMuscle: $sessionsPerMuscle, totalVolumeKg: $totalVolumeKg, totalSets: $totalSets, totalSessions: $totalSessions, weekStartDate: $weekStartDate)';
}


}

/// @nodoc
abstract mixin class _$WeeklyVolumeReportDataCopyWith<$Res> implements $WeeklyVolumeReportDataCopyWith<$Res> {
  factory _$WeeklyVolumeReportDataCopyWith(_WeeklyVolumeReportData value, $Res Function(_WeeklyVolumeReportData) _then) = __$WeeklyVolumeReportDataCopyWithImpl;
@override @useResult
$Res call({
 Map<String, double> volumePerMuscle, Map<String, int> setsPerMuscle, Map<String, int> sessionsPerMuscle, double totalVolumeKg, int totalSets, int totalSessions, int weekStartDate
});




}
/// @nodoc
class __$WeeklyVolumeReportDataCopyWithImpl<$Res>
    implements _$WeeklyVolumeReportDataCopyWith<$Res> {
  __$WeeklyVolumeReportDataCopyWithImpl(this._self, this._then);

  final _WeeklyVolumeReportData _self;
  final $Res Function(_WeeklyVolumeReportData) _then;

/// Create a copy of WeeklyVolumeReportData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? volumePerMuscle = null,Object? setsPerMuscle = null,Object? sessionsPerMuscle = null,Object? totalVolumeKg = null,Object? totalSets = null,Object? totalSessions = null,Object? weekStartDate = null,}) {
  return _then(_WeeklyVolumeReportData(
volumePerMuscle: null == volumePerMuscle ? _self._volumePerMuscle : volumePerMuscle // ignore: cast_nullable_to_non_nullable
as Map<String, double>,setsPerMuscle: null == setsPerMuscle ? _self._setsPerMuscle : setsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<String, int>,sessionsPerMuscle: null == sessionsPerMuscle ? _self._sessionsPerMuscle : sessionsPerMuscle // ignore: cast_nullable_to_non_nullable
as Map<String, int>,totalVolumeKg: null == totalVolumeKg ? _self.totalVolumeKg : totalVolumeKg // ignore: cast_nullable_to_non_nullable
as double,totalSets: null == totalSets ? _self.totalSets : totalSets // ignore: cast_nullable_to_non_nullable
as int,totalSessions: null == totalSessions ? _self.totalSessions : totalSessions // ignore: cast_nullable_to_non_nullable
as int,weekStartDate: null == weekStartDate ? _self.weekStartDate : weekStartDate // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
