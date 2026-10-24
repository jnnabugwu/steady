import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/check_in_controller.dart';
import 'package:checkin_presentation/src/check_in_format.dart';
import 'package:checkin_presentation/src/date_labels.dart';
import 'package:checkin_presentation/src/providers.dart';
import 'package:checkin_presentation/src/week_card_controller.dart';
import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The week card (Pass 02 "Native Glass", artboard A2): the [CairnWeek]
/// for the Friday–Thursday week [date] falls in, its headline ("5 of 6
/// days logged") and a [CairnLegend] with a count per status.
///
/// Reads the week through `weekCardControllerProvider(weekCardStart(day))`,
/// the share card's data path, so the cairn and the share card agree. The
/// day's own stone comes from `checkInControllerProvider(day)`, the fresher
/// source: it changes the moment a check-in is logged, before the week
/// re-reads. Today (the cairn's top stone) is read from
/// [checkInTodayProvider].
///
/// A [GlassCard] with no outer padding, so a host screen lays it out: the
/// check-in screen and the app's Today screen both do.
class CairnWeekCard extends ConsumerWidget {
  /// Creates the week card for the week [date] falls in.
  const CairnWeekCard({required this.date, super.key});

  /// A day of the week to show; normalized to midnight. Its stone follows
  /// that day's check-in.
  final DateTime date;

  /// The cairn's height: 7 stones and 6 gaps, so the loading and error
  /// states don't make the card jump when the week arrives.
  static const double _cairnHeight =
      CairnStone.height * DateTime.daysPerWeek +
      CairnWeek.stoneGap * (DateTime.daysPerWeek - 1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final day = DateTime(date.year, date.month, date.day);
    final checkIn = ref.watch(checkInControllerProvider(day));
    // One range read keyed on the normalized week start.
    final week = ref.watch(weekCardControllerProvider(weekCardStart(day)));
    final today = ref.watch(checkInTodayProvider);

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
        AsyncValue(:final value?) => _cairn(day, today, value, checkIn),
        _ => const SizedBox(
          height: _cairnHeight,
          child: Center(
            child: CircularProgressIndicator(key: Key('weekProgress')),
          ),
        ),
      },
    );
  }

  Widget _cairn(
    DateTime day,
    DateTime today,
    WeekCardData data,
    AsyncValue<CheckInStatus?> checkIn,
  ) {
    // The day's controller is the fresher source for [day]. Its last saved
    // status counts while a write is in flight or after one failed, the
    // same value the check-in card shows.
    final saved = checkIn.value;
    final dayStatus = checkIn.hasValue
        ? (value: saved == null ? null : loggingStatusFor(saved))
        : null;
    // Days after today have no stone yet. A deep link to a later day of
    // the week makes that day the cairn's top, so its stone still shows.
    final focus = day.isAfter(today) ? day : today;
    final days = [
      for (final d in data.days)
        CairnDay(
          label: weekdayLetter(d.date),
          fullName: fullWeekday(d.date),
          status: d.date == day && dayStatus != null
              ? dayStatus.value
              : d.status,
          isToday: d.date == focus,
        ),
    ];
    final first = data.days.first.date;
    final last = data.days.last.date;
    final span = '${shortWeekday(first)}–${shortWeekday(last)}';
    final eyebrow = data.days.any((d) => d.date == today)
        ? 'This week · $span'
        : 'Week of ${dayAndDate(first)} · $span';

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
