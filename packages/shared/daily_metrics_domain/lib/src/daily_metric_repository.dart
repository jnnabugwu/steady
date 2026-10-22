import 'package:daily_metrics_domain/src/daily_metric.dart';
import 'package:daily_metrics_domain/src/daily_metric_field.dart';
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
  ///
  /// Because `null` means "leave untouched" here, [upsert] can never set a
  /// field back to `null`. Use [clearFields] for that.
  ResultFuture<DailyMetric> upsert(
    DateTime date, {
    int? caloriesEaten,
    int? caloriesBurnedActive,
    int? caloriesBurnedBasal,
    int? steps,
    LoggingStatus? loggingStatus,
  });

  /// Sets each of [fields] back to `null` ("nothing recorded") on the row
  /// for [date], leaving every other field untouched. This is the only way
  /// to clear a single field: [upsert] treats `null` as "leave untouched",
  /// and [delete] removes the whole row, including other features' fields.
  ///
  /// - [date] is normalized to local midnight, the same way [upsert] does.
  /// - Clearing is not the same as writing `0`. A cleared `caloriesEaten`
  ///   reads back as `null`, never `0` ("logged zero").
  /// - If no row exists for [date], this is a no-op that returns `Ok(unit)`.
  ///   It does not create an empty row. Clearing a field that is already
  ///   `null` is fine too, so the call is idempotent.
  /// - An empty [fields] set is a no-op.
  /// - If clearing leaves every field `null`, the row is **removed**, so
  ///   [getByDate] returns `Ok(null)` and [getRange] skips that day. A row
  ///   with nothing in it means the same thing as no row ("nothing recorded
  ///   yet"), and removing it means readers never need to filter out empty
  ///   rows. Clearing every field of a day is then the same as [delete].
  ///
  /// Why a separate method instead of a sentinel or `Optional`-style wrapper
  /// on [upsert]'s parameters: [upsert]'s signature and its "null = leave
  /// untouched" rule stay exactly as they are (Checkpoint A kept them), so
  /// none of its callers change. A wrapper would give every [upsert]
  /// parameter three states (leave, set, clear) that each caller and each
  /// implementation would have to get right. A separate method keeps
  /// clearing an explicit act you can find by name, and maps onto the
  /// SwiftData channel as a plain list of field names.
  ResultFuture<Unit> clearFields(DateTime date, Set<DailyMetricField> fields);

  /// Deletes the row for [date], if one exists.
  ResultFuture<Unit> delete(DateTime date);
}
