// PROTOTYPE, throwaway. Branch `prototype/onboarding`; never merge to main.
//
// Question: what should Steady's first-run onboarding feel like?
// Three structurally different variants of the same 7 steps, each answer
// dropping a stone onto the cairn. Answers live in memory only and are
// shared across variants, so flipping variants keeps your progress.
//
// Run: cd app && flutter run -t lib/prototype_onboarding/main_prototype_onboarding.dart
// Switch variants with the floating bar at the bottom; "{ }" shows the state.

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

void main() => runApp(
  ShadcnApp(
    title: 'Onboarding prototype',
    theme: steadyTheme,
    debugShowCheckedModeBanner: false,
    home: const _PrototypeRoot(),
  ),
);

// --- shared state -------------------------------------------------------------

enum Step { welcome, tracking, health, week, hardParts, voice, coach }

const stepNames = {
  Step.welcome: 'Welcome',
  Step.tracking: 'Tracking',
  Step.health: 'Apple Health',
  Step.week: 'Your week',
  Step.hardParts: 'What gets in the way',
  Step.voice: 'Coach voice',
  Step.coach: 'Meet the coach',
};

const trackingOptions = [
  'Cal AI',
  'Another app that writes to Apple Health',
  "I'm just starting",
];
const activityOptions = ['Tennis', 'Gym', 'Walks', 'Runs', 'Yoga', 'Other'];
const weekendOptions = ['Busier', 'Quieter', 'All over the place'];
const hardPartOptions = [
  'Eating out',
  'Late nights',
  'Weekends',
  'Forgetting',
  'Travel',
  'Feeling judged',
];
const voiceOptions = ['Gentle', 'Direct', 'Playful'];

const sampleSituation = 'I skipped logging Saturday.';
const sampleReplies = {
  'Gentle':
      "Saturdays are often the hardest day to log, and one quiet day doesn't "
      'undo the rest of your week. Want to pick one small thing that would '
      'make next Saturday easier?',
  'Direct':
      "One skipped Saturday is a gap, not a problem. What got in the way: "
      "plans, or just forgetting? Let's pick one fix for next Saturday.",
  'Playful':
      'Saturday went off the map! Happens to the best of us, and weekends '
      'are sneaky. Want to try a ten-second log right after you get home?',
};

class Answers extends ChangeNotifier {
  int current = 0;
  bool finished = false;

  /// Per step: answered (logged), skipped, or not reached yet (null).
  final statuses = List<LoggingStatus?>.filled(Step.values.length, null);

  String? tracking;
  bool healthConnected = false;
  final activities = <String>{};
  String? weekends;
  final hardParts = <String>{};
  String? voice;
  bool coachOn = false;
  String note = '';

  Step get step => Step.values[current];

  void update(VoidCallback change) {
    change();
    notifyListeners();
  }

  /// Answer the current step: its stone drops, then (after the drop) move on.
  Future<void> answer() async {
    final at = current;
    update(() => statuses[at] = LoggingStatus.logged);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (current == at) _advance();
  }

  /// Skip the current step: it still gets a stone, a dimmer one.
  Future<void> skip() async {
    final at = current;
    update(() => statuses[at] = LoggingStatus.skipped);
    await Future<void>.delayed(const Duration(milliseconds: 650));
    if (current == at) _advance();
  }

  void _advance() => update(() {
    if (current < Step.values.length - 1) {
      current++;
    } else {
      finished = true;
    }
  });

  void restart() => update(() {
    current = 0;
    finished = false;
    statuses.fillRange(0, statuses.length, null);
    tracking = null;
    healthConnected = false;
    activities.clear();
    weekends = null;
    hardParts.clear();
    voice = null;
    coachOn = false;
    note = '';
  });

  /// What the proxy would get as `aboutMe` (the spec's structured shape).
  Map<String, Object?> get aboutMe => {
    'voice': voice?.toLowerCase(),
    'tracking': tracking,
    'activities': activities.toList(),
    'weekends': weekends,
    'hardParts': hardParts.toList(),
    'note': note.isEmpty ? null : note,
  };

