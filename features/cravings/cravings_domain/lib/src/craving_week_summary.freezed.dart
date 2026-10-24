// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'craving_week_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CravingWeekSummary {

/// Craving check-ins started in the window.
 int get count;/// The part of the day more than half of them started in, or `null`
/// when no part of the day has a majority (or there were none).
 CravingTimeOfDay? get mostly;
/// Create a copy of CravingWeekSummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CravingWeekSummaryCopyWith<CravingWeekSummary> get copyWith => _$CravingWeekSummaryCopyWithImpl<CravingWeekSummary>(this as CravingWeekSummary, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CravingWeekSummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CravingWeekSummary&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.mostly, _this.mostly) || other.mostly == _this.mostly));
}


@override
int get hashCode {
  final _this = this as CravingWeekSummary;
  return Object.hash(runtimeType,_this.count,_this.mostly);
}

@override
String toString() {
  final _this = this as CravingWeekSummary;
  return 'CravingWeekSummary(count: ${_this.count}, mostly: ${_this.mostly})';
}


}

/// @nodoc
abstract mixin class $CravingWeekSummaryCopyWith<$Res>  {
  factory $CravingWeekSummaryCopyWith(CravingWeekSummary value, $Res Function(CravingWeekSummary) _then) = _$CravingWeekSummaryCopyWithImpl;
@useResult
$Res call({
 int count, CravingTimeOfDay? mostly
});




}
/// @nodoc
class _$CravingWeekSummaryCopyWithImpl<$Res>
    implements $CravingWeekSummaryCopyWith<$Res> {
  _$CravingWeekSummaryCopyWithImpl(this._self, this._then);

  final CravingWeekSummary _self;
  final $Res Function(CravingWeekSummary) _then;

/// Create a copy of CravingWeekSummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? mostly = freezed,}) {
  return _then(CravingWeekSummary(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,mostly: freezed == mostly ? _self.mostly : mostly // ignore: cast_nullable_to_non_nullable
as CravingTimeOfDay?,
  ));
}

}


/// Adds pattern-matching-related methods to [CravingWeekSummary].
extension CravingWeekSummaryPatterns on CravingWeekSummary {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CravingWeekSummary value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CravingWeekSummary() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CravingWeekSummary value)  $default,){
final _that = this;
switch (_that) {
case _CravingWeekSummary():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CravingWeekSummary value)?  $default,){
final _that = this;
switch (_that) {
case _CravingWeekSummary() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  CravingTimeOfDay? mostly)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CravingWeekSummary() when $default != null:
return $default(_that.count,_that.mostly);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  CravingTimeOfDay? mostly)  $default,) {final _that = this;
switch (_that) {
case _CravingWeekSummary():
return $default(_that.count,_that.mostly);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  CravingTimeOfDay? mostly)?  $default,) {final _that = this;
switch (_that) {
case _CravingWeekSummary() when $default != null:
return $default(_that.count,_that.mostly);case _:
  return null;

}
}

}

/// @nodoc


class _CravingWeekSummary implements CravingWeekSummary {
  const _CravingWeekSummary({required this.count, this.mostly});
  

/// Craving check-ins started in the window.
@override final  int count;
/// The part of the day more than half of them started in, or `null`
/// when no part of the day has a majority (or there were none).
@override final  CravingTimeOfDay? mostly;

/// Create a copy of CravingWeekSummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CravingWeekSummaryCopyWith<_CravingWeekSummary> get copyWith => __$CravingWeekSummaryCopyWithImpl<_CravingWeekSummary>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CravingWeekSummary&&(identical(other.count, count) || other.count == count)&&(identical(other.mostly, mostly) || other.mostly == mostly));
}


@override
int get hashCode {
    return Object.hash(runtimeType,count,mostly);
}

@override
String toString() {
    return 'CravingWeekSummary(count: $count, mostly: $mostly)';
}


}

/// @nodoc
abstract mixin class _$CravingWeekSummaryCopyWith<$Res> implements $CravingWeekSummaryCopyWith<$Res> {
  factory _$CravingWeekSummaryCopyWith(_CravingWeekSummary value, $Res Function(_CravingWeekSummary) _then) = __$CravingWeekSummaryCopyWithImpl;
@override @useResult
$Res call({
 int count, CravingTimeOfDay? mostly
});




}
/// @nodoc
class __$CravingWeekSummaryCopyWithImpl<$Res>
    implements _$CravingWeekSummaryCopyWith<$Res> {
  __$CravingWeekSummaryCopyWithImpl(this._self, this._then);

  final _CravingWeekSummary _self;
  final $Res Function(_CravingWeekSummary) _then;

/// Create a copy of CravingWeekSummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? mostly = freezed,}) {
  return _then(_CravingWeekSummary(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,mostly: freezed == mostly ? _self.mostly : mostly // ignore: cast_nullable_to_non_nullable
as CravingTimeOfDay?,
  ));
}


}

// dart format on
