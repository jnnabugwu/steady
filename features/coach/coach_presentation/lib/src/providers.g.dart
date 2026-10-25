// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `CoachRepository` coach sessions and transcripts are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store
/// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).

@ProviderFor(coachRepository)
final coachRepositoryProvider = CoachRepositoryProvider._();

/// The `CoachRepository` coach sessions and transcripts are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store
/// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).

final class CoachRepositoryProvider
    extends
        $FunctionalProvider<CoachRepository, CoachRepository, CoachRepository>
    with $Provider<CoachRepository> {
  /// The `CoachRepository` coach sessions and transcripts are stored through.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
  /// only, to the device-only file store; on macOS it stays unbound, so a Mac
  /// path that reads it fails loudly instead of quietly creating a store
  /// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
  /// override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless (D6).
  CoachRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachRepositoryHash();

  @$internal
  @override
  $ProviderElement<CoachRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachRepository create(Ref ref) {
    return coachRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachRepository>(value),
    );
  }
}

String _$coachRepositoryHash() => r'33015002c10110eccfc36663949035be74915bfc';

/// Whether this device has the coach at all: `true` on iOS only.
///
/// A platform fact, not the model's runtime availability (whether this
/// iPhone supports Apple Intelligence and the model is ready), which the
/// coach checks separately when a session starts. `false` by default;
/// `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the coach's Settings card renders nothing.
///
/// `keepAlive`: a constant for the app's lifetime.

@ProviderFor(coachSupportAvailable)
final coachSupportAvailableProvider = CoachSupportAvailableProvider._();

/// Whether this device has the coach at all: `true` on iOS only.
///
/// A platform fact, not the model's runtime availability (whether this
/// iPhone supports Apple Intelligence and the model is ready), which the
/// coach checks separately when a session starts. `false` by default;
/// `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the coach's Settings card renders nothing.
///
/// `keepAlive`: a constant for the app's lifetime.

final class CoachSupportAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this device has the coach at all: `true` on iOS only.
  ///
  /// A platform fact, not the model's runtime availability (whether this
  /// iPhone supports Apple Intelligence and the model is ready), which the
  /// coach checks separately when a session starts. `false` by default;
  /// `app/lib/providers.dart` sets it from the platform
  /// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
  /// it's `false` the coach's Settings card renders nothing.
  ///
  /// `keepAlive`: a constant for the app's lifetime.
  CoachSupportAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachSupportAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachSupportAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return coachSupportAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$coachSupportAvailableHash() =>
    r'66af6f8ec10efe0f25537579d583370a0a49df0a';
