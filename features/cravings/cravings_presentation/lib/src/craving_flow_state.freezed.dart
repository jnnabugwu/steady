// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'craving_flow_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CravingFlowState {

/// The event's id, fixed when the flow opens, so saving again replaces
/// rather than duplicates.
 String get id;/// When the flow opened.
 DateTime get startedAt;/// The current step.
 CravingStep get step;/// The first rating, once given.
 int? get intensityBefore;/// The reasons picked so far.
 Set<CravingReason> get reasons;/// Whether the guided minute was started.
 bool get tookMinute;/// The second rating, if given.
 int? get intensityAfter;/// How it ended, once it has.
 CravingOutcome? get outcome;/// When it ended, once it has.
 DateTime? get endedAt;/// Whether the finished event is being saved right now.
 bool get saving;/// Why the last save failed, if it did.
 Failure? get saveFailure;
/// Create a copy of CravingFlowState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CravingFlowStateCopyWith<CravingFlowState> get copyWith => _$CravingFlowStateCopyWithImpl<CravingFlowState>(this as CravingFlowState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CravingFlowState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CravingFlowState&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.step, _this.step) || other.step == _this.step)&&(identical(other.intensityBefore, _this.intensityBefore) || other.intensityBefore == _this.intensityBefore)&&const DeepCollectionEquality().equals(other.reasons, _this.reasons)&&(identical(other.tookMinute, _this.tookMinute) || other.tookMinute == _this.tookMinute)&&(identical(other.intensityAfter, _this.intensityAfter) || other.intensityAfter == _this.intensityAfter)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.saving, _this.saving) || other.saving == _this.saving)&&(identical(other.saveFailure, _this.saveFailure) || other.saveFailure == _this.saveFailure));
}


@override
int get hashCode {
  final _this = this as CravingFlowState;
  return Object.hash(runtimeType,_this.id,_this.startedAt,_this.step,_this.intensityBefore,const DeepCollectionEquality().hash(_this.reasons),_this.tookMinute,_this.intensityAfter,_this.outcome,_this.endedAt,_this.saving,_this.saveFailure);
}

@override
String toString() {
  final _this = this as CravingFlowState;
  return 'CravingFlowState(id: ${_this.id}, startedAt: ${_this.startedAt}, step: ${_this.step}, intensityBefore: ${_this.intensityBefore}, reasons: ${_this.reasons}, tookMinute: ${_this.tookMinute}, intensityAfter: ${_this.intensityAfter}, outcome: ${_this.outcome}, endedAt: ${_this.endedAt}, saving: ${_this.saving}, saveFailure: ${_this.saveFailure})';
}


}

/// @nodoc
abstract mixin class $CravingFlowStateCopyWith<$Res>  {
  factory $CravingFlowStateCopyWith(CravingFlowState value, $Res Function(CravingFlowState) _then) = _$CravingFlowStateCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startedAt, CravingStep step, int? intensityBefore, Set<CravingReason> reasons, bool tookMinute, int? intensityAfter, CravingOutcome? outcome, DateTime? endedAt, bool saving, Failure? saveFailure
});




}
/// @nodoc
class _$CravingFlowStateCopyWithImpl<$Res>
    implements $CravingFlowStateCopyWith<$Res> {
  _$CravingFlowStateCopyWithImpl(this._self, this._then);

  final CravingFlowState _self;
  final $Res Function(CravingFlowState) _then;

/// Create a copy of CravingFlowState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? step = null,Object? intensityBefore = freezed,Object? reasons = null,Object? tookMinute = null,Object? intensityAfter = freezed,Object? outcome = freezed,Object? endedAt = freezed,Object? saving = null,Object? saveFailure = freezed,}) {
  return _then(CravingFlowState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CravingStep,intensityBefore: freezed == intensityBefore ? _self.intensityBefore : intensityBefore // ignore: cast_nullable_to_non_nullable
as int?,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as Set<CravingReason>,tookMinute: null == tookMinute ? _self.tookMinute : tookMinute // ignore: cast_nullable_to_non_nullable
as bool,intensityAfter: freezed == intensityAfter ? _self.intensityAfter : intensityAfter // ignore: cast_nullable_to_non_nullable
as int?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CravingOutcome?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveFailure: freezed == saveFailure ? _self.saveFailure : saveFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

}


/// Adds pattern-matching-related methods to [CravingFlowState].
extension CravingFlowStatePatterns on CravingFlowState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CravingFlowState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CravingFlowState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CravingFlowState value)  $default,){
final _that = this;
switch (_that) {
case _CravingFlowState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CravingFlowState value)?  $default,){
final _that = this;
switch (_that) {
case _CravingFlowState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime startedAt,  CravingStep step,  int? intensityBefore,  Set<CravingReason> reasons,  bool tookMinute,  int? intensityAfter,  CravingOutcome? outcome,  DateTime? endedAt,  bool saving,  Failure? saveFailure)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CravingFlowState() when $default != null:
return $default(_that.id,_that.startedAt,_that.step,_that.intensityBefore,_that.reasons,_that.tookMinute,_that.intensityAfter,_that.outcome,_that.endedAt,_that.saving,_that.saveFailure);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime startedAt,  CravingStep step,  int? intensityBefore,  Set<CravingReason> reasons,  bool tookMinute,  int? intensityAfter,  CravingOutcome? outcome,  DateTime? endedAt,  bool saving,  Failure? saveFailure)  $default,) {final _that = this;
switch (_that) {
case _CravingFlowState():
return $default(_that.id,_that.startedAt,_that.step,_that.intensityBefore,_that.reasons,_that.tookMinute,_that.intensityAfter,_that.outcome,_that.endedAt,_that.saving,_that.saveFailure);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime startedAt,  CravingStep step,  int? intensityBefore,  Set<CravingReason> reasons,  bool tookMinute,  int? intensityAfter,  CravingOutcome? outcome,  DateTime? endedAt,  bool saving,  Failure? saveFailure)?  $default,) {final _that = this;
switch (_that) {
case _CravingFlowState() when $default != null:
return $default(_that.id,_that.startedAt,_that.step,_that.intensityBefore,_that.reasons,_that.tookMinute,_that.intensityAfter,_that.outcome,_that.endedAt,_that.saving,_that.saveFailure);case _:
  return null;

}
}

}

