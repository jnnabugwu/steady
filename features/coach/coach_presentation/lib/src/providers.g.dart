// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `CoachRepository` coach sessions and transcripts are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store
/// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: unlike most repositories (D6), the file store is stateful —
/// it owns the loaded sessions and the queue that serialises every write.
/// One instance has to own both, so disposing it mid-write is not an option.

@ProviderFor(coachRepository)
final coachRepositoryProvider = CoachRepositoryProvider._();

/// The `CoachRepository` coach sessions and transcripts are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store
/// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: unlike most repositories (D6), the file store is stateful —
/// it owns the loaded sessions and the queue that serialises every write.
/// One instance has to own both, so disposing it mid-write is not an option.

final class CoachRepositoryProvider
    extends
        $FunctionalProvider<CoachRepository, CoachRepository, CoachRepository>
    with $Provider<CoachRepository> {
  /// The `CoachRepository` coach sessions and transcripts are stored through.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
  /// only, to the device-only file store; on macOS it stays unbound, so a Mac
  /// path that reads it fails loudly instead of quietly creating a store
  /// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
  /// override throws.
  ///
  /// `keepAlive`: unlike most repositories (D6), the file store is stateful —
  /// it owns the loaded sessions and the queue that serialises every write.
  /// One instance has to own both, so disposing it mid-write is not an option.
  CoachRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachRepositoryHash();

  @$internal
  @override
  $ProviderElement<CoachRepository> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachRepository create(Ref ref) {
    return coachRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachRepository>(value),
    );
  }
}

String _$coachRepositoryHash() => r'33015002c10110eccfc36663949035be74915bfc';

/// Whether this device has the coach at all: `true` on iOS only.
///
/// A platform fact, not the model's runtime availability (whether this
/// iPhone supports Apple Intelligence and the model is ready), which the
/// coach checks separately when a session starts. `false` by default;
/// `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the coach's Settings card renders nothing.
///
/// `keepAlive`: a constant for the app's lifetime.

@ProviderFor(coachSupportAvailable)
final coachSupportAvailableProvider = CoachSupportAvailableProvider._();

/// Whether this device has the coach at all: `true` on iOS only.
///
/// A platform fact, not the model's runtime availability (whether this
/// iPhone supports Apple Intelligence and the model is ready), which the
/// coach checks separately when a session starts. `false` by default;
/// `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the coach's Settings card renders nothing.
///
/// `keepAlive`: a constant for the app's lifetime.

final class CoachSupportAvailableProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  /// Whether this device has the coach at all: `true` on iOS only.
  ///
  /// A platform fact, not the model's runtime availability (whether this
  /// iPhone supports Apple Intelligence and the model is ready), which the
  /// coach checks separately when a session starts. `false` by default;
  /// `app/lib/providers.dart` sets it from the platform
  /// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
  /// it's `false` the coach's Settings card renders nothing.
  ///
  /// `keepAlive`: a constant for the app's lifetime.
  CoachSupportAvailableProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachSupportAvailableProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachSupportAvailableHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return coachSupportAvailable(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$coachSupportAvailableHash() =>
    r'66af6f8ec10efe0f25537579d583370a0a49df0a';

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

/// Check-in statuses, for the coach's context. Bound by the app to the
/// check-in feature's own repository (the same instance, so the same
/// shared store; CLAUDE.md §9). Typed against `checkin_domain` only.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachCheckInRepository)
final coachCheckInRepositoryProvider = CoachCheckInRepositoryProvider._();

/// Check-in statuses, for the coach's context. Bound by the app to the
/// check-in feature's own repository (the same instance, so the same
/// shared store; CLAUDE.md §9). Typed against `checkin_domain` only.
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachCheckInRepositoryProvider
    extends
        $FunctionalProvider<
          CheckInRepository,
          CheckInRepository,
          CheckInRepository
        >
    with $Provider<CheckInRepository> {
  /// Check-in statuses, for the coach's context. Bound by the app to the
  /// check-in feature's own repository (the same instance, so the same
  /// shared store; CLAUDE.md §9). Typed against `checkin_domain` only.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachCheckInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachCheckInRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachCheckInRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheckInRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckInRepository create(Ref ref) {
    return coachCheckInRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInRepository>(value),
    );
  }
}

