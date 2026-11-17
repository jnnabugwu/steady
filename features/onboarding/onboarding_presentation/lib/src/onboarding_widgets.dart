import 'package:onboarding_presentation/src/onboarding_copy.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The top of every onboarding screen, kept in place while the screens
/// change under it: the back arrow, the progress cairn and "Not now".
///
/// Staying put is what lets a step's stone drop into the cairn as the
/// next screen comes in.
class OnboardingHeader extends StatelessWidget {
  /// Creates the header.
  const OnboardingHeader({
    required this.onBack,
    required this.onNotNow,
    this.cairn,
    super.key,
  });

  /// The cairn's height in the header: the nine-stone stack, scaled down.
  static const double cairnHeight = 72;

  /// The progress cairn, or `null` for none.
  final List<OnboardingStone>? cairn;

  /// The back arrow, or `null` on the first screen.
  final VoidCallback? onBack;

  /// "Not now", or `null` for none.
  final VoidCallback? onNotNow;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 8, 14, 0),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Align(
            alignment: Alignment.centerLeft,
            child: onBack == null
                ? const SizedBox.square(dimension: GlassIconButton.size)
                : GlassIconButton(
                    key: const Key('onboardingBack'),
                    icon: LucideIcons.arrowLeft,
                    semanticLabel: OnboardingCopy.back,
                    onPressed: onBack,
                  ),
          ),
        ),
        Expanded(
          child: Center(
            child: switch (cairn) {
              final stones? => SizedBox(
                key: const Key('onboardingHeaderCairn'),
                height: cairnHeight,
                child: FittedBox(child: OnboardingCairn(stones: stones)),
              ),
              null => const SizedBox(height: GlassIconButton.size),
            },
          ),
        ),
        SizedBox(
          width: 96,
          child: Align(
            alignment: Alignment.centerRight,
            child: onNotNow == null
                ? const SizedBox.shrink()
                : GhostButton(
                    key: const Key('onboardingNotNow'),
                    onPressed: onNotNow,
                    child: Text(
                      OnboardingCopy.notNow,
                      style: SteadyType.body.copyWith(
                        fontSize: 14,
                        color: SteadyColors.textMuted,
                      ),
                    ),
                  ),
          ),
        ),
      ],
    ),
  );
}

/// One onboarding screen under the [OnboardingHeader]: the title, its
/// one-line reason and the screen's [body] in a scroll view, then the main
/// button and Skip at the bottom.
///
/// Scrolls rather than clips, so it reads at large text sizes. Built from
/// `shadcn_flutter` and `ui_kit` only.
class OnboardingPage extends StatelessWidget {
  /// Creates a screen.
  const OnboardingPage({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.reason,
    this.paid = false,
    this.onSkip,
    this.saveFailed = false,
    super.key,
  });

  /// Keeps the flow phone-width on a wide window.
  static const double maxWidth = 480;

  /// The question or the screen's name.
  final String title;

  /// The one line under [title] saying why it's asked.
  final String? reason;

  /// Whether to show the [PaidBadge] beside [title] (the coach steps).
  final bool paid;

  /// The screen's answers or content.
  final Widget body;

  /// The main button's label.
  final String primaryLabel;

  /// The main button. `null` disables it (nothing answered yet).
  final VoidCallback? onPrimary;

  /// Skip, or `null` for none.
  final VoidCallback? onSkip;

  /// Whether the last save failed; shows [OnboardingCopy.saveFailed].
  final bool saveFailed;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _title(),
                if (reason case final reason?) ...[
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    style: SteadyType.body.copyWith(
                      color: SteadyColors.textTertiary,
                    ),
                  ),
                ],
                const SizedBox(height: 24),
                body,
              ],
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(22, 8, 22, 16 + bottomInset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (saveFailed) ...[
                Text(
                  OnboardingCopy.saveFailed,
                  key: const Key('onboardingSaveFailed'),
                  style: SteadyType.body.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 8),
              ],
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 52),
                child: PrimaryButton(
                  key: const Key('onboardingContinue'),
                  onPressed: onPrimary,
                  child: Center(
                    child: Text(primaryLabel, textAlign: TextAlign.center),
                  ),
                ),
              ),
              if (onSkip != null) ...[
                const SizedBox(height: 6),
                ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 44),
                  child: GhostButton(
                    key: const Key('onboardingSkip'),
                    onPressed: onSkip,
                    child: const Center(child: Text(OnboardingCopy.skip)),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _title() {
    final heading = Semantics(
      header: true,
      child: Text(title, style: SteadyType.headline.copyWith(fontSize: 30)),
    );
    if (!paid) return heading;
    return Wrap(
      spacing: 10,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [heading, const PaidBadge()],
    );
  }
}

/// A large answer row: the [label], an optional [detail] line under it,
/// and a radio ring (single answer) or a check box ([multiSelect]).
///
/// Selected, it takes the teal tint like a chosen check-in option. Screen
/// readers hear a button with [label] and whether it's selected.
class OnboardingChoiceRow extends StatelessWidget {
  /// Creates a row.
  const OnboardingChoiceRow({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.detail,
    this.multiSelect = false,
    super.key,
  });

  /// The row's text.
  final String label;

  /// The line under [label], if any.
  final String? detail;

  /// Whether it's chosen.
  final bool selected;

