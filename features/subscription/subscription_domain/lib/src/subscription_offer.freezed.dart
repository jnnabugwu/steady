// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'subscription_offer.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SubscriptionPeriod {

 int get count; SubscriptionPeriodUnit get unit;
/// Create a copy of SubscriptionPeriod
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionPeriodCopyWith<SubscriptionPeriod> get copyWith => _$SubscriptionPeriodCopyWithImpl<SubscriptionPeriod>(this as SubscriptionPeriod, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubscriptionPeriod;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionPeriod&&(identical(other.count, _this.count) || other.count == _this.count)&&(identical(other.unit, _this.unit) || other.unit == _this.unit));
}


@override
int get hashCode {
  final _this = this as SubscriptionPeriod;
  return Object.hash(runtimeType,_this.count,_this.unit);
}

@override
String toString() {
  final _this = this as SubscriptionPeriod;
  return 'SubscriptionPeriod(count: ${_this.count}, unit: ${_this.unit})';
}


}

/// @nodoc
abstract mixin class $SubscriptionPeriodCopyWith<$Res>  {
  factory $SubscriptionPeriodCopyWith(SubscriptionPeriod value, $Res Function(SubscriptionPeriod) _then) = _$SubscriptionPeriodCopyWithImpl;
@useResult
$Res call({
 int count, SubscriptionPeriodUnit unit
});




}
/// @nodoc
class _$SubscriptionPeriodCopyWithImpl<$Res>
    implements $SubscriptionPeriodCopyWith<$Res> {
  _$SubscriptionPeriodCopyWithImpl(this._self, this._then);

  final SubscriptionPeriod _self;
  final $Res Function(SubscriptionPeriod) _then;

/// Create a copy of SubscriptionPeriod
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? count = null,Object? unit = null,}) {
  return _then(SubscriptionPeriod(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as SubscriptionPeriodUnit,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionPeriod].
extension SubscriptionPeriodPatterns on SubscriptionPeriod {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionPeriod value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionPeriod() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionPeriod value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPeriod():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionPeriod value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPeriod() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int count,  SubscriptionPeriodUnit unit)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionPeriod() when $default != null:
return $default(_that.count,_that.unit);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int count,  SubscriptionPeriodUnit unit)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPeriod():
return $default(_that.count,_that.unit);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int count,  SubscriptionPeriodUnit unit)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPeriod() when $default != null:
return $default(_that.count,_that.unit);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionPeriod implements SubscriptionPeriod {
  const _SubscriptionPeriod({required this.count, required this.unit});
  

@override final  int count;
@override final  SubscriptionPeriodUnit unit;

/// Create a copy of SubscriptionPeriod
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionPeriodCopyWith<_SubscriptionPeriod> get copyWith => __$SubscriptionPeriodCopyWithImpl<_SubscriptionPeriod>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionPeriod&&(identical(other.count, count) || other.count == count)&&(identical(other.unit, unit) || other.unit == unit));
}


@override
int get hashCode {
    return Object.hash(runtimeType,count,unit);
}

@override
String toString() {
    return 'SubscriptionPeriod(count: $count, unit: $unit)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionPeriodCopyWith<$Res> implements $SubscriptionPeriodCopyWith<$Res> {
  factory _$SubscriptionPeriodCopyWith(_SubscriptionPeriod value, $Res Function(_SubscriptionPeriod) _then) = __$SubscriptionPeriodCopyWithImpl;
@override @useResult
$Res call({
 int count, SubscriptionPeriodUnit unit
});




}
/// @nodoc
class __$SubscriptionPeriodCopyWithImpl<$Res>
    implements _$SubscriptionPeriodCopyWith<$Res> {
  __$SubscriptionPeriodCopyWithImpl(this._self, this._then);

  final _SubscriptionPeriod _self;
  final $Res Function(_SubscriptionPeriod) _then;

/// Create a copy of SubscriptionPeriod
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? count = null,Object? unit = null,}) {
  return _then(_SubscriptionPeriod(
count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,unit: null == unit ? _self.unit : unit // ignore: cast_nullable_to_non_nullable
as SubscriptionPeriodUnit,
  ));
}


}

/// @nodoc
mixin _$FreeTrial {

/// How long it is (one week for Steady's free week).
 SubscriptionPeriod get length;/// Whether this Apple Account can get it.
 TrialEligibility get eligibility;
/// Create a copy of FreeTrial
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FreeTrialCopyWith<FreeTrial> get copyWith => _$FreeTrialCopyWithImpl<FreeTrial>(this as FreeTrial, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as FreeTrial;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FreeTrial&&(identical(other.length, _this.length) || other.length == _this.length)&&(identical(other.eligibility, _this.eligibility) || other.eligibility == _this.eligibility));
}


