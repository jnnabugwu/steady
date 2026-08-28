/// Self-reported end-of-day logging status for a `DailyMetric`.
enum LoggingStatus {
  /// The day was fully logged.
  logged,

  /// The day was partially logged.
  partial,

  /// The day was skipped.
  skipped,
}
