import 'package:coach_domain/src/coach_instructions.dart';
import 'package:coach_domain/src/coach_session.dart';

/// The most tokens one coach reply may use. The `steady/coach` channel
/// sends it with every reply (Foundation Models' `GenerationOptions`); the
/// budget below reserves this much room for every reply, so a reply can
/// never be what overflows a session.
const int coachMaxReplyTokens = 512;

/// A deliberately high estimate of how many tokens [text] takes.
///
/// Apple's SDK docs put English at about three to four characters per
/// token, so Latin text is counted at three characters per token: the safe
/// side, since a session that fits this estimate fits the model.
///
/// Three per token only holds for Latin script, though. CJK, Hangul, emoji
/// and the rest are split far more finely — often a token per character or
/// more — so dividing every code point by three would *under*-count them
/// threefold and let a turn through that the model then rejects. Anything
/// outside the Latin range is therefore counted as a whole token each.
/// That over-counts Greek and Cyrillic, which is again the safe side: a
/// conversation in them moves to a fresh session sooner than it strictly
/// must, rather than overflowing.
///
/// Counted in Unicode code points, so an emoji or an accented letter isn't
/// counted as several characters.
int estimateCoachTokens(String text) {
  final (:latin, :dense) = _runeCounts(text);
  return _tokensFor(latin, dense);
}

/// [text]'s Latin and non-Latin code points. Additive: the counts of a
/// joined text are the sums of its parts', which is what lets
/// [coachSummaryPrompt] fit a transcript in one pass.
({int latin, int dense}) _runeCounts(String text) {
  var latin = 0;
  var dense = 0;
  for (final rune in text.runes) {
    if (rune < _firstNonLatinRune) {
      latin++;
    } else {
      dense++;
    }
  }
  return (latin: latin, dense: dense);
}

int _tokensFor(int latin, int dense) => (latin / 3).ceil() + dense;

/// The first code point past Basic Latin, Latin-1, Latin Extended-A/B and
/// IPA extensions — i.e. where "about three characters per token" stops
/// being a safe assumption. See [estimateCoachTokens].
const int _firstNonLatinRune = 0x0370;

/// Tokens for the role markers the model's transcript wraps every prompt
/// and every reply in. A guess on the high side; the margin covers the
/// rest.
const int coachTurnOverheadTokens = 8;

/// How much of the on-device model's context window a coach session can
/// use (CLAUDE.md §11).
///
/// Everything in one model session shares [contextSize] (4,096 tokens on
/// iOS 26; read from the device as `CoachModelInfo.contextSize`): the
/// instructions with the week's data, every prompt and every reply. A turn
/// is only sent when its prompt, a full-length reply ([replyTokens]) and a
/// safety [marginTokens] still fit on top of what the session already
/// holds; otherwise the conversation moves to a fresh session first
/// (`CoachConversation`).
class CoachContextBudget {
  /// Creates the budget for a model whose context window is [contextSize]
  /// tokens.
  const CoachContextBudget({
    required this.contextSize,
    this.replyTokens = coachMaxReplyTokens,
    this.marginTokens = 256,
  });

  /// The model's whole context window, in tokens.
  final int contextSize;

  /// Room kept free for one reply: the channel's reply cap.
  final int replyTokens;

  /// Extra room kept free, for estimates that come out low.
  final int marginTokens;

  /// Whether a prompt of [prompt] fits in a session that already holds
  /// [sessionTokens], with room left for a full reply.
  bool fitsTurn({required int sessionTokens, required String prompt}) =>
      sessionTokens + turnCost(prompt) <= contextSize;

  /// What sending [prompt] adds to a session, a full-length reply included.
  int turnCost(String prompt) =>
      estimateCoachTokens(prompt) +
      2 * coachTurnOverheadTokens +
      replyTokens +
      marginTokens;

