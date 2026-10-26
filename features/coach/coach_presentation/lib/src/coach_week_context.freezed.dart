// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_week_context.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoachDayData {

/// The day, at local midnight.
 DateTime get date;/// The end-of-day check-in, or `null` if there was none (or it
/// couldn't be read: see [checkInUnreadable]).
 CheckInStatus? get status;/// Whether this day's check-in couldn't be read, so `null` [status]
/// isn't a day without one.
 bool get checkInUnreadable;/// Calories eaten (from a Cal AI import), or `null` if none.
 int? get caloriesEaten;/// Steps from Apple Health, or `null` if unknown.
 int? get steps;/// Active energy from Apple Health, kcal, or `null` if unknown.
 int? get activeEnergy;/// Basal (resting) energy from Apple Health, kcal, or `null`.
 int? get basalEnergy;
/// Create a copy of CoachDayData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachDayDataCopyWith<CoachDayData> get copyWith => _$CoachDayDataCopyWithImpl<CoachDayData>(this as CoachDayData, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachDayData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachDayData&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.checkInUnreadable, _this.checkInUnreadable) || other.checkInUnreadable == _this.checkInUnreadable)&&(identical(other.caloriesEaten, _this.caloriesEaten) || other.caloriesEaten == _this.caloriesEaten)&&(identical(other.steps, _this.steps) || other.steps == _this.steps)&&(identical(other.activeEnergy, _this.activeEnergy) || other.activeEnergy == _this.activeEnergy)&&(identical(other.basalEnergy, _this.basalEnergy) || other.basalEnergy == _this.basalEnergy));
}


@override
int get hashCode {
  final _this = this as CoachDayData;
  return Object.hash(runtimeType,_this.date,_this.status,_this.checkInUnreadable,_this.caloriesEaten,_this.steps,_this.activeEnergy,_this.basalEnergy);
}

@override
String toString() {
  final _this = this as CoachDayData;
  return 'CoachDayData(date: ${_this.date}, status: ${_this.status}, checkInUnreadable: ${_this.checkInUnreadable}, caloriesEaten: ${_this.caloriesEaten}, steps: ${_this.steps}, activeEnergy: ${_this.activeEnergy}, basalEnergy: ${_this.basalEnergy})';
}


}

/// @nodoc
abstract mixin class $CoachDayDataCopyWith<$Res>  {
  factory $CoachDayDataCopyWith(CoachDayData value, $Res Function(CoachDayData) _then) = _$CoachDayDataCopyWithImpl;
@useResult
$Res call({
 DateTime date, CheckInStatus? status, bool checkInUnreadable, int? caloriesEaten, int? steps, int? activeEnergy, int? basalEnergy
});




}
/// @nodoc
class _$CoachDayDataCopyWithImpl<$Res>
    implements $CoachDayDataCopyWith<$Res> {
  _$CoachDayDataCopyWithImpl(this._self, this._then);

  final CoachDayData _self;
  final $Res Function(CoachDayData) _then;

/// Create a copy of CoachDayData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? status = freezed,Object? checkInUnreadable = null,Object? caloriesEaten = freezed,Object? steps = freezed,Object? activeEnergy = freezed,Object? basalEnergy = freezed,}) {
  return _then(CoachDayData(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CheckInStatus?,checkInUnreadable: null == checkInUnreadable ? _self.checkInUnreadable : checkInUnreadable // ignore: cast_nullable_to_non_nullable
as bool,caloriesEaten: freezed == caloriesEaten ? _self.caloriesEaten : caloriesEaten // ignore: cast_nullable_to_non_nullable
as int?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,activeEnergy: freezed == activeEnergy ? _self.activeEnergy : activeEnergy // ignore: cast_nullable_to_non_nullable
as int?,basalEnergy: freezed == basalEnergy ? _self.basalEnergy : basalEnergy // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachDayData].
extension CoachDayDataPatterns on CoachDayData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachDayData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachDayData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachDayData value)  $default,){
final _that = this;
switch (_that) {
case _CoachDayData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachDayData value)?  $default,){
final _that = this;
switch (_that) {
case _CoachDayData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  CheckInStatus? status,  bool checkInUnreadable,  int? caloriesEaten,  int? steps,  int? activeEnergy,  int? basalEnergy)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachDayData() when $default != null:
return $default(_that.date,_that.status,_that.checkInUnreadable,_that.caloriesEaten,_that.steps,_that.activeEnergy,_that.basalEnergy);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  CheckInStatus? status,  bool checkInUnreadable,  int? caloriesEaten,  int? steps,  int? activeEnergy,  int? basalEnergy)  $default,) {final _that = this;
switch (_that) {
case _CoachDayData():
return $default(_that.date,_that.status,_that.checkInUnreadable,_that.caloriesEaten,_that.steps,_that.activeEnergy,_that.basalEnergy);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  CheckInStatus? status,  bool checkInUnreadable,  int? caloriesEaten,  int? steps,  int? activeEnergy,  int? basalEnergy)?  $default,) {final _that = this;
switch (_that) {
case _CoachDayData() when $default != null:
return $default(_that.date,_that.status,_that.checkInUnreadable,_that.caloriesEaten,_that.steps,_that.activeEnergy,_that.basalEnergy);case _:
  return null;

}
}

}

