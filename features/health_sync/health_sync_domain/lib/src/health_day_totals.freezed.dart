// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_day_totals.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HealthDayTotals {

/// The day, at local midnight.
 DateTime get date;/// Summed `stepCount`.
 int? get steps;/// Summed `activeEnergyBurned`, rounded to whole kcal.
 int? get caloriesBurnedActive;/// Summed `basalEnergyBurned`, rounded to whole kcal.
 int? get caloriesBurnedBasal;/// The day's most recent `bodyMass` reading, in kilograms. Not a sum,
/// and not smoothed: see `weightTrendKg` for the trend.
 double? get weightKg;
/// Create a copy of HealthDayTotals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthDayTotalsCopyWith<HealthDayTotals> get copyWith => _$HealthDayTotalsCopyWithImpl<HealthDayTotals>(this as HealthDayTotals, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HealthDayTotals;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthDayTotals&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.steps, _this.steps) || other.steps == _this.steps)&&(identical(other.caloriesBurnedActive, _this.caloriesBurnedActive) || other.caloriesBurnedActive == _this.caloriesBurnedActive)&&(identical(other.caloriesBurnedBasal, _this.caloriesBurnedBasal) || other.caloriesBurnedBasal == _this.caloriesBurnedBasal)&&(identical(other.weightKg, _this.weightKg) || other.weightKg == _this.weightKg));
}


@override
int get hashCode {
  final _this = this as HealthDayTotals;
  return Object.hash(runtimeType,_this.date,_this.steps,_this.caloriesBurnedActive,_this.caloriesBurnedBasal,_this.weightKg);
}

@override
String toString() {
  final _this = this as HealthDayTotals;
  return 'HealthDayTotals(date: ${_this.date}, steps: ${_this.steps}, caloriesBurnedActive: ${_this.caloriesBurnedActive}, caloriesBurnedBasal: ${_this.caloriesBurnedBasal}, weightKg: ${_this.weightKg})';
}


}

/// @nodoc
abstract mixin class $HealthDayTotalsCopyWith<$Res>  {
  factory $HealthDayTotalsCopyWith(HealthDayTotals value, $Res Function(HealthDayTotals) _then) = _$HealthDayTotalsCopyWithImpl;
@useResult
$Res call({
 DateTime date, int? steps, int? caloriesBurnedActive, int? caloriesBurnedBasal, double? weightKg
});




}
/// @nodoc
class _$HealthDayTotalsCopyWithImpl<$Res>
    implements $HealthDayTotalsCopyWith<$Res> {
  _$HealthDayTotalsCopyWithImpl(this._self, this._then);

  final HealthDayTotals _self;
  final $Res Function(HealthDayTotals) _then;

/// Create a copy of HealthDayTotals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? steps = freezed,Object? caloriesBurnedActive = freezed,Object? caloriesBurnedBasal = freezed,Object? weightKg = freezed,}) {
  return _then(HealthDayTotals(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedActive: freezed == caloriesBurnedActive ? _self.caloriesBurnedActive : caloriesBurnedActive // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedBasal: freezed == caloriesBurnedBasal ? _self.caloriesBurnedBasal : caloriesBurnedBasal // ignore: cast_nullable_to_non_nullable
as int?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthDayTotals].
extension HealthDayTotalsPatterns on HealthDayTotals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthDayTotals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthDayTotals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthDayTotals value)  $default,){
final _that = this;
switch (_that) {
case _HealthDayTotals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthDayTotals value)?  $default,){
final _that = this;
switch (_that) {
case _HealthDayTotals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  int? steps,  int? caloriesBurnedActive,  int? caloriesBurnedBasal,  double? weightKg)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthDayTotals() when $default != null:
return $default(_that.date,_that.steps,_that.caloriesBurnedActive,_that.caloriesBurnedBasal,_that.weightKg);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  int? steps,  int? caloriesBurnedActive,  int? caloriesBurnedBasal,  double? weightKg)  $default,) {final _that = this;
switch (_that) {
case _HealthDayTotals():
return $default(_that.date,_that.steps,_that.caloriesBurnedActive,_that.caloriesBurnedBasal,_that.weightKg);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  int? steps,  int? caloriesBurnedActive,  int? caloriesBurnedBasal,  double? weightKg)?  $default,) {final _that = this;
switch (_that) {
case _HealthDayTotals() when $default != null:
return $default(_that.date,_that.steps,_that.caloriesBurnedActive,_that.caloriesBurnedBasal,_that.weightKg);case _:
  return null;

}
}

}