  /// How many tokens of prompt (by [estimateCoachTokens]) fit in a session
  /// that holds only [instructionTokens] (a fresh one), with room left for
  /// a full reply. Never negative.
  ///
  /// Tokens, not characters: a character allowance at the Latin rate would
  /// let a CJK, Hangul or emoji prompt through at three times what fits.
  int promptRoomTokens(int instructionTokens) {
    final tokens =
        contextSize -
        instructionTokens -
        2 * coachTurnOverheadTokens -
        replyTokens -
        marginTokens;
    return tokens <= 0 ? 0 : tokens;
  }
}

/// The longest message the person can send, in characters (about 330
/// tokens). The message box enforces it, and the conversation truncates
/// anything longer, so one message can't crowd out the rest of a session.
const int coachMaxMessageChars = 1000;

/// The most characters of an earlier-conversation summary carried into a
/// fresh model session.
const int coachMaxCarriedSummaryChars = 600;

/// The most characters of recent messages carried, word for word, into a
/// fresh model session.
const int coachMaxCarriedMessagesChars = 900;

/// The live conversation's bookkeeping: what the current model session
/// holds, and what was summarised away to keep it inside the budget.
///
/// Pure: it decides, and the controller calls the model. The flow per turn:
///
/// 1. [needsFreshSession] for the person's message. If `true`, summarise
///    [toSummarise] (with the model, in a separate session), start a new
///    model session with the same [instructions], and continue with
///    [afterFreshSession] (the summary, or `null` to drop those turns).
/// 2. Send [promptFor] the message. A fresh session's first prompt carries
///    the summary and the last few messages word for word; after that a
///    prompt is just the message.
/// 3. [afterTurn] with the prompt that was sent and the reply.
///
/// A session can never overflow: a turn is sent only when
/// [CoachContextBudget.fitsTurn] says so, and a fresh session's first
/// prompt is bounded ([coachMaxCarriedSummaryChars],
/// [coachMaxCarriedMessagesChars], [coachMaxMessageChars]).
class CoachConversation {
  /// Starts the bookkeeping for a new model session primed with
  /// [instructions].
  CoachConversation.start({required this.instructions})
    : earlierSummary = null,
      window = const [],
      carry = null,
      sessionTokens = estimateCoachTokens(instructions);

  const CoachConversation._({
    required this.instructions,
    required this.earlierSummary,
    required this.window,
    required this.carry,
    required this.sessionTokens,
  });

  /// The model session's instructions: the session kind's instructions
  /// with the person's data. The same for every model session in the
  /// conversation.
  final String instructions;

  /// A summary of the turns no longer in the model session, or `null` if
  /// none were dropped (or they were dropped without a summary).
  final String? earlierSummary;

  /// The messages the current model session has seen, oldest first.
  final List<CoachMessage> window;

  /// Context to put in front of the next prompt (a fresh session's
  /// summary and recent messages), or `null`.
  final String? carry;

  /// The estimated tokens the current model session holds.
  final int sessionTokens;

  /// [message], cut to [coachMaxMessageChars].
  static String clampMessage(String message) {
    final trimmed = message.trim();
    return trimmed.runes.length <= coachMaxMessageChars
        ? trimmed
        : String.fromCharCodes(trimmed.runes.take(coachMaxMessageChars));
  }

  /// The prompt to send for the person's [message]: the message itself, or,
  /// first in a fresh session, the carried context followed by it.
  ///
  /// With [fromApp], [message] is the app's own prompt (the weekly
  /// session's opening or its next topic): it isn't clamped, and follows
  /// the carried context as is.
  String promptFor(String message, {bool fromApp = false}) {
    final carried = carry;
    if (fromApp) return carried == null ? message : '$carried\n\n$message';
    final text = clampMessage(message);
    if (carried == null) return text;
    return '$carried\n\nThe person now says:\n$text';
  }

