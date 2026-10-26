// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'coach_session.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CoachMessage {

/// Who wrote it.
 CoachMessageRole get role;/// What was said.
 String get text;/// When it was said.
 DateTime get at;
/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachMessageCopyWith<CoachMessage> get copyWith => _$CoachMessageCopyWithImpl<CoachMessage>(this as CoachMessage, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachMessage;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachMessage&&(identical(other.role, _this.role) || other.role == _this.role)&&(identical(other.text, _this.text) || other.text == _this.text)&&(identical(other.at, _this.at) || other.at == _this.at));
}


@override
int get hashCode {
  final _this = this as CoachMessage;
  return Object.hash(runtimeType,_this.role,_this.text,_this.at);
}



}

/// @nodoc
abstract mixin class $CoachMessageCopyWith<$Res>  {
  factory $CoachMessageCopyWith(CoachMessage value, $Res Function(CoachMessage) _then) = _$CoachMessageCopyWithImpl;
@useResult
$Res call({
 CoachMessageRole role, String text, DateTime at
});




}
/// @nodoc
class _$CoachMessageCopyWithImpl<$Res>
    implements $CoachMessageCopyWith<$Res> {
  _$CoachMessageCopyWithImpl(this._self, this._then);

  final CoachMessage _self;
  final $Res Function(CoachMessage) _then;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? role = null,Object? text = null,Object? at = null,}) {
  return _then(CoachMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CoachMessageRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachMessage].
extension CoachMessagePatterns on CoachMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachMessage value)  $default,){
final _that = this;
switch (_that) {
case _CoachMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachMessage value)?  $default,){
final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( CoachMessageRole role,  String text,  DateTime at)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that.role,_that.text,_that.at);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( CoachMessageRole role,  String text,  DateTime at)  $default,) {final _that = this;
switch (_that) {
case _CoachMessage():
return $default(_that.role,_that.text,_that.at);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( CoachMessageRole role,  String text,  DateTime at)?  $default,) {final _that = this;
switch (_that) {
case _CoachMessage() when $default != null:
return $default(_that.role,_that.text,_that.at);case _:
  return null;

}
}

}

/// @nodoc


class _CoachMessage extends CoachMessage {
  const _CoachMessage({required this.role, required this.text, required this.at}): super._();
  

/// Who wrote it.
@override final  CoachMessageRole role;
/// What was said.
@override final  String text;
/// When it was said.
@override final  DateTime at;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachMessageCopyWith<_CoachMessage> get copyWith => __$CoachMessageCopyWithImpl<_CoachMessage>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachMessage&&(identical(other.role, role) || other.role == role)&&(identical(other.text, text) || other.text == text)&&(identical(other.at, at) || other.at == at));
}


@override
int get hashCode {
    return Object.hash(runtimeType,role,text,at);
}



}

/// @nodoc
abstract mixin class _$CoachMessageCopyWith<$Res> implements $CoachMessageCopyWith<$Res> {
  factory _$CoachMessageCopyWith(_CoachMessage value, $Res Function(_CoachMessage) _then) = __$CoachMessageCopyWithImpl;
@override @useResult
$Res call({
 CoachMessageRole role, String text, DateTime at
});




}
/// @nodoc
class __$CoachMessageCopyWithImpl<$Res>
    implements _$CoachMessageCopyWith<$Res> {
  __$CoachMessageCopyWithImpl(this._self, this._then);

  final _CoachMessage _self;
  final $Res Function(_CoachMessage) _then;

/// Create a copy of CoachMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? role = null,Object? text = null,Object? at = null,}) {
  return _then(_CoachMessage(
role: null == role ? _self.role : role // ignore: cast_nullable_to_non_nullable
as CoachMessageRole,text: null == text ? _self.text : text // ignore: cast_nullable_to_non_nullable
as String,at: null == at ? _self.at : at // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

/// @nodoc
mixin _$CoachSession {

/// Identity, unique per session. Saving a session with an `id` that's
/// already stored replaces it.
///
/// Opaque (e.g. a UUID): never built from what was said, the summary,
/// or a Health value. [toString] prints it, so a log line or error dump
/// can say which session it's about without saying anything about it.
 String get id;/// Chat or the weekly session.
 CoachSessionKind get kind;/// When the session started. Sessions are listed newest first by it.
 DateTime get startedAt;/// The transcript, in the order it was said. Empty until the first
/// message.
 List<CoachMessage> get messages;/// When the session ended; `null` while it's still going (or if it was
/// left without ending).
 DateTime? get endedAt;/// The coach's short summary of the session, once there is one.
 String? get summary;
/// Create a copy of CoachSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachSessionCopyWith<CoachSession> get copyWith => _$CoachSessionCopyWithImpl<CoachSession>(this as CoachSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachSession&&(identical(other.id, _this.id) || other.id == _this.id)&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.startedAt, _this.startedAt) || other.startedAt == _this.startedAt)&&const DeepCollectionEquality().equals(other.messages, _this.messages)&&(identical(other.endedAt, _this.endedAt) || other.endedAt == _this.endedAt)&&(identical(other.summary, _this.summary) || other.summary == _this.summary));
}


@override
int get hashCode {
  final _this = this as CoachSession;
  return Object.hash(runtimeType,_this.id,_this.kind,_this.startedAt,const DeepCollectionEquality().hash(_this.messages),_this.endedAt,_this.summary);
}



}

/// @nodoc
abstract mixin class $CoachSessionCopyWith<$Res>  {
  factory $CoachSessionCopyWith(CoachSession value, $Res Function(CoachSession) _then) = _$CoachSessionCopyWithImpl;
@useResult
$Res call({
 String id, CoachSessionKind kind, DateTime startedAt, List<CoachMessage> messages, DateTime? endedAt, String? summary
});




}
/// @nodoc
class _$CoachSessionCopyWithImpl<$Res>
    implements $CoachSessionCopyWith<$Res> {
  _$CoachSessionCopyWithImpl(this._self, this._then);

  final CoachSession _self;
  final $Res Function(CoachSession) _then;

/// Create a copy of CoachSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? kind = null,Object? startedAt = null,Object? messages = null,Object? endedAt = freezed,Object? summary = freezed,}) {
  return _then(CoachSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CoachSessionKind,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,messages: null == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<CoachMessage>,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachSession].
extension CoachSessionPatterns on CoachSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachSession value)  $default,){
final _that = this;
switch (_that) {
case _CoachSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachSession value)?  $default,){
final _that = this;
switch (_that) {
case _CoachSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id,  CoachSessionKind kind,  DateTime startedAt,  List<CoachMessage> messages,  DateTime? endedAt,  String? summary)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachSession() when $default != null:
return $default(_that.id,_that.kind,_that.startedAt,_that.messages,_that.endedAt,_that.summary);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id,  CoachSessionKind kind,  DateTime startedAt,  List<CoachMessage> messages,  DateTime? endedAt,  String? summary)  $default,) {final _that = this;
switch (_that) {
case _CoachSession():
return $default(_that.id,_that.kind,_that.startedAt,_that.messages,_that.endedAt,_that.summary);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id,  CoachSessionKind kind,  DateTime startedAt,  List<CoachMessage> messages,  DateTime? endedAt,  String? summary)?  $default,) {final _that = this;
switch (_that) {
case _CoachSession() when $default != null:
return $default(_that.id,_that.kind,_that.startedAt,_that.messages,_that.endedAt,_that.summary);case _:
  return null;

}
}

}