  String get dump => [
    'step: ${current + 1}/7 ${stepNames[step]}${finished ? ' (finished)' : ''}',
    'stones: ${[for (final s in statuses) s?.name ?? '-'].join(', ')}',
    'healthConnected: $healthConnected, coachOn: $coachOn',
    'aboutMe: $aboutMe',
  ].join('\n');
}

/// The 7 steps as a cairn: answered and skipped steps are stones, the
/// current one is "today" (its stone drops in when answered), later ones
/// are still to come.
Widget onboardingCairn(Answers a, {double width = 150}) {
  final today = a.finished ? Step.values.length - 1 : a.current;
  return CairnWeek(
    width: width,
    days: [
      for (final (i, s) in Step.values.indexed)
        CairnDay(
          label: '${i + 1}',
          fullName: stepNames[s]!,
          status: a.statuses[i],
          isToday: i == today,
        ),
    ],
  );
}

// --- shared bits --------------------------------------------------------------

class ChoiceChip extends StatelessWidget {
  const ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: selected
            ? SteadyColors.coachCardFill
            : SteadyColors.glassControlFill,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: selected
              ? SteadyColors.accentTeal
              : SteadyColors.glassControlBorder,
        ),
      ),
      child: Text(
        label,
        style: SteadyType.body.copyWith(
          color: selected ? SteadyColors.textPrimary : SteadyColors.textSecondary,
        ),
      ),
    ),
  );
}

Widget chips(
  List<String> options,
  bool Function(String) isSelected,
  void Function(String) onTap,
) => Wrap(
  spacing: 8,
  runSpacing: 8,
  children: [
    for (final o in options)
      ChoiceChip(label: o, selected: isSelected(o), onTap: () => onTap(o)),
  ],
);

Widget eyebrow(String text) =>
    Text(text.toUpperCase(), style: SteadyType.eyebrow);

Widget title(String text, {double size = 28}) =>
    Text(text, style: SteadyType.headline.copyWith(fontSize: size));

Widget body(String text) => Text(text, style: SteadyType.body);

Widget sampleBubble(String voice) => Container(
  padding: const EdgeInsets.all(14),
  decoration: BoxDecoration(
    color: SteadyColors.coachCardFill,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: SteadyColors.coachCardBorder),
  ),
  child: Text(
    sampleReplies[voice]!,
    style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
  ),
);

/// Each step's question content, used by variants A and C.
Widget stepContent(Answers a, Step s) => switch (s) {
  Step.welcome => body(
    'Log more days, without the guilt. A few quick questions so the coach '
    'knows how your weeks go. Skip any of them.',
  ),
  Step.tracking => chips(
    trackingOptions,
    (o) => a.tracking == o,
    (o) => a.update(() => a.tracking = o),
  ),
  Step.health => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      body(
        'Steps and calories eaten come from Apple Health. They stay on this '
        'iPhone and are never stored in iCloud.',
      ),
      const SizedBox(height: 16),
      OutlineButton(
        onPressed: () => a.update(() => a.healthConnected = true),
        child: Text(
          a.healthConnected ? 'Connected (pretend)' : 'Connect Apple Health',
        ),
      ),
    ],
  ),
  Step.week => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      eyebrow('What keeps you moving'),
      const SizedBox(height: 8),
      chips(
        activityOptions,
        a.activities.contains,
        (o) => a.update(
          () => a.activities.contains(o)
              ? a.activities.remove(o)
              : a.activities.add(o),
        ),
      ),
      const SizedBox(height: 20),
      eyebrow('My weekends are'),
      const SizedBox(height: 8),
      chips(
        weekendOptions,
        (o) => a.weekends == o,
        (o) => a.update(() => a.weekends = o),
      ),
    ],
  ),
  Step.hardParts => chips(
    hardPartOptions,
    a.hardParts.contains,
    (o) => a.update(
      () => a.hardParts.contains(o) ? a.hardParts.remove(o) : a.hardParts.add(o),
    ),
  ),
  Step.voice => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      chips(
        voiceOptions,
        (o) => a.voice == o,
        (o) => a.update(() => a.voice = o),
      ),
      const SizedBox(height: 16),
      Text('You: “$sampleSituation”', style: SteadyType.body),
      const SizedBox(height: 8),
      sampleBubble(a.voice ?? 'Gentle'),
    ],
  ),
  Step.coach => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      body(
        'A 5-minute check-in each week, and a chat whenever you want one. '
        "It asks before it sends anything (here's where the consent screen "
        'would open).',
      ),
      const SizedBox(height: 16),
      NoteField(answers: a),
    ],
  ),
};

