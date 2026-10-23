import 'dart:async';
import 'dart:typed_data';

import 'package:failures/failures.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

/// Hand-written fake for `PdfImportRepository`.
///
/// Each method returns whatever its handler returns. Every call is
/// recorded so tests can assert on the arguments and call counts.
class FakePdfImportRepository implements PdfImportRepository {
  FakePdfImportRepository({
    FutureOr<Result<List<ParsedDay>>> Function(Uint8List bytes)? onParse,
    FutureOr<Result<Unit>> Function(List<ParsedDay> days)? onCommit,
  }) : onParse = onParse ?? ((_) => Ok(sampleDays)),
       onCommit = onCommit ?? ((_) => const Ok(unit));

  FutureOr<Result<List<ParsedDay>>> Function(Uint8List bytes) onParse;
  FutureOr<Result<Unit>> Function(List<ParsedDay> days) onCommit;

  final List<Uint8List> parseCalls = [];
  final List<List<ParsedDay>> commitCalls = [];

  @override
  ResultFuture<List<ParsedDay>> parse(Uint8List pdfBytes) async {
    parseCalls.add(pdfBytes);
    return await onParse(pdfBytes);
  }

  @override
  ResultFuture<Unit> commitDailyTotals(List<ParsedDay> days) async {
    commitCalls.add(days);
    return await onCommit(days);
  }
}

/// A fake file picker: returns [bytes] (`null` = cancelled), or throws
/// [error] if set. Counts its calls.
class FakePdfFilePicker {
  FakePdfFilePicker({this.bytes, this.error});

  Uint8List? bytes;

  /// Any object, not just an `Exception`: the real picker can throw
  /// anything, and the controller catches `Object`.
  Object? error;
  int calls = 0;

  Future<Uint8List?> call() async {
    calls++;
    // Deliberately models a non-Exception throw from the platform picker.
    // ignore: only_throw_errors
    if (error case final error?) throw error;
    return bytes;
  }
}

final pdfBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46]); // "%PDF"

/// Stands in for the bundled sample export; distinct from [pdfBytes] so a
/// test can tell which path supplied the bytes.
final sampleBytes = Uint8List.fromList([0x25, 0x50, 0x44, 0x46, 0x2D]); // %PDF-

ParsedFoodEntry _entry(String name, int calories) => ParsedFoodEntry(
  name: name,
  calories: calories,
  proteinG: 10,
  carbsG: 20,
  fatG: 5,
  fiberG: 2,
  sugarG: 3,
  sodiumMg: 100,
  loggedAtTime: '12:00pm',
);

/// Two days, deliberately out of date order to exercise the range.
final sampleDays = [
  ParsedDay(
    date: DateTime(2026, 8, 17),
    caloriesEaten: 2150,
    foodEntries: [_entry('Ground Turkey', 780), _entry('Rice Bowl', 1370)],
  ),
  ParsedDay(
    date: DateTime(2026, 8, 16),
    caloriesEaten: 640,
    foodEntries: [_entry('Greek Yogurt', 640)],
  ),
];
