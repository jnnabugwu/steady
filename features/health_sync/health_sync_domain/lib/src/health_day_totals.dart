import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_day_totals.freezed.dart';

/// One local calendar day's totals from Apple Health: summed steps, summed
/// active and basal energy and summed dietary energy (calories eaten) in
/// whole kilocalories, and the day's latest weight reading.
///
/// Each value is `null` when Health has no samples of that type for the
/// day. `null` is "unknown", never "zero": HealthKit doesn't tell an app
/// whether the user denied it read access, so a type the user didn't allow
/// looks exactly like a type with no data. Field names match the
/// `DailyMetric` fields of the same meaning, but these values are only ever
/// held in memory for display: they're never written to that store.
@freezed
abstract class HealthDayTotals with _$HealthDayTotals {
  /// Creates one day's totals.
  const factory HealthDayTotals({
    /// The day, at local midnight.
    required DateTime date,

    /// Summed `stepCount`.
    int? steps,

    /// Summed `activeEnergyBurned`, rounded to whole kcal.
    int? caloriesBurnedActive,

    /// Summed `basalEnergyBurned`, rounded to whole kcal.
    int? caloriesBurnedBasal,

    /// The day's most recent `bodyMass` reading, in kilograms. Not a sum,
    /// and not smoothed: see `weightTrendKg` for the trend.
    double? weightKg,

    /// Summed `dietaryEnergyConsumed`, rounded to whole kcal: what another
    /// app (Cal AI, for one) logged as eaten that day (#138).
    int? caloriesEaten,
  }) = _HealthDayTotals;

  const HealthDayTotals._();

  /// Whether every value is unavailable that day: no samples, or read
  /// access not granted (HealthKit doesn't say which).
  bool get isEmpty => !hasMetricValue && weightKg == null;

  /// Whether the day has steps or burned energy (the values that sit next
  /// to a `DailyMetric` row), whatever its weight.
  bool get hasActivity =>
      steps != null ||
      caloriesBurnedActive != null ||
      caloriesBurnedBasal != null;

  /// Whether the day has a value that sits next to a `DailyMetric` row:
  /// steps, burned energy or calories eaten. Weight doesn't count.
  bool get hasMetricValue => hasActivity || caloriesEaten != null;
}
