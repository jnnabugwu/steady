// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_router.dart';

// **************************************************************************
// GoRouterGenerator
// **************************************************************************

List<RouteBase> get $appRoutes => [
  $homeRoute,
  $importRoute,
  $signInRoute,
  $checkInRoute,
];

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

RouteBase get $signInRoute => GoRouteData.$route(
  path: '/sign-in',
  hasOverriddenOnExit: false,
  factory: $SignInRoute._fromState,
);

mixin $SignInRoute on GoRouteData {
  static SignInRoute _fromState(GoRouterState state) => const SignInRoute();

  @override
  String get location => GoRouteData.$location('/sign-in');

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

String _$routerHash() => r'5ae2f38facfc62de498867a767baaa98878075d9';
