// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The on-device model the coach talks through (Apple Foundation Models).
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the `steady/coach` channel; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of reaching for a model that
/// isn't there (§11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: cheap and stateless (D6); the native side holds the
/// sessions.

@ProviderFor(coachModel)
final coachModelProvider = CoachModelProvider._();

/// The on-device model the coach talks through (Apple Foundation Models).
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the `steady/coach` channel; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of reaching for a model that
/// isn't there (§11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: cheap and stateless (D6); the native side holds the
/// sessions.

final class CoachModelProvider
    extends $FunctionalProvider<CoachModel, CoachModel, CoachModel>
    with $Provider<CoachModel> {
  /// The on-device model the coach talks through (Apple Foundation Models).
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
  /// only, to the `steady/coach` channel; on macOS it stays unbound, so a Mac
  /// path that reads it fails loudly instead of reaching for a model that
  /// isn't there (§11). Tests override it with a fake. Reading it without an
  /// override throws.
  ///
  /// `keepAlive`: cheap and stateless (D6); the native side holds the
  /// sessions.
  CoachModelProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachModelProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachModelHash();

  @$internal
  @override
  $ProviderElement<CoachModel> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachModel create(Ref ref) {
    return coachModel(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachModel>(value),
    );
  }
}

String _$coachModelHash() => r'683d504a6b6ec41f3f38295db61e9e43b875736a';
