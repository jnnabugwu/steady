import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/src/first_week_suggestions.dart';
import 'package:onboarding_presentation/src/onboarding_controller.dart';
import 'package:onboarding_presentation/src/onboarding_copy.dart';
import 'package:onboarding_presentation/src/onboarding_flow_state.dart';
import 'package:onboarding_presentation/src/onboarding_screens.dart';
import 'package:onboarding_presentation/src/onboarding_source.dart';
import 'package:onboarding_presentation/src/onboarding_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Onboarding: ten screens, one decision each, with the cairn as the
/// progress bar (docs/design/onboarding.md). Opens on the screen the person
/// was last on, with their answers filled in.
///
/// **Nothing traps anyone.** Every question has Skip (a dimmer stone, no
/// answer saved), and "Not now" in the corner of screens 1–9 leaves at
/// once, marking onboarding done (`leaveOnboarding`) and then calling
/// [onLeft]. A save that fails is a quiet line, never a dead end; a read
/// that fails offers to try again or leave.
///
/// Knows nothing about routing, analytics, Apple Health or the coach
/// (CLAUDE.md §5): the app wires each callback. Built from `shadcn_flutter`
/// and `ui_kit` only.
class OnboardingModule extends ConsumerWidget {
  /// Creates the flow.
  const OnboardingModule({
    required this.onFinished,
    required this.onLeft,
    required this.onSourceChosen,
    required this.onHealthRequested,
    required this.onConsentRequested,
    super.key,
  });

  /// Screen 10's "Go to Today", after onboarding is marked done (even if
  /// that save failed: the person goes on either way). The app goes to
  /// Today.
  final void Function() onFinished;

  /// "Not now" on screen `at`, after onboarding is marked done (even if
  /// that save failed). The app sends `onboarding_exited` with `at`'s code
  /// (`at.name`) and goes to Today.
  final void Function(OnboardingStep at) onLeft;

  /// Screen 3 answered: `code` is an [OnboardingSource]'s code (`friend`,
  /// `instagram`, `reddit`, `appStore`, `tiktok`, `other`). Called only
  /// when an answer is chosen and Continue tapped; never on Skip or "Not
  /// now". Nothing is stored. The app sends `onboarding_source`.
  final void Function(String code) onSourceChosen;

  /// Screen 4's "Connect Apple Health": the app asks for Apple Health and
  /// completes once the system sheet is answered. The flow moves on
  /// whatever the answer, and if this throws (the error is reported).
  final Future<void> Function() onHealthRequested;

  /// Screen 8's "Turn on the coach": the app shows the coach's consent
  /// screen and completes with whether consent was given. Either answer
  /// moves on; a throw counts as `false` (and is reported). Any note typed
  /// is saved with it.
  final Future<bool> Function() onConsentRequested;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flow = ref.watch(onboardingControllerProvider);
    return Scaffold(
      child: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: OnboardingPage.maxWidth,
            ),
            child: switch (flow) {
              AsyncData(:final value) => _Flow(
                flow: value,
                onFinished: onFinished,
                onLeft: onLeft,
                onSourceChosen: onSourceChosen,
                onHealthRequested: onHealthRequested,
                onConsentRequested: onConsentRequested,
              ),
              AsyncError() => _ReadFailed(
                loading: flow.isLoading,
                onTryAgain: () => ref.invalidate(onboardingControllerProvider),
                onNotNow: () async {
                  await ref
                      .read(onboardingControllerProvider.notifier)
                      .leaveOnboarding();
                  if (context.mounted) onLeft(OnboardingStep.firstStone);
                },
              ),
              AsyncLoading() => const Center(
                child: CircularProgressIndicator(),
              ),
            },
          ),
        ),
      ),
    );
  }
}

/// The flow once the record is read: the header that stays put, and the
/// current screen under it.
class _Flow extends ConsumerStatefulWidget {
  const _Flow({
    required this.flow,
    required this.onFinished,
    required this.onLeft,
    required this.onSourceChosen,
    required this.onHealthRequested,
    required this.onConsentRequested,
  });

  final OnboardingFlowState flow;
  final void Function() onFinished;
  final void Function(OnboardingStep at) onLeft;
  final void Function(String code) onSourceChosen;
  final Future<void> Function() onHealthRequested;
  final Future<bool> Function() onConsentRequested;

  @override
  ConsumerState<_Flow> createState() => _FlowState();
}

class _FlowState extends ConsumerState<_Flow> {
  /// Screen transitions: a short fade and rise. None with reduced motion.
  static const _transition = Duration(milliseconds: 280);

  /// Set while waiting on the app (Apple Health, consent) or on finishing
  /// or leaving, so a second tap can't start a second one.
  bool _busy = false;

  OnboardingController get _controller =>
      ref.read(onboardingControllerProvider.notifier);

  OnboardingFlowState get _flow => widget.flow;

