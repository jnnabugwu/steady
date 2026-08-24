import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

/// Which of §10's three metric accent colors a [MetricAccentChip] uses.
enum MetricAccent { caloriesEaten, caloriesBurned, steps }

extension on MetricAccent {
  Color get full => switch (this) {
    MetricAccent.caloriesEaten => SteadyColors.caloriesEaten,
    MetricAccent.caloriesBurned => SteadyColors.caloriesBurned,
    MetricAccent.steps => SteadyColors.steps,
  };

  Color get dimmed => switch (this) {
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
    final color = dimmed ? accent.dimmed : accent.full;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: SteadyColors.bgChip,
        borderRadius: BorderRadius.circular(SteadyRadii.control),
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
