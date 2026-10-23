import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// Which of §10's three metric accent colors a metric widget uses (e.g.
/// [MetricAccentChip], `MetricTile`).
enum MetricAccent { caloriesEaten, caloriesBurned, steps }

/// The one place a [MetricAccent] maps to its §10 colours, so every metric
/// widget agrees on them.
extension MetricAccentColors on MetricAccent {
  /// The accent's full colour, e.g. [SteadyColors.caloriesEaten].
  Color get color => switch (this) {
    MetricAccent.caloriesEaten => SteadyColors.caloriesEaten,
    MetricAccent.caloriesBurned => SteadyColors.caloriesBurned,
    MetricAccent.steps => SteadyColors.steps,
  };

  /// The accent's ~35%-alpha variant for future or unlogged days, e.g.
  /// [SteadyColors.caloriesEatenDimmed].
  Color get dimmedColor => switch (this) {
    MetricAccent.caloriesEaten => SteadyColors.caloriesEatenDimmed,
    MetricAccent.caloriesBurned => SteadyColors.caloriesBurnedDimmed,
    MetricAccent.steps => SteadyColors.stepsDimmed,
  };
}

/// A small metric-accent chip (e.g. calories eaten/burned, steps), per §10's
/// bg.chip fill + per-metric accent color. [dimmed] renders the ~35%-alpha
/// variant §10 specifies for future/unlogged days.
class MetricAccentChip extends StatelessWidget {
  const MetricAccentChip({
    required this.accent,
    required this.label,
    this.dimmed = false,
    super.key,
  });

  final MetricAccent accent;
  final String label;
  final bool dimmed;

  @override
  Widget build(BuildContext context) {
    final color = dimmed ? accent.dimmedColor : accent.color;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SteadyColors.bgChip,
        borderRadius: BorderRadius.circular(SteadyRadii.pill),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            DecoratedBox(
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              child: const SizedBox(
                width: SteadyRadii.indicator,
                height: SteadyRadii.indicator,
              ),
            ),
            const SizedBox(width: 6),
            Text(label, style: SteadyType.label),
          ],
        ),
      ),
    );
  }
}
