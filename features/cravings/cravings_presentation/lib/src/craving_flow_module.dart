import 'dart:async';

import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/src/craving_controls.dart';
import 'package:cravings_presentation/src/craving_flow_controller.dart';
import 'package:cravings_presentation/src/craving_flow_state.dart';
import 'package:cravings_presentation/src/craving_minute.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The craving flow, one screen per step (see [CravingStep]):
///
/// 1. "Having a craving?": how strong, 1 to 5.
/// 2. "What's behind it?": optional reasons. Hungry ends it right there
///    with "eating something is a good call".
/// 3. "Want to take a minute with it?": the guided minute
///    ([CravingMinute]), or not.
/// 4. "Still want it?": a second rating, then Having it / It passed / Not
///    sure, each with an equally neutral line.
///
/// Never shows a score, a streak, calories or praise for not eating
/// (docs/research/craving_support.md §4, §6). Calm and roomy: one question
/// per screen, the answers at the bottom within thumb reach, every target
/// at least 44pt.
///
/// Knows nothing about routing (CLAUDE.md §5): the close button calls
/// [onClosed] (nothing is recorded), and "Done" at an ending calls
/// [onFinished]; the app layer decides where each goes.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class CravingFlowModule extends ConsumerWidget {
  /// Creates the craving flow.
  const CravingFlowModule({
    required this.onClosed,
    required this.onFinished,
    super.key,
  });

  /// Called when the person closes the flow before an ending.
  final void Function() onClosed;

  /// Called when the person taps "Done" at an ending.
  final void Function() onFinished;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(cravingFlowControllerProvider);
    final controller = ref.read(cravingFlowControllerProvider.notifier);
    final ended =
        flow.step == CravingStep.hungry || flow.step == CravingStep.finished;

    return Scaffold(
      headers: [
        AppBar(
          leading: [
            if (!ended)
              Semantics(
                label: 'Close',
                button: true,
                child: IconButton.ghost(
                  key: const Key('cravingCloseButton'),
                  icon: const Icon(LucideIcons.x),
                  onPressed: onClosed,
                ),
              ),
          ],
        ),
      ],
      child: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: KeyedSubtree(
                key: ValueKey(flow.step),
                child: switch (flow.step) {
                  CravingStep.intensity => _IntensityStep(
                    onRated: controller.rateCraving,
                  ),
                  CravingStep.reasons => _ReasonsStep(
                    reasons: flow.reasons,
                    onToggled: controller.toggleReason,
                    onNext: () => unawaited(controller.noteReasons()),
                  ),
                  CravingStep.offer => _OfferStep(
                    onTakeMinute: controller.startMinute,
                    onNotNow: controller.skipMinute,
                  ),
                  CravingStep.minute => CravingMinute(
                    onEnded: controller.endMinute,
                  ),
                  CravingStep.stillWant => _StillWantStep(
                    intensityAfter: flow.intensityAfter,
                    onRated: controller.rateAgain,
                    onOutcome: (o) => unawaited(controller.chooseOutcome(o)),
                  ),
                  CravingStep.hungry || CravingStep.finished => _EndingStep(
                    flow: flow,
                    onRetry: () => unawaited(controller.retrySave()),
                    onDone: onFinished,
                  ),
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A full-width, 52pt-tall button slot (over the 44pt minimum).
Widget _tall(Widget button) => SizedBox(height: 52, child: button);

/// A question at the top, its answers at the bottom, within thumb reach.
class _StepLayout extends StatelessWidget {
  const _StepLayout({
    required this.title,
    required this.actions,
    this.subtitle,
    this.body,
    this.titleStyle = SteadyType.headline,
  });

  final String title;
  final TextStyle titleStyle;
  final String? subtitle;
  final Widget? body;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 24),
                Semantics(header: true, child: Text(title, style: titleStyle)),
                if (subtitle case final subtitle?) ...[
                  const SizedBox(height: 12),
                  Text(subtitle, style: SteadyType.body),
                ],
                if (body case final body?) ...[
                  const SizedBox(height: 28),
                  body,
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        for (final (i, action) in actions.indexed) ...[
          if (i > 0) const SizedBox(height: 12),
          action,
        ],
      ],
    );
  }
}

class _IntensityStep extends StatelessWidget {
  const _IntensityStep({required this.onRated});

  final void Function(int) onRated;

  @override
  Widget build(BuildContext context) => _StepLayout(
    title: 'Having a craving?',
    subtitle: 'How strong is it?',
    actions: [
      CravingIntensityPicker(
        keyPrefix: 'cravingIntensityBefore',
        selected: null,
        onSelected: onRated,
      ),
    ],
  );
}

class _ReasonsStep extends StatelessWidget {
  const _ReasonsStep({
    required this.reasons,
    required this.onToggled,
    required this.onNext,
  });

