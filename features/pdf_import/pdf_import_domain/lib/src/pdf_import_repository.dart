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
  ResultFuture<Unit> commitDailyTotals(List<ParsedDay> days);
}
