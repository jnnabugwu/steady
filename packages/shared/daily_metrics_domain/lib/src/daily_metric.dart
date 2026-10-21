import 'package:daily_metrics_domain/src/logging_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'daily_metric.freezed.dart';

/// A single day's metrics row: calories, steps, and self-reported logging
/// status. Shared across the checkin, metrics, and pdf_import features —
/// `logging_status` lives on the same row as the calorie/step fields, there
/// is no separate check-in table.
///
/// Every field but [date] is nullable, satisfying the CloudKit-backed
/// SwiftData constraint that every stored attribute be optional or
/// defaulted. Fields are nullable rather than defaulted to `0` deliberately:
/// `caloriesEaten == 0` and `caloriesEaten == null` mean different things
/// ("logged zero" vs. "nothing recorded yet").
@freezed
abstract class DailyMetric with _$DailyMetric {
  const factory DailyMetric({
    /// Date-only granularity, normalized to local midnight — the row's
    /// natural key.
    required DateTime date,

    /// Calories eaten, parsed from a Cal AI PDF import.
    int? caloriesEaten,

    /// Active calories burned, from HealthKit's `activeEnergyBurned`.
    int? caloriesBurnedActive,

    /// Basal calories burned, from HealthKit's `basalEnergyBurned`.
    int? caloriesBurnedBasal,

    /// Step count, from HealthKit's `stepCount`.
    int? steps,

    /// Self-reported end-of-day logging status.
    LoggingStatus? loggingStatus,
  }) = _DailyMetric;
}
