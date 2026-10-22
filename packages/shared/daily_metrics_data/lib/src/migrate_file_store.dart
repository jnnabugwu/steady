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
/// - Each row is written with `upsert`, a partial-field merge, so a field
///   the file doesn't have never overwrites one [target] already holds.
/// - Once every row is in, [file] is renamed to `<file>.migrated`, so the
///   next launch finds nothing and returns `Ok(0)`.
/// - An unreadable or corrupt [file] returns `Err(UnknownFailure)` and is
///   left exactly where it is. So does a failed write into [target]; since
///   upserting the same values again changes nothing, the next launch can
///   simply retry.
///
/// Returns the number of rows copied.
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
    final result = await target.upsert(
      row.date,
      caloriesEaten: row.caloriesEaten,
      caloriesBurnedActive: row.caloriesBurnedActive,
      caloriesBurnedBasal: row.caloriesBurnedBasal,
      steps: row.steps,
      loggingStatus: row.loggingStatus,
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
