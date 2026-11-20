import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/src/first_stone.dart';
import 'package:onboarding_presentation/src/onboarding_copy.dart';
import 'package:onboarding_presentation/src/onboarding_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

// The ten screens' bodies (docs/design/onboarding.md, "The flow"). Each is
// one decision, kept as a draft in the screen's own state until Continue
// hands it to the controller; Skip hands nothing. `OnboardingModule` wires
// them to the controller and the app's callbacks.

/// Screen 1: place your first stone.
class FirstStoneScreen extends StatelessWidget {
  /// Creates screen 1.
  const FirstStoneScreen({
    required this.placed,
    required this.saveFailed,
    required this.onPlaced,
    required this.onContinue,
    required this.onSkip,
    super.key,
  });

  /// Whether the stone is on the ground.
  final bool placed;

  /// Whether the last save failed.
  final bool saveFailed;

  /// The stone landed.
  final VoidCallback onPlaced;

  /// Continue, once the stone is down.
  final VoidCallback onContinue;

  /// Skip.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.firstStoneTitle,
    reason: OnboardingCopy.firstStoneReason,
    saveFailed: saveFailed,
    primaryLabel: OnboardingCopy.continueLabel,
    onPrimary: placed ? onContinue : null,
    onSkip: onSkip,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FirstStone(placed: placed, onPlaced: onPlaced),
        const SizedBox(height: 12),
        Text(
          placed
              ? OnboardingCopy.firstStonePlaced
              : OnboardingCopy.firstStoneHint,
          textAlign: TextAlign.center,
          style: SteadyType.body,
        ),
      ],
    ),
  );
}

/// A one-answer question: screen 2 (how you track food) and screen 3
/// (where you heard about Steady).
class SingleChoiceScreen<T extends Enum> extends StatefulWidget {
  /// Creates a one-answer screen.
  const SingleChoiceScreen({
    required this.title,
    required this.reason,
    required this.options,
    required this.label,
    required this.initial,
    required this.saveFailed,
    required this.onAnswer,
    required this.onSkip,
    super.key,
  });

  /// The question.
  final String title;

  /// Why it's asked.
  final String reason;

  /// The answers, in order.
  final List<T> options;

  /// Each answer's row text.
  final String Function(T) label;

  /// The answer already given, if any.
  final T? initial;

  /// Whether the last save failed.
  final bool saveFailed;

  /// Continue, with the answer.
  final void Function(T) onAnswer;

  /// Skip.
  final VoidCallback onSkip;

  @override
  State<SingleChoiceScreen<T>> createState() => _SingleChoiceScreenState<T>();
}

class _SingleChoiceScreenState<T extends Enum>
    extends State<SingleChoiceScreen<T>> {
  late T? _choice = widget.initial;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: widget.title,
    reason: widget.reason,
    saveFailed: widget.saveFailed,
    primaryLabel: OnboardingCopy.continueLabel,
    onPrimary: switch (_choice) {
      final choice? => () => widget.onAnswer(choice),
      null => null,
    },
    onSkip: widget.onSkip,
    body: OnboardingChoiceList<T>(
      options: widget.options,
      label: widget.label,
      isSelected: (option) => option == _choice,
      onPressed: (option) => setState(() => _choice = option),
    ),
  );
}

/// Screen 4: Apple Health, with a sample of Today's tiles before the
/// system permission.
class HealthScreen extends StatelessWidget {
  /// Creates screen 4.
  const HealthScreen({
    required this.busy,
    required this.saveFailed,
    required this.onConnect,
    required this.onSkip,
    super.key,
  });

  /// Whether the app is asking for Apple Health right now.
  final bool busy;

  /// Whether the last save failed.
  final bool saveFailed;

  /// "Connect Apple Health": the app asks next.
  final VoidCallback onConnect;

  /// Skip.
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.healthTitle,
    reason: OnboardingCopy.healthReason,
    saveFailed: saveFailed,
    primaryLabel: OnboardingCopy.healthConnect,
    onPrimary: busy ? null : onConnect,
    onSkip: busy ? null : onSkip,
    body: const HealthPreview(),
  );
}

