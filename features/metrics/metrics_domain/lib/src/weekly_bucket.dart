import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'weekly_bucket.freezed.dart';

/// A week's worth of `DailyMetric` rows, plus derived totals.
///
/// `copyWith: false` because freezed's generated `copyWith` calls the
/// generated constructor directly, skipping the copy in the public factory
/// below. Buckets are only ever built by `bucketIntoWeeks`, so nothing
/// needs it. No `when`/`map` either: this isn't a union, and freezed names
/// their parameters after the private `_create` constructor, which doesn't
/// compile.
@Freezed(
  copyWith: false,
  map: FreezedMapOptions.none,
  when: FreezedWhenOptions.none,
)
abstract class WeeklyBucket with _$WeeklyBucket {
  /// Copies [days] into an unmodifiable list; see the [days] getter doc.
  ///
  /// Not `const`: freezed alone only wraps the caller's list in an
  /// unmodifiable view, so mutating that list afterwards would still show
  /// through the bucket.
  factory WeeklyBucket({
    required DateTime weekStart,
    required List<DailyMetric> days,
  }) =>
      WeeklyBucket._create(weekStart: weekStart, days: List.unmodifiable(days));

  // Field docs live here: freezed copies them onto the generated getters
  // from the redirecting constructor.
  const factory WeeklyBucket._create({
    /// The anchor day of this bucket.
    required DateTime weekStart,

    /// The days in this bucket. 1-7 entries; may be fewer than 7 for a
    /// partial/edge week. Stored as an unmodifiable copy so the bucket
    /// keeps value semantics (it goes into equality) even if the caller
    /// mutates the list it passed in — and stays safe as a `Set` element
    /// or `Map` key.
    required List<DailyMetric> days,
  }) = _WeeklyBucket;

  const WeeklyBucket._();

  /// Sum of `caloriesEaten` across [days], or `null` if none had a value.
  int? get totalCaloriesEaten => _sumOrNull(days.map((d) => d.caloriesEaten));

  /// Sum of active + basal calories burned across [days], or `null` if none
  /// had a value for either field.
  int? get totalCaloriesBurned => _sumOrNull(
    days.map((d) {
      if (d.caloriesBurnedActive == null && d.caloriesBurnedBasal == null) {
        return null;
      }
      return (d.caloriesBurnedActive ?? 0) + (d.caloriesBurnedBasal ?? 0);
    }),
  );

  /// Sum of `steps` across [days], or `null` if none had a value.
  int? get totalSteps => _sumOrNull(days.map((d) => d.steps));

  static int? _sumOrNull(Iterable<int?> values) {
    final present = values.whereType<int>();
    if (present.isEmpty) return null;
    return present.reduce((a, b) => a + b);
  }
}