@override
int get hashCode {
  final _this = this as FreeTrial;
  return Object.hash(runtimeType,_this.length,_this.eligibility);
}

@override
String toString() {
  final _this = this as FreeTrial;
  return 'FreeTrial(length: ${_this.length}, eligibility: ${_this.eligibility})';
}


}

/// @nodoc
abstract mixin class $FreeTrialCopyWith<$Res>  {
  factory $FreeTrialCopyWith(FreeTrial value, $Res Function(FreeTrial) _then) = _$FreeTrialCopyWithImpl;
@useResult
$Res call({
 SubscriptionPeriod length, TrialEligibility eligibility
});


$SubscriptionPeriodCopyWith<$Res> get length;

}
/// @nodoc
class _$FreeTrialCopyWithImpl<$Res>
    implements $FreeTrialCopyWith<$Res> {
  _$FreeTrialCopyWithImpl(this._self, this._then);

  final FreeTrial _self;
  final $Res Function(FreeTrial) _then;

/// Create a copy of FreeTrial
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? length = null,Object? eligibility = null,}) {
  return _then(FreeTrial(
length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as SubscriptionPeriod,eligibility: null == eligibility ? _self.eligibility : eligibility // ignore: cast_nullable_to_non_nullable
as TrialEligibility,
  ));
}
/// Create a copy of FreeTrial
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionPeriodCopyWith<$Res> get length {
  
  return $SubscriptionPeriodCopyWith<$Res>(_self.length, (value) {
    return _then(_self.copyWith(length: value));
  });
}
}


/// Adds pattern-matching-related methods to [FreeTrial].
extension FreeTrialPatterns on FreeTrial {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FreeTrial value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FreeTrial() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FreeTrial value)  $default,){
final _that = this;
switch (_that) {
case _FreeTrial():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FreeTrial value)?  $default,){
final _that = this;
switch (_that) {
case _FreeTrial() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubscriptionPeriod length,  TrialEligibility eligibility)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FreeTrial() when $default != null:
return $default(_that.length,_that.eligibility);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubscriptionPeriod length,  TrialEligibility eligibility)  $default,) {final _that = this;
switch (_that) {
case _FreeTrial():
return $default(_that.length,_that.eligibility);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubscriptionPeriod length,  TrialEligibility eligibility)?  $default,) {final _that = this;
switch (_that) {
case _FreeTrial() when $default != null:
return $default(_that.length,_that.eligibility);case _:
  return null;

}
}

}

/// @nodoc


class _FreeTrial extends FreeTrial {
  const _FreeTrial({required this.length, required this.eligibility}): super._();
  

/// How long it is (one week for Steady's free week).
@override final  SubscriptionPeriod length;
/// Whether this Apple Account can get it.
@override final  TrialEligibility eligibility;

/// Create a copy of FreeTrial
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FreeTrialCopyWith<_FreeTrial> get copyWith => __$FreeTrialCopyWithImpl<_FreeTrial>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _FreeTrial&&(identical(other.length, length) || other.length == length)&&(identical(other.eligibility, eligibility) || other.eligibility == eligibility));
}


@override
int get hashCode {
    return Object.hash(runtimeType,length,eligibility);
}

@override
String toString() {
    return 'FreeTrial(length: $length, eligibility: $eligibility)';
}


}

/// @nodoc
abstract mixin class _$FreeTrialCopyWith<$Res> implements $FreeTrialCopyWith<$Res> {
  factory _$FreeTrialCopyWith(_FreeTrial value, $Res Function(_FreeTrial) _then) = __$FreeTrialCopyWithImpl;
@override @useResult
$Res call({
 SubscriptionPeriod length, TrialEligibility eligibility
});


@override $SubscriptionPeriodCopyWith<$Res> get length;

}
/// @nodoc
class __$FreeTrialCopyWithImpl<$Res>
    implements _$FreeTrialCopyWith<$Res> {
  __$FreeTrialCopyWithImpl(this._self, this._then);

  final _FreeTrial _self;
  final $Res Function(_FreeTrial) _then;

/// Create a copy of FreeTrial
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? length = null,Object? eligibility = null,}) {
  return _then(_FreeTrial(
length: null == length ? _self.length : length // ignore: cast_nullable_to_non_nullable
as SubscriptionPeriod,eligibility: null == eligibility ? _self.eligibility : eligibility // ignore: cast_nullable_to_non_nullable
as TrialEligibility,
  ));
}

