// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `OnboardingRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `onboarding_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
/// with the real implementation (CLAUDE.md §9); tests override it with
/// `InMemoryOnboardingRepository`. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

@ProviderFor(onboardingRepository)
final onboardingRepositoryProvider = OnboardingRepositoryProvider._();

/// The `OnboardingRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `onboarding_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
/// with the real implementation (CLAUDE.md §9); tests override it with
/// `InMemoryOnboardingRepository`. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

final class OnboardingRepositoryProvider
    extends
        $FunctionalProvider<
          OnboardingRepository,
          OnboardingRepository,
          OnboardingRepository
        >
    with $Provider<OnboardingRepository> {
  /// The `OnboardingRepository` this feature reads and writes through.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `onboarding_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it
  /// with the real implementation (CLAUDE.md §9); tests override it with
  /// `InMemoryOnboardingRepository`. Reading it without an override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless, so recreating one
  /// gains nothing (D6).
  OnboardingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingRepositoryHash();

  @$internal
  @override
  $ProviderElement<OnboardingRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  OnboardingRepository create(Ref ref) {
    return onboardingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(OnboardingRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<OnboardingRepository>(value),
    );
  }
}

String _$onboardingRepositoryHash() =>
    r'b766c48973ea25b5a9f85024ea5d3aba60158e1c';
