// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_record.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingRecord {

/// Whether the person has finished (or skipped to the end of)
/// onboarding.
 bool get completed;/// Their answers so far; [AboutMe.empty] if none.
 AboutMe get aboutMe;
/// Create a copy of OnboardingRecord
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingRecordCopyWith<OnboardingRecord> get copyWith => _$OnboardingRecordCopyWithImpl<OnboardingRecord>(this as OnboardingRecord, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OnboardingRecord;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingRecord&&(identical(other.completed, _this.completed) || other.completed == _this.completed)&&(identical(other.aboutMe, _this.aboutMe) || other.aboutMe == _this.aboutMe));
}


@override
int get hashCode {
  final _this = this as OnboardingRecord;
  return Object.hash(runtimeType,_this.completed,_this.aboutMe);
}

@override
String toString() {
  final _this = this as OnboardingRecord;
  return 'OnboardingRecord(completed: ${_this.completed}, aboutMe: ${_this.aboutMe})';
}


}

/// @nodoc
abstract mixin class $OnboardingRecordCopyWith<$Res>  {
  factory $OnboardingRecordCopyWith(OnboardingRecord value, $Res Function(OnboardingRecord) _then) = _$OnboardingRecordCopyWithImpl;
@useResult
$Res call({
 bool completed, AboutMe aboutMe
});


$AboutMeCopyWith<$Res> get aboutMe;

}
/// @nodoc
class _$OnboardingRecordCopyWithImpl<$Res>
    implements $OnboardingRecordCopyWith<$Res> {
  _$OnboardingRecordCopyWithImpl(this._self, this._then);

  final OnboardingRecord _self;
  final $Res Function(OnboardingRecord) _then;

/// Create a copy of OnboardingRecord
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? completed = null,Object? aboutMe = null,}) {
  return _then(OnboardingRecord(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,aboutMe: null == aboutMe ? _self.aboutMe : aboutMe // ignore: cast_nullable_to_non_nullable
as AboutMe,
  ));
}
/// Create a copy of OnboardingRecord
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutMeCopyWith<$Res> get aboutMe {
  
  return $AboutMeCopyWith<$Res>(_self.aboutMe, (value) {
    return _then(_self.copyWith(aboutMe: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnboardingRecord].
extension OnboardingRecordPatterns on OnboardingRecord {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingRecord value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingRecord() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingRecord value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingRecord():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingRecord value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingRecord() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( bool completed,  AboutMe aboutMe)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingRecord() when $default != null:
return $default(_that.completed,_that.aboutMe);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( bool completed,  AboutMe aboutMe)  $default,) {final _that = this;
switch (_that) {
case _OnboardingRecord():
return $default(_that.completed,_that.aboutMe);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( bool completed,  AboutMe aboutMe)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingRecord() when $default != null:
return $default(_that.completed,_that.aboutMe);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingRecord implements OnboardingRecord {
  const _OnboardingRecord({this.completed = false, this.aboutMe = AboutMe.empty});
  

/// Whether the person has finished (or skipped to the end of)
/// onboarding.
@override@JsonKey() final  bool completed;
/// Their answers so far; [AboutMe.empty] if none.
@override@JsonKey() final  AboutMe aboutMe;

/// Create a copy of OnboardingRecord
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingRecordCopyWith<_OnboardingRecord> get copyWith => __$OnboardingRecordCopyWithImpl<_OnboardingRecord>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingRecord&&(identical(other.completed, completed) || other.completed == completed)&&(identical(other.aboutMe, aboutMe) || other.aboutMe == aboutMe));
}


@override
int get hashCode {
    return Object.hash(runtimeType,completed,aboutMe);
}

@override
String toString() {
    return 'OnboardingRecord(completed: $completed, aboutMe: $aboutMe)';
}


}

/// @nodoc
abstract mixin class _$OnboardingRecordCopyWith<$Res> implements $OnboardingRecordCopyWith<$Res> {
  factory _$OnboardingRecordCopyWith(_OnboardingRecord value, $Res Function(_OnboardingRecord) _then) = __$OnboardingRecordCopyWithImpl;
@override @useResult
$Res call({
 bool completed, AboutMe aboutMe
});


@override $AboutMeCopyWith<$Res> get aboutMe;

}
/// @nodoc
class __$OnboardingRecordCopyWithImpl<$Res>
    implements _$OnboardingRecordCopyWith<$Res> {
  __$OnboardingRecordCopyWithImpl(this._self, this._then);

  final _OnboardingRecord _self;
  final $Res Function(_OnboardingRecord) _then;

/// Create a copy of OnboardingRecord
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? completed = null,Object? aboutMe = null,}) {
  return _then(_OnboardingRecord(
completed: null == completed ? _self.completed : completed // ignore: cast_nullable_to_non_nullable
as bool,aboutMe: null == aboutMe ? _self.aboutMe : aboutMe // ignore: cast_nullable_to_non_nullable
as AboutMe,
  ));
}

/// Create a copy of OnboardingRecord
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
