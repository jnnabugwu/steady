// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_status.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubscriptionStatus {

/// Where this Apple Account stands.
 SubscriptionAccess get access;/// The plan it's on (or was on, when [SubscriptionAccess.lapsed]);
/// `null` for [SubscriptionAccess.none], or for a product that isn't
/// one of Steady's two plans.
 SubscriptionPlan? get plan;/// When the current period ends (the free period's end in a trial), or
/// when it ended once lapsed. `null` for [SubscriptionAccess.none].
 DateTime? get expiresAt;/// Whether it renews at [expiresAt]. `false` once the person has turned
/// renewal off, and for anything not active.
 bool get willRenew;/// Where the person manages or cancels it (Apple's subscriptions page),
/// when the store gives one.
 Uri? get manageUrl;
/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionStatusCopyWith<SubscriptionStatus> get copyWith => _$SubscriptionStatusCopyWithImpl<SubscriptionStatus>(this as SubscriptionStatus, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubscriptionStatus;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionStatus&&(identical(other.access, _this.access) || other.access == _this.access)&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.expiresAt, _this.expiresAt) || other.expiresAt == _this.expiresAt)&&(identical(other.willRenew, _this.willRenew) || other.willRenew == _this.willRenew)&&(identical(other.manageUrl, _this.manageUrl) || other.manageUrl == _this.manageUrl));
}


@override
int get hashCode {
  final _this = this as SubscriptionStatus;
  return Object.hash(runtimeType,_this.access,_this.plan,_this.expiresAt,_this.willRenew,_this.manageUrl);
}

@override
String toString() {
  final _this = this as SubscriptionStatus;
  return 'SubscriptionStatus(access: ${_this.access}, plan: ${_this.plan}, expiresAt: ${_this.expiresAt}, willRenew: ${_this.willRenew}, manageUrl: ${_this.manageUrl})';
}


}

/// @nodoc
abstract mixin class $SubscriptionStatusCopyWith<$Res>  {
  factory $SubscriptionStatusCopyWith(SubscriptionStatus value, $Res Function(SubscriptionStatus) _then) = _$SubscriptionStatusCopyWithImpl;
@useResult
$Res call({
 SubscriptionAccess access, SubscriptionPlan? plan, DateTime? expiresAt, bool willRenew, Uri? manageUrl
});




}
/// @nodoc
class _$SubscriptionStatusCopyWithImpl<$Res>
    implements $SubscriptionStatusCopyWith<$Res> {
  _$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final SubscriptionStatus _self;
  final $Res Function(SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? access = null,Object? plan = freezed,Object? expiresAt = freezed,Object? willRenew = null,Object? manageUrl = freezed,}) {
  return _then(SubscriptionStatus(
access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as SubscriptionAccess,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,manageUrl: freezed == manageUrl ? _self.manageUrl : manageUrl // ignore: cast_nullable_to_non_nullable
as Uri?,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionStatus].
extension SubscriptionStatusPatterns on SubscriptionStatus {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionStatus value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionStatus value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStatus():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionStatus value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubscriptionAccess access,  SubscriptionPlan? plan,  DateTime? expiresAt,  bool willRenew,  Uri? manageUrl)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.access,_that.plan,_that.expiresAt,_that.willRenew,_that.manageUrl);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubscriptionAccess access,  SubscriptionPlan? plan,  DateTime? expiresAt,  bool willRenew,  Uri? manageUrl)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus():
return $default(_that.access,_that.plan,_that.expiresAt,_that.willRenew,_that.manageUrl);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubscriptionAccess access,  SubscriptionPlan? plan,  DateTime? expiresAt,  bool willRenew,  Uri? manageUrl)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionStatus() when $default != null:
return $default(_that.access,_that.plan,_that.expiresAt,_that.willRenew,_that.manageUrl);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionStatus extends SubscriptionStatus {
  const _SubscriptionStatus({required this.access, this.plan, this.expiresAt, this.willRenew = false, this.manageUrl}): super._();
  

/// Where this Apple Account stands.
@override final  SubscriptionAccess access;
/// The plan it's on (or was on, when [SubscriptionAccess.lapsed]);
/// `null` for [SubscriptionAccess.none], or for a product that isn't
/// one of Steady's two plans.
@override final  SubscriptionPlan? plan;
/// When the current period ends (the free period's end in a trial), or
/// when it ended once lapsed. `null` for [SubscriptionAccess.none].
@override final  DateTime? expiresAt;
/// Whether it renews at [expiresAt]. `false` once the person has turned
/// renewal off, and for anything not active.
@override@JsonKey() final  bool willRenew;
/// Where the person manages or cancels it (Apple's subscriptions page),
/// when the store gives one.
@override final  Uri? manageUrl;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionStatusCopyWith<_SubscriptionStatus> get copyWith => __$SubscriptionStatusCopyWithImpl<_SubscriptionStatus>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionStatus&&(identical(other.access, access) || other.access == access)&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.expiresAt, expiresAt) || other.expiresAt == expiresAt)&&(identical(other.willRenew, willRenew) || other.willRenew == willRenew)&&(identical(other.manageUrl, manageUrl) || other.manageUrl == manageUrl));
}


@override
int get hashCode {
    return Object.hash(runtimeType,access,plan,expiresAt,willRenew,manageUrl);
}

@override
String toString() {
    return 'SubscriptionStatus(access: $access, plan: $plan, expiresAt: $expiresAt, willRenew: $willRenew, manageUrl: $manageUrl)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionStatusCopyWith<$Res> implements $SubscriptionStatusCopyWith<$Res> {
  factory _$SubscriptionStatusCopyWith(_SubscriptionStatus value, $Res Function(_SubscriptionStatus) _then) = __$SubscriptionStatusCopyWithImpl;
@override @useResult
$Res call({
 SubscriptionAccess access, SubscriptionPlan? plan, DateTime? expiresAt, bool willRenew, Uri? manageUrl
});




}
/// @nodoc
class __$SubscriptionStatusCopyWithImpl<$Res>
    implements _$SubscriptionStatusCopyWith<$Res> {
  __$SubscriptionStatusCopyWithImpl(this._self, this._then);

  final _SubscriptionStatus _self;
  final $Res Function(_SubscriptionStatus) _then;

/// Create a copy of SubscriptionStatus
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? access = null,Object? plan = freezed,Object? expiresAt = freezed,Object? willRenew = null,Object? manageUrl = freezed,}) {
  return _then(_SubscriptionStatus(
access: null == access ? _self.access : access // ignore: cast_nullable_to_non_nullable
as SubscriptionAccess,plan: freezed == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan?,expiresAt: freezed == expiresAt ? _self.expiresAt : expiresAt // ignore: cast_nullable_to_non_nullable
as DateTime?,willRenew: null == willRenew ? _self.willRenew : willRenew // ignore: cast_nullable_to_non_nullable
as bool,manageUrl: freezed == manageUrl ? _self.manageUrl : manageUrl // ignore: cast_nullable_to_non_nullable
as Uri?,
  ));
}


}

// dart format on
