import 'package:equatable/equatable.dart';

/// A single food entry parsed from a Cal AI PDF export. Kept only for an
/// in-session review screen — never persisted. Only a day's aggregate
/// `caloriesEaten` total lands in SwiftData.
class ParsedFoodEntry extends Equatable {
  const ParsedFoodEntry({
    required this.name,
    required this.calories,
    required this.proteinG,
    required this.carbsG,
    required this.fatG,
    required this.fiberG,
    required this.sugarG,
    required this.sodiumMg,
    required this.loggedAtTime,
  });

  /// The food's name, reassembled if it wrapped across multiple lines.
  final String name;

  /// Calories for this entry.
  final int calories;

  /// Grams of protein.
  final int proteinG;

  /// Grams of carbohydrates.
  final int carbsG;

  /// Grams of fat.
  final int fatG;

  /// Grams of fiber.
  final int fiberG;

  /// Grams of sugar.
  final int sugarG;

  /// Milligrams of sodium.
  final int sodiumMg;

  /// The raw logged time, e.g. `"3:11pm"`. Kept as a string — no timezone
  /// semantics to parse into.
  final String loggedAtTime;

  @override
  List<Object?> get props => [
    name,
    calories,
    proteinG,
    carbsG,
    fatG,
    fiberG,
    sugarG,
    sodiumMg,
    loggedAtTime,
  ];
}