/// A static sample of Today's tiles, drawn with `ui_kit`'s [MetricTile]:
/// no Health data is read before the permission.
class HealthPreview extends StatelessWidget {
  /// Creates the sample.
  const HealthPreview({super.key});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const OnboardingGroupHeading(OnboardingCopy.healthPreviewCaption),
      const SizedBox(height: 10),
      Semantics(
        container: true,
        label: OnboardingCopy.healthPreviewCaption,
        child: const Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 8,
          children: [
            Expanded(
              child: MetricTile(
                label: 'Eaten',
                value: '1,840',
                unit: 'kcal',
                accent: MetricAccent.caloriesEaten,
                dailyValues: [1720, 2050, 1610, 1930, 1880, 2140, 1840],
              ),
            ),
            Expanded(
              child: MetricTile(
                label: 'Burned',
                value: '2,310',
                unit: 'kcal',
                accent: MetricAccent.caloriesBurned,
                dailyValues: [2240, 2410, 2180, 2290, 2360, 2520, 2310],
              ),
            ),
            Expanded(
              child: MetricTile(
                label: 'Steps',
                value: '7,412',
                accent: MetricAccent.steps,
                dailyValues: [6200, 9100, 5400, 8300, 7000, 10400, 7412],
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

/// Screen 5: your week. Activities (any) and weekends (one); either
/// answers it.
class WeekScreen extends StatefulWidget {
  /// Creates screen 5.
  const WeekScreen({
    required this.initial,
    required this.saveFailed,
    required this.onAnswer,
    required this.onSkip,
    super.key,
  });

  /// The answers already given.
  final AboutMe initial;

  /// Whether the last save failed.
  final bool saveFailed;

  /// Continue, with the answers.
  final void Function(Set<OnboardingActivity>, WeekendShape?) onAnswer;

  /// Skip.
  final VoidCallback onSkip;

  @override
  State<WeekScreen> createState() => _WeekScreenState();
}

class _WeekScreenState extends State<WeekScreen> {
  late final Set<OnboardingActivity> _activities = Set.of(
    widget.initial.activities,
  );
  late WeekendShape? _weekends = widget.initial.weekends;

  bool get _answered => _activities.isNotEmpty || _weekends != null;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.weekTitle,
    reason: OnboardingCopy.weekReason,
    saveFailed: widget.saveFailed,
    primaryLabel: OnboardingCopy.continueLabel,
    onPrimary: _answered
        ? () => widget.onAnswer(Set.of(_activities), _weekends)
        : null,
    onSkip: widget.onSkip,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const OnboardingGroupHeading(OnboardingCopy.activitiesHeading),
        const SizedBox(height: 10),
        OnboardingActivityChips(
          selected: _activities,
          onPressed: (activity) => setState(() {
            if (!_activities.remove(activity)) _activities.add(activity);
          }),
        ),
        const SizedBox(height: 28),
        const OnboardingGroupHeading(OnboardingCopy.weekendsHeading),
        const SizedBox(height: 10),
        OnboardingChoiceList<WeekendShape>(
          options: WeekendShape.values,
          label: OnboardingCopy.weekends,
          isSelected: (weekends) => weekends == _weekends,
          // Tapping the chosen one again clears it: the activities alone
          // can answer the screen.
          onPressed: (weekends) => setState(
            () => _weekends = _weekends == weekends ? null : weekends,
          ),
        ),
      ],
    ),
  );
}

/// Screen 6: what gets in the way. Any number.
class HardPartsScreen extends StatefulWidget {
  /// Creates screen 6.
  const HardPartsScreen({
    required this.initial,
    required this.saveFailed,
    required this.onAnswer,
    required this.onSkip,
    super.key,
  });

  /// The answers already given.
  final Set<HardPart> initial;

  /// Whether the last save failed.
  final bool saveFailed;

  /// Continue, with the answers.
  final void Function(Set<HardPart>) onAnswer;

  /// Skip.
  final VoidCallback onSkip;

  @override
  State<HardPartsScreen> createState() => _HardPartsScreenState();
}

class _HardPartsScreenState extends State<HardPartsScreen> {
  late final Set<HardPart> _parts = Set.of(widget.initial);

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.hardPartsTitle,
    reason: OnboardingCopy.hardPartsReason,
    saveFailed: widget.saveFailed,
    primaryLabel: OnboardingCopy.continueLabel,
    onPrimary: _parts.isEmpty ? null : () => widget.onAnswer(Set.of(_parts)),
    onSkip: widget.onSkip,
    body: OnboardingChoiceList<HardPart>(
      options: HardPart.values,
      label: OnboardingCopy.hardPart,
      multiSelect: true,
      isSelected: _parts.contains,
      onPressed: (part) => setState(() {
        if (!_parts.remove(part)) _parts.add(part);
      }),
    ),
  );
}

/// Screen 7: the coach's voice, with the coach answering "I skipped
/// logging Saturday" in the chosen voice (text in the app, no network).
/// Marked paid.
class VoiceScreen extends StatefulWidget {
  /// Creates screen 7.
  const VoiceScreen({
    required this.initial,
    required this.saveFailed,
    required this.onAnswer,
    required this.onSkip,
    super.key,
  });

  /// The voice already chosen, if any.
  final CoachVoice? initial;

  /// Whether the last save failed.
  final bool saveFailed;

  /// Continue, with the voice.
  final void Function(CoachVoice) onAnswer;

  /// Skip.
  final VoidCallback onSkip;

