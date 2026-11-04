/// The longest message the person can send, in characters (Unicode code
/// points). The message box enforces it, and [clampCoachMessage] cuts
/// anything longer. The proxy enforces the same cap on every person turn
/// (1 to 1,000 code points): it bounds cost and abuse.
const int coachMaxMessageChars = 1000;

/// [message], trimmed and cut to [coachMaxMessageChars] code points.
String clampCoachMessage(String message) {
  final trimmed = message.trim();
  return trimmed.runes.length <= coachMaxMessageChars
      ? trimmed
      : String.fromCharCodes(trimmed.runes.take(coachMaxMessageChars));
}
