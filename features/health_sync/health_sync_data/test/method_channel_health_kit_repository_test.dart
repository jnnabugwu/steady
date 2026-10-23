import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(HealthKitChannel.name);
  late List<MethodCall> calls;
  late MethodChannelHealthKitRepository repository;

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) handler) {
    messenger().setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  void throwPlatform(String code, [String? message]) =>
      answer((_) => throw PlatformException(code: code, message: message));

  T okValue<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  Failure errFailure<T>(Result<T> result) => switch (result) {
    Ok(:final value) => fail('Expected Err, got Ok($value)'),
    Err(:final failure) => failure,
  };

  setUp(() {
    calls = [];
    repository = MethodChannelHealthKitRepository();
  });

  tearDown(() => messenger().setMockMethodCallHandler(channel, null));

  group('isAvailable', () {
    test('passes the bool through', () async {
      answer((_) => true);
      expect(okValue(await repository.isAvailable()), isTrue);
      answer((_) => false);
      expect(okValue(await repository.isAvailable()), isFalse);
      expect(calls.map((c) => c.method), everyElement('isAvailable'));
    });

    test('a non-bool reply is an UnknownFailure', () async {
      answer((_) => 'yes');
      expect(errFailure(await repository.isAvailable()), isA<UnknownFailure>());
    });
  });

  group('authorizationStatus', () {
    const expected = {
      'unavailable': HealthAuthorizationStatus.unavailable,
      'notDetermined': HealthAuthorizationStatus.notDetermined,
      'requested': HealthAuthorizationStatus.requested,
      'somethingNew': HealthAuthorizationStatus.notDetermined,
    };
    for (final MapEntry(key: wire, value: status) in expected.entries) {
      test('maps "$wire" to $status', () async {
        answer((_) => wire);
        expect(okValue(await repository.authorizationStatus()), status);
        expect(calls.single.method, 'authorizationStatus');
      });
    }
  });

  group('requestAuthorization', () {
    test('Ok(unit) when the native side completes', () async {
      answer((_) => null);
      expect(okValue(await repository.requestAuthorization()), unit);
      expect(calls.single.method, 'requestAuthorization');
      expect(calls.single.arguments, isNull);
    });

    test('a PlatformException is a PlatformChannelFailure', () async {
      throwPlatform('authorizationFailed', 'Not entitled');
      final failure = errFailure(await repository.requestAuthorization());
      expect(
        failure,
        const PlatformChannelFailure(
          'Not entitled',
          code: 'authorizationFailed',
        ),
      );
    });
  });

  group('dailyTotals', () {
    test('sends yyyy-MM-dd bounds and decodes one row per day', () async {
      answer(
        (_) => [
          {
            'date': '2026-10-21',
            'steps': 8123,
            'activeKcal': 412,
            'basalKcal': 1650,
          },
          {
            'date': '2026-10-22',
            'steps': null,
            'activeKcal': null,
            'basalKcal': null,
          },
          {
            'date': '2026-10-23',
            'steps': 10,
            'activeKcal': 3.6,
            'basalKcal': null,
          },
        ],
      );

      final days = okValue(
        await repository.dailyTotals(
          DateTime(2026, 10, 21, 18, 30),
          DateTime(2026, 10, 23),
        ),
      );

      expect(calls.single.method, 'dailyTotals');
      expect(calls.single.arguments, {
        'start': '2026-10-21',
        'end': '2026-10-23',
      });
      expect(days, [
        HealthDayTotals(
          date: DateTime(2026, 10, 21),
          steps: 8123,
          caloriesBurnedActive: 412,
          caloriesBurnedBasal: 1650,
        ),
        HealthDayTotals(date: DateTime(2026, 10, 22)),
        HealthDayTotals(
          date: DateTime(2026, 10, 23),
          steps: 10,
          caloriesBurnedActive: 4,
        ),
      ]);
      expect(days[1].isEmpty, isTrue);
    });

    test(
      'start after end is a ValidationFailure, without calling native',
      () async {
        answer((_) => <Object?>[]);
        final failure = errFailure(
          await repository.dailyTotals(
            DateTime(2026, 10, 5),
            DateTime(2026, 10, 4),
          ),
        );
        expect(failure, isA<ValidationFailure>());
        expect(calls, isEmpty);
      },
    );

    final malformed = <String, Object?>{
      'not a list': {'date': '2026-10-21'},
      'a row that is not a map': ['2026-10-21'],
      'a bad date': [
        {'date': '21/10/2026', 'steps': 1},
      ],
      'an impossible date': [
        {'date': '2026-02-30', 'steps': 1},
      ],
      'a negative count': [
        {'date': '2026-10-21', 'steps': -1},
      ],
      'a string count': [
        {'date': '2026-10-21', 'steps': '12'},
      ],
    };
    for (final MapEntry(key: name, value: reply) in malformed.entries) {
      test('$name is an UnknownFailure', () async {
        answer((_) => reply);
        final failure = errFailure(
          await repository.dailyTotals(
            DateTime(2026, 10, 21),
            DateTime(2026, 10, 21),
          ),
        );
        expect(failure, isA<UnknownFailure>());
      });
    }

    test('the native unavailable error is a PlatformChannelFailure', () async {
      throwPlatform(HealthKitChannel.unavailableCode, 'Health is unavailable');
      final failure = errFailure(
        await repository.dailyTotals(
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 21),
        ),
      );
      expect(failure, isA<PlatformChannelFailure>());
      expect((failure as PlatformChannelFailure).code, 'unavailable');
    });
  });

  test('no native handler (macOS) is a PlatformChannelFailure', () async {
    // No mock handler: the channel throws MissingPluginException.
    final failure = errFailure(await repository.isAvailable());
    expect(failure, isA<PlatformChannelFailure>());
    expect((failure as PlatformChannelFailure).code, 'missingPlugin');
  });

  group('wire dates', () {
    test('format pads and parse round-trips to local midnight', () {
      expect(formatHealthDate(DateTime(2026, 3, 4, 23, 59)), '2026-03-04');
      expect(parseHealthDate('2026-03-04'), DateTime(2026, 3, 4));
    });
  });
}
