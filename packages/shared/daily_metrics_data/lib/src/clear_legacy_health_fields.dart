import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';

/// The Apple Health fields an older build wrote into `DailyMetric` rows.
const Set<DailyMetricField> legacyHealthFields = {
  DailyMetricField.steps,
  DailyMetricField.caloriesBurnedActive,
  DailyMetricField.caloriesBurnedBasal,
};

/// Removes Apple Health values an older build stored in [repository]
/// (`steps`, `caloriesBurnedActive`, `caloriesBurnedBasal`), so they don't
/// stay in the user's iCloud (App Store guideline 5.1.3(ii)). Health is now
/// read live and never stored (`metrics_presentation`'s `live_health.dart`).
///
/// **Safe to clear:** no feature other than the Health sync ever wrote these
/// fields (PDF import writes calories eaten, check-in the logging status),
/// so nothing else's data is lost. The interim file migration could copy
/// them too, but only values a Health sync had put there.
///
/// - Reads every row the store can hold (years 0000-9999, the
///   SwiftData store's span) and calls `clearFields` only on rows that still
///   have one of those fields, with exactly those fields. Every other field
///   is untouched; a row left with nothing in it is removed by
///   `clearFields`, which is what "nothing recorded" means.
/// - **Idempotent and cheap:** once clean, a run is a single range read and
///   no writes, so it can run on every launch.
/// - A failed read or write returns that `Err` and stops; rows already
///   cleared stay cleared, and the next launch finishes the rest.
///
/// Returns how many rows were cleared.
Future<Result<int>> clearLegacyHealthFields(
  DailyMetricRepository repository,
) async {
  final List<DailyMetric> rows;
  switch (await repository.getRange(DateTime(0), DateTime(9999, 12, 31))) {
    case Ok(:final value):
      rows = value;
    case Err(:final failure):
      return Err(failure);
  }
  var cleared = 0;
  for (final row in rows) {
    final fields = {
      if (row.steps != null) DailyMetricField.steps,
      if (row.caloriesBurnedActive != null)
        DailyMetricField.caloriesBurnedActive,
      if (row.caloriesBurnedBasal != null) DailyMetricField.caloriesBurnedBasal,
    };
    if (fields.isEmpty) continue;
    if (await repository.clearFields(row.date, fields) case Err(
      :final failure,
    )) {
      return Err(failure);
    }
    cleared++;
  }
  return Ok(cleared);
}
