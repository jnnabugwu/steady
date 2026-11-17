import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const failures = <CoachModelFailure>[
    CoachConsentNotGivenFailure(),
    CoachTurnedOffFailure(),
    CoachDeviceNotVerifiedFailure(),
    CoachOfflineFailure(),
    CoachRateLimitedFailure(retryAfter: Duration(hours: 3)),
    CoachRefusalFailure(),
    CoachServerFailure(),
  ];

  test('every coach failure is a Failure with a plain message', () {
    // Plain: a whole sentence for the person, with no wire code or other
    // identifier (a camelCase or snake_case word, apart from iPhone) and no
    // HTTP or error jargon.
    final identifier = RegExp(r'\b(?!iPhone\b)[a-z]+[A-Z_]\w*');
    for (final failure in failures) {
      expect(failure, isA<Failure>());
      final message = failure.message;
      expect(message, isNotEmpty);
      expect(message, endsWith('.'), reason: message);
      expect(message, isNot(matches(identifier)), reason: message);
      for (final jargon in ['http', 'error', 'exception', 'attest', '429']) {
        expect(message.toLowerCase(), isNot(contains(jargon)), reason: message);
      }
    }
  });

  test('the switch the coach screens make is exhaustive', () {
    // Adding a failure without handling it here fails to compile, the same
    // as it will in the coach UI.
    for (final failure in failures) {
      final what = switch (failure) {
        CoachConsentNotGivenFailure() => 'not set up',
        CoachTurnedOffFailure() => 'off',
        CoachDeviceNotVerifiedFailure() => 'not verified',
        CoachOfflineFailure() => 'offline',
        CoachRateLimitedFailure() => 'limit',
        CoachRefusalFailure() => 'help line',
        CoachServerFailure() => 'server',
      };
      expect(what, isNotEmpty);
    }
  });

  test('consent, the kill switch and verification are "unavailable"; the '
      'rest are reply failures', () {
    expect(
      failures.whereType<CoachUnavailableFailure>().map((f) => f.runtimeType),
      [
        CoachConsentNotGivenFailure,
        CoachTurnedOffFailure,
        CoachDeviceNotVerifiedFailure,
      ],
    );
  });

  test('the kill switch says the coach is off, as the proxy asks', () {
    expect(
      const CoachTurnedOffFailure().message,
      'The coach is off right now.',
    );
  });

  test('rate limits compare by retryAfter, and nothing compares by cause', () {
    expect(
      const CoachRateLimitedFailure(retryAfter: Duration(seconds: 5)),
      CoachRateLimitedFailure(
        retryAfter: const Duration(seconds: 5),
        cause: Exception('x'),
      ),
    );
    expect(
      const CoachRateLimitedFailure(retryAfter: Duration(seconds: 5)),
      isNot(const CoachRateLimitedFailure(retryAfter: Duration(seconds: 6))),
    );
    expect(const CoachServerFailure(), CoachServerFailure(cause: Exception()));
  });
}
