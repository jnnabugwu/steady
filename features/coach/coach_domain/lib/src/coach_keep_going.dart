/// "Keep going": what the coach screens offer under a reply that was cut off
/// at the proxy's token limit.
///
/// The proxy says when that happened: the reply's last snapshot carries
/// `CoachStopReason.maxTokens`. The reply is shown and stored as it came,
/// and a "Keep going" button under it sends [prompt] as the person's next
/// turn and stores it as [message], so the transcript reads as the reply
/// followed by the person's "Keep going".
///
/// With a generous token limit and replies kept short by the instructions, a
/// cut-off should be rare. Whether the button stays is an open decision
/// (#152); removing it means deleting this class, `keepGoing` and
/// `CoachSessionState.replyCutOff`, and the button in `CoachSessionModule`.
abstract final class CoachKeepGoing {
  /// The person's turn "Keep going" sends.
  static const String prompt =
      'Please go on from where you stopped. Start again at the sentence '
      "you didn't finish.";

  /// What the transcript stores and shows as the person's turn.
  static const String message = 'Keep going';
}
