/// What the bundled sample Cal AI export ("Try a sample export") puts in
/// the store: each made-up day, Mon Jan 6 - Sun Jan 12 2025, mapped to its
/// `caloriesEaten` total.
///
/// The one definition of the sample's identity. Removing the sample
/// (`PdfImportRepository.removeSampleDays`) only touches a row whose date
/// is a key here **and** whose `caloriesEaten` equals that key's value, so
/// a real day on one of these dates, with any other total, is never
/// touched. `pdf_import_data/test/sample_export_test.dart` checks this map
/// against the real parse of the bundled PDF, so it can't drift from the
/// asset (`docs/sample/generate.py` builds both).
///
/// Keys are local midnight, the store's date normalization.
final Map<DateTime, int> sampleExportDailyTotals = Map.unmodifiable({
  DateTime(2025, 1, 6): 1450,
  DateTime(2025, 1, 7): 1625,
  DateTime(2025, 1, 8): 1920,
  DateTime(2025, 1, 9): 230,
  DateTime(2025, 1, 10): 1500,
  DateTime(2025, 1, 11): 1610,
  DateTime(2025, 1, 12): 1070,
});
