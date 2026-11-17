// The answers onboarding offers, one enum per question.
//
// **Each value's `name` is its wire code** (docs/design/onboarding.md,
// "About me, as the proxy will receive it"): it's what the device-only file
// stores and what the coach proxy will receive in `aboutMe`, where the proxy
// turns codes into sentences. Renaming a value changes the contract with the
// proxy and makes stored answers unreadable (dropped as unknown), so don't:
// add a value instead. `test/about_me_answers_test.dart` pins every code.

/// How the person tracks food (screen 2). Decides what Today shows, e.g.
/// whether it offers the Cal AI import.
enum FoodTracking {
  /// Cal AI.
  calAi,

  /// Another app that writes to Apple Health.
  otherHealthApp,

  /// "I'm just starting".
  justStarting,
}

/// An activity from "Your week" (screen 5). Multi-select.
enum OnboardingActivity {
  /// Tennis.
  tennis,

  /// The gym.
  gym,

  /// Walks.
  walks,

  /// Runs.
  runs,

  /// Yoga.
  yoga,

  /// Something else. No free text: the note carries any detail.
  other,
}

/// "My weekends are…" (screen 5).
enum WeekendShape {
  /// Busier.
  busier,

  /// Quieter.
  quieter,

  /// "All over the place".
  mixed,
}

/// "What gets in the way" (screen 6). Multi-select.
enum HardPart {
  /// Eating out.
  eatingOut,

  /// Late nights.
  lateNights,

  /// Weekends.
  weekends,

  /// Forgetting.
  forgetting,

  /// Travel.
  travel,

  /// Feeling judged.
  feelingJudged,
}

/// The coach's voice (screen 7). Each voice gets its own tone rule on the
/// proxy; none of them shames.
enum CoachVoice {
  /// Gentle.
  gentle,

  /// Direct.
  direct,

  /// Playful.
  playful,
}
