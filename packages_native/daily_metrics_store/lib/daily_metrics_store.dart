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
/// Info: `capabilities` (no arguments, never opens the store) returns
/// `{historyFiltering: bool}`: whether the changes channel below can leave
/// out this app's own writes (true on iOS 18 / macOS 15+).
///
/// Test-only: `useStore` (`{name}`) reopens the container on a separate
/// local, never-CloudKit store file (`{name: null}` switches back to the
/// real store); `reset` (test stores only) deletes every record in the
/// current store; `insertRecordForTesting` (`{row, modifiedAtMillis}`, test
/// stores only) inserts a raw record without de-duplicating, to simulate
/// two devices creating the same day; `simulateImportForTesting` (same
/// arguments, test stores only) inserts a record through a second
/// `ModelContext` under another author, the way a CloudKit import does, so
/// it triggers the changes channel below. A test-stores-only call made while
/// the real store is selected fails with `not_test_store` before the real
/// store is opened.
///
/// Debug builds only: `initializeCloudKitSchema` (no arguments) pushes every
/// attribute of the SwiftData model to the CloudKit **development** schema
/// through a throwaway store in the temp directory (never the real store),
/// with `NSPersistentCloudKitContainer.initializeCloudKitSchema`, off the
/// main thread; it can take tens of seconds (#93,
/// `docs/cloudkit_schema.md`). Returns `{containerIdentifier, recordTypes:
/// [{name, fields: [{name, type}]}]}` in CloudKit's names
/// (`CD_DailyMetricRecord`, `CD_day`: `String`, ...). Fails with
/// `cloudkit_disabled` (Info.plist has no CloudKit container),
/// `schema_init_running` (a run is already in flight) or
/// `schema_init_failed`. In release builds the method doesn't exist, so it
/// fails with `MissingPluginException`.
///
/// Same-day duplicates are merged on read: per field, the non-null value
/// from the record with the latest `modifiedAt` wins, equal timestamps
/// broken by comparing the records' values (`MetricRow.outranks`), so every
/// device reaches the same row.
///
/// Failures come back as `PlatformException`s with one of these codes:
/// `bad_args`, `store_unavailable`, `fetch_failed`, `save_failed`,
/// `not_test_store`, `cloudkit_disabled`, `schema_init_running`,
/// `schema_init_failed`, or `unknown` (any other native error).
///
/// Remote changes, on the EventChannel [dailyMetricsStoreChangesChannelName]:
/// while Dart listens, the plugin observes `NSPersistentStoreRemoteChange`
/// for the open store, waits for a burst of saves to settle (400 ms), and
/// emits one event if any of them came from something other than the
/// channel itself, in practice a CloudKit import from another device. The
/// event is an `int` counting events since launch; it carries no data, so a
/// listener just re-reads. Own channel writes are told apart through
/// SwiftData's persistent history (author `steady.daily_metrics_channel`),
/// which needs iOS 18 / macOS 15; on iOS 17 / macOS 14 every change emits,
/// own writes included (`capabilities` reports which). Cancelling is
/// idempotent: a `cancel` with no active listener is a no-op. Test stores
/// are observed the same way; they never sync, so only
/// `simulateImportForTesting` makes them emit.
library;

/// The MethodChannel the native store listens on.
const String dailyMetricsStoreChannelName = 'steady/daily_metrics';

/// The EventChannel the native store reports remote (CloudKit) changes on.
const String dailyMetricsStoreChangesChannelName =
    'steady/daily_metrics/changes';
