import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_data/pdf_import_data.dart';

/// End-to-end check of `CalAIParser` against the real reference export
/// (personal data, gitignored -- see test/fixtures/README or
/// docs/technical_decisions.md). Skips itself if the fixture isn't present,
/// so it only runs when a developer restores the file locally.
///
/// The CI-visible regression bar for the parsing logic lives in
/// `cal_ai_parser_lines_test.dart`, which drives the `parsePageLines` seam
/// with synthetic lines and needs no fixture.
void main() {
  final fixture = File('test/fixtures/jordanssummary.pdf');
  final fixtureExists = fixture.existsSync();

  group('CalAIParser', () {
    test(
      'parses every day, with exact calorie totals and no boilerplate '
      'leaking into food names',
      () async {
        final bytes = fixture.readAsBytesSync();
        final parser = CalAIParser();

        final days = await parser.parse(Uint8List.fromList(bytes));

        expect(days, hasLength(208));

        // Exact daily totals, spot-checked against the source PDF.
        final byDate = {for (final d in days) d.date: d};
        expect(byDate[DateTime(2025, 8)]?.caloriesEaten, 4941);
        expect(byDate[DateTime(2025, 8, 2)]?.caloriesEaten, 1630);
        expect(byDate[DateTime(2025, 8, 3)]?.caloriesEaten, 2428);
        expect(byDate[DateTime(2025, 8, 4)]?.caloriesEaten, 852);
        expect(byDate[DateTime(2025, 8, 5)]?.caloriesEaten, 2710);
        expect(byDate[DateTime(2026, 3, 31)]?.caloriesEaten, 2925);
        expect(byDate[DateTime(2026, 4, 2)]?.caloriesEaten, 1192);

        expect(byDate[DateTime(2025, 8)]?.foodEntries, hasLength(17));

        // Multi-line wrapped food name reassembled correctly, with no
        // boilerplate (the "Foods Calories ... Time" column header, or
        // "Jordan's Report" page header) leaking into the name.
        final aug5Names = byDate[DateTime(2025, 8, 5)]!.foodEntries
            .map((e) => e.name);
        expect(
          aug5Names,
          contains('Muscle Milk Chocolate Peanut Butter Protein Shake'),
        );

        // No day's date appears twice, and no entry name contains
        // boilerplate/header text.
        expect(days.map((d) => d.date).toSet(), hasLength(days.length));
        for (final day in days) {
          for (final entry in day.foodEntries) {
            expect(entry.name, isNot(contains('Jordan')));
            expect(entry.name, isNot(contains('Foods Calories')));
            expect(entry.name, isNot(contains('Summary for')));
            expect(entry.name.trim(), isNotEmpty);
          }
        }
      },
      skip: fixtureExists
          ? null
          : 'reference PDF not present at test/fixtures/jordanssummary.pdf',
    );
  });
}
