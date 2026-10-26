import 'dart:async';
import 'dart:convert';

import 'package:coach_domain/coach_domain.dart';
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
  late ProviderSubscription<_State> subscription;

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
    subscription = container.listen<_State>(
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
      expect(file.contents, contains('"schemaVersion": 2'));
      // No coach bound (the Mac): no coach sessions key at all.
      final json = jsonDecode(file.contents) as Map<String, Object?>;
      expect(json.containsKey('coachSessions'), isFalse);
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

    test('an empty store is data(receipt) with dayCount 0, and shares a '
        'header-only file', () async {
      states.clear();
      repository.onGetRange = () => const Ok([]);

      await notifier().exportData(ExportFormat.csv);

      expect(states, [
        _isLoading(),
        _isData(
          const ExportReceipt(
            format: ExportFormat.csv,
            fileName: 'steady-export-2026-10-22.csv',
            dayCount: 0,
            outcome: ExportShareOutcome.shared,
          ),
        ),
      ]);
      expect(
        sharer.sharedFiles.single,
        ExportBundle(
          exportedAt: now,
          dailyMetrics: const [],
        ).toFile(ExportFormat.csv),
      );
      // Header only: no day rows.
      expect(
        sharer.sharedFiles.single.contents,
        '${ExportBundle.columns.join(',')}\r\n',
      );
    });

    test('disposed while the read is in flight: the share sheet never '
        'opens', () async {
      final read = Completer<Result<List<DailyMetric>>>();
      repository.onGetRange = () => read.future;

      final pending = notifier().exportData(ExportFormat.csv);
      await pumpEventQueue();
      expect(repository.getRangeCalls, hasLength(1));

      // The user leaves Settings: the screen stops listening, and the
      // auto-dispose controller is disposed.
      subscription.close();
      await pumpEventQueue();
      expect(container.exists(dataExportControllerProvider), isFalse);

      read.complete(Ok(rows));
      await pending;

      expect(sharer.sharedFiles, isEmpty);
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

  group('with the coach (iPhone)', () {
    final sessionStart = DateTime(2026, 10, 23, 19);
    final session = CoachSession(
      id: 'w1',
      kind: CoachSessionKind.weekly,
      startedAt: sessionStart,
      summary: 'Steps were steady this week.',
      messages: [
        CoachMessage(
          role: CoachMessageRole.user,
          text: 'A private thing I said',
          at: sessionStart,
        ),
      ],
    );
    late FakeCoachRepository coach;
    late ProviderContainer withCoach;

    setUp(() {
      coach = FakeCoachRepository(onList: () => Ok([session]));
      withCoach = ProviderContainer.test(
        overrides: [
          exportDailyMetricRepositoryProvider.overrideWithValue(repository),
          exportCoachRepositoryProvider.overrideWithValue(coach),
          exportFileSharerProvider.overrideWithValue(sharer.call),
          exportClockProvider.overrideWithValue(() => now),
        ],
      )..listen(dataExportControllerProvider, (_, _) {});
    });

    Future<void> export(ExportFormat format) => withCoach
        .read(dataExportControllerProvider.notifier)
        .exportData(format);

    test("the JSON has each session's date, kind and summary, not the "
        'transcript', () async {
      await export(ExportFormat.json);

      final contents = sharer.sharedFiles.single.contents;
      final json = jsonDecode(contents) as Map<String, Object?>;
      expect(json['coachSessions'], [
        {
          'date': '2026-10-23',
          'kind': 'weekly',
          'summary': 'Steps were steady this week.',
        },
      ]);
      expect(contents, isNot(contains('A private thing I said')));
      expect(coach.listCalls, 1);
    });

    test('the CSV stays one row per day, with no coach content', () async {
      await export(ExportFormat.csv);

      final contents = sharer.sharedFiles.single.contents;
      // A header, one line per day, and the empty string after the last
      // CRLF.
      expect(contents.split('\r\n'), hasLength(rows.length + 2));
      expect(contents, isNot(contains('Steps were steady')));
    });

    test(
      'the receipt says nothing was left out when the coach reads',
      () async {
        await export(ExportFormat.json);

        expect(
          withCoach
              .read(dataExportControllerProvider)
              .value
              ?.coachHistoryLeftOut,
          isNull,
        );
      },
    );

    test('no sessions yet: coachSessions is [] and nothing was left '
        'out', () async {
      coach.onList = () => const Ok([]);
      await export(ExportFormat.json);

      final json = jsonDecode(
        sharer.sharedFiles.single.contents,
      ) as Map<String, Object?>;
      expect(json['coachSessions'], isEmpty);
      expect(
        withCoach.read(dataExportControllerProvider).value?.coachHistoryLeftOut,
        isNull,
      );
    });

    group('a coach read Err', () {
      setUp(() {
        coach.onList = () =>
            const Err(CoachHistoryUnreadableFailure('unreadable'));
      });

      test('still exports the JSON, with every day and coachSessions null, '
          'and the receipt says the coach was left out', () async {
        await export(ExportFormat.json);

        final json = jsonDecode(
          sharer.sharedFiles.single.contents,
        ) as Map<String, Object?>;
        expect(json['dailyMetrics'], hasLength(rows.length));
        expect(json.containsKey('coachSessions'), isTrue);
        expect(json['coachSessions'], isNull);
        expect(
          withCoach.read(dataExportControllerProvider),
          _isData(
            const ExportReceipt(
              format: ExportFormat.json,
              fileName: 'steady-export-2026-10-22.json',
              dayCount: 2,
              outcome: ExportShareOutcome.shared,
              coachHistoryLeftOut: CoachHistoryLeftOut.unreadable,
            ),
          ),
        );
      });

      test(
        'a storage failure is left out as readFailed, not unreadable',
        () async {
          coach.onList = () => const Err(CoachHistoryStorageFailure('locked'));
          await export(ExportFormat.json);

          expect(sharer.sharedFiles, hasLength(1));
          expect(
            withCoach
                .read(dataExportControllerProvider)
                .value
                ?.coachHistoryLeftOut,
            CoachHistoryLeftOut.readFailed,
          );
        },
      );

      test('leaves the CSV as it always is, with nothing left out', () async {
        await export(ExportFormat.csv);

        expect(
          sharer.sharedFiles.single.contents,
          ExportBundle(
            exportedAt: now,
            dailyMetrics: rows,
          ).toFile(ExportFormat.csv).contents,
        );
        expect(
          withCoach
              .read(dataExportControllerProvider)
              .value
              ?.coachHistoryLeftOut,
          isNull,
        );
      });
    });
  });
}
