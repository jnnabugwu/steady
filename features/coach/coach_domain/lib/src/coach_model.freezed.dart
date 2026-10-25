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
mixin _$CoachModelInfo {

/// The model's context window, in tokens: everything in one session
/// (instructions, data, prompts and replies) has to fit. 4,096 on
/// iOS 26; read from the device, since a later iOS can change it.
 int get contextSize;
/// Create a copy of CoachModelInfo
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachModelInfoCopyWith<CoachModelInfo> get copyWith => _$CoachModelInfoCopyWithImpl<CoachModelInfo>(this as CoachModelInfo, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachModelInfo;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachModelInfo&&(identical(other.contextSize, _this.contextSize) || other.contextSize == _this.contextSize));
}


@override
int get hashCode {
  final _this = this as CoachModelInfo;
  return Object.hash(runtimeType,_this.contextSize);
}

@override
String toString() {
  final _this = this as CoachModelInfo;
  return 'CoachModelInfo(contextSize: ${_this.contextSize})';
}


}

/// @nodoc
abstract mixin class $CoachModelInfoCopyWith<$Res>  {
  factory $CoachModelInfoCopyWith(CoachModelInfo value, $Res Function(CoachModelInfo) _then) = _$CoachModelInfoCopyWithImpl;
@useResult
$Res call({
 int contextSize
});




}
/// @nodoc
class _$CoachModelInfoCopyWithImpl<$Res>
    implements $CoachModelInfoCopyWith<$Res> {
  _$CoachModelInfoCopyWithImpl(this._self, this._then);

  final CoachModelInfo _self;
  final $Res Function(CoachModelInfo) _then;

/// Create a copy of CoachModelInfo
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? contextSize = null,}) {
  return _then(CoachModelInfo(
contextSize: null == contextSize ? _self.contextSize : contextSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachModelInfo].
extension CoachModelInfoPatterns on CoachModelInfo {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachModelInfo value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachModelInfo() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachModelInfo value)  $default,){
final _that = this;
switch (_that) {
case _CoachModelInfo():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachModelInfo value)?  $default,){
final _that = this;
switch (_that) {
case _CoachModelInfo() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int contextSize)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachModelInfo() when $default != null:
return $default(_that.contextSize);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int contextSize)  $default,) {final _that = this;
switch (_that) {
case _CoachModelInfo():
return $default(_that.contextSize);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int contextSize)?  $default,) {final _that = this;
switch (_that) {
case _CoachModelInfo() when $default != null:
return $default(_that.contextSize);case _:
  return null;

}
}

}

/// @nodoc


class _CoachModelInfo implements CoachModelInfo {
  const _CoachModelInfo({required this.contextSize});
  

/// The model's context window, in tokens: everything in one session
/// (instructions, data, prompts and replies) has to fit. 4,096 on
/// iOS 26; read from the device, since a later iOS can change it.
@override final  int contextSize;

/// Create a copy of CoachModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachModelInfoCopyWith<_CoachModelInfo> get copyWith => __$CoachModelInfoCopyWithImpl<_CoachModelInfo>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachModelInfo&&(identical(other.contextSize, contextSize) || other.contextSize == contextSize));
}


@override
int get hashCode {
    return Object.hash(runtimeType,contextSize);
}

@override
String toString() {
    return 'CoachModelInfo(contextSize: $contextSize)';
}


}

/// @nodoc
abstract mixin class _$CoachModelInfoCopyWith<$Res> implements $CoachModelInfoCopyWith<$Res> {
  factory _$CoachModelInfoCopyWith(_CoachModelInfo value, $Res Function(_CoachModelInfo) _then) = __$CoachModelInfoCopyWithImpl;
@override @useResult
$Res call({
 int contextSize
});




}
/// @nodoc
class __$CoachModelInfoCopyWithImpl<$Res>
    implements _$CoachModelInfoCopyWith<$Res> {
  __$CoachModelInfoCopyWithImpl(this._self, this._then);

  final _CoachModelInfo _self;
  final $Res Function(_CoachModelInfo) _then;

/// Create a copy of CoachModelInfo
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? contextSize = null,}) {
  return _then(_CoachModelInfo(
contextSize: null == contextSize ? _self.contextSize : contextSize // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$CoachModelSession {

/// The native side's id for the session.
 String get id;
/// Create a copy of CoachModelSession
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CoachModelSessionCopyWith<CoachModelSession> get copyWith => _$CoachModelSessionCopyWithImpl<CoachModelSession>(this as CoachModelSession, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as CoachModelSession;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CoachModelSession&&(identical(other.id, _this.id) || other.id == _this.id));
}


@override
int get hashCode {
  final _this = this as CoachModelSession;
  return Object.hash(runtimeType,_this.id);
}

@override
String toString() {
  final _this = this as CoachModelSession;
  return 'CoachModelSession(id: ${_this.id})';
}


}

/// @nodoc
abstract mixin class $CoachModelSessionCopyWith<$Res>  {
  factory $CoachModelSessionCopyWith(CoachModelSession value, $Res Function(CoachModelSession) _then) = _$CoachModelSessionCopyWithImpl;
@useResult
$Res call({
 String id
});




}
/// @nodoc
class _$CoachModelSessionCopyWithImpl<$Res>
    implements $CoachModelSessionCopyWith<$Res> {
  _$CoachModelSessionCopyWithImpl(this._self, this._then);

  final CoachModelSession _self;
  final $Res Function(CoachModelSession) _then;

/// Create a copy of CoachModelSession
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,}) {
  return _then(CoachModelSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [CoachModelSession].
extension CoachModelSessionPatterns on CoachModelSession {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CoachModelSession value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CoachModelSession() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CoachModelSession value)  $default,){
final _that = this;
switch (_that) {
case _CoachModelSession():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CoachModelSession value)?  $default,){
final _that = this;
switch (_that) {
case _CoachModelSession() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String id)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CoachModelSession() when $default != null:
return $default(_that.id);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String id)  $default,) {final _that = this;
switch (_that) {
case _CoachModelSession():
return $default(_that.id);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String id)?  $default,) {final _that = this;
switch (_that) {
case _CoachModelSession() when $default != null:
return $default(_that.id);case _:
  return null;

}
}

}

/// @nodoc


class _CoachModelSession implements CoachModelSession {
  const _CoachModelSession({required this.id});
  

/// The native side's id for the session.
@override final  String id;

/// Create a copy of CoachModelSession
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CoachModelSessionCopyWith<_CoachModelSession> get copyWith => __$CoachModelSessionCopyWithImpl<_CoachModelSession>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _CoachModelSession&&(identical(other.id, id) || other.id == id));
}


@override
int get hashCode {
    return Object.hash(runtimeType,id);
}

@override
String toString() {
    return 'CoachModelSession(id: $id)';
}


}

/// @nodoc
abstract mixin class _$CoachModelSessionCopyWith<$Res> implements $CoachModelSessionCopyWith<$Res> {
  factory _$CoachModelSessionCopyWith(_CoachModelSession value, $Res Function(_CoachModelSession) _then) = __$CoachModelSessionCopyWithImpl;
@override @useResult
$Res call({
 String id
});




}
/// @nodoc
class __$CoachModelSessionCopyWithImpl<$Res>
    implements _$CoachModelSessionCopyWith<$Res> {
  __$CoachModelSessionCopyWithImpl(this._self, this._then);

  final _CoachModelSession _self;
  final $Res Function(_CoachModelSession) _then;

/// Create a copy of CoachModelSession
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,}) {
  return _then(_CoachModelSession(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
