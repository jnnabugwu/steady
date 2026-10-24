import 'dart:async';

import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_craving_repository.dart';

void main() {
  late FakeCravingRepository repository;
  late ProviderContainer container;
  late DateTime now;

  setUp(() {
    repository = FakeCravingRepository();
    now = DateTime(2026, 10, 23, 20);
    container =
        ProviderContainer.test(
            overrides: [
              cravingRepositoryProvider.overrideWithValue(repository),
              cravingClockProvider.overrideWithValue(() => now),
              cravingIdGeneratorProvider.overrideWithValue(() => 'id-1'),
            ],
          )
          // Keep the auto-dispose flow alive for the test.
          ..listen(cravingFlowControllerProvider, (_, _) {});
  });

  CravingFlowController flow() =>
      container.read(cravingFlowControllerProvider.notifier);
  CravingFlowState state() => container.read(cravingFlowControllerProvider);

  test('starts at the intensity step, stamped with the clock and an id', () {
    expect(state().step, CravingStep.intensity);
    expect(state().startedAt, now);
    expect(state().id, 'id-1');
    expect(state().event, isNull);
  });

  test('ignores an intensity outside 1 to 5', () {
    flow()
      ..rateCraving(0)
      ..rateCraving(6);
    expect(state().step, CravingStep.intensity);
  });

  test('hungry short-circuits: saved with no minute and no second rating, '
      'without offering a wait', () async {
    flow()
      ..rateCraving(4)
      ..toggleReason(CravingReason.hungry)
      ..toggleReason(CravingReason.stressed);
    now = DateTime(2026, 10, 23, 20, 0, 30);
    await flow().noteReasons();

    expect(state().step, CravingStep.hungry);
    expect(state().saved, isTrue);
    expect(
      repository.saveCalls.single,
      CravingEvent(
        id: 'id-1',
        startedAt: DateTime(2026, 10, 23, 20),
        endedAt: DateTime(2026, 10, 23, 20, 0, 30),
        intensityBefore: 4,
        reasons: const {CravingReason.hungry, CravingReason.stressed},
        tookMinute: false,
        outcome: CravingOutcome.hungry,
      ),
    );

    // Nothing later in the flow can happen from here.
    flow().startMinute();
    await flow().chooseOutcome(CravingOutcome.passed);
    expect(state().step, CravingStep.hungry);
    expect(repository.saveCalls, hasLength(1));
  });

  test('toggling a reason twice removes it; no reasons is fine', () async {
    flow()
      ..rateCraving(2)
      ..toggleReason(CravingReason.bored)
      ..toggleReason(CravingReason.bored);
    expect(state().reasons, isEmpty);

    await flow().noteReasons();
    expect(state().step, CravingStep.offer);
    expect(repository.saveCalls, isEmpty);
  });

  test('skipping the minute goes straight to "Still want it?"', () async {
    flow().rateCraving(3);
    await flow().noteReasons();
    flow().skipMinute();

    expect(state().step, CravingStep.stillWant);
    expect(state().tookMinute, isFalse);

    await flow().chooseOutcome(CravingOutcome.notSure);
    final saved = repository.saveCalls.single;
    expect(saved.tookMinute, isFalse);
    expect(saved.intensityAfter, isNull);
    expect(saved.outcome, CravingOutcome.notSure);
  });

  test('taking the minute records it, however the minute ends', () async {
    flow().rateCraving(5);
    await flow().noteReasons();
    flow().startMinute();
    expect(state().step, CravingStep.minute);

    flow().endMinute();
    expect(state().step, CravingStep.stillWant);

    flow()
      ..rateAgain(3)
      ..rateAgain(2);
    await flow().chooseOutcome(CravingOutcome.passed);

    final saved = repository.saveCalls.single;
    expect(saved.tookMinute, isTrue);
    expect(saved.intensityBefore, 5);
    expect(saved.intensityAfter, 2);
    expect(state().step, CravingStep.finished);
  });

  for (final outcome in [
    CravingOutcome.havingIt,
    CravingOutcome.passed,
    CravingOutcome.notSure,
  ]) {
    test('${outcome.name} is saved and ends the flow', () async {
      flow()
        ..rateCraving(3)
        ..toggleReason(CravingReason.tired);
      await flow().noteReasons();
      flow().skipMinute();
      await flow().chooseOutcome(outcome);

      expect(state().step, CravingStep.finished);
      expect(state().outcome, outcome);
      expect(state().saved, isTrue);
      expect(repository.events.single.outcome, outcome);
      expect(repository.events.single.reasons, {CravingReason.tired});
    });
  }

  test('hungry cannot be picked as an outcome at "Still want it?"', () async {
    flow().rateCraving(3);
    await flow().noteReasons();
    flow().skipMinute();
    await flow().chooseOutcome(CravingOutcome.hungry);
    expect(state().step, CravingStep.stillWant);
    expect(repository.saveCalls, isEmpty);
  });

  test('steps out of order are ignored', () async {
    flow()
      ..startMinute()
      ..endMinute()
      ..rateAgain(3);
    await flow().chooseOutcome(CravingOutcome.passed);
    await flow().noteReasons();
    expect(state().step, CravingStep.intensity);
    expect(repository.saveCalls, isEmpty);
  });

  test(
    'a failed save keeps the ending and can be retried with the same id',
    () async {
      repository.onSave = (_) async => const Err(UnknownFailure('disk full'));
      flow().rateCraving(3);
      await flow().noteReasons();
      flow().skipMinute();
      await flow().chooseOutcome(CravingOutcome.havingIt);

      expect(state().step, CravingStep.finished);
      expect(state().saveFailure, const UnknownFailure('disk full'));
      expect(state().saved, isFalse);

      repository.onSave = null;
      await flow().retrySave();
      expect(state().saveFailure, isNull);
      expect(state().saved, isTrue);
      expect(repository.saveCalls.map((e) => e.id), ['id-1', 'id-1']);
      expect(repository.events, hasLength(1));
    },
  );

  test('a thrown error becomes an UnknownFailure, never escapes', () async {
    repository.onSave = (_) async => throw StateError('boom');
    flow().rateCraving(3);
    await flow().noteReasons();
    flow().skipMinute();
    await flow().chooseOutcome(CravingOutcome.passed);
    expect(state().saveFailure, isA<UnknownFailure>());
  });

  test('saving refreshes the weekly summary', () async {
    container.listen(cravingWeekControllerProvider, (_, _) {});
    expect(
      await container.read(cravingWeekControllerProvider.future),
      const CravingWeekSummary(count: 0),
    );

    flow().rateCraving(3);
    await flow().noteReasons();
    flow().skipMinute();
    await flow().chooseOutcome(CravingOutcome.passed);

    expect(
      await container.read(cravingWeekControllerProvider.future),
      const CravingWeekSummary(count: 1, mostly: CravingTimeOfDay.evening),
    );
  });

  test('a save still lands if the flow closes before it returns', () async {
    final gate = Completer<Result<Unit>>();
    repository.onSave = (_) => gate.future;
    final sub = container.listen(cravingFlowControllerProvider, (_, _) {});
    flow().rateCraving(3);
    await flow().noteReasons();
    flow().skipMinute();
    final pending = flow().chooseOutcome(CravingOutcome.passed);
    sub.close();
    container.dispose();
    gate.complete(const Ok(unit));
    await pending;
    expect(repository.saveCalls, hasLength(1));
  });
}