String _$coachCheckInRepositoryHash() =>
    r'cca806147ffa85db4bb14e57983513626d837e48';

/// Calories eaten, for the coach's context. Bound by the app to the
/// metrics feature's repository (the same instance). Typed against
/// `metrics_domain` only.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachMetricsRepository)
final coachMetricsRepositoryProvider = CoachMetricsRepositoryProvider._();

/// Calories eaten, for the coach's context. Bound by the app to the
/// metrics feature's repository (the same instance). Typed against
/// `metrics_domain` only.
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachMetricsRepositoryProvider
    extends
        $FunctionalProvider<
          MetricsRepository,
          MetricsRepository,
          MetricsRepository
        >
    with $Provider<MetricsRepository> {
  /// Calories eaten, for the coach's context. Bound by the app to the
  /// metrics feature's repository (the same instance). Typed against
  /// `metrics_domain` only.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachMetricsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachMetricsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachMetricsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MetricsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MetricsRepository create(Ref ref) {
    return coachMetricsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRepository>(value),
    );
  }
}

String _$coachMetricsRepositoryHash() =>
    r'b00b621abc119065c9750a186850a5fcf4ddf93c';

/// Apple Health's daily totals, read live for the coach's context and
/// never stored, or `null` where there's no Health (CLAUDE.md §7). Bound
/// by the app to its one Health source.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachHealthKitRepository)
final coachHealthKitRepositoryProvider = CoachHealthKitRepositoryProvider._();

/// Apple Health's daily totals, read live for the coach's context and
/// never stored, or `null` where there's no Health (CLAUDE.md §7). Bound
/// by the app to its one Health source.
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachHealthKitRepositoryProvider
    extends
        $FunctionalProvider<
          HealthKitRepository?,
          HealthKitRepository?,
          HealthKitRepository?
        >
    with $Provider<HealthKitRepository?> {
  /// Apple Health's daily totals, read live for the coach's context and
  /// never stored, or `null` where there's no Health (CLAUDE.md §7). Bound
  /// by the app to its one Health source.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachHealthKitRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachHealthKitRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachHealthKitRepositoryHash();

  @$internal
  @override
  $ProviderElement<HealthKitRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  HealthKitRepository? create(Ref ref) {
    return coachHealthKitRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(HealthKitRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<HealthKitRepository?>(value),
    );
  }
}

String _$coachHealthKitRepositoryHash() =>
    r'031dc71e31c550966ff8a3b7fa1a86e64d341647';

/// Craving check-ins, for the coach's context (counts, time of day and
/// reasons; never turned into calorie advice, #82), or `null` where
/// craving support isn't bound. Bound by the app to the cravings
/// feature's repository (the same instance, so the same device-only file).
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachCravingRepository)
final coachCravingRepositoryProvider = CoachCravingRepositoryProvider._();

/// Craving check-ins, for the coach's context (counts, time of day and
/// reasons; never turned into calorie advice, #82), or `null` where
/// craving support isn't bound. Bound by the app to the cravings
/// feature's repository (the same instance, so the same device-only file).
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachCravingRepositoryProvider
    extends
        $FunctionalProvider<
          CravingRepository?,
          CravingRepository?,
          CravingRepository?
        >
    with $Provider<CravingRepository?> {
  /// Craving check-ins, for the coach's context (counts, time of day and
  /// reasons; never turned into calorie advice, #82), or `null` where
  /// craving support isn't bound. Bound by the app to the cravings
  /// feature's repository (the same instance, so the same device-only file).
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachCravingRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachCravingRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachCravingRepositoryHash();

  @$internal
  @override
  $ProviderElement<CravingRepository?> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CravingRepository? create(Ref ref) {
    return coachCravingRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CravingRepository? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CravingRepository?>(value),
    );
  }
}

String _$coachCravingRepositoryHash() =>
    r'795bf393e7a32a0229255fd06a41ec63054ae290';

/// The clock the coach reads "now" from (session start, message times, the
/// context's days). Defaults to [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachClock)
final coachClockProvider = CoachClockProvider._();

