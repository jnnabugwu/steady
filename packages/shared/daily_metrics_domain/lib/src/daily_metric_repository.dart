import 'package:daily_metrics_domain/src/daily_metric.dart';
import 'package:daily_metrics_domain/src/logging_status.dart';
import 'package:failures/failures.dart';

/// Reads and writes `DailyMetric` rows.
abstract class DailyMetricRepository {
  /// Returns the row for [date], or `Ok(null)` if nothing has been recorded
  /// for that day yet. A day with nothing logged is the normal starting
  /// state, not an error.
  ResultFuture<DailyMetric?> getByDate(DateTime date);

  /// Returns every row between [start] and [end], inclusive, sorted by
  /// date. Returns `Err(ValidationFailure)` if [start] is after [end].
  ResultFuture<List<DailyMetric>> getRange(DateTime start, DateTime end);

  /// Merges the given fields into the row for [date], creating it if it
  /// doesn't exist yet. This is a **partial-field merge, not a full-row
  /// replace** — omitted (`null`) named parameters leave the existing
  /// field's value untouched, rather than clearing it. This is what lets
  /// checkin, metrics, pdf_import, and a future HealthKit writer each touch
  /// the same date-row independently without clobbering each other's
  /// fields.
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  });

  /// Deletes the row for [date], if one exists.
  ResultFuture<Unit> delete(DateTime date);
}