/// Create a copy of FreeTrial
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionPeriodCopyWith<$Res> get length {
  
  return $SubscriptionPeriodCopyWith<$Res>(_self.length, (value) {
    return _then(_self.copyWith(length: value));
  });
}
}

/// @nodoc
mixin _$SubscriptionPlanOffer {

/// Which of Steady's plans this is.
 SubscriptionPlan get plan;/// The App Store product id.
 String get productId;/// The billed price, localized by the store ("$4.99", "39,99 €"). The
/// paywall shows this as the largest price (App Store 3.1.2).
 String get price;/// The billed price as a number, in [currencyCode].
 double get amount;/// The ISO 4217 currency code of [amount].
 String get currencyCode;/// How often it bills.
 SubscriptionPeriod get period;/// Its free trial, or `null` if it has none. A paid introductory price
/// isn't something Steady sells, so it's left out rather than shown as
/// a trial.
 FreeTrial? get freeTrial;
/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionPlanOfferCopyWith<SubscriptionPlanOffer> get copyWith => _$SubscriptionPlanOfferCopyWithImpl<SubscriptionPlanOffer>(this as SubscriptionPlanOffer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubscriptionPlanOffer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionPlanOffer&&(identical(other.plan, _this.plan) || other.plan == _this.plan)&&(identical(other.productId, _this.productId) || other.productId == _this.productId)&&(identical(other.price, _this.price) || other.price == _this.price)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.currencyCode, _this.currencyCode) || other.currencyCode == _this.currencyCode)&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.freeTrial, _this.freeTrial) || other.freeTrial == _this.freeTrial));
}


@override
int get hashCode {
  final _this = this as SubscriptionPlanOffer;
  return Object.hash(runtimeType,_this.plan,_this.productId,_this.price,_this.amount,_this.currencyCode,_this.period,_this.freeTrial);
}

@override
String toString() {
  final _this = this as SubscriptionPlanOffer;
  return 'SubscriptionPlanOffer(plan: ${_this.plan}, productId: ${_this.productId}, price: ${_this.price}, amount: ${_this.amount}, currencyCode: ${_this.currencyCode}, period: ${_this.period}, freeTrial: ${_this.freeTrial})';
}


}

/// @nodoc
abstract mixin class $SubscriptionPlanOfferCopyWith<$Res>  {
  factory $SubscriptionPlanOfferCopyWith(SubscriptionPlanOffer value, $Res Function(SubscriptionPlanOffer) _then) = _$SubscriptionPlanOfferCopyWithImpl;
@useResult
$Res call({
 SubscriptionPlan plan, String productId, String price, double amount, String currencyCode, SubscriptionPeriod period, FreeTrial? freeTrial
});


$SubscriptionPeriodCopyWith<$Res> get period;$FreeTrialCopyWith<$Res>? get freeTrial;

}
/// @nodoc
class _$SubscriptionPlanOfferCopyWithImpl<$Res>
    implements $SubscriptionPlanOfferCopyWith<$Res> {
  _$SubscriptionPlanOfferCopyWithImpl(this._self, this._then);

  final SubscriptionPlanOffer _self;
  final $Res Function(SubscriptionPlanOffer) _then;

/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plan = null,Object? productId = null,Object? price = null,Object? amount = null,Object? currencyCode = null,Object? period = null,Object? freeTrial = freezed,}) {
  return _then(SubscriptionPlanOffer(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as SubscriptionPeriod,freeTrial: freezed == freeTrial ? _self.freeTrial : freeTrial // ignore: cast_nullable_to_non_nullable
as FreeTrial?,
  ));
}
/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionPeriodCopyWith<$Res> get period {
  
  return $SubscriptionPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeTrialCopyWith<$Res>? get freeTrial {
    if (_self.freeTrial == null) {
    return null;
  }

  return $FreeTrialCopyWith<$Res>(_self.freeTrial!, (value) {
    return _then(_self.copyWith(freeTrial: value));
  });
}
}


