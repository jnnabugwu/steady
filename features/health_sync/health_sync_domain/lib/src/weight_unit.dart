/// The unit the Health app shows weight in (`preferredUnits(for:)`).
/// Steady reads weight in kilograms and converts only to display it.
enum WeightUnit {
  /// Kilograms, e.g. "82.4 kg". Also the fallback for any unit Health
  /// reports that isn't one of the others.
  kilograms,

  /// Pounds, e.g. "181.7 lb".
  pounds,

  /// Stones and pounds, e.g. "12 st 13.7 lb".
  stones,
}