  Future<void> _whileBusy(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _back() {
    if (_flow.step.previous case final previous?) {
      unawaited(_controller.moveToOnboardingStep(previous));
    }
  }

  void _skip(OnboardingStep step) =>
      unawaited(_controller.skipOnboardingStep(step));

  void _complete(OnboardingStep step) =>
      unawaited(_controller.completeOnboardingStep(step));

  void _leave() => unawaited(
    _whileBusy(() async {
      final at = _flow.step;
      await _controller.leaveOnboarding();
      if (mounted) widget.onLeft(at);
    }),
  );

  void _finish() => unawaited(
    _whileBusy(() async {
      await _controller.finishOnboarding();
      if (mounted) widget.onFinished();
    }),
  );

  void _chooseSource(OnboardingSource source) {
    widget.onSourceChosen(source.code);
    _complete(OnboardingStep.source);
  }

  void _connectHealth() => unawaited(
    _whileBusy(() async {
      try {
        await widget.onHealthRequested();
      } on Object catch (error, stack) {
        _report(error, stack, 'while asking for Apple Health');
      }
      if (mounted) _complete(OnboardingStep.health);
    }),
  );

  void _turnOnCoach(String note) => unawaited(
    _whileBusy(() async {
      var consentGiven = false;
      try {
        consentGiven = await widget.onConsentRequested();
      } on Object catch (error, stack) {
        _report(error, stack, "while asking for the coach's consent");
      }
      if (!mounted) return;
      unawaited(_controller.meetCoach(consentGiven: consentGiven, note: note));
    }),
  );

  static void _report(Object error, StackTrace stack, String context) =>
      FlutterError.reportError(
        FlutterErrorDetails(
          exception: error,
          stack: stack,
          library: 'onboarding_presentation',
          context: ErrorDescription(context),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final step = _flow.step;
    final reducedMotion = MediaQuery.disableAnimationsOf(context);
    final last = step == OnboardingStep.cairn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingHeader(
          cairn: last ? null : _flow.cairn,
          onBack: step.previous == null || _busy ? null : _back,
          onNotNow: last || _busy ? null : _leave,
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: reducedMotion ? Duration.zero : _transition,
            switchInCurve: Curves.easeOut,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.03),
                  end: Offset.zero,
                ).animate(animation),
                child: child,
              ),
            ),
            child: KeyedSubtree(
              key: ValueKey<OnboardingStep>(step),
              child: _screen(step),
            ),
          ),
        ),
      ],
    );
  }

  Widget _screen(OnboardingStep step) {
    final saveFailed = _flow.saveFailure != null;
    final aboutMe = _flow.aboutMe;
    return switch (step) {
      OnboardingStep.firstStone => FirstStoneScreen(
        placed: _flow.stones[step] == OnboardingStone.placed,
        saveFailed: saveFailed,
        onPlaced: _controller.placeFirstStone,
        onContinue: () => _complete(step),
        onSkip: () => _skip(step),
      ),
      OnboardingStep.tracking => SingleChoiceScreen<FoodTracking>(
        title: OnboardingCopy.trackingTitle,
        reason: OnboardingCopy.trackingReason,
        options: FoodTracking.values,
        label: OnboardingCopy.tracking,
        initial: aboutMe.tracking,
        saveFailed: saveFailed,
        onAnswer: (tracking) =>
            unawaited(_controller.answerFoodTracking(tracking)),
        onSkip: () => _skip(step),
      ),
      OnboardingStep.source => SingleChoiceScreen<OnboardingSource>(
        title: OnboardingCopy.sourceTitle,
        reason: OnboardingCopy.sourceReason,
        options: OnboardingSource.values,
        label: (source) => source.label,
        // Never stored, so never filled in.
        initial: null,
        saveFailed: saveFailed,
        onAnswer: _chooseSource,
        onSkip: () => _skip(step),
      ),
      OnboardingStep.health => HealthScreen(
        busy: _busy,
        saveFailed: saveFailed,
        onConnect: _connectHealth,
        onSkip: () => _skip(step),
      ),
      OnboardingStep.week => WeekScreen(
        initial: aboutMe,
        saveFailed: saveFailed,
        onAnswer: (activities, weekends) => unawaited(
          _controller.answerYourWeek(
            activities: activities,
            weekends: weekends,
          ),
        ),
        onSkip: () => _skip(step),
      ),
      OnboardingStep.hardParts => HardPartsScreen(
        initial: aboutMe.hardParts,
        saveFailed: saveFailed,
        onAnswer: (parts) => unawaited(_controller.answerHardParts(parts)),
        onSkip: () => _skip(step),
      ),
      OnboardingStep.voice => VoiceScreen(
        initial: aboutMe.voice,
        saveFailed: saveFailed,
        onAnswer: (voice) => unawaited(_controller.chooseCoachVoice(voice)),
        onSkip: () => _skip(step),
      ),
      OnboardingStep.meetCoach => MeetCoachScreen(
        initialNote: aboutMe.note,
        busy: _busy,
        saveFailed: saveFailed,
        onTurnOn: _turnOnCoach,
        onSkip: () => _skip(step),
      ),
      OnboardingStep.firstWeek => FirstWeekScreen(
        suggestions: firstWeekSuggestions(aboutMe),
        saveFailed: saveFailed,
        onContinue: () => _complete(step),
      ),
      OnboardingStep.cairn => CairnScreen(
        stones: _flow.cairn,
        busy: _busy,
        saveFailed: saveFailed,
        onFinish: _finish,
      ),
    };
  }
}

/// The stored answers couldn't be read: try again, or leave.
class _ReadFailed extends StatelessWidget {
  const _ReadFailed({
    required this.loading,
    required this.onTryAgain,
    required this.onNotNow,
  });

  final bool loading;
  final VoidCallback onTryAgain;
  final Future<void> Function() onNotNow;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OnboardingHeader(
        onBack: null,
        onNotNow: loading ? null : () => unawaited(onNotNow()),
      ),
      Expanded(
        child: OnboardingPage(
          key: const Key('onboardingReadFailed'),
          title: OnboardingCopy.readFailed,
          body: const SizedBox.shrink(),
          primaryLabel: OnboardingCopy.tryAgain,
          onPrimary: loading ? null : onTryAgain,
        ),
      ),
    ],
  );
}
