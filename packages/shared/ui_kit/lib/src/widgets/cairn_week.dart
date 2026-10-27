import 'dart:math' as math;

import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';
import 'package:ui_kit/src/widgets/logging_status_indicator.dart';

/// One day of the 7-day window that [CairnWeek] stacks.
@immutable
class CairnDay {
  /// Creates a day. [label] is the short letter beside the stone ("F"),
  /// [fullName] the spoken name used in the semantics label ("Friday").
  const CairnDay({
    required this.label,
    required this.fullName,
    this.status,
    this.isToday = false,
    this.caloriesEaten,
  });

  /// Short day letter drawn beside the stone, e.g. `'F'`.
  final String label;

  /// Full day name for screen readers, e.g. `'Friday'`.
  final String fullName;

  /// The day's check-in status, or null when it hasn't been checked in yet.
  final LoggingStatus? status;

  /// Whether this is today. Today's letter is teal, and its stone drops into
  /// place when [status] goes from null to a value.
  final bool isToday;

  /// Calories eaten that day, drawn beside the stone, or null for none.
  final int? caloriesEaten;
}

/// The signature Pass 02 piece: the week as a cairn (§10, artboard
/// "A2 · Native Glass, stacked week"). Each day of the 7-day window is a
/// stone stacked on the one before; the first day of the window sits at the
/// bottom.
///
/// - Logged, partial and skipped days are filled from the status ladder.
///   **A skipped day is still a stone**, dimmer and with a faint border,
///   never removed: the stack never falls (product doc §1, no shame
///   visuals).
/// - A day with no status (today, before check-in) is a dashed teal
///   outline stone.
/// - Days after today in the window have no stone yet, only a faint letter:
///   the stone gets placed when that day comes. The slot keeps its height,
///   so the stack doesn't shift as the week fills.
/// - Widths, x-offsets and rotations are fixed per position (the artboard's
///   values), never random, so the stack looks hand-balanced and goldens
///   stay stable.
///
/// - When any day has [CairnDay.caloriesEaten], a column of tan numbers
///   sits right of the stones, one per day that has a value ([width] plus
///   [caloriesWidth] in all). A day without one, or still to come, shows
///   none: never a zero.
///
/// When today's status goes from null to a value, today's stone drops into
/// place (slides down and fades in over [dropDuration]); with reduced motion
/// on (`MediaQuery.disableAnimationsOf`) it just appears.
///
/// Screen readers get one label for the whole stack ([semanticsLabel]); the
/// stones and letters are excluded from semantics.
class CairnWeek extends StatelessWidget {
  /// Creates the stack. [days] must hold exactly 7 entries in window order
  /// (first day at the bottom), so any anchor weekday works.
  const CairnWeek({required this.days, this.width = 150, super.key})
    : assert(days.length == 7, 'CairnWeek needs exactly 7 days.');

  /// The 7 days of the window, in order. The first is drawn at the bottom.
  final List<CairnDay> days;

  /// Width of the letters and stones. The artboard's card uses 150. The
  /// calories column, when shown, adds [caloriesWidth].
  final double width;

  /// Width of the calories column, when any day has calories eaten.
  static const caloriesWidth = 38.0;

  bool get _showsCalories => days.any((d) => d.caloriesEaten != null);

  /// How long today's stone takes to drop into place.
  static const dropDuration = Duration(milliseconds: 350);

  /// Vertical gap between stones.
  static const stoneGap = 3.0;

  /// The artboard's stone shapes, bottom to top: width, x-offset (px) and
  /// rotation (degrees). Copied exactly; the 4th stone is deliberately a
  /// little wider than the 3rd.
  static const _shapes = <({double width, double dx, double rotation})>[
    (width: 100, dx: 0, rotation: 0),
    (width: 90, dx: 4, rotation: -2),
    (width: 84, dx: -3, rotation: 1.5),
    (width: 88, dx: 2, rotation: -1),
    (width: 76, dx: -4, rotation: 2),
    (width: 68, dx: 3, rotation: -1.5),
    (width: 58, dx: 0, rotation: 1),
  ];

  static const _labelWidth = 12.0;
  static const _labelGap = 8.0;

  int get _todayIndex => days.indexWhere((d) => d.isToday);

  bool _isUpcoming(int index) {
    final today = _todayIndex;
    return today >= 0 && index > today;
  }

  /// The single screen-reader label for the whole stack, e.g. "This week as
  /// a stack of days, Friday at the bottom: Friday logged fully, …,
  /// Thursday not checked in yet".
  String get semanticsLabel {
    final parts = [for (final (i, day) in days.indexed) _spokenDay(i, day)];
    return 'This week as a stack of days, ${days.first.fullName} at the '
        'bottom: ${parts.join(', ')}';
  }

  static const _upcoming = 'still to come';

