// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [$homeRoute, $importRoute, $checkInRoute];

RouteBase get $homeRoute => GoRouteData.$route(
  path: '/',
  hasOverriddenOnExit: false,
  factory: $HomeRoute._fromState,
  routes: [
    GoRouteData.$route(
      path: 'settings',
      hasOverriddenOnExit: false,
      factory: $SettingsRoute._fromState,
    ),
  ],
);

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

RouteBase get $checkInRoute => GoRouteData.$route(
  path: '/checkin/:date',
  hasOverriddenOnExit: false,
  factory: $CheckInRoute._fromState,
);

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

String _$routerHash() => r'0089ba9ad4bf2ad4871b31ab83f507dd4e9f9adc';
