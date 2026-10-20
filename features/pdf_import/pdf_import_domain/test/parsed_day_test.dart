import 'package:flutter_test/flutter_test.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';

ParsedFoodEntry _entry({String name = 'Ground Turkey', int calories = 780}) =>
    ParsedFoodEntry(
      name: name,
      calories: calories,
      proteinG: 96,
      carbsG: 0,
      fatG: 48,
      fiberG: 0,
      sugarG: 0,
      sodiumMg: 1440,
      loggedAtTime: '3:11pm',
    );

void main() {
  group('ParsedFoodEntry', () {
    test('equal when every field matches', () {
      expect(_entry(), _entry());
      expect(_entry().hashCode, _entry().hashCode);
    });

    test('not equal when any field differs', () {
      expect(_entry(), isNot(_entry(calories: 781)));
      expect(_entry(), isNot(_entry(name: 'Oatmeal')));
    });
  });

  group('ParsedDay', () {
    final date = DateTime(2025, 8, 5);

    test('compares foodEntries by value, not identity', () {
      final a = ParsedDay(
        date: date,
        caloriesEaten: 780,
        foodEntries: [_entry()],
      );
      final b = ParsedDay(
        date: date,
        caloriesEaten: 780,
        foodEntries: [_entry()],
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('not equal when foodEntries differ', () {
      final a = ParsedDay(
        date: date,
        caloriesEaten: 780,
        foodEntries: [_entry()],
      );
      final b = ParsedDay(
        date: date,
        caloriesEaten: 780,
        foodEntries: [_entry(name: 'Oatmeal')],
      );
      expect(a, isNot(b));
    });

    test('foodEntries cannot be mutated through the entity', () {
      final day = ParsedDay(
        date: date,
        caloriesEaten: 780,
        foodEntries: [_entry()],
      );
      expect(() => day.foodEntries.add(_entry()), throwsUnsupportedError);
    });
  });
}
