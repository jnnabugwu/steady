import 'package:equatable/equatable.dart';
import 'package:pdf_import_domain/src/parsed_food_entry.dart';

/// A single day's worth of food parsed from a Cal AI PDF export.
class ParsedDay extends Equatable {
  const ParsedDay({
    required this.date,
    required this.caloriesEaten,
    required this.foodEntries,
  });

  /// The day this data belongs to.
  final DateTime date;

  /// The day's aggregate calorie total — the only field that lands in
  /// SwiftData; individual food entries are not persisted.
  final int caloriesEaten;

  /// This day's individual food entries, kept only for an in-session
  /// review screen.
  final List<ParsedFoodEntry> foodEntries;

  @override
  List<Object?> get props => [date, caloriesEaten, foodEntries];
}
