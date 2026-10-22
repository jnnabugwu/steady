/// Names each nullable `DailyMetric` field, for
/// `DailyMetricRepository.clearFields`.
///
/// `date` has no member on purpose: it is the row's natural key, not a value
/// that can be cleared. Adding a nullable field to `DailyMetric` means adding
/// a member here too. Implementations switch exhaustively over this enum, so
/// the compiler then points at every place that needs to handle it.
enum DailyMetricField {
  /// `DailyMetric.caloriesEaten`.
  caloriesEaten,

  /// `DailyMetric.caloriesBurnedActive`.
  caloriesBurnedActive,

  /// `DailyMetric.caloriesBurnedBasal`.
  caloriesBurnedBasal,

  /// `DailyMetric.steps`.
  steps,

  /// `DailyMetric.loggingStatus`.
  loggingStatus,
}
