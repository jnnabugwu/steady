// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the person tracks food, from onboarding screen 2, or `null`: not
/// answered, no onboarding on this device, or the record couldn't be read.
///
/// Auto-dispose: read again whenever Today is built afresh, which is the
/// case after onboarding (it replaces the shell); the onboarding route
/// also invalidates it on the way out.

@ProviderFor(onboardingFoodTracking)
final onboardingFoodTrackingProvider = OnboardingFoodTrackingProvider._();

/// How the person tracks food, from onboarding screen 2, or `null`: not
/// answered, no onboarding on this device, or the record couldn't be read.
///
/// Auto-dispose: read again whenever Today is built afresh, which is the
/// case after onboarding (it replaces the shell); the onboarding route
/// also invalidates it on the way out.

final class OnboardingFoodTrackingProvider
    extends
        $FunctionalProvider<
          AsyncValue<FoodTracking?>,
          FoodTracking?,
          FutureOr<FoodTracking?>
        >
    with $FutureModifier<FoodTracking?>, $FutureProvider<FoodTracking?> {
  /// How the person tracks food, from onboarding screen 2, or `null`: not
  /// answered, no onboarding on this device, or the record couldn't be read.
  ///
  /// Auto-dispose: read again whenever Today is built afresh, which is the
  /// case after onboarding (it replaces the shell); the onboarding route
  /// also invalidates it on the way out.
  OnboardingFoodTrackingProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'onboardingFoodTrackingProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$onboardingFoodTrackingHash();

  @$internal
  @override
  $FutureProviderElement<FoodTracking?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<FoodTracking?> create(Ref ref) {
    return onboardingFoodTracking(ref);
  }
}

String _$onboardingFoodTrackingHash() =>
    r'59e97e87a80fab78acdc0e95ef1d1fcee7d9eb24';

/// Whether Today's header shows the Cal AI import button
/// (docs/design/onboarding.md, screen 2: the answer decides it). Hidden
/// only for someone who said they track with another Health app, or are
/// just starting; shown for Cal AI, no answer, and while the answer is
/// still being read. The Week tab's header keeps its import button for
/// everyone.

@ProviderFor(todayImportButtonShown)
final todayImportButtonShownProvider = TodayImportButtonShownProvider._();

/// Whether Today's header shows the Cal AI import button
/// (docs/design/onboarding.md, screen 2: the answer decides it). Hidden
/// only for someone who said they track with another Health app, or are
/// just starting; shown for Cal AI, no answer, and while the answer is
/// still being read. The Week tab's header keeps its import button for
/// everyone.

final class TodayImportButtonShownProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether Today's header shows the Cal AI import button
  /// (docs/design/onboarding.md, screen 2: the answer decides it). Hidden
  /// only for someone who said they track with another Health app, or are
  /// just starting; shown for Cal AI, no answer, and while the answer is
  /// still being read. The Week tab's header keeps its import button for
  /// everyone.
  TodayImportButtonShownProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayImportButtonShownProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayImportButtonShownHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return todayImportButtonShown(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$todayImportButtonShownHash() =>
    r'71e92e9b382457de2f42587bb83cb88f615eef79';
