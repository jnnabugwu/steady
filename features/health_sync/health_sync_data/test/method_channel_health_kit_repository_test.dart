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

    final unsupportedYears = <String, (DateTime, DateTime)>{
      'a start before year 0': (DateTime(-1, 12, 31), DateTime(2026, 10, 4)),
      'an end after year 9999': (DateTime(2026, 10, 4), DateTime(10000)),
    };
    for (final MapEntry(key: name, value: (start, end))
        in unsupportedYears.entries) {
      test('$name is a ValidationFailure, without calling native', () async {
        answer((_) => <Object?>[]);
        final failure = errFailure(await repository.dailyTotals(start, end));
        expect(failure, isA<ValidationFailure>());
        expect(calls, isEmpty);
      });
    }

    test('a UTC bound is sent as its local calendar day', () async {
      final utc = utcWithDifferentLocalDay();
      if (utc == null) {
        markTestSkipped('Local time is UTC here: no differing day to test');
        return;
      }
      final local = utc.toLocal();
      final expected = formatHealthDate(
        DateTime(local.year, local.month, local.day),
      );
      expect(
        expected,
        isNot(
          '${utc.year.toString().padLeft(4, '0')}-'
          '${utc.month.toString().padLeft(2, '0')}-'
          '${utc.day.toString().padLeft(2, '0')}',
        ),
      );
      answer((_) => <Object?>[]);
      okValue(await repository.dailyTotals(utc, utc));
      expect(calls.single.arguments, {'start': expected, 'end': expected});
    });

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
      'a zero weight': [
        {'date': '2026-10-21', 'weightKg': 0},
      ],
      'a string weight': [
        {'date': '2026-10-21', 'weightKg': '80.2'},
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

  group('weight', () {
    test('dailyTotals decodes weightKg as a double, int or null', () async {
      answer(
        (_) => [
          {'date': '2026-10-21', 'weightKg': 81.37},
          {'date': '2026-10-22', 'weightKg': 81},
          {'date': '2026-10-23', 'weightKg': null},
        ],
      );
      final days = okValue(
        await repository.dailyTotals(
          DateTime(2026, 10, 21),
          DateTime(2026, 10, 23),
        ),
      );
      expect(days.map((d) => d.weightKg), [81.37, 81.0, null]);
      expect(days.first.hasActivity, isFalse);
      expect(days.first.isEmpty, isFalse);
    });

    const units = {
      'kg': WeightUnit.kilograms,
      'lb': WeightUnit.pounds,
      'st': WeightUnit.stones,
      'somethingNew': WeightUnit.kilograms,
    };
    for (final MapEntry(key: wire, value: unit) in units.entries) {
      test('preferredWeightUnit maps "$wire" to $unit', () async {
        answer((_) => wire);
        expect(okValue(await repository.preferredWeightUnit()), unit);
        expect(calls.single.method, 'preferredWeightUnit');
        expect(calls.single.arguments, isNull);
      });
    }

    test('preferredWeightUnit before the permission sheet is a '
        'PlatformChannelFailure', () async {
      throwPlatform(HealthKitChannel.authorizationNotDeterminedCode);
      final failure = errFailure(await repository.preferredWeightUnit());
      expect(
        (failure as PlatformChannelFailure).code,
        'authorizationNotDetermined',
      );
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
      expect(formatHealthDate(DateTime(7, 1, 2)), '0007-01-02');
      expect(parseHealthDate('2026-03-04'), DateTime(2026, 3, 4));
    });

    test('format rejects years outside 0000 to 9999', () {
      expect(formatHealthDate(DateTime(0)), '0000-01-01');
      expect(formatHealthDate(DateTime(9999, 12, 31)), '9999-12-31');
      expect(() => formatHealthDate(DateTime(-1)), throwsRangeError);
      expect(() => formatHealthDate(DateTime(10000)), throwsRangeError);
    });

    test('format uses the local calendar day of a UTC DateTime', () {
      final utc = utcWithDifferentLocalDay();
      if (utc == null) {
        markTestSkipped('Local time is UTC here: no differing day to test');
        return;
      }
      final local = utc.toLocal();
      expect(local.day, isNot(utc.day));
      expect(formatHealthDate(utc), formatHealthDate(local));
    });
  });
}

/// A UTC instant whose local calendar day differs from its UTC one in the
/// test's time zone (CI runs with `TZ=America/Chicago`), or `null` when
/// local time is UTC. 01:00 UTC is the previous local day west of UTC;
/// 23:00 UTC is the next local day east of it.
DateTime? utcWithDifferentLocalDay() {
  for (final utc in [
    DateTime.utc(2026, 10, 22, 1),
    DateTime.utc(2026, 10, 21, 23),
  ]) {
    if (utc.toLocal().day != utc.day) return utc;
  }
  return null;
}