  /// Whether more than one row can be chosen (draws a check box).
  final bool multiSelect;

  /// Called on tap.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onPressed != null,
      label: label,
      hint: detail,
      // The texts are read from [label] and [detail]; the tap is given
      // here because excluding the children drops Clickable's own.
      onTap: onPressed,
      excludeSemantics: true,
      child: Clickable(
        onPressed: onPressed,
        enabled: onPressed != null,
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        decoration: WidgetStatePropertyAll(
          BoxDecoration(
            color: selected
                ? SteadyColors.accentTealTint(0.16)
                : StatusOptionTile.unselectedFill,
            borderRadius: BorderRadius.circular(SteadyRadii.option),
            border: Border.all(
              color: selected
                  ? SteadyColors.accentTealTint(0.65)
                  : SteadyColors.glassBorder,
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 32),
          child: Row(
            spacing: 14,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: SteadyType.fontFamily,
                        fontFamilyFallback: SteadyType.fontFamilyFallback,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: SteadyColors.textPrimary,
                      ),
                    ),
                    if (detail case final detail?)
                      Text(
                        detail,
                        style: SteadyType.body.copyWith(
                          fontSize: 13,
                          height: 1.35,
                          color: SteadyColors.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              _Mark(selected: selected, multiSelect: multiSelect),
            ],
          ),
        ),
      ),
    );
  }
}

class _Mark extends StatelessWidget {
  const _Mark({required this.selected, required this.multiSelect});

  final bool selected;
  final bool multiSelect;

  @override
  Widget build(BuildContext context) {
    final radius = multiSelect
        ? BorderRadius.circular(6)
        : BorderRadius.circular(11);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: selected ? SteadyColors.accentTeal : null,
        borderRadius: radius,
        border: Border.all(
          color: selected
              ? SteadyColors.accentTeal
              : SteadyColors.glassControlBorder,
          width: 1.5,
        ),
      ),
      child: SizedBox.square(
        dimension: 22,
        child: selected
            ? const Icon(
                LucideIcons.check,
                size: 14,
                color: SteadyColors.bgScreen,
              )
            : null,
      ),
    );
  }
}

/// A pill-shaped answer, for short multi-select answers (screen 5's
/// activities). Screen readers hear a button with [label] and whether
/// it's selected.
class OnboardingChip extends StatelessWidget {
  /// Creates a chip.
  const OnboardingChip({
    required this.label,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  /// The chip's text.
  final String label;

  /// Whether it's chosen.
  final bool selected;

  /// Called on tap.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: onPressed != null,
      label: label,
      // Excluding the text drops Clickable's tap too, so give it here.
      onTap: onPressed,
      excludeSemantics: true,
      child: Clickable(
        onPressed: onPressed,
        enabled: onPressed != null,
        mouseCursor: const WidgetStatePropertyAll(SystemMouseCursors.click),
        decoration: WidgetStatePropertyAll(
          BoxDecoration(
            color: selected
                ? SteadyColors.accentTealTint(0.16)
                : SteadyColors.glassControlFill,
            borderRadius: BorderRadius.circular(SteadyRadii.pill),
            border: Border.all(
              color: selected
                  ? SteadyColors.accentTealTint(0.65)
                  : SteadyColors.glassControlBorder,
            ),
          ),
        ),
        padding: const WidgetStatePropertyAll(
          EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: SteadyType.fontFamily,
            fontFamilyFallback: SteadyType.fontFamilyFallback,
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: selected
                ? SteadyColors.textPrimary
                : SteadyColors.textSecondary,
          ),
        ),
      ),
    );
  }
}

/// A small uppercase heading over a group of answers.
class OnboardingGroupHeading extends StatelessWidget {
  /// Creates a heading reading [text].
  const OnboardingGroupHeading(this.text, {super.key});

  /// The heading's text, shown uppercase.
  final String text;

  @override
  Widget build(BuildContext context) => Semantics(
    header: true,
    label: text,
    excludeSemantics: true,
    child: Text(text.toUpperCase(), style: SteadyType.eyebrow),
  );
}

/// A chat bubble, for screen 7's sample exchange: the person's on the
/// right, the coach's on the left in the coach card's colours.
class OnboardingBubble extends StatelessWidget {
  /// Creates a bubble. [speaker] is read before [text] by screen readers.
  const OnboardingBubble({
    required this.text,
    required this.speaker,
    required this.fromCoach,
    super.key,
  });

  /// What's said.
  final String text;

  /// Who says it, for screen readers.
  final String speaker;

  /// Whether the coach says it.
  final bool fromCoach;

  @override
  Widget build(BuildContext context) => Align(
    alignment: fromCoach ? Alignment.centerLeft : Alignment.centerRight,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 320),
      child: Semantics(
        container: true,
        label: '$speaker: $text',
        excludeSemantics: true,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: fromCoach
                ? SteadyColors.coachCardFill
                : SteadyColors.bgInput,
            borderRadius: fromCoach
                ? SteadyRadii.chatBubble
                : SteadyRadii.chatBubbleMirrored,
            border: Border.all(
              color: fromCoach
                  ? SteadyColors.coachCardBorder
                  : SteadyColors.borderSubtleStrong,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Text(
              text,
              style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
            ),
          ),
        ),
      ),
    ),
  );
}
