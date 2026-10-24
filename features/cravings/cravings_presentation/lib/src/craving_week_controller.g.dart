// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'craving_week_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The last seven days of craving check-ins, summarized for the home
/// screen ([summarizeCravingWeek]).
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A saved check-in and
/// "Delete craving history" both invalidate it. Never built where craving
/// support isn't offered (the home section checks first).

@ProviderFor(CravingWeekController)
final cravingWeekControllerProvider = CravingWeekControllerProvider._();

/// The last seven days of craving check-ins, summarized for the home
/// screen ([summarizeCravingWeek]).
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A saved check-in and
/// "Delete craving history" both invalidate it. Never built where craving
/// support isn't offered (the home section checks first).
final class CravingWeekControllerProvider
    extends $AsyncNotifierProvider<CravingWeekController, CravingWeekSummary> {
  /// The last seven days of craving check-ins, summarized for the home
  /// screen ([summarizeCravingWeek]).
  ///
  /// Screen-scoped, so auto-dispose (CLAUDE.md §4). A saved check-in and
  /// "Delete craving history" both invalidate it. Never built where craving
  /// support isn't offered (the home section checks first).
  CravingWeekControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'cravingWeekControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$cravingWeekControllerHash();

  @$internal
  @override
  CravingWeekController create() => CravingWeekController();
}

String _$cravingWeekControllerHash() =>
    r'eaddfc49ae05ebf0ec38ee24feeb9678264b18c3';

/// The last seven days of craving check-ins, summarized for the home
/// screen ([summarizeCravingWeek]).
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A saved check-in and
/// "Delete craving history" both invalidate it. Never built where craving
/// support isn't offered (the home section checks first).

abstract class _$CravingWeekController
    extends $AsyncNotifier<CravingWeekSummary> {
  FutureOr<CravingWeekSummary> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref =
        this.ref as $Ref<AsyncValue<CravingWeekSummary>, CravingWeekSummary>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CravingWeekSummary>, CravingWeekSummary>,
              AsyncValue<CravingWeekSummary>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
