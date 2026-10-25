/// Typed `go_router` routes (CLAUDE.md §5). Features never import the
/// router or each other's routes: a feature's `presentation` Module exposes
/// typed callbacks, and this file wires those callbacks to real routes.
///
/// [CheckInRoute] (`/checkin/<date>`) is the typed, date-carrying link
/// into one day's check-in, and works from a cold start too.
///
/// There is no sign-in gate: iCloud is optional (CLAUDE.md §7). When it
/// isn't syncing, the Today screen shows the account feature's
/// [ICloudSyncBanner] under its header instead.
///
/// **The shell** ([AppShellRoute], issue #66) is a typed
/// `StatefulShellRoute` with one branch per tab of the floating
/// [GlassTabBar] (`app_shell.dart`): Today (`/`, [HomeRoute]), Week
/// (`/week`, [WeekRoute]), Coach (`/coach`, [CoachRoute], iPhone only) and
/// Settings (`/settings`, [SettingsRoute]). Each branch keeps its own
/// navigation stack. On the Mac the bar has no Coach tab and `/coach`
/// redirects home (CLAUDE.md §11).
///
/// [CheckInRoute] (`/checkin/<date>`) is nested under [HomeRoute] in the
/// Today branch: a cold start from a deep link lands on Today with the
/// day's check-in on top and the tab bar still showing, and tapping Today
/// returns to it. [CravingRoute] (`/craving`) is nested under [HomeRoute]
/// too, so home is beneath it on a cold start, but it's a focused flow, so
/// it's presented on the root navigator, over the shell and its bar.
/// [ImportRoute] (`/import`) stays top-level, on the root navigator over
/// the shell, pushed from the import actions.
///
/// [SettingsRoute] (`/settings`) hosts Apple Health, "Cravings" and
/// "Coach" (iPhone), "Sample data" and the data export (and, in debug
/// builds, the Developer card). [CravingRoute] (`/craving`, iPhone only)
/// is the craving flow, pushed from the Today screen's "Having a craving?"
/// button.
library;

import 'dart:async';

import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:coach_domain/coach_domain.dart' show CoachSessionKind;
import 'package:coach_presentation/coach_presentation.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/app_shell.dart';
import 'package:steady/apple_health_card.dart';
import 'package:steady/developer_card.dart';
import 'package:steady/sample_data_card.dart';
import 'package:steady/today_screen.dart';
import 'package:ui_kit/ui_kit.dart' show GlassTabBar;

part 'app_router.g.dart';

/// The root navigator, above the shell. Routes that present over the shell
/// and its tab bar ([CravingRoute]) name it as their `$parentNavigatorKey`.
final _rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

/// The app's single [GoRouter].
///
/// A provider rather than a global so redirects can read other providers
/// later without a second DI path (CLAUDE.md §5). `keepAlive`: rebuilding it
/// would reset navigation state.
///
/// `initialLocation` is only the fallback. On a cold start from a deep link
/// the platform's initial route (e.g. `/checkin/2026-10-19`) wins, because
/// `overridePlatformDefaultLocation` is left `false`.
///
/// The only top-level `redirect` is [redirectMalformedCheckIn]. The iCloud
/// account status never redirects (CLAUDE.md §7: a banner, not a gate).
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    routes: $appRoutes,
    redirect: (_, state) => redirectMalformedCheckIn(state.uri),
  );
  ref.onDispose(router.dispose);
  return router;
}

