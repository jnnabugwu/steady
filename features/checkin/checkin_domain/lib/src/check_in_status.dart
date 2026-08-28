/// Check-in's own status vocabulary. Deliberately a separate enum from
/// `daily_metrics_domain`'s `LoggingStatus` (which shares the same three
/// values today) rather than a direct reuse — see `docs/technical_decisions.md`.
enum CheckInStatus {
  /// The day was fully logged.
  logged,

  /// The day was partially logged.
  partial,

  /// The day was skipped.
  skipped,
}
