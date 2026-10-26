/// The Today screen (issue #70), the Today tab's root at `/`, in the Pass 02
/// "Native Glass" layout (artboard A2).
///
/// The app layer only composes it: every card comes from its own feature's
/// `*_presentation` package, and no feature imports another's (CLAUDE.md
/// §2–3, §5). Top to bottom:
///
/// 1. The header: today's date in teal, a time-of-day greeting and a
///    [GlassIconButton] that asks for a Cal AI PDF import.
/// 2. The account feature's [ICloudSyncBanner], which renders nothing
///    unless iCloud isn't syncing.
/// 3. Tonight's check-in: checkin's [CheckInCard] for today.
/// 4. This week: checkin's [CairnWeekCard] for today's week.
/// 5. Metrics: metrics' [TodayMetricTiles] for today (the Mac shows only
///    what it has: no Apple Health there).
/// 6. The coach nudge slot, [TodayScreen.coachNudge]: the app router puts
///    coach's `CoachNudgeCard` there, which offers the weekly check-in on
///    an iPhone from Friday to Sunday and renders nothing otherwise.
/// 7. The cravings feature's [CravingHomeSection], iPhone only (it renders
///    nothing on macOS).
library;

import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The Today screen. See the library comment for its sections.
///
/// "Today" comes from checkin's [checkInTodayProvider], the same day the
/// check-in and cairn cards read, so every card agrees on it, and tests pin
/// it through `checkInClockProvider`. It moves to the new day at local
/// midnight and on returning to the foreground (the app root calls
/// `refreshToday`, see `main.dart`), so a screen left open overnight shows
/// the new date and its date-keyed cards re-key on it.
///
/// **Scrolls under the tab bar.** The shell raises the bottom padding to
/// clear its floating bar (`AppShell`); this screen pads its scroll content
/// by `MediaQuery.paddingOf(context).bottom` rather than wrapping itself in
/// a bottom `SafeArea`, so the cards scroll under the bar's blur and still
/// stop clear of it.
///
/// Built from `shadcn_flutter` and `ui_kit` widgets only.
class TodayScreen extends ConsumerWidget {
  /// Creates the Today screen.
  const TodayScreen({
    required this.onImportRequested,
    required this.onOpenAccountSettings,
    required this.onCravingRequested,
    this.coachNudge,
    super.key,
  });

  /// Called when the header's import button is tapped.
  final void Function() onImportRequested;

  /// Called when the iCloud banner's "Open Settings" is tapped.
  final void Function() onOpenAccountSettings;

  /// Called when the cravings section's "Having a craving?" is tapped.
  final void Function() onCravingRequested;

  /// The coach nudge card, below the metrics, or `null` for none. The
  /// router passes coach's `CoachNudgeCard`, which sizes to nothing when
  /// there's no nudge (and always on the Mac).
  final Widget? coachNudge;

  /// Keeps the cards phone-width on a wide macOS window.
  static const double maxWidth = 480;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Rebuilds when the day rolls over (see the class comment); the
    // greeting reads the clock's time on each build.
    final today = ref.watch(checkInTodayProvider);
    final now = ref.read(checkInClockProvider)();
    final padding = MediaQuery.paddingOf(context);

    return Scaffold(
      child: Stack(
        children: [
          // The Pass 02 screen's teal glow, top left.
          Positioned(
            left: -90,
            top: -160,
            width: 440,
            height: 380,
            child: IgnorePointer(
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
          ),
          SingleChildScrollView(
            key: const Key('todayScroll'),
            padding: EdgeInsets.only(
              top: padding.top + 16,
              bottom: padding.bottom,
            ),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _Header(now: now, onImportRequested: onImportRequested),
                    // Carries its own padding; takes no space when hidden.
                    ICloudSyncBanner(onOpenSettings: onOpenAccountSettings),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        spacing: 12,
                        children: [
                          CheckInCard(date: today),
                          CairnWeekCard(date: today),
                          TodayMetricTiles(date: today),
                          ?coachNudge,
                        ],
                      ),
                    ),
                    // Carries its own padding; nothing on macOS.
                    CravingHomeSection(onCravingRequested: onCravingRequested),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The artboard's header: the date in teal over the greeting, and the round
/// glass import button.
class _Header extends StatelessWidget {
  const _Header({required this.now, required this.onImportRequested});

  final DateTime now;
  final void Function() onImportRequested;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 0, 18, 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 4,
              children: [
                Text(
                  todayDateLine(now),
                  key: const Key('todayDate'),
                  style: _dateStyle,
                ),
                Text(
                  greetingFor(now),
                  key: const Key('todayGreeting'),
                  style: SteadyType.headline,
                ),
              ],
            ),
          ),
          GlassIconButton(
            key: const Key('importButton_header'),
            icon: LucideIcons.arrowDownToLine,
            semanticLabel: 'Import Cal AI PDF',
            onPressed: onImportRequested,
          ),
        ],
      ),
    );
  }

  /// The artboard's date line: 13px, medium, in the lighter teal.
  static const _dateStyle = TextStyle(
    fontFamily: SteadyType.fontFamily,
    fontFamilyFallback: SteadyType.fontFamilyFallback,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: SteadyColors.accentTealHover,
  );
}

/// The header's greeting for the time of day at [now]: "Good morning"
/// from 05:00, "Good afternoon" from 12:00, "Good evening" from 17:00 (and
/// through the night, until 05:00).
String greetingFor(DateTime now) => switch (now.hour) {
  >= 5 && < 12 => 'Good morning',
  >= 12 && < 17 => 'Good afternoon',
  _ => 'Good evening',
};

/// The header's date line, e.g. "Thursday, Oct 22".
String todayDateLine(DateTime now) =>
    '${_weekdays[now.weekday - 1]}, ${_months[now.month - 1]} ${now.day}';

const _weekdays = [
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
