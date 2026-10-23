/// Typed `go_router` routes (CLAUDE.md §5). Features never import the
/// router or each other's routes: a feature's `presentation` Module exposes
/// typed callbacks, and this file wires those callbacks to real routes.
///
/// [CheckInRoute] is the deep-link target for the local-notification safety
/// net: a tapped reminder opens `/checkin/<date>` from a cold start.
///
/// There is no sign-in gate: iCloud is optional (CLAUDE.md §7). When it
/// isn't syncing, the home screen shows the account feature's
/// [ICloudSyncBanner] above the history instead.
///
/// [ImportRoute] is pushed from the home screen's import action.
/// [SettingsRoute] (`/settings`) hosts Apple Health, "Sample data" and the
/// data export (and, in debug builds, the Developer card).
library;

import 'dart:async';

import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/apple_health_card.dart';
import 'package:steady/developer_card.dart';
import 'package:steady/providers.dart';
import 'package:steady/sample_data_card.dart';

part 'app_router.g.dart';

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
    initialLocation: '/',
    routes: $appRoutes,
    redirect: (_, state) => redirectMalformedCheckIn(state.uri),
  );
  ref.onDispose(router.dispose);
  return router;
}

/// `/`: the home screen, the metrics history, with the iCloud sync banner
/// ([ICloudSyncBanner]) composed in above it. The banner hides itself
/// unless iCloud isn't syncing; "Open Settings" goes through the account
/// repository's platform channel.
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: [TypedGoRoute<SettingsRoute>(path: 'settings')],
)
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the home route.
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return MetricsHistoryModule(
      onImportRequested: () => unawaited(_import(context, container)),
      onOpenSettings: () => const SettingsRoute().go(context),
      banner: ICloudSyncBanner(
        onOpenSettings: () => unawaited(_openAccountSettings(container)),
      ),
    );
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

  /// Opens the import flow, then refreshes the history however it closes.
  /// Refreshing on return rather than on completion also covers leaving
  /// mid-commit, when the days are written but the import screen is gone
  /// before it can report completion.
  static Future<void> _import(
    BuildContext context,
    ProviderContainer container,
  ) async {
    await const ImportRoute().push<void>(context);
    container.invalidate(metricsHistoryControllerProvider);
  }
}

/// `/settings`: the settings screen (`DataExportModule`), with the Apple
/// Health section ([AppleHealthCard]), "Sample data" ([SampleDataCard],
/// shown only while the sample export's days are in the store) and the
/// debug-only Developer card
/// ([developerSettingsSections]) composed in above the export.
///
/// Nested under [HomeRoute], so the home screen is always beneath it, even
/// on a cold start straight to `/settings`, and back returns home.
class SettingsRoute extends GoRouteData with $SettingsRoute {
  /// Creates the settings route.
  const SettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => DataExportModule(
    onBack: () =>
        context.canPop() ? context.pop() : const HomeRoute().go(context),
    sections: [
      const AppleHealthCard(),
      const SampleDataCard(),
      ...developerSettingsSections(),
    ],
  );
}

/// `/import`: the Cal AI PDF import flow.
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
          // HomeRoute refreshes the history once this route pops.
          context.pop();
        } else {
          // Cold start straight into /import: no history under us yet.
          container.invalidate(metricsHistoryControllerProvider);
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
@TypedGoRoute<CheckInRoute>(path: '/checkin/:date')
class CheckInRoute extends GoRouteData with $CheckInRoute {
  /// Creates the check-in route for [date].
  const CheckInRoute({required this.date});

  /// The day to check in for.
  @CustomParameterCodec(encode: encodeCheckInDate, decode: decodeCheckInDate)
  final DateTime date;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    // The reminder is per calendar day, so cancel with the midnight day,
    // not whatever time of day [date] carries.
    final day = DateTime(date.year, date.month, date.day);
    return CheckInModule(
      date: date,
      onCheckInCompleted: () => unawaited(_cancelReminder(container, day)),
    );
  }

  /// Cancels [day]'s reminder. There is no UI for a failed cancel yet, so an
  /// `Err` is reported through [FlutterError.reportError] rather than
  /// dropped.
  static Future<void> _cancelReminder(
    ProviderContainer container,
    DateTime day,
  ) async {
    final result = await container
        .read(notificationSchedulerProvider)
        .cancelReminder(day);
    result.fold<void>(
      (failure) => FlutterError.reportError(
        FlutterErrorDetails(
          exception: failure,
          library: 'steady app_router',
          context: ErrorDescription(
            'while cancelling the check-in reminder for $day',
          ),
        ),
      ),
      (_) {},
    );
  }
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
