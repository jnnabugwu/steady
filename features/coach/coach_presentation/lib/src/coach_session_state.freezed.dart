// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_session_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoachSessionState {

/// Where the session is.
 CoachSessionPhase get phase;/// The session as stored (`CoachRepository`): its id, kind, start, and
/// the transcript so far.
 CoachSession get session;/// The coach's reply so far while [phase] is
/// [CoachSessionPhase.replying]: the latest snapshot, the whole reply
/// so far. `null` until the first snapshot arrives.
 String? get reply;/// Why the session couldn't start ([CoachSessionPhase.unavailable],
/// [CoachSessionPhase.failedToStart]), or why the last reply failed
/// (while [CoachSessionPhase.ready]). `null` otherwise.
 Failure? get failure;/// Whether the last save to the coach history failed. The conversation
/// carries on; the next save writes the whole session again.
 bool get saveFailed;/// Whether the coach's last reply was cut off at the reply cap
/// (`CoachKeepGoing`). It's stored trimmed to its last complete
/// sentence, and the screen offers "Keep going".
 bool get replyCutOff;/// Weekly only: the week it looks back on (its Friday), once known.
 DateTime? get weekFirst;/// Weekly only: the week's Thursday, once known.
 DateTime? get weekLast;/// Weekly only: the session's topics, in order (`weeklyTopicsFor`).
 List<WeeklyTopic> get topics;/// Weekly only: the index in [topics] of the topic under way, or `-1`
/// before the session begins.
 int get topicIndex;
/// Create a copy of CoachSessionState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachSessionStateCopyWith<CoachSessionState> get copyWith => _$CoachSessionStateCopyWithImpl<CoachSessionState>(this as CoachSessionState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachSessionState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachSessionState&&(identical(other.phase, _this.phase) || other.phase == _this.phase)&&(identical(other.session, _this.session) || other.session == _this.session)&&(identical(other.reply, _this.reply) || other.reply == _this.reply)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.saveFailed, _this.saveFailed) || other.saveFailed == _this.saveFailed)&&(identical(other.replyCutOff, _this.replyCutOff) || other.replyCutOff == _this.replyCutOff)&&(identical(other.weekFirst, _this.weekFirst) || other.weekFirst == _this.weekFirst)&&(identical(other.weekLast, _this.weekLast) || other.weekLast == _this.weekLast)&&const DeepCollectionEquality().equals(other.topics, _this.topics)&&(identical(other.topicIndex, _this.topicIndex) || other.topicIndex == _this.topicIndex));
}


@override
int get hashCode {
  final _this = this as CoachSessionState;
  return Object.hash(runtimeType,_this.phase,_this.session,_this.reply,_this.failure,_this.saveFailed,_this.replyCutOff,_this.weekFirst,_this.weekLast,const DeepCollectionEquality().hash(_this.topics),_this.topicIndex);
}

@override
String toString() {
  final _this = this as CoachSessionState;
  return 'CoachSessionState(phase: ${_this.phase}, session: ${_this.session}, reply: ${_this.reply}, failure: ${_this.failure}, saveFailed: ${_this.saveFailed}, replyCutOff: ${_this.replyCutOff}, weekFirst: ${_this.weekFirst}, weekLast: ${_this.weekLast}, topics: ${_this.topics}, topicIndex: ${_this.topicIndex})';
}


}

/// @nodoc
abstract mixin class $CoachSessionStateCopyWith<$Res>  {
  factory $CoachSessionStateCopyWith(CoachSessionState value, $Res Function(CoachSessionState) _then) = _$CoachSessionStateCopyWithImpl;
@useResult
$Res call({
 CoachSessionPhase phase, CoachSession session, String? reply, Failure? failure, bool saveFailed, bool replyCutOff, DateTime? weekFirst, DateTime? weekLast, List<WeeklyTopic> topics, int topicIndex
});


$CoachSessionCopyWith<$Res> get session;

}
/// @nodoc
class _$CoachSessionStateCopyWithImpl<$Res>
    implements $CoachSessionStateCopyWith<$Res> {
  _$CoachSessionStateCopyWithImpl(this._self, this._then);

  final CoachSessionState _self;
  final $Res Function(CoachSessionState) _then;

/// Create a copy of CoachSessionState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? phase = null,Object? session = null,Object? reply = freezed,Object? failure = freezed,Object? saveFailed = null,Object? replyCutOff = null,Object? weekFirst = freezed,Object? weekLast = freezed,Object? topics = null,Object? topicIndex = null,}) {
  return _then(CoachSessionState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CoachSessionPhase,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as CoachSession,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,saveFailed: null == saveFailed ? _self.saveFailed : saveFailed // ignore: cast_nullable_to_non_nullable
as bool,replyCutOff: null == replyCutOff ? _self.replyCutOff : replyCutOff // ignore: cast_nullable_to_non_nullable
as bool,weekFirst: freezed == weekFirst ? _self.weekFirst : weekFirst // ignore: cast_nullable_to_non_nullable
as DateTime?,weekLast: freezed == weekLast ? _self.weekLast : weekLast // ignore: cast_nullable_to_non_nullable
as DateTime?,topics: null == topics ? _self.topics : topics // ignore: cast_nullable_to_non_nullable
as List<WeeklyTopic>,topicIndex: null == topicIndex ? _self.topicIndex : topicIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}
/// Create a copy of CoachSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachSessionCopyWith<$Res> get session {
  
  return $CoachSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}


