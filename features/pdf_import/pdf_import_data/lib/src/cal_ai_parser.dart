import 'dart:typed_data';

import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdfrx_engine/pdfrx_engine.dart';

/// Parses Cal AI PDF exports into per-day food data, using pdfrx_engine
/// (on-device, no backend) and the token-lookahead algorithm from
/// CLAUDE.md §6: split each extracted line on whitespace, check whether the
/// last 8 tokens match the expected pattern (bare int, 5x grams, 1x mg,
/// 1x time) -- everything before that tail is the food name.
///
/// A day's total is read directly from its `TOTAL ... Calories eaten: N`
/// line rather than summed from individual food entries -- Cal AI already
/// computes it, and reading it directly avoids any risk of the parser's own
/// sum silently drifting from Cal AI's.
///
/// `currentDate`/the pending-name buffer reset per PDF page, matching the
/// already-validated algorithm this ports (see docs/cal_ai_parser_tradeoffs.md).
/// Known residual risk, not yet observed: a day's food list spilling across
/// a page boundary without Cal AI re-printing the date header on the
/// continuation page would silently drop the entries after the break.
class CalAIParser {
  static final _dateHeaderPattern = RegExp(
    r'^([A-Z][a-z]+) (\d{1,2}), (\d{4})$',
  );
  static final _totalCaloriesPattern = RegExp(r'Calories eaten:\s*(\d+)');
  static final _gramsPattern = RegExp(r'^\d+g$');
  static final _milligramsPattern = RegExp(r'^\d+mg$');
  static final _timePattern = RegExp(r'^\d{1,2}:\d{2}(am|pm)$');
  static final _intPattern = RegExp(r'^\d+$');

  /// Lines that repeat on every page/table and carry no data of their own --
  /// must be skipped outright, not absorbed into the pending-name buffer,
  /// or they get prepended to the next real food entry's name.
  static const _boilerplateLines = {
    "Jordan's Report",
    'Foods Calories Protein Carbs Fat Fiber Sugar Sodium Time',
  };

  static const _monthNames = {
    'January': 1,
    'February': 2,
    'March': 3,
    'April': 4,
    'May': 5,
    'June': 6,
    'July': 7,
    'August': 8,
    'September': 9,
    'October': 10,
    'November': 11,
    'December': 12,
  };

  /// Parses [pdfBytes] into a list of `ParsedDay`s.
  Future<List<ParsedDay>> parse(Uint8List pdfBytes) async {
    await pdfrxInitialize();
    final document = await PdfDocument.openData(pdfBytes);
    try {
      final days = <ParsedDay>[];

      for (final page in document.pages) {
        final rawText = await page.loadText();
        final lines = (rawText?.fullText ?? '').split('\n');

        DateTime? currentDate;
        var pendingName = '';
        var currentEntries = <ParsedFoodEntry>[];

        for (final rawLine in lines) {
          final line = rawLine.trim();
          if (line.isEmpty || _isBoilerplate(line)) continue;

          final dateMatch = _dateHeaderPattern.firstMatch(line);
          if (dateMatch != null) {
            final month = _monthNames[dateMatch.group(1)];
            if (month != null) {
              currentDate = DateTime(
                int.parse(dateMatch.group(3)!),
                month,
                int.parse(dateMatch.group(2)!),
              );
              pendingName = '';
            }
            continue;
          }

          if (line.startsWith('TOTAL')) {
            final totalMatch = _totalCaloriesPattern.firstMatch(line);
            if (totalMatch != null && currentDate != null) {
              days.add(
                ParsedDay(
                  date: currentDate,
                  caloriesEaten: int.parse(totalMatch.group(1)!),
                  foodEntries: List.of(currentEntries),
                ),
              );
            }
            currentEntries = [];
            pendingName = '';
            continue;
          }

          final tokens = line.split(RegExp(r'\s+'));
          final entry = _tryParseFoodRow(tokens, pendingName);
          if (entry != null) {
            currentEntries.add(entry);
            pendingName = '';
          } else {
            pendingName = pendingName.isEmpty ? line : '$pendingName $line';
          }
        }
      }

      return days;
    } finally {
      await document.dispose();
    }
  }

  ParsedFoodEntry? _tryParseFoodRow(List<String> tokens, String pendingName) {
    if (tokens.length < 8) return null;
    final tail = tokens.sublist(tokens.length - 8);
    final calories = tail[0];
    final grams = tail.sublist(1, 6);
    final milligrams = tail[6];
    final time = tail[7];

    if (!_intPattern.hasMatch(calories)) return null;
    if (!grams.every(_gramsPattern.hasMatch)) return null;
    if (!_milligramsPattern.hasMatch(milligrams)) return null;
    if (!_timePattern.hasMatch(time)) return null;

    final nameTokens = tokens.sublist(0, tokens.length - 8);
    final name = [
      pendingName,
      ...nameTokens,
    ].where((s) => s.isNotEmpty).join(' ').trim();
    if (name.isEmpty) return null;

    return ParsedFoodEntry(
      name: name,
      calories: int.parse(calories),
      proteinG: _stripUnit(grams[0]),
      carbsG: _stripUnit(grams[1]),
      fatG: _stripUnit(grams[2]),
      fiberG: _stripUnit(grams[3]),
      sugarG: _stripUnit(grams[4]),
      sodiumMg: _stripUnit(milligrams),
      loggedAtTime: time,
    );
  }

  int _stripUnit(String token) =>
      int.parse(token.replaceAll(RegExp(r'[a-z]+$'), ''));

  bool _isBoilerplate(String line) =>
      _boilerplateLines.contains(line) || line.startsWith('Start:');
}
