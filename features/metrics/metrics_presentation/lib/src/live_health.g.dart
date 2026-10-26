// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_health.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where the history reads Apple Health from, or `null` where there is no
/// Health to read (macOS, and tests that don't override it).
///
/// Typed against `health_sync_domain` only: this package never depends on
/// `health_sync_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it to
/// the app's one `healthKitRepositoryProvider`, which is non-null on iOS
/// only.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(metricsHealthKitRepository)
final metricsHealthKitRepositoryProvider =
    MetricsHealthKitRepositoryProvider._();

/// Where the history reads Apple Health from, or `null` where there is no
/// Health to read (macOS, and tests that don't override it).
///
/// Typed against `health_sync_domain` only: this package never depends on
/// `health_sync_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it to
/// the app's one `healthKitRepositoryProvider`, which is non-null on iOS
/// only.
///
/// `keepAlive`: cheap and stateless (D6).

final class MetricsHealthKitRepositoryProvider
    extends
        $FunctionalProvider<
          HealthKitRepository?,
          HealthKitRepository?,
          HealthKitRepository?
        >
    with $Provider<HealthKitRepository?> {
  /// Where the history reads Apple Health from, or `null` where there is no
  /// Health to read (macOS, and tests that don't override it).
  ///
  /// Typed against `health_sync_domain` only: this package never depends on
  /// `health_sync_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it to
  /// the app's one `healthKitRepositoryProvider`, which is non-null on iOS
  /// only.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  MetricsHealthKitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'metricsHealthKitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$metricsHealthKitRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthKitRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthKitRepository? create(Ref ref) {
    return metricsHealthKitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthKitRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthKitRepository?>(value),
    );
  }
}

String _$metricsHealthKitRepositoryHash() =>
    r'7d07515b053bc8805bd50a913144b4a3f19b27dd';

/// Apple Health's totals for each day from [start] to [end] (inclusive,
/// local midnights; build the key with [healthHistoryWindow]), keyed by
/// local midnight. Days where all of Health's values are unavailable (no
/// samples, or read access not granted — HealthKit doesn't say which) are
/// left out.
///
/// Empty where [metricsHealthKitRepositoryProvider] is `null` (macOS). A
/// Health error throws its [Failure] into `AsyncError`.
///
/// Auto-dispose, so the values live only while a screen shows them (never
/// `keepAlive`: CLAUDE.md §4 on families). The app re-reads it on every
/// return to the foreground by invalidating it, so today's steps stay
/// current.

@ProviderFor(healthDayTotals)
final healthDayTotalsProvider = HealthDayTotalsFamily._();

/// Apple Health's totals for each day from [start] to [end] (inclusive,
/// local midnights; build the key with [healthHistoryWindow]), keyed by
/// local midnight. Days where all of Health's values are unavailable (no
/// samples, or read access not granted — HealthKit doesn't say which) are
/// left out.
///
/// Empty where [metricsHealthKitRepositoryProvider] is `null` (macOS). A
/// Health error throws its [Failure] into `AsyncError`.
///
/// Auto-dispose, so the values live only while a screen shows them (never
/// `keepAlive`: CLAUDE.md §4 on families). The app re-reads it on every
/// return to the foreground by invalidating it, so today's steps stay
/// current.

