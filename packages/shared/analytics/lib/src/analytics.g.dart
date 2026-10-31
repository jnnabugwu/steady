// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'analytics.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [Analytics]. [NoAnalytics] unless the app overrides it, which
/// `app/lib/providers.dart` does only when a TestFlight build has a PostHog
/// key, so feature tests need no override.
///
/// `keepAlive`: cheap and stateless (CLAUDE.md §4).

@ProviderFor(analytics)
final analyticsProvider = AnalyticsProvider._();

/// The app's [Analytics]. [NoAnalytics] unless the app overrides it, which
/// `app/lib/providers.dart` does only when a TestFlight build has a PostHog
/// key, so feature tests need no override.
///
/// `keepAlive`: cheap and stateless (CLAUDE.md §4).

final class AnalyticsProvider
    extends $FunctionalProvider<Analytics, Analytics, Analytics>
    with $Provider<Analytics> {
  /// The app's [Analytics]. [NoAnalytics] unless the app overrides it, which
  /// `app/lib/providers.dart` does only when a TestFlight build has a PostHog
  /// key, so feature tests need no override.
  ///
  /// `keepAlive`: cheap and stateless (CLAUDE.md §4).
  AnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'analyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$analyticsHash();

  @$internal
  @override
  $ProviderElement<Analytics> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  Analytics create(Ref ref) {
    return analytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(Analytics value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<Analytics>(value),
    );
  }
}

String _$analyticsHash() => r'e7ebfc19abb5dd49b3397c75139b287fea88e123';