/// The clock the coach reads "now" from (session start, message times, the
/// context's days). Defaults to [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachClockProvider
    extends $FunctionalProvider<CoachClock, CoachClock, CoachClock>
    with $Provider<CoachClock> {
  /// The clock the coach reads "now" from (session start, message times, the
  /// context's days). Defaults to [DateTime.now]; tests pin it.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachClockHash();

  @$internal
  @override
  $ProviderElement<CoachClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachClock create(Ref ref) {
    return coachClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachClock>(value),
    );
  }
}

String _$coachClockHash() => r'3058842c244af0777bcd2fcaef1086df11a9a720';

/// The id generator for new coach sessions: a random version 4 UUID by
/// default ([randomCoachSessionId]); tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(coachIdGenerator)
final coachIdGeneratorProvider = CoachIdGeneratorProvider._();

/// The id generator for new coach sessions: a random version 4 UUID by
/// default ([randomCoachSessionId]); tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

final class CoachIdGeneratorProvider
    extends
        $FunctionalProvider<
          CoachIdGenerator,
          CoachIdGenerator,
          CoachIdGenerator
        >
    with $Provider<CoachIdGenerator> {
  /// The id generator for new coach sessions: a random version 4 UUID by
  /// default ([randomCoachSessionId]); tests pin it.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CoachIdGeneratorProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachIdGeneratorProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachIdGeneratorHash();

  @$internal
  @override
  $ProviderElement<CoachIdGenerator> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CoachIdGenerator create(Ref ref) {
    return coachIdGenerator(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachIdGenerator value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachIdGenerator>(value),
    );
  }
}

String _$coachIdGeneratorHash() => r'5ee441b420fc850db702f2df60f73966519784f9';

/// The weekly session's gate: the 4-of-7 check-in rule (#81, CLAUDE.md
/// §4), over [coachCheckInRepositoryProvider].

@ProviderFor(coachWeeklyReadiness)
final coachWeeklyReadinessProvider = CoachWeeklyReadinessProvider._();

/// The weekly session's gate: the 4-of-7 check-in rule (#81, CLAUDE.md
/// §4), over [coachCheckInRepositoryProvider].

final class CoachWeeklyReadinessProvider
    extends
        $FunctionalProvider<
          CheckWeeklyReadiness,
          CheckWeeklyReadiness,
          CheckWeeklyReadiness
        >
    with $Provider<CheckWeeklyReadiness> {
  /// The weekly session's gate: the 4-of-7 check-in rule (#81, CLAUDE.md
  /// §4), over [coachCheckInRepositoryProvider].
  CoachWeeklyReadinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachWeeklyReadinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachWeeklyReadinessHash();

  @$internal
  @override
  $ProviderElement<CheckWeeklyReadiness> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckWeeklyReadiness create(Ref ref) {
    return coachWeeklyReadiness(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckWeeklyReadiness value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckWeeklyReadiness>(value),
    );
  }
}

String _$coachWeeklyReadinessHash() =>
    r'59feec0dcc2352573c5dcab07029443ad0ec572a';

/// The use case that builds the coach's context from the four domains
/// above (CLAUDE.md §4: it combines several repositories).

@ProviderFor(coachWeekContext)
final coachWeekContextProvider = CoachWeekContextProvider._();

/// The use case that builds the coach's context from the four domains
/// above (CLAUDE.md §4: it combines several repositories).

final class CoachWeekContextProvider
    extends
        $FunctionalProvider<
          BuildCoachWeekContext,
          BuildCoachWeekContext,
          BuildCoachWeekContext
        >
    with $Provider<BuildCoachWeekContext> {
  /// The use case that builds the coach's context from the four domains
  /// above (CLAUDE.md §4: it combines several repositories).
  CoachWeekContextProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachWeekContextProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachWeekContextHash();

  @$internal
  @override
  $ProviderElement<BuildCoachWeekContext> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BuildCoachWeekContext create(Ref ref) {
    return coachWeekContext(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BuildCoachWeekContext value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BuildCoachWeekContext>(value),
    );
  }
}

String _$coachWeekContextHash() => r'c23761a2870a1b0e491cc130ece2f23758e5b49d';
