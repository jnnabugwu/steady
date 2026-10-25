// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_history_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Settings' "Delete coach history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).

@ProviderFor(CoachHistoryController)
final coachHistoryControllerProvider = CoachHistoryControllerProvider._();

/// Settings' "Delete coach history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).
final class CoachHistoryControllerProvider
    extends $AsyncNotifierProvider<CoachHistoryController, bool> {
  /// Settings' "Delete coach history".
  ///
  /// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
  /// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
  /// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).
  CoachHistoryControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachHistoryControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachHistoryControllerHash();

  @$internal
  @override
  CoachHistoryController create() => CoachHistoryController();
}

String _$coachHistoryControllerHash() =>
    r'c39865b01c4612592a98feb521cd944cf3e34071';

/// Settings' "Delete coach history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).

abstract class _$CoachHistoryController extends $AsyncNotifier<bool> {
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