/// @nodoc


class _CoachDayData implements CoachDayData {
  const _CoachDayData({required this.date, this.status, this.checkInUnreadable = false, this.caloriesEaten, this.steps, this.activeEnergy, this.basalEnergy});
  

/// The day, at local midnight.
@override final  DateTime date;
/// The end-of-day check-in, or `null` if there was none (or it
/// couldn't be read: see [checkInUnreadable]).
@override final  CheckInStatus? status;
/// Whether this day's check-in couldn't be read, so `null` [status]
/// isn't a day without one.
@override@JsonKey() final  bool checkInUnreadable;
/// Calories eaten (from a Cal AI import), or `null` if none.
@override final  int? caloriesEaten;
/// Steps from Apple Health, or `null` if unknown.
@override final  int? steps;
/// Active energy from Apple Health, kcal, or `null` if unknown.
@override final  int? activeEnergy;
/// Basal (resting) energy from Apple Health, kcal, or `null`.
@override final  int? basalEnergy;

/// Create a copy of CoachDayData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachDayDataCopyWith<_CoachDayData> get copyWith => __$CoachDayDataCopyWithImpl<_CoachDayData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachDayData&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.checkInUnreadable, checkInUnreadable) || other.checkInUnreadable == checkInUnreadable)&&(identical(other.caloriesEaten, caloriesEaten) || other.caloriesEaten == caloriesEaten)&&(identical(other.steps, steps) || other.steps == steps)&&(identical(other.activeEnergy, activeEnergy) || other.activeEnergy == activeEnergy)&&(identical(other.basalEnergy, basalEnergy) || other.basalEnergy == basalEnergy));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date,status,checkInUnreadable,caloriesEaten,steps,activeEnergy,basalEnergy);
}

@override
String toString() {
    return 'CoachDayData(date: $date, status: $status, checkInUnreadable: $checkInUnreadable, caloriesEaten: $caloriesEaten, steps: $steps, activeEnergy: $activeEnergy, basalEnergy: $basalEnergy)';
}


}