/// Adds pattern-matching-related methods to [CoachSessionState].
extension CoachSessionStatePatterns on CoachSessionState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachSessionState value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachSessionState() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachSessionState value)  $default,){
final _that = this;
switch (_that) {
case _CoachSessionState():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachSessionState value)?  $default,){
final _that = this;
switch (_that) {
case _CoachSessionState() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoachSessionPhase phase,  CoachSession session,  String? reply,  Failure? failure,  bool saveFailed,  bool replyCutOff,  DateTime? weekFirst,  DateTime? weekLast,  List<WeeklyTopic> topics,  int topicIndex)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachSessionState() when $default != null:
return $default(_that.phase,_that.session,_that.reply,_that.failure,_that.saveFailed,_that.replyCutOff,_that.weekFirst,_that.weekLast,_that.topics,_that.topicIndex);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoachSessionPhase phase,  CoachSession session,  String? reply,  Failure? failure,  bool saveFailed,  bool replyCutOff,  DateTime? weekFirst,  DateTime? weekLast,  List<WeeklyTopic> topics,  int topicIndex)  $default,) {final _that = this;
switch (_that) {
case _CoachSessionState():
return $default(_that.phase,_that.session,_that.reply,_that.failure,_that.saveFailed,_that.replyCutOff,_that.weekFirst,_that.weekLast,_that.topics,_that.topicIndex);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoachSessionPhase phase,  CoachSession session,  String? reply,  Failure? failure,  bool saveFailed,  bool replyCutOff,  DateTime? weekFirst,  DateTime? weekLast,  List<WeeklyTopic> topics,  int topicIndex)?  $default,) {final _that = this;
switch (_that) {
case _CoachSessionState() when $default != null:
return $default(_that.phase,_that.session,_that.reply,_that.failure,_that.saveFailed,_that.replyCutOff,_that.weekFirst,_that.weekLast,_that.topics,_that.topicIndex);case _:
  return null;

}
}

}

/// @nodoc


class _CoachSessionState extends CoachSessionState {
  const _CoachSessionState({required this.phase, required this.session, this.reply, this.failure, this.saveFailed = false, this.replyCutOff = false, this.weekFirst, this.weekLast,  List<WeeklyTopic> topics = const <WeeklyTopic>[], this.topicIndex = -1}): _topics = topics,super._();
  

/// Where the session is.
@override final  CoachSessionPhase phase;
/// The session as stored (`CoachRepository`): its id, kind, start, and
/// the transcript so far.
@override final  CoachSession session;
/// The coach's reply so far while [phase] is
/// [CoachSessionPhase.replying]: the latest snapshot, the whole reply
/// so far. `null` until the first snapshot arrives.
@override final  String? reply;
/// Why the session couldn't start ([CoachSessionPhase.unavailable],
/// [CoachSessionPhase.failedToStart]), or why the last reply failed
/// (while [CoachSessionPhase.ready]). `null` otherwise.
@override final  Failure? failure;
/// Whether the last save to the coach history failed. The conversation
/// carries on; the next save writes the whole session again.
@override@JsonKey() final  bool saveFailed;
/// Whether the coach's last reply was cut off at the reply cap
/// (`CoachKeepGoing`). It's stored trimmed to its last complete
/// sentence, and the screen offers "Keep going".
@override@JsonKey() final  bool replyCutOff;
/// Weekly only: the week it looks back on (its Friday), once known.
@override final  DateTime? weekFirst;
/// Weekly only: the week's Thursday, once known.
@override final  DateTime? weekLast;
/// Weekly only: the session's topics, in order (`weeklyTopicsFor`).
 final  List<WeeklyTopic> _topics;
/// Weekly only: the session's topics, in order (`weeklyTopicsFor`).
@override@JsonKey() List<WeeklyTopic> get topics {
  if (_topics is EqualUnmodifiableListView) return _topics;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topics);
}

