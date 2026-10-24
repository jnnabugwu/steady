// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'craving_event.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CravingEvent {

/// Identity, unique per event.
 String get id;/// When the flow was opened. Drives the time-of-day summary.
 DateTime get startedAt;/// How strong it was at the start, 1 (mild) to 5 (strong).
 int get intensityBefore;/// What was behind it, if the person said. Empty is fine.
 Set<CravingReason> get reasons;/// Whether the person chose to take the guided minute.
 bool get tookMinute;/// How it ended.
 CravingOutcome get outcome;/// When the flow reached its outcome.
 DateTime? get endedAt;/// How strong it was at "Still want it?", 1 to 5, if rated. Always
/// `null` for [CravingOutcome.hungry], which skips that question.
 int? get intensityAfter;
/// Create a copy of CravingEvent
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CravingEventCopyWith<CravingEvent> get copyWith => _$CravingEventCopyWithImpl<CravingEvent>(this as CravingEvent, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CravingEvent;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CravingEvent&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&(identical(other.intensityBefore, _this.intensityBefore) || other.intensityBefore == _this.intensityBefore)&&const DeepCollectionEquality().equals(other.reasons, _this.reasons)&&(identical(other.tookMinute, _this.tookMinute) || other.tookMinute == _this.tookMinute)&&(identical(other.outcome, _this.outcome) || other.outcome == _this.outcome)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.intensityAfter, _this.intensityAfter) || other.intensityAfter == _this.intensityAfter));
}


@override
int get hashCode {
  final _this = this as CravingEvent;
  return Object.hash(runtimeType,_this.id,_this.startedAt,_this.intensityBefore,const DeepCollectionEquality().hash(_this.reasons),_this.tookMinute,_this.outcome,_this.endedAt,_this.intensityAfter);
}

@override
String toString() {
  final _this = this as CravingEvent;
  return 'CravingEvent(id: ${_this.id}, startedAt: ${_this.startedAt}, intensityBefore: ${_this.intensityBefore}, reasons: ${_this.reasons}, tookMinute: ${_this.tookMinute}, outcome: ${_this.outcome}, endedAt: ${_this.endedAt}, intensityAfter: ${_this.intensityAfter})';
}


}

/// @nodoc
abstract mixin class $CravingEventCopyWith<$Res>  {
  factory $CravingEventCopyWith(CravingEvent value, $Res Function(CravingEvent) _then) = _$CravingEventCopyWithImpl;
@useResult
$Res call({
 String id, DateTime startedAt, int intensityBefore, Set<CravingReason> reasons, bool tookMinute, CravingOutcome outcome, DateTime? endedAt, int? intensityAfter
});




}
/// @nodoc
class _$CravingEventCopyWithImpl<$Res>
    implements $CravingEventCopyWith<$Res> {
  _$CravingEventCopyWithImpl(this._self, this._then);

  final CravingEvent _self;
  final $Res Function(CravingEvent) _then;

/// Create a copy of CravingEvent
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? startedAt = null,Object? intensityBefore = null,Object? reasons = null,Object? tookMinute = null,Object? outcome = null,Object? endedAt = freezed,Object? intensityAfter = freezed,}) {
  return _then(CravingEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,intensityBefore: null == intensityBefore ? _self.intensityBefore : intensityBefore // ignore: cast_nullable_to_non_nullable
as int,reasons: null == reasons ? _self.reasons : reasons // ignore: cast_nullable_to_non_nullable
as Set<CravingReason>,tookMinute: null == tookMinute ? _self.tookMinute : tookMinute // ignore: cast_nullable_to_non_nullable
as bool,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CravingOutcome,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,intensityAfter: freezed == intensityAfter ? _self.intensityAfter : intensityAfter // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [CravingEvent].
extension CravingEventPatterns on CravingEvent {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CravingEvent value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CravingEvent() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CravingEvent value)  $default,){
final _that = this;
switch (_that) {
case _CravingEvent():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CravingEvent value)?  $default,){
final _that = this;
switch (_that) {
case _CravingEvent() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  DateTime startedAt,  int intensityBefore,  Set<CravingReason> reasons,  bool tookMinute,  CravingOutcome outcome,  DateTime? endedAt,  int? intensityAfter)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CravingEvent() when $default != null:
return $default(_that.id,_that.startedAt,_that.intensityBefore,_that.reasons,_that.tookMinute,_that.outcome,_that.endedAt,_that.intensityAfter);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  DateTime startedAt,  int intensityBefore,  Set<CravingReason> reasons,  bool tookMinute,  CravingOutcome outcome,  DateTime? endedAt,  int? intensityAfter)  $default,) {final _that = this;
switch (_that) {
case _CravingEvent():
return $default(_that.id,_that.startedAt,_that.intensityBefore,_that.reasons,_that.tookMinute,_that.outcome,_that.endedAt,_that.intensityAfter);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  DateTime startedAt,  int intensityBefore,  Set<CravingReason> reasons,  bool tookMinute,  CravingOutcome outcome,  DateTime? endedAt,  int? intensityAfter)?  $default,) {final _that = this;
switch (_that) {
case _CravingEvent() when $default != null:
return $default(_that.id,_that.startedAt,_that.intensityBefore,_that.reasons,_that.tookMinute,_that.outcome,_that.endedAt,_that.intensityAfter);case _:
  return null;

}
}

}

