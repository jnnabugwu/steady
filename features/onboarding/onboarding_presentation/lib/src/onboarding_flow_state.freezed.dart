// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'onboarding_flow_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$OnboardingFlowState {

/// The screen the person is on.
 OnboardingStep get step;/// Their answers so far.
 AboutMe get aboutMe;/// The stone each passed step placed: [OnboardingStone.placed] for an
/// answered step, [OnboardingStone.dimmed] for a skipped one. Steps not
/// reached yet have none.
 Map<OnboardingStep, OnboardingStone> get stones;/// The last save that failed, if the latest one did. Shown as a quiet
/// line; the answer is still kept in memory and the flow goes on.
 Failure? get saveFailure;
/// Create a copy of OnboardingFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$OnboardingFlowStateCopyWith<OnboardingFlowState> get copyWith => _$OnboardingFlowStateCopyWithImpl<OnboardingFlowState>(this as OnboardingFlowState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as OnboardingFlowState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is OnboardingFlowState&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.aboutMe, _this.aboutMe) || other.aboutMe == _this.aboutMe)&&const DeepCollectionEquality().equals(other.stones, _this.stones)&&(identical(other.saveFailure, _this.saveFailure) || other.saveFailure == _this.saveFailure));
}


@override
int get hashCode {
  final _this = this as OnboardingFlowState;
  return Object.hash(runtimeType,_this.step,_this.aboutMe,const DeepCollectionEquality().hash(_this.stones),_this.saveFailure);
}

@override
String toString() {
  final _this = this as OnboardingFlowState;
  return 'OnboardingFlowState(step: ${_this.step}, aboutMe: ${_this.aboutMe}, stones: ${_this.stones}, saveFailure: ${_this.saveFailure})';
}


}

