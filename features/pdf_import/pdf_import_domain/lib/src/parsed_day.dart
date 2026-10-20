import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pdf_import_domain/src/parsed_food_entry.dart';

part 'parsed_day.freezed.dart';

/// A single day's worth of food parsed from a Cal AI PDF export.
@freezed
abstract class ParsedDay with _$ParsedDay {
  /// Creates a [ParsedDay].
  const factory ParsedDay({
    /// The day this data belongs to.
    required DateTime date,

    /// The day's aggregate calorie total — the only field that lands in
    /// SwiftData; individual food entries are not persisted.
    required int caloriesEaten,

    /// This day's individual food entries, kept only for an in-session
    /// review screen.
    required List<ParsedFoodEntry> foodEntries,
  }) = _ParsedDay;
}
