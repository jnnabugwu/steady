import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/check_in_controller.dart';
import 'package:checkin_presentation/src/providers.dart';
import 'package:checkin_presentation/src/share_week_dialog.dart';
import 'package:checkin_presentation/src/week_card_controller.dart';
import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The check-in screen for one calendar day, in the Pass 02 "Native Glass"
/// style (§10, artboard "A2 · Native Glass, stacked week").
///
/// Two [GlassCard]s: the check-in card, with one [StatusOptionTile] per
/// [CheckInStatus], and the week card, a [CairnWeek] plus [CairnLegend] for
/// the Friday–Thursday week [date] falls in (`weekCardStart`, the same week
/// the share card uses).
///
/// Knows nothing about routing (CLAUDE.md §5): when a check-in is logged
/// successfully it calls [onCheckInCompleted], and the app layer decides
/// what happens next.
///
/// Also hosts the "Share week" action (see `showShareWeekDialog`) until a
/// week view exists.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only, so it needs a
/// `ShadcnApp` ancestor and no Material ones.
class CheckInModule extends ConsumerWidget {
  /// Creates the check-in screen for [date].
  const CheckInModule({
    required this.date,
    required this.onCheckInCompleted,
    super.key,
  });

  /// The day to check in for. Any time of day is accepted; it is normalized
  /// to midnight before keying [checkInControllerProvider].
  final DateTime date;

  /// Called once after a check-in is logged successfully. Not called when
  /// logging fails.
  final void Function() onCheckInCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Family key normalized to midnight (CLAUDE.md §4): one provider per
    // calendar day.
    final day = DateTime(date.year, date.month, date.day);
    final provider = checkInControllerProvider(day);
    final checkIn = ref.watch(provider);
    // The week reuses the share card's data path: one range read keyed on
    // the normalized week start, so the cairn and the card agree.
    final weekStart = weekCardStart(day);
    final weekProvider = weekCardControllerProvider(weekStart);
    final week = ref.watch(weekProvider);
    final now = ref.watch(checkInClockProvider)();
    final today = DateTime(now.year, now.month, now.day);

    Future<void> log(CheckInStatus status) async {
      await ref.read(provider.notifier).logCheckIn(status);
      if (!context.mounted) return;
      if (ref.read(provider) is AsyncData<CheckInStatus?>) {
        // The week now holds a new status: re-read it so the cairn's other
        // data and the share card both see the store as it is now.
        ref.invalidate(weekProvider);
        onCheckInCompleted();
      }
    }