/// @nodoc
abstract mixin class _$CoachDayDataCopyWith<$Res> implements $CoachDayDataCopyWith<$Res> {
  factory _$CoachDayDataCopyWith(_CoachDayData value, $Res Function(_CoachDayData) _then) = __$CoachDayDataCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, CheckInStatus? status, bool checkInUnreadable, int? caloriesEaten, int? steps, int? activeEnergy, int? basalEnergy
});




}
/// @nodoc
class __$CoachDayDataCopyWithImpl<$Res>
    implements _$CoachDayDataCopyWith<$Res> {
  __$CoachDayDataCopyWithImpl(this._self, this._then);

  final _CoachDayData _self;
  final $Res Function(_CoachDayData) _then;

/// Create a copy of CoachDayData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? status = freezed,Object? checkInUnreadable = null,Object? caloriesEaten = freezed,Object? steps = freezed,Object? activeEnergy = freezed,Object? basalEnergy = freezed,}) {
  return _then(_CoachDayData(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CheckInStatus?,checkInUnreadable: null == checkInUnreadable ? _self.checkInUnreadable : checkInUnreadable // ignore: cast_nullable_to_non_nullable
as bool,caloriesEaten: freezed == caloriesEaten ? _self.caloriesEaten : caloriesEaten // ignore: cast_nullable_to_non_nullable
as int?,steps: freezed == steps ? _self.steps : steps // ignore: cast_nullable_to_non_nullable
as int?,activeEnergy: freezed == activeEnergy ? _self.activeEnergy : activeEnergy // ignore: cast_nullable_to_non_nullable
as int?,basalEnergy: freezed == basalEnergy ? _self.basalEnergy : basalEnergy // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

/// @nodoc
mixin _$CoachWeekData {

/// Every day in the window, oldest first.
 List<CoachDayData> get days;/// Today, at local midnight. Today's line may be incomplete.
 DateTime get today;/// Whether check-in statuses could be read.
 bool get checkInsRead;/// Whether calories eaten could be read.
 bool get caloriesRead;/// Whether Apple Health could be read (`false` where there's none).
 bool get healthRead;/// Whether craving check-ins could be read.
 bool get cravingsRead;/// How many craving check-ins started in the window.
 int get cravingCount;/// When they started, by part of the day.
 Map<CravingTimeOfDay, int> get cravingTimes;/// What was behind them, if the person said (one event can have
/// several). Only the weekly session shows these.
 Map<CravingReason, int> get cravingReasons;
/// Create a copy of CoachWeekData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachWeekDataCopyWith<CoachWeekData> get copyWith => _$CoachWeekDataCopyWithImpl<CoachWeekData>(this as CoachWeekData, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachWeekData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachWeekData&&const DeepCollectionEquality().equals(other.days, _this.days)&&(identical(other.today, _this.today) || other.today == _this.today)&&(identical(other.checkInsRead, _this.checkInsRead) || other.checkInsRead == _this.checkInsRead)&&(identical(other.caloriesRead, _this.caloriesRead) || other.caloriesRead == _this.caloriesRead)&&(identical(other.healthRead, _this.healthRead) || other.healthRead == _this.healthRead)&&(identical(other.cravingsRead, _this.cravingsRead) || other.cravingsRead == _this.cravingsRead)&&(identical(other.cravingCount, _this.cravingCount) || other.cravingCount == _this.cravingCount)&&const DeepCollectionEquality().equals(other.cravingTimes, _this.cravingTimes)&&const DeepCollectionEquality().equals(other.cravingReasons, _this.cravingReasons));
}


@override
int get hashCode {
  final _this = this as CoachWeekData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.days),_this.today,_this.checkInsRead,_this.caloriesRead,_this.healthRead,_this.cravingsRead,_this.cravingCount,const DeepCollectionEquality().hash(_this.cravingTimes),const DeepCollectionEquality().hash(_this.cravingReasons));
}

@override
String toString() {
  final _this = this as CoachWeekData;
  return 'CoachWeekData(days: ${_this.days}, today: ${_this.today}, checkInsRead: ${_this.checkInsRead}, caloriesRead: ${_this.caloriesRead}, healthRead: ${_this.healthRead}, cravingsRead: ${_this.cravingsRead}, cravingCount: ${_this.cravingCount}, cravingTimes: ${_this.cravingTimes}, cravingReasons: ${_this.cravingReasons})';
}


}

