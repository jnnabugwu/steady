import 'dart:typed_data';
import 'dart:ui' show Rect;

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_metrics_repository.dart';

void main() {
  final weekStart = DateTime(2026, 8, 21);
  late FakeMetricsRepository repository;
  late RecordingSharer sharer;
  late ProviderContainer container;

  setUp(() {
    repository = FakeMetricsRepository();
    sharer = RecordingSharer();
    container = ProviderContainer.test(
      overrides: [
        weekMetricsRepositoryProvider.overrideWithValue(repository),
        weekCardSharerProvider.overrideWithValue(sharer.call),
      ],
    );
  });

  // Keeps the auto-dispose family alive for the rest of the test, the way
  // the share dialog's `ref.watch` does.
  void listenWeek() {
    final sub = container.listen(
      weekCardControllerProvider(weekStart),
      (_, _) {},
    );
    addTearDown(sub.close);
  }

  group('WeekCardController', () {
    test('reads the whole week with one range read', () async {
      repository.onGetRange = (_, _) => Ok([
        DailyMetric(
          date: DateTime(2026, 8, 24),
          loggingStatus: LoggingStatus.logged,
        ),
      ]);
      listenWeek();

      final data = await container.read(
        weekCardControllerProvider(weekStart).future,
      );

      expect(repository.getRangeCalls, [
        (DateTime(2026, 8, 21), DateTime(2026, 8, 27)),
      ]);
      expect(data.days, hasLength(7));
      expect(data.days[3].status, LoggingStatus.logged);
    });

    test(
      'surfaces a repository Failure as AsyncError, not empty data',
      () async {
        repository.onGetRange = (_, _) =>
            const Err(PlatformChannelFailure('store down'));
        listenWeek();

        await expectLater(
          container.read(weekCardControllerProvider(weekStart).future),
          throwsA(const PlatformChannelFailure('store down')),
        );

        final state = container.read(weekCardControllerProvider(weekStart));
        expect(state, isA<AsyncError<WeekCardData>>());
        expect(state.error, const PlatformChannelFailure('store down'));
        // Not retried: a Failure is already a final answer.
        expect(repository.getRangeCalls, hasLength(1));
      },
    );

    test(
      'shareWeek hands the PNG to the seam with a dated file name',
      () async {
        listenWeek();
        await container.read(weekCardControllerProvider(weekStart).future);
        final png = Uint8List.fromList([1, 2, 3]);
        const origin = Rect.fromLTWH(10, 20, 30, 40);

        final result = await container
            .read(weekCardControllerProvider(weekStart).notifier)
            .shareWeek(png, origin: origin);

        expect(result, isA<Ok<Unit>>());
        expect(sharer.calls, hasLength(1));
        expect(sharer.calls.single.png, png);
        expect(sharer.calls.single.fileName, 'steady-week-2026-08-21.png');
        expect(sharer.calls.single.origin, origin);
      },
    );

    test('shareWeek returns the seam Failure', () async {
      sharer.result = const Err(UnknownFailure('no sheet'));
      listenWeek();
      await container.read(weekCardControllerProvider(weekStart).future);

      final result = await container
          .read(weekCardControllerProvider(weekStart).notifier)
          .shareWeek(Uint8List(0));

      expect(result, isA<Err<Unit>>());
      expect((result as Err<Unit>).failure, const UnknownFailure('no sheet'));
    });

    test('shareWeek refuses to share a week that failed to load', () async {
      repository.onGetRange = (_, _) => const Err(UnknownFailure('nope'));
      listenWeek();
      await expectLater(
        container.read(weekCardControllerProvider(weekStart).future),
        throwsA(isA<Failure>()),
      );

      final result = await container
          .read(weekCardControllerProvider(weekStart).notifier)
          .shareWeek(Uint8List(0));

      expect(result, isA<Err<Unit>>());
      expect((result as Err<Unit>).failure, isA<ValidationFailure>());
      expect(sharer.calls, isEmpty);
    });

    test('is auto-dispose: freed once nothing listens', () async {
      final sub = container.listen(
        weekCardControllerProvider(weekStart),
        (_, _) {},
      );
      await container.read(weekCardControllerProvider(weekStart).future);
      expect(container.exists(weekCardControllerProvider(weekStart)), isTrue);

      sub.close();
      await container.pump();

      expect(container.exists(weekCardControllerProvider(weekStart)), isFalse);
    });
  });
}
