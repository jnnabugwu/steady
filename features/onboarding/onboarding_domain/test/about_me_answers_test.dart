import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

// Each enum value's `name` is its wire code: what the device-only file
// stores and what the coach proxy will receive in `aboutMe`. These tests
// pin every code, in order, so a rename or reorder fails here before it
// reaches the proxy or makes stored answers unreadable.
//
// The expected lists are copied from docs/design/onboarding.md (the flow
// table and "About me, as the proxy will receive it"), not from the enums,
// so they check the code against the design, not against itself. The
// proxy's side of the contract doesn't exist yet: when it does, its
// accepted codes should be checked against the same lists.
void main() {
  List<String> codes(List<Enum> values) => [for (final v in values) v.name];

  test('FoodTracking codes (screen 2)', () {
    expect(codes(FoodTracking.values), [
      'calAi',
      'otherHealthApp',
      'justStarting',
    ]);
  });

  test('OnboardingActivity codes (screen 5)', () {
    expect(codes(OnboardingActivity.values), [
      'tennis',
      'gym',
      'walks',
      'runs',
      'yoga',
      'other',
    ]);
  });

  test('WeekendShape codes (screen 5): "all over the place" is mixed', () {
    expect(codes(WeekendShape.values), ['busier', 'quieter', 'mixed']);
  });

  test('HardPart codes (screen 6)', () {
    expect(codes(HardPart.values), [
      'eatingOut',
      'lateNights',
      'weekends',
      'forgetting',
      'travel',
      'feelingJudged',
    ]);
  });

  test('CoachVoice codes (screen 7)', () {
    expect(codes(CoachVoice.values), ['gentle', 'direct', 'playful']);
  });

  test('the design doc example uses only codes that exist', () {
    // The `aboutMe` example in docs/design/onboarding.md, field by field.
    expect(CoachVoice.values.byName('gentle'), CoachVoice.gentle);
    expect(FoodTracking.values.byName('calAi'), FoodTracking.calAi);
    expect(['tennis', 'walks'].map(OnboardingActivity.values.byName), [
      OnboardingActivity.tennis,
      OnboardingActivity.walks,
    ]);
    expect(WeekendShape.values.byName('busier'), WeekendShape.busier);
    expect(['eatingOut', 'lateNights'].map(HardPart.values.byName), [
      HardPart.eatingOut,
      HardPart.lateNights,
    ]);
  });
}