/// @nodoc


class _CravingEvent implements CravingEvent {
  const _CravingEvent({required this.id, required this.startedAt, required this.intensityBefore, required  Set<CravingReason> reasons, required this.tookMinute, required this.outcome, this.endedAt, this.intensityAfter}): assert(intensityBefore >= 1 && intensityBefore <= 5, 'intensityBefore must be 1 to 5'),assert(intensityAfter == null || (intensityAfter >= 1 && intensityAfter <= 5), 'intensityAfter must be 1 to 5'),_reasons = reasons;
  

/// Identity, unique per event.
@override final  String id;
/// When the flow was opened. Drives the time-of-day summary.
@override final  DateTime startedAt;
/// How strong it was at the start, 1 (mild) to 5 (strong).
@override final  int intensityBefore;
/// What was behind it, if the person said. Empty is fine.
 final  Set<CravingReason> _reasons;
/// What was behind it, if the person said. Empty is fine.
@override Set<CravingReason> get reasons {
  if (_reasons is EqualUnmodifiableSetView) return _reasons;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableSetView(_reasons);
}

/// Whether the person chose to take the guided minute.
@override final  bool tookMinute;
/// How it ended.
@override final  CravingOutcome outcome;
/// When the flow reached its outcome.
@override final  DateTime? endedAt;
/// How strong it was at "Still want it?", 1 to 5, if rated. Always
/// `null` for [CravingOutcome.hungry], which skips that question.
@override final  int? intensityAfter;

/// Create a copy of CravingEvent
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CravingEventCopyWith<_CravingEvent> get copyWith => __$CravingEventCopyWithImpl<_CravingEvent>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CravingEvent&&(identical(other.id, id) || other.id == id)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&(identical(other.intensityBefore, intensityBefore) || other.intensityBefore == intensityBefore)&&const DeepCollectionEquality().equals(other.reasons, _reasons)&&(identical(other.tookMinute, tookMinute) || other.tookMinute == tookMinute)&&(identical(other.outcome, outcome) || other.outcome == outcome)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.intensityAfter, intensityAfter) || other.intensityAfter == intensityAfter));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,startedAt,intensityBefore,const DeepCollectionEquality().hash(_reasons),tookMinute,outcome,endedAt,intensityAfter);
}

@override
String toString() {
    return 'CravingEvent(id: $id, startedAt: $startedAt, intensityBefore: $intensityBefore, reasons: $reasons, tookMinute: $tookMinute, outcome: $outcome, endedAt: $endedAt, intensityAfter: $intensityAfter)';
}


}

/// @nodoc
abstract mixin class _$CravingEventCopyWith<$Res> implements $CravingEventCopyWith<$Res> {
  factory _$CravingEventCopyWith(_CravingEvent value, $Res Function(_CravingEvent) _then) = __$CravingEventCopyWithImpl;
@override @useResult
$Res call({
 String id, DateTime startedAt, int intensityBefore, Set<CravingReason> reasons, bool tookMinute, CravingOutcome outcome, DateTime? endedAt, int? intensityAfter
});




}
/// @nodoc
class __$CravingEventCopyWithImpl<$Res>
    implements _$CravingEventCopyWith<$Res> {
  __$CravingEventCopyWithImpl(this._self, this._then);

  final _CravingEvent _self;
  final $Res Function(_CravingEvent) _then;

/// Create a copy of CravingEvent
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? startedAt = null,Object? intensityBefore = null,Object? reasons = null,Object? tookMinute = null,Object? outcome = null,Object? endedAt = freezed,Object? intensityAfter = freezed,}) {
  return _then(_CravingEvent(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,intensityBefore: null == intensityBefore ? _self.intensityBefore : intensityBefore // ignore: cast_nullable_to_non_nullable
as int,reasons: null == reasons ? _self._reasons : reasons // ignore: cast_nullable_to_non_nullable
as Set<CravingReason>,tookMinute: null == tookMinute ? _self.tookMinute : tookMinute // ignore: cast_nullable_to_non_nullable
as bool,outcome: null == outcome ? _self.outcome : outcome // ignore: cast_nullable_to_non_nullable
as CravingOutcome,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,intensityAfter: freezed == intensityAfter ? _self.intensityAfter : intensityAfter // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
