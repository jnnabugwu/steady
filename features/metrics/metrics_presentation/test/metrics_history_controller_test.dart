import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';

import 'helpers/fake_metrics_repository.dart';

typedef _State = AsyncValue<List<DailyMetric>>;

void main() {
  late FakeMetricsRepository repository;
  late ProviderContainer container;
  late List<_State> states;

  setUp(() {
    repository = FakeMetricsRepository();
    container = ProviderContainer.test(
      overrides: [metricsRepositoryProvider.overrideWithValue(repository)],
    );
    states = [];
  });

  void listen() {
    container.listen<_State>(
      metricsHistoryControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  }

  group('MetricsHistoryController.build', () {
    test('reads 2000-01-01 through today and sorts newest first', () async {
      final oldest = DailyMetric(date: DateTime(2026, 8, 14));
      final middle = DailyMetric(
        date: DateTime(2026, 8, 15),
        caloriesEaten: 1800,
      );
      final newest = DailyMetric(date: DateTime(2026, 8, 16));
      repository.onGetRange = (_, _) => Ok([middle, oldest, newest]);
      listen();

      final days = await container.read(
        metricsHistoryControllerProvider.future,
      );

      expect(days, [newest, middle, oldest]);
      expect(states.first, isA<AsyncLoading<List<DailyMetric>>>());
      expect(states.last, isA<AsyncData<List<DailyMetric>>>());

      final now = DateTime.now();
      expect(repository.getRangeCalls, [
        (DateTime(2000), DateTime(now.year, now.month, now.day)),
      ]);
    });

    test(
      'goes loading -> error carrying the Failure, without retrying',
      () async {
        const failure = PlatformChannelFailure('channel down', code: 'E_IO');
        repository.onGetRange = (_, _) => const Err(failure);
        listen();

        await expectLater(
          container.read(metricsHistoryControllerProvider.future),
          throwsA(failure),
        );

        expect(states, [
          isA<AsyncLoading<List<DailyMetric>>>(),
          isA<AsyncError<List<DailyMetric>>>().having(
            (s) => s.error,
            'error',
            isA<PlatformChannelFailure>().having((f) => f.code, 'code', 'E_IO'),
          ),
        ]);
        expect(repository.getRangeCalls, hasLength(1));
      },
    );

    test('invalidating re-reads the repository', () async {
      listen();
      await container.read(metricsHistoryControllerProvider.future);

      container.invalidate(metricsHistoryControllerProvider);
      await container.read(metricsHistoryControllerProvider.future);

      expect(repository.getRangeCalls, hasLength(2));
    });
  });
}