/// @nodoc


class _CravingFlowState extends CravingFlowState {
  const _CravingFlowState({required this.id, required this.startedAt, this.step = CravingStep.intensity, this.intensityBefore,  Set<CravingReason> reasons = const <CravingReason>{}, this.tookMinute = false, this.intensityAfter, this.outcome, this.endedAt, this.saving = false, this.saveFailure}): _reasons = reasons,super._();
  

/// The event's id, fixed when the flow opens, so saving again replaces
/// rather than duplicates.
@override final  String id;
/// When the flow opened.
@override final  DateTime startedAt;
/// The current step.
@override@JsonKey() final  CravingStep step;
/// The first rating, once given.
@override final  int? intensityBefore;
/// The reasons picked so far.
 final  Set<CravingReason> _reasons;
/// The reasons picked so far.
@override@JsonKey() Set<CravingReason> get reasons {
  if (_reasons is EqualUnmodifiableSetView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_reasons);
}

/// Whether the guided minute was started.
@override@JsonKey() final  bool tookMinute;
/// The second rating, if given.
@override final  int? intensityAfter;
/// How it ended, once it has.
@override final  CravingOutcome? outcome;
/// When it ended, once it has.
@override final  DateTime? endedAt;
/// Whether the finished event is being saved right now.
@override@JsonKey() final  bool saving;
/// Why the last save failed, if it did.
@override final  Failure? saveFailure;

/// Create a copy of CravingFlowState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CravingFlowStateCopyWith<_CravingFlowState> get copyWith => __$CravingFlowStateCopyWithImpl<_CravingFlowState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CravingFlowState&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.step, step) || other.step == step)&&(identical(other.intensityBefore, intensityBefore) || other.intensityBefore == intensityBefore)&&const DeepCollectionEquality().equals(other.reasons, _reasons)&&(identical(other.tookMinute, tookMinute) || other.tookMinute == tookMinute)&&(identical(other.intensityAfter, intensityAfter) || other.intensityAfter == intensityAfter)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.saving, saving) || other.saving == saving)&&(identical(other.saveFailure, saveFailure) || other.saveFailure == saveFailure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,startedAt,step,intensityBefore,const DeepCollectionEquality().hash(_reasons),tookMinute,intensityAfter,outcome,endedAt,saving,saveFailure);
}

@override
String toString() {
    return 'CravingFlowState(id: $id, startedAt: $startedAt, step: $step, intensityBefore: $intensityBefore, reasons: $reasons, tookMinute: $tookMinute, intensityAfter: $intensityAfter, outcome: $outcome, endedAt: $endedAt, saving: $saving, saveFailure: $saveFailure)';
}


}

/// @nodoc
abstract mixin class _$CravingFlowStateCopyWith<$Res> implements $CravingFlowStateCopyWith<$Res> {
  factory _$CravingFlowStateCopyWith(_CravingFlowState value, $Res Function(_CravingFlowState) _then) = __$CravingFlowStateCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime startedAt, CravingStep step, int? intensityBefore, Set<CravingReason> reasons, bool tookMinute, int? intensityAfter, CravingOutcome? outcome, DateTime? endedAt, bool saving, Failure? saveFailure
});




}
/// @nodoc
class __$CravingFlowStateCopyWithImpl<$Res>
    implements _$CravingFlowStateCopyWith<$Res> {
  __$CravingFlowStateCopyWithImpl(this._self, this._then);

  final _CravingFlowState _self;
  final $Res Function(_CravingFlowState) _then;

/// Create a copy of CravingFlowState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? step = null,Object? intensityBefore = freezed,Object? reasons = null,Object? tookMinute = null,Object? intensityAfter = freezed,Object? outcome = freezed,Object? endedAt = freezed,Object? saving = null,Object? saveFailure = freezed,}) {
  return _then(_CravingFlowState(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,step: null == step ? _self.step : step // ignore: cast_nullable_to_non_nullable
as CravingStep,intensityBefore: freezed == intensityBefore ? _self.intensityBefore : intensityBefore // ignore: cast_nullable_to_non_nullable
as int?,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as Set<CravingReason>,tookMinute: null == tookMinute ? _self.tookMinute : tookMinute // ignore: cast_nullable_to_non_nullable
as bool,intensityAfter: freezed == intensityAfter ? _self.intensityAfter : intensityAfter // ignore: cast_nullable_to_non_nullable
as int?,outcome: freezed == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CravingOutcome?,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,saving: null == saving ? _self.saving : saving // ignore: cast_nullable_to_non_nullable
as bool,saveFailure: freezed == saveFailure ? _self.saveFailure : saveFailure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}


}

// dart format on
