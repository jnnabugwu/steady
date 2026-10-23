import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:health_sync_domain/src/health_day_totals.dart';
import 'package:health_sync_domain/src/health_kit_repository.dart';
import 'package:health_sync_domain/src/health_sync_report.dart';

/// How many days `syncHealthDays` covers by default, today included: a
/// 30-day backfill that also refreshes today.
const int healthSyncWindowDays = 30;

/// Copies Apple Health's daily totals for the last [days] local calendar
/// days ending on [today] (today included) into [dailyMetrics].
///
/// The rules, all of which protect what other features wrote:
///
/// - Only `steps`, `caloriesBurnedActive` and `caloriesBurnedBasal` are
///   ever written. `caloriesEaten` (PDF import) and `loggingStatus`
///   (check-in) are never passed to `upsert`, and its partial-field merge
///   leaves them alone (the same pattern as `commitDailyTotals`).
/// - A field is written only when Health has a value for it **and** that
///   value differs from the stored one. A day where nothing changed isn't
///   written at all, so a repeat sync makes no CloudKit traffic.
/// - A Health `null` (no samples, or read access not allowed: HealthKit
///   doesn't say which) never clears a stored value. It's unknown, not
///   zero. A day with no Health data at all creates no row.
///
/// The first `Failure` (reading Health, reading the store, or a write) is
/// returned as is; days already written before it stay written.
ResultFuture<HealthSyncReport> syncHealthDays({
  required HealthKitRepository health,
  required DailyMetricRepository dailyMetrics,
  required DateTime today,
  int days = healthSyncWindowDays,
}) async {
  if (days < 1) {
    return Err(ValidationFailure('days must be at least 1, got $days'));
  }
  final end = DateTime(today.year, today.month, today.day);
  final start = DateTime(end.year, end.month, end.day - (days - 1));

  final List<HealthDayTotals> totals;
  switch (await health.dailyTotals(start, end)) {
    case Ok(:final value):
      totals = value;
    case Err(:final failure):
      return Err(failure);
  }

  final Map<DateTime, DailyMetric> stored;
  switch (await dailyMetrics.getRange(start, end)) {
    case Ok(:final value):
      stored = {for (final row in value) _midnight(row.date): row};
    case Err(:final failure):
      return Err(failure);
  }

  var daysUpdated = 0;
  var daysWithData = 0;
  for (final day in totals) {
    if (day.isEmpty) continue;
    daysWithData++;
    final date = _midnight(day.date);
    final row = stored[date];
    final steps = _changed(day.steps, row?.steps);
    final active = _changed(
      day.caloriesBurnedActive,
      row?.caloriesBurnedActive,
    );
    final basal = _changed(day.caloriesBurnedBasal, row?.caloriesBurnedBasal);
    if (steps == null && active == null && basal == null) continue;

    final written = await dailyMetrics.upsert(
      date,
      steps: steps,
      caloriesBurnedActive: active,
      caloriesBurnedBasal: basal,
    );
    if (written case Err(:final failure)) return Err(failure);
    daysUpdated++;
  }
  return Ok(
    HealthSyncReport(daysUpdated: daysUpdated, daysWithData: daysWithData),
  );
}

/// [fromHealth] when it's a value that differs from [stored], else `null`
/// (which `upsert` reads as "leave untouched").
int? _changed(int? fromHealth, int? stored) =>
    fromHealth != null && fromHealth != stored ? fromHealth : null;

DateTime _midnight(DateTime date) => DateTime(date.year, date.month, date.day);
