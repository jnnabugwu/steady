import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_coach_consent_repository.dart';

void main() {
  late FakeCoachConsentRepository consent;
  late ProviderContainer container;

  ProviderContainer make() => container = ProviderContainer.test(
    overrides: [coachConsentRepositoryProvider.overrideWithValue(consent)],
  );

  Future<bool> given() => container.read(coachConsentGivenProvider.future);

  CoachConsentGiven notifier() =>
      container.read(coachConsentGivenProvider.notifier);

  setUp(() => consent = FakeCoachConsentRepository());

  group('reading', () {
    test('nothing stored: not given', () async {
      make();
      expect(await given(), isFalse);
    });

    test('the current version: given', () async {
      consent.agreed = CoachConsent.currentVersion;
      make();
      expect(await given(), isTrue);
      expect(
        isCoachConsentGiven(container.read(coachConsentGivenProvider)),
        isTrue,
      );
    });

    test('an earlier version (the text changed since): not given, so it '
        'asks again', () async {
      consent.agreed = CoachConsent.currentVersion - 1;
      make();
      expect(await given(), isFalse);
    });

    test('a later version than this build knows: not given', () async {
      consent.agreed = CoachConsent.currentVersion + 1;
      make();
      expect(await given(), isFalse);
    });

    test('a store that fails to read: an error at once (no retry), which '
        'reads as not given', () async {
      final container = ProviderContainer.test(
        overrides: [
          coachConsentRepositoryProvider.overrideWithValue(_FailingRead()),
        ],
      );
      await expectLater(
        container.read(coachConsentGivenProvider.future),
        throwsA(isA<CoachConsentStorageFailure>()),
      );
      expect(
        isCoachConsentGiven(container.read(coachConsentGivenProvider)),
        isFalse,
      );
      expect(
        await readCoachConsent(
          container.read(coachConsentGivenProvider.future),
        ),
        isFalse,
      );
    });

    test('while loading, not given', () {
      consent.agreed = CoachConsent.currentVersion;
      make();
      expect(
        isCoachConsentGiven(container.read(coachConsentGivenProvider)),
        isFalse,
      );
    });
  });

  group('giveCoachConsent (CoachConsentGiven)', () {
    test('stores the current version, and reads as given', () async {
      make();
      await given();
      await notifier().giveCoachConsent();
      expect(consent.agreed, CoachConsent.currentVersion);
      expect(container.read(coachConsentGivenProvider), const AsyncData(true));
    });

    test('after a bumped version, agreeing again stores the new one', () async {
      consent.agreed = CoachConsent.currentVersion - 1;
      make();
      expect(await given(), isFalse);
      await notifier().giveCoachConsent();
      expect(consent.agreed, CoachConsent.currentVersion);
      expect(await given(), isTrue);
    });

    test("a save that fails is a typed error, and isn't given", () async {
      make();
      await given();
      consent.failNext = const CoachConsentStorageFailure('disk');
      await notifier().giveCoachConsent();
      final state = container.read(coachConsentGivenProvider);
      expect(state.error, isA<CoachConsentStorageFailure>());
      expect(isCoachConsentGiven(state), isFalse);
    });

    test(
      'ignored while loading: the first read, or a write in flight',
      () async {
        make();
        await notifier().giveCoachConsent();
        expect(consent.calls, ['read']);

        await given();
        consent.holdWrites = Completer<void>();
        final first = notifier().giveCoachConsent();
        await notifier().giveCoachConsent();
        await notifier().withdrawCoachConsent();
        consent.holdWrites!.complete();
        await first;
        expect(consent.calls, ['read', 'give ${CoachConsent.currentVersion}']);
      },
    );

    test("with no store bound (the Mac), says it couldn't save", () async {
      final container = ProviderContainer.test();
      await container.read(coachConsentGivenProvider.future);
      await container
          .read(coachConsentGivenProvider.notifier)
          .giveCoachConsent();
      expect(
        container.read(coachConsentGivenProvider).error,
        isA<CoachConsentStorageFailure>(),
      );
    });
  });

  group('withdrawCoachConsent (CoachConsentWithdrawn)', () {
    test('forgets the agreement', () async {
      consent.agreed = CoachConsent.currentVersion;
      make();
      await given();
      await notifier().withdrawCoachConsent();
      expect(consent.agreed, isNull);
      expect(container.read(coachConsentGivenProvider), const AsyncData(false));
    });

    test('reads as not given from its first line, before the store is '
        'written', () async {
      consent.agreed = CoachConsent.currentVersion;
      make();
      await given();
      consent.holdWrites = Completer<void>();
      final withdrawing = notifier().withdrawCoachConsent();
      expect(
        isCoachConsentGiven(container.read(coachConsentGivenProvider)),
        isFalse,
      );
      consent.holdWrites!.complete();
      await withdrawing;
      expect(consent.agreed, isNull);
    });

    test('a save that fails says so, and stays not given here', () async {
      consent.agreed = CoachConsent.currentVersion;
      make();
      await given();
      consent.failNext = const CoachConsentStorageFailure('disk');
      await notifier().withdrawCoachConsent();
      final state = container.read(coachConsentGivenProvider);
      expect(state.error, isA<CoachConsentStorageFailure>());
      expect(isCoachConsentGiven(state), isFalse);
    });
  });
}

class _FailingRead implements CoachConsentRepository {
  @override
  ResultFuture<int?> readAgreedVersion() async =>
      const Err(CoachConsentStorageFailure('disk'));

  @override
  ResultFuture<Unit> giveConsent(int version) async => const Ok(unit);

  @override
  ResultFuture<Unit> withdrawConsent() async => const Ok(unit);
}
