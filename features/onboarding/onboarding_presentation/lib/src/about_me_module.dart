import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/src/about_me_controller.dart';
import 'package:onboarding_presentation/src/onboarding_copy.dart';
import 'package:onboarding_presentation/src/onboarding_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// Settings → About me (#172): every onboarding answer, each editable on
/// its own (docs/design/onboarding.md: "every answer can be changed later
/// in Settings → About me").
///
/// Food tracking, your week (activities and weekends), what gets in the
/// way, the coach's voice and the note, with the onboarding screens' own
/// rows, chips and words. Tapping a chosen single answer again clears it,
/// and so does unticking every chip or row of a multi-select, or emptying
/// the note: a cleared answer is a skipped one. The voice and the note
/// carry the [PaidBadge], like screens 7 and 8.
///
/// Every change shows at once and is saved behind it
/// ([AboutMeController]); a failed save keeps the edit on screen and shows
/// a quiet line of its own ([OnboardingSaveFailedLine.aboutMe]: the flow's
/// says "later in Settings", and this is Settings).
///
/// Knows nothing about routing or Today (CLAUDE.md §5): [onBack] and
/// [onAboutMeChanged] are the app's. Scrolls under the tab bar, like the
/// other Settings screens. Built from `shadcn_flutter` and `ui_kit` only.
class AboutMeModule extends ConsumerWidget {
  /// Creates the editor.
  const AboutMeModule({
    required this.onBack,
    required this.onAboutMeChanged,
    super.key,
  });

  /// The back button.
  final void Function() onBack;

  /// Called after each change's save has finished, whether or not it
  /// worked, even if the screen has gone by then. The app re-reads what
  /// follows the stored answers (Today's import button, its Apple Health
  /// prompt and its empty text follow food tracking).
  final void Function() onAboutMeChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final editor = ref.watch(aboutMeControllerProvider);
    return Scaffold(
      headers: [
        AppBar(
          leading: [
            Semantics(
              label: OnboardingCopy.back,
              button: true,
              child: IconButton.ghost(
                key: const Key('aboutMeBack'),
                icon: const Icon(LucideIcons.chevronLeft),
                onPressed: onBack,
              ),
            ),
          ],
          title: const Text(OnboardingCopy.aboutMeTitle),
        ),
      ],
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: OnboardingPage.maxWidth),
          child: switch (editor) {
            AsyncData(:final value) => _Editor(
              state: value,
              onAboutMeChanged: onAboutMeChanged,
            ),
            AsyncError() => _ReadFailed(
              loading: editor.isLoading,
              onTryAgain: () => ref.invalidate(aboutMeControllerProvider),
            ),
            AsyncLoading() => const Center(child: CircularProgressIndicator()),
          },
        ),
      ),
    );
  }
}

class _Editor extends ConsumerStatefulWidget {
  const _Editor({required this.state, required this.onAboutMeChanged});

  final AboutMeEditorState state;
  final void Function() onAboutMeChanged;

  @override
  ConsumerState<_Editor> createState() => _EditorState();
}

class _EditorState extends ConsumerState<_Editor> {
  /// The note as typed. Filled in once from what's stored; after that the
  /// field is the source, and each edit is saved trimmed.
  late final TextEditingController _note = TextEditingController(
    text: widget.state.aboutMe.note ?? '',
  );

  /// The note's text as last handed to the controller: the field can
  /// report the same text twice.
  late String _noteSent;

