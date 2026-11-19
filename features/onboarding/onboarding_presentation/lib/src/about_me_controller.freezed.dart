// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_me_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutMeEditorState {

/// The answers on screen: every edit, saved or not.
 AboutMe get aboutMe;/// Why the latest save failed, if it did. Shown as the quiet line;
/// [aboutMe] keeps the edit, and the next edit saves it again.
 Failure? get saveFailure;
/// Create a copy of AboutMeEditorState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutMeEditorStateCopyWith<AboutMeEditorState> get copyWith => _$AboutMeEditorStateCopyWithImpl<AboutMeEditorState>(this as AboutMeEditorState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AboutMeEditorState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutMeEditorState&&(identical(other.aboutMe, _this.aboutMe) || other.aboutMe == _this.aboutMe)&&(identical(other.saveFailure, _this.saveFailure) || other.saveFailure == _this.saveFailure));
}


@override
int get hashCode {
  final _this = this as AboutMeEditorState;
  return Object.hash(runtimeType,_this.aboutMe,_this.saveFailure);
}

@override
String toString() {
  final _this = this as AboutMeEditorState;
  return 'AboutMeEditorState(aboutMe: ${_this.aboutMe}, saveFailure: ${_this.saveFailure})';
}


}

/// @nodoc
abstract mixin class $AboutMeEditorStateCopyWith<$Res>  {
  factory $AboutMeEditorStateCopyWith(AboutMeEditorState value, $Res Function(AboutMeEditorState) _then) = _$AboutMeEditorStateCopyWithImpl;
@useResult
$Res call({
 AboutMe aboutMe, Failure? saveFailure
});


$AboutMeCopyWith<$Res> get aboutMe;

}
/// @nodoc
class _$AboutMeEditorStateCopyWithImpl<$Res>
    implements $AboutMeEditorStateCopyWith<$Res> {
  _$AboutMeEditorStateCopyWithImpl(this._self, this._then);

  final AboutMeEditorState _self;
  final $Res Function(AboutMeEditorState) _then;

/// Create a copy of AboutMeEditorState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? aboutMe = null,Object? saveFailure = freezed,}) {
  return _then(AboutMeEditorState(
aboutMe: null == aboutMe ? _self.aboutMe : aboutMe // ignore: cast_nullable_to_non_nullable
as AboutMe,saveFailure: freezed == saveFailure ? _self.saveFailure : saveFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of AboutMeEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutMeCopyWith<$Res> get aboutMe {
  
  return $AboutMeCopyWith<$Res>(_self.aboutMe, (value) {
    return _then(_self.copyWith(aboutMe: value));
  });
}
}


/// Adds pattern-matching-related methods to [AboutMeEditorState].
extension AboutMeEditorStatePatterns on AboutMeEditorState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AboutMeEditorState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AboutMeEditorState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AboutMeEditorState value)  $default,){
final _that = this;
switch (_that) {
case _AboutMeEditorState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AboutMeEditorState value)?  $default,){
final _that = this;
switch (_that) {
case _AboutMeEditorState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( AboutMe aboutMe,  Failure? saveFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AboutMeEditorState() when $default != null:
return $default(_that.aboutMe,_that.saveFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( AboutMe aboutMe,  Failure? saveFailure)  $default,) {final _that = this;
switch (_that) {
case _AboutMeEditorState():
return $default(_that.aboutMe,_that.saveFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( AboutMe aboutMe,  Failure? saveFailure)?  $default,) {final _that = this;
switch (_that) {
case _AboutMeEditorState() when $default != null:
return $default(_that.aboutMe,_that.saveFailure);case _:
  return null;

}
}

}

/// @nodoc


class _AboutMeEditorState implements AboutMeEditorState {
  const _AboutMeEditorState({required this.aboutMe, this.saveFailure});
  

/// The answers on screen: every edit, saved or not.
@override final  AboutMe aboutMe;
/// Why the latest save failed, if it did. Shown as the quiet line;
/// [aboutMe] keeps the edit, and the next edit saves it again.
@override final  Failure? saveFailure;

/// Create a copy of AboutMeEditorState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AboutMeEditorStateCopyWith<_AboutMeEditorState> get copyWith => __$AboutMeEditorStateCopyWithImpl<_AboutMeEditorState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AboutMeEditorState&&(identical(other.aboutMe, aboutMe) || other.aboutMe == aboutMe)&&(identical(other.saveFailure, saveFailure) || other.saveFailure == saveFailure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,aboutMe,saveFailure);
}

@override
String toString() {
    return 'AboutMeEditorState(aboutMe: $aboutMe, saveFailure: $saveFailure)';
}


}

/// @nodoc
abstract mixin class _$AboutMeEditorStateCopyWith<$Res> implements $AboutMeEditorStateCopyWith<$Res> {
  factory _$AboutMeEditorStateCopyWith(_AboutMeEditorState value, $Res Function(_AboutMeEditorState) _then) = __$AboutMeEditorStateCopyWithImpl;
@override @useResult
$Res call({
 AboutMe aboutMe, Failure? saveFailure
});


@override $AboutMeCopyWith<$Res> get aboutMe;

}
/// @nodoc
class __$AboutMeEditorStateCopyWithImpl<$Res>
    implements _$AboutMeEditorStateCopyWith<$Res> {
  __$AboutMeEditorStateCopyWithImpl(this._self, this._then);

  final _AboutMeEditorState _self;
  final $Res Function(_AboutMeEditorState) _then;

/// Create a copy of AboutMeEditorState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? aboutMe = null,Object? saveFailure = freezed,}) {
  return _then(_AboutMeEditorState(
aboutMe: null == aboutMe ? _self.aboutMe : aboutMe // ignore: cast_nullable_to_non_nullable
as AboutMe,saveFailure: freezed == saveFailure ? _self.saveFailure : saveFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of AboutMeEditorState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutMeCopyWith<$Res> get aboutMe {
  
  return $AboutMeCopyWith<$Res>(_self.aboutMe, (value) {
    return _then(_self.copyWith(aboutMe: value));
  });
}
}

// dart format on
