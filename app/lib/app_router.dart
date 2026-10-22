/// Typed `go_router` routes (CLAUDE.md §5). Features never import the
/// router or each other's routes: a feature's `presentation` Module exposes
/// typed callbacks, and this file wires those callbacks to real routes.
///
/// [CheckInRoute] is the deep-link target for the local-notification safety
/// net: a tapped reminder opens `/checkin/<date>` from a cold start.
library;

import 'dart:async';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/design_system_preview.dart';
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
@Riverpod(keepAlive: true)
GoRouter router(Ref ref) {
  final router = GoRouter(initialLocation: '/', routes: $appRoutes);
  ref.onDispose(router.dispose);
  return router;
}

/// `/`: the home screen.
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  /// Creates the home route.
  const new();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const DesignSystemPreview();
}

/// `/checkin/:date`: one calendar day's check-in screen.
///
/// **Date encoding:** [date] is written to the path as a date-only
/// `yyyy-MM-dd` string (`/checkin/2026-10-19`); any time component is
/// dropped, since a check-in belongs to a whole day. Reading accepts
/// anything `DateTime.parse` does, so `/checkin/2026-10-19` and
/// `/checkin/2026-10-19T21:30:00` both resolve to the 19th. [CheckInModule]
/// normalizes to midnight itself.
@TypedGoRoute<CheckInRoute>(path: '/checkin/:date')
class CheckInRoute extends GoRouteData with $CheckInRoute {
  /// Creates the check-in route for [date].
  const new({required this.date});

  /// The day to check in for.
  @CustomParameterCodec(encode: encodeCheckInDate, decode: decodeCheckInDate)
  final DateTime date;

  @override
  Widget build(BuildContext context, GoRouterState state) {
    final container = ProviderScope.containerOf(context, listen: false);
    return CheckInModule(
      date: date,
      onCheckInCompleted: () => unawaited(
        container.read(notificationSchedulerProvider).cancelReminder(date),
      ),
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

/// Path decoder for [CheckInRoute.date]. The identity: the generated code
/// passes the result to `DateTime.parse`, which already accepts both
/// `2026-10-19` and `2026-10-19T21:30:00`.
String decodeCheckInDate(String pathSegment) => pathSegment;
