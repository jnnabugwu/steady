import 'package:failures/failures.dart';
import 'package:health_sync_domain/src/health_authorization_status.dart';
import 'package:health_sync_domain/src/health_day_totals.dart';
import 'package:health_sync_domain/src/weight_unit.dart';

/// Reads daily totals from Apple Health. Read-only: Steady never writes to
/// Health.
///
/// iOS only: nothing on macOS implements this, and the Mac has no Health
/// data. What it returns is shown live and kept in memory only; it is never
/// written to the iCloud-synced `DailyMetric` store (App Store guideline
/// 5.1.3(ii)).
abstract class HealthKitRepository {
  /// Whether Health is available on this device at all.
  ResultFuture<bool> isAvailable();

  /// Whether the read-permission sheet has been shown yet. See
  /// [HealthAuthorizationStatus] for why that's all HealthKit says.
  ResultFuture<HealthAuthorizationStatus> authorizationStatus();

  /// Shows the read-permission sheet for step count, active energy, basal
  /// energy, weight and dietary energy, if it hasn't been shown for all five
  /// already (iOS shows it at most once per type; after that this returns
  /// at once).
  ///
  /// `Ok` means the request completed, not that the user allowed anything.
  ResultFuture<Unit> requestAuthorization();

  /// One [HealthDayTotals] per local calendar day from [start] to [end],
  /// inclusive (both are converted to local time, then reduced to their
  /// calendar day), sorted by date. A day with no samples still has a row,
  /// with `null` values. `Err(ValidationFailure)` if [start] is after
  /// [end], or either is outside the years 0000 to 9999.
  ///
  /// A `null` value is ambiguous: no samples that day, read access the user
  /// didn't allow (HealthKit doesn't say which), or, for weight and calories
  /// eaten, a permission sheet not shown yet. Don't present it as "nothing
  /// recorded" unless the same type has a value elsewhere in the range.
  ResultFuture<List<HealthDayTotals>> dailyTotals(DateTime start, DateTime end);

  /// The unit the Health app shows weight in, so Steady shows the same.
  /// Fails until the permission sheet has been shown.
  ResultFuture<WeightUnit> preferredWeightUnit();
}
