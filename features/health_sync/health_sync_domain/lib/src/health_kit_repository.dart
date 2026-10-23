import 'package:failures/failures.dart';
import 'package:health_sync_domain/src/health_authorization_status.dart';
import 'package:health_sync_domain/src/health_day_totals.dart';

/// Reads daily totals from Apple Health. Read-only: Steady never writes to
/// Health.
///
/// iOS only. The iPhone is the one HealthKit reader; the Mac sees the same
/// values through CloudKit, so nothing on macOS implements this.
abstract class HealthKitRepository {
  /// Whether Health is available on this device at all.
  ResultFuture<bool> isAvailable();

  /// Whether the read-permission sheet has been shown yet. See
  /// [HealthAuthorizationStatus] for why that's all HealthKit says.
  ResultFuture<HealthAuthorizationStatus> authorizationStatus();

  /// Shows the read-permission sheet for step count, active energy and
  /// basal energy, if it hasn't been shown for all three already (iOS
  /// shows it at most once per type; after that this returns at once).
  ///
  /// `Ok` means the request completed, not that the user allowed anything.
  ResultFuture<Unit> requestAuthorization();

  /// One [HealthDayTotals] per local calendar day from [start] to [end],
  /// inclusive (both are reduced to their calendar day), sorted by date.
  /// A day with no samples still has a row, with `null` values.
  ResultFuture<List<HealthDayTotals>> dailyTotals(DateTime start, DateTime end);
}
