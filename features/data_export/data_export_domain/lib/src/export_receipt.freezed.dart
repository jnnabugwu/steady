// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_receipt.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportReceipt {

/// The format that was exported.
 ExportFormat get format;/// The dated file name handed to the share sheet.
 String get fileName;/// How many days (rows) the file holds. `0` is a real, complete export
/// of an empty store, not a failure.
 int get dayCount;/// What the user did with the share sheet.
 ExportShareOutcome get outcome;
/// Create a copy of ExportReceipt
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportReceiptCopyWith<ExportReceipt> get copyWith => _$ExportReceiptCopyWithImpl<ExportReceipt>(this as ExportReceipt, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExportReceipt;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportReceipt&&(identical(other.format, _this.format) || other.format == _this.format)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.dayCount, _this.dayCount) || other.dayCount == _this.dayCount)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome));
}


@override
int get hashCode {
  final _this = this as ExportReceipt;
  return Object.hash(runtimeType,_this.format,_this.fileName,_this.dayCount,_this.outcome);
}

@override
String toString() {
  final _this = this as ExportReceipt;
  return 'ExportReceipt(format: ${_this.format}, fileName: ${_this.fileName}, dayCount: ${_this.dayCount}, outcome: ${_this.outcome})';
}


}

/// @nodoc
abstract mixin class $ExportReceiptCopyWith<$Res>  {
  factory $ExportReceiptCopyWith(ExportReceipt value, $Res Function(ExportReceipt) _then) = _$ExportReceiptCopyWithImpl;
@useResult
$Res call({
 ExportFormat format, String fileName, int dayCount, ExportShareOutcome outcome
});




}
/// @nodoc
class _$ExportReceiptCopyWithImpl<$Res>
    implements $ExportReceiptCopyWith<$Res> {
  _$ExportReceiptCopyWithImpl(this._self, this._then);

  final ExportReceipt _self;
  final $Res Function(ExportReceipt) _then;

/// Create a copy of ExportReceipt
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? format = null,Object? fileName = null,Object? dayCount = null,Object? outcome = null,}) {
  return _then(ExportReceipt(
format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ExportFormat,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,dayCount: null == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as ExportShareOutcome,
  ));
}

}


/// Adds pattern-matching-related methods to [ExportReceipt].
extension ExportReceiptPatterns on ExportReceipt {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExportReceipt value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExportReceipt() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExportReceipt value)  $default,){
final _that = this;
switch (_that) {
case _ExportReceipt():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExportReceipt value)?  $default,){
final _that = this;
switch (_that) {
case _ExportReceipt() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( ExportFormat format,  String fileName,  int dayCount,  ExportShareOutcome outcome)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExportReceipt() when $default != null:
return $default(_that.format,_that.fileName,_that.dayCount,_that.outcome);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( ExportFormat format,  String fileName,  int dayCount,  ExportShareOutcome outcome)  $default,) {final _that = this;
switch (_that) {
case _ExportReceipt():
return $default(_that.format,_that.fileName,_that.dayCount,_that.outcome);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( ExportFormat format,  String fileName,  int dayCount,  ExportShareOutcome outcome)?  $default,) {final _that = this;
switch (_that) {
case _ExportReceipt() when $default != null:
return $default(_that.format,_that.fileName,_that.dayCount,_that.outcome);case _:
  return null;

}
}

}

/// @nodoc


class _ExportReceipt implements ExportReceipt {
  const _ExportReceipt({required this.format, required this.fileName, required this.dayCount, required this.outcome});
  

/// The format that was exported.
@override final  ExportFormat format;
/// The dated file name handed to the share sheet.
@override final  String fileName;
/// How many days (rows) the file holds. `0` is a real, complete export
/// of an empty store, not a failure.
@override final  int dayCount;
/// What the user did with the share sheet.
@override final  ExportShareOutcome outcome;

/// Create a copy of ExportReceipt
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExportReceiptCopyWith<_ExportReceipt> get copyWith => __$ExportReceiptCopyWithImpl<_ExportReceipt>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExportReceipt&&(identical(other.format, format) || other.format == format)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.dayCount, dayCount) || other.dayCount == dayCount)&&(identical(other.outcome, outcome) || other.outcome == outcome));
}


@override
int get hashCode {
    return Object.hash(runtimeType,format,fileName,dayCount,outcome);
}

@override
String toString() {
    return 'ExportReceipt(format: $format, fileName: $fileName, dayCount: $dayCount, outcome: $outcome)';
}


}

/// @nodoc
abstract mixin class _$ExportReceiptCopyWith<$Res> implements $ExportReceiptCopyWith<$Res> {
  factory _$ExportReceiptCopyWith(_ExportReceipt value, $Res Function(_ExportReceipt) _then) = __$ExportReceiptCopyWithImpl;
@override @useResult
$Res call({
 ExportFormat format, String fileName, int dayCount, ExportShareOutcome outcome
});




}
/// @nodoc
class __$ExportReceiptCopyWithImpl<$Res>
    implements _$ExportReceiptCopyWith<$Res> {
  __$ExportReceiptCopyWithImpl(this._self, this._then);

  final _ExportReceipt _self;
  final $Res Function(_ExportReceipt) _then;

/// Create a copy of ExportReceipt
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? format = null,Object? fileName = null,Object? dayCount = null,Object? outcome = null,}) {
  return _then(_ExportReceipt(
format: null == format ? _self.format : format // ignore: cast_nullable_to_non_nullable
as ExportFormat,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,dayCount: null == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as ExportShareOutcome,
  ));
}


}

// dart format on
