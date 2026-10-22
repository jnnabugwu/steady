import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_data/testing/daily_metric_repository_contract.dart';
import 'package:daily_metrics_data/testing/fake_daily_metrics_store.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeDailyMetricsStore native;

  setUp(() {
    native = FakeDailyMetricsStore()..install();
  });

  tearDown(() => native.uninstall());

  // A fresh fake store per contract test: setUp runs before each one.
  runDailyMetricRepositoryContractTests(SwiftDataDailyMetricRepository.new);

  group('SwiftDataDailyMetricRepository channel', () {
    final day = DateTime(2026, 8, 24);

    test('sends full rows keyed by yyyy-MM-dd', () async {
      await SwiftDataDailyMetricRepository().upsert(
        DateTime(2026, 8, 24, 21, 45),
        steps: 8000,
      );

      expect(native.rows, {
        '2026-08-24': {
          'date': '2026-08-24',
          'caloriesEaten': null,
          'caloriesBurnedActive': null,
          'caloriesBurnedBasal': null,
          'steps': 8000,
          'loggingStatus': null,
        },
      });
    });

    test('a fresh instance reads back what an earlier one wrote', () async {
      await SwiftDataDailyMetricRepository().upsert(
        day,
        caloriesEaten: 0,
        loggingStatus: LoggingStatus.partial,
      );

      final row = await SwiftDataDailyMetricRepository().getByDate(day);

      expect(
        (row as Ok<DailyMetric?>).value,
        DailyMetric(
          date: day,
          caloriesEaten: 0,
          loggingStatus: LoggingStatus.partial,
        ),
      );
    });

    test('clearing every field removes the row natively', () async {
      final repo = SwiftDataDailyMetricRepository();
      await repo.upsert(day, steps: 8000);

      await repo.clearFields(day, {DailyMetricField.steps});

      expect(native.rows, isEmpty);
      expect(native.calls.last.method, 'remove');
    });

    test('concurrent upserts to one day are serialized, none lost', () async {
      final repo = SwiftDataDailyMetricRepository();
      await Future.wait([
        repo.upsert(day, caloriesEaten: 2000),
        repo.upsert(day, steps: 8000),
        repo.upsert(day, loggingStatus: LoggingStatus.logged),
      ]);

      final row = (await repo.getByDate(day) as Ok<DailyMetric?>).value;
      expect(
        row,
        DailyMetric(
          date: day,
          caloriesEaten: 2000,
          steps: 8000,
          loggingStatus: LoggingStatus.logged,
        ),
      );
    });

    test('rejects a year the yyyy-MM-dd key cannot hold', () async {
      final result = await SwiftDataDailyMetricRepository().upsert(
        DateTime(10000),
        steps: 1,
      );

      expect((result as Err).failure, isA<ValidationFailure>());
      expect(native.calls, isEmpty);
    });
  });

  group('SwiftDataDailyMetricRepository failure mapping', () {
    final day = DateTime(2026, 8, 24);

    test('PlatformException becomes PlatformChannelFailure with its code', () {
      native.failNextWithCode = 'save_failed';
      return expectLater(
        SwiftDataDailyMetricRepository().upsert(day, steps: 1),
        completion(
          isA<Err<DailyMetric>>().having(
            (e) => e.failure,
            'failure',
            isA<PlatformChannelFailure>().having(
              (f) => f.code,
              'code',
              'save_failed',
            ),
          ),
        ),
      );
    });

    for (final call in <String, Future<Result<Object?>> Function()>{
      'getByDate': () => SwiftDataDailyMetricRepository().getByDate(day),
      'getRange': () => SwiftDataDailyMetricRepository().getRange(day, day),
      'upsert': () => SwiftDataDailyMetricRepository().upsert(day, steps: 1),
      'clearFields': () => SwiftDataDailyMetricRepository().clearFields(day, {
        DailyMetricField.steps,
      }),
      'delete': () => SwiftDataDailyMetricRepository().delete(day),
    }.entries) {
      test('${call.key}: no plugin becomes PlatformChannelFailure', () async {
        native.uninstall();

        final result = await call.value();

        expect(
          (result as Err).failure,
          isA<PlatformChannelFailure>().having(
            (f) => f.code,
            'code',
            'missing_plugin',
          ),
        );
      });

      test('${call.key}: a platform error becomes a Failure', () async {
        native.failNextWithCode = 'fetch_failed';

        final result = await call.value();

        expect((result as Err).failure, isA<PlatformChannelFailure>());
      });
    }

    test('a non-map row becomes UnknownFailure', () async {
      native.replyOverride = (_) => 'not a row';

      final result = await SwiftDataDailyMetricRepository().getByDate(day);

      expect((result as Err).failure, isA<UnknownFailure>());
    });

    test('an unknown loggingStatus becomes UnknownFailure', () async {
      native.replyOverride = (_) => {
        'date': '2026-08-24',
        'loggingStatus': 'abandoned',
      };

      final result = await SwiftDataDailyMetricRepository().getByDate(day);

      expect((result as Err).failure, isA<UnknownFailure>());
    });

    test('a non-list range reply becomes UnknownFailure', () async {
      native.replyOverride = (_) => {'date': '2026-08-24'};

      final result = await SwiftDataDailyMetricRepository().getRange(day, day);

      expect((result as Err).failure, isA<UnknownFailure>());
    });

    test('a bad date in a range row becomes UnknownFailure', () async {
      native.replyOverride = (_) => [
        {'date': '2026-02-31'},
      ];

      final result = await SwiftDataDailyMetricRepository().getRange(day, day);

      expect((result as Err).failure, isA<UnknownFailure>());
    });

    test('a failure does not wedge the queue', () async {
      final repo = SwiftDataDailyMetricRepository();
      native.failNextWithCode = 'save_failed';
      await repo.upsert(day, steps: 1);

      final result = await repo.upsert(day, steps: 2);

      expect((result as Ok<DailyMetric>).value.steps, 2);
    });
  });
}
