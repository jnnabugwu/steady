import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/providers.dart';

/// Guards the DI wiring in `lib/providers.dart`, built from the **real**
/// [appProviderOverrides] list rather than hand-picked fakes, so a broken
/// override fails here even when every feature's own unit tests pass.
void main() {
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
}
