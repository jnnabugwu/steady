// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoachTurn {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachTurn);
}


@override
int get hashCode => runtimeType.hashCode;



}

/// @nodoc
class $CoachTurnCopyWith<$Res>  {
$CoachTurnCopyWith(CoachTurn _, $Res Function(CoachTurn) __);
}


/// Adds pattern-matching-related methods to [CoachTurn].
extension CoachTurnPatterns on CoachTurn {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CoachPersonTurn value)?  person,TResult Function( CoachReplyTurn value)?  coach,TResult Function( CoachTopicTurn value)?  app,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CoachPersonTurn() when person != null:
return person(_that);case CoachReplyTurn() when coach != null:
return coach(_that);case CoachTopicTurn() when app != null:
return app(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CoachPersonTurn value)  person,required TResult Function( CoachReplyTurn value)  coach,required TResult Function( CoachTopicTurn value)  app,}){
final _that = this;
switch (_that) {
case CoachPersonTurn():
return person(_that);case CoachReplyTurn():
return coach(_that);case CoachTopicTurn():
return app(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CoachPersonTurn value)?  person,TResult? Function( CoachReplyTurn value)?  coach,TResult? Function( CoachTopicTurn value)?  app,}){
final _that = this;
switch (_that) {
case CoachPersonTurn() when person != null:
return person(_that);case CoachReplyTurn() when coach != null:
return coach(_that);case CoachTopicTurn() when app != null:
return app(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function( String text)?  person,TResult Function( String text)?  coach,TResult Function( WeeklyTopic topic)?  app,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CoachPersonTurn() when person != null:
return person(_that.text);case CoachReplyTurn() when coach != null:
return coach(_that.text);case CoachTopicTurn() when app != null:
return app(_that.topic);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function( String text)  person,required TResult Function( String text)  coach,required TResult Function( WeeklyTopic topic)  app,}) {final _that = this;
switch (_that) {
case CoachPersonTurn():
return person(_that.text);case CoachReplyTurn():
return coach(_that.text);case CoachTopicTurn():
return app(_that.topic);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function( String text)?  person,TResult? Function( String text)?  coach,TResult? Function( WeeklyTopic topic)?  app,}) {final _that = this;
switch (_that) {
case CoachPersonTurn() when person != null:
return person(_that.text);case CoachReplyTurn() when coach != null:
return coach(_that.text);case CoachTopicTurn() when app != null:
return app(_that.topic);case _:
  return null;

}
}

}

/// @nodoc


class CoachPersonTurn extends CoachTurn {
  const CoachPersonTurn(this.text): super._();
  

 final  String text;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachPersonTurnCopyWith<CoachPersonTurn> get copyWith => _$CoachPersonTurnCopyWithImpl<CoachPersonTurn>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachPersonTurn&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text);
}



}

