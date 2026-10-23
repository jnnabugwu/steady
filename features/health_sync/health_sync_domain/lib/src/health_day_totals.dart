import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_day_totals.freezed.dart';

/// One local calendar day's totals from Apple Health: summed steps and
/// summed active and basal energy, in whole kilocalories.
///
/// Each value is `null` when Health has no samples of that type for the
/// day. `null` is "unknown", never "zero": HealthKit doesn't tell an app
/// whether the user denied it read access, so a type the user didn't allow
/// looks exactly like a type with no data. Field names match the
/// `DailyMetric` fields of the same meaning.
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
  }) = _HealthDayTotals;

  const HealthDayTotals._();

  /// Whether all three totals are unavailable that day: no samples, or
  /// read access not granted (HealthKit doesn't say which).
  bool get isEmpty =>
      steps == null &&
      caloriesBurnedActive == null &&
      caloriesBurnedBasal == null;
}
