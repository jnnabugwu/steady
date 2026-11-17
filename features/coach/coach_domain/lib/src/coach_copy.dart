/// User-facing coach copy the screens show, kept in one place (#80, #82).
///
/// The coach's instructions and guardrails live on the proxy now
/// (`jnnabugwu/steady-backend`, `src/coach/instructions.ts`, with a test per
/// constraint), so a fix ships without App Review. [helpLine]'s numbers are
/// the ones the proxy's instructions point to, and the proxy's tests check
/// its copy of this line word for word.
abstract final class CoachCopy {
  /// The "not medical advice" note for the coach screens (App Store 1.4.1;
  /// `docs/PRIVACY.md`): on the Coach tab and at the top of every live
  /// session.
  static const String notMedicalAdvice =
      "Steady's coach isn't medical advice and can't diagnose or treat "
      'anything. For questions about your health, talk to a doctor.';

  /// Where the coach points someone who mentions disordered eating,
  /// feeling out of control with food, or a crisis. Shown when the model
  /// refuses a reply (`CoachRefusalFailure`). The same numbers as the
  /// proxy's instructions and the cravings Settings card.
  static const String helpLine =
      "If food ever feels out of control, you don't have to sort it out "
      "alone. ANAD's free eating disorders helpline is open on weekdays at "
      '1-888-375-7767. In a crisis, call or text 988.';
}