/// The app shell: the tab branches under the floating [GlassTabBar]
/// ([AppShell]). Branch order is tab order ([appShellTabs]).
@TypedStatefulShellRoute<AppShellRoute>(
  branches: [
    TypedStatefulShellBranch<TodayBranch>(
      routes: [
        TypedGoRoute<HomeRoute>(
          path: '/',
          routes: [
            TypedGoRoute<CheckInRoute>(path: 'checkin/:date'),
            TypedGoRoute<CravingRoute>(path: 'craving'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<WeekBranch>(
      routes: [TypedGoRoute<WeekRoute>(path: '/week')],
    ),
    TypedStatefulShellBranch<CoachBranch>(
      routes: [
        TypedGoRoute<CoachRoute>(
          path: '/coach',
          routes: [
            TypedGoRoute<CoachChatRoute>(path: 'chat'),
            TypedGoRoute<CoachTranscriptRoute>(path: 'sessions/:sessionId'),
          ],
        ),
      ],
    ),
    TypedStatefulShellBranch<SettingsBranch>(
      routes: [TypedGoRoute<SettingsRoute>(path: '/settings')],
    ),
  ],
)
class AppShellRoute extends StatefulShellRouteData {
  /// Creates the shell route.
  const AppShellRoute();

  @override
  Widget builder(
    BuildContext context,
    GoRouterState state,
    StatefulNavigationShell navigationShell,
  ) => AppShell(navigationShell: navigationShell);
}

/// The Today tab's branch: [HomeRoute] and what's pushed on it.
class TodayBranch extends StatefulShellBranchData {
  /// Creates the Today branch.
  const TodayBranch();
}

/// The Week tab's branch: [WeekRoute].
class WeekBranch extends StatefulShellBranchData {
  /// Creates the Week branch.
  const WeekBranch();
}

/// The Coach tab's branch (iPhone only): [CoachRoute] and what's pushed on
/// it. The branch exists on the Mac too, since typed shell branches are
/// fixed at compile time, but the Mac's bar has no Coach tab and
/// [CoachRoute] redirects home there, so nothing in it is ever built.
class CoachBranch extends StatefulShellBranchData {
  /// Creates the Coach branch.
  const CoachBranch();
}

/// The Settings tab's branch: [SettingsRoute].
class SettingsBranch extends StatefulShellBranchData {
  /// Creates the Settings branch.
  const SettingsBranch();
}

/// `/`, the Today tab: the [TodayScreen] (issue #70). The app layer only
/// composes it from the features' cards (CLAUDE.md §2–3) and wires their
/// callbacks here: the header's import button opens [ImportRoute], the
/// iCloud banner's "Open Settings" goes through the account repository's
/// platform channel, and "Having a craving?" (iPhone only) opens
/// [CravingRoute].
///
/// The coach nudge slot holds coach's [CoachNudgeCard]: on an iPhone, from
/// Friday to Sunday, when last week's weekly check-in is ready. Its "Talk
/// now" opens [CoachWeeklyRoute].
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the home route.
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return TodayScreen(
      onImportRequested: () => unawaited(_import(context, container)),
      onOpenAccountSettings: () => unawaited(_openAccountSettings(container)),
      onCravingRequested: () => unawaited(_craving(context, container)),
      // Renders nothing on the Mac, and nothing on the iPhone unless the
      // weekly check-in is ready (check-in data only, #81).
      coachNudge: CoachNudgeCard(
        onTalkNow: () =>
            unawaited(const CoachWeeklyRoute().push<void>(context)),
      ),
    );
  }

  /// Opens the craving flow, then refreshes the weekly line however it
  /// closes (the flow may have saved a check-in after its own refresh).
  static Future<void> _craving(
    BuildContext context,
    ProviderContainer container,
  ) async {
    await const CravingRoute().push<void>(context);
    container.invalidate(cravingWeekControllerProvider);
  }

  /// Opens the iCloud settings. There is no UI for a failure, so an `Err`
  /// is reported through [FlutterError.reportError] rather than dropped.
  static Future<void> _openAccountSettings(ProviderContainer container) async {
    final result = await container
        .read(accountStatusRepositoryProvider)
        .openAccountSettings();
    result.fold<void>(
      (failure) => FlutterError.reportError(
        FlutterErrorDetails(
          exception: failure,
          library: 'steady app_router',
          context: ErrorDescription('while opening the iCloud settings'),
        ),
      ),
      (_) {},
    );
  }

  /// Opens the import flow, then refreshes what shows imported days however
  /// it closes. Refreshing on return rather than on completion also covers
  /// leaving mid-commit, when the days are written but the import screen is
  /// gone before it can report completion.
  static Future<void> _import(
    BuildContext context,
    ProviderContainer container,
  ) async {
    await const ImportRoute().push<void>(context);
    _invalidateImportReaders(container);
  }
}

/// Re-reads everything that shows imported (Cal AI) days: the Week tab's
/// history, Today's metric tiles, and the week cards (the share card's
/// opt-in calories).
void _invalidateImportReaders(ProviderContainer container) => container
  ..invalidate(metricsHistoryControllerProvider)
  ..invalidate(todayMetricsProvider)
  ..invalidate(weekCardControllerProvider);

/// `/week`, the Week tab: the metrics history ([MetricsHistoryModule]), every
/// imported day with the latest week's tiles. A placeholder for the week
/// view proper. Its header has the import button (shared with Today) and
/// the gear, which switches to the Settings tab.
class WeekRoute extends GoRouteData with $WeekRoute {
  /// Creates the Week route.
  const WeekRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return MetricsHistoryModule(
      onImportRequested: () => unawaited(HomeRoute._import(context, container)),
      onOpenSettings: () => const SettingsRoute().go(context),
    );
  }
}

/// `/settings`, the Settings tab: the settings screen (`DataExportModule`),
/// with the Apple Health section ([AppleHealthCard]), "Cravings"
/// ([CravingSettingsCard], iPhone only), "Coach" ([CoachSettingsCard],
/// iPhone only), "Sample data" ([SampleDataCard], shown only while the
/// sample export's days are in the store) and the debug-only Developer
/// card ([developerSettingsSections]) composed in above the export.
///
/// The root of its own tab, so there's nothing to pop: back switches to
/// the Today tab, on a cold start straight to `/settings` too.
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates the settings route.
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => DataExportModule(
    onBack: () =>
        context.canPop() ? context.pop() : const HomeRoute().go(context),
    sections: [
      const AppleHealthCard(),
      // Both render nothing on macOS.
      const CravingSettingsCard(),
      const CoachSettingsCard(),
      const SampleDataCard(),
      ...developerSettingsSections(),
    ],
  );
}

/// `/coach`, the Coach tab (iPhone only, #80): [CoachHomeModule], to start
/// a chat ([CoachChatRoute]) or read a past one ([CoachTranscriptRoute]).
///
/// `/` where this device has no coach, else `null` (stay put).
///
/// Shared by [CoachRoute] and [CoachWeeklyRoute] so the two can't drift
/// apart: the Mac must be able to reach neither, including by a typed-in
/// link.
String? _homeWhereNoCoach(BuildContext context) =>
    ProviderScope.containerOf(
      context,
      listen: false,
    ).read(coachSupportAvailableProvider)
    ? null
    : const HomeRoute().location;

/// Where the coach doesn't exist (the Mac, `coachSupportAvailableProvider`
/// `false`) it redirects to `/`, and so does every route under it (a
/// parent's redirect runs for its children too), so no coach screen can
/// open there, even from a typed-in link.
class CoachRoute extends GoRouteData with $CoachRoute {
  /// Creates the Coach tab's route.
  const CoachRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
_homeWhereNoCoach(context);

  @override
  Widget build(BuildContext context, GoRouterState state) => CoachHomeModule(
    onChatRequested: () =>
        unawaited(const CoachChatRoute().push<void>(context)),
    onWeeklyRequested: () =>
        unawaited(const CoachWeeklyRoute().push<void>(context)),
    onSessionSelected: (id) =>
        unawaited(CoachTranscriptRoute(sessionId: id).push<void>(context)),
  );
}

/// `/coach/chat`: a new chat with the coach ([CoachSessionModule]).
///
/// Presented on the root navigator, over the shell and its tab bar: the
/// message box sits where the bar would. Closing returns to the Coach tab;
/// the session finishes its summary in the background and refreshes the
/// tab's list itself.
class CoachChatRoute extends GoRouteData with $CoachChatRoute {
  /// Creates the chat route.
  const CoachChatRoute();

  /// Presents the chat over the shell rather than inside the Coach tab.
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  Widget build(BuildContext context, GoRouterState state) => CoachSessionModule(
    onClosed: () =>
        context.canPop() ? context.pop() : const CoachRoute().go(context),
  );
}

/// `/weekly-check-in`: the weekly 15-minute session (#81,
/// [CoachSessionModule] with `CoachSessionKind.weekly`), iPhone only.
///
/// Top-level, on the root navigator over the shell, because it's opened
/// from two tabs: the Today nudge's "Talk now" and the Coach tab's weekly
/// card. Closing returns to whichever opened it. Redirects home where the
/// coach doesn't exist (the Mac), like [CoachRoute].
@TypedGoRoute<CoachWeeklyRoute>(path: '/weekly-check-in')
class CoachWeeklyRoute extends GoRouteData with $CoachWeeklyRoute {
  /// Creates the weekly session's route.
  const CoachWeeklyRoute();

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
_homeWhereNoCoach(context);

  @override
  Widget build(BuildContext context, GoRouterState state) => CoachSessionModule(
    kind: CoachSessionKind.weekly,
    onClosed: () =>
        context.canPop() ? context.pop() : const CoachRoute().go(context),
  );
}

/// `/coach/sessions/<id>`: one past session's transcript, read-only
/// ([CoachTranscriptModule]), inside the Coach tab.
class CoachTranscriptRoute extends GoRouteData with $CoachTranscriptRoute {
  /// Creates the transcript route for [sessionId].
  const CoachTranscriptRoute({required this.sessionId});

  /// The stored session's id.
  final String sessionId;

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CoachTranscriptModule(
        sessionId: sessionId,
        onBack: () =>
            context.canPop() ? context.pop() : const CoachRoute().go(context),
      );
}

/// `/craving`: the craving flow ([CravingFlowModule]), iPhone only.
///
/// Nested under [HomeRoute], so home is always beneath it, even on a cold
/// start straight to `/craving`, and closing or finishing returns there.
/// Presented on the root navigator, over the shell and its tab bar: it's a
/// focused flow with its own close action.
/// Where craving support isn't offered (macOS) it redirects to `/`, so the
/// flow can't open where its repository isn't bound.
class CravingRoute extends GoRouteData with $CravingRoute {
  /// Creates the craving route.
  const CravingRoute();

  /// Presents the flow over the shell rather than inside the Today tab.
  static final GlobalKey<NavigatorState> $parentNavigatorKey =
      _rootNavigatorKey;

  @override
  String? redirect(BuildContext context, GoRouterState state) =>
      ProviderScope.containerOf(
        context,
        listen: false,
      ).read(cravingSupportAvailableProvider)
      ? null
      : const HomeRoute().location;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    void leave() =>
        context.canPop() ? context.pop() : const HomeRoute().go(context);
    return CravingFlowModule(onClosed: leave, onFinished: leave);
  }
}

