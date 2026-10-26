// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$appShellRoute, $importRoute];

RouteBase get $appShellRoute => StatefulShellRouteData.$route(
  factory: $AppShellRouteExtension._fromState,
  branches: [
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/',
          hasOverriddenOnExit: false,
          factory: $HomeRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'checkin/:date',
              hasOverriddenOnExit: false,
              factory: $CheckInRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'craving',
              hasOverriddenOnExit: false,
              parentNavigatorKey: CravingRoute.$parentNavigatorKey,
              factory: $CravingRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/week',
          hasOverriddenOnExit: false,
          factory: $WeekRoute._fromState,
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/coach',
          hasOverriddenOnExit: false,
          factory: $CoachRoute._fromState,
          routes: [
            GoRouteData.$route(
              path: 'chat',
              hasOverriddenOnExit: false,
              parentNavigatorKey: CoachChatRoute.$parentNavigatorKey,
              factory: $CoachChatRoute._fromState,
            ),
            GoRouteData.$route(
              path: 'sessions/:sessionId',
              hasOverriddenOnExit: false,
              factory: $CoachTranscriptRoute._fromState,
            ),
          ],
        ),
      ],
    ),
    StatefulShellBranchData.$branch(
      routes: [
        GoRouteData.$route(
          path: '/settings',
          hasOverriddenOnExit: false,
          factory: $SettingsRoute._fromState,
        ),
      ],
    ),
  ],
);

extension $AppShellRouteExtension on AppShellRoute {
  static AppShellRoute _fromState(GoRouterState state) => const AppShellRoute();
}

mixin $HomeRoute on GoRouteData {
  static HomeRoute _fromState(GoRouterState state) => const HomeRoute();

  @override
  String get location => GoRouteData.$location('/');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CheckInRoute on GoRouteData {
  static CheckInRoute _fromState(GoRouterState state) => CheckInRoute(
    date: DateTime.parse(decodeCheckInDate(state.pathParameters['date']!)),
  );

  CheckInRoute get _self => this as CheckInRoute;

  @override
  String get location => GoRouteData.$location(
    '/checkin/${Uri.encodeComponent(encodeCheckInDate(_self.date.toString()))}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CravingRoute on GoRouteData {
  static CravingRoute _fromState(GoRouterState state) => const CravingRoute();

  @override
  String get location => GoRouteData.$location('/craving');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $WeekRoute on GoRouteData {
  static WeekRoute _fromState(GoRouterState state) => const WeekRoute();

  @override
  String get location => GoRouteData.$location('/week');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CoachRoute on GoRouteData {
  static CoachRoute _fromState(GoRouterState state) => const CoachRoute();

  @override
  String get location => GoRouteData.$location('/coach');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CoachChatRoute on GoRouteData {
  static CoachChatRoute _fromState(GoRouterState state) =>
      const CoachChatRoute();

  @override
  String get location => GoRouteData.$location('/coach/chat');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $CoachTranscriptRoute on GoRouteData {
  static CoachTranscriptRoute _fromState(GoRouterState state) =>
      CoachTranscriptRoute(sessionId: state.pathParameters['sessionId']!);

  CoachTranscriptRoute get _self => this as CoachTranscriptRoute;

  @override
  String get location => GoRouteData.$location(
    '/coach/sessions/${Uri.encodeComponent(_self.sessionId)}',
  );

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

mixin $SettingsRoute on GoRouteData {
  static SettingsRoute _fromState(GoRouterState state) => const SettingsRoute();

  @override
  String get location => GoRouteData.$location('/settings');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

RouteBase get $importRoute => GoRouteData.$route(
  path: '/import',
  hasOverriddenOnExit: false,
  factory: $ImportRoute._fromState,
);

mixin $ImportRoute on GoRouteData {
  static ImportRoute _fromState(GoRouterState state) => const ImportRoute();

  @override
  String get location => GoRouteData.$location('/import');

  @override
  void go(BuildContext context) => context.go(location);

  @override
  Future<T?> push<T>(BuildContext context) => context.push<T>(location);

  @override
  void pushReplacement(BuildContext context) =>
      context.pushReplacement(location);

  @override
  void replace(BuildContext context) => context.replace(location);
}

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(router)
final routerProvider = RouterProvider._();

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

final class RouterProvider
    extends $FunctionalProvider<GoRouter, GoRouter, GoRouter>
    with $Provider<GoRouter> {
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
  RouterProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'routerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$routerHash();

  @$internal
  @override
  $ProviderElement<GoRouter> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  GoRouter create(Ref ref) {
    return router(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(GoRouter value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<GoRouter>(value),
    );
  }
}

String _$routerHash() => r'46fcb91068f13a2a20b7eec93ead6d81ac970d4c';
