/// Typed `go_router` routes (CLAUDE.md §5). Features never import the
/// router or each other's routes: a feature's `presentation` Module exposes
/// typed callbacks, and this file wires those callbacks to real routes.
///
/// [CheckInRoute] is the deep-link target for the local-notification safety
/// net: a tapped reminder opens `/checkin/<date>` from a cold start.
///
/// [SignInRoute] is where the router sends a user who isn't signed in to
/// iCloud (see [redirectForAccount]).
///
/// [ImportRoute] is pushed from the home screen's import action.
/// [SettingsRoute] (`/settings`) hosts the data export.
library;

import 'dart:async';

import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:data_export_presentation/data_export_presentation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/providers.dart';

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
/// The top-level `redirect` is [appRedirect]: the iCloud account gate
/// ([redirectForAccount]) first, then the malformed check-in link check
/// ([redirectMalformedCheckIn]).
///
/// **Reading the account status without rebuilding the router.** The router
/// must not `ref.watch` [accountStatusControllerProvider]: that would build
/// a new `GoRouter` (and reset navigation) every time the status changed.
/// Instead it `ref.listen`s and copies each new value into a
/// [ValueNotifier], which is both what the redirect reads and the router's
/// `refreshListenable`, so the redirect re-runs on every status change. The
/// listen also keeps the (already `keepAlive`) controller subscribed for as
/// long as the router lives.
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final accountStatus = ValueNotifier<AsyncValue<AccountStatus>>(
    const AsyncLoading(),
  );
  ref.listen(
    accountStatusControllerProvider,
    (_, next) => accountStatus.value = next,
    fireImmediately: true,
  );
  final router = GoRouter(
    initialLocation: '/',
    routes: $appRoutes,
    refreshListenable: accountStatus,
    redirect: (_, state) => appRedirect(state.uri, accountStatus.value),
  );
  ref.onDispose(() {
    // The router removes its listener from `accountStatus` when disposed,
    // so it goes first.
    router.dispose();
    accountStatus.dispose();
  });
  return router;
}

/// `/`: the home screen, the metrics history.
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

/// `/settings`: the settings screen, which today is the data export
/// (`DataExportModule`).
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

/// `/sign-in`: the iCloud sign-in screen.
///
/// Reached through [redirectForAccount], not by navigating here directly,
/// and left the same way once the status allows it. "Open Settings" goes
/// through the account repository's platform channel; a failure is
/// reported, not dropped.
@TypedGoRoute<SignInRoute>(path: '/sign-in')
class SignInRoute extends GoRouteData with $SignInRoute {
  /// Creates the sign-in route.
  const SignInRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return SignInModule(
      onOpenSettings: () => unawaited(_openAccountSettings(container)),
    );
  }

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

/// The second half of [appRedirect]: sends a `/checkin/<segment>`
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

/// Top-level redirect for [routerProvider]: the account gate
/// ([redirectForAccount]) first, so a signed-out user's deep link (even a
/// malformed one) lands on the sign-in screen, then
/// [redirectMalformedCheckIn].
String? appRedirect(Uri uri, AsyncValue<AccountStatus> accountStatus) =>
    redirectForAccount(uri, accountStatus) ?? redirectMalformedCheckIn(uri);

/// The iCloud account gate (CLAUDE.md §7: iCloud is required, with no
/// local-only fallback).
///
/// - `noAccount` / `restricted` ([AccountStatus.requiresSignIn]): every
///   location goes to `/sign-in`.
/// - On `/sign-in`, `available` or `notConfigured` goes to `/`: the user
///   signed in, or this build has nothing to sign in to.
/// - Everything else returns `null` (no redirect): `notConfigured`,
///   `couldNotDetermine` and `temporarilyUnavailable` never block, and
///   neither does a status that's still loading or failed to load. During a
///   re-check the state is loading, so the user stays where they are.
///
/// Only a settled `AsyncData` counts. A loading or error state that still
/// carries a previous value is ignored, so a re-check can't bounce the user
/// between screens.
String? redirectForAccount(Uri uri, AsyncValue<AccountStatus> accountStatus) {
  final status = switch (accountStatus) {
    AsyncData(:final value) => value,
    _ => null,
  };
  if (status == null) return null;
  final onSignIn = uri.path == const SignInRoute().location;
  if (status.requiresSignIn) {
    return onSignIn ? null : const SignInRoute().location;
  }
  if (onSignIn &&
      (status == AccountStatus.available ||
          status == AccountStatus.notConfigured)) {
    return const HomeRoute().location;
  }
  return null;
}