final class HealthDayTotalsProvider
    extends
        $FunctionalProvider<
          AsyncValue<Map<DateTime, HealthDayTotals>>,
          Map<DateTime, HealthDayTotals>,
          FutureOr<Map<DateTime, HealthDayTotals>>
        >
    with
        $FutureModifier<Map<DateTime, HealthDayTotals>>,
        $FutureProvider<Map<DateTime, HealthDayTotals>> {
  /// Apple Health's totals for each day from [start] to [end] (inclusive,
  /// local midnights; build the key with [healthHistoryWindow]), keyed by
  /// local midnight. Days where all of Health's values are unavailable (no
  /// samples, or read access not granted — HealthKit doesn't say which) are
  /// left out.
  ///
  /// Empty where [metricsHealthKitRepositoryProvider] is `null` (macOS). A
  /// Health error throws its [Failure] into `AsyncError`.
  ///
  /// Auto-dispose, so the values live only while a screen shows them (never
  /// `keepAlive`: CLAUDE.md §4 on families). The app re-reads it on every
  /// return to the foreground by invalidating it, so today's steps stay
  /// current.
  HealthDayTotalsProvider._({
    required HealthDayTotalsFamily super.from,
    required (DateTime, DateTime) super.argument,
  }) : super(
         retry: _retryUnlessFailure,
         name: r'healthDayTotalsProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$healthDayTotalsHash();

  @override
  String toString() {
    return r'healthDayTotalsProvider'
        ''
        '$argument';
  }

  @$internal
  @override
  $FutureProviderElement<Map<DateTime, HealthDayTotals>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<Map<DateTime, HealthDayTotals>> create(Ref ref) {
    final argument = this.argument as (DateTime, DateTime);
    return healthDayTotals(ref, argument.$1, argument.$2);
  }

  @override
  bool operator ==(Object other) {
    return other is HealthDayTotalsProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$healthDayTotalsHash() => r'57d9df55ec16ee634ab9535158b9ee00910ed9f6';

/// Apple Health's totals for each day from [start] to [end] (inclusive,
/// local midnights; build the key with [healthHistoryWindow]), keyed by
/// local midnight. Days where all of Health's values are unavailable (no
/// samples, or read access not granted — HealthKit doesn't say which) are
/// left out.
///
/// Empty where [metricsHealthKitRepositoryProvider] is `null` (macOS). A
/// Health error throws its [Failure] into `AsyncError`.
///
/// Auto-dispose, so the values live only while a screen shows them (never
/// `keepAlive`: CLAUDE.md §4 on families). The app re-reads it on every
/// return to the foreground by invalidating it, so today's steps stay
/// current.

final class HealthDayTotalsFamily extends $Family
    with
        $FunctionalFamilyOverride<
          FutureOr<Map<DateTime, HealthDayTotals>>,
          (DateTime, DateTime)
        > {
  HealthDayTotalsFamily._()
    : super(
        retry: _retryUnlessFailure,
        name: r'healthDayTotalsProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Apple Health's totals for each day from [start] to [end] (inclusive,
  /// local midnights; build the key with [healthHistoryWindow]), keyed by
  /// local midnight. Days where all of Health's values are unavailable (no
  /// samples, or read access not granted — HealthKit doesn't say which) are
  /// left out.
  ///
  /// Empty where [metricsHealthKitRepositoryProvider] is `null` (macOS). A
  /// Health error throws its [Failure] into `AsyncError`.
  ///
  /// Auto-dispose, so the values live only while a screen shows them (never
  /// `keepAlive`: CLAUDE.md §4 on families). The app re-reads it on every
  /// return to the foreground by invalidating it, so today's steps stay
  /// current.

  HealthDayTotalsProvider call(DateTime start, DateTime end) =>
      HealthDayTotalsProvider._(argument: (start, end), from: this);

  @override
  String toString() => r'healthDayTotalsProvider';
}

/// The unit the Health app shows weight in, for Today's weight card.
/// Kilograms where [metricsHealthKitRepositoryProvider] is `null` (macOS,
/// which has no weight to show anyway). A Health error throws its
/// [Failure] into `AsyncError`; until the permission sheet has been shown,
/// that's the expected answer.
///
/// Auto-dispose like [healthDayTotalsProvider], and invalidated with it on
/// every refresh, so a unit changed in the Health app shows on return.

@ProviderFor(healthWeightUnit)
final healthWeightUnitProvider = HealthWeightUnitProvider._();

/// The unit the Health app shows weight in, for Today's weight card.
/// Kilograms where [metricsHealthKitRepositoryProvider] is `null` (macOS,
/// which has no weight to show anyway). A Health error throws its
/// [Failure] into `AsyncError`; until the permission sheet has been shown,
/// that's the expected answer.
///
/// Auto-dispose like [healthDayTotalsProvider], and invalidated with it on
/// every refresh, so a unit changed in the Health app shows on return.

final class HealthWeightUnitProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeightUnit>,
          WeightUnit,
          FutureOr<WeightUnit>
        >
    with $FutureModifier<WeightUnit>, $FutureProvider<WeightUnit> {
  /// The unit the Health app shows weight in, for Today's weight card.
  /// Kilograms where [metricsHealthKitRepositoryProvider] is `null` (macOS,
  /// which has no weight to show anyway). A Health error throws its
  /// [Failure] into `AsyncError`; until the permission sheet has been shown,
  /// that's the expected answer.
  ///
  /// Auto-dispose like [healthDayTotalsProvider], and invalidated with it on
  /// every refresh, so a unit changed in the Health app shows on return.
  HealthWeightUnitProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'healthWeightUnitProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$healthWeightUnitHash();

  @$internal
  @override
  $FutureProviderElement<WeightUnit> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<WeightUnit> create(Ref ref) {
    return healthWeightUnit(ref);
  }
}

String _$healthWeightUnitHash() => r'63156343d92cd7f75bb78e6524eb77a6bcd9a8c3';