/// Adds pattern-matching-related methods to [SubscriptionPlanOffer].
extension SubscriptionPlanOfferPatterns on SubscriptionPlanOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionPlanOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionPlanOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionPlanOffer value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPlanOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionPlanOffer value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionPlanOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( SubscriptionPlan plan,  String productId,  String price,  double amount,  String currencyCode,  SubscriptionPeriod period,  FreeTrial? freeTrial)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionPlanOffer() when $default != null:
return $default(_that.plan,_that.productId,_that.price,_that.amount,_that.currencyCode,_that.period,_that.freeTrial);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( SubscriptionPlan plan,  String productId,  String price,  double amount,  String currencyCode,  SubscriptionPeriod period,  FreeTrial? freeTrial)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPlanOffer():
return $default(_that.plan,_that.productId,_that.price,_that.amount,_that.currencyCode,_that.period,_that.freeTrial);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( SubscriptionPlan plan,  String productId,  String price,  double amount,  String currencyCode,  SubscriptionPeriod period,  FreeTrial? freeTrial)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionPlanOffer() when $default != null:
return $default(_that.plan,_that.productId,_that.price,_that.amount,_that.currencyCode,_that.period,_that.freeTrial);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionPlanOffer implements SubscriptionPlanOffer {
  const _SubscriptionPlanOffer({required this.plan, required this.productId, required this.price, required this.amount, required this.currencyCode, required this.period, this.freeTrial});
  

/// Which of Steady's plans this is.
@override final  SubscriptionPlan plan;
/// The App Store product id.
@override final  String productId;
/// The billed price, localized by the store ("$4.99", "39,99 €"). The
/// paywall shows this as the largest price (App Store 3.1.2).
@override final  String price;
/// The billed price as a number, in [currencyCode].
@override final  double amount;
/// The ISO 4217 currency code of [amount].
@override final  String currencyCode;
/// How often it bills.
@override final  SubscriptionPeriod period;
/// Its free trial, or `null` if it has none. A paid introductory price
/// isn't something Steady sells, so it's left out rather than shown as
/// a trial.
@override final  FreeTrial? freeTrial;

/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionPlanOfferCopyWith<_SubscriptionPlanOffer> get copyWith => __$SubscriptionPlanOfferCopyWithImpl<_SubscriptionPlanOffer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionPlanOffer&&(identical(other.plan, plan) || other.plan == plan)&&(identical(other.productId, productId) || other.productId == productId)&&(identical(other.price, price) || other.price == price)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.period, period) || other.period == period)&&(identical(other.freeTrial, freeTrial) || other.freeTrial == freeTrial));
}


@override
int get hashCode {
    return Object.hash(runtimeType,plan,productId,price,amount,currencyCode,period,freeTrial);
}

@override
String toString() {
    return 'SubscriptionPlanOffer(plan: $plan, productId: $productId, price: $price, amount: $amount, currencyCode: $currencyCode, period: $period, freeTrial: $freeTrial)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionPlanOfferCopyWith<$Res> implements $SubscriptionPlanOfferCopyWith<$Res> {
  factory _$SubscriptionPlanOfferCopyWith(_SubscriptionPlanOffer value, $Res Function(_SubscriptionPlanOffer) _then) = __$SubscriptionPlanOfferCopyWithImpl;
@override @useResult
$Res call({
 SubscriptionPlan plan, String productId, String price, double amount, String currencyCode, SubscriptionPeriod period, FreeTrial? freeTrial
});


@override $SubscriptionPeriodCopyWith<$Res> get period;@override $FreeTrialCopyWith<$Res>? get freeTrial;

}
/// @nodoc
class __$SubscriptionPlanOfferCopyWithImpl<$Res>
    implements _$SubscriptionPlanOfferCopyWith<$Res> {
  __$SubscriptionPlanOfferCopyWithImpl(this._self, this._then);

  final _SubscriptionPlanOffer _self;
  final $Res Function(_SubscriptionPlanOffer) _then;

/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plan = null,Object? productId = null,Object? price = null,Object? amount = null,Object? currencyCode = null,Object? period = null,Object? freeTrial = freezed,}) {
  return _then(_SubscriptionPlanOffer(
plan: null == plan ? _self.plan : plan // ignore: cast_nullable_to_non_nullable
as SubscriptionPlan,productId: null == productId ? _self.productId : productId // ignore: cast_nullable_to_non_nullable
as String,price: null == price ? _self.price : price // ignore: cast_nullable_to_non_nullable
as String,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as SubscriptionPeriod,freeTrial: freezed == freeTrial ? _self.freeTrial : freeTrial // ignore: cast_nullable_to_non_nullable
as FreeTrial?,
  ));
}

/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SubscriptionPeriodCopyWith<$Res> get period {
  
  return $SubscriptionPeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of SubscriptionPlanOffer
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FreeTrialCopyWith<$Res>? get freeTrial {
    if (_self.freeTrial == null) {
    return null;
  }

  return $FreeTrialCopyWith<$Res>(_self.freeTrial!, (value) {
    return _then(_self.copyWith(freeTrial: value));
  });
}
}

