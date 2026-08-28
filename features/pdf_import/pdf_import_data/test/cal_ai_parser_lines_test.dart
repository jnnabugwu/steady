import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_data/pdf_import_data.dart';

/// CI regression bar for `CalAIParser`'s text-shape logic, driven by
/// synthetic page lines (no PDF, no personal data) so it actually runs on
/// every build -- unlike `cal_ai_parser_test.dart`, which needs the
/// gitignored reference export and self-skips in CI. Exercises the
/// `parsePageLines` seam directly.
///
/// Line shapes mirror a real `pdfrx_engine` extraction (CLAUDE.md §6): each
/// table row is one whitespace-joined line ending in 8 tokens -- a bare
/// int, 5x grams, 1x mg, 1x time -- with everything before that the name.
void main() {
  final parser = CalAIParser();

  group('CalAIParser.parsePageLines', () {
    test('parses a date header, food rows, and the printed TOTAL', () {
      final days = parser.parsePageLines([
        "Jordan's Report",
        'Foods Calories Protein Carbs Fat Fiber Sugar Sodium Time',
        'August 1, 2025',
        'Ground Turkey 780 96g 0g 48g 0g 0g 1440mg 3:11pm',
        'White Rice 205 4g 45g 0g 1g 0g 2mg 3:12pm',
        'TOTAL Calories eaten: 985',
      ]);

      expect(days, hasLength(1));
      expect(days.single.date, DateTime(2025, 8));
      expect(days.single.caloriesEaten, 985);
      expect(
        days.single.foodEntries.map((e) => e.name),
        ['Ground Turkey', 'White Rice'],
      );
      expect(days.single.foodEntries.map((e) => e.calories), [780, 205]);
    });

    test('reassembles a food name wrapped across two lines', () {
      final days = parser.parsePageLines([
        'August 5, 2025',
        'Muscle Milk Chocolate Peanut Butter',
        'Protein Shake 160 20g 5g 3g 1g 2g 200mg 8:04am',
        'TOTAL Calories eaten: 160',
      ]);

      expect(
        days.single.foodEntries.single.name,
        'Muscle Milk Chocolate Peanut Butter Protein Shake',
      );
    });

    test('never absorbs boilerplate into the following food name', () {
      final days = parser.parsePageLines([
        'August 2, 2025',
        "Jordan's Report",
        'Foods Calories Protein Carbs Fat Fiber Sugar Sodium Time',
        'Start: 12:00am',
        'Oatmeal 300 10g 54g 5g 8g 1g 0mg 7:30am',
        'TOTAL Calories eaten: 300',
      ]);

      expect(days.single.foodEntries.single.name, 'Oatmeal');
    });

    test('uses the printed TOTAL, not the sum of the food rows', () {
      final days = parser.parsePageLines([
        'August 3, 2025',
        'Item A 100 1g 1g 1g 1g 1g 1mg 9:00am',
        'Item B 100 1g 1g 1g 1g 1g 1mg 9:30am',
        // Deliberately not 200 -- Cal AI's own total wins.
        'TOTAL Calories eaten: 2428',
      ]);

      expect(days.single.caloriesEaten, 2428);
    });

    test('a day with no TOTAL line produces no ParsedDay', () {
      final days = parser.parsePageLines([
        'August 4, 2025',
        'Lonely Snack 90 0g 20g 0g 0g 10g 5mg 4:00pm',
      ]);

      expect(days, isEmpty);
    });

    test('splits multiple days on one page', () {
      final days = parser.parsePageLines([
        'August 1, 2025',
        'Eggs 140 12g 1g 10g 0g 0g 140mg 8:00am',
        'TOTAL Calories eaten: 140',
        'August 2, 2025',
        'Toast 90 3g 15g 1g 2g 2g 150mg 8:10am',
        'Butter 100 0g 0g 11g 0g 0g 90mg 8:11am',
        'TOTAL Calories eaten: 190',
      ]);

      expect(days.map((d) => d.date), [
        DateTime(2025, 8),
        DateTime(2025, 8, 2),
      ]);
      expect(days.map((d) => d.foodEntries.length), [1, 2]);
    });
  });
}