const stepTitles = {
  Step.welcome: 'Steady',
  Step.tracking: 'How do you track what you eat?',
  Step.health: 'Connect Apple Health',
  Step.week: 'What does your week look like?',
  Step.hardParts: 'What gets in the way of logging?',
  Step.voice: 'How should your coach talk to you?',
  Step.coach: 'Meet your coach',
};

class NoteField extends StatefulWidget {
  const NoteField({required this.answers, super.key});
  final Answers answers;

  @override
  State<NoteField> createState() => _NoteFieldState();
}

class _NoteFieldState extends State<NoteField> {
  late final controller = TextEditingController(text: widget.answers.note);

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    placeholder: const Text('Anything else the coach should know? (optional)'),
    maxLines: 3,
    maxLength: 200,
    maxLengthEnforcement: MaxLengthEnforcement.enforced,
    onChanged: (v) => widget.answers.note = v,
  );
}

String primaryLabel(Step s) => switch (s) {
  Step.welcome => "Let's start",
  Step.coach => 'Turn on the coach',
  _ => 'Next',
};

void primaryAction(Answers a) {
  if (a.step == Step.coach) a.coachOn = true;
  a.answer();
}

// --- variant A: one question per screen, the cairn on top ---------------------

class VariantA extends StatelessWidget {
  const VariantA({required this.answers, super.key});
  final Answers answers;

  @override
  Widget build(BuildContext context) {
    final a = answers;
    if (a.finished) return FinishScreen(answers: a);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 96),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                eyebrow('Step ${a.current + 1} of 7'),
                const Spacer(),
                if (a.step != Step.welcome)
                  GhostButton(onPressed: a.skip, child: const Text('Skip')),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: onboardingCairn(a, width: 140)),
            const SizedBox(height: 28),
            title(stepTitles[a.step]!),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(child: stepContent(a, a.step)),
            ),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                onPressed: () => primaryAction(a),
                child: Center(child: Text(primaryLabel(a.step))),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- variant B: a conversation with the coach --------------------------------

class VariantB extends StatelessWidget {
  const VariantB({required this.answers, super.key});
  final Answers answers;

  static const _questions = {
    Step.welcome:
        "Hi, I'm your Steady coach. I'm here to help you log more days, "
        'without the guilt. Mind if I ask a few quick things?',
    Step.tracking: 'First: how do you track what you eat?',
    Step.health:
        'Steady can read steps and calories eaten from Apple Health. They '
        'stay on your iPhone. Want to connect it?',
    Step.week: 'What keeps you moving? And are your weekends busier or quieter?',
    Step.hardParts: 'What usually gets in the way of logging?',
    Step.voice:
        "How should I talk to you? Pick one and I'll show you how I'd answer "
        '“$sampleSituation”',
    Step.coach:
        "Last thing: anything else I should know? Then I'll ask before I "
        'send anything, every time.',
  };

  String? _answerText(Answers a, Step s) => switch (s) {
    Step.welcome => 'Sure',
    Step.tracking => a.tracking,
    Step.health => a.healthConnected ? 'Connected' : null,
    Step.week => [
      ...a.activities,
      if (a.weekends != null) 'weekends: ${a.weekends!.toLowerCase()}',
    ].join(', '),
    Step.hardParts => a.hardParts.join(', '),
    Step.voice => a.voice,
    Step.coach => a.note.isEmpty ? 'Turn on the coach' : a.note,
  };