  final Set<CravingReason> reasons;
  final void Function(CravingReason) onToggled;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return _StepLayout(
      title: "What's behind it?",
      subtitle: 'Pick any that fit, or none.',
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Two per row, like the check-in options.
          final width = (constraints.maxWidth - 8) / 2;
          return Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final reason in CravingReason.values)
                SizedBox(
                  width: width,
                  child: CravingChoiceTile(
                    key: Key('cravingReason_${reason.name}'),
                    label: cravingReasonLabel(reason),
                    selected: reasons.contains(reason),
                    onPressed: () => onToggled(reason),
                  ),
                ),
            ],
          );
        },
      ),
      actions: [
        _tall(
          PrimaryButton(
            key: const Key('cravingReasonsNext'),
            onPressed: onNext,
            child: const Center(child: Text('Next')),
          ),
        ),
      ],
    );
  }
}

class _OfferStep extends StatelessWidget {
  const _OfferStep({required this.onTakeMinute, required this.onNotNow});

  final VoidCallback onTakeMinute;
  final VoidCallback onNotNow;

  @override
  Widget build(BuildContext context) => _StepLayout(
    title: 'Want to take a minute with it?',
    subtitle:
        'A short, guided minute of picturing somewhere calm. Some people '
        'find it takes the edge off. Either way is fine.',
    actions: [
      _tall(
        PrimaryButton(
          key: const Key('cravingTakeMinute'),
          onPressed: onTakeMinute,
          child: const Center(child: Text('Take a minute')),
        ),
      ),
      _tall(
        OutlineButton(
          key: const Key('cravingNotNow'),
          onPressed: onNotNow,
          child: const Center(child: Text('Not now')),
        ),
      ),
    ],
  );
}

class _StillWantStep extends StatelessWidget {
  const _StillWantStep({
    required this.intensityAfter,
    required this.onRated,
    required this.onOutcome,
  });

  final int? intensityAfter;
  final void Function(int) onRated;
  final void Function(CravingOutcome) onOutcome;

  @override
  Widget build(BuildContext context) => _StepLayout(
    title: 'Still want it?',
    subtitle: 'How strong is it now?',
    body: CravingIntensityPicker(
      keyPrefix: 'cravingIntensityAfter',
      selected: intensityAfter,
      onSelected: onRated,
    ),
    actions: [
      for (final outcome in _outcomes)
        _tall(
          OutlineButton(
            key: Key('cravingOutcome_${outcome.name}'),
            onPressed: () => onOutcome(outcome),
            child: Center(child: Text(_outcomeLabel(outcome))),
          ),
        ),
    ],
  );

  // Same weight and style for all three: none is the "right" answer.
  static const List<CravingOutcome> _outcomes = [
    CravingOutcome.havingIt,
    CravingOutcome.passed,
    CravingOutcome.notSure,
  ];

  static String _outcomeLabel(CravingOutcome outcome) => switch (outcome) {
    CravingOutcome.havingIt => 'Having it',
    CravingOutcome.passed => 'It passed',
    CravingOutcome.notSure => 'Not sure',
    CravingOutcome.hungry => 'Hungry',
  };
}

class _EndingStep extends StatelessWidget {
  const _EndingStep({
    required this.flow,
    required this.onRetry,
    required this.onDone,
  });

  final CravingFlowState flow;
  final VoidCallback onRetry;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final failed = flow.saveFailure != null;
    return _StepLayout(
      title: endingLine(flow.outcome!),
      // Smaller than a question: these are sentences, not headings.
      titleStyle: SteadyType.cardTitle.copyWith(fontSize: 24, height: 1.3),
      subtitle: failed
          ? "This check-in couldn't be saved on your iPhone. You can try "
                'again, or just carry on.'
          : null,
      actions: [
        if (failed)
          _tall(
            OutlineButton(
              key: const Key('cravingRetrySave'),
              onPressed: flow.saving ? null : onRetry,
              child: const Center(child: Text('Try again')),
            ),
          ),
        _tall(
          PrimaryButton(
            key: const Key('cravingDone'),
            onPressed: onDone,
            child: const Center(child: Text('Done')),
          ),
        ),
      ],
    );
  }
}

/// The neutral line each ending shows. Equally warm whatever happened: no
/// praise for "It passed", no judgement for "Having it".
String endingLine(CravingOutcome outcome) => switch (outcome) {
  CravingOutcome.havingIt => "That's okay. Log it in Cal AI when you're ready.",
  CravingOutcome.passed => 'Noted.',
  CravingOutcome.notSure => "That's fine. You can check back in anytime.",
  CravingOutcome.hungry =>
    'Sounds like you might actually be hungry. Eating something is a good '
        'call.',
};
