import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/src/export_bundle.dart';
import 'package:failures/failures.dart';

/// Dart's `DateTime` limit: 100,000,000 days either side of the epoch, in
/// milliseconds. No `DateTime`, and so no stored row, can fall outside it.
const int _dateTimeLimitMs = 8640000000000000;

/// The first day an export reads: the earliest local midnight a `DateTime`
/// can represent.
///
/// An export must never silently drop a row, and the repository contract
/// accepts any `DateTime`, so the range is every day a row's date could
/// hold, not a "plausible" span such as 1970 onwards. It's a query bound,
/// not a loop, so its width costs nothing.
///
/// Computed in the current time zone rather than fixed: the earliest
/// representable local midnight differs by a day either side of UTC, and
/// a repository normalizes `getRange` bounds to local midnight with
/// `DateTime(year, month, day)`, which throws for an unrepresentable day.
DateTime get exportRangeStart {
  final earliest = DateTime.fromMillisecondsSinceEpoch(-_dateTimeLimitMs);
  // The midnight that starts `earliest`'s day is before the limit (and so
  // can't be built) unless `earliest` is that midnight, so otherwise start
  // on the next day. Checked by field, not by building that midnight.
  final atMidnight =
      earliest.hour == 0 &&
      earliest.minute == 0 &&
      earliest.second == 0 &&
      earliest.millisecond == 0 &&
      earliest.microsecond == 0;
  return atMidnight
      ? earliest
      : DateTime(earliest.year, earliest.month, earliest.day + 1);
}

/// The last day an export reads: the latest local midnight a `DateTime`
/// can represent.
///
/// Far in the future rather than today, on purpose: a row dated after
/// "today" can exist (a device in a time zone ahead of this one writing
/// its own today). See [exportRangeStart] for why it's the representable
/// limit and why it's computed in the current time zone.
DateTime get exportRangeEnd =>
    _midnightOf(DateTime.fromMillisecondsSinceEpoch(_dateTimeLimitMs));

/// Local midnight of [moment]'s day. Only safe when that midnight is
/// representable, which holds for the latest instant (its midnight is
/// earlier) but not for the earliest one.
DateTime _midnightOf(DateTime moment) =>
    DateTime(moment.year, moment.month, moment.day);

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
