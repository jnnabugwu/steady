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
/// **Apple Health is iOS only, and never stored** (#74, #75): the iPhone
/// reads Health live and keeps the values in memory while they're shown;
/// they're never written to the shared store, which is mirrored to iCloud
/// (App Store guideline 5.1.3(ii)). The Mac and the coach have no Health
/// data. [healthKitRepositoryProvider] is bound only when
/// [appProviderOverridesFor] is built with `isIOS: true`; everywhere else it
/// stays `null`, and Health reads (`metricsHealthKitRepositoryProvider`,
/// `health_access.dart`) return nothing.
///
/// **Craving support is iOS only, and device-only** (#109): the iPhone
/// stores craving check-ins in a JSON file in its application support
/// directory ([cravingStoreFile]), never in SwiftData/CloudKit, so they
/// never reach iCloud (App Store 5.1.3(ii); CLAUDE.md §7). Like Apple
/// Health, it's bound only when [appProviderOverridesFor] is built with
/// `isIOS: true`, which also sets `cravingSupportAvailableProvider`; on
/// macOS the repository stays unbound and every craving surface renders
/// nothing.
///
/// **The coach is iOS only, and its sessions are device-only** (#78,
/// CLAUDE.md §11): transcripts and summaries are kept in a JSON file in the
/// application support directory ([coachStoreFile]), never in
/// SwiftData/CloudKit, for the same 5.1.3(ii) reason as cravings.
/// `coachRepositoryProvider`, `coachSupportAvailableProvider` and the
/// export's `exportCoachRepositoryProvider` are bound only when
/// [appProviderOverridesFor] is built with `isIOS: true`; the Mac binds no
/// coach provider at all.
///
/// **The coach is iOS only** (#79, CLAUDE.md §11): its on-device model
/// (`coachModelProvider`, Apple Foundation Models through the
/// `steady/coach` channel) is bound only when [appProviderOverridesFor] is
/// built with `isIOS: true`. On macOS it stays unbound, and there's no
/// coach code in `app/macos/` at all. Whether the model can actually run
/// on a given iPhone is a runtime check (`CoachModel.checkAvailability`).
library;

import 'dart:io';

import 'package:account_data/account_data.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_data/checkin_data.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:coach_data/coach_data.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:cravings_data/cravings_data.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_data/metrics_data.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:path_provider/path_provider.dart';
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

/// Apple Health's daily totals, or `null` where Health isn't read: macOS,
/// and tests. `null` by default; [appProviderOverridesFor] binds the
/// `steady/healthkit` channel on iOS only. The one Health source: features
/// that read Health bind their own provider to this one.
///
/// Declared here rather than in a feature package: `health_sync` is
/// headless (no `*_presentation` package).
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
HealthKitRepository? healthKitRepository(Ref ref) => null;

/// Binds every feature-declared repository provider to its `*_data`
/// implementation, for the current platform. Passed to `ProviderScope` in
/// `main.dart`, and used as-is by `test/bootstrap_test.dart`.
final List<Override> appProviderOverrides = appProviderOverridesFor(
  isIOS: Platform.isIOS,
);

/// The device-only craving file: `cravings.json` in the application
/// support directory. Looked up on first use, not at launch.
Future<File> cravingStoreFile() async =>
    File('${(await getApplicationSupportDirectory()).path}/cravings.json');

/// The device-only coach file: `coach_sessions.json` in the application
/// support directory. Looked up on first use, not at launch.
Future<File> coachStoreFile() async => File(
  '${(await getApplicationSupportDirectory()).path}/coach_sessions.json',
);

/// [appProviderOverrides] for a given platform. The platform choices in it
/// are Apple Health, craving support and the coach, all bound only when
/// [isIOS] (see the library comment). A function, not just the list, so
/// tests can build the iOS wiring on any host.
List<Override> appProviderOverridesFor({required bool isIOS}) => [
  if (isIOS) ...[
    healthKitRepositoryProvider.overrideWith(
      (ref) => MethodChannelHealthKitRepository(),
    ),
    cravingSupportAvailableProvider.overrideWithValue(true),
    cravingRepositoryProvider.overrideWith(
      (ref) => FileCravingRepository.locatedBy(cravingStoreFile),
    ),
    coachSupportAvailableProvider.overrideWithValue(true),
    coachRepositoryProvider.overrideWith(
      (ref) => FileCoachRepository.locatedBy(coachStoreFile),
    ),
    // The export reads each session's date, kind and summary through the
    // coach's own repository: the same instance, so the same file.
    exportCoachRepositoryProvider.overrideWith(
      (ref) => ref.watch(coachRepositoryProvider),
    ),
    coachModelProvider.overrideWith((ref) => MethodChannelCoachModel()),
  ],
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
  // The history's live Health read: the app's one Health source, so `null`
  // (no Health) everywhere but iOS. Read only, never written anywhere.
  metricsHealthKitRepositoryProvider.overrideWith(
    (ref) => ref.watch(healthKitRepositoryProvider),
  ),
];