/// @nodoc
abstract mixin class $CoachWeekDataCopyWith<$Res>  {
  factory $CoachWeekDataCopyWith(CoachWeekData value, $Res Function(CoachWeekData) _then) = _$CoachWeekDataCopyWithImpl;
@useResult
$Res call({
 List<CoachDayData> days, DateTime today, bool checkInsRead, bool caloriesRead, bool healthRead, bool cravingsRead, int cravingCount, Map<CravingTimeOfDay, int> cravingTimes, Map<CravingReason, int> cravingReasons
});




}
/// @nodoc
class _$CoachWeekDataCopyWithImpl<$Res>
    implements $CoachWeekDataCopyWith<$Res> {
  _$CoachWeekDataCopyWithImpl(this._self, this._then);

  final CoachWeekData _self;
  final $Res Function(CoachWeekData) _then;

/// Create a copy of CoachWeekData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? days = null,Object? today = null,Object? checkInsRead = null,Object? caloriesRead = null,Object? healthRead = null,Object? cravingsRead = null,Object? cravingCount = null,Object? cravingTimes = null,Object? cravingReasons = null,}) {
  return _then(CoachWeekData(
days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<CoachDayData>,today: null == today ? _self.today : today // ignore: cast_nullable_to_non_nullable
as DateTime,checkInsRead: null == checkInsRead ? _self.checkInsRead : checkInsRead // ignore: cast_nullable_to_non_nullable
as bool,caloriesRead: null == caloriesRead ? _self.caloriesRead : caloriesRead // ignore: cast_nullable_to_non_nullable
as bool,healthRead: null == healthRead ? _self.healthRead : healthRead // ignore: cast_nullable_to_non_nullable
as bool,cravingsRead: null == cravingsRead ? _self.cravingsRead : cravingsRead // ignore: cast_nullable_to_non_nullable
as bool,cravingCount: null == cravingCount ? _self.cravingCount : cravingCount // ignore: cast_nullable_to_non_nullable
as int,cravingTimes: null == cravingTimes ? _self.cravingTimes : cravingTimes // ignore: cast_nullable_to_non_nullable
as Map<CravingTimeOfDay, int>,cravingReasons: null == cravingReasons ? _self.cravingReasons : cravingReasons // ignore: cast_nullable_to_non_nullable
as Map<CravingReason, int>,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachWeekData].
extension CoachWeekDataPatterns on CoachWeekData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachWeekData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachWeekData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachWeekData value)  $default,){
final _that = this;
switch (_that) {
case _CoachWeekData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachWeekData value)?  $default,){
final _that = this;
switch (_that) {
case _CoachWeekData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<CoachDayData> days,  DateTime today,  bool checkInsRead,  bool caloriesRead,  bool healthRead,  bool cravingsRead,  int cravingCount,  Map<CravingTimeOfDay, int> cravingTimes,  Map<CravingReason, int> cravingReasons)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachWeekData() when $default != null:
return $default(_that.days,_that.today,_that.checkInsRead,_that.caloriesRead,_that.healthRead,_that.cravingsRead,_that.cravingCount,_that.cravingTimes,_that.cravingReasons);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<CoachDayData> days,  DateTime today,  bool checkInsRead,  bool caloriesRead,  bool healthRead,  bool cravingsRead,  int cravingCount,  Map<CravingTimeOfDay, int> cravingTimes,  Map<CravingReason, int> cravingReasons)  $default,) {final _that = this;
switch (_that) {
case _CoachWeekData():
return $default(_that.days,_that.today,_that.checkInsRead,_that.caloriesRead,_that.healthRead,_that.cravingsRead,_that.cravingCount,_that.cravingTimes,_that.cravingReasons);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<CoachDayData> days,  DateTime today,  bool checkInsRead,  bool caloriesRead,  bool healthRead,  bool cravingsRead,  int cravingCount,  Map<CravingTimeOfDay, int> cravingTimes,  Map<CravingReason, int> cravingReasons)?  $default,) {final _that = this;
switch (_that) {
case _CoachWeekData() when $default != null:
return $default(_that.days,_that.today,_that.checkInsRead,_that.caloriesRead,_that.healthRead,_that.cravingsRead,_that.cravingCount,_that.cravingTimes,_that.cravingReasons);case _:
  return null;

}
}

}

/// @nodoc


class _CoachWeekData implements CoachWeekData {
  const _CoachWeekData({required  List<CoachDayData> days, required this.today, this.checkInsRead = true, this.caloriesRead = true, this.healthRead = true, this.cravingsRead = true, this.cravingCount = 0,  Map<CravingTimeOfDay, int> cravingTimes = const <CravingTimeOfDay, int>{},  Map<CravingReason, int> cravingReasons = const <CravingReason, int>{}}): _days = days,_cravingTimes = cravingTimes,_cravingReasons = cravingReasons;
  

/// Every day in the window, oldest first.
 final  List<CoachDayData> _days;
/// Every day in the window, oldest first.
@override List<CoachDayData> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}

/// Today, at local midnight. Today's line may be incomplete.
@override final  DateTime today;
/// Whether check-in statuses could be read.
@override@JsonKey() final  bool checkInsRead;
/// Whether calories eaten could be read.
@override@JsonKey() final  bool caloriesRead;
/// Whether Apple Health could be read (`false` where there's none).
@override@JsonKey() final  bool healthRead;
/// Whether craving check-ins could be read.
@override@JsonKey() final  bool cravingsRead;
/// How many craving check-ins started in the window.
@override@JsonKey() final  int cravingCount;
/// When they started, by part of the day.
 final  Map<CravingTimeOfDay, int> _cravingTimes;
/// When they started, by part of the day.
@override@JsonKey() Map<CravingTimeOfDay, int> get cravingTimes {
  if (_cravingTimes is EqualUnmodifiableMapView) return _cravingTimes;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_cravingTimes);
}

