// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sample_data_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// How many of the sample export's days are in the store; Settings shows
/// [SampleDataCard] only when it's at least 1.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): opening Settings counts
/// afresh. A remote change also re-counts it (`DailyMetricsRemoteRefresh`).

@ProviderFor(SampleDaysController)
final sampleDaysControllerProvider = SampleDaysControllerProvider._();

/// How many of the sample export's days are in the store; Settings shows
/// [SampleDataCard] only when it's at least 1.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): opening Settings counts
/// afresh. A remote change also re-counts it (`DailyMetricsRemoteRefresh`).
final class SampleDaysControllerProvider
    extends $AsyncNotifierProvider<SampleDaysController, int> {
  /// How many of the sample export's days are in the store; Settings shows
  /// [SampleDataCard] only when it's at least 1.
  ///
  /// Screen-scoped, so auto-dispose (CLAUDE.md §4): opening Settings counts
  /// afresh. A remote change also re-counts it (`DailyMetricsRemoteRefresh`).
  SampleDaysControllerProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'sampleDaysControllerProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$sampleDaysControllerHash();

  @$internal
  @override
  SampleDaysController create() => SampleDaysController();
}

String _$sampleDaysControllerHash() =>
    r'a54e06d966c648106aced941982ababeeb60177c';

/// How many of the sample export's days are in the store; Settings shows
/// [SampleDataCard] only when it's at least 1.
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4): opening Settings counts
/// afresh. A remote change also re-counts it (`DailyMetricsRemoteRefresh`).

abstract class _$SampleDaysController extends $AsyncNotifier<int> {
  FutureOr<int> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<int>, int>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<int>, int>,
              AsyncValue<int>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
