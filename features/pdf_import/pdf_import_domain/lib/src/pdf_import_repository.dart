import 'dart:typed_data';

import 'package:failures/failures.dart';
import 'package:pdf_import_domain/src/parsed_day.dart';

/// Parses Cal AI PDF exports and commits the resulting daily totals.
abstract class PdfImportRepository {
  /// Parses [pdfBytes] into a list of `ParsedDay`s.
  ResultFuture<List<ParsedDay>> parse(Uint8List pdfBytes);

  /// Writes each day's `caloriesEaten` total into the shared
  /// `daily_metrics` store, preserving any other fields already on that
  /// row (e.g. HealthKit-sourced steps/burned-calorie data).
  ///
  /// **Not atomic.** Days are upserted one at a time; a failure partway
  /// through leaves the earlier days already committed and returns the
  /// first `Err` without reporting how far it got. This is acceptable
  /// because each write is an idempotent partial-field merge
  /// (`DailyMetricRepository.upsert`), so the caller's remedy on failure is
  /// simply to re-run the whole import — re-applying the already-committed
  /// days is a no-op. A cross-record transaction isn't available under the
  /// CloudKit-backed store anyway (CLAUDE.md §7: record-level last-writer-
  /// wins, no custom merge layer).
  ResultFuture<Unit> commitDailyTotals(List<ParsedDay> days);

  /// Counts the sample export's rows still in the shared store: rows whose
  /// date is in `sampleExportDailyTotals` and whose `caloriesEaten` equals
  /// that date's sample total. Settings shows "Sample data" only when this
  /// is at least 1.
  ResultFuture<int> countSampleDays();

  /// Removes the sample export's rows (the ones [countSampleDays] counts)
  /// and returns how many it removed. Nothing else is touched:
  ///
  /// - A row with only the sample's `caloriesEaten` is deleted.
  /// - A row that also holds other data (a check-in status, steps, burned
  ///   calories) keeps it: only its `caloriesEaten` is cleared.
  /// - A row on a sample date with a different `caloriesEaten` is a real
  ///   day, and is left alone.
  ///
  /// Not atomic, like [commitDailyTotals]: a failure partway returns the
  /// first `Err`, with earlier rows already removed. Re-running is safe,
  /// since removed rows no longer match.
  ResultFuture<int> removeSampleDays();
}