    return Scaffold(
      headers: const [AppBar(title: Text('Check-in'))],
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                spacing: 12,
                children: [
                  _CheckInCard(
                    day: day,
                    isToday: day == today,
                    checkIn: checkIn,
                    onLog: (status) => unawaited(log(status)),
                  ),
                  _WeekCard(
                    day: day,
                    today: today,
                    week: week,
                    checkIn: checkIn,
                  ),
                  // Entry point for the week share card until a week view
                  // exists to host it. Independent of this day's check-in
                  // state: the card reads the whole week itself.
                  Center(
                    child: GhostButton(
                      key: const Key('shareWeekButton'),
                      onPressed: () =>
                          unawaited(showShareWeekDialog(context, date: day)),
                      leading: const Icon(LucideIcons.share),
                      child: const Text('Share week'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Keeps the cards phone-width on a wide macOS window.
  static const _maxWidth = 480.0;
}

/// The check-in card: eyebrow, prompt and the three status options.
class _CheckInCard extends StatelessWidget {
  const _CheckInCard({
    required this.day,
    required this.isToday,
    required this.checkIn,
    required this.onLog,
  });

  final DateTime day;
  final bool isToday;
  final AsyncValue<CheckInStatus?> checkIn;
  final void Function(CheckInStatus status) onLog;

  @override
  Widget build(BuildContext context) {
    // The last saved status: loading and error states carry it over (see
    // `CheckInController.logCheckIn`), so a write in flight or a failed
    // change keeps the saved tile selected, matching the cairn.
    final current = checkIn.value;
    final eyebrow = isToday
        ? "Tonight's check-in"
        : 'Check-in · ${_dayAndDate(day)}';
    // The artboard's title becomes "Added to this week's stack" once the
    // day has a status.
    final title = current != null
        ? 'Added to this week’s stack'
        : isToday
        ? 'How did tracking go today?'
        : 'How did tracking go on ${_fullWeekday(day)}?';

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 14,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 4,
            children: [
              Text(eyebrow.toUpperCase(), style: SteadyType.eyebrow),
              Row(
                spacing: 12,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      key: const Key('checkInTitle'),
                      style: SteadyType.cardTitle,
                    ),
                  ),
                  if (checkIn.isLoading)
                    const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(
                        key: Key('checkInProgress'),
                        size: 18,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // One error state covers both the initial read and a failed
          // write, so the message doesn't name the operation.
          if (checkIn case AsyncError(:final error))
            Text(
              error is Failure
                  ? 'Something went wrong: ${error.message}'
                  : 'Something went wrong',
              style: SteadyType.body,
            ),
          Row(
            spacing: 8,
            children: [
              for (final status in CheckInStatus.values)
                Expanded(
                  child: StatusOptionTile(
                    key: Key('checkInButton_${status.name}'),
                    status: _loggingStatus(status),
                    label: _label(status),
                    selected: current == status,
                    // Disabled while the initial read or a write is in
                    // flight; the controller also ignores writes then.
                    onPressed: checkIn.isLoading ? null : () => onLog(status),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(CheckInStatus status) => switch (status) {
    CheckInStatus.logged => 'Logged fully',
    CheckInStatus.partial => 'Partial',
    CheckInStatus.skipped => 'Skipped',
  };
}

/// The week card: the cairn for the week [day] falls in, its headline and
/// legend.
class _WeekCard extends StatelessWidget {
  const _WeekCard({
    required this.day,
    required this.today,
    required this.week,
    required this.checkIn,
  });

  final DateTime day;
  final DateTime today;
  final AsyncValue<WeekCardData> week;
  final AsyncValue<CheckInStatus?> checkIn;

  /// The cairn's height: 7 stones and 6 gaps, so the loading and error
  /// states don't make the card jump when the week arrives.
  static const double _cairnHeight =
      CairnStone.height * DateTime.daysPerWeek +
      CairnWeek.stoneGap * (DateTime.daysPerWeek - 1);

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      // Error first: a failed re-read must not keep showing the old week
      // as if it were current.
      child: switch (week) {
        AsyncValue(:final error?) => SizedBox(
          height: _cairnHeight,
          child: Center(
            child: Text(
              error is Failure
                  ? "Couldn't load this week: ${error.message}"
                  : "Couldn't load this week.",
              textAlign: TextAlign.center,
              style: SteadyType.body,
            ),
          ),
        ),
        AsyncValue(:final value?) => _cairn(value),
        _ => const SizedBox(
          height: _cairnHeight,
          child: Center(
            child: CircularProgressIndicator(key: Key('weekProgress')),
          ),
        ),
      },
    );
  }

  Widget _cairn(WeekCardData data) {
    // This screen's own controller is the fresher source for [day]: it
    // changes the moment a check-in is logged, before the week re-reads.
    // Its last saved status counts while a write is in flight or after one
    // failed, the same value the check-in card shows.
    final saved = checkIn.value;
    final dayStatus = checkIn.hasValue
        ? (value: saved == null ? null : _loggingStatus(saved))
        : null;
    // Days after today have no stone yet. A deep link to a later day of
    // the week makes that day the cairn's top, so its stone still shows.
    final focus = day.isAfter(today) ? day : today;
    final days = [
      for (final d in data.days)
        CairnDay(
          label: _fullWeekday(d.date).substring(0, 1),
          fullName: _fullWeekday(d.date),
          status: d.date == day && dayStatus != null
              ? dayStatus.value
              : d.status,
          isToday: d.date == focus,
        ),
    ];
    final first = data.days.first.date;
    final last = data.days.last.date;
    final span = '${_weekday(first)}–${_weekday(last)}';
    final eyebrow = data.days.any((d) => d.date == today)
        ? 'This week · $span'
        : 'Week of ${_dayAndDate(first)} · $span';

    final checkedIn = days.where((d) => d.status != null);
    final withFood = checkedIn
        .where((d) => d.status != LoggingStatus.skipped)
        .length;
    final headline = checkedIn.isEmpty
        ? 'No days checked in yet'
        : '$withFood of ${checkedIn.length} '
              '${checkedIn.length == 1 ? 'day' : 'days'} logged';

    return Row(
      spacing: 14,
      children: [
        CairnWeek(key: const Key('checkInCairn'), days: days),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 10,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 2,
                children: [
                  Text(eyebrow.toUpperCase(), style: SteadyType.eyebrow),
                  Text(
                    headline,
                    key: const Key('weekHeadline'),
                    style: SteadyType.metricValue.copyWith(height: 1.2),
                  ),
                ],
              ),
              CairnLegend(days: days),
            ],
          ),
        ),
      ],
    );
  }
}

/// Maps to `ui_kit`'s status ladder for the swatches and stones.
/// Presentation-only: `CheckInStatus` stays its own domain enum.
LoggingStatus _loggingStatus(CheckInStatus status) => switch (status) {
  CheckInStatus.logged => LoggingStatus.logged,
  CheckInStatus.partial => LoggingStatus.partial,
  CheckInStatus.skipped => LoggingStatus.skipped,
};

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _fullWeekdays = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];
const _months = [
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

String _weekday(DateTime date) => _weekdays[date.weekday - 1];

String _fullWeekday(DateTime date) => _fullWeekdays[date.weekday - 1];

/// E.g. "Mon, Aug 24".
String _dayAndDate(DateTime date) =>
    '${_weekday(date)}, ${_months[date.month - 1]} ${date.day}';
