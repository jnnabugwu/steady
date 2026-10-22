/// Native side of the shared `DailyMetric` store (CLAUDE.md §7, §8).
///
/// This package ships the Swift half only: a SwiftData `@Model` and a thin
/// MethodChannel bridge in `darwin/`. The Dart client, and every domain
/// rule (partial-field merge, clearFields, normalization), live in
/// `daily_metrics_data`'s `SwiftDataDailyMetricRepository`, so they stay
/// unit-testable without a device.
///
/// Channel contract, on [dailyMetricsStoreChannelName]. Dates are
/// `yyyy-MM-dd` strings. A row is a map with `date` plus every
/// `DailyMetric` field (`caloriesEaten`, `caloriesBurnedActive`,
/// `caloriesBurnedBasal`, `steps`: int or null; `loggingStatus`: the
/// `LoggingStatus` enum name or null).
///
/// | Method   | Arguments                     | Returns                    |
/// | -------- | ----------------------------- | -------------------------- |
/// | `get`    | `{date}`                      | row or null                |
/// | `range`  | `{start, end}` (inclusive)    | rows, sorted by date       |
/// | `put`    | row (full replace, nil = nil) | the stored row             |
/// | `remove` | `{date}`                      | null                       |
///
/// Test-only: `useStore` (`{name}`) reopens the container on a separate
/// local, never-CloudKit store file (`{name: null}` switches back to the
/// real store); `reset` (test stores only) deletes every record in the
/// current store; `insertRecordForTesting` (`{row, modifiedAtMillis}`, test
/// stores only) inserts a raw record without de-duplicating, to simulate
/// two devices creating the same day. A test-stores-only call made while
/// the real store is selected fails with `not_test_store` before the real
/// store is opened.
///
/// Same-day duplicates are merged on read: per field, the non-null value
/// from the record with the latest `modifiedAt` wins, equal timestamps
/// broken by comparing the records' values (`MetricRow.outranks`), so every
/// device reaches the same row.
///
/// Failures come back as `PlatformException`s with one of these codes:
/// `bad_args`, `store_unavailable`, `fetch_failed`, `save_failed`,
/// `not_test_store`, or `unknown` (any other native error).
library;

/// The MethodChannel the native store listens on.
const String dailyMetricsStoreChannelName = 'steady/daily_metrics';