/// @nodoc
mixin _$SubscriptionOffer {

/// On sale now, monthly first.
 List<SubscriptionPlanOffer> get plans;
/// Create a copy of SubscriptionOffer
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SubscriptionOfferCopyWith<SubscriptionOffer> get copyWith => _$SubscriptionOfferCopyWithImpl<SubscriptionOffer>(this as SubscriptionOffer, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SubscriptionOffer;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SubscriptionOffer&&const DeepCollectionEquality().equals(other.plans, _this.plans));
}


@override
int get hashCode {
  final _this = this as SubscriptionOffer;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.plans));
}

@override
String toString() {
  final _this = this as SubscriptionOffer;
  return 'SubscriptionOffer(plans: ${_this.plans})';
}


}

/// @nodoc
abstract mixin class $SubscriptionOfferCopyWith<$Res>  {
  factory $SubscriptionOfferCopyWith(SubscriptionOffer value, $Res Function(SubscriptionOffer) _then) = _$SubscriptionOfferCopyWithImpl;
@useResult
$Res call({
 List<SubscriptionPlanOffer> plans
});




}
/// @nodoc
class _$SubscriptionOfferCopyWithImpl<$Res>
    implements $SubscriptionOfferCopyWith<$Res> {
  _$SubscriptionOfferCopyWithImpl(this._self, this._then);

  final SubscriptionOffer _self;
  final $Res Function(SubscriptionOffer) _then;

/// Create a copy of SubscriptionOffer
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? plans = null,}) {
  return _then(SubscriptionOffer(
plans: null == plans ? _self.plans : plans // ignore: cast_nullable_to_non_nullable
as List<SubscriptionPlanOffer>,
  ));
}

}


/// Adds pattern-matching-related methods to [SubscriptionOffer].
extension SubscriptionOfferPatterns on SubscriptionOffer {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SubscriptionOffer value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SubscriptionOffer() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SubscriptionOffer value)  $default,){
final _that = this;
switch (_that) {
case _SubscriptionOffer():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SubscriptionOffer value)?  $default,){
final _that = this;
switch (_that) {
case _SubscriptionOffer() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<SubscriptionPlanOffer> plans)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SubscriptionOffer() when $default != null:
return $default(_that.plans);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<SubscriptionPlanOffer> plans)  $default,) {final _that = this;
switch (_that) {
case _SubscriptionOffer():
return $default(_that.plans);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<SubscriptionPlanOffer> plans)?  $default,) {final _that = this;
switch (_that) {
case _SubscriptionOffer() when $default != null:
return $default(_that.plans);case _:
  return null;

}
}

}

/// @nodoc


class _SubscriptionOffer extends SubscriptionOffer {
  const _SubscriptionOffer({required  List<SubscriptionPlanOffer> plans}): _plans = plans,super._();
  

/// On sale now, monthly first.
 final  List<SubscriptionPlanOffer> _plans;
/// On sale now, monthly first.
@override List<SubscriptionPlanOffer> get plans {
  if (_plans is EqualUnmodifiableListView) return _plans;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_plans);
}


/// Create a copy of SubscriptionOffer
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SubscriptionOfferCopyWith<_SubscriptionOffer> get copyWith => __$SubscriptionOfferCopyWithImpl<_SubscriptionOffer>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SubscriptionOffer&&const DeepCollectionEquality().equals(other.plans, _plans));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_plans));
}

@override
String toString() {
    return 'SubscriptionOffer(plans: $plans)';
}


}

/// @nodoc
abstract mixin class _$SubscriptionOfferCopyWith<$Res> implements $SubscriptionOfferCopyWith<$Res> {
  factory _$SubscriptionOfferCopyWith(_SubscriptionOffer value, $Res Function(_SubscriptionOffer) _then) = __$SubscriptionOfferCopyWithImpl;
@override @useResult
$Res call({
 List<SubscriptionPlanOffer> plans
});




}
/// @nodoc
class __$SubscriptionOfferCopyWithImpl<$Res>
    implements _$SubscriptionOfferCopyWith<$Res> {
  __$SubscriptionOfferCopyWithImpl(this._self, this._then);

  final _SubscriptionOffer _self;
  final $Res Function(_SubscriptionOffer) _then;

/// Create a copy of SubscriptionOffer
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? plans = null,}) {
  return _then(_SubscriptionOffer(
plans: null == plans ? _self._plans : plans // ignore: cast_nullable_to_non_nullable
as List<SubscriptionPlanOffer>,
  ));
}


}

// dart format on
