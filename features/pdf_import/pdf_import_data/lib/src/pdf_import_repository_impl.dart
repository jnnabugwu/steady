import 'dart:typed_data';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:pdf_import_data/src/cal_ai_parser.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

/// Implements `PdfImportRepository` on top of `CalAIParser` and an injected
/// `DailyMetricRepository`.
class PdfImportRepositoryImpl implements PdfImportRepository {
  PdfImportRepositoryImpl({
    required CalAIParser parser,
    required DailyMetricRepository dailyMetrics,
  }) : _parser = parser,
       _dailyMetrics = dailyMetrics;

  final CalAIParser _parser;
  final DailyMetricRepository _dailyMetrics;

  @override
  ResultFuture<List<ParsedDay>> parse(Uint8List pdfBytes) async {
    try {
      final days = await _parser.parse(pdfBytes);
      return Ok(days);
    } on Exception catch (e) {
      return Err(ValidationFailure('failed to parse PDF', cause: e));
    }
  }

  @override
  ResultFuture<Unit> commitDailyTotals(List<ParsedDay> days) async {
    // Only caloriesEaten is passed to upsert -- this is what makes the
    // partial-field merge preserve any HealthKit-sourced fields (or vice
    // versa, if PDF import runs before HealthKit backfills a day).
    //
    // Non-atomic on purpose: a mid-loop failure leaves earlier days
    // committed and returns the first Err. Each upsert is an idempotent
    // merge, so the caller recovers by re-running the whole import. See
    // PdfImportRepository.commitDailyTotals doc.
    for (final day in days) {
      final result = await _dailyMetrics.upsert(
        day.date,
        caloriesEaten: day.caloriesEaten,
      );
      if (result is Err<DailyMetric>) {
        return Err(result.failure);
      }
    }
    return const Ok(unit);
  }

  @override
  ResultFuture<int> countSampleDays() async {
    final rows = await _sampleRows();
    return switch (rows) {
      Ok(:final value) => Ok(value.length),
      Err(:final failure) => Err(failure),
    };
  }

  @override
  ResultFuture<int> removeSampleDays() async {
    final rows = await _sampleRows();
    if (rows case Err(:final failure)) return Err(failure);
    var removed = 0;
    for (final row in (rows as Ok<List<DailyMetric>>).value) {
      final hasOtherData =
          row.loggingStatus != null ||
          row.steps != null ||
          row.caloriesBurnedActive != null ||
          row.caloriesBurnedBasal != null;
      final result = hasOtherData
          ? await _dailyMetrics.clearFields(row.date, const {
              DailyMetricField.caloriesEaten,
            })
          : await _dailyMetrics.delete(row.date);
      if (result case Err(:final failure)) return Err(failure);
      removed++;
    }
    return Ok(removed);
  }

  /// The store's rows that came from the sample export: a date in
  /// [sampleExportDailyTotals] with exactly that date's `caloriesEaten`.
  ResultFuture<List<DailyMetric>> _sampleRows() async {
    final dates = sampleExportDailyTotals.keys.toList()..sort();
    final result = await _dailyMetrics.getRange(dates.first, dates.last);
    return switch (result) {
      Ok(:final value) => Ok([
        for (final row in value)
          if (row.caloriesEaten != null &&
              sampleExportDailyTotals[row.date] == row.caloriesEaten)
            row,
      ]),
      Err(:final failure) => Err(failure),
    };
  }
}
