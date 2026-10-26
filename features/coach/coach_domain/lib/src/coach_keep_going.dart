import 'package:coach_domain/src/coach_context_budget.dart';

/// "Keep going": what happens to a coach reply cut off at the reply cap.
///
/// Every reply is capped at [coachMaxReplyTokens] (the channel's
/// `GenerationOptions.maximumResponseTokens`, so a reply that loops can't
/// fill the context). A reply that reaches the cap just stops, usually in
/// the middle of a sentence. The coach screens then:
///
/// 1. trim the reply, as shown and as stored, back to its last complete
///    sentence ([trim]);
/// 2. offer a "Keep going" button under it, which sends [prompt] as the
///    person's next turn and stores it as [message], so the transcript reads
///    as a short reply followed by the person's "Keep going".
///
/// Shared by every coach screen that streams replies: the chat (#80) and
/// the weekly session (#127).
///
/// **Detecting a cut-off ([wasCutOff]).** Foundation Models gives no stop
/// reason: neither `ResponseStream.Snapshot` nor `Response` has a finish
/// reason or a "hit the token limit" flag (checked in
/// `FoundationModels.swiftinterface`, iPhoneOS 27.1 SDK). What it does have,
/// from iOS 27 on, is the reply's output token count (`Snapshot.usage`),
/// which the channel forwards as `CoachReplySnapshot.outputTokens`. So a
/// reply counts as cut off when either:
///
/// - the model reports an output token count, and it reached the cap; or
/// - (the only test on iOS 26, which reports no count) the reply is long,
///   its token estimate ([estimateCoachTokens]) at least half the cap, and
///   it doesn't end at the end of a sentence.
///
/// The heuristic's threshold is half the cap, not the cap, because the
/// estimate's three characters per token over-counts prose but can
/// under-count text full of numbers and punctuation. A complete reply
/// that long and without closing punctuation is rare from a coach told to
/// keep replies short; the cost of a false positive is one unneeded
/// button. A reply that was cut exactly at a sentence end passes as
/// complete on iOS 26; nothing is lost but the button.
abstract final class CoachKeepGoing {
  /// The prompt "Keep going" sends. The model's own transcript still has
  /// the unfinished sentence that [trim] took off the stored reply, so it
  /// is asked to start again from there.
  static const String prompt =
      'Please go on from where you stopped. Start again at the sentence '
      "you didn't finish.";

  /// What the transcript stores and shows as the person's turn.
  static const String message = 'Keep going';

  /// Whether a reply that ended on its own (not stopped by the person, not
  /// failed) ended because it reached [cap]: see the class doc. [text] is
  /// the reply as generated, [outputTokens] the model's count, if any.
  static bool wasCutOff(
    String text, {
    int? outputTokens,
    int cap = coachMaxReplyTokens,
  }) {
    if (outputTokens != null && outputTokens >= cap) return true;
    final reply = text.trim();
    if (reply.isEmpty) return false;
    return estimateCoachTokens(reply) * 2 >= cap && !_endsASentence(reply);
  }

  /// [text] up to the end of its last complete sentence, or its last line
  /// break if that comes later (a list item is complete at its line's end).
  /// The whole of [text], trimmed, if neither is found.
  ///
  /// A sentence ends at `.`, `!`, `?`, `…` (or the CJK `。`, `！`, `？`),
  /// after any closing quotes or brackets, where whitespace or the end of
  /// the text follows (or anything, after a CJK one). A list number (`2.`
  /// at the start of a line) isn't a sentence end.
  static String trim(String text) {
    final reply = text.trimRight();
    var end = -1;
    var lineStart = 0;
    for (var i = 0; i < reply.length; i++) {
      final c = reply[i];
      if (c == '\n') {
        if (reply.substring(lineStart, i).trim().isNotEmpty) end = i;
        lineStart = i + 1;
        continue;
      }
      if (!_enders.contains(c)) continue;
      if (c == '.' && _isListNumber(reply.substring(lineStart, i))) continue;
      var j = i + 1;
      while (j < reply.length && _closers.contains(reply[j])) {
        j++;
      }
      // CJK runs sentences together with no space between them.
      if (j == reply.length || _isSpace(reply[j]) || _cjkEnders.contains(c)) {
        end = j;
      }
    }
    if (end <= 0) return reply.trim();
    final kept = reply.substring(0, end).trim();
    return kept.isEmpty ? reply.trim() : kept;
  }

  static bool _endsASentence(String reply) {
    var i = reply.length - 1;
    while (i >= 0 && _closers.contains(reply[i])) {
      i--;
    }
    return i >= 0 && _enders.contains(reply[i]);
  }

  static bool _isListNumber(String beforeDot) {
    final marker = beforeDot.trim();
    return marker.isNotEmpty &&
        marker.codeUnits.every((c) => c >= 48 && c <= 57);
  }

  static bool _isSpace(String c) => c.trim().isEmpty;

  static const Set<String> _cjkEnders = {'。', '！', '？'};

  static const Set<String> _enders = {'.', '!', '?', '…', ..._cjkEnders};

  static const Set<String> _closers = {
    '"',
    "'",
    '”',
    '’',
    '»',
    ')',
    ']',
    '）',
    '」',
    '』',
  };
}
