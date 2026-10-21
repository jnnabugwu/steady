// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'daily_metric.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DailyMetric {

/// Date-only granularity, normalized to local midnight — the row's
/// natural key.
 DateTime get date;/// Calories eaten, parsed from a Cal AI PDF import.
 int? get caloriesEaten;/// Active calories burned, from HealthKit's `activeEnergyBurned`.
 int? get caloriesBurnedActive;/// Basal calories burned, from HealthKit's `basalEnergyBurned`.
 int? get caloriesBurnedBasal;/// Step count, from HealthKit's `stepCount`.
 int? get steps;/// Self-reported end-of-day logging status.
 LoggingStatus? get loggingStatus;
/// Create a copy of DailyMetric
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyMetricCopyWith<DailyMetric> get copyWith => _$DailyMetricCopyWithImpl<DailyMetric>(this as DailyMetric, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DailyMetric;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyMetric&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.caloriesEaten, _this.caloriesEaten) || other.caloriesEaten == _this.caloriesEaten)&&(identical(other.caloriesBurnedActive, _this.caloriesBurnedActive) || other.caloriesBurnedActive == _this.caloriesBurnedActive)&&(identical(other.caloriesBurnedBasal, _this.caloriesBurnedBasal) || other.caloriesBurnedBasal == _this.caloriesBurnedBasal)&&(identical(other.steps, _this.steps) || other.steps == _this.steps)&&(identical(other.loggingStatus, _this.loggingStatus) || other.loggingStatus == _this.loggingStatus));
}


@override
int get hashCode {
  final _this = this as DailyMetric;
  return Object.hash(runtimeType,_this.date,_this.caloriesEaten,_this.caloriesBurnedActive,_this.caloriesBurnedBasal,_this.steps,_this.loggingStatus);
}

@override
String toString() {
  final _this = this as DailyMetric;
  return 'DailyMetric(date: ${_this.date}, caloriesEaten: ${_this.caloriesEaten}, caloriesBurnedActive: ${_this.caloriesBurnedActive}, caloriesBurnedBasal: ${_this.caloriesBurnedBasal}, steps: ${_this.steps}, loggingStatus: ${_this.loggingStatus})';
}


}

/// @nodoc
abstract mixin class $DailyMetricCopyWith<$Res>  {
  factory $DailyMetricCopyWith(DailyMetric value, $Res Function(DailyMetric) _then) = _$DailyMetricCopyWithImpl;
@useResult
$Res call({
 DateTime date, int? caloriesEaten, int? caloriesBurnedActive, int? caloriesBurnedBasal, int? steps, LoggingStatus? loggingStatus
});




}
/// @nodoc
class _$DailyMetricCopyWithImpl<$Res>
    implements $DailyMetricCopyWith<$Res> {
  _$DailyMetricCopyWithImpl(this._self, this._then);

  final DailyMetric _self;
  final $Res Function(DailyMetric) _then;

/// Create a copy of DailyMetric
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? caloriesEaten = freezed,Object? caloriesBurnedActive = freezed,Object? caloriesBurnedBasal = freezed,Object? steps = freezed,Object? loggingStatus = freezed,}) {
  return _then(DailyMetric(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,caloriesEaten: freezed == caloriesEaten ? _self.caloriesEaten : caloriesEaten // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedActive: freezed == caloriesBurnedActive ? _self.caloriesBurnedActive : caloriesBurnedActive // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedBasal: freezed == caloriesBurnedBasal ? _self.caloriesBurnedBasal : caloriesBurnedBasal // ignore: cast_nullable_to_non_nullable
as int?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,loggingStatus: freezed == loggingStatus ? _self.loggingStatus : loggingStatus // ignore: cast_nullable_to_non_nullable
as LoggingStatus?,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyMetric].
extension DailyMetricPatterns on DailyMetric {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyMetric value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyMetric() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyMetric value)  $default,){
final _that = this;
switch (_that) {
case _DailyMetric():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyMetric value)?  $default,){
final _that = this;
switch (_that) {
case _DailyMetric() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  int? caloriesEaten,  int? caloriesBurnedActive,  int? caloriesBurnedBasal,  int? steps,  LoggingStatus? loggingStatus)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyMetric() when $default != null:
return $default(_that.date,_that.caloriesEaten,_that.caloriesBurnedActive,_that.caloriesBurnedBasal,_that.steps,_that.loggingStatus);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  int? caloriesEaten,  int? caloriesBurnedActive,  int? caloriesBurnedBasal,  int? steps,  LoggingStatus? loggingStatus)  $default,) {final _that = this;
switch (_that) {
case _DailyMetric():
return $default(_that.date,_that.caloriesEaten,_that.caloriesBurnedActive,_that.caloriesBurnedBasal,_that.steps,_that.loggingStatus);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  int? caloriesEaten,  int? caloriesBurnedActive,  int? caloriesBurnedBasal,  int? steps,  LoggingStatus? loggingStatus)?  $default,) {final _that = this;
switch (_that) {
case _DailyMetric() when $default != null:
return $default(_that.date,_that.caloriesEaten,_that.caloriesBurnedActive,_that.caloriesBurnedBasal,_that.steps,_that.loggingStatus);case _:
  return null;

}
}

}

