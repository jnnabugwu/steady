import 'package:daily_metrics_domain/src/logging_status.dart';
import 'package:equatable/equatable.dart';

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
class DailyMetric extends Equatable {
  const DailyMetric({
    required this.date,
    this.caloriesEaten,
    this.caloriesBurnedActive,
    this.caloriesBurnedBasal,
    this.steps,
    this.loggingStatus,
  });

  /// Date-only granularity, normalized to local midnight — the row's
  /// natural key.
  final DateTime date;

  /// Calories eaten, parsed from a Cal AI PDF import.
  final int? caloriesEaten;

  /// Active calories burned, from HealthKit's `activeEnergyBurned`.
  final int? caloriesBurnedActive;

  /// Basal calories burned, from HealthKit's `basalEnergyBurned`.
  final int? caloriesBurnedBasal;

  /// Step count, from HealthKit's `stepCount`.
  final int? steps;

  /// Self-reported end-of-day logging status.
  final LoggingStatus? loggingStatus;

  @override
  List<Object?> get props => [
    date,
    caloriesEaten,
    caloriesBurnedActive,
    caloriesBurnedBasal,
    steps,
    loggingStatus,
  ];
}
