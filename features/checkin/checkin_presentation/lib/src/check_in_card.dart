import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/check_in_controller.dart';
import 'package:checkin_presentation/src/check_in_format.dart';
import 'package:checkin_presentation/src/providers.dart';
import 'package:checkin_presentation/src/week_card_controller.dart';
import 'package:checkin_presentation/src/week_card_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The check-in card for one calendar day (Pass 02 "Native Glass", artboard
/// A2): an eyebrow, the prompt and one [StatusOptionTile] per
/// [CheckInStatus], backed by `checkInControllerProvider(day)`.
///
/// For today the eyebrow reads "Tonight's check-in"; for another day it
/// names the day. Once the day has a status, the title confirms it was
/// "Added to this week's stack".
///
/// A [GlassCard] with no outer padding, so a host screen lays it out: the
/// check-in screen (`CheckInModule`) and the app's Today screen both do.
/// Today is read from [checkInClockProvider].
///
/// Logging a status fires the CheckInLogged / CheckInPartial /
/// CheckInSkipped domain event (`CheckInController.logCheckIn`). On success
/// it re-reads the day's week (`weekCardControllerProvider`), so a
/// `CairnWeekCard` for the same week picks up the change, then calls
/// [onCheckInCompleted]. Knows nothing about routing (CLAUDE.md §5).
class CheckInCard extends ConsumerWidget {
  /// Creates the check-in card for [date].
  const CheckInCard({required this.date, this.onCheckInCompleted, super.key});

  /// The day to check in for. Any time of day is accepted; it is normalized
  /// to midnight before keying [checkInControllerProvider].
  final DateTime date;

  /// Called once after a check-in is logged successfully. Not called when
  /// logging fails.
  final void Function()? onCheckInCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Family key normalized to midnight (CLAUDE.md §4): one provider per
    // calendar day.
    final day = DateTime(date.year, date.month, date.day);
    final provider = checkInControllerProvider(day);
    final checkIn = ref.watch(provider);
    final now = ref.watch(checkInClockProvider)();
    final isToday = day == DateTime(now.year, now.month, now.day);

    Future<void> log(CheckInStatus status) async {
      await ref.read(provider.notifier).logCheckIn(status);
      if (!context.mounted) return;
      if (ref.read(provider) is AsyncData<CheckInStatus?>) {
        // The week now holds a new status: re-read it so the cairn's other
        // data and the share card both see the store as it is now.
        ref.invalidate(weekCardControllerProvider(weekCardStart(day)));
        onCheckInCompleted?.call();
      }
    }

    // The last saved status: loading and error states carry it over (see
    // `CheckInController.logCheckIn`), so a write in flight or a failed
    // change keeps the saved tile selected, matching the cairn.
    final current = checkIn.value;
    final eyebrow = isToday
        ? "Tonight's check-in"
        : 'Check-in · ${dayAndDate(day)}';
    // The artboard's title becomes "Added to this week's stack" once the
    // day has a status.
    final title = current != null
        ? 'Added to this week’s stack'
        : isToday
        ? 'How did tracking go today?'
        : 'How did tracking go on ${fullWeekday(day)}?';

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
                    status: loggingStatusFor(status),
                    label: _label(status),
                    selected: current == status,
                    // Disabled while the initial read or a write is in
                    // flight; the controller also ignores writes then.
                    onPressed: checkIn.isLoading
                        ? null
                        : () => unawaited(log(status)),
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
