import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The week share card: Steady wordmark, the week's dates, and each of the
/// 7 days' check-in status on the single-hue status ladder (product doc
/// §10; no red/green, no shame marks for empty days).
///
/// Calories and steps appear only when [showNumbers] is `true`; the share
/// flow keeps it off unless the user opts in for that share.
///
/// Pure and data-driven, so any screen can host it (today the check-in
/// screen's share dialog; later a week view). Lay it out at exactly
/// [logicalSize] and render it at [pixelRatio] so the PNG is 1080×1350
/// whatever the device's own pixel ratio.
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
    return ColoredBox(
      color: SteadyColors.bgScreen,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'STEADY',
              style: SteadyType.label.copyWith(
                color: SteadyColors.accentTeal,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            const Text('My week', style: SteadyType.cardTitle, maxLines: 1),
            Text(
              '${_dayAndDate(first)} – ${_dayAndDate(last)}',
              style: SteadyType.body,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Column(
                children: [
                  for (final (i, day) in data.days.indexed)
                    Expanded(
                      child: _DayRow(
                        key: Key('weekCardDay_$i'),
                        day: day,
                        showNumbers: showNumbers,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            const _Legend(),
          ],
        ),
      ),
    );
  }

  static const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
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

  static String _weekday(DateTime date) => _weekdays[date.weekday - 1];

  static String _dayAndDate(DateTime date) =>
      '${_weekday(date)} ${_months[date.month - 1]} ${date.day}';

  /// The status word shown beside the dot. A day with no check-in reads as
  /// neutral, not as a miss.
  static String statusLabel(LoggingStatus? status) => switch (status) {
    LoggingStatus.logged => 'Logged',
    LoggingStatus.partial => 'Partial',
    LoggingStatus.skipped => 'Skipped',
    null => 'No check-in',
  };

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

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day, required this.showNumbers, super.key});

  final WeekCardDay day;
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    final status = day.status;
    final calories = day.caloriesEaten;
    final steps = day.steps;
    return Row(
      children: [
        SizedBox(
          width: 44,
          child: Text(
            WeekCard._weekday(day.date).toUpperCase(),
            style: SteadyType.label,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),
        SizedBox(
          width: 32,
          child: Text(
            '${day.date.day}',
            style: SteadyType.body.copyWith(color: SteadyColors.textPrimary),
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
          ),
        ),
        if (status == null)
          const _EmptyDot()
        else
          LoggingStatusIndicator(status: status),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            WeekCard.statusLabel(status),
            style: status == null
                ? SteadyType.body.copyWith(color: SteadyColors.textDisabled)
                : SteadyType.body,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (showNumbers)
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (calories != null)
                  _Number(
                    '${WeekCard._thousands(calories)} cal',
                    color: SteadyColors.caloriesEaten,
                  ),
                if (steps != null)
                  _Number(
                    '${WeekCard._thousands(steps)} steps',
                    color: SteadyColors.steps,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Number extends StatelessWidget {
  const _Number(this.text, {required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: SteadyType.label.copyWith(color: color, letterSpacing: 0.4),
    maxLines: 1,
    softWrap: false,
    overflow: TextOverflow.ellipsis,
  );
}

/// An unfilled ring the size of [LoggingStatusIndicator], for a day with no
/// check-in: present, but neutral.
class _EmptyDot extends StatelessWidget {
  const _EmptyDot();

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: SteadyColors.textDisabled),
    ),
    child: const SizedBox(
      width: SteadyRadii.indicator,
      height: SteadyRadii.indicator,
    ),
  );
}

/// Explains the three dots to whoever receives the card.
class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 16,
    runSpacing: 4,
    children: [
      for (final status in LoggingStatus.values)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoggingStatusIndicator(status: status),
            const SizedBox(width: 6),
            Text(WeekCard.statusLabel(status), style: SteadyType.label),
          ],
        ),
    ],
  );
}
