// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'parsed_food_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ParsedFoodEntry {

/// The food's name, reassembled if it wrapped across multiple lines.
 String get name;/// Calories for this entry.
 int get calories;/// Grams of protein.
 int get proteinG;/// Grams of carbohydrates.
 int get carbsG;/// Grams of fat.
 int get fatG;/// Grams of fiber.
 int get fiberG;/// Grams of sugar.
 int get sugarG;/// Milligrams of sodium.
 int get sodiumMg;/// The raw logged time, e.g. `"3:11pm"`. Kept as a string — no timezone
/// semantics to parse into.
 String get loggedAtTime;
/// Create a copy of ParsedFoodEntry
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ParsedFoodEntryCopyWith<ParsedFoodEntry> get copyWith => _$ParsedFoodEntryCopyWithImpl<ParsedFoodEntry>(this as ParsedFoodEntry, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as ParsedFoodEntry;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ParsedFoodEntry&&(identical(other.name, _this.name) || other.name == _this.name)&&(identical(other.calories, _this.calories) || other.calories == _this.calories)&&(identical(other.proteinG, _this.proteinG) || other.proteinG == _this.proteinG)&&(identical(other.carbsG, _this.carbsG) || other.carbsG == _this.carbsG)&&(identical(other.fatG, _this.fatG) || other.fatG == _this.fatG)&&(identical(other.fiberG, _this.fiberG) || other.fiberG == _this.fiberG)&&(identical(other.sugarG, _this.sugarG) || other.sugarG == _this.sugarG)&&(identical(other.sodiumMg, _this.sodiumMg) || other.sodiumMg == _this.sodiumMg)&&(identical(other.loggedAtTime, _this.loggedAtTime) || other.loggedAtTime == _this.loggedAtTime));
}


@override
int get hashCode {
  final _this = this as ParsedFoodEntry;
  return Object.hash(runtimeType,_this.name,_this.calories,_this.proteinG,_this.carbsG,_this.fatG,_this.fiberG,_this.sugarG,_this.sodiumMg,_this.loggedAtTime);
}

@override
String toString() {
  final _this = this as ParsedFoodEntry;
  return 'ParsedFoodEntry(name: ${_this.name}, calories: ${_this.calories}, proteinG: ${_this.proteinG}, carbsG: ${_this.carbsG}, fatG: ${_this.fatG}, fiberG: ${_this.fiberG}, sugarG: ${_this.sugarG}, sodiumMg: ${_this.sodiumMg}, loggedAtTime: ${_this.loggedAtTime})';
}


}

/// @nodoc
abstract mixin class $ParsedFoodEntryCopyWith<$Res>  {
  factory $ParsedFoodEntryCopyWith(ParsedFoodEntry value, $Res Function(ParsedFoodEntry) _then) = _$ParsedFoodEntryCopyWithImpl;
@useResult
$Res call({
 String name, int calories, int proteinG, int carbsG, int fatG, int fiberG, int sugarG, int sodiumMg, String loggedAtTime
});




}
/// @nodoc
class _$ParsedFoodEntryCopyWithImpl<$Res>
    implements $ParsedFoodEntryCopyWith<$Res> {
  _$ParsedFoodEntryCopyWithImpl(this._self, this._then);

  final ParsedFoodEntry _self;
  final $Res Function(ParsedFoodEntry) _then;

/// Create a copy of ParsedFoodEntry
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? name = null,Object? calories = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,Object? sugarG = null,Object? sodiumMg = null,Object? loggedAtTime = null,}) {
  return _then(ParsedFoodEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as int,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as int,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as int,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as int,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as int,sugarG: null == sugarG ? _self.sugarG : sugarG // ignore: cast_nullable_to_non_nullable
as int,sodiumMg: null == sodiumMg ? _self.sodiumMg : sodiumMg // ignore: cast_nullable_to_non_nullable
as int,loggedAtTime: null == loggedAtTime ? _self.loggedAtTime : loggedAtTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [ParsedFoodEntry].
extension ParsedFoodEntryPatterns on ParsedFoodEntry {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ParsedFoodEntry value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ParsedFoodEntry() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ParsedFoodEntry value)  $default,){
final _that = this;
switch (_that) {
case _ParsedFoodEntry():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ParsedFoodEntry value)?  $default,){
final _that = this;
switch (_that) {
case _ParsedFoodEntry() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String name,  int calories,  int proteinG,  int carbsG,  int fatG,  int fiberG,  int sugarG,  int sodiumMg,  String loggedAtTime)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ParsedFoodEntry() when $default != null:
return $default(_that.name,_that.calories,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.sugarG,_that.sodiumMg,_that.loggedAtTime);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String name,  int calories,  int proteinG,  int carbsG,  int fatG,  int fiberG,  int sugarG,  int sodiumMg,  String loggedAtTime)  $default,) {final _that = this;
switch (_that) {
case _ParsedFoodEntry():
return $default(_that.name,_that.calories,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.sugarG,_that.sodiumMg,_that.loggedAtTime);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String name,  int calories,  int proteinG,  int carbsG,  int fatG,  int fiberG,  int sugarG,  int sodiumMg,  String loggedAtTime)?  $default,) {final _that = this;
switch (_that) {
case _ParsedFoodEntry() when $default != null:
return $default(_that.name,_that.calories,_that.proteinG,_that.carbsG,_that.fatG,_that.fiberG,_that.sugarG,_that.sodiumMg,_that.loggedAtTime);case _:
  return null;

}
}

}