/// Weekly only: the index in [topics] of the topic under way, or `-1`
/// before the session begins.
@override@JsonKey() final  int topicIndex;

/// Create a copy of CoachSessionState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachSessionStateCopyWith<_CoachSessionState> get copyWith => __$CoachSessionStateCopyWithImpl<_CoachSessionState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachSessionState&&(identical(other.phase, phase) || other.phase == phase)&&(identical(other.session, session) || other.session == session)&&(identical(other.reply, reply) || other.reply == reply)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.saveFailed, saveFailed) || other.saveFailed == saveFailed)&&(identical(other.replyCutOff, replyCutOff) || other.replyCutOff == replyCutOff)&&(identical(other.weekFirst, weekFirst) || other.weekFirst == weekFirst)&&(identical(other.weekLast, weekLast) || other.weekLast == weekLast)&&const DeepCollectionEquality().equals(other.topics, _topics)&&(identical(other.topicIndex, topicIndex) || other.topicIndex == topicIndex));
}


@override
int get hashCode {
    return Object.hash(runtimeType,phase,session,reply,failure,saveFailed,replyCutOff,weekFirst,weekLast,const DeepCollectionEquality().hash(_topics),topicIndex);
}

@override
String toString() {
    return 'CoachSessionState(phase: $phase, session: $session, reply: $reply, failure: $failure, saveFailed: $saveFailed, replyCutOff: $replyCutOff, weekFirst: $weekFirst, weekLast: $weekLast, topics: $topics, topicIndex: $topicIndex)';
}


}

/// @nodoc
abstract mixin class _$CoachSessionStateCopyWith<$Res> implements $CoachSessionStateCopyWith<$Res> {
  factory _$CoachSessionStateCopyWith(_CoachSessionState value, $Res Function(_CoachSessionState) _then) = __$CoachSessionStateCopyWithImpl;
@override @useResult
$Res call({
 CoachSessionPhase phase, CoachSession session, String? reply, Failure? failure, bool saveFailed, bool replyCutOff, DateTime? weekFirst, DateTime? weekLast, List<WeeklyTopic> topics, int topicIndex
});


@override $CoachSessionCopyWith<$Res> get session;

}
/// @nodoc
class __$CoachSessionStateCopyWithImpl<$Res>
    implements _$CoachSessionStateCopyWith<$Res> {
  __$CoachSessionStateCopyWithImpl(this._self, this._then);

  final _CoachSessionState _self;
  final $Res Function(_CoachSessionState) _then;

/// Create a copy of CoachSessionState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? phase = null,Object? session = null,Object? reply = freezed,Object? failure = freezed,Object? saveFailed = null,Object? replyCutOff = null,Object? weekFirst = freezed,Object? weekLast = freezed,Object? topics = null,Object? topicIndex = null,}) {
  return _then(_CoachSessionState(
phase: null == phase ? _self.phase : phase // ignore: cast_nullable_to_non_nullable
as CoachSessionPhase,session: null == session ? _self.session : session // ignore: cast_nullable_to_non_nullable
as CoachSession,reply: freezed == reply ? _self.reply : reply // ignore: cast_nullable_to_non_nullable
as String?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,saveFailed: null == saveFailed ? _self.saveFailed : saveFailed // ignore: cast_nullable_to_non_nullable
as bool,replyCutOff: null == replyCutOff ? _self.replyCutOff : replyCutOff // ignore: cast_nullable_to_non_nullable
as bool,weekFirst: freezed == weekFirst ? _self.weekFirst : weekFirst // ignore: cast_nullable_to_non_nullable
as DateTime?,weekLast: freezed == weekLast ? _self.weekLast : weekLast // ignore: cast_nullable_to_non_nullable
as DateTime?,topics: null == topics ? _self._topics : topics // ignore: cast_nullable_to_non_nullable
as List<WeeklyTopic>,topicIndex: null == topicIndex ? _self.topicIndex : topicIndex // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

/// Create a copy of CoachSessionState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CoachSessionCopyWith<$Res> get session {
  
  return $CoachSessionCopyWith<$Res>(_self.session, (value) {
    return _then(_self.copyWith(session: value));
  });
}
}

// dart format on