/// @nodoc


class _HealthDayTotals extends HealthDayTotals {
  const _HealthDayTotals({required this.date, this.steps, this.caloriesBurnedActive, this.caloriesBurnedBasal, this.weightKg}): super._();
  

/// The day, at local midnight.
@override final  DateTime date;
/// Summed `stepCount`.
@override final  int? steps;
/// Summed `activeEnergyBurned`, rounded to whole kcal.
@override final  int? caloriesBurnedActive;
/// Summed `basalEnergyBurned`, rounded to whole kcal.
@override final  int? caloriesBurnedBasal;
/// The day's most recent `bodyMass` reading, in kilograms. Not a sum,
/// and not smoothed: see `weightTrendKg` for the trend.
@override final  double? weightKg;

/// Create a copy of HealthDayTotals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthDayTotalsCopyWith<_HealthDayTotals> get copyWith => __$HealthDayTotalsCopyWithImpl<_HealthDayTotals>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthDayTotals&&(identical(other.date, date) || other.date == date)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.caloriesBurnedActive, caloriesBurnedActive) || other.caloriesBurnedActive == caloriesBurnedActive)&&(identical(other.caloriesBurnedBasal, caloriesBurnedBasal) || other.caloriesBurnedBasal == caloriesBurnedBasal)&&(identical(other.weightKg, weightKg) || other.weightKg == weightKg));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date,steps,caloriesBurnedActive,caloriesBurnedBasal,weightKg);
}

@override
String toString() {
    return 'HealthDayTotals(date: $date, steps: $steps, caloriesBurnedActive: $caloriesBurnedActive, caloriesBurnedBasal: $caloriesBurnedBasal, weightKg: $weightKg)';
}


}

/// @nodoc
abstract mixin class _$HealthDayTotalsCopyWith<$Res> implements $HealthDayTotalsCopyWith<$Res> {
  factory _$HealthDayTotalsCopyWith(_HealthDayTotals value, $Res Function(_HealthDayTotals) _then) = __$HealthDayTotalsCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, int? steps, int? caloriesBurnedActive, int? caloriesBurnedBasal, double? weightKg
});




}
/// @nodoc
class __$HealthDayTotalsCopyWithImpl<$Res>
    implements _$HealthDayTotalsCopyWith<$Res> {
  __$HealthDayTotalsCopyWithImpl(this._self, this._then);

  final _HealthDayTotals _self;
  final $Res Function(_HealthDayTotals) _then;

/// Create a copy of HealthDayTotals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? steps = freezed,Object? caloriesBurnedActive = freezed,Object? caloriesBurnedBasal = freezed,Object? weightKg = freezed,}) {
  return _then(_HealthDayTotals(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedActive: freezed == caloriesBurnedActive ? _self.caloriesBurnedActive : caloriesBurnedActive // ignore: cast_nullable_to_non_nullable
as int?,caloriesBurnedBasal: freezed == caloriesBurnedBasal ? _self.caloriesBurnedBasal : caloriesBurnedBasal // ignore: cast_nullable_to_non_nullable
as int?,weightKg: freezed == weightKg ? _self.weightKg : weightKg // ignore: cast_nullable_to_non_nullable
as double?,
  ));
}


}

// dart format on
