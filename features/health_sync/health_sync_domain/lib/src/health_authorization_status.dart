/// Where Steady stands with Apple Health's read permission.
///
/// There's deliberately no "allowed" or "denied": for read access, HealthKit
/// never tells an app what the user chose (so an app can't infer that the
/// user has, say, a health condition from a refusal). All Steady can know
/// is whether it has already shown the permission sheet.
enum HealthAuthorizationStatus {
  /// Health isn't available on this device (an iPad without Health, or any
  /// platform other than iOS).
  unavailable,

  /// The permission sheet hasn't been shown yet for at least one of the
  /// three types Steady reads.
  notDetermined,

  /// The permission sheet has been shown for every type Steady reads. The
  /// user may have allowed some, all or none of them; Settings > Health is
  /// the only place that says which.
  requested,
}
