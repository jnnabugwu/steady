import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

import 'support/pdfium.dart';

/// The made-up sample export (`docs/sample/`, built by
/// `docs/sample/generate.py`) through the real `CalAIParser`. It's what App
/// Review imports with "Try a sample export", so it must keep parsing to
/// exactly these seven days. No personal data, so it runs in CI.
void main() {
  const samplePath = '../../../docs/sample/cal_ai_sample_export.pdf';
  const assetPath =
      '../pdf_import_presentation/assets/cal_ai_sample_export.pdf';

  setUpAll(usePdfiumBuiltByFlutterTest);

  late List<ParsedDay> days;

  setUpAll(() async {
    days = await CalAIParser().parse(File(samplePath).readAsBytesSync());
  });

  test('parses to the seven days of Jan 6-12 2025, with exact totals', () {
    expect(days.map((d) => d.date), [
      for (var day = 6; day <= 12; day++) DateTime(2025, 1, day),
    ]);
    expect(days.map((d) => d.caloriesEaten), [
      1450,
      1625,
      1920,
      230,
      1500,
      1610,
      1070,
    ]);
    expect(days.map((d) => d.foodEntries.length), [3, 4, 4, 1, 3, 3, 2]);
  });

  test('matches sampleExportDailyTotals, the sample identity removal uses', () {
    expect(
      {for (final day in days) day.date: day.caloriesEaten},
      sampleExportDailyTotals,
      reason:
          'update sampleExportDailyTotals (pdf_import_domain) with the asset',
    );
  });

  test("each day's TOTAL equals the sum of its entries", () {
    for (final day in days) {
      final sum = day.foodEntries.fold<int>(0, (s, e) => s + e.calories);
      expect(sum, day.caloriesEaten, reason: 'day ${day.date}');
    }
  });

  test('reassembles the wrapped name and keeps headers out of names', () {
    final jan8 = days[2].foodEntries.map((e) => e.name);
    expect(
      jan8,
      contains('Chicken Burrito Bowl with Black Beans, Brown Rice and Salsa'),
    );
    expect(days[3].foodEntries.single.name, 'Protein Bar');
    for (final entry in days.expand((d) => d.foodEntries)) {
      expect(entry.name, isNot(contains('Report')));
      expect(entry.name, isNot(contains('Foods Calories')));
      expect(entry.name, isNot(contains('Start:')));
    }
  });

  test('the bundled asset is the same file as docs/sample', () {
    expect(
      File(assetPath).readAsBytesSync(),
      File(samplePath).readAsBytesSync(),
      reason: 'copy docs/sample/cal_ai_sample_export.pdf into the asset',
    );
  });
}
