// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'craving_flow_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One run of the craving flow, from "Having a craving?" to its ending.
///
/// Auto-dispose (CLAUDE.md §4): one flow per visit to the screen, gone when
/// it closes. Nothing is stored until the flow reaches an ending (hungry,
/// or an outcome at "Still want it?"); closing partway records nothing.
///
/// Every public method is one domain event (CLAUDE.md §4) and is ignored
/// unless the flow is at the step it belongs to, so a double tap can't
/// skip a step or save twice.

@ProviderFor(CravingFlowController)
final cravingFlowControllerProvider = CravingFlowControllerProvider._();

/// One run of the craving flow, from "Having a craving?" to its ending.
///
/// Auto-dispose (CLAUDE.md §4): one flow per visit to the screen, gone when
/// it closes. Nothing is stored until the flow reaches an ending (hungry,
/// or an outcome at "Still want it?"); closing partway records nothing.
///
/// Every public method is one domain event (CLAUDE.md §4) and is ignored
/// unless the flow is at the step it belongs to, so a double tap can't
/// skip a step or save twice.
final class CravingFlowControllerProvider
    extends $NotifierProvider<CravingFlowController, CravingFlowState> {
  /// One run of the craving flow, from "Having a craving?" to its ending.
  ///
  /// Auto-dispose (CLAUDE.md §4): one flow per visit to the screen, gone when
  /// it closes. Nothing is stored until the flow reaches an ending (hungry,
  /// or an outcome at "Still want it?"); closing partway records nothing.
  ///
  /// Every public method is one domain event (CLAUDE.md §4) and is ignored
  /// unless the flow is at the step it belongs to, so a double tap can't
  /// skip a step or save twice.
  CravingFlowControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'cravingFlowControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingFlowControllerHash();

  @$internal
  @override
  CravingFlowController create() => CravingFlowController();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CravingFlowState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CravingFlowState>(value),
    );
  }
}

String _$cravingFlowControllerHash() =>
    r'e915b077f2587a2779998ba7b366ae6f29b57bfb';

/// One run of the craving flow, from "Having a craving?" to its ending.
///
/// Auto-dispose (CLAUDE.md §4): one flow per visit to the screen, gone when
/// it closes. Nothing is stored until the flow reaches an ending (hungry,
/// or an outcome at "Still want it?"); closing partway records nothing.
///
/// Every public method is one domain event (CLAUDE.md §4) and is ignored
/// unless the flow is at the step it belongs to, so a double tap can't
/// skip a step or save twice.

abstract class _$CravingFlowController extends $Notifier<CravingFlowState> {
  CravingFlowState build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<CravingFlowState, CravingFlowState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<CravingFlowState, CravingFlowState>,
              CravingFlowState,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
