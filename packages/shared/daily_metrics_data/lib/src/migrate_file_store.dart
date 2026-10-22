import 'dart:convert';
import 'dart:io';

import 'package:daily_metrics_data/src/daily_metric_json.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';

/// One-time move of the interim JSON store (`FileDailyMetricRepository`'s
/// file) into [target], so rows imported before SwiftData landed aren't
/// lost.
///
/// - A missing [file] means nothing to migrate: `Ok(0)`.
/// - **Fill-only.** For each file row, [target]'s row for that day is read
///   first, and only the fields [target] doesn't have (null there) are
///   written. A value [target] already holds is never overwritten, whether
///   it came from the user or from an earlier, partly failed run of this
///   migration.
/// - Once every row is in, [file] is renamed to `<file>.migrated`, so the
///   next launch finds nothing and returns `Ok(0)`.
/// - An unreadable or corrupt [file] returns `Err(UnknownFailure)` and is
///   left exactly where it is. So does a failed read or write on [target];
///   the next launch retries the whole file, and fill-only makes that safe:
///   rows that already made it in, and anything the user changed since,
///   are kept.
/// - The one residual case: a field the user *cleared* after a partly
///   failed run is null again in [target], so the retry refills it from the
///   file. Fill-only can't tell "never migrated" from "cleared since".
///
/// Returns the number of rows in [file].
Future<Result<int>> migrateFileStore(
  File file,
  DailyMetricRepository target,
) async {
  final List<DailyMetric> rows;
  try {
    if (!file.existsSync()) return const Ok(0);
    rows = decodeDailyMetrics(jsonDecode(await file.readAsString()));
  } on FormatException catch (e) {
    return Err(
      UnknownFailure(
        'Daily metrics file ${file.path} is unreadable; left untouched',
        cause: e,
      ),
    );
  } on FileSystemException catch (e) {
    return Err(
      UnknownFailure(
        'Could not read daily metrics file ${file.path}',
        cause: e,
      ),
    );
  }

  for (final row in rows) {
    final DailyMetric? existing;
    switch (await target.getByDate(row.date)) {
      case Ok(:final value):
        existing = value;
      case Err(:final failure):
        return Err(failure);
    }
    // Only fields the file has and the target lacks; null means "leave as
    // is" to upsert.
    int? fill(int? fromFile, int? inTarget) =>
        inTarget == null ? fromFile : null;
    final caloriesEaten = fill(row.caloriesEaten, existing?.caloriesEaten);
    final caloriesBurnedActive = fill(
      row.caloriesBurnedActive,
      existing?.caloriesBurnedActive,
    );
    final caloriesBurnedBasal = fill(
      row.caloriesBurnedBasal,
      existing?.caloriesBurnedBasal,
    );
    final steps = fill(row.steps, existing?.steps);
    final loggingStatus = existing?.loggingStatus == null
        ? row.loggingStatus
        : null;
    if (caloriesEaten == null &&
        caloriesBurnedActive == null &&
        caloriesBurnedBasal == null &&
        steps == null &&
        loggingStatus == null) {
      continue;
    }
    final result = await target.upsert(
      row.date,
      caloriesEaten: caloriesEaten,
      caloriesBurnedActive: caloriesBurnedActive,
      caloriesBurnedBasal: caloriesBurnedBasal,
      steps: steps,
      loggingStatus: loggingStatus,
    );
    if (result case Err(:final failure)) return Err(failure);
  }

  try {
    await file.rename('${file.path}.migrated');
  } on FileSystemException catch (e) {
    return Err(
      UnknownFailure(
        'Migrated ${rows.length} rows but could not rename ${file.path}',
        cause: e,
      ),
    );
  }
  return Ok(rows.length);
}
