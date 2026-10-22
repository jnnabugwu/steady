import 'dart:async';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fakes.dart';

typedef _State = AsyncValue<ExportReceipt?>;

Matcher _isLoading() => isA<AsyncLoading<ExportReceipt?>>();

Matcher _isData(Object? value) =>
    isA<AsyncData<ExportReceipt?>>().having((s) => s.value, 'value', value);

Matcher _isError(Matcher failure) =>
    isA<AsyncError<ExportReceipt?>>().having((s) => s.error, 'error', failure);

void main() {
  final now = DateTime(2026, 10, 22, 9, 30);
  final rows = [
    DailyMetric(
      date: DateTime(2026, 10, 19),
      caloriesEaten: 1850,
      loggingStatus: LoggingStatus.logged,
    ),
    DailyMetric(date: DateTime(2026, 10, 20), steps: 0),
  ];

  late FakeDailyMetricRepository repository;
  late FakeExportSharer sharer;
  late ProviderContainer container;
  late List<_State> states;

  setUp(() {
    repository = FakeDailyMetricRepository(onGetRange: () => Ok(rows));
    sharer = FakeExportSharer();
    container = ProviderContainer.test(
      overrides: [
        exportDailyMetricRepositoryProvider.overrideWithValue(repository),
        exportFileSharerProvider.overrideWithValue(sharer.call),
        exportClockProvider.overrideWithValue(() => now),
      ],
    );
    states = [];
    container.listen<_State>(
      dataExportControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  });

  DataExportController notifier() =>
      container.read(dataExportControllerProvider.notifier);

  test('starts idle, as data(null)', () {
    expect(states, [_isData(null)]);
  });

  group('exportData', () {
    test('goes loading -> data(receipt) and shares the dated file', () async {
      states.clear();
      final share = Completer<Result<ExportShareOutcome>>();
      sharer.onShare = (_) => share.future;
      const origin = Rect.fromLTWH(10, 20, 100, 40);

      final pending = notifier().exportData(
        ExportFormat.csv,
        sharePositionOrigin: origin,
      );
      expect(states, [_isLoading()]);

      share.complete(const Ok(ExportShareOutcome.shared));
      await pending;

      expect(states, [
        _isLoading(),
        _isData(
          const ExportReceipt(
            format: ExportFormat.csv,
            fileName: 'steady-export-2026-10-22.csv',
            dayCount: 2,
            outcome: ExportShareOutcome.shared,
          ),
        ),
      ]);
      expect(repository.getRangeCalls, [(exportRangeStart, exportRangeEnd)]);
      expect(sharer.origins, [origin]);
      expect(
        sharer.sharedFiles.single,
        ExportBundle(
          exportedAt: now,
          dailyMetrics: rows,
        ).toFile(ExportFormat.csv),
      );
    });

    test('json shares the JSON file', () async {
      await notifier().exportData(ExportFormat.json);

      final file = sharer.sharedFiles.single;
      expect(file.fileName, 'steady-export-2026-10-22.json');
      expect(file.mimeType, 'application/json');
      expect(file.contents, contains('"schemaVersion": 1'));
    });

    test('a dismissed share sheet is data(dismissed), not an error', () async {
      sharer.onShare = (_) => const Ok(ExportShareOutcome.dismissed);

      await notifier().exportData(ExportFormat.csv);

      expect(
        states.last,
        isA<AsyncData<ExportReceipt?>>().having(
          (s) => s.value?.outcome,
          'outcome',
          ExportShareOutcome.dismissed,
        ),
      );
    });

    test('a repository Err goes loading -> error with that Failure, and '
        'nothing is shared', () async {
      states.clear();
      const failure = PlatformChannelFailure('store down', code: 'E_IO');
      repository.onGetRange = () => const Err(failure);

      await notifier().exportData(ExportFormat.csv);

      expect(states, [_isLoading(), _isError(same(failure))]);
      expect(sharer.sharedFiles, isEmpty);
    });

    test('a share failure goes loading -> error(ExportShareFailure)', () async {
      states.clear();
      sharer.onShare = (_) =>
          const Err(ExportShareFailure('Could not open the share sheet'));

      await notifier().exportData(ExportFormat.json);

      expect(states, [_isLoading(), _isError(isA<ExportShareFailure>())]);
    });

    test('a second export while one is in flight is ignored', () async {
      states.clear();
      final share = Completer<Result<ExportShareOutcome>>();
      sharer.onShare = (_) => share.future;

      final first = notifier().exportData(ExportFormat.csv);
      final second = notifier().exportData(ExportFormat.json);
      await second;
      // Let the first export's read finish and reach the share sheet.
      await pumpEventQueue();
      expect(states, [_isLoading()]);

      share.complete(const Ok(ExportShareOutcome.shared));
      await first;

      expect(states, [_isLoading(), isA<AsyncData<ExportReceipt?>>()]);
      expect(repository.getRangeCalls, hasLength(1));
      expect(sharer.sharedFiles.map((f) => f.fileName), [
        'steady-export-2026-10-22.csv',
      ]);
    });

    test('can export again after a failure', () async {
      repository.onGetRange = () => const Err(UnknownFailure('boom'));
      await notifier().exportData(ExportFormat.csv);
      expect(states.last, isA<AsyncError<ExportReceipt?>>());

      repository.onGetRange = () => Ok(rows);
      await notifier().exportData(ExportFormat.csv);

      expect(states.last, isA<AsyncData<ExportReceipt?>>());
      expect(sharer.sharedFiles, hasLength(1));
    });
  });
}