/// @nodoc


class _DailyMetric implements DailyMetric {
  const _DailyMetric({required this.date, this.caloriesEaten, this.caloriesBurnedActive, this.caloriesBurnedBasal, this.steps, this.loggingStatus});
  

/// Date-only granularity, normalized to local midnight — the row's
/// natural key.
@override final  DateTime date;
/// Calories eaten, parsed from a Cal AI PDF import.
@override final  int? caloriesEaten;
/// Active calories burned, from HealthKit's `activeEnergyBurned`.
@override final  int? caloriesBurnedActive;
/// Basal calories burned, from HealthKit's `basalEnergyBurned`.
@override final  int? caloriesBurnedBasal;
/// Step count, from HealthKit's `stepCount`.
@override final  int? steps;
/// Self-reported end-of-day logging status.
@override final  LoggingStatus? loggingStatus;

/// Create a copy of DailyMetric
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyMetricCopyWith<_DailyMetric> get copyWith => __$DailyMetricCopyWithImpl<_DailyMetric>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyMetric&&(identical(other.date, date) || other.date == date)&&(identical(other.caloriesEaten, caloriesEaten) || other.caloriesEaten == caloriesEaten)&&(identical(other.caloriesBurnedActive, caloriesBurnedActive) || other.caloriesBurnedActive == caloriesBurnedActive)&&(identical(other.caloriesBurnedBasal, caloriesBurnedBasal) || other.caloriesBurnedBasal == caloriesBurnedBasal)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.loggingStatus, loggingStatus) || other.loggingStatus == loggingStatus));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date,caloriesEaten,caloriesBurnedActive,caloriesBurnedBasal,steps,loggingStatus);
}

@override
String toString() {
    return 'DailyMetric(date: $date, caloriesEaten: $caloriesEaten, caloriesBurnedActive: $caloriesBurnedActive, caloriesBurnedBasal: $caloriesBurnedBasal, steps: $steps, loggingStatus: $loggingStatus)';
}


}

/// @nodoc
abstract mixin class _$DailyMetricCopyWith<$Res> implements $DailyMetricCopyWith<$Res> {
  factory _$DailyMetricCopyWith(_DailyMetric value, $Res Function(_DailyMetric) _then) = __$DailyMetricCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, int? caloriesEaten, int? caloriesBurnedActive, int? caloriesBurnedBasal, int? steps, LoggingStatus? loggingStatus
});




}
/// @nodoc
class __$DailyMetricCopyWithImpl<$Res>
    implements _$DailyMetricCopyWith<$Res> {
  __$DailyMetricCopyWithImpl(this._self, this._then);

  final _DailyMetric _self;
  final $Res Function(_DailyMetric) _then;

/// Create a copy of DailyMetric
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? caloriesEaten = freezed,Object? caloriesBurnedActive = freezed,Object? caloriesBurnedBasal = freezed,Object? steps = freezed,Object? loggingStatus = freezed,}) {
  return _then(_DailyMetric(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,caloriesEaten: freezed == caloriesEaten ? _self.caloriesEaten : caloriesEaten // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedActive: freezed == caloriesBurnedActive ? _self.caloriesBurnedActive : caloriesBurnedActive // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedBasal: freezed == caloriesBurnedBasal ? _self.caloriesBurnedBasal : caloriesBurnedBasal // ignore: cast_nullable_to_non_nullable
as int?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,loggingStatus: freezed == loggingStatus ? _self.loggingStatus : loggingStatus // ignore: cast_nullable_to_non_nullable
as LoggingStatus?,
  ));
}


}

// dart format on
