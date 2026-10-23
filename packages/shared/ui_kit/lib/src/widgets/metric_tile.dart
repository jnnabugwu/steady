import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';
import 'package:ui_kit/src/widgets/metric_accent_chip.dart';

/// A metric tile from the Pass 02 three-across grid (§10): a [label], the
/// big [value] with its [unit], and a 7-bar sparkline of the week in the
/// metric's accent colour.
///
/// The tile is a glass surface (fill [SteadyColors.glassFill], 1px
/// [SteadyColors.glassBorder], [SteadyRadii.tile] radius, 13/14 padding)
/// with no blur and no inner highlight, matching the A2 artboard.
///
/// **Sparkline.** [dailyValues] holds seven values, oldest first. Each bar
/// is scaled against the week's largest value, so the tallest bar fills
/// the 26px track; logged values never drop below [minBarHeight], so a
/// small day still reads as a bar. Two kinds of day render in the
/// accent's ~35%-alpha dimmed colour (e.g. [SteadyColors.stepsDimmed]):
///
/// - **No data** (a null value, past or future) renders as a
///   [minBarHeight] dimmed stub, not a gap. A stub keeps the seven-slot
///   rhythm, so the bars still line up with the week's days and a missing
///   day reads as "nothing logged" rather than as a layout glitch.
/// - **Future days**, at and after [futureFrom], always use the dimmed
///   colour, stub or not.
///
/// A zero is data: it renders as a full-colour [minBarHeight] bar, told
/// apart from a missing day by colour.
///
/// Screen readers hear "[label], [value] [unit]" (or [semanticLabel]); the
/// sparkline is decorative and hidden from them.
class MetricTile extends StatelessWidget {
  /// Creates a metric tile. [dailyValues] must have exactly seven entries.
  const MetricTile({
    required this.label,
    required this.value,
    required this.accent,
    required this.dailyValues,
    this.unit,
    this.futureFrom,
    this.semanticLabel,
    super.key,
  });

  /// The sparkline track's height; the tallest bar fills it.
  static const double sparklineHeight = 26;

  /// The height of a missing day's stub, and the floor for logged bars.
  static const double minBarHeight = 4;

  /// The metric's name, e.g. "Eaten".
  final String label;

  /// The headline value, already formatted by the caller (e.g. "1,840").
  final String value;

  /// Optional unit after [value], e.g. "kcal". Null or empty shows none.
  final String? unit;

  /// Which metric colour the sparkline uses.
  final MetricAccent accent;

  /// Seven daily values, oldest first. Null means no data for that day.
  final List<num?> dailyValues;

  /// Index of the first future day: bars from here on are dimmed. Null
  /// means no day is in the future.
  final int? futureFrom;

  /// Overrides the screen-reader label.
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    // Checked here, not in the constructor: a const constructor can't read
    // a list's length.
    assert(dailyValues.length == 7, 'A week sparkline has seven bars.');
    assert(
      futureFrom == null || (futureFrom! >= 0 && futureFrom! <= 7),
      'futureFrom is an index into the seven days.',
    );
    final hasUnit = unit != null && unit!.isNotEmpty;
    final spoken = hasUnit ? '$label, $value $unit' : '$label, $value';
    return Semantics(
      container: true,
      label: semanticLabel ?? spoken,
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: SteadyColors.glassFill,
            borderRadius: BorderRadius.circular(SteadyRadii.tile),
            border: Border.all(color: SteadyColors.glassBorder),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamilyFallback: SteadyType.fontFamilyFallback,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: SteadyColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Flexible(
                      child: Text(
                        value,
                        maxLines: 1,
                        softWrap: false,
                        overflow: TextOverflow.fade,
                        style: SteadyType.metricValue,
                      ),
                    ),
                    if (hasUnit) ...[
                      const SizedBox(width: 3),
                      Text(
                        unit!,
                        style: const TextStyle(
                          fontFamilyFallback: SteadyType.fontFamilyFallback,
                          fontSize: 11,
                          color: SteadyColors.textMuted,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                _Sparkline(
                  values: dailyValues,
                  futureFrom: futureFrom,
                  color: accent.color,
                  dimmed: accent.dimmedColor,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  const _Sparkline({
    required this.values,
    required this.futureFrom,
    required this.color,
    required this.dimmed,
  });

  final List<num?> values;
  final int? futureFrom;
  final Color color;
  final Color dimmed;

  @override
  Widget build(BuildContext context) {
    final peak = values.fold<double>(
      0,
      (peak, v) => v == null ? peak : math.max(peak, v.toDouble()),
    );
    final bars = <Widget>[];
    for (var i = 0; i < values.length; i++) {
      final v = values[i];
      final future = futureFrom != null && i >= futureFrom!;
      final height = v == null || peak <= 0
          ? MetricTile.minBarHeight
          : math.max(
              MetricTile.minBarHeight,
              MetricTile.sparklineHeight * math.max(0, v.toDouble()) / peak,
            );
      if (i > 0) bars.add(const SizedBox(width: 3));
      bars.add(
        Expanded(
          child: Container(
            key: ValueKey('metric-bar-$i'),
            height: height,
            decoration: BoxDecoration(
              color: v == null || future ? dimmed : color,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
        ),
      );
    }
    return SizedBox(
      height: MetricTile.sparklineHeight,
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: bars),
    );
  }
}