/// `/import`: the Cal AI PDF import flow.
///
/// Top-level, outside the shell, so it's presented on the root navigator
/// over the shell and its tab bar.
@TypedGoRoute<ImportRoute>(path: '/import')
class ImportRoute extends GoRouteData with $ImportRoute {
  /// Creates the import route.
  const ImportRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return PdfImportModule(
      onImportCompleted: () {
        if (context.canPop()) {
          // The pushing screen refreshes once this route pops.
          context.pop();
        } else {
          // Cold start straight into /import: nothing under us yet.
          _invalidateImportReaders(container);
          const HomeRoute().go(context);
        }
      },
    );
  }
}

/// `/checkin/:date`: one calendar day's check-in screen.
///
/// **Date encoding:** [date] is written to the path as a date-only
/// `yyyy-MM-dd` string (`/checkin/2026-10-19`); any time component is
/// dropped, since a check-in belongs to a whole day. Reading takes only the
/// segment's leading `yyyy-MM-dd` and ignores any time or UTC offset after
/// it, so `/checkin/2026-10-19`, `/checkin/2026-10-19T21:30:00` and
/// `/checkin/2026-10-19T23:30:00-05:00` all resolve to local midnight on the
/// 19th. [CheckInModule] normalizes to midnight itself.
///
/// Nested under [HomeRoute] in the Today branch (path `checkin/:date`
/// under `/`, so the location is still `/checkin/<date>`): Today is
/// beneath it, even on a cold start, and the tab bar stays up, so tapping
/// Today returns there.
class CheckInRoute extends GoRouteData with $CheckInRoute {
  /// Creates the check-in route for [date].
  const CheckInRoute({required this.date});

