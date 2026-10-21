// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'weekly_bucket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WeeklyBucket {

/// The anchor day of this bucket.
 DateTime get weekStart;/// The days in this bucket. 1-7 entries; may be fewer than 7 for a
/// partial/edge week. Stored as an unmodifiable copy so the bucket
/// keeps value semantics (it goes into equality) even if the caller
/// mutates the list it passed in — and stays safe as a `Set` element
/// or `Map` key.
 List<DailyMetric> get days;



@override
bool operator ==(Object other) {
  final _this = this as WeeklyBucket;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WeeklyBucket&&(identical(other.weekStart, _this.weekStart) || other.weekStart == _this.weekStart)&&const DeepCollectionEquality().equals(other.days, _this.days));
}


@override
int get hashCode {
  final _this = this as WeeklyBucket;
  return Object.hash(runtimeType,_this.weekStart,const DeepCollectionEquality().hash(_this.days));
}

@override
String toString() {
  final _this = this as WeeklyBucket;
  return 'WeeklyBucket(weekStart: ${_this.weekStart}, days: ${_this.days})';
}


}





/// @nodoc


class _WeeklyBucket extends WeeklyBucket {
  const _WeeklyBucket({required this.weekStart, required  List<DailyMetric> days}): _days = days,super._();
  

/// The anchor day of this bucket.
@override final  DateTime weekStart;
/// The days in this bucket. 1-7 entries; may be fewer than 7 for a
/// partial/edge week. Stored as an unmodifiable copy so the bucket
/// keeps value semantics (it goes into equality) even if the caller
/// mutates the list it passed in — and stays safe as a `Set` element
/// or `Map` key.
 final  List<DailyMetric> _days;
/// The days in this bucket. 1-7 entries; may be fewer than 7 for a
/// partial/edge week. Stored as an unmodifiable copy so the bucket
/// keeps value semantics (it goes into equality) even if the caller
/// mutates the list it passed in — and stays safe as a `Set` element
/// or `Map` key.
@override List<DailyMetric> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _WeeklyBucket&&(identical(other.weekStart, weekStart) || other.weekStart == weekStart)&&const DeepCollectionEquality().equals(other.days, _days));
}


@override
int get hashCode {
    return Object.hash(runtimeType,weekStart,const DeepCollectionEquality().hash(_days));
}

@override
String toString() {
    return 'WeeklyBucket._create(weekStart: $weekStart, days: $days)';
}


}




// dart format on
