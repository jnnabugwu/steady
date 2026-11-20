// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'onboarding.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How the person tracks food, from onboarding screen 2 or Settings → About
/// me, or `null`: not answered, no onboarding on this device, or the record
/// couldn't be read.
///
/// **The one source** for everything on Today that follows the answer
/// ([todayImportButtonShownProvider], [todayMetricsEmptyHintProvider] and
/// `todayHealthPromptProvider`): whoever writes the record invalidates
/// this, and they all follow. The onboarding route does on the way out,
/// and Settings → About me after every edit (`AboutMeRoute`), so Today
/// changes straight away, without a relaunch.
///
/// Auto-dispose: read again whenever Today is built afresh too.

@ProviderFor(onboardingFoodTracking)
final onboardingFoodTrackingProvider = OnboardingFoodTrackingProvider._();

/// How the person tracks food, from onboarding screen 2 or Settings → About
/// me, or `null`: not answered, no onboarding on this device, or the record
/// couldn't be read.
///
/// **The one source** for everything on Today that follows the answer
/// ([todayImportButtonShownProvider], [todayMetricsEmptyHintProvider] and
/// `todayHealthPromptProvider`): whoever writes the record invalidates
/// this, and they all follow. The onboarding route does on the way out,
/// and Settings → About me after every edit (`AboutMeRoute`), so Today
/// changes straight away, without a relaunch.
///
/// Auto-dispose: read again whenever Today is built afresh too.

final class OnboardingFoodTrackingProvider
    extends
        $FunctionalProvider<
          AsyncValue<FoodTracking?>,
          FoodTracking?,
          FutureOr<FoodTracking?>
        >
    with $FutureModifier<FoodTracking?>, $FutureProvider<FoodTracking?> {
  /// How the person tracks food, from onboarding screen 2 or Settings → About
  /// me, or `null`: not answered, no onboarding on this device, or the record
  /// couldn't be read.
  ///
  /// **The one source** for everything on Today that follows the answer
  /// ([todayImportButtonShownProvider], [todayMetricsEmptyHintProvider] and
  /// `todayHealthPromptProvider`): whoever writes the record invalidates
  /// this, and they all follow. The onboarding route does on the way out,
  /// and Settings → About me after every edit (`AboutMeRoute`), so Today
  /// changes straight away, without a relaunch.
  ///
  /// Auto-dispose: read again whenever Today is built afresh too.
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

/// What Today's empty-metrics card says, from screen 2's answer: the Cal AI
/// import for `calAi` and no answer (also while loading, or unreadable), a
/// note that another food app's calories come through Apple Health for
/// `otherHealthApp`, and no ask at all for `justStarting`.

@ProviderFor(todayMetricsEmptyHint)
final todayMetricsEmptyHintProvider = TodayMetricsEmptyHintProvider._();

/// What Today's empty-metrics card says, from screen 2's answer: the Cal AI
/// import for `calAi` and no answer (also while loading, or unreadable), a
/// note that another food app's calories come through Apple Health for
/// `otherHealthApp`, and no ask at all for `justStarting`.

final class TodayMetricsEmptyHintProvider
    extends
        $FunctionalProvider<
          TodayMetricsEmptyHint,
          TodayMetricsEmptyHint,
          TodayMetricsEmptyHint
        >
    with $Provider<TodayMetricsEmptyHint> {
  /// What Today's empty-metrics card says, from screen 2's answer: the Cal AI
  /// import for `calAi` and no answer (also while loading, or unreadable), a
  /// note that another food app's calories come through Apple Health for
  /// `otherHealthApp`, and no ask at all for `justStarting`.
  TodayMetricsEmptyHintProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'todayMetricsEmptyHintProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$todayMetricsEmptyHintHash();

  @$internal
  @override
  $ProviderElement<TodayMetricsEmptyHint> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TodayMetricsEmptyHint create(Ref ref) {
    return todayMetricsEmptyHint(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodayMetricsEmptyHint value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodayMetricsEmptyHint>(value),
    );
  }
}

String _$todayMetricsEmptyHintHash() =>
    r'ec53be6f713bc9b4d56cabf92c505c91b7f2b29a';

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
