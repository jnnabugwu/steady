import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_coach_consent_repository.dart';

void main() {
  test('the coach model is unbound until the app overrides it', () {
    final container = ProviderContainer.test();
    expect(
      () => container.read(coachModelProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<UnimplementedError>(),
        ),
      ),
    );
  });

  test("the context's sources are unbound until the app binds them", () {
    final container = ProviderContainer.test();
    expect(container.read(coachHealthKitRepositoryProvider), isNull);
    expect(container.read(coachCravingRepositoryProvider), isNull);
    for (final read in [
      () => container.read(coachCheckInRepositoryProvider),
      () => container.read(coachMetricsRepositoryProvider),
    ]) {
      expect(read, throwsA(isA<ProviderException>()));
    }
  });

  test('session ids are random version 4 UUIDs', () {
    final a = randomCoachSessionId();
    expect(
      a,
      matches(
        RegExp(
          '^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
          r'[0-9a-f]{12}$',
        ),
      ),
    );
    expect(randomCoachSessionId(), isNot(a));
  });

  group('the consent gate', () {
    test('defaults to not given: no store is bound', () async {
      final container = ProviderContainer.test();
      expect(container.read(coachConsentRepositoryProvider), isNull);
      expect(await container.read(coachConsentGivenProvider.future), isFalse);
    });

    test('without it the coach is unavailable, and the model is never '
        'asked', () async {
      final model = _FakeCoachModel();
      final container = ProviderContainer.test(
        overrides: [coachModelProvider.overrideWithValue(model)],
      );
      await expectLater(
        container.read(coachAvailabilityProvider.future),
        throwsA(isA<CoachConsentNotGivenFailure>()),
      );
      expect(model.checks, 0);
    });

    test("with it, availability is the model's local check", () async {
      final model = _FakeCoachModel();
      final container = ProviderContainer.test(
        overrides: [
          coachModelProvider.overrideWithValue(model),
          coachConsentRepositoryProvider.overrideWithValue(
            FakeCoachConsentRepository(agreed: CoachConsent.currentVersion),
          ),
        ],
      );
      expect(await container.read(coachAvailabilityProvider.future), unit);
      expect(model.checks, 1);
    });

    test('availability follows consent: withdrawn, the coach is off again '
        'without asking the model', () async {
      final model = _FakeCoachModel();
      final container = ProviderContainer.test(
        overrides: [
          coachModelProvider.overrideWithValue(model),
          coachConsentRepositoryProvider.overrideWithValue(
            FakeCoachConsentRepository(agreed: CoachConsent.currentVersion),
          ),
        ],
      )..listen(coachAvailabilityProvider, (_, _) {});
      expect(await container.read(coachAvailabilityProvider.future), unit);
      await container
          .read(coachConsentGivenProvider.notifier)
          .withdrawCoachConsent();
      await expectLater(
        container.read(coachAvailabilityProvider.future),
        throwsA(isA<CoachConsentNotGivenFailure>()),
      );
      expect(model.checks, 1);
    });
  });

  test('an override is what the coach reads', () {
    final model = _FakeCoachModel();
    final container = ProviderContainer.test(
      overrides: [coachModelProvider.overrideWithValue(model)],
    );
    expect(container.read(coachModelProvider), same(model));
  });
}

class _FakeCoachModel implements CoachModel {
  int checks = 0;

  @override
  ResultFuture<Unit> checkAvailability() async {
    checks++;
    return const Ok(unit);
  }

  @override
  Stream<Result<CoachReplySnapshot>> reply(CoachRequest request) =>
      const Stream.empty();
}
