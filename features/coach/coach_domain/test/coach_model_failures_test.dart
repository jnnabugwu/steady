import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('every unavailable reason is a CoachModelUnavailableFailure with a '
      'plain message', () {
    const failures = <CoachModelUnavailableFailure>[
      CoachDeviceNotEligibleFailure(),
      CoachAppleIntelligenceNotEnabledFailure(),
      CoachModelNotReadyFailure(),
      CoachOsTooOldFailure(),
      CoachModelUnavailableUnknownFailure(),
    ];
    // Plain: a whole sentence for the person, with no wire reason or other
    // code identifier (a camelCase word, apart from Apple names like iPhone)
    // and no framework or error jargon.
    final identifier = RegExp(r'\b(?!(?:iOS|iPhone|iCloud)\b)[a-z]+[A-Z]\w*');
    for (final failure in failures) {
      expect(failure, isA<Failure>());
      final message = failure.message;
      expect(message, isNotEmpty);
      expect(message, endsWith('.'), reason: message);
      expect(message, isNot(matches(identifier)), reason: message);
      for (final jargon in ['Foundation Models', 'error', 'exception']) {
        expect(
          message.toLowerCase(),
          isNot(contains(jargon.toLowerCase())),
          reason: message,
        );
      }
      // An exhaustive switch: adding a reason without handling it here
      // fails to compile, the same as it will in the coach UI.
      final reason = switch (failure) {
        CoachDeviceNotEligibleFailure() => 'device',
        CoachAppleIntelligenceNotEnabledFailure() => 'off',
        CoachModelNotReadyFailure() => 'not ready',
        CoachOsTooOldFailure() => 'os',
        CoachModelUnavailableUnknownFailure() => 'unknown',
      };
      expect(reason, isNotEmpty);
    }
    expect(
      const CoachAppleIntelligenceNotEnabledFailure().message,
      contains('Settings'),
    );
    expect(const CoachOsTooOldFailure().message, contains('iOS 26'));
  });

  test('inference failures compare by message and reason, not cause', () {
    const a = CoachInferenceFailure(
      'Too long',
      reason: CoachInferenceFailureReason.contextExceeded,
    );
    final b = CoachInferenceFailure(
      'Too long',
      reason: CoachInferenceFailureReason.contextExceeded,
      cause: Exception('x'),
    );
    expect(a, b);
    expect(
      a,
      isNot(
        const CoachInferenceFailure(
          'Too long',
          reason: CoachInferenceFailureReason.other,
        ),
      ),
    );
  });

  test('model values compare by value', () {
    expect(
      const CoachModelInfo(contextSize: 4096),
      const CoachModelInfo(contextSize: 4096),
    );
    expect(
      const CoachModelSession(id: 'a'),
      isNot(const CoachModelSession(id: 'b')),
    );
  });
}
