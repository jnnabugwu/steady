// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'export_file.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ExportFile {

/// e.g. `steady-export-2026-10-22.csv`.
 String get fileName;/// e.g. `text/csv`.
 String get mimeType;/// The whole file, as text.
 String get contents;
/// Create a copy of ExportFile
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ExportFileCopyWith<ExportFile> get copyWith => _$ExportFileCopyWithImpl<ExportFile>(this as ExportFile, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ExportFile;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ExportFile&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.mimeType, _this.mimeType) || other.mimeType == _this.mimeType)&&(identical(other.contents, _this.contents) || other.contents == _this.contents));
}


@override
int get hashCode {
  final _this = this as ExportFile;
  return Object.hash(runtimeType,_this.fileName,_this.mimeType,_this.contents);
}

@override
String toString() {
  final _this = this as ExportFile;
  return 'ExportFile(fileName: ${_this.fileName}, mimeType: ${_this.mimeType}, contents: ${_this.contents})';
}


}

/// @nodoc
abstract mixin class $ExportFileCopyWith<$Res>  {
  factory $ExportFileCopyWith(ExportFile value, $Res Function(ExportFile) _then) = _$ExportFileCopyWithImpl;
@useResult
$Res call({
 String fileName, String mimeType, String contents
});




}
/// @nodoc
class _$ExportFileCopyWithImpl<$Res>
    implements $ExportFileCopyWith<$Res> {
  _$ExportFileCopyWithImpl(this._self, this._then);

  final ExportFile _self;
  final $Res Function(ExportFile) _then;

/// Create a copy of ExportFile
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? fileName = null,Object? mimeType = null,Object? contents = null,}) {
  return _then(ExportFile(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,contents: null == contents ? _self.contents : contents // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ExportFile].
extension ExportFilePatterns on ExportFile {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ExportFile value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ExportFile() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ExportFile value)  $default,){
final _that = this;
switch (_that) {
case _ExportFile():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ExportFile value)?  $default,){
final _that = this;
switch (_that) {
case _ExportFile() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String fileName,  String mimeType,  String contents)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ExportFile() when $default != null:
return $default(_that.fileName,_that.mimeType,_that.contents);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String fileName,  String mimeType,  String contents)  $default,) {final _that = this;
switch (_that) {
case _ExportFile():
return $default(_that.fileName,_that.mimeType,_that.contents);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String fileName,  String mimeType,  String contents)?  $default,) {final _that = this;
switch (_that) {
case _ExportFile() when $default != null:
return $default(_that.fileName,_that.mimeType,_that.contents);case _:
  return null;

}
}

}

/// @nodoc


class _ExportFile extends ExportFile {
  const _ExportFile({required this.fileName, required this.mimeType, required this.contents}): super._();
  

/// e.g. `steady-export-2026-10-22.csv`.
@override final  String fileName;
/// e.g. `text/csv`.
@override final  String mimeType;
/// The whole file, as text.
@override final  String contents;

/// Create a copy of ExportFile
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ExportFileCopyWith<_ExportFile> get copyWith => __$ExportFileCopyWithImpl<_ExportFile>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ExportFile&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.mimeType, mimeType) || other.mimeType == mimeType)&&(identical(other.contents, contents) || other.contents == contents));
}


@override
int get hashCode {
    return Object.hash(runtimeType,fileName,mimeType,contents);
}

@override
String toString() {
    return 'ExportFile(fileName: $fileName, mimeType: $mimeType, contents: $contents)';
}


}

/// @nodoc
abstract mixin class _$ExportFileCopyWith<$Res> implements $ExportFileCopyWith<$Res> {
  factory _$ExportFileCopyWith(_ExportFile value, $Res Function(_ExportFile) _then) = __$ExportFileCopyWithImpl;
@override @useResult
$Res call({
 String fileName, String mimeType, String contents
});




}
/// @nodoc
class __$ExportFileCopyWithImpl<$Res>
    implements _$ExportFileCopyWith<$Res> {
  __$ExportFileCopyWithImpl(this._self, this._then);

  final _ExportFile _self;
  final $Res Function(_ExportFile) _then;

/// Create a copy of ExportFile
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? fileName = null,Object? mimeType = null,Object? contents = null,}) {
  return _then(_ExportFile(
fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,mimeType: null == mimeType ? _self.mimeType : mimeType // ignore: cast_nullable_to_non_nullable
as String,contents: null == contents ? _self.contents : contents // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
