import 'dart:async';

import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_account_status_repository.dart';

typedef _State = AsyncValue<AccountStatus>;

Matcher _isLoading() => isA<AsyncLoading<AccountStatus>>();

Matcher _isData(AccountStatus value) =>
    isA<AsyncData<AccountStatus>>().having((s) => s.value, 'value', value);

Matcher _isError(Matcher failure) =>
    isA<AsyncError<AccountStatus>>().having((s) => s.error, 'error', failure);

void main() {
  late FakeAccountStatusRepository repository;
  late ProviderContainer container;
  late List<_State> states;

  setUp(() {
    repository = FakeAccountStatusRepository();
    container = ProviderContainer.test(
      overrides: [
        accountStatusRepositoryProvider.overrideWithValue(repository),
      ],
    );
    states = [];
  });

  void listen() {
    container.listen<_State>(
      accountStatusControllerProvider,
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  }

  group('AccountStatusController.build', () {
    for (final status in AccountStatus.values) {
      test('goes loading -> data(${status.name})', () async {
        repository.onAccountStatus = () => Ok(status);
        listen();

        await container.read(accountStatusControllerProvider.future);

        expect(states, [_isLoading(), _isData(status)]);
        expect(repository.accountStatusCalls, 1);
      });
    }

    test(
      'goes loading -> error carrying the Failure, without retrying',
      () async {
        const failure = PlatformChannelFailure('channel down', code: 'E_CK');
        repository.onAccountStatus = () => const Err(failure);
        listen();

        await expectLater(
          container.read(accountStatusControllerProvider.future),
          throwsA(isA<PlatformChannelFailure>()),
        );

        expect(states, [
          _isLoading(),
          _isError(
            isA<PlatformChannelFailure>().having((f) => f, 'failure', failure),
          ),
        ]);
        expect(repository.accountStatusCalls, 1);
      },
    );
  });

  group('AccountStatusController.recheckAccount', () {
    test('re-reads and goes loading -> data(new status)', () async {
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      listen();
      await container.read(accountStatusControllerProvider.future);
      states.clear();

      final read = Completer<Result<AccountStatus>>();
      repository.onAccountStatus = () => read.future;
      final pending = container
          .read(accountStatusControllerProvider.notifier)
          .recheckAccount();

      expect(states, [_isLoading()]);
      read.complete(const Ok(AccountStatus.available));
      await pending;

      expect(states, [_isLoading(), _isData(AccountStatus.available)]);
      expect(repository.accountStatusCalls, 2);
    });

    test('the loading state keeps the previous status', () async {
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      listen();
      await container.read(accountStatusControllerProvider.future);

      final read = Completer<Result<AccountStatus>>();
      repository.onAccountStatus = () => read.future;
      final pending = container
          .read(accountStatusControllerProvider.notifier)
          .recheckAccount();

      final loading = container.read(accountStatusControllerProvider);
      expect(loading.isLoading, isTrue);
      expect(loading.value, AccountStatus.noAccount);

      read.complete(const Ok(AccountStatus.noAccount));
      await pending;
    });

    test('goes loading -> error carrying the Failure', () async {
      listen();
      await container.read(accountStatusControllerProvider.future);
      states.clear();

      repository.onAccountStatus = () =>
          const Err(PlatformChannelFailure('down', code: 'E_IO'));
      await container
          .read(accountStatusControllerProvider.notifier)
          .recheckAccount();

      expect(states, [
        _isLoading(),
        _isError(
          isA<PlatformChannelFailure>().having((f) => f.code, 'code', 'E_IO'),
        ),
      ]);
    });

    test('a re-check while one is in flight is ignored', () async {
      listen();
      await container.read(accountStatusControllerProvider.future);
      states.clear();

      final read = Completer<Result<AccountStatus>>();
      repository.onAccountStatus = () => read.future;
      final notifier = container.read(accountStatusControllerProvider.notifier);
      final first = notifier.recheckAccount();
      final second = notifier.recheckAccount();

      await second;
      expect(states, [_isLoading()]);

      read.complete(const Ok(AccountStatus.restricted));
      await first;

      expect(states, [_isLoading(), _isData(AccountStatus.restricted)]);
      expect(repository.accountStatusCalls, 2);
    });

    test('a re-check while the initial read is in flight is ignored', () async {
      final read = Completer<Result<AccountStatus>>();
      repository.onAccountStatus = () => read.future;
      listen();

      await container
          .read(accountStatusControllerProvider.notifier)
          .recheckAccount();
      read.complete(const Ok(AccountStatus.available));
      await container.read(accountStatusControllerProvider.future);

      expect(states, [_isLoading(), _isData(AccountStatus.available)]);
      expect(repository.accountStatusCalls, 1);
    });
  });

  test('is kept alive with no listeners', () async {
    await container.read(accountStatusControllerProvider.future);
    await container.pump();

    expect(container.exists(accountStatusControllerProvider), isTrue);
  });
}