/// @nodoc
abstract mixin class $CoachPersonTurnCopyWith<$Res> implements $CoachTurnCopyWith<$Res> {
  factory $CoachPersonTurnCopyWith(CoachPersonTurn value, $Res Function(CoachPersonTurn) _then) = _$CoachPersonTurnCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$CoachPersonTurnCopyWithImpl<$Res>
    implements $CoachPersonTurnCopyWith<$Res> {
  _$CoachPersonTurnCopyWithImpl(this._self, this._then);

  final CoachPersonTurn _self;
  final $Res Function(CoachPersonTurn) _then;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(CoachPersonTurn(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CoachReplyTurn extends CoachTurn {
  const CoachReplyTurn(this.text): super._();
  

 final  String text;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachReplyTurnCopyWith<CoachReplyTurn> get copyWith => _$CoachReplyTurnCopyWithImpl<CoachReplyTurn>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachReplyTurn&&(identical(other.text, text) || other.text == text));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text);
}



}

/// @nodoc
abstract mixin class $CoachReplyTurnCopyWith<$Res> implements $CoachTurnCopyWith<$Res> {
  factory $CoachReplyTurnCopyWith(CoachReplyTurn value, $Res Function(CoachReplyTurn) _then) = _$CoachReplyTurnCopyWithImpl;
@useResult
$Res call({
 String text
});




}
/// @nodoc
class _$CoachReplyTurnCopyWithImpl<$Res>
    implements $CoachReplyTurnCopyWith<$Res> {
  _$CoachReplyTurnCopyWithImpl(this._self, this._then);

  final CoachReplyTurn _self;
  final $Res Function(CoachReplyTurn) _then;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? text = null,}) {
  return _then(CoachReplyTurn(
null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class CoachTopicTurn extends CoachTurn {
  const CoachTopicTurn(this.topic): super._();
  

 final  WeeklyTopic topic;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachTopicTurnCopyWith<CoachTopicTurn> get copyWith => _$CoachTopicTurnCopyWithImpl<CoachTopicTurn>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachTopicTurn&&(identical(other.topic, topic) || other.topic == topic));
}


@override
int get hashCode {
    return Object.hash(runtimeType,topic);
}



}

/// @nodoc
abstract mixin class $CoachTopicTurnCopyWith<$Res> implements $CoachTurnCopyWith<$Res> {
  factory $CoachTopicTurnCopyWith(CoachTopicTurn value, $Res Function(CoachTopicTurn) _then) = _$CoachTopicTurnCopyWithImpl;
@useResult
$Res call({
 WeeklyTopic topic
});




}
/// @nodoc
class _$CoachTopicTurnCopyWithImpl<$Res>
    implements $CoachTopicTurnCopyWith<$Res> {
  _$CoachTopicTurnCopyWithImpl(this._self, this._then);

  final CoachTopicTurn _self;
  final $Res Function(CoachTopicTurn) _then;

/// Create a copy of CoachTurn
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? topic = null,}) {
  return _then(CoachTopicTurn(
null == topic ? _self.topic : topic // ignore: cast_nullable_to_non_nullable
as WeeklyTopic,
  ));
}


}

/// @nodoc
mixin _$CoachRequest {

/// What's asked for.
 CoachRequestKind get kind;/// The whole conversation so far, oldest first. For chat and weekly the
/// last turn is the person's or the app's (the coach replies to it);
/// a summary may end with the coach's, and leaves out app turns.
 List<CoachTurn> get turns;/// The week's compact context (`formatCoachWeek`, at most 1,200
/// characters): required for chat and weekly, `null` for a summary.
 String? get weekContext;
/// Create a copy of CoachRequest
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachRequestCopyWith<CoachRequest> get copyWith => _$CoachRequestCopyWithImpl<CoachRequest>(this as CoachRequest, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachRequest;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachRequest&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&const DeepCollectionEquality().equals(other.turns, _this.turns)&&(identical(other.weekContext, _this.weekContext) || other.weekContext == _this.weekContext));
}


@override
int get hashCode {
  final _this = this as CoachRequest;
  return Object.hash(runtimeType,_this.kind,const DeepCollectionEquality().hash(_this.turns),_this.weekContext);
}



}

