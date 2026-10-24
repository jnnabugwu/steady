import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The week share card, drawn around the cairn (Pass 02, §10): the Steady
/// wordmark, the week's dates and a one-line summary over the screen's teal
/// glow, then the week's [CairnWeek] stack as the hero inside a glass card,
/// with its [CairnLegend] below.
///
/// Every day is a stone, whatever happened (product doc §1: no shame
/// visuals, the stack never falls). A day with no check-in is the cairn's
/// dashed outline stone.
///
/// Calories and steps appear only when [showNumbers] is `true`, each beside
/// its own day's stone; the share flow keeps it off unless the user opts in
/// for that share.
///
/// Pure and data-driven, so any screen can host it (today the check-in
/// screen's share dialog; later a week view). It needs a `ShadcnApp`
/// ancestor for the glass card's theme. Lay it out at exactly
/// [logicalSize] and render it at [pixelRatio] so the PNG is 1080×1350
/// whatever the device's own pixel ratio. It renders settled: the cairn's
/// drop-in only plays when a day's status changes on a live widget, never
/// on a first build.
class WeekCard extends StatelessWidget {
  /// Creates the card for [data].
  const WeekCard({required this.data, this.showNumbers = false, super.key});

  /// The card's fixed layout size, 4:5 portrait.
  static const logicalSize = Size(360, 450);

  /// Render scale for the shared PNG: 360×450 logical → 1080×1350 pixels
  /// (≈5.8 MB decoded RGBA). Fixed, not the device's pixel ratio, so a
  /// large Mac display doesn't produce an oversized image.
  static const pixelRatio = 3.0;

  /// The week to show.
  final WeekCardData data;

  /// Whether to show each day's calories eaten and steps.
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    final first = data.days.first.date;
    final last = data.days.last.date;
    final cairnDays = [
      for (final day in data.days)
        CairnDay(
          label: _weekdayLetters[day.date.weekday - 1],
          fullName: _weekdayNames[day.date.weekday - 1],
          status: day.status,
        ),
    ];
    final numbers = showNumbers
        ? [for (final day in data.days) _numbersFor(day)]
        : const <List<_Number>>[];
    final hasNumbers = numbers.any((n) => n.isNotEmpty);

    return ClipRect(
      child: ColoredBox(
        color: SteadyColors.bgScreen,
        child: Stack(
          children: [
            // The Pass 02 screen's teal glow, top left.
            Positioned(
              left: -80,
              top: -150,
              width: 400,
              height: 340,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      SteadyColors.accentTealTint(0.20),
                      SteadyColors.accentTealTint(0),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('STEADY', style: _wordmark, maxLines: 1),
                  const SizedBox(height: 18),
                  Text(
                    '${_dayAndDate(first)} – ${_dayAndDate(last)}',
                    style: _dateLine,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    headline(data),
                    style: _headline,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: GlassCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 14,
                        children: [
                          Expanded(
                            child: SizedBox.expand(
                              // Tight, so FittedBox scales the stack up: the
                              // hero. With numbers beside the stones it
                              // scales as one, so each day's numbers stay
                              // level with its stone.
                              child: FittedBox(
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CairnWeek(
                                      key: const Key('weekCardCairn'),
                                      days: cairnDays,
                                    ),
                                    if (hasNumbers) ...[
                                      const SizedBox(width: 12),
                                      _NumbersColumn(numbers: numbers),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                          CairnLegend(days: cairnDays),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// The one-line summary under the dates, e.g. "5 of 6 days logged":
  /// days with food logged (fully or partly) out of days checked in. A
  /// skipped day counts as checked in, not as a failure.
  static String headline(WeekCardData data) {
    final checkedIn = data.days.where((d) => d.status != null).toList();
    if (checkedIn.isEmpty) return 'A fresh week';
    final withFood = checkedIn
        .where((d) => d.status != LoggingStatus.skipped)
        .length;
    final noun = checkedIn.length == 1 ? 'day' : 'days';
    return '$withFood of ${checkedIn.length} $noun logged';
  }

  static List<_Number> _numbersFor(WeekCardDay day) {
    final calories = day.caloriesEaten;
    final steps = day.steps;
    return [
      if (calories != null)
        _Number('${_thousands(calories)} cal', SteadyColors.caloriesEaten),
      if (steps != null)
        _Number('${_thousands(steps)} steps', SteadyColors.steps),
    ];
  }

  static const _wordmark = TextStyle(
    fontFamily: SteadyType.fontFamily,
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 2.6,
    color: SteadyColors.accentTeal,
  );

  /// The artboard's date line above the screen title.
  static const _dateLine = TextStyle(
    fontFamily: SteadyType.fontFamily,
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SteadyColors.accentTealHover,
  );

  static final TextStyle _headline = SteadyType.headline.copyWith(fontSize: 28);

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  static const _weekdayLetters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const _weekdayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _dayAndDate(DateTime date) =>
      '${_weekdays[date.weekday - 1]} ${_months[date.month - 1]} ${date.day}';

  /// `1850` → `1,850`.
  static String _thousands(int n) {
    final digits = n.abs().toString();
    final buffer = StringBuffer(n < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

/// One opt-in number beside a stone.
class _Number {
  const _Number(this.text, this.color);

  final String text;
  final Color color;
}

/// Each day's opt-in numbers, one row per stone, laid out on the cairn's
/// own row rhythm ([CairnStone.height] rows, [CairnWeek.stoneGap] apart,
/// first day at the bottom) so a row sits level with its day's stone. A day
/// with no numbers keeps an empty row; nothing is invented for it.
class _NumbersColumn extends StatelessWidget {
  const _NumbersColumn({required this.numbers});

  final List<List<_Number>> numbers;

  static final TextStyle _style = SteadyType.eyebrow.copyWith(
    fontSize: 10,
    height: 1,
    letterSpacing: 0.2,
  );

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    spacing: CairnWeek.stoneGap,
    children: [
      for (var i = numbers.length - 1; i >= 0; i--)
        SizedBox(
          key: Key('weekCardNumbers_$i'),
          height: CairnStone.height,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (j, number) in numbers[i].indexed) ...[
                if (j > 0) Text(' · ', style: _style),
                Text(
                  number.text,
                  style: _style.copyWith(color: number.color),
                  maxLines: 1,
                  softWrap: false,
                ),
              ],
            ],
          ),
        ),
    ],
  );
}
