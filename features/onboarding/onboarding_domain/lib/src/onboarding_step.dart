/// A screen of the onboarding flow, in flow order (docs/design/onboarding.md,
/// "The flow"). Stored so a person who leaves partway resumes where they
/// left off.
///
/// **Each value's `name` is its wire code** in `onboarding.json`. Renaming
/// one makes a stored step unreadable (it reads as not started), so don't;
/// reordering changes only the flow. `test/onboarding_step_test.dart` pins
/// every code.
enum OnboardingStep {
  /// 1. Place your first stone.
  firstStone,

  /// 2. How you track food.
  tracking,

  /// 3. Where did you hear about Steady? (an analytics event only; the
  /// answer itself is never stored).
  source,

  /// 4. Apple Health.
  health,

  /// 5. Your week.
  week,

  /// 6. What gets in the way.
  hardParts,

  /// 7. Your coach's voice.
  voice,

  /// 8. Meet the coach (consent and the note).
  meetCoach,

  /// 9. Your first week.
  firstWeek,

  /// 10. Your cairn.
  cairn,
}
