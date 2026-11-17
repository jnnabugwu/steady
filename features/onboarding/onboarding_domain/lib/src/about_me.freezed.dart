// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'about_me.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AboutMe {

/// The coach's voice (screen 7), or `null` if skipped.
 CoachVoice? get voice;/// How the person tracks food (screen 2), or `null` if skipped.
 FoodTracking? get tracking;/// The person's activities (screen 5). Empty if skipped.
 Set<OnboardingActivity> get activities;/// What the person's weekends are like (screen 5), or `null` if
/// skipped.
 WeekendShape? get weekends;/// What gets in the way (screen 6). Empty if skipped.
 Set<HardPart> get hardParts;/// "Anything else the coach should know?" (screen 8), at most
/// [aboutMeNoteMaxChars] code points, or `null` if skipped. The only
/// free text in About me.
 String? get note;
/// Create a copy of AboutMe
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AboutMeCopyWith<AboutMe> get copyWith => _$AboutMeCopyWithImpl<AboutMe>(this as AboutMe, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AboutMe;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AboutMe&&(identical(other.voice, _this.voice) || other.voice == _this.voice)&&(identical(other.tracking, _this.tracking) || other.tracking == _this.tracking)&&const DeepCollectionEquality().equals(other.activities, _this.activities)&&(identical(other.weekends, _this.weekends) || other.weekends == _this.weekends)&&const DeepCollectionEquality().equals(other.hardParts, _this.hardParts)&&(identical(other.note, _this.note) || other.note == _this.note));
}


@override
int get hashCode {
  final _this = this as AboutMe;
  return Object.hash(runtimeType,_this.voice,_this.tracking,const DeepCollectionEquality().hash(_this.activities),_this.weekends,const DeepCollectionEquality().hash(_this.hardParts),_this.note);
}

@override
String toString() {
  final _this = this as AboutMe;
  return 'AboutMe(voice: ${_this.voice}, tracking: ${_this.tracking}, activities: ${_this.activities}, weekends: ${_this.weekends}, hardParts: ${_this.hardParts}, note: ${_this.note})';
}


}

/// @nodoc
abstract mixin class $AboutMeCopyWith<$Res>  {
  factory $AboutMeCopyWith(AboutMe value, $Res Function(AboutMe) _then) = _$AboutMeCopyWithImpl;
@useResult
$Res call({
 CoachVoice? voice, FoodTracking? tracking, Set<OnboardingActivity> activities, WeekendShape? weekends, Set<HardPart> hardParts, String? note
});




}
/// @nodoc
class _$AboutMeCopyWithImpl<$Res>
    implements $AboutMeCopyWith<$Res> {
  _$AboutMeCopyWithImpl(this._self, this._then);

  final AboutMe _self;
  final $Res Function(AboutMe) _then;

/// Create a copy of AboutMe
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? voice = freezed,Object? tracking = freezed,Object? activities = null,Object? weekends = freezed,Object? hardParts = null,Object? note = freezed,}) {
  return _then(AboutMe(
voice: freezed == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as CoachVoice?,tracking: freezed == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as FoodTracking?,activities: null == activities ? _self.activities : activities // ignore: cast_nullable_to_non_nullable
as Set<OnboardingActivity>,weekends: freezed == weekends ? _self.weekends : weekends // ignore: cast_nullable_to_non_nullable
as WeekendShape?,hardParts: null == hardParts ? _self.hardParts : hardParts // ignore: cast_nullable_to_non_nullable
as Set<HardPart>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [AboutMe].
extension AboutMePatterns on AboutMe {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AboutMe value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AboutMe() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AboutMe value)  $default,){
final _that = this;
switch (_that) {
case _AboutMe():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AboutMe value)?  $default,){
final _that = this;
switch (_that) {
case _AboutMe() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoachVoice? voice,  FoodTracking? tracking,  Set<OnboardingActivity> activities,  WeekendShape? weekends,  Set<HardPart> hardParts,  String? note)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AboutMe() when $default != null:
return $default(_that.voice,_that.tracking,_that.activities,_that.weekends,_that.hardParts,_that.note);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoachVoice? voice,  FoodTracking? tracking,  Set<OnboardingActivity> activities,  WeekendShape? weekends,  Set<HardPart> hardParts,  String? note)  $default,) {final _that = this;
switch (_that) {
case _AboutMe():
return $default(_that.voice,_that.tracking,_that.activities,_that.weekends,_that.hardParts,_that.note);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoachVoice? voice,  FoodTracking? tracking,  Set<OnboardingActivity> activities,  WeekendShape? weekends,  Set<HardPart> hardParts,  String? note)?  $default,) {final _that = this;
switch (_that) {
case _AboutMe() when $default != null:
return $default(_that.voice,_that.tracking,_that.activities,_that.weekends,_that.hardParts,_that.note);case _:
  return null;

}
}

}