  /// Whether [message] (the app's own with [fromApp]) has to go to a fresh
  /// model session because it wouldn't fit, with a full reply, in the
  /// current one.
  bool needsFreshSession(
    String message,
    CoachContextBudget budget, {
    bool fromApp = false,
  }) => !budget.fitsTurn(
    sessionTokens: sessionTokens,
    prompt: promptFor(message, fromApp: fromApp),
  );

  /// The messages to summarise before moving to a fresh session: every
  /// message in the window except the ones carried word for word.
  List<CoachMessage> get toSummarise =>
      window.sublist(0, window.length - _carriedMessages.length);

  /// The last messages of the window that fit in
  /// [coachMaxCarriedMessagesChars] (at most four), each cut to 400
  /// characters.
  List<CoachMessage> get _carriedMessages {
    final carried = <CoachMessage>[];
    var chars = 0;
    for (final message in window.reversed) {
      final text = _cut(message.text, 400);
      // Runes, like `_cut` and every other cap here: counting UTF-16 code
      // units would spend the allowance twice as fast on emoji and other
      // surrogate pairs, dropping recent context for no reason.
      final length = text.runes.length;
      if (carried.length == 4 ||
          chars + length > coachMaxCarriedMessagesChars) {
        break;
      }
      chars += length;
      carried.insert(0, message.copyWith(text: text));
    }
    return carried;
  }

  /// The conversation in a fresh model session (its token count is just
  /// the instructions'), carrying [summary] of [toSummarise] (or, when
  /// `null`, the previous [earlierSummary]) and the last few messages into
  /// its first prompt.
  CoachConversation afterFreshSession(String? summary) {
    final kept = _carriedMessages;
    final newSummary = summary == null
        ? earlierSummary
        : _cut(summary.trim(), coachMaxCarriedSummaryChars);
    final parts = [
      if (newSummary != null && newSummary.isNotEmpty)
        'Earlier in this conversation (a summary):\n$newSummary',
      if (kept.isNotEmpty) 'The last messages:\n${coachTranscriptLines(kept)}',
    ];
    return CoachConversation._(
      instructions: instructions,
      earlierSummary: newSummary,
      window: kept,
      carry: parts.isEmpty ? null : parts.join('\n\n'),
      sessionTokens: estimateCoachTokens(instructions),
    );
  }

  /// The conversation after [prompt] was sent for [message] and [reply]
  /// came back (the reply may be partial if it was stopped, or empty).
  CoachConversation afterTurn({
    required String prompt,
    required CoachMessage message,
    required CoachMessage? reply,
  }) => CoachConversation._(
    instructions: instructions,
    earlierSummary: earlierSummary,
    window: [...window, message, ?reply],
    carry: null,
    sessionTokens:
        sessionTokens +
        estimateCoachTokens(prompt) +
        estimateCoachTokens(reply?.text ?? '') +
        2 * coachTurnOverheadTokens,
  );

  /// The conversation with nothing carried into the next prompt and an
  /// empty window: for a fresh session whose carried context still
  /// wouldn't fit (a very small context window), or a retry after the
  /// model said the context was exceeded.
  CoachConversation withoutCarry() => CoachConversation._(
    instructions: instructions,
    earlierSummary: earlierSummary,
    window: const [],
    carry: null,
    sessionTokens: estimateCoachTokens(instructions),
  );

  /// The prompt for the session's end summary of [all] the messages: the
  /// whole transcript if it fits a fresh summary session
  /// ([CoachInstructions.summary]), otherwise [earlierSummary] and the
  /// current window (oldest dropped first). `null` if there's nothing to
  /// summarise.
  String? summaryPromptFor(
    List<CoachMessage> all, {
    required String request,
    required CoachContextBudget budget,
  }) {
    final whole = coachSummaryPrompt(
      request: request,
      messages: all,
      budget: budget,
    );
    if (whole != null && whole.contains(coachTranscriptLines(all))) {
      return whole;
    }
    return coachSummaryPrompt(
      request: request,
      messages: window,
      earlierSummary: earlierSummary,
      budget: budget,
    );
  }