  @override
  Widget build(BuildContext context) {
    final a = answers;
    final shown = a.finished ? Step.values.length : a.current + 1;
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(child: title('Getting to know you', size: 24)),
                onboardingCairn(a, width: 70),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              reverse: true,
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
              children: [
                for (final (i, s) in Step.values.take(shown).indexed.toList().reversed) ...[
                  if (a.statuses[i] != null)
                    _bubble(
                      a.statuses[i] == LoggingStatus.skipped
                          ? 'Skip'
                          : (_answerText(a, s)?.isNotEmpty ?? false)
                          ? _answerText(a, s)!
                          : 'Done',
                      mine: true,
                    ),
                  if (s == Step.voice && a.voice != null) ...[
                    _bubble(sampleReplies[a.voice]!, mine: false),
                  ],
                  _bubble(_questions[s]!, mine: false),
                ],
              ],
            ),
          ),
          if (!a.finished) _replyBar(a) else _finishBar(a),
          const SizedBox(height: 72),
        ],
      ),
    );
  }

  Widget _bubble(String text, {required bool mine}) => Align(
    alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      constraints: const BoxConstraints(maxWidth: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: mine ? SteadyColors.bgInput : SteadyColors.coachCardFill,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: mine
              ? SteadyColors.borderSubtleStrong
              : SteadyColors.coachCardBorder,
        ),
      ),
      child: Text(
        text,
        style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
      ),
    ),
  );

  Widget _replyBar(Answers a) {
    final s = a.step;
    final options = switch (s) {
      Step.welcome => const <Widget>[],
      Step.coach => [NoteField(answers: a)],
      Step.health => [
        chips(
          const ['Connect Apple Health'],
          (_) => a.healthConnected,
          (_) => a.update(() => a.healthConnected = true),
        ),
      ],
      _ => [stepContent(a, s)],
    };
    // The voice step's sample is already in the conversation.
    final content = s == Step.voice
        ? [
            chips(
              voiceOptions,
              (o) => a.voice == o,
              (o) => a.update(() => a.voice = o),
            ),
          ]
        : options;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: SteadyColors.borderSubtleStrong)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...content,
          const SizedBox(height: 12),
          Row(
            children: [
              if (s != Step.welcome)
                GhostButton(onPressed: a.skip, child: const Text('Skip')),
              const Spacer(),
              PrimaryButton(
                onPressed: () => primaryAction(a),
                child: Text(s == Step.welcome ? 'Sure' : primaryLabel(s)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _finishBar(Answers a) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
    child: SizedBox(
      width: double.infinity,
      child: PrimaryButton(
        onPressed: a.restart,
        child: const Center(child: Text("Let's go (restarts the prototype)")),
      ),
    ),
  );
}

// --- variant C: one scrolling page, the cairn pinned beside it ---------------

class VariantC extends StatelessWidget {
  const VariantC({required this.answers, super.key});
  final Answers answers;

  @override
  Widget build(BuildContext context) {
    final a = answers;
    if (a.finished) return FinishScreen(answers: a);
    final done = a.statuses.where((s) => s != null).length;
    return SafeArea(
      child: Column(
        children: [
          // Pinned header: the cairn grows as sections are finished.
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      title('Set up Steady', size: 30),
                      const SizedBox(height: 6),
                      body('$done of 7 stones placed. Answer in any order.'),
                    ],
                  ),
                ),
                onboardingCairn(a, width: 90),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              children: [
                for (final (i, s) in Step.values.indexed)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _section(a, i, s),
                  ),
                PrimaryButton(
                  onPressed: () => a.update(() {
                    for (var i = 0; i < a.statuses.length; i++) {
                      a.statuses[i] ??= LoggingStatus.skipped;
                    }
                    a.finished = true;
                  }),
                  child: const Center(child: Text('Done')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(Answers a, int i, Step s) {
    final status = a.statuses[i];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(stepTitles[s]!, style: SteadyType.cardTitle),
              ),
              if (status != null)
                Text(
                  status == LoggingStatus.skipped ? 'Skipped' : 'Done',
                  style: SteadyType.eyebrow,
                ),
            ],
          ),
          const SizedBox(height: 12),
          stepContent(a, s),
          const SizedBox(height: 12),
          Row(
            children: [
              if (status == null && s != Step.welcome)
                GhostButton(
                  onPressed: () => a.update(() {
                    a.statuses[i] = LoggingStatus.skipped;
                    a.current = _nextOpen(a);
                  }),
                  child: const Text('Skip'),
                ),
              const Spacer(),
              if (status == null)
                OutlineButton(
                  onPressed: () => a.update(() {
                    if (s == Step.coach) a.coachOn = true;
                    a.statuses[i] = LoggingStatus.logged;
                    a.current = _nextOpen(a);
                  }),
                  child: Text(s == Step.coach ? 'Turn on the coach' : 'Save'),
                ),
            ],
          ),
        ],
      ),
    );
  }

  /// The cairn's "today" is the first unanswered section.
  int _nextOpen(Answers a) {
    final open = a.statuses.indexWhere((s) => s == null);
    return open == -1 ? Step.values.length - 1 : open;
  }
}

