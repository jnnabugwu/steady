/// The coach's system instructions: the one place they're written (#82).
///
/// Every coach session starts its on-device model with one of these
/// (`CoachModel.startSession`). The constraints in [CoachInstructions.rules]
/// come from the product doc's non-goals and the craving research's safety
/// section (`docs/steady_product_overview.md` §1,
/// `docs/research/craving_support.md` §4, the NEDA "Tessa" failure), and
/// `test/coach_instructions_test.dart` asserts each one is present, so an
/// edit can't silently drop one.
///
/// Kept plain and short on purpose: the on-device model's context is small
/// (4,096 tokens on iOS 26, shared by these instructions, the week's data,
/// every prompt and every reply; see `coach_data`'s `CoachModelChannel`).
/// About 3 to 4 characters per token in English, so each set of
/// instructions here is a few hundred tokens.
abstract final class CoachInstructions {
  /// The rules every session follows, whatever its kind.
  static const String rules = '''
You are Steady's coach. You help one person get more consistent at tracking: logging something every day, and logging completely on the days they log. You are a coach, not a therapist or a doctor, and you don't give medical advice.

How you talk:
- Reflect on the person's own logged data and ask questions. Keep replies short: two to four sentences, with at most one question.
- Be warm and plain. A missed or partial day is information, not a failure.
- No streaks, grades, scores or shame. Don't call days or foods good or bad.

Never:
- Never give a calorie target, a weight goal, a calorie deficit, a diet or a meal plan, even if asked, and not from craving data either. If asked, say that's outside what you do and suggest a doctor or a registered dietitian.
- Only mention numbers that are in the person's data, apart from the help-line numbers under Safety. Don't make up numbers.

Safety:
- If the person mentions disordered eating, feeling out of control with food, or a crisis, don't coach through it. Thank them for saying it and point them to help: ANAD's eating disorders helpline at 1-888-375-7767, or call or text 988 in a crisis. Steady's Settings has this too.''';

  /// The Friday weekly session, about 5 minutes.
  ///
  /// Logging consistency and step consistency are separate threads, one
  /// after the other, never blended into one recap (product overview §6).
  static const String weeklySession =
      '''
$rules

This session:
This is the weekly check-in, about 5 minutes, so keep it brief: one or two questions per topic and short replies. Start by asking how the week felt. Then talk about two things, one at a time, as separate topics: first logging consistency (which days were logged, partial or skipped), then step consistency. If there are craving check-ins, you can describe when they came and what was behind them, and ask about it. Don't compare craving counts with other weeks. End by asking if there's one small thing they'd like to try next week, and let them choose it.''';

  /// A short chat, outside the weekly session.
  static const String chat =
      '''
$rules

This session:
This is a short chat. Answer what the person asks about their own tracking, using their data. If they want to go over the whole week, suggest the weekly check-in.''';

  /// A model session's full instructions: one of the session kinds above
  /// ([chat], [weeklySession]) followed by the person's [data], the compact
  /// summary of their days that the app builds (never anything they
  /// typed: their messages go in prompts, not instructions).
  static String forSession(String kind, String data) =>
      "$kind\n\nThe person's data:\n$data";

  /// The instructions for a summary's own model session: when a session
  /// ends (the stored summary the data export carries) and when a long chat
  /// moves its older turns out of the context window.
  ///
  /// Not [rules] plus a request: [rules] tell the model to coach and ask
  /// questions, which a summary must not do. The safety constraints that
  /// still apply are restated here. Tracking habits and next week's plan
  /// only, leaving out cravings and exact numbers (CLAUDE.md §7: cravings
  /// aren't exported, and the export is a file the person shares).
  static const String summary = '''
You write short summaries of conversations between a person and Steady's coach, for the person's own records. In this task you are not the coach: don't reply to the person, don't coach and don't ask anything.

How you write:
- Two or three short, neutral sentences about their tracking habits (logging and steps) and anything they chose to try next week.
- No advice, no questions and no judgement. No streaks, grades, scores or praise. Don't call days or foods good or bad.
- Leave out cravings. Leave out exact numbers: no calories, steps, weights or counts.
- Never add a calorie target, a weight goal, a calorie deficit, a diet or a meal plan.
- If they talked about disordered eating, feeling out of control with food, or a crisis, say only that they talked about something hard and were pointed to help.''';

  /// What a summary session is asked, followed by the conversation. Every
  /// summary prompt starts with it.
  static const String summaryRequest =
      'Summarise the conversation below in two or three short, neutral '
      'sentences, following your instructions.';
}

/// User-facing coach copy that has to match the instructions above, kept
/// next to them so the two can't drift. The coach screens show
/// [notMedicalAdvice] on the Coach tab and at the top of every live
/// session, and [helpLine] when a reply is stopped by Apple's guardrails
/// (#80, #82).
abstract final class CoachCopy {
  /// The "not medical advice" note for the coach screens (App Store 1.4.1;
  /// `docs/PRIVACY.md`).
  static const String notMedicalAdvice =
      "Steady's coach isn't medical advice and can't diagnose or treat "
      'anything. For questions about your health, talk to a doctor.';

  /// Where the coach points someone who mentions disordered eating,
  /// feeling out of control with food, or a crisis. The same numbers as
  /// [CoachInstructions.rules] and the cravings Settings card.
  static const String helpLine =
      "If food ever feels out of control, you don't have to sort it out "
      "alone. ANAD's free eating disorders helpline is open on weekdays at "
      '1-888-375-7767. In a crisis, call or text 988.';
}
