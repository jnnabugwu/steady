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
}
