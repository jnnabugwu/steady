import 'package:cravings_domain/cravings_domain.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// A selectable tile in the Pass 02 check-in option style
/// (`StatusOptionTile`): a faint glass tile that turns teal when
/// [selected]. At least 52pt tall, comfortably over the 44pt minimum.
///
/// Screen readers hear a button with [semanticLabel] (or [label]) and its
/// selected state.
class CravingChoiceTile extends StatelessWidget {
  /// Creates a tile showing [label].
  const CravingChoiceTile({
    required this.label,
    required this.selected,
    required this.onPressed,
    this.semanticLabel,
    this.height = 52,
    super.key,
  });

  /// The visible text.
  final String label;

  /// Overrides what screen readers hear.
  final String? semanticLabel;

  /// Whether it's picked.
  final bool selected;

  /// Called on tap. Null disables it.
  final VoidCallback? onPressed;

  /// The tile's height.
  final double height;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      label: semanticLabel ?? label,
      child: SizedBox(
        height: height,
        child: Clickable(
          enabled: enabled,
          onPressed: onPressed,
          mouseCursor: WidgetStatePropertyAll(
            enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
          ),
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
            EdgeInsets.symmetric(horizontal: 16),
          ),
          child: Center(
            child: ExcludeSemantics(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamilyFallback: SteadyType.fontFamilyFallback,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: enabled
                      ? SteadyColors.textPrimary
                      : SteadyColors.textDisabled,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Five tiles, 1 (mild) to 5 (strong), with "Mild" and "Strong" under the
/// ends. One tap picks a strength.
class CravingIntensityPicker extends StatelessWidget {
  /// Creates the picker. [keyPrefix] tells two pickers' tiles apart in
  /// tests (`<keyPrefix>_1` … `<keyPrefix>_5`).
  const CravingIntensityPicker({
    required this.selected,
    required this.onSelected,
    required this.keyPrefix,
    super.key,
  });

  /// The picked strength, if any.
  final int? selected;

  /// Called with the tapped strength.
  final void Function(int intensity) onSelected;

  /// The tiles' key prefix.
  final String keyPrefix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            for (
              var i = minCravingIntensity;
              i <= maxCravingIntensity;
              i++
            ) ...[
              if (i > minCravingIntensity) const SizedBox(width: 8),
              Expanded(
                child: CravingChoiceTile(
                  key: Key('${keyPrefix}_$i'),
                  label: '$i',
                  semanticLabel: _spoken(i),
                  height: 64,
                  selected: selected == i,
                  onPressed: () => onSelected(i),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        const ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mild', style: SteadyType.eyebrow),
              Text('Strong', style: SteadyType.eyebrow),
            ],
          ),
        ),
      ],
    );
  }

  static String _spoken(int i) => switch (i) {
    minCravingIntensity => '$i of 5, mild',
    maxCravingIntensity => '$i of 5, strong',
    _ => '$i of 5',
  };
}

/// The label shown on each reason chip.
String cravingReasonLabel(CravingReason reason) => switch (reason) {
  CravingReason.hungry => 'Hungry',
  CravingReason.bored => 'Bored',
  CravingReason.stressed => 'Stressed',
  CravingReason.tired => 'Tired',
  CravingReason.habit => 'Habit / saw it',
  CravingReason.notSure => 'Not sure',
};
