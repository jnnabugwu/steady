import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:equatable/equatable.dart';

/// A week's worth of `DailyMetric` rows, plus derived totals.
class WeeklyBucket extends Equatable {
  /// Wraps [days] in an unmodifiable copy; see the [days] field doc.
  WeeklyBucket({required this.weekStart, required List<DailyMetric> days})
    : days = List.unmodifiable(days);

  /// The anchor day of this bucket.
  final DateTime weekStart;

  /// The days in this bucket. 1-7 entries; may be fewer than 7 for a
  /// partial/edge week. Stored as an unmodifiable copy so the bucket keeps
  /// value semantics (it goes into `props`) even if the caller mutates the
  /// list it passed in — and stays safe as a `Set` element or `Map` key.
  final List<DailyMetric> days;

  /// Sum of `caloriesEaten` across [days], or `null` if none had a value.
  int? get totalCaloriesEaten =>
      _sumOrNull(days.map((d) => d.caloriesEaten));

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

  @override
  List<Object?> get props => [weekStart, days];
}
