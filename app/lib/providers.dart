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
/// HealthKit or SwiftData datasource), the choice is made inside this file
/// with `Platform.isIOS`/`isMacOS` or conditional imports. None is needed
/// yet: the shared store is an interim JSON file (in-memory in tests), and
/// every other repository is in-memory, the same on both platforms.
///
/// **Shared-store invariant:** [dailyMetricRepositoryProvider] is the single
/// `DailyMetricRepository`. Every override that needs it does
/// `ref.watch(dailyMetricRepositoryProvider)` and never constructs its own.
/// If that's ever broken, checkin/metrics/pdf_import each end up with a
/// private copy of the store, and their writes silently stop being visible
/// to each other even though every isolated unit test still passes.
/// `test/bootstrap_test.dart` guards this against [appProviderOverrides].
///
/// Nothing is wired for coach yet: `coach_domain` has no repository
/// interface so far.
///
/// Swap-in-later: once the real SwiftData-backed datasource lands, only the
/// body of [dailyMetricRepository] changes. Every downstream signature stays
/// the same.
library;

import 'dart:io';

import 'package:checkin_data/checkin_data.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:metrics_data/metrics_data.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:notifications_data/notifications_data.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:pdf_import_data/pdf_import_data.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The JSON file the interim [dailyMetricRepository] persists to, or `null`
/// for an in-memory store.
///
/// `null` by default, so tests built from [appProviderOverrides] stay
/// in-memory and touch no disk. `main.dart` overrides it with a file in the
/// app-support directory, which needs an async `path_provider` lookup before
/// `runApp`.
@Riverpod(keepAlive: true)
File? dailyMetricsFile(Ref ref) => null;

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through.
///
/// Interim: backed by a local JSON file when [dailyMetricsFile] is set,
/// until the SwiftData + CloudKit datasource replaces it (#43). That swap
/// changes only this body.
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).
@Riverpod(keepAlive: true)
DailyMetricRepository dailyMetricRepository(Ref ref) {
  final file = ref.watch(dailyMetricsFileProvider);
  return file == null
      ? InMemoryDailyMetricRepository()
      : FileDailyMetricRepository(file);
}

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
];
