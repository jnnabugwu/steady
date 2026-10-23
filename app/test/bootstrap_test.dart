import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_data/testing/fake_daily_metrics_store.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/health_sync.dart';
import 'package:steady/providers.dart';

/// Guards the DI wiring in `lib/providers.dart`, built from the **real**
/// [appProviderOverrides] list rather than hand-picked fakes, so a broken
/// override fails here even when every feature's own unit tests pass.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ProviderContainer container;

  setUp(() {
    container = ProviderContainer.test(overrides: appProviderOverrides);
  });

  test('every repository interface resolves', () {
    // Reading a feature-declared provider that isn't overridden throws, so
    // each read below also proves the override list binds it.
    expect(
      container.read(dailyMetricRepositoryProvider),
      isA<DailyMetricRepository>(),
    );
    expect(container.read(checkInRepositoryProvider), isA<CheckInRepository>());
    expect(container.read(metricsRepositoryProvider), isA<MetricsRepository>());
    expect(
      container.read(pdfImportRepositoryProvider),
      isA<PdfImportRepository>(),
    );
    expect(
      container.read(notificationSchedulerProvider),
      isA<NotificationScheduler>(),
    );
  });

  test('health_sync (iOS) writes into the same underlying store, leaving '
      "pdf_import's calories alone", () async {
    final day = DateTime(2026, 8, 24);
    final ios = ProviderContainer.test(
      overrides: [
        // The iOS list binds the real channel; swap only that for a fake.
        ...appProviderOverridesFor(isIOS: false),
        healthKitRepositoryProvider.overrideWithValue(
          InMemoryHealthKitRepository(
            status: HealthAuthorizationStatus.requested,
            days: [HealthDayTotals(date: day, steps: 6000)],
          ),
        ),
        healthSyncClockProvider.overrideWithValue(() => DateTime(2026, 8, 25)),
      ],
    );
    await ios.read(pdfImportRepositoryProvider).commitDailyTotals([
      ParsedDay(date: day, caloriesEaten: 1850, foodEntries: const []),
    ]);

    await ios.read(healthSyncControllerProvider.notifier).syncHealthData();

    final result = await ios.read(metricsRepositoryProvider).getRange(day, day);
    final row = (result as Ok<List<DailyMetric>>).value.single;
    expect(row.steps, 6000);
    expect(row.caloriesEaten, 1850);
  });

  test('checkin and daily_metrics share the same underlying store', () async {
    final date = DateTime(2026, 8, 24);
    await container
        .read(checkInRepositoryProvider)
        .logCheckIn(date, CheckInStatus.logged);

    final result = await container
        .read(dailyMetricRepositoryProvider)
        .getByDate(date);
    final row = (result as Ok<DailyMetric?>).value;

    expect(row?.loggingStatus, LoggingStatus.logged);
  });

  test(
    'pdf_import and daily_metrics share the same underlying store',
    () async {
      final date = DateTime(2026, 8, 24);
      final commit = await container
          .read(pdfImportRepositoryProvider)
          .commitDailyTotals([
            ParsedDay(date: date, caloriesEaten: 1850, foodEntries: const []),
          ]);
      expect(commit, isA<Ok<Unit>>());

      final result = await container
          .read(dailyMetricRepositoryProvider)
          .getByDate(date);
      final row = (result as Ok<DailyMetric?>).value;

      expect(row?.caloriesEaten, 1850);
    },
  );

  test('metrics reads what the other features wrote, merged per day', () async {
    final date = DateTime(2026, 8, 24);
    await container
        .read(checkInRepositoryProvider)
        .logCheckIn(date, CheckInStatus.partial);
    await container.read(pdfImportRepositoryProvider).commitDailyTotals([
      ParsedDay(date: date, caloriesEaten: 1850, foodEntries: const []),
    ]);

    final result = await container
        .read(metricsRepositoryProvider)
        .getRange(date, date);
    final rows = (result as Ok<List<DailyMetric>>).value;

    expect(rows, hasLength(1));
    expect(rows.single.loggingStatus, LoggingStatus.partial);
    expect(rows.single.caloriesEaten, 1850);
  });

  test('data_export reads what checkin and pdf_import wrote, from the same '
      'store', () async {
    // The real override list; only the share sheet and the clock are
    // faked, so the export never reaches the share_plus plugin.
    final shared = <ExportFile>[];
    final exporting = ProviderContainer.test(
      overrides: [
        ...appProviderOverrides,
        exportFileSharerProvider.overrideWithValue((
          file, {
          sharePositionOrigin,
        }) async {
          shared.add(file);
          return const Ok(ExportShareOutcome.shared);
        }),
        exportClockProvider.overrideWithValue(() => DateTime(2026, 10, 22)),
      ],
    );
    final date = DateTime(2026, 8, 24);
    await exporting
        .read(checkInRepositoryProvider)
        .logCheckIn(date, CheckInStatus.partial);
    await exporting.read(pdfImportRepositoryProvider).commitDailyTotals([
      ParsedDay(date: date, caloriesEaten: 1850, foodEntries: const []),
    ]);

    // The export's repository is the shared store itself, not a copy.
    expect(
      exporting.read(exportDailyMetricRepositoryProvider),
      same(exporting.read(dailyMetricRepositoryProvider)),
    );

    exporting.listen(dataExportControllerProvider, (_, _) {});
    await exporting
        .read(dataExportControllerProvider.notifier)
        .exportData(ExportFormat.csv);

    expect(shared.single.fileName, 'steady-export-2026-10-22.csv');
    expect(
      shared.single.contents.split('\r\n')[1],
      '2026-08-24,1850,,,,partial',
    );
  });

  test('data_export reads rows dated anywhere a DateTime can hold, from the '
      'real store', () async {
    final store = container.read(dailyMetricRepositoryProvider);
    final dates = [
      exportRangeStart,
      DateTime(-5, 6, 7),
      DateTime(1969, 12, 31),
      DateTime(2026, 8, 24),
      DateTime(10000),
      exportRangeEnd,
    ];
    for (final date in dates) {
      await store.upsert(date, steps: 1);
    }

    final result = await readExportBundle(
      store,
      exportedAt: DateTime(2026, 10, 22),
    );

    final bundle = (result as Ok<ExportBundle>).value;
    expect(bundle.dailyMetrics.map((m) => m.date), dates);
  });

  test('with the SwiftData store, imports survive into a fresh container '
      '(an app restart)', () async {
    // A Dart stand-in for the native plugin; its rows outlive containers.
    final native = FakeDailyMetricsStore()..install();
    addTearDown(native.uninstall);
    ProviderContainer launch() => ProviderContainer.test(
      overrides: [
        ...appProviderOverrides,
        dailyMetricStoreProvider.overrideWithValue(DailyMetricStore.swiftData),
      ],
    );

    final date = DateTime(2026, 8, 24);
    final first = launch();
    expect(
      first.read(dailyMetricRepositoryProvider),
      isA<SwiftDataDailyMetricRepository>(),
    );
    await first.read(pdfImportRepositoryProvider).commitDailyTotals([
      ParsedDay(date: date, caloriesEaten: 1850, foodEntries: const []),
    ]);
    await first
        .read(checkInRepositoryProvider)
        .logCheckIn(date, CheckInStatus.partial);

    final result = await launch()
        .read(metricsRepositoryProvider)
        .getRange(date, date);
    final rows = (result as Ok<List<DailyMetric>>).value;

    expect(rows.single.caloriesEaten, 1850);
    expect(rows.single.loggingStatus, LoggingStatus.partial);
  });

  test('by default the shared store is in memory (no native plugin)', () {
    expect(
      container.read(dailyMetricRepositoryProvider),
      isA<InMemoryDailyMetricRepository>(),
    );
  });

  test('with the SwiftData store, data_export reads it, including days '
      'written before an app restart', () async {
    // A Dart stand-in for the native plugin; its rows outlive containers.
    final native = FakeDailyMetricsStore()..install();
    addTearDown(native.uninstall);
    final shared = <ExportFile>[];
    ProviderContainer launch() => ProviderContainer.test(
      overrides: [
        ...appProviderOverrides,
        dailyMetricStoreProvider.overrideWithValue(DailyMetricStore.swiftData),
        exportFileSharerProvider.overrideWithValue((
          exported, {
          sharePositionOrigin,
        }) async {
          shared.add(exported);
          return const Ok(ExportShareOutcome.shared);
        }),
        exportClockProvider.overrideWithValue(() => DateTime(2026, 10, 22)),
      ],
    );

    final date = DateTime(2026, 8, 24);
    await launch().read(pdfImportRepositoryProvider).commitDailyTotals([
      ParsedDay(date: date, caloriesEaten: 1850, foodEntries: const []),
    ]);

    // A fresh container: the export can only see the day through the store.
    final exporting = launch();
    expect(
      exporting.read(exportDailyMetricRepositoryProvider),
      allOf(
        isA<SwiftDataDailyMetricRepository>(),
        same(exporting.read(dailyMetricRepositoryProvider)),
      ),
    );
    exporting.listen(dataExportControllerProvider, (_, _) {});
    await exporting
        .read(dataExportControllerProvider.notifier)
        .exportData(ExportFormat.csv);

    expect(shared.single.contents.split('\r\n')[1], '2026-08-24,1850,,,,');
  });

  test('the share card reads the week from the shared store', () async {
    final day = DateTime(2026, 8, 24);
    await container
        .read(checkInRepositoryProvider)
        .logCheckIn(day, CheckInStatus.partial);
    await container.read(pdfImportRepositoryProvider).commitDailyTotals([
      ParsedDay(date: day, caloriesEaten: 1850, foodEntries: const []),
    ]);

    final weekStart = weekCardStart(day);
    final sub = container.listen(
      weekCardControllerProvider(weekStart),
      (_, _) {},
    );
    addTearDown(sub.close);
    final week = await container.read(
      weekCardControllerProvider(weekStart).future,
    );

    final shown = week.days.singleWhere((d) => d.date == day);
    expect(shown.status, LoggingStatus.partial);
    expect(shown.caloriesEaten, 1850);
    expect(
      container.read(weekMetricsRepositoryProvider),
      same(container.read(metricsRepositoryProvider)),
    );
  });

  test('without appProviderOverrides, feature repositories are unbound', () {
    final bare = ProviderContainer.test();
    // Riverpod 3 wraps an error thrown while building a provider.
    final unbound = throwsA(
      isA<ProviderException>().having(
        (e) => e.exception,
        'exception',
        isA<UnimplementedError>(),
      ),
    );

    expect(() => bare.read(checkInRepositoryProvider), unbound);
    expect(() => bare.read(metricsRepositoryProvider), unbound);
    expect(() => bare.read(pdfImportRepositoryProvider), unbound);
  });

  test('accountStatusRepositoryProvider is bound by appProviderOverrides', () {
    expect(
      container.read(accountStatusRepositoryProvider),
      isA<AccountStatusRepository>(),
    );

    // And it's genuinely the override doing it: unbound without the list.
    final bare = ProviderContainer.test();
    expect(
      () => bare.read(accountStatusRepositoryProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<UnimplementedError>(),
        ),
      ),
    );
  });
}
