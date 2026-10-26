// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_weekly_readiness.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeeklyReadiness {

/// The week's Friday, at local midnight.
 DateTime get first;/// The week's Thursday, at local midnight.
 DateTime get last;/// Days in the week with any check-in status.
 int get daysWithCheckIn;/// Whether any of the seven days couldn't be read at all.
///
/// The session's own gate stays permissive about this — an unreadable
/// day counts as no check-in, and only a week where *every* day fails
/// is a failure, so a half-broken store doesn't block a session the
/// person asked for. The Today nudge is the stricter reader: it offers
/// a session unasked, so it stands down on anything it couldn't read
/// (`coachNudgeProvider`).
 bool get anyDayUnreadable;
/// Create a copy of WeeklyReadiness
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WeeklyReadinessCopyWith<WeeklyReadiness> get copyWith => _$WeeklyReadinessCopyWithImpl<WeeklyReadiness>(this as WeeklyReadiness, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as WeeklyReadiness;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyReadiness&&(identical(other.first, _this.first) || other.first == _this.first)&&(identical(other.last, _this.last) || other.last == _this.last)&&(identical(other.daysWithCheckIn, _this.daysWithCheckIn) || other.daysWithCheckIn == _this.daysWithCheckIn)&&(identical(other.anyDayUnreadable, _this.anyDayUnreadable) || other.anyDayUnreadable == _this.anyDayUnreadable));
}


@override
int get hashCode {
  final _this = this as WeeklyReadiness;
  return Object.hash(runtimeType,_this.first,_this.last,_this.daysWithCheckIn,_this.anyDayUnreadable);
}

@override
String toString() {
  final _this = this as WeeklyReadiness;
  return 'WeeklyReadiness(first: ${_this.first}, last: ${_this.last}, daysWithCheckIn: ${_this.daysWithCheckIn}, anyDayUnreadable: ${_this.anyDayUnreadable})';
}


}

/// @nodoc
abstract mixin class $WeeklyReadinessCopyWith<$Res>  {
  factory $WeeklyReadinessCopyWith(WeeklyReadiness value, $Res Function(WeeklyReadiness) _then) = _$WeeklyReadinessCopyWithImpl;
@useResult
$Res call({
 DateTime first, DateTime last, int daysWithCheckIn, bool anyDayUnreadable
});




}
/// @nodoc
class _$WeeklyReadinessCopyWithImpl<$Res>
    implements $WeeklyReadinessCopyWith<$Res> {
  _$WeeklyReadinessCopyWithImpl(this._self, this._then);

  final WeeklyReadiness _self;
  final $Res Function(WeeklyReadiness) _then;

/// Create a copy of WeeklyReadiness
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? first = null,Object? last = null,Object? daysWithCheckIn = null,Object? anyDayUnreadable = null,}) {
  return _then(WeeklyReadiness(
first: null == first ? _self.first : first // ignore: cast_nullable_to_non_nullable
as DateTime,last: null == last ? _self.last : last // ignore: cast_nullable_to_non_nullable
as DateTime,daysWithCheckIn: null == daysWithCheckIn ? _self.daysWithCheckIn : daysWithCheckIn // ignore: cast_nullable_to_non_nullable
as int,anyDayUnreadable: null == anyDayUnreadable ? _self.anyDayUnreadable : anyDayUnreadable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

}


/// Adds pattern-matching-related methods to [WeeklyReadiness].
extension WeeklyReadinessPatterns on WeeklyReadiness {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WeeklyReadiness value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WeeklyReadiness() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WeeklyReadiness value)  $default,){
final _that = this;
switch (_that) {
case _WeeklyReadiness():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WeeklyReadiness value)?  $default,){
final _that = this;
switch (_that) {
case _WeeklyReadiness() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime first,  DateTime last,  int daysWithCheckIn,  bool anyDayUnreadable)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WeeklyReadiness() when $default != null:
return $default(_that.first,_that.last,_that.daysWithCheckIn,_that.anyDayUnreadable);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime first,  DateTime last,  int daysWithCheckIn,  bool anyDayUnreadable)  $default,) {final _that = this;
switch (_that) {
case _WeeklyReadiness():
return $default(_that.first,_that.last,_that.daysWithCheckIn,_that.anyDayUnreadable);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime first,  DateTime last,  int daysWithCheckIn,  bool anyDayUnreadable)?  $default,) {final _that = this;
switch (_that) {
case _WeeklyReadiness() when $default != null:
return $default(_that.first,_that.last,_that.daysWithCheckIn,_that.anyDayUnreadable);case _:
  return null;

}
}

}