  /// The day to check in for.
  @CustomParameterCodec(encode: encodeCheckInDate, decode: decodeCheckInDate)
  final DateTime date;

  /// Nothing happens on completion: the screen stays up showing the logged
  /// status, with its "Share week" action still in reach.
  @override
  Widget build(BuildContext context, GoRouterState state) =>
      CheckInModule(date: date, onCheckInCompleted: () {});
}

/// Path encoder for [CheckInRoute.date].
///
/// `go_router_builder` hands a custom encoder the field's `toString()`, so
/// this re-parses it and keeps only the calendar date, as `yyyy-MM-dd`.
String encodeCheckInDate(String dateTimeString) {
  final date = DateTime.parse(dateTimeString);
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Path decoder for [CheckInRoute.date].
///
/// Returns only the segment's leading `yyyy-MM-dd`, which the generated
/// code passes to `DateTime.parse` (local midnight). Any time or UTC offset
/// after it is ignored, so an offset can't move the date across midnight.
/// Throws a [FormatException] if the segment doesn't start with a valid
/// date; the router redirects those away first ([redirectMalformedCheckIn]).
String decodeCheckInDate(String pathSegment) =>
    checkInCalendarDate(pathSegment) ??
    (throw FormatException('Not a yyyy-MM-dd check-in date', pathSegment));

final _leadingDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})');

/// The leading `yyyy-MM-dd` of a `/checkin/:date` path segment, or `null`
/// if the segment doesn't start with a real calendar date (`2026-02-30`
/// and `garbage` both give `null`).
String? checkInCalendarDate(String pathSegment) {
  final match = _leadingDate.firstMatch(pathSegment);
  if (match == null) return null;
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    return null;
  }
  return match.group(0);
}

/// The router's top-level redirect: sends a `/checkin/<segment>`
/// whose segment has no valid leading date to `/`, so a malformed deep link
/// opens the home screen instead of failing to build [CheckInRoute].
/// Returns `null` (no redirect) for every other location.
String? redirectMalformedCheckIn(Uri uri) {
  final segments = uri.pathSegments;
  if (segments.length == 2 &&
      segments.first == 'checkin' &&
      checkInCalendarDate(segments.last) == null) {
    return const HomeRoute().location;
  }
  return null;
}