/// @nodoc


class _AboutMe extends AboutMe {
  const _AboutMe({this.voice, this.tracking,  Set<OnboardingActivity> activities = const <OnboardingActivity>{}, this.weekends,  Set<HardPart> hardParts = const <HardPart>{}, this.note}): _activities = activities,_hardParts = hardParts,super._();
  

/// The coach's voice (screen 7), or `null` if skipped.
@override final  CoachVoice? voice;
/// How the person tracks food (screen 2), or `null` if skipped.
@override final  FoodTracking? tracking;
/// The person's activities (screen 5). Empty if skipped.
 final  Set<OnboardingActivity> _activities;
/// The person's activities (screen 5). Empty if skipped.
@override@JsonKey() Set<OnboardingActivity> get activities {
  if (_activities is EqualUnmodifiableSetView) return _activities;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_activities);
}

/// What the person's weekends are like (screen 5), or `null` if
/// skipped.
@override final  WeekendShape? weekends;
/// What gets in the way (screen 6). Empty if skipped.
 final  Set<HardPart> _hardParts;
/// What gets in the way (screen 6). Empty if skipped.
@override@JsonKey() Set<HardPart> get hardParts {
  if (_hardParts is EqualUnmodifiableSetView) return _hardParts;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_hardParts);
}

/// "Anything else the coach should know?" (screen 8), at most
/// [aboutMeNoteMaxChars] code points, or `null` if skipped. The only
/// free text in About me.
@override final  String? note;

/// Create a copy of AboutMe
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AboutMeCopyWith<_AboutMe> get copyWith => __$AboutMeCopyWithImpl<_AboutMe>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AboutMe&&(identical(other.voice, voice) || other.voice == voice)&&(identical(other.tracking, tracking) || other.tracking == tracking)&&const DeepCollectionEquality().equals(other.activities, _activities)&&(identical(other.weekends, weekends) || other.weekends == weekends)&&const DeepCollectionEquality().equals(other.hardParts, _hardParts)&&(identical(other.note, note) || other.note == note));
}


@override
int get hashCode {
    return Object.hash(runtimeType,voice,tracking,const DeepCollectionEquality().hash(_activities),weekends,const DeepCollectionEquality().hash(_hardParts),note);
}

@override
String toString() {
    return 'AboutMe(voice: $voice, tracking: $tracking, activities: $activities, weekends: $weekends, hardParts: $hardParts, note: $note)';
}


}

/// @nodoc
abstract mixin class _$AboutMeCopyWith<$Res> implements $AboutMeCopyWith<$Res> {
  factory _$AboutMeCopyWith(_AboutMe value, $Res Function(_AboutMe) _then) = __$AboutMeCopyWithImpl;
@override @useResult
$Res call({
 CoachVoice? voice, FoodTracking? tracking, Set<OnboardingActivity> activities, WeekendShape? weekends, Set<HardPart> hardParts, String? note
});




}
/// @nodoc
class __$AboutMeCopyWithImpl<$Res>
    implements _$AboutMeCopyWith<$Res> {
  __$AboutMeCopyWithImpl(this._self, this._then);

  final _AboutMe _self;
  final $Res Function(_AboutMe) _then;

/// Create a copy of AboutMe
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? voice = freezed,Object? tracking = freezed,Object? activities = null,Object? weekends = freezed,Object? hardParts = null,Object? note = freezed,}) {
  return _then(_AboutMe(
voice: freezed == voice ? _self.voice : voice // ignore: cast_nullable_to_non_nullable
as CoachVoice?,tracking: freezed == tracking ? _self.tracking : tracking // ignore: cast_nullable_to_non_nullable
as FoodTracking?,activities: null == activities ? _self._activities : activities // ignore: cast_nullable_to_non_nullable
as Set<OnboardingActivity>,weekends: freezed == weekends ? _self.weekends : weekends // ignore: cast_nullable_to_non_nullable
as WeekendShape?,hardParts: null == hardParts ? _self._hardParts : hardParts // ignore: cast_nullable_to_non_nullable
as Set<HardPart>,note: freezed == note ? _self.note : note // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