  @override
  State<VoiceScreen> createState() => _VoiceScreenState();
}

class _VoiceScreenState extends State<VoiceScreen> {
  late CoachVoice? _voice = widget.initial;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.voiceTitle,
    reason: OnboardingCopy.voiceReason,
    paid: true,
    saveFailed: widget.saveFailed,
    primaryLabel: OnboardingCopy.continueLabel,
    onPrimary: switch (_voice) {
      final voice? => () => widget.onAnswer(voice),
      null => null,
    },
    onSkip: widget.onSkip,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingChoiceList<CoachVoice>(
          options: CoachVoice.values,
          label: OnboardingCopy.voice,
          detail: OnboardingCopy.voiceDetail,
          isSelected: (voice) => voice == _voice,
          onPressed: (voice) => setState(() => _voice = voice),
        ),
        if (_voice case final voice?) ...[
          const SizedBox(height: 24),
          const OnboardingBubble(
            text: OnboardingCopy.sampleSituation,
            speaker: OnboardingCopy.sampleYou,
            fromCoach: false,
          ),
          const SizedBox(height: 8),
          OnboardingBubble(
            key: const Key('onboardingSampleReply'),
            text: OnboardingCopy.sampleReply(voice),
            speaker: OnboardingCopy.sampleCoach,
            fromCoach: true,
          ),
        ],
      ],
    ),
  );
}

/// Screen 8: meet the coach. A short intro, the optional note, and the
/// button that opens the coach's consent screen. Marked paid.
class MeetCoachScreen extends StatefulWidget {
  /// Creates screen 8.
  const MeetCoachScreen({
    required this.initialNote,
    required this.busy,
    required this.saveFailed,
    required this.onTurnOn,
    required this.onSkip,
    super.key,
  });

  /// The note already left, if any.
  final String? initialNote;

  /// Whether the consent screen is showing.
  final bool busy;

  /// Whether the last save failed.
  final bool saveFailed;

  /// "Turn on the coach", with the note as typed.
  final void Function(String note) onTurnOn;

  /// Skip: no consent asked, no note saved.
  final VoidCallback onSkip;

  @override
  State<MeetCoachScreen> createState() => _MeetCoachScreenState();
}

class _MeetCoachScreenState extends State<MeetCoachScreen> {
  late final TextEditingController _note = TextEditingController(
    text: widget.initialNote ?? '',
  );

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.meetCoachTitle,
    reason: OnboardingCopy.meetCoachReason,
    paid: true,
    saveFailed: widget.saveFailed,
    primaryLabel: OnboardingCopy.turnOnCoach,
    onPrimary: widget.busy ? null : () => widget.onTurnOn(_note.text),
    onSkip: widget.busy ? null : widget.onSkip,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(OnboardingCopy.meetCoachIntro, style: SteadyType.body),
        const SizedBox(height: 28),
        const OnboardingGroupHeading(OnboardingCopy.noteLabel),
        const SizedBox(height: 10),
        AboutMeNoteField(
          fieldKey: const Key('onboardingNote'),
          controller: _note,
          enabled: !widget.busy,
        ),
      ],
    ),
  );
}

/// Screen 9: your first week, two or three small suggestions built from
/// the answers.
class FirstWeekScreen extends StatelessWidget {
  /// Creates screen 9.
  const FirstWeekScreen({
    required this.suggestions,
    required this.saveFailed,
    required this.onContinue,
    super.key,
  });

  /// The suggestions to show (`firstWeekSuggestions`).
  final List<String> suggestions;

  /// Whether the last save failed.
  final bool saveFailed;

  /// "Sounds good".
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.firstWeekTitle,
    reason: OnboardingCopy.firstWeekReason,
    saveFailed: saveFailed,
    primaryLabel: OnboardingCopy.firstWeekContinue,
    onPrimary: onContinue,
    body: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: 10,
      children: [
        for (final (i, suggestion) in suggestions.indexed)
          GlassCard(
            key: Key('onboardingSuggestion_$i'),
            child: Text(
              suggestion,
              style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
            ),
          ),
      ],
    ),
  );
}

/// Screen 10: the stones placed so far, and the next one still to come.
class CairnScreen extends StatelessWidget {
  /// Creates screen 10.
  const CairnScreen({
    required this.stones,
    required this.busy,
    required this.saveFailed,
    required this.onFinish,
    super.key,
  });

  /// The cairn: every step's stone, then tonight's, pending.
  final List<OnboardingStone> stones;

  /// Whether finishing is being saved.
  final bool busy;

  /// Whether the last save failed.
  final bool saveFailed;

  /// "Go to Today".
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) => OnboardingPage(
    title: OnboardingCopy.cairnTitle,
    reason: OnboardingCopy.cairnNext,
    saveFailed: saveFailed,
    primaryLabel: OnboardingCopy.goToToday,
    onPrimary: busy ? null : onFinish,
    body: Column(
      children: [
        const SizedBox(height: 12),
        OnboardingCairn(key: const Key('onboardingFinalCairn'), stones: stones),
        if (stones.contains(OnboardingStone.dimmed)) ...[
          const SizedBox(height: 24),
          const Text(
            OnboardingCopy.cairnSkipped,
            textAlign: TextAlign.center,
            style: SteadyType.body,
          ),
        ],
      ],
    ),
  );
}