/// What was behind them, if the person said (one event can have
/// several). Only the weekly session shows these.
 final  Map<CravingReason, int> _cravingReasons;
/// What was behind them, if the person said (one event can have
/// several). Only the weekly session shows these.
@override@JsonKey() Map<CravingReason, int> get cravingReasons {
  if (_cravingReasons is EqualUnmodifiableMapView) return _cravingReasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_cravingReasons);
}


/// Create a copy of CoachWeekData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachWeekDataCopyWith<_CoachWeekData> get copyWith => __$CoachWeekDataCopyWithImpl<_CoachWeekData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachWeekData&&const DeepCollectionEquality().equals(other.days, _days)&&(identical(other.today, today) || other.today == today)&&(identical(other.checkInsRead, checkInsRead) || other.checkInsRead == checkInsRead)&&(identical(other.caloriesRead, caloriesRead) || other.caloriesRead == caloriesRead)&&(identical(other.healthRead, healthRead) || other.healthRead == healthRead)&&(identical(other.cravingsRead, cravingsRead) || other.cravingsRead == cravingsRead)&&(identical(other.cravingCount, cravingCount) || other.cravingCount == cravingCount)&&const DeepCollectionEquality().equals(other.cravingTimes, _cravingTimes)&&const DeepCollectionEquality().equals(other.cravingReasons, _cravingReasons));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_days),today,checkInsRead,caloriesRead,healthRead,cravingsRead,cravingCount,const DeepCollectionEquality().hash(_cravingTimes),const DeepCollectionEquality().hash(_cravingReasons));
}

@override
String toString() {
    return 'CoachWeekData(days: $days, today: $today, checkInsRead: $checkInsRead, caloriesRead: $caloriesRead, healthRead: $healthRead, cravingsRead: $cravingsRead, cravingCount: $cravingCount, cravingTimes: $cravingTimes, cravingReasons: $cravingReasons)';
}


}

/// @nodoc
abstract mixin class _$CoachWeekDataCopyWith<$Res> implements $CoachWeekDataCopyWith<$Res> {
  factory _$CoachWeekDataCopyWith(_CoachWeekData value, $Res Function(_CoachWeekData) _then) = __$CoachWeekDataCopyWithImpl;
@override @useResult
$Res call({
 List<CoachDayData> days, DateTime today, bool checkInsRead, bool caloriesRead, bool healthRead, bool cravingsRead, int cravingCount, Map<CravingTimeOfDay, int> cravingTimes, Map<CravingReason, int> cravingReasons
});




}
/// @nodoc
class __$CoachWeekDataCopyWithImpl<$Res>
    implements _$CoachWeekDataCopyWith<$Res> {
  __$CoachWeekDataCopyWithImpl(this._self, this._then);

  final _CoachWeekData _self;
  final $Res Function(_CoachWeekData) _then;

/// Create a copy of CoachWeekData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? days = null,Object? today = null,Object? checkInsRead = null,Object? caloriesRead = null,Object? healthRead = null,Object? cravingsRead = null,Object? cravingCount = null,Object? cravingTimes = null,Object? cravingReasons = null,}) {
  return _then(_CoachWeekData(
days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<CoachDayData>,today: null == today ? _self.today : today // ignore: cast_nullable_to_non_nullable
as DateTime,checkInsRead: null == checkInsRead ? _self.checkInsRead : checkInsRead // ignore: cast_nullable_to_non_nullable
as bool,caloriesRead: null == caloriesRead ? _self.caloriesRead : caloriesRead // ignore: cast_nullable_to_non_nullable
as bool,healthRead: null == healthRead ? _self.healthRead : healthRead // ignore: cast_nullable_to_non_nullable
as bool,cravingsRead: null == cravingsRead ? _self.cravingsRead : cravingsRead // ignore: cast_nullable_to_non_nullable
as bool,cravingCount: null == cravingCount ? _self.cravingCount : cravingCount // ignore: cast_nullable_to_non_nullable
as int,cravingTimes: null == cravingTimes ? _self._cravingTimes : cravingTimes // ignore: cast_nullable_to_non_nullable
as Map<CravingTimeOfDay, int>,cravingReasons: null == cravingReasons ? _self._cravingReasons : cravingReasons // ignore: cast_nullable_to_non_nullable
as Map<CravingReason, int>,
  ));
}


}

// dart format on