  @override
  void initState() {
    super.initState();
    _noteSent = _note.text;
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  void _noteChanged(String text) {
    if (text == _noteSent) return;
    _noteSent = text;
    _save(_controller.changeAboutMeNote(text));
  }

  AboutMeController get _controller =>
      ref.read(aboutMeControllerProvider.notifier);

  /// Runs an event, then tells the app once it's saved. The callback is
  /// the app's and outlives this screen, so it's called even if the screen
  /// has gone by then.
  void _save(Future<void> event) {
    final changed = widget.onAboutMeChanged;
    unawaited(event.whenComplete(changed));
  }

  /// A single answer's row tapped: chooses it, or clears it if it was the
  /// one chosen.
  static T? _toggled<T>(T? current, T tapped) =>
      current == tapped ? null : tapped;

  /// A multi-select's row or chip tapped: adds it, or takes it out.
  static Set<T> _toggledIn<T>(Set<T> current, T tapped) => {
    ...current.where((value) => value != tapped),
    if (!current.contains(tapped)) tapped,
  };

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final failed = widget.state.saveFailure != null;
    // The quiet line is pinned under the list, so it's in view whichever
    // answer failed. The list stays the first child either way, so the
    // note keeps its focus when the line comes or goes.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: _list(widget.state.aboutMe, failed ? 12 : 24 + bottomInset),
        ),
        if (failed)
          Padding(
            padding: EdgeInsets.fromLTRB(22, 8, 22, 12 + bottomInset),
            child: const OnboardingSaveFailedLine.aboutMe(),
          ),
      ],
    );
  }

  /// Every section, built at once (a short page): the note's field keeps
  /// its state however far it's scrolled.
  Widget _list(AboutMe aboutMe, double bottomPadding) => SingleChildScrollView(
    key: const Key('aboutMeList'),
    padding: EdgeInsets.fromLTRB(20, 8, 20, bottomPadding),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(OnboardingCopy.aboutMeIntro, style: SteadyType.body),
        const SizedBox(height: 16),
        _Section(
          key: const Key('aboutMeTracking'),
          title: OnboardingCopy.aboutMeTrackingHeading,
          reason: OnboardingCopy.trackingReason,
          child: OnboardingChoiceList<FoodTracking>(
            keyPrefix: _keyPrefix,
            options: FoodTracking.values,
            label: OnboardingCopy.tracking,
            isSelected: (tracking) => tracking == aboutMe.tracking,
            onPressed: (tracking) => _save(
              _controller.changeFoodTracking(
                _toggled(aboutMe.tracking, tracking),
              ),
            ),
          ),
        ),
        _Section(
          key: const Key('aboutMeWeek'),
          title: OnboardingCopy.aboutMeWeekHeading,
          reason: OnboardingCopy.weekReason,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const OnboardingGroupHeading(OnboardingCopy.activitiesHeading),
              const SizedBox(height: 10),
              OnboardingActivityChips(
                keyPrefix: _keyPrefix,
                selected: aboutMe.activities,
                onPressed: (activity) => _save(
                  _controller.changeActivities(
                    _toggledIn(aboutMe.activities, activity),
                  ),
                ),
              ),
              const SizedBox(height: 22),
              const OnboardingGroupHeading(OnboardingCopy.weekendsHeading),
              const SizedBox(height: 10),
              OnboardingChoiceList<WeekendShape>(
                keyPrefix: _keyPrefix,
                options: WeekendShape.values,
                label: OnboardingCopy.weekends,
                isSelected: (weekends) => weekends == aboutMe.weekends,
                onPressed: (weekends) => _save(
                  _controller.changeWeekends(
                    _toggled(aboutMe.weekends, weekends),
                  ),
                ),
              ),
            ],
          ),
        ),
        _Section(
          key: const Key('aboutMeHardParts'),
          title: OnboardingCopy.aboutMeHardPartsHeading,
          reason: OnboardingCopy.hardPartsReason,
          child: OnboardingChoiceList<HardPart>(
            keyPrefix: _keyPrefix,
            options: HardPart.values,
            label: OnboardingCopy.hardPart,
            multiSelect: true,
            isSelected: aboutMe.hardParts.contains,
            onPressed: (part) => _save(
              _controller.changeHardParts(_toggledIn(aboutMe.hardParts, part)),
            ),
          ),
        ),
        _Section(
          key: const Key('aboutMeVoice'),
          title: OnboardingCopy.aboutMeVoiceHeading,
          paid: true,
          child: OnboardingChoiceList<CoachVoice>(
            keyPrefix: _keyPrefix,
            options: CoachVoice.values,
            label: OnboardingCopy.voice,
            detail: OnboardingCopy.voiceDetail,
            isSelected: (voice) => voice == aboutMe.voice,
            onPressed: (voice) => _save(
              _controller.changeCoachVoice(_toggled(aboutMe.voice, voice)),
            ),
          ),
        ),
        _Section(
          key: const Key('aboutMeNote'),
          title: OnboardingCopy.aboutMeNoteHeading,
          reason: OnboardingCopy.noteLabel,
          paid: true,
          child: AboutMeNoteField(
            fieldKey: const Key('aboutMeNoteField'),
            controller: _note,
            onChanged: _noteChanged,
          ),
        ),
      ],
    ),
  );

  /// The editor's answers are keyed `aboutMeOption_<code>`.
  static const _keyPrefix = 'aboutMeOption_';
}

/// One question in the editor: its heading (with the [PaidBadge] for the
/// coach's answers), the line saying why it's asked, and its answers.
class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.child,
    this.reason,
    this.paid = false,
    super.key,
  });

  final String title;
  final String? reason;
  final bool paid;
  final Widget child;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 10,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Semantics(
                header: true,
                child: Text(title, style: SteadyType.cardTitle),
              ),
              if (paid) const PaidBadge(),
            ],
          ),
          if (reason case final reason?) ...[
            const SizedBox(height: 6),
            Text(
              reason,
              style: SteadyType.body.copyWith(color: SteadyColors.textTertiary),
            ),
          ],
          const SizedBox(height: 16),
          child,
        ],
      ),
    ),
  );
}

/// The stored answers couldn't be read: try again.
class _ReadFailed extends StatelessWidget {
  const _ReadFailed({required this.loading, required this.onTryAgain});

  final bool loading;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) => Padding(
    key: const Key('aboutMeReadFailed'),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        const Text(OnboardingCopy.readFailed, style: SteadyType.body),
        PrimaryButton(
          key: const Key('aboutMeTryAgain'),
          onPressed: loading ? null : onTryAgain,
          child: const Text(OnboardingCopy.tryAgain),
        ),
      ],
    ),
  );
}

/// The "About me" row in Settings: opens the editor ([AboutMeModule]).
///
/// Named "About me" because screen 7 says "You can change it later in
/// Settings", and that's the name people will look for. Whether it shows
/// (iPhone only) is the app's call. Screen readers hear a button named
/// "About me".
class AboutMeSettingsCard extends StatelessWidget {
  /// Creates the row.
  const AboutMeSettingsCard({required this.onOpen, super.key});

  /// Tapped: the app opens the editor.
  final void Function() onOpen;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    button: true,
    label: OnboardingCopy.aboutMeTitle,
    hint: OnboardingCopy.aboutMeRowDetail,
    onTap: onOpen,
    excludeSemantics: true,
    child: Clickable(
      key: const Key('aboutMeSettingsRow'),
      onPressed: onOpen,
      mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
      child: const SteadyCard(
        child: Row(
          spacing: 12,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    OnboardingCopy.aboutMeTitle,
                    style: SteadyType.cardTitle,
                  ),
                  SizedBox(height: 8),
                  Text(OnboardingCopy.aboutMeRowDetail, style: SteadyType.body),
                ],
              ),
            ),
            Icon(LucideIcons.chevronRight, color: SteadyColors.textMuted),
          ],
        ),
      ),
    ),
  );
}
