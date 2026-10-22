import 'package:account_data/account_data.dart';
import 'package:account_domain/account_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A channel whose every call throws [error], for exceptions the mocked
/// messenger can't produce (anything other than a [PlatformException]).
class _ThrowingChannel extends MethodChannel {
  const _ThrowingChannel(this.error) : super(AccountChannel.name);

  final Exception error;

  @override
  Future<T?> invokeMethod<T>(String method, [dynamic arguments]) async =>
      throw error;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(AccountChannel.name);
  late List<MethodCall> calls;
  late MethodChannelAccountStatusRepository repository;

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  void answer(Object? Function(MethodCall call) handler) {
    messenger().setMockMethodCallHandler(channel, (call) async {
      calls.add(call);
      return handler(call);
    });
  }

  setUp(() {
    calls = [];
    repository = MethodChannelAccountStatusRepository();
  });

  tearDown(() => messenger().setMockMethodCallHandler(channel, null));

  group('accountStatus', () {
    const expected = {
      'available': AccountStatus.available,
      'noAccount': AccountStatus.noAccount,
      'restricted': AccountStatus.restricted,
      'temporarilyUnavailable': AccountStatus.temporarilyUnavailable,
      'couldNotDetermine': AccountStatus.couldNotDetermine,
      'notConfigured': AccountStatus.notConfigured,
    };

    for (final MapEntry(key: wire, value: status) in expected.entries) {
      test('maps "$wire" to $status', () async {
        answer((_) => wire);

        final result = await repository.accountStatus();

        expect(result, isA<Ok<AccountStatus>>());
        expect((result as Ok<AccountStatus>).value, status);
        expect(calls.single.method, AccountChannel.accountStatusMethod);
      });
    }

    test('every AccountStatus has a wire string', () {
      expect(expected.values.toSet(), AccountStatus.values.toSet());
    });

    for (final unknown in <Object?>['signedOut', '', 'AVAILABLE', null, 3]) {
      test('maps unknown value ${unknown is String ? '"$unknown"' : unknown} '
          'to couldNotDetermine', () async {
        answer((_) => unknown);

        final result = await repository.accountStatus();

        expect(
          (result as Ok<AccountStatus>).value,
          AccountStatus.couldNotDetermine,
        );
      });
    }

    test('maps a PlatformException to a PlatformChannelFailure', () async {
      answer(
        (_) => throw PlatformException(code: 'E_CK', message: 'CloudKit down'),
      );

      final result = await repository.accountStatus();

      expect(result, isA<Err<AccountStatus>>());
      final failure = (result as Err<AccountStatus>).failure;
      expect(
        failure,
        isA<PlatformChannelFailure>()
            .having((f) => f.code, 'code', 'E_CK')
            .having((f) => f.message, 'message', 'CloudKit down')
            .having((f) => f.cause, 'cause', isA<PlatformException>()),
      );
    });

    test('a PlatformException without a message still gets one', () async {
      answer((_) => throw PlatformException(code: 'E_CK'));

      final failure =
          (await repository.accountStatus() as Err<AccountStatus>).failure;

      expect(failure.message, isNotEmpty);
    });

    test(
      'no native handler is a Failure, not a MissingPluginException',
      () async {
        final result = await repository.accountStatus();

        expect(
          (result as Err<AccountStatus>).failure,
          isA<PlatformChannelFailure>().having(
            (f) => f.code,
            'code',
            'missingPlugin',
          ),
        );
      },
    );
  });

  group('openAccountSettings', () {
    test('invokes the channel method and returns Ok', () async {
      answer((_) => null);

      final result = await repository.openAccountSettings();

      expect(result, isA<Ok<Unit>>());
      expect(calls.single.method, AccountChannel.openAccountSettingsMethod);
    });

    test('maps a PlatformException to a PlatformChannelFailure', () async {
      answer(
        (_) => throw PlatformException(code: 'E_OPEN', message: 'no pane'),
      );

      final result = await repository.openAccountSettings();

      expect(
        (result as Err<Unit>).failure,
        isA<PlatformChannelFailure>().having((f) => f.code, 'code', 'E_OPEN'),
      );
    });

    test('no native handler is a Failure', () async {
      final result = await repository.openAccountSettings();

      expect((result as Err<Unit>).failure, isA<PlatformChannelFailure>());
    });
  });

  group('any other Exception', () {
    const error = FormatException('bad payload');
    final throwing = MethodChannelAccountStatusRepository(
      channel: const _ThrowingChannel(error),
    );

    test('from accountStatus is an UnknownFailure', () async {
      final result = await throwing.accountStatus();

      expect(
        (result as Err<AccountStatus>).failure,
        isA<UnknownFailure>().having((f) => f.cause, 'cause', error),
      );
    });

    test('from openAccountSettings is an UnknownFailure', () async {
      final result = await throwing.openAccountSettings();

      expect(
        (result as Err<Unit>).failure,
        isA<UnknownFailure>().having((f) => f.cause, 'cause', error),
      );
    });
  });
}
