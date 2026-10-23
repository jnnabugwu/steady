import 'package:freezed_annotation/freezed_annotation.dart';

part 'health_sync_report.freezed.dart';

/// What one `syncHealthDays` run did.
@freezed
abstract class HealthSyncReport with _$HealthSyncReport {
  /// Creates a report.
  const factory HealthSyncReport({
    /// Days whose `DailyMetric` row was written: a Health value was new or
    /// had changed. Unchanged days aren't written, so this is 0 on a
    /// repeat sync with nothing new.
    required int daysUpdated,

    /// Days in the window where Health had any of the three values. 0 means
    /// Health returned nothing at all, which is also what it returns when
    /// the user didn't allow read access (HealthKit doesn't say which).
    required int daysWithData,
  }) = _HealthSyncReport;
}