/// @nodoc


class _WeeklyReadiness extends WeeklyReadiness {
  const _WeeklyReadiness({required this.first, required this.last, required this.daysWithCheckIn, this.anyDayUnreadable = false}): super._();
  

/// The week's Friday, at local midnight.
@override final  DateTime first;
/// The week's Thursday, at local midnight.
@override final  DateTime last;
/// Days in the week with any check-in status.
@override final  int daysWithCheckIn;
/// Whether any of the seven days couldn't be read at all.
///
/// The session's own gate stays permissive about this — an unreadable
/// day counts as no check-in, and only a week where *every* day fails
/// is a failure, so a half-broken store doesn't block a session the
/// person asked for. The Today nudge is the stricter reader: it offers
/// a session unasked, so it stands down on anything it couldn't read
/// (`coachNudgeProvider`).
@override@JsonKey() final  bool anyDayUnreadable;

/// Create a copy of WeeklyReadiness
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WeeklyReadinessCopyWith<_WeeklyReadiness> get copyWith => __$WeeklyReadinessCopyWithImpl<_WeeklyReadiness>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyReadiness&&(identical(other.first, first) || other.first == first)&&(identical(other.last, last) || other.last == last)&&(identical(other.daysWithCheckIn, daysWithCheckIn) || other.daysWithCheckIn == daysWithCheckIn)&&(identical(other.anyDayUnreadable, anyDayUnreadable) || other.anyDayUnreadable == anyDayUnreadable));
}


@override
int get hashCode {
    return Object.hash(runtimeType,first,last,daysWithCheckIn,anyDayUnreadable);
}

@override
String toString() {
    return 'WeeklyReadiness(first: $first, last: $last, daysWithCheckIn: $daysWithCheckIn, anyDayUnreadable: $anyDayUnreadable)';
}


}

/// @nodoc
abstract mixin class _$WeeklyReadinessCopyWith<$Res> implements $WeeklyReadinessCopyWith<$Res> {
  factory _$WeeklyReadinessCopyWith(_WeeklyReadiness value, $Res Function(_WeeklyReadiness) _then) = __$WeeklyReadinessCopyWithImpl;
@override @useResult
$Res call({
 DateTime first, DateTime last, int daysWithCheckIn, bool anyDayUnreadable
});




}
/// @nodoc
class __$WeeklyReadinessCopyWithImpl<$Res>
    implements _$WeeklyReadinessCopyWith<$Res> {
  __$WeeklyReadinessCopyWithImpl(this._self, this._then);

  final _WeeklyReadiness _self;
  final $Res Function(_WeeklyReadiness) _then;

/// Create a copy of WeeklyReadiness
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? first = null,Object? last = null,Object? daysWithCheckIn = null,Object? anyDayUnreadable = null,}) {
  return _then(_WeeklyReadiness(
first: null == first ? _self.first : first // ignore: cast_nullable_to_non_nullable
as DateTime,last: null == last ? _self.last : last // ignore: cast_nullable_to_non_nullable
as DateTime,daysWithCheckIn: null == daysWithCheckIn ? _self.daysWithCheckIn : daysWithCheckIn // ignore: cast_nullable_to_non_nullable
as int,anyDayUnreadable: null == anyDayUnreadable ? _self.anyDayUnreadable : anyDayUnreadable // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

// dart format on