  /// The conversation after the app itself prompted the coach ([prompt],
  /// e.g. the weekly session's opening or its move to the next topic) and
  /// it said [reply]. The prompt isn't one of the person's messages, so
  /// only the reply joins the window.
  CoachConversation afterAppPrompt({
    required String prompt,
    required CoachMessage? reply,
  }) => CoachConversation._(
    instructions: instructions,
    earlierSummary: earlierSummary,
    window: [...window, ?reply],
    carry: null,
    sessionTokens:
        sessionTokens +
        estimateCoachTokens(prompt) +
        estimateCoachTokens(reply?.text ?? '') +
        2 * coachTurnOverheadTokens,
  );

  static String _cut(String text, int max) {
    if (text.runes.length <= max) return text;
    return '${String.fromCharCodes(text.runes.take(max - 1))}…';
  }
}

/// [messages] as plain lines, "Person: …" and "Coach: …", for the model.
String coachTranscriptLines(Iterable<CoachMessage> messages) => [
  for (final m in messages)
    '${m.role == CoachMessageRole.user ? 'Person' : 'Coach'}: ${m.text}',
].join('\n');

/// The prompt asking the model for a short, neutral summary of a
/// conversation, sent in a separate model session primed with
/// [CoachInstructions.summary].
///
/// The transcript is [earlierSummary] (if any) followed by [messages],
/// keeping the newest messages that fit a fresh session under [budget]
/// after [instructionTokens] (by default the summary instructions'), by
/// [estimateCoachTokens]. Returns `null` if there's nothing to summarise.
String? coachSummaryPrompt({
  required String request,
  required List<CoachMessage> messages,
  required CoachContextBudget budget,
  int? instructionTokens,
  String? earlierSummary,
}) {
  if (messages.isEmpty && (earlierSummary == null || earlierSummary.isEmpty)) {
    return null;
  }
  final room = budget.promptRoomTokens(
    instructionTokens ?? estimateCoachTokens(CoachInstructions.summary),
  );
  final head = [
    request,
    if (earlierSummary != null && earlierSummary.isNotEmpty)
      'Summary of the start of the conversation:\n$earlierSummary',
  ].join('\n\n');
  const transcriptHeader = '\n\nThe conversation:\n';
  // One pass, newest first, then one build. Rune counts add up, so the
  // running counts give the joined prompt's estimate exactly: the newest
  // messages that fit are kept, and no more.
  var (:latin, :dense) = _runeCounts('$head$transcriptHeader');
  var first = messages.length;
  for (var i = messages.length - 1; i >= 0; i--) {
    final line = _runeCounts(coachTranscriptLines([messages[i]]));
    // Every line after the first adds the newline that joins it.
    final newline = first == messages.length ? 0 : 1;
    final nextLatin = latin + line.latin + newline;
    final nextDense = dense + line.dense;
    if (_tokensFor(nextLatin, nextDense) > room) break;
    latin = nextLatin;
    dense = nextDense;
    first = i;
  }
  final kept = messages.sublist(first);
  final prompt = kept.isEmpty
      ? head
      : '$head$transcriptHeader${coachTranscriptLines(kept)}';
  return _takeTokens(prompt, room);
}

/// The longest start of [text] whose [estimateCoachTokens] is at most
/// [maxTokens]: [text] itself if it fits.
String _takeTokens(String text, int maxTokens) {
  if (estimateCoachTokens(text) <= maxTokens) return text;
  var latin = 0;
  var dense = 0;
  final kept = <int>[];
  for (final rune in text.runes) {
    if (rune < _firstNonLatinRune) {
      latin++;
    } else {
      dense++;
    }
    if (_tokensFor(latin, dense) > maxTokens) break;
    kept.add(rune);
  }
  return String.fromCharCodes(kept);
}