/// @nodoc


class _ParsedFoodEntry implements ParsedFoodEntry {
  const _ParsedFoodEntry({required this.name, required this.calories, required this.proteinG, required this.carbsG, required this.fatG, required this.fiberG, required this.sugarG, required this.sodiumMg, required this.loggedAtTime});
  

/// The food's name, reassembled if it wrapped across multiple lines.
@override final  String name;
/// Calories for this entry.
@override final  int calories;
/// Grams of protein.
@override final  int proteinG;
/// Grams of carbohydrates.
@override final  int carbsG;
/// Grams of fat.
@override final  int fatG;
/// Grams of fiber.
@override final  int fiberG;
/// Grams of sugar.
@override final  int sugarG;
/// Milligrams of sodium.
@override final  int sodiumMg;
/// The raw logged time, e.g. `"3:11pm"`. Kept as a string — no timezone
/// semantics to parse into.
@override final  String loggedAtTime;

/// Create a copy of ParsedFoodEntry
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ParsedFoodEntryCopyWith<_ParsedFoodEntry> get copyWith => __$ParsedFoodEntryCopyWithImpl<_ParsedFoodEntry>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _ParsedFoodEntry&&(identical(other.name, name) || other.name == name)&&(identical(other.calories, calories) || other.calories == calories)&&(identical(other.proteinG, proteinG) || other.proteinG == proteinG)&&(identical(other.carbsG, carbsG) || other.carbsG == carbsG)&&(identical(other.fatG, fatG) || other.fatG == fatG)&&(identical(other.fiberG, fiberG) || other.fiberG == fiberG)&&(identical(other.sugarG, sugarG) || other.sugarG == sugarG)&&(identical(other.sodiumMg, sodiumMg) || other.sodiumMg == sodiumMg)&&(identical(other.loggedAtTime, loggedAtTime) || other.loggedAtTime == loggedAtTime));
}


@override
int get hashCode {
    return Object.hash(runtimeType,name,calories,proteinG,carbsG,fatG,fiberG,sugarG,sodiumMg,loggedAtTime);
}

@override
String toString() {
    return 'ParsedFoodEntry(name: $name, calories: $calories, proteinG: $proteinG, carbsG: $carbsG, fatG: $fatG, fiberG: $fiberG, sugarG: $sugarG, sodiumMg: $sodiumMg, loggedAtTime: $loggedAtTime)';
}


}

/// @nodoc
abstract mixin class _$ParsedFoodEntryCopyWith<$Res> implements $ParsedFoodEntryCopyWith<$Res> {
  factory _$ParsedFoodEntryCopyWith(_ParsedFoodEntry value, $Res Function(_ParsedFoodEntry) _then) = __$ParsedFoodEntryCopyWithImpl;
@override @useResult
$Res call({
 String name, int calories, int proteinG, int carbsG, int fatG, int fiberG, int sugarG, int sodiumMg, String loggedAtTime
});




}
/// @nodoc
class __$ParsedFoodEntryCopyWithImpl<$Res>
    implements _$ParsedFoodEntryCopyWith<$Res> {
  __$ParsedFoodEntryCopyWithImpl(this._self, this._then);

  final _ParsedFoodEntry _self;
  final $Res Function(_ParsedFoodEntry) _then;

/// Create a copy of ParsedFoodEntry
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? name = null,Object? calories = null,Object? proteinG = null,Object? carbsG = null,Object? fatG = null,Object? fiberG = null,Object? sugarG = null,Object? sodiumMg = null,Object? loggedAtTime = null,}) {
  return _then(_ParsedFoodEntry(
name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,calories: null == calories ? _self.calories : calories // ignore: cast_nullable_to_non_nullable
as int,proteinG: null == proteinG ? _self.proteinG : proteinG // ignore: cast_nullable_to_non_nullable
as int,carbsG: null == carbsG ? _self.carbsG : carbsG // ignore: cast_nullable_to_non_nullable
as int,fatG: null == fatG ? _self.fatG : fatG // ignore: cast_nullable_to_non_nullable
as int,fiberG: null == fiberG ? _self.fiberG : fiberG // ignore: cast_nullable_to_non_nullable
as int,sugarG: null == sugarG ? _self.sugarG : sugarG // ignore: cast_nullable_to_non_nullable
as int,sodiumMg: null == sodiumMg ? _self.sodiumMg : sodiumMg // ignore: cast_nullable_to_non_nullable
as int,loggedAtTime: null == loggedAtTime ? _self.loggedAtTime : loggedAtTime // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

// dart format on
