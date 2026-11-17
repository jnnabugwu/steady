// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_sharing.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The app's [PostHogAnalytics], or `null` where there's none: no key, not
/// iOS, and tests. `main.dart` overrides it; `providers.dart` binds
/// `analyticsProvider` to it.
///
/// `keepAlive`: app-scoped, it holds the SDK's state (CLAUDE.md §4).

@ProviderFor(postHogAnalytics)
final postHogAnalyticsProvider = PostHogAnalyticsProvider._();

/// The app's [PostHogAnalytics], or `null` where there's none: no key, not
/// iOS, and tests. `main.dart` overrides it; `providers.dart` binds
/// `analyticsProvider` to it.
///
/// `keepAlive`: app-scoped, it holds the SDK's state (CLAUDE.md §4).

final class PostHogAnalyticsProvider
    extends
        $FunctionalProvider<
          PostHogAnalytics?,
          PostHogAnalytics?,
          PostHogAnalytics?
        >
    with $Provider<PostHogAnalytics?> {
  /// The app's [PostHogAnalytics], or `null` where there's none: no key, not
  /// iOS, and tests. `main.dart` overrides it; `providers.dart` binds
  /// `analyticsProvider` to it.
  ///
  /// `keepAlive`: app-scoped, it holds the SDK's state (CLAUDE.md §4).
  PostHogAnalyticsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'postHogAnalyticsProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$postHogAnalyticsHash();

  @$internal
  @override
  $ProviderElement<PostHogAnalytics?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  PostHogAnalytics? create(Ref ref) {
    return postHogAnalytics(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(PostHogAnalytics? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<PostHogAnalytics?>(value),
    );
  }
}

String _$postHogAnalyticsHash() => r'2383e3c776f624d81c116de508a20add3b3675f2';

/// Settings' usage-sharing switch.
///
/// `keepAlive`: app-scoped and cheap; the switch shows the same state on
/// every visit to Settings.

@ProviderFor(UsageSharingController)
final usageSharingControllerProvider = UsageSharingControllerProvider._();

/// Settings' usage-sharing switch.
///
/// `keepAlive`: app-scoped and cheap; the switch shows the same state on
/// every visit to Settings.
final class UsageSharingControllerProvider
    extends $AsyncNotifierProvider<UsageSharingController, UsageSharingStatus> {
  /// Settings' usage-sharing switch.
  ///
  /// `keepAlive`: app-scoped and cheap; the switch shows the same state on
  /// every visit to Settings.
  UsageSharingControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'usageSharingControllerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$usageSharingControllerHash();

  @$internal
  @override
  UsageSharingController create() => UsageSharingController();
}

String _$usageSharingControllerHash() =>
    r'54ec79d699dbbf1492ca22e976fa94e6aaa2bffc';

/// Settings' usage-sharing switch.
///
/// `keepAlive`: app-scoped and cheap; the switch shows the same state on
/// every visit to Settings.

abstract class _$UsageSharingController
    extends $AsyncNotifier<UsageSharingStatus> {
  FutureOr<UsageSharingStatus> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<UsageSharingStatus>, UsageSharingStatus>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<UsageSharingStatus>, UsageSharingStatus>,
              AsyncValue<UsageSharingStatus>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
