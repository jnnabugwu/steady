import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_check_in_repository.dart';

typedef _State = AsyncValue<CheckInStatus?>;

Matcher _isLoading() => isA<AsyncLoading<CheckInStatus?>>();

Matcher _isData(CheckInStatus? value) =>
    isA<AsyncData<CheckInStatus?>>().having((s) => s.value, 'value', value);

Matcher _isError(Matcher failure) =>
    isA<AsyncError<CheckInStatus?>>().having((s) => s.error, 'error', failure);

void main() {
  final day = DateTime(2026, 8, 24);
  late FakeCheckInRepository repository;
  late ProviderContainer container;
  late List<_State> states;

  setUp(() {
    repository = FakeCheckInRepository();
    container = ProviderContainer.test(
      overrides: [checkInRepositoryProvider.overrideWithValue(repository)],
    );
    states = [];
  });

  void listen() {
    container.listen<_State>(
      checkInControllerProvider(day),
      (_, next) => states.add(next),
      fireImmediately: true,
    );
  }

  group('CheckInController.build', () {
    test('goes loading -> data with the stored status', () async {
      repository.onGetStatus = (_) => const Ok(CheckInStatus.logged);
      listen();

      await container.read(checkInControllerProvider(day).future);

      expect(states, [_isLoading(), _isData(CheckInStatus.logged)]);
      expect(repository.getStatusCalls, [day]);
    });

    test('goes loading -> data(null) when nothing is logged yet', () async {
      listen();

      await container.read(checkInControllerProvider(day).future);

      expect(states, [_isLoading(), _isData(null)]);
    });

    test(
      'goes loading -> error carrying the Failure, without retrying',
      () async {
        const failure = NotFoundFailure('no row');
        repository.onGetStatus = (_) => const Err(failure);
        listen();

        await expectLater(
          container.read(checkInControllerProvider(day).future),
          throwsA(isA<NotFoundFailure>()),
        );

        expect(states, [
          _isLoading(),
          _isError(isA<NotFoundFailure>().having((f) => f, 'failure', failure)),
        ]);
        expect(repository.getStatusCalls, hasLength(1));
      },
    );
  });

  group('CheckInController.logCheckIn', () {
    test('goes loading -> data(status) and writes through', () async {
      listen();
      await container.read(checkInControllerProvider(day).future);
      states.clear();

      final completer = Completer<Result<Unit>>();
      repository.onLogCheckIn = (_, _) => completer.future;
      final pending = container
          .read(checkInControllerProvider(day).notifier)
          .logCheckIn(CheckInStatus.partial);

      expect(states, [_isLoading()]);
      completer.complete(const Ok(unit));
      await pending;

      expect(states, [_isLoading(), _isData(CheckInStatus.partial)]);
      expect(repository.logCheckInCalls, [(day, CheckInStatus.partial)]);
    });

    test('goes loading -> error carrying the Failure', () async {
      listen();
      await container.read(checkInControllerProvider(day).future);
      states.clear();

      repository.onLogCheckIn = (_, _) =>
          const Err(PlatformChannelFailure('write failed', code: 'E_IO'));
      await container
          .read(checkInControllerProvider(day).notifier)
          .logCheckIn(CheckInStatus.skipped);

      expect(states, [
        _isLoading(),
        _isError(
          isA<PlatformChannelFailure>().having((f) => f.code, 'code', 'E_IO'),
        ),
      ]);
    });

    test(
      'loading and error keep the last saved status as their value',
      () async {
        repository.onGetStatus = (_) => const Ok(CheckInStatus.logged);
        listen();
        await container.read(checkInControllerProvider(day).future);
        states.clear();

        final completer = Completer<Result<Unit>>();
        repository.onLogCheckIn = (_, _) => completer.future;
        final pending = container
            .read(checkInControllerProvider(day).notifier)
            .logCheckIn(CheckInStatus.skipped);

        expect(states.single.value, CheckInStatus.logged);
        completer.complete(const Err(UnknownFailure('write failed')));
        await pending;

        expect(states, [_isLoading(), _isError(isA<UnknownFailure>())]);
        expect(states.last.value, CheckInStatus.logged);
      },
    );

    test(
      'a throwing write ends in an error and a later write still runs',
      () async {
        listen();
        await container.read(checkInControllerProvider(day).future);
        states.clear();

        repository.onLogCheckIn = (_, _) => throw StateError('channel died');
        final notifier = container.read(
          checkInControllerProvider(day).notifier,
        );
        await notifier.logCheckIn(CheckInStatus.partial);

        expect(states, [
          _isLoading(),
          _isError(
            isA<UnknownFailure>().having(
              (f) => f.cause,
              'cause',
              isA<StateError>(),
            ),
          ),
        ]);

        repository.onLogCheckIn = (_, _) => const Ok(unit);
        await notifier.logCheckIn(CheckInStatus.logged);

        expect(states.last, _isData(CheckInStatus.logged));
        expect(repository.logCheckInCalls, [
          (day, CheckInStatus.partial),
          (day, CheckInStatus.logged),
        ]);
      },
    );

    test('a thrown Failure is surfaced as that Failure', () async {
      listen();
      await container.read(checkInControllerProvider(day).future);
      states.clear();

      repository.onLogCheckIn = (_, _) =>
          throw const PlatformChannelFailure('write failed', code: 'E_IO');
      await container
          .read(checkInControllerProvider(day).notifier)
          .logCheckIn(CheckInStatus.skipped);

      expect(states, [
        _isLoading(),
        _isError(
          isA<PlatformChannelFailure>().having((f) => f.code, 'code', 'E_IO'),
        ),
      ]);
    });

    test('a second write while one is in flight is ignored', () async {
      listen();
      await container.read(checkInControllerProvider(day).future);
      states.clear();

      final completer = Completer<Result<Unit>>();
      repository.onLogCheckIn = (_, _) => completer.future;
      final notifier = container.read(checkInControllerProvider(day).notifier);
      final first = notifier.logCheckIn(CheckInStatus.partial);
      final second = notifier.logCheckIn(CheckInStatus.skipped);

      await second;
      expect(states, [_isLoading()]);

      completer.complete(const Ok(unit));
      await first;

      expect(states, [_isLoading(), _isData(CheckInStatus.partial)]);
      expect(repository.logCheckInCalls, [(day, CheckInStatus.partial)]);
    });

    test('a write while the initial read is in flight is ignored', () async {
      final read = Completer<Result<CheckInStatus?>>();
      repository.onGetStatus = (_) => read.future;
      listen();

      await container
          .read(checkInControllerProvider(day).notifier)
          .logCheckIn(CheckInStatus.logged);
      read.complete(const Ok(null));
      await container.read(checkInControllerProvider(day).future);

      expect(states, [_isLoading(), _isData(null)]);
      expect(repository.logCheckInCalls, isEmpty);
    });
  });

  group('family key', () {
    test('the same midnight DateTime keys the same provider', () {
      expect(
        checkInControllerProvider(DateTime(2026, 8, 24)),
        checkInControllerProvider(DateTime(2026, 8, 24)),
      );
    });

    test('un-normalized times on the same day key different providers', () {
      expect(
        checkInControllerProvider(DateTime(2026, 8, 24, 9)),
        isNot(checkInControllerProvider(DateTime(2026, 8, 24, 18))),
      );
    });
  });
}
