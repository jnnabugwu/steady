import 'dart:async';

import 'package:checkin_presentation/src/cairn_week_card.dart';
import 'package:checkin_presentation/src/check_in_card.dart';
import 'package:checkin_presentation/src/share_week_dialog.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

/// The check-in screen for one calendar day, in the Pass 02 "Native Glass"
/// style (§10, artboard "A2 · Native Glass, stacked week").
///
/// Two `GlassCard`s: the [CheckInCard], with one `StatusOptionTile` per
/// `CheckInStatus`, and the [CairnWeekCard], a `CairnWeek` plus
/// `CairnLegend` for the Friday–Thursday week [date] falls in
/// (`weekCardStart`, the same week the share card uses). The app's Today
/// screen composes the same two cards.
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
class CheckInModule extends StatelessWidget {
  /// Creates the check-in screen for [date].
  const CheckInModule({
    required this.date,
    required this.onCheckInCompleted,
    super.key,
  });

  /// The day to check in for. Any time of day is accepted; it is normalized
  /// to midnight before keying `checkInControllerProvider`.
  final DateTime date;

  /// Called once after a check-in is logged successfully. Not called when
  /// logging fails.
  final void Function() onCheckInCompleted;

  @override
  Widget build(BuildContext context) {
    // Family key normalized to midnight (CLAUDE.md §4): one provider per
    // calendar day.
    final day = DateTime(date.year, date.month, date.day);

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
                  CheckInCard(
                    date: day,
                    onCheckInCompleted: onCheckInCompleted,
                  ),
                  CairnWeekCard(date: day),
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
