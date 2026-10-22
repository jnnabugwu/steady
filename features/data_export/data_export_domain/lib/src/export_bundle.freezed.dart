// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_bundle.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportBundle {

/// When the export was made. Written to the JSON as UTC ISO 8601, and
/// its local calendar date names the file.
 DateTime get exportedAt;/// The rows to export, in any order: both encoders sort by date.
 List<DailyMetric> get dailyMetrics;
/// Create a copy of ExportBundle
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportBundleCopyWith<ExportBundle> get copyWith => _$ExportBundleCopyWithImpl<ExportBundle>(this as ExportBundle, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExportBundle;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportBundle&&(identical(other.exportedAt, _this.exportedAt) || other.exportedAt == _this.exportedAt)&&const DeepCollectionEquality().equals(other.dailyMetrics, _this.dailyMetrics));
}


@override
int get hashCode {
  final _this = this as ExportBundle;
  return Object.hash(runtimeType,_this.exportedAt,const DeepCollectionEquality().hash(_this.dailyMetrics));
}

@override
String toString() {
  final _this = this as ExportBundle;
  return 'ExportBundle(exportedAt: ${_this.exportedAt}, dailyMetrics: ${_this.dailyMetrics})';
}


}

/// @nodoc
abstract mixin class $ExportBundleCopyWith<$Res>  {
  factory $ExportBundleCopyWith(ExportBundle value, $Res Function(ExportBundle) _then) = _$ExportBundleCopyWithImpl;
@useResult
$Res call({
 DateTime exportedAt, List<DailyMetric> dailyMetrics
});




}
/// @nodoc
class _$ExportBundleCopyWithImpl<$Res>
    implements $ExportBundleCopyWith<$Res> {
  _$ExportBundleCopyWithImpl(this._self, this._then);

  final ExportBundle _self;
  final $Res Function(ExportBundle) _then;

/// Create a copy of ExportBundle
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? exportedAt = null,Object? dailyMetrics = null,}) {
  return _then(ExportBundle(
exportedAt: null == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dailyMetrics: null == dailyMetrics ? _self.dailyMetrics : dailyMetrics // ignore: cast_nullable_to_non_nullable
as List<DailyMetric>,
  ));
}

}


/// Adds pattern-matching-related methods to [ExportBundle].
extension ExportBundlePatterns on ExportBundle {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExportBundle value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExportBundle() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExportBundle value)  $default,){
final _that = this;
switch (_that) {
case _ExportBundle():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExportBundle value)?  $default,){
final _that = this;
switch (_that) {
case _ExportBundle() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime exportedAt,  List<DailyMetric> dailyMetrics)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExportBundle() when $default != null:
return $default(_that.exportedAt,_that.dailyMetrics);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime exportedAt,  List<DailyMetric> dailyMetrics)  $default,) {final _that = this;
switch (_that) {
case _ExportBundle():
return $default(_that.exportedAt,_that.dailyMetrics);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime exportedAt,  List<DailyMetric> dailyMetrics)?  $default,) {final _that = this;
switch (_that) {
case _ExportBundle() when $default != null:
return $default(_that.exportedAt,_that.dailyMetrics);case _:
  return null;

}
}

}

/// @nodoc


class _ExportBundle extends ExportBundle {
  const _ExportBundle({required this.exportedAt, required  List<DailyMetric> dailyMetrics}): _dailyMetrics = dailyMetrics,super._();
  

/// When the export was made. Written to the JSON as UTC ISO 8601, and
/// its local calendar date names the file.
@override final  DateTime exportedAt;
/// The rows to export, in any order: both encoders sort by date.
 final  List<DailyMetric> _dailyMetrics;
/// The rows to export, in any order: both encoders sort by date.
@override List<DailyMetric> get dailyMetrics {
  if (_dailyMetrics is EqualUnmodifiableListView) return _dailyMetrics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyMetrics);
}


/// Create a copy of ExportBundle
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExportBundleCopyWith<_ExportBundle> get copyWith => __$ExportBundleCopyWithImpl<_ExportBundle>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExportBundle&&(identical(other.exportedAt, exportedAt) || other.exportedAt == exportedAt)&&const DeepCollectionEquality().equals(other.dailyMetrics, _dailyMetrics));
}


@override
int get hashCode {
    return Object.hash(runtimeType,exportedAt,const DeepCollectionEquality().hash(_dailyMetrics));
}

@override
String toString() {
    return 'ExportBundle(exportedAt: $exportedAt, dailyMetrics: $dailyMetrics)';
}


}

/// @nodoc
abstract mixin class _$ExportBundleCopyWith<$Res> implements $ExportBundleCopyWith<$Res> {
  factory _$ExportBundleCopyWith(_ExportBundle value, $Res Function(_ExportBundle) _then) = __$ExportBundleCopyWithImpl;
@override @useResult
$Res call({
 DateTime exportedAt, List<DailyMetric> dailyMetrics
});




}
/// @nodoc
class __$ExportBundleCopyWithImpl<$Res>
    implements _$ExportBundleCopyWith<$Res> {
  __$ExportBundleCopyWithImpl(this._self, this._then);

  final _ExportBundle _self;
  final $Res Function(_ExportBundle) _then;

/// Create a copy of ExportBundle
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? exportedAt = null,Object? dailyMetrics = null,}) {
  return _then(_ExportBundle(
exportedAt: null == exportedAt ? _self.exportedAt : exportedAt // ignore: cast_nullable_to_non_nullable
as DateTime,dailyMetrics: null == dailyMetrics ? _self._dailyMetrics : dailyMetrics // ignore: cast_nullable_to_non_nullable
as List<DailyMetric>,
  ));
}


}

// dart format on