/// @nodoc


class _CoachSession extends CoachSession {
  const _CoachSession({required this.id, required this.kind, required this.startedAt,  List<CoachMessage> messages = const <CoachMessage>[], this.endedAt, this.summary}): _messages = messages,super._();
  

/// Identity, unique per session. Saving a session with an `id` that's
/// already stored replaces it.
///
/// Opaque (e.g. a UUID): never built from what was said, the summary,
/// or a Health value. [toString] prints it, so a log line or error dump
/// can say which session it's about without saying anything about it.
@override final  String id;
/// Chat or the weekly session.
@override final  CoachSessionKind kind;
/// When the session started. Sessions are listed newest first by it.
@override final  DateTime startedAt;
/// The transcript, in the order it was said. Empty until the first
/// message.
 final  List<CoachMessage> _messages;
/// The transcript, in the order it was said. Empty until the first
/// message.
@override@JsonKey() List<CoachMessage> get messages {
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_messages);
}

/// When the session ended; `null` while it's still going (or if it was
/// left without ending).
@override final  DateTime? endedAt;
/// The coach's short summary of the session, once there is one.
@override final  String? summary;

/// Create a copy of CoachSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachSessionCopyWith<_CoachSession> get copyWith => __$CoachSessionCopyWithImpl<_CoachSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachSession&&(identical(other.id, id) || other.id == id)&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.startedAt, startedAt) || other.startedAt == startedAt)&&const DeepCollectionEquality().equals(other.messages, _messages)&&(identical(other.endedAt, endedAt) || other.endedAt == endedAt)&&(identical(other.summary, summary) || other.summary == summary));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id,kind,startedAt,const DeepCollectionEquality().hash(_messages),endedAt,summary);
}



}

/// @nodoc
abstract mixin class _$CoachSessionCopyWith<$Res> implements $CoachSessionCopyWith<$Res> {
  factory _$CoachSessionCopyWith(_CoachSession value, $Res Function(_CoachSession) _then) = __$CoachSessionCopyWithImpl;
@override @useResult
$Res call({
 String id, CoachSessionKind kind, DateTime startedAt, List<CoachMessage> messages, DateTime? endedAt, String? summary
});




}
/// @nodoc
class __$CoachSessionCopyWithImpl<$Res>
    implements _$CoachSessionCopyWith<$Res> {
  __$CoachSessionCopyWithImpl(this._self, this._then);

  final _CoachSession _self;
  final $Res Function(_CoachSession) _then;

/// Create a copy of CoachSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? kind = null,Object? startedAt = null,Object? messages = null,Object? endedAt = freezed,Object? summary = freezed,}) {
  return _then(_CoachSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as CoachSessionKind,startedAt: null == startedAt ? _self.startedAt : startedAt // ignore: cast_nullable_to_non_nullable
as DateTime,messages: null == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<CoachMessage>,endedAt: freezed == endedAt ? _self.endedAt : endedAt // ignore: cast_nullable_to_non_nullable
as DateTime?,summary: freezed == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

// dart format on
