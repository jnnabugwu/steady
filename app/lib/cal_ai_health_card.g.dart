// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cal_ai_health_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where "Not now" is remembered. In memory by default; `main.dart` binds a
/// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(calAiCardSnoozeStore)
final calAiCardSnoozeStoreProvider = CalAiCardSnoozeStoreProvider._();

/// Where "Not now" is remembered. In memory by default; `main.dart` binds a
/// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
///
/// `keepAlive`: cheap and stateless (D6).

final class CalAiCardSnoozeStoreProvider
    extends
        $FunctionalProvider<
          CalAiCardSnoozeStore,
          CalAiCardSnoozeStore,
          CalAiCardSnoozeStore
        >
    with $Provider<CalAiCardSnoozeStore> {
  /// Where "Not now" is remembered. In memory by default; `main.dart` binds a
  /// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CalAiCardSnoozeStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calAiCardSnoozeStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calAiCardSnoozeStoreHash();

  @$internal
  @override
  $ProviderElement<CalAiCardSnoozeStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalAiCardSnoozeStore create(Ref ref) {
    return calAiCardSnoozeStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalAiCardSnoozeStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalAiCardSnoozeStore>(value),
    );
  }
}

String _$calAiCardSnoozeStoreHash() =>
    r'4b4eaf1934610b2745d1de5efb4ed19138c9ba12';

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.

@ProviderFor(CalAiCardSnooze)
final calAiCardSnoozeProvider = CalAiCardSnoozeProvider._();

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.
final class CalAiCardSnoozeProvider
    extends $AsyncNotifierProvider<CalAiCardSnooze, DateTime?> {
  /// When "Not now" was last tapped on the card, or `null`.
  ///
  /// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
  /// it's one value, not a family.
  CalAiCardSnoozeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calAiCardSnoozeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calAiCardSnoozeHash();

  @$internal
  @override
  CalAiCardSnooze create() => CalAiCardSnooze();
}

String _$calAiCardSnoozeHash() => r'63ceec0d0684fde64de84eebf1fde592a61d5476';

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.

abstract class _$CalAiCardSnooze extends $AsyncNotifier<DateTime?> {
  FutureOr<DateTime?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DateTime?>, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime?>, DateTime?>,
              AsyncValue<DateTime?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
