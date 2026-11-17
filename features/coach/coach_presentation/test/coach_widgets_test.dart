import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('a rate limit says when it lifts, roughly', () {
    expect(coachRetryAfterLabel(null), 'later');
    expect(
      coachRetryAfterLabel(const Duration(seconds: 30)),
      'in a few minutes',
    );
    expect(
      coachRetryAfterLabel(const Duration(minutes: 25)),
      'in about 25 minutes',
    );
    expect(
      coachRetryAfterLabel(const Duration(minutes: 70)),
      'in about an hour',
    );
    expect(coachRetryAfterLabel(const Duration(hours: 7)), 'in about 7 hours');
  });

  test('"Check again" only where it could help', () {
    final canRetry = {
      for (final failure in <Failure>[
        const CoachConsentNotGivenFailure(),
        const CoachTurnedOffFailure(),
        const CoachDeviceNotVerifiedFailure(),
        const CoachOfflineFailure(),
        const CoachRateLimitedFailure(),
        const CoachServerFailure(),
        const UnknownFailure('x'),
      ])
        failure.runtimeType: coachUnavailableCopy(failure).canRetry,
    };
    expect(canRetry, {
      // Consent is the consent screen's job (#153), not a retry.
      CoachConsentNotGivenFailure: false,
      CoachTurnedOffFailure: true,
      CoachDeviceNotVerifiedFailure: false,
      CoachOfflineFailure: true,
      CoachRateLimitedFailure: true,
      CoachServerFailure: true,
      UnknownFailure: true,
    });
  });

  test("the kill switch copy is the proxy's", () {
    expect(
      coachUnavailableCopy(const CoachTurnedOffFailure()).title,
      'The coach is off right now',
    );
  });
}