/// @nodoc
abstract mixin class $CoachRequestCopyWith<$Res>  {
  factory $CoachRequestCopyWith(CoachRequest value, $Res Function(CoachRequest) _then) = _$CoachRequestCopyWithImpl;
@useResult
$Res call({
 CoachRequestKind kind, List<CoachTurn> turns, String? weekContext
});




}
/// @nodoc
class _$CoachRequestCopyWithImpl<$Res>
    implements $CoachRequestCopyWith<$Res> {
  _$CoachRequestCopyWithImpl(this._self, this._then);

  final CoachRequest _self;
  final $Res Function(CoachRequest) _then;

/// Create a copy of CoachRequest
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? turns = null,Object? weekContext = freezed,}) {
  return _then(CoachRequest(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CoachRequestKind,turns: null == turns ? _self.turns : turns // ignore: cast_nullable_to_non_nullable
as List<CoachTurn>,weekContext: freezed == weekContext ? _self.weekContext : weekContext // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachRequest].
extension CoachRequestPatterns on CoachRequest {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachRequest value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachRequest() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachRequest value)  $default,){
final _that = this;
switch (_that) {
case _CoachRequest():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachRequest value)?  $default,){
final _that = this;
switch (_that) {
case _CoachRequest() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoachRequestKind kind,  List<CoachTurn> turns,  String? weekContext)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachRequest() when $default != null:
return $default(_that.kind,_that.turns,_that.weekContext);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoachRequestKind kind,  List<CoachTurn> turns,  String? weekContext)  $default,) {final _that = this;
switch (_that) {
case _CoachRequest():
return $default(_that.kind,_that.turns,_that.weekContext);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoachRequestKind kind,  List<CoachTurn> turns,  String? weekContext)?  $default,) {final _that = this;
switch (_that) {
case _CoachRequest() when $default != null:
return $default(_that.kind,_that.turns,_that.weekContext);case _:
  return null;

}
}

}

/// @nodoc


class _CoachRequest extends CoachRequest {
  const _CoachRequest({required this.kind, required  List<CoachTurn> turns, this.weekContext}): _turns = turns,super._();
  

/// What's asked for.
@override final  CoachRequestKind kind;
/// The whole conversation so far, oldest first. For chat and weekly the
/// last turn is the person's or the app's (the coach replies to it);
/// a summary may end with the coach's, and leaves out app turns.
 final  List<CoachTurn> _turns;
/// The whole conversation so far, oldest first. For chat and weekly the
/// last turn is the person's or the app's (the coach replies to it);
/// a summary may end with the coach's, and leaves out app turns.
@override List<CoachTurn> get turns {
  if (_turns is EqualUnmodifiableListView) return _turns;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_turns);
}

/// The week's compact context (`formatCoachWeek`, at most 1,200
/// characters): required for chat and weekly, `null` for a summary.
@override final  String? weekContext;

/// Create a copy of CoachRequest
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachRequestCopyWith<_CoachRequest> get copyWith => __$CoachRequestCopyWithImpl<_CoachRequest>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachRequest&&(identical(other.kind, kind) || other.kind == kind)&&const DeepCollectionEquality().equals(other.turns, _turns)&&(identical(other.weekContext, weekContext) || other.weekContext == weekContext));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,const DeepCollectionEquality().hash(_turns),weekContext);
}



}

/// @nodoc
abstract mixin class _$CoachRequestCopyWith<$Res> implements $CoachRequestCopyWith<$Res> {
  factory _$CoachRequestCopyWith(_CoachRequest value, $Res Function(_CoachRequest) _then) = __$CoachRequestCopyWithImpl;
@override @useResult
$Res call({
 CoachRequestKind kind, List<CoachTurn> turns, String? weekContext
});




}
/// @nodoc
class __$CoachRequestCopyWithImpl<$Res>
    implements _$CoachRequestCopyWith<$Res> {
  __$CoachRequestCopyWithImpl(this._self, this._then);

  final _CoachRequest _self;
  final $Res Function(_CoachRequest) _then;

/// Create a copy of CoachRequest
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? turns = null,Object? weekContext = freezed,}) {
  return _then(_CoachRequest(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CoachRequestKind,turns: null == turns ? _self._turns : turns // ignore: cast_nullable_to_non_nullable
as List<CoachTurn>,weekContext: freezed == weekContext ? _self.weekContext : weekContext // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc
mixin _$CoachReplySnapshot {

/// The whole reply so far.
 String get text;/// Why the reply finished, on the last snapshot only; `null` while it
/// streams.
 CoachStopReason? get stopReason;
/// Create a copy of CoachReplySnapshot
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachReplySnapshotCopyWith<CoachReplySnapshot> get copyWith => _$CoachReplySnapshotCopyWithImpl<CoachReplySnapshot>(this as CoachReplySnapshot, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachReplySnapshot;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachReplySnapshot&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.stopReason, _this.stopReason) || other.stopReason == _this.stopReason));
}


@override
int get hashCode {
  final _this = this as CoachReplySnapshot;
  return Object.hash(runtimeType,_this.text,_this.stopReason);
}



}