// --- the shared finish screen (A and C) --------------------------------------

class FinishScreen extends StatelessWidget {
  const FinishScreen({required this.answers, super.key});
  final Answers answers;

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 96),
      child: Column(
        children: [
          const Spacer(),
          onboardingCairn(answers, width: 170),
          const SizedBox(height: 32),
          title('Your first cairn', size: 30),
          const SizedBox(height: 12),
          Text(
            "Seven stones, one for each answer (skipped ones too). Tonight's "
            'check-in starts your first real week.',
            textAlign: TextAlign.center,
            style: SteadyType.body,
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: PrimaryButton(
              onPressed: answers.restart,
              child: const Center(child: Text("Let's go (restarts the prototype)")),
            ),
          ),
        ],
      ),
    ),
  );
}

// --- root + floating variant switcher (debug only) ----------------------------

class _PrototypeRoot extends StatefulWidget {
  const _PrototypeRoot();

  @override
  State<_PrototypeRoot> createState() => _PrototypeRootState();
}

class _PrototypeRootState extends State<_PrototypeRoot> {
  static const variants = [
    ('A', 'One question per screen'),
    ('B', 'Chat with the coach'),
    ('C', 'One page, any order'),
  ];

  final answers = Answers();
  int variant = 0;
  bool showState = false;

  @override
  void dispose() {
    answers.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    child: Stack(
      children: [
        Positioned.fill(
          child: ColoredBox(
            color: SteadyColors.bgScreen,
            child: ListenableBuilder(
              listenable: answers,
              builder: (context, _) => switch (variant) {
                0 => VariantA(answers: answers),
                1 => VariantB(answers: answers),
                _ => VariantC(answers: answers),
              },
            ),
          ),
        ),
        if (showState)
          Positioned(
            left: 12,
            right: 12,
            bottom: 96,
            child: ListenableBuilder(
              listenable: answers,
              builder: (context, _) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xEE000000),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFFFD54F)),
                ),
                child: Text(
                  answers.dump,
                  style: const TextStyle(
                    fontFamily: 'Menlo',
                    fontSize: 11,
                    color: Color(0xFFFFD54F),
                  ),
                ),
              ),
            ),
          ),
        if (kDebugMode)
          Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Center(child: _switcher()),
          ),
      ],
    ),
  );

  // Deliberately loud (yellow) so it never reads as part of the design.
  Widget _switcher() {
    final (key, name) = variants[variant];
    Widget arrow(String glyph, int delta) => GestureDetector(
      onTap: () => setState(
        () => variant = (variant + delta) % variants.length,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(glyph, style: _switcherText),
      ),
    );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFD54F),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x88000000), blurRadius: 12)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          arrow('‹', variants.length - 1),
          Text('$key  $name', style: _switcherText),
          arrow('›', 1),
          GestureDetector(
            onTap: () => setState(() => showState = !showState),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Text('{ }', style: _switcherText),
            ),
          ),
        ],
      ),
    );
  }

  static const _switcherText = TextStyle(
    color: Color(0xFF1A1A1A),
    fontSize: 15,
    fontWeight: FontWeight.w700,
  );
}
