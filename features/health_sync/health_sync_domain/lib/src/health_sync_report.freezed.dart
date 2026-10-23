// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'health_sync_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$HealthSyncReport {

/// Days whose `DailyMetric` row was written: a Health value was new or
/// had changed. Unchanged days aren't written, so this is 0 on a
/// repeat sync with nothing new.
 int get daysUpdated;/// Days in the window where Health had any of the three values. 0 means
/// Health returned nothing at all, which is also what it returns when
/// the user didn't allow read access (HealthKit doesn't say which).
 int get daysWithData;
/// Create a copy of HealthSyncReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$HealthSyncReportCopyWith<HealthSyncReport> get copyWith => _$HealthSyncReportCopyWithImpl<HealthSyncReport>(this as HealthSyncReport, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as HealthSyncReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is HealthSyncReport&&(identical(other.daysUpdated, _this.daysUpdated) || other.daysUpdated == _this.daysUpdated)&&(identical(other.daysWithData, _this.daysWithData) || other.daysWithData == _this.daysWithData));
}


@override
int get hashCode {
  final _this = this as HealthSyncReport;
  return Object.hash(runtimeType,_this.daysUpdated,_this.daysWithData);
}

@override
String toString() {
  final _this = this as HealthSyncReport;
  return 'HealthSyncReport(daysUpdated: ${_this.daysUpdated}, daysWithData: ${_this.daysWithData})';
}


}

/// @nodoc
abstract mixin class $HealthSyncReportCopyWith<$Res>  {
  factory $HealthSyncReportCopyWith(HealthSyncReport value, $Res Function(HealthSyncReport) _then) = _$HealthSyncReportCopyWithImpl;
@useResult
$Res call({
 int daysUpdated, int daysWithData
});




}
/// @nodoc
class _$HealthSyncReportCopyWithImpl<$Res>
    implements $HealthSyncReportCopyWith<$Res> {
  _$HealthSyncReportCopyWithImpl(this._self, this._then);

  final HealthSyncReport _self;
  final $Res Function(HealthSyncReport) _then;

/// Create a copy of HealthSyncReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? daysUpdated = null,Object? daysWithData = null,}) {
  return _then(HealthSyncReport(
daysUpdated: null == daysUpdated ? _self.daysUpdated : daysUpdated // ignore: cast_nullable_to_non_nullable
as int,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [HealthSyncReport].
extension HealthSyncReportPatterns on HealthSyncReport {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _HealthSyncReport value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _HealthSyncReport() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _HealthSyncReport value)  $default,){
final _that = this;
switch (_that) {
case _HealthSyncReport():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _HealthSyncReport value)?  $default,){
final _that = this;
switch (_that) {
case _HealthSyncReport() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int daysUpdated,  int daysWithData)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _HealthSyncReport() when $default != null:
return $default(_that.daysUpdated,_that.daysWithData);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int daysUpdated,  int daysWithData)  $default,) {final _that = this;
switch (_that) {
case _HealthSyncReport():
return $default(_that.daysUpdated,_that.daysWithData);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int daysUpdated,  int daysWithData)?  $default,) {final _that = this;
switch (_that) {
case _HealthSyncReport() when $default != null:
return $default(_that.daysUpdated,_that.daysWithData);case _:
  return null;

}
}

}

/// @nodoc


class _HealthSyncReport implements HealthSyncReport {
  const _HealthSyncReport({required this.daysUpdated, required this.daysWithData});
  

/// Days whose `DailyMetric` row was written: a Health value was new or
/// had changed. Unchanged days aren't written, so this is 0 on a
/// repeat sync with nothing new.
@override final  int daysUpdated;
/// Days in the window where Health had any of the three values. 0 means
/// Health returned nothing at all, which is also what it returns when
/// the user didn't allow read access (HealthKit doesn't say which).
@override final  int daysWithData;

/// Create a copy of HealthSyncReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$HealthSyncReportCopyWith<_HealthSyncReport> get copyWith => __$HealthSyncReportCopyWithImpl<_HealthSyncReport>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _HealthSyncReport&&(identical(other.daysUpdated, daysUpdated) || other.daysUpdated == daysUpdated)&&(identical(other.daysWithData, daysWithData) || other.daysWithData == daysWithData));
}


@override
int get hashCode {
    return Object.hash(runtimeType,daysUpdated,daysWithData);
}

@override
String toString() {
    return 'HealthSyncReport(daysUpdated: $daysUpdated, daysWithData: $daysWithData)';
}


}

/// @nodoc
abstract mixin class _$HealthSyncReportCopyWith<$Res> implements $HealthSyncReportCopyWith<$Res> {
  factory _$HealthSyncReportCopyWith(_HealthSyncReport value, $Res Function(_HealthSyncReport) _then) = __$HealthSyncReportCopyWithImpl;
@override @useResult
$Res call({
 int daysUpdated, int daysWithData
});




}
/// @nodoc
class __$HealthSyncReportCopyWithImpl<$Res>
    implements _$HealthSyncReportCopyWith<$Res> {
  __$HealthSyncReportCopyWithImpl(this._self, this._then);

  final _HealthSyncReport _self;
  final $Res Function(_HealthSyncReport) _then;

/// Create a copy of HealthSyncReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? daysUpdated = null,Object? daysWithData = null,}) {
  return _then(_HealthSyncReport(
daysUpdated: null == daysUpdated ? _self.daysUpdated : daysUpdated // ignore: cast_nullable_to_non_nullable
as int,daysWithData: null == daysWithData ? _self.daysWithData : daysWithData // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