  String _spokenDay(int index, CairnDay day) {
    final status = _isUpcoming(index) ? _upcoming : _spoken(day.status);
    return '${day.fullName} $status${_spokenCalories(index)}';
  }

  String _spokenCalories(int index) => switch (days[index].caloriesEaten) {
    final kcal? when !_isUpcoming(index) => ', ate ${formatKcal(kcal)} kcal',
    _ => '',
  };

  static String _spoken(LoggingStatus? status) => switch (status) {
    LoggingStatus.logged => 'logged fully',
    LoggingStatus.partial => 'partial',
    LoggingStatus.skipped => 'skipped',
    null => 'not checked in yet',
  };

  @override
  Widget build(BuildContext context) {
    assert(
      days.where((d) => d.isToday).length <= 1,
      'At most one CairnDay can be today.',
    );
    return Semantics(
      container: true,
      image: true,
      label: semanticsLabel,
      excludeSemantics: true,
      child: SizedBox(
        width: width + (_showsCalories ? caloriesWidth : 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          spacing: stoneGap,
          children: [
            // Top to bottom, so the first day of the window lands at the
            // bottom (the artboard's column-reverse).
            for (var i = days.length - 1; i >= 0; i--) _row(i),
          ],
        ),
      ),
    );
  }

  Widget _row(int i) {
    final day = days[i];
    final shape = _shapes[i];
    final upcoming = _isUpcoming(i);
    final labelColor = day.isToday
        ? SteadyColors.accentTealHover
        : upcoming
        ? SteadyColors.textDisabled
        : SteadyColors.textMuted;
    return SizedBox(
      height: CairnStone.height,
      child: Row(
        children: [
          SizedBox(
            width: _labelWidth,
            child: Text(
              day.label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontFamilyFallback: SteadyType.fontFamilyFallback,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ),
          const SizedBox(width: _labelGap),
          Expanded(
            child: Center(
              // Same element in every row (positional state), so today's
              // drop state survives rebuilds; only its child changes.
              child: _DropIn(
                isToday: day.isToday,
                status: day.status,
                child: upcoming
                    ? SizedBox(width: shape.width, height: CairnStone.height)
                    : Transform.translate(
                        offset: Offset(shape.dx, 0),
                        child: Transform.rotate(
                          angle: shape.rotation * math.pi / 180,
                          child: CairnStone(
                            status: day.status,
                            width: shape.width,
                          ),
                        ),
                      ),
              ),
            ),
          ),
          if (_showsCalories)
            SizedBox(
              width: caloriesWidth,
              child: Text(
                switch (day.caloriesEaten) {
                  final kcal? when !upcoming => formatKcal(kcal),
                  _ => '',
                },
                textAlign: TextAlign.right,
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.visible,
                style: _caloriesStyle,
              ),
            ),
        ],
      ),
    );
  }

  static const _caloriesStyle = TextStyle(
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    fontFeatures: [FontFeature.tabularFigures()],
    color: SteadyColors.caloriesEaten,
  );
}

/// `1840` → `1,840`, for the cairn's calories column.
String formatKcal(int kcal) {
  final digits = kcal.abs().toString();
  final buffer = StringBuffer(kcal < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// A single cairn stone: a 15px-tall rounded bar filled from the status
/// ladder. Skipped is [SteadyColors.statusSkipped] with a 1px white 0.14
/// border; a null status is a transparent stone with a 1.5px dashed teal
/// (0.75) outline. Used by [CairnWeek]; usable alone (e.g. a legend
/// swatch or the share card).
class CairnStone extends StatelessWidget {
  /// Creates a stone [width] wide in [status]'s style.
  const CairnStone({required this.status, required this.width, super.key});

  /// The stone's status; null draws the dashed "not checked in yet" outline.
  final LoggingStatus? status;

  /// The stone's width. Its height is always [height].
  final double width;

  /// Stone height.
  static const height = 15.0;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(width, height),
      painter: _StonePainter(status),
    );
  }
}

class _StonePainter extends CustomPainter {
  const _StonePainter(this.status);

  final LoggingStatus? status;

  /// The artboard's 8px radius. CSS clamps it to half the 15px height, so
  /// the ends are full semicircles; clamp the same way.
  static const _radius = 8.0;

