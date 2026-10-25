import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_coach_repository.dart';

void main() {
  late FakeCoachRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeCoachRepository([
      CoachSession(
        id: 'a',
        kind: CoachSessionKind.weekly,
        startedAt: DateTime(2026, 10, 23, 19),
      ),
    ]);
    container = ProviderContainer.test(
      overrides: [coachRepositoryProvider.overrideWithValue(repository)],
    );
  });

  CoachHistoryController notifier() =>
      container.read(coachHistoryControllerProvider.notifier);

  Future<bool> settled() =>
      container.read(coachHistoryControllerProvider.future);

  test('starts as data(false)', () async {
    expect(await settled(), isFalse);
    expect(container.read(coachHistoryControllerProvider).hasValue, isTrue);
  });

  test('deleteCoachHistory goes loading -> data(true) and clears the '
      'store', () async {
    container.listen(coachHistoryControllerProvider, (_, _) {});
    await settled();
    final deleting = notifier().deleteCoachHistory();
    expect(container.read(coachHistoryControllerProvider).isLoading, isTrue);
    await deleting;

    expect(container.read(coachHistoryControllerProvider).value, isTrue);
    expect(repository.sessions, isEmpty);
    expect(repository.deleteAllCalls, 1);
  });

  test('an Err becomes an AsyncError carrying that Failure', () async {
    container.listen(coachHistoryControllerProvider, (_, _) {});
    await settled();
    const failure = CoachHistoryStorageFailure('locked');
    repository.onDeleteAll = () async => const Err(failure);
    await notifier().deleteCoachHistory();

    final state = container.read(coachHistoryControllerProvider);
    expect(state.error, failure);
    expect(repository.sessions, hasLength(1));
  });

  test('a thrown error becomes an AsyncError with a typed Failure', () async {
    container.listen(coachHistoryControllerProvider, (_, _) {});
    await settled();
    repository.onDeleteAll = () async => throw StateError('boom');
    await notifier().deleteCoachHistory();

    expect(
      container.read(coachHistoryControllerProvider).error,
      isA<UnknownFailure>(),
    );
  });

  test('a second delete while one is in flight is ignored', () async {
    container.listen(coachHistoryControllerProvider, (_, _) {});
    await settled();
    final gate = Completer<Result<Unit>>();
    repository.onDeleteAll = () => gate.future;
    final first = notifier().deleteCoachHistory();
    await notifier().deleteCoachHistory();
    expect(repository.deleteAllCalls, 1);

    gate.complete(const Ok(unit));
    await first;
    expect(container.read(coachHistoryControllerProvider).value, isTrue);
  });

  test('can delete again after a failure', () async {
    container.listen(coachHistoryControllerProvider, (_, _) {});
    await settled();
    repository.onDeleteAll = () async => const Err(UnknownFailure('x'));
    await notifier().deleteCoachHistory();
    repository.onDeleteAll = null;
    await notifier().deleteCoachHistory();

    expect(container.read(coachHistoryControllerProvider).value, isTrue);
    expect(repository.deleteAllCalls, 2);
  });

  test('disposed mid-delete: the delete still runs, and nothing '
      'throws', () async {
    final sub = container.listen(coachHistoryControllerProvider, (_, _) {});
    await settled();
    final gate = Completer<Result<Unit>>();
    repository.onDeleteAll = () => gate.future;
    final deleting = notifier().deleteCoachHistory();
    sub.close();
    await container.pump();

    gate.complete(const Ok(unit));
    await deleting;
    expect(repository.deleteAllCalls, 1);
  });
}
