// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_day.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParsedDay {

/// The day this data belongs to.
 DateTime get date;/// The day's aggregate calorie total — the only field that lands in
/// SwiftData; individual food entries are not persisted.
 int get caloriesEaten;/// This day's individual food entries, kept only for an in-session
/// review screen.
 List<ParsedFoodEntry> get foodEntries;
/// Create a copy of ParsedDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedDayCopyWith<ParsedDay> get copyWith => _$ParsedDayCopyWithImpl<ParsedDay>(this as ParsedDay, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ParsedDay;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedDay&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.caloriesEaten, _this.caloriesEaten) || other.caloriesEaten == _this.caloriesEaten)&&const DeepCollectionEquality().equals(other.foodEntries, _this.foodEntries));
}


@override
int get hashCode {
  final _this = this as ParsedDay;
  return Object.hash(runtimeType,_this.date,_this.caloriesEaten,const DeepCollectionEquality().hash(_this.foodEntries));
}

@override
String toString() {
  final _this = this as ParsedDay;
  return 'ParsedDay(date: ${_this.date}, caloriesEaten: ${_this.caloriesEaten}, foodEntries: ${_this.foodEntries})';
}


}

/// @nodoc
abstract mixin class $ParsedDayCopyWith<$Res>  {
  factory $ParsedDayCopyWith(ParsedDay value, $Res Function(ParsedDay) _then) = _$ParsedDayCopyWithImpl;
@useResult
$Res call({
 DateTime date, int caloriesEaten, List<ParsedFoodEntry> foodEntries
});




}
/// @nodoc
class _$ParsedDayCopyWithImpl<$Res>
    implements $ParsedDayCopyWith<$Res> {
  _$ParsedDayCopyWithImpl(this._self, this._then);

  final ParsedDay _self;
  final $Res Function(ParsedDay) _then;

/// Create a copy of ParsedDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? caloriesEaten = null,Object? foodEntries = null,}) {
  return _then(ParsedDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,caloriesEaten: null == caloriesEaten ? _self.caloriesEaten : caloriesEaten // ignore: cast_nullable_to_non_nullable
as int,foodEntries: null == foodEntries ? _self.foodEntries : foodEntries // ignore: cast_nullable_to_non_nullable
as List<ParsedFoodEntry>,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedDay].
extension ParsedDayPatterns on ParsedDay {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedDay value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedDay() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedDay value)  $default,){
final _that = this;
switch (_that) {
case _ParsedDay():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedDay value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedDay() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime date,  int caloriesEaten,  List<ParsedFoodEntry> foodEntries)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedDay() when $default != null:
return $default(_that.date,_that.caloriesEaten,_that.foodEntries);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime date,  int caloriesEaten,  List<ParsedFoodEntry> foodEntries)  $default,) {final _that = this;
switch (_that) {
case _ParsedDay():
return $default(_that.date,_that.caloriesEaten,_that.foodEntries);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime date,  int caloriesEaten,  List<ParsedFoodEntry> foodEntries)?  $default,) {final _that = this;
switch (_that) {
case _ParsedDay() when $default != null:
return $default(_that.date,_that.caloriesEaten,_that.foodEntries);case _:
  return null;

}
}

}

/// @nodoc


class _ParsedDay implements ParsedDay {
  const _ParsedDay({required this.date, required this.caloriesEaten, required  List<ParsedFoodEntry> foodEntries}): _foodEntries = foodEntries;
  

/// The day this data belongs to.
@override final  DateTime date;
/// The day's aggregate calorie total — the only field that lands in
/// SwiftData; individual food entries are not persisted.
@override final  int caloriesEaten;
/// This day's individual food entries, kept only for an in-session
/// review screen.
 final  List<ParsedFoodEntry> _foodEntries;
/// This day's individual food entries, kept only for an in-session
/// review screen.
@override List<ParsedFoodEntry> get foodEntries {
  if (_foodEntries is EqualUnmodifiableListView) return _foodEntries;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_foodEntries);
}


/// Create a copy of ParsedDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedDayCopyWith<_ParsedDay> get copyWith => __$ParsedDayCopyWithImpl<_ParsedDay>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedDay&&(identical(other.date, date) || other.date == date)&&(identical(other.caloriesEaten, caloriesEaten) || other.caloriesEaten == caloriesEaten)&&const DeepCollectionEquality().equals(other.foodEntries, _foodEntries));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date,caloriesEaten,const DeepCollectionEquality().hash(_foodEntries));
}

@override
String toString() {
    return 'ParsedDay(date: $date, caloriesEaten: $caloriesEaten, foodEntries: $foodEntries)';
}


}

/// @nodoc
abstract mixin class _$ParsedDayCopyWith<$Res> implements $ParsedDayCopyWith<$Res> {
  factory _$ParsedDayCopyWith(_ParsedDay value, $Res Function(_ParsedDay) _then) = __$ParsedDayCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, int caloriesEaten, List<ParsedFoodEntry> foodEntries
});




}
/// @nodoc
class __$ParsedDayCopyWithImpl<$Res>
    implements _$ParsedDayCopyWith<$Res> {
  __$ParsedDayCopyWithImpl(this._self, this._then);

  final _ParsedDay _self;
  final $Res Function(_ParsedDay) _then;

/// Create a copy of ParsedDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? caloriesEaten = null,Object? foodEntries = null,}) {
  return _then(_ParsedDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,caloriesEaten: null == caloriesEaten ? _self.caloriesEaten : caloriesEaten // ignore: cast_nullable_to_non_nullable
as int,foodEntries: null == foodEntries ? _self._foodEntries : foodEntries // ignore: cast_nullable_to_non_nullable
as List<ParsedFoodEntry>,
  ));
}


}

// dart format on