  static const _dashWidth = 1.5;
  static const _dash = 4.0;
  static const _dashGap = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final radius = Radius.circular(math.min(_radius, size.shortestSide / 2));
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, radius);
    switch (status) {
      case LoggingStatus.logged:
        canvas.drawRRect(rrect, Paint()..color = SteadyColors.statusLogged);
      case LoggingStatus.partial:
        canvas.drawRRect(rrect, Paint()..color = SteadyColors.statusPartial);
      case LoggingStatus.skipped:
        canvas
          ..drawRRect(rrect, Paint()..color = SteadyColors.statusSkipped)
          // 1px border inside the box (CSS box-sizing: border-box).
          ..drawRRect(
            rrect.deflate(0.5),
            Paint()
              ..style = PaintingStyle.stroke
              ..strokeWidth = 1
              ..color = const Color.fromRGBO(255, 255, 255, 0.14),
          );
      case null:
        _paintDashed(canvas, rrect.deflate(_dashWidth / 2));
    }
  }

  /// Flutter has no dashed border: walk the rounded rect's outline with
  /// `PathMetric` and stroke evenly spaced dashes. The dash/gap pair is
  /// stretched slightly so a whole number of dashes fits and the pattern
  /// closes without a short or doubled dash at the seam.
  void _paintDashed(Canvas canvas, RRect outline) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _dashWidth
      ..color = SteadyColors.accentTealTint(0.75);
    final dashes = Path();
    for (final metric in (Path()..addRRect(outline)).computeMetrics()) {
      final count = math.max(1, (metric.length / (_dash + _dashGap)).round());
      final period = metric.length / count;
      final dash = period * _dash / (_dash + _dashGap);
      for (var i = 0; i < count; i++) {
        final start = i * period;
        dashes.addPath(metric.extractPath(start, start + dash), Offset.zero);
      }
    }
    canvas.drawPath(dashes, paint);
  }

  @override
  bool shouldRepaint(_StonePainter oldDelegate) => oldDelegate.status != status;
}

/// Drops today's stone into place when its status goes from null to a
/// value: slides down from above and fades in, ease-out. Idle (fully shown)
/// otherwise, and skipped entirely when reduced motion is on.
class _DropIn extends StatefulWidget {
  const _DropIn({
    required this.isToday,
    required this.status,
    required this.child,
  });

  final bool isToday;
  final LoggingStatus? status;
  final Widget child;

  @override
  State<_DropIn> createState() => _DropInState();
}

class _DropInState extends State<_DropIn> with SingleTickerProviderStateMixin {
  /// How far above its resting place the stone starts, in stone heights.
  static const _dropFrom = 1.6;

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: CairnWeek.dropDuration,
    value: 1,
  );
  late final CurvedAnimation _curve = CurvedAnimation(
    parent: _controller,
    curve: Curves.easeOut,
  );
  late final Animation<Offset> _offset = Tween<Offset>(
    begin: const Offset(0, -_dropFrom),
    end: Offset.zero,
  ).animate(_curve);

  @override
  void didUpdateWidget(_DropIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    final placed =
        widget.isToday && oldWidget.status == null && widget.status != null;
    if (!placed) return;
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _curve,
      child: SlideTransition(position: _offset, child: widget.child),
    );
  }
}

/// Counts per status for a [CairnWeek]'s days, as in the artboard's card:
/// a swatch, the status name and the count, for logged fully, partial and
/// skipped (zero counts included). Days without a status aren't counted.
/// When any day has calories eaten, a last "Eaten" row with a tan swatch
/// keys the cairn's tan numbers (no count).
class CairnLegend extends StatelessWidget {
  /// Creates the legend for [days].
  const CairnLegend({required this.days, super.key});

  /// The same days passed to [CairnWeek].
  final List<CairnDay> days;

  static const _entries = <(LoggingStatus, String, Color)>[
    (LoggingStatus.logged, 'Logged fully', SteadyColors.statusLogged),
    (LoggingStatus.partial, 'Partial', SteadyColors.statusPartial),
    (LoggingStatus.skipped, 'Skipped', SteadyColors.statusSkipped),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      spacing: 6,
      children: [
        for (final (status, label, color) in _entries)
          MergeSemantics(
            child: Row(
              spacing: 8,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: const Color.fromRGBO(255, 255, 255, 0.12),
                    ),
                  ),
                  child: const SizedBox(width: 16, height: 7),
                ),
                Expanded(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamilyFallback: SteadyType.fontFamilyFallback,
                      fontSize: 13,
                      color: SteadyColors.textSecondary,
                    ),
                  ),
                ),
                Text(
                  '${days.where((d) => d.status == status).length}',
                  style: const TextStyle(
                    fontFamilyFallback: SteadyType.fontFamilyFallback,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFeatures: [FontFeature.tabularFigures()],
                    color: SteadyColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        if (days.any((d) => d.caloriesEaten != null))
          const MergeSemantics(
            key: Key('cairnLegend_eaten'),
            child: Row(
              spacing: 8,
              children: [
                DecoratedBox(
                  decoration: BoxDecoration(
                    color: SteadyColors.caloriesEaten,
                    borderRadius: BorderRadius.all(Radius.circular(4)),
                  ),
                  child: SizedBox(width: 16, height: 7),
                ),
                Expanded(
                  child: Text(
                    'Eaten',
                    style: TextStyle(
                      fontFamilyFallback: SteadyType.fontFamilyFallback,
                      fontSize: 13,
                      color: SteadyColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
