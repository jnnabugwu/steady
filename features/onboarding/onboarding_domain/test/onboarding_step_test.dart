import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

void main() {
  test('OnboardingStep codes, in flow order', () {
    // Each `name` is the wire code stored as "step" in onboarding.json, so
    // a rename makes a stored step unreadable (it reads as not started).
    // The list is #161's spec and the screen order of
    // docs/design/onboarding.md's flow table, not copied from the enum.
    expect(
      [for (final s in OnboardingStep.values) s.name],
      [
        'firstStone',
        'tracking',
        'source',
        'health',
        'week',
        'hardParts',
        'voice',
        'meetCoach',
        'firstWeek',
        'cairn',
      ],
    );
  });
}
