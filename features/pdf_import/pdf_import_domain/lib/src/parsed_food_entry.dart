import 'package:freezed_annotation/freezed_annotation.dart';

part 'parsed_food_entry.freezed.dart';

/// A single food entry parsed from a Cal AI PDF export. Kept only for an
/// in-session review screen — never persisted. Only a day's aggregate
/// `caloriesEaten` total lands in SwiftData.
@freezed
abstract class ParsedFoodEntry with _$ParsedFoodEntry {
  /// Creates a [ParsedFoodEntry].
  const factory ParsedFoodEntry({
    /// The food's name, reassembled if it wrapped across multiple lines.
    required String name,

    /// Calories for this entry.
    required int calories,

    /// Grams of protein.
    required int proteinG,

    /// Grams of carbohydrates.
    required int carbsG,

    /// Grams of fat.
    required int fatG,

    /// Grams of fiber.
    required int fiberG,

    /// Grams of sugar.
    required int sugarG,

    /// Milligrams of sodium.
    required int sodiumMg,

    /// The raw logged time, e.g. `"3:11pm"`. Kept as a string — no timezone
    /// semantics to parse into.
    required String loggedAtTime,
  }) = _ParsedFoodEntry;
}
