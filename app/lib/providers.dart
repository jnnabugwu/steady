/// Dependency injection for the whole app (CLAUDE.md §9, D1 Option A).
///
/// Each `*_presentation` package declares the repository providers it needs,
/// typed against its domain interface, and throws unless overridden. This
/// file is the one place that binds them to their `*_data` implementations,
/// via [appProviderOverrides]. `main.dart` passes that list to
/// `ProviderScope`, and `test/bootstrap_test.dart` builds a container from
/// the same list, so the tests exercise the real wiring.
///
/// One app, two platform targets, so there's one override list, not one per
/// target. When an implementation does differ by platform (e.g. the
/// HealthKit datasource), the choice is made inside this file with
/// `Platform.isIOS`/`isMacOS` or conditional imports. The shared store is
/// SwiftData on both targets (in-memory in tests, see [dailyMetricStore]),
/// every other repository is in-memory, the same on both platforms, and
/// the account status goes through the `steady/account` platform channel,
/// whose one Dart implementation talks to a per-platform Swift handler
/// (`app/macos/Runner/MainFlutterWindow.swift`,
/// `app/ios/Runner/AppDelegate.swift`).
///
/// **Shared-store invariant:** [dailyMetricRepositoryProvider] is the single
/// `DailyMetricRepository`. Every override that needs it does
/// `ref.watch(dailyMetricRepositoryProvider)` and never constructs its own.
/// If that's ever broken, checkin/metrics/pdf_import each end up with a
/// private copy of the store, and their writes silently stop being visible
/// to each other (or to data_export, which would then export an empty or
/// stale copy) even though every isolated unit test still passes.
/// `test/bootstrap_test.dart` guards this against [appProviderOverrides].
///
/// Nothing is wired for coach yet: `coach_domain` has no repository
/// interface so far.
library;

import 'package:account_data/account_data.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_data/checkin_data.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:metrics_data/metrics_data.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:notifications_data/notifications_data.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// Which backing store [dailyMetricRepository] uses.
enum DailyMetricStore {
  /// In memory, gone on restart. The default, so tests built from
  /// [appProviderOverrides] touch no disk and need no native plugin.
  inMemory,

  /// SwiftData via the `daily_metrics_store` plugin: the live store on iOS
  /// and macOS. CloudKit sync is gated natively by Info.plist
  /// `SteadyCloudKitEnabled` (CLAUDE.md §7).
  swiftData,
}

/// The store [dailyMetricRepository] is built on. `main.dart` overrides it
/// to [DailyMetricStore.swiftData].
@Riverpod(keepAlive: true)
DailyMetricStore dailyMetricStore(Ref ref) => DailyMetricStore.inMemory;

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through, and data_export reads from.
/// Backed by [dailyMetricStore].
///
/// The interim JSON file store is no longer used here; `main.dart` migrates
/// its rows into this repository once (`migrateFileStore`).
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).
@Riverpod(keepAlive: true)
DailyMetricRepository dailyMetricRepository(Ref ref) =>
    switch (ref.watch(dailyMetricStoreProvider)) {
      DailyMetricStore.inMemory => InMemoryDailyMetricRepository(),
      DailyMetricStore.swiftData => SwiftDataDailyMetricRepository(),
    };

/// Schedules and cancels the end-of-day reminder.
///
/// Declared here rather than in a feature package: `notifications` is
/// headless (no `*_presentation` package), and the app layer is what reads
/// it, e.g. a route cancelling the reminder once a check-in completes
/// (CLAUDE.md §5).
///
/// `keepAlive`: cheap and stateless, so recreating it gains nothing (D6).
@Riverpod(keepAlive: true)
NotificationScheduler notificationScheduler(Ref ref) =>
    InMemoryNotificationScheduler();

/// Binds every feature-declared repository provider to its `*_data`
/// implementation. Passed to `ProviderScope` in `main.dart`, and used as-is
/// by `test/bootstrap_test.dart`.
final List<Override> appProviderOverrides = [
  // The iCloud account status (#53). Until CloudKit is configured (the
  // `SteadyCloudKitEnabled` Info.plist flag, flipped by #43), the native
  // side answers `notConfigured`, which never blocks the app.
  accountStatusRepositoryProvider.overrideWith(
    (ref) => MethodChannelAccountStatusRepository(),
  ),
  checkInRepositoryProvider.overrideWith(
    (ref) => CheckInRepositoryImpl(ref.watch(dailyMetricRepositoryProvider)),
  ),
  metricsRepositoryProvider.overrideWith(
    (ref) => MetricsRepositoryImpl(ref.watch(dailyMetricRepositoryProvider)),
  ),
  // checkin's share card reads the week through metrics' read-only
  // interface: the same instance, so the same shared store.
  weekMetricsRepositoryProvider.overrideWith(
    (ref) => ref.watch(metricsRepositoryProvider),
  ),
  pdfImportRepositoryProvider.overrideWith(
    (ref) => PdfImportRepositoryImpl(
      parser: CalAIParser(),
      dailyMetrics: ref.watch(dailyMetricRepositoryProvider),
    ),
  ),
  // data_export has no `*_data` package: it only reads, through the shared
  // store's domain interface, so it binds straight to that store.
  exportDailyMetricRepositoryProvider.overrideWith(
    (ref) => ref.watch(dailyMetricRepositoryProvider),
  ),
];