/// @nodoc
abstract mixin class $CoachReplySnapshotCopyWith<$Res>  {
  factory $CoachReplySnapshotCopyWith(CoachReplySnapshot value, $Res Function(CoachReplySnapshot) _then) = _$CoachReplySnapshotCopyWithImpl;
@useResult
$Res call({
 String text, CoachStopReason? stopReason
});




}
/// @nodoc
class _$CoachReplySnapshotCopyWithImpl<$Res>
    implements $CoachReplySnapshotCopyWith<$Res> {
  _$CoachReplySnapshotCopyWithImpl(this._self, this._then);

  final CoachReplySnapshot _self;
  final $Res Function(CoachReplySnapshot) _then;

/// Create a copy of CoachReplySnapshot
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? text = null,Object? stopReason = freezed,}) {
  return _then(CoachReplySnapshot(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,stopReason: freezed == stopReason ? _self.stopReason : stopReason // ignore: cast_nullable_to_non_nullable
as CoachStopReason?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachReplySnapshot].
extension CoachReplySnapshotPatterns on CoachReplySnapshot {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachReplySnapshot value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachReplySnapshot() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachReplySnapshot value)  $default,){
final _that = this;
switch (_that) {
case _CoachReplySnapshot():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachReplySnapshot value)?  $default,){
final _that = this;
switch (_that) {
case _CoachReplySnapshot() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String text,  CoachStopReason? stopReason)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachReplySnapshot() when $default != null:
return $default(_that.text,_that.stopReason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String text,  CoachStopReason? stopReason)  $default,) {final _that = this;
switch (_that) {
case _CoachReplySnapshot():
return $default(_that.text,_that.stopReason);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String text,  CoachStopReason? stopReason)?  $default,) {final _that = this;
switch (_that) {
case _CoachReplySnapshot() when $default != null:
return $default(_that.text,_that.stopReason);case _:
  return null;

}
}

}

/// @nodoc


class _CoachReplySnapshot extends CoachReplySnapshot {
  const _CoachReplySnapshot({required this.text, this.stopReason}): super._();
  

/// The whole reply so far.
@override final  String text;
/// Why the reply finished, on the last snapshot only; `null` while it
/// streams.
@override final  CoachStopReason? stopReason;

/// Create a copy of CoachReplySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachReplySnapshotCopyWith<_CoachReplySnapshot> get copyWith => __$CoachReplySnapshotCopyWithImpl<_CoachReplySnapshot>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachReplySnapshot&&(identical(other.text, text) || other.text == text)&&(identical(other.stopReason, stopReason) || other.stopReason == stopReason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,text,stopReason);
}



}

/// @nodoc
abstract mixin class _$CoachReplySnapshotCopyWith<$Res> implements $CoachReplySnapshotCopyWith<$Res> {
  factory _$CoachReplySnapshotCopyWith(_CoachReplySnapshot value, $Res Function(_CoachReplySnapshot) _then) = __$CoachReplySnapshotCopyWithImpl;
@override @useResult
$Res call({
 String text, CoachStopReason? stopReason
});




}
/// @nodoc
class __$CoachReplySnapshotCopyWithImpl<$Res>
    implements _$CoachReplySnapshotCopyWith<$Res> {
  __$CoachReplySnapshotCopyWithImpl(this._self, this._then);

  final _CoachReplySnapshot _self;
  final $Res Function(_CoachReplySnapshot) _then;

/// Create a copy of CoachReplySnapshot
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? text = null,Object? stopReason = freezed,}) {
  return _then(_CoachReplySnapshot(
text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,stopReason: freezed == stopReason ? _self.stopReason : stopReason // ignore: cast_nullable_to_non_nullable
as CoachStopReason?,
  ));
}


}

// dart format on