/// @nodoc
abstract mixin class $OnboardingFlowStateCopyWith<$Res>  {
  factory $OnboardingFlowStateCopyWith(OnboardingFlowState value, $Res Function(OnboardingFlowState) _then) = _$OnboardingFlowStateCopyWithImpl;
@useResult
$Res call({
 OnboardingStep step, AboutMe aboutMe, Map<OnboardingStep, OnboardingStone> stones, Failure? saveFailure
});


$AboutMeCopyWith<$Res> get aboutMe;

}
/// @nodoc
class _$OnboardingFlowStateCopyWithImpl<$Res>
    implements $OnboardingFlowStateCopyWith<$Res> {
  _$OnboardingFlowStateCopyWithImpl(this._self, this._then);

  final OnboardingFlowState _self;
  final $Res Function(OnboardingFlowState) _then;

/// Create a copy of OnboardingFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? step = null,Object? aboutMe = null,Object? stones = null,Object? saveFailure = freezed,}) {
  return _then(OnboardingFlowState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,aboutMe: null == aboutMe ? _self.aboutMe : aboutMe // ignore: cast_nullable_to_non_nullable
as AboutMe,stones: null == stones ? _self.stones : stones // ignore: cast_nullable_to_non_nullable
as Map<OnboardingStep, OnboardingStone>,saveFailure: freezed == saveFailure ? _self.saveFailure : saveFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of OnboardingFlowState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$AboutMeCopyWith<$Res> get aboutMe {
  
  return $AboutMeCopyWith<$Res>(_self.aboutMe, (value) {
    return _then(_self.copyWith(aboutMe: value));
  });
}
}


/// Adds pattern-matching-related methods to [OnboardingFlowState].
extension OnboardingFlowStatePatterns on OnboardingFlowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _OnboardingFlowState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _OnboardingFlowState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _OnboardingFlowState value)  $default,){
final _that = this;
switch (_that) {
case _OnboardingFlowState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _OnboardingFlowState value)?  $default,){
final _that = this;
switch (_that) {
case _OnboardingFlowState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( OnboardingStep step,  AboutMe aboutMe,  Map<OnboardingStep, OnboardingStone> stones,  Failure? saveFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _OnboardingFlowState() when $default != null:
return $default(_that.step,_that.aboutMe,_that.stones,_that.saveFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( OnboardingStep step,  AboutMe aboutMe,  Map<OnboardingStep, OnboardingStone> stones,  Failure? saveFailure)  $default,) {final _that = this;
switch (_that) {
case _OnboardingFlowState():
return $default(_that.step,_that.aboutMe,_that.stones,_that.saveFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( OnboardingStep step,  AboutMe aboutMe,  Map<OnboardingStep, OnboardingStone> stones,  Failure? saveFailure)?  $default,) {final _that = this;
switch (_that) {
case _OnboardingFlowState() when $default != null:
return $default(_that.step,_that.aboutMe,_that.stones,_that.saveFailure);case _:
  return null;

}
}

}

/// @nodoc


class _OnboardingFlowState extends OnboardingFlowState {
  const _OnboardingFlowState({required this.step, this.aboutMe = AboutMe.empty,  Map<OnboardingStep, OnboardingStone> stones = const <OnboardingStep, OnboardingStone>{}, this.saveFailure}): _stones = stones,super._();
  

/// The screen the person is on.
@override final  OnboardingStep step;
/// Their answers so far.
@override@JsonKey() final  AboutMe aboutMe;
/// The stone each passed step placed: [OnboardingStone.placed] for an
/// answered step, [OnboardingStone.dimmed] for a skipped one. Steps not
/// reached yet have none.
 final  Map<OnboardingStep, OnboardingStone> _stones;
/// The stone each passed step placed: [OnboardingStone.placed] for an
/// answered step, [OnboardingStone.dimmed] for a skipped one. Steps not
/// reached yet have none.
@override@JsonKey() Map<OnboardingStep, OnboardingStone> get stones {
  if (_stones is EqualUnmodifiableMapView) return _stones;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_stones);
}

/// The last save that failed, if the latest one did. Shown as a quiet
/// line; the answer is still kept in memory and the flow goes on.
@override final  Failure? saveFailure;

/// Create a copy of OnboardingFlowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$OnboardingFlowStateCopyWith<_OnboardingFlowState> get copyWith => __$OnboardingFlowStateCopyWithImpl<_OnboardingFlowState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _OnboardingFlowState&&(identical(other.step, step) || other.step == step)&&(identical(other.aboutMe, aboutMe) || other.aboutMe == aboutMe)&&const DeepCollectionEquality().equals(other.stones, _stones)&&(identical(other.saveFailure, saveFailure) || other.saveFailure == saveFailure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,step,aboutMe,const DeepCollectionEquality().hash(_stones),saveFailure);
}

@override
String toString() {
    return 'OnboardingFlowState(step: $step, aboutMe: $aboutMe, stones: $stones, saveFailure: $saveFailure)';
}


}

/// @nodoc
abstract mixin class _$OnboardingFlowStateCopyWith<$Res> implements $OnboardingFlowStateCopyWith<$Res> {
  factory _$OnboardingFlowStateCopyWith(_OnboardingFlowState value, $Res Function(_OnboardingFlowState) _then) = __$OnboardingFlowStateCopyWithImpl;
@override @useResult
$Res call({
 OnboardingStep step, AboutMe aboutMe, Map<OnboardingStep, OnboardingStone> stones, Failure? saveFailure
});


@override $AboutMeCopyWith<$Res> get aboutMe;

}
/// @nodoc
class __$OnboardingFlowStateCopyWithImpl<$Res>
    implements _$OnboardingFlowStateCopyWith<$Res> {
  __$OnboardingFlowStateCopyWithImpl(this._self, this._then);

  final _OnboardingFlowState _self;
  final $Res Function(_OnboardingFlowState) _then;

/// Create a copy of OnboardingFlowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? step = null,Object? aboutMe = null,Object? stones = null,Object? saveFailure = freezed,}) {
  return _then(_OnboardingFlowState(
step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as OnboardingStep,aboutMe: null == aboutMe ? _self.aboutMe : aboutMe // ignore: cast_nullable_to_non_nullable
as AboutMe,stones: null == stones ? _self._stones : stones // ignore: cast_nullable_to_non_nullable
as Map<OnboardingStep, OnboardingStone>,saveFailure: freezed == saveFailure ? _self.saveFailure : saveFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of OnboardingFlowState
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
