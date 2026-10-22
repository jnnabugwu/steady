import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/src/export_bundle.dart';
import 'package:failures/failures.dart';

/// The first day an export reads. Earlier than any data Steady can hold.
final DateTime exportRangeStart = DateTime(1970);

/// The last day an export reads.
///
/// Far in the future rather than today, on purpose: a backup must never
/// silently drop a row, and a row dated after "today" can exist (a device
/// in a time zone ahead of this one writing its own today). The range is
/// a query bound, not a loop, so its width costs nothing.
final DateTime exportRangeEnd = DateTime(9999, 12, 31);

/// Reads every `DailyMetric` row through [repository] and bundles it for
/// export, stamped [exportedAt].
///
/// Uses the existing [DailyMetricRepository.getRange] with an all-time
/// span ([exportRangeStart] to [exportRangeEnd]) instead of adding a
/// "read everything" method to the shared interface.
///
/// A repository `Err` is passed through unchanged, so no bundle (and no
/// file) is ever built from a failed or partial read.
ResultFuture<ExportBundle> readExportBundle(
  DailyMetricRepository repository, {
  required DateTime exportedAt,
}) async {
  final result = await repository.getRange(exportRangeStart, exportRangeEnd);
  return switch (result) {
    Ok(:final value) => Ok(
      ExportBundle(exportedAt: exportedAt, dailyMetrics: value),
    ),
    Err(:final failure) => Err(failure),
  };
}
