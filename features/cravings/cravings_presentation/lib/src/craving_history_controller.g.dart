// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'craving_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Settings' "Delete craving history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).

@ProviderFor(CravingHistoryController)
final cravingHistoryControllerProvider = CravingHistoryControllerProvider._();

/// Settings' "Delete craving history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).
final class CravingHistoryControllerProvider
    extends $AsyncNotifierProvider<CravingHistoryController, bool> {
  /// Settings' "Delete craving history".
  ///
  /// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
  /// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
  /// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).
  CravingHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingHistoryControllerHash();

  @$internal
  @override
  CravingHistoryController create() => CravingHistoryController();
}

String _$cravingHistoryControllerHash() =>
    r'32b294628debd82a811107cff08bbf2437887ef4';

/// Settings' "Delete craving history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).

abstract class _$CravingHistoryController extends $AsyncNotifier<bool> {
  FutureOr<bool> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<bool>, bool>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<bool>, bool>,
              AsyncValue<bool>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
