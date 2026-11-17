// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the coach can run on this iPhone now, before anything is sent:
/// `unit`, or an `AsyncError` carrying the typed [CoachUnavailableFailure]
/// that says why not ([checkCoachAvailable]). Rebuilds when consent
/// changes (given, or withdrawn in Settings → Coach).
///
/// iPhone only: read it only where `coachSupportAvailableProvider` is
/// `true`, since the model isn't bound anywhere else. **Never calls the
/// network** (CLAUDE.md §11: the nudge and the Coach tab must not call the
/// model). Auto-dispose; the app invalidates it on every return to the
/// foreground, cheaply.

@ProviderFor(coachAvailability)
final coachAvailabilityProvider = CoachAvailabilityProvider._();

/// Whether the coach can run on this iPhone now, before anything is sent:
/// `unit`, or an `AsyncError` carrying the typed [CoachUnavailableFailure]
/// that says why not ([checkCoachAvailable]). Rebuilds when consent
/// changes (given, or withdrawn in Settings → Coach).
///
/// iPhone only: read it only where `coachSupportAvailableProvider` is
/// `true`, since the model isn't bound anywhere else. **Never calls the
/// network** (CLAUDE.md §11: the nudge and the Coach tab must not call the
/// model). Auto-dispose; the app invalidates it on every return to the
/// foreground, cheaply.

final class CoachAvailabilityProvider
    extends $FunctionalProvider<AsyncValue<Unit>, Unit, FutureOr<Unit>>
    with $FutureModifier<Unit>, $FutureProvider<Unit> {
  /// Whether the coach can run on this iPhone now, before anything is sent:
  /// `unit`, or an `AsyncError` carrying the typed [CoachUnavailableFailure]
  /// that says why not ([checkCoachAvailable]). Rebuilds when consent
  /// changes (given, or withdrawn in Settings → Coach).
  ///
  /// iPhone only: read it only where `coachSupportAvailableProvider` is
  /// `true`, since the model isn't bound anywhere else. **Never calls the
  /// network** (CLAUDE.md §11: the nudge and the Coach tab must not call the
  /// model). Auto-dispose; the app invalidates it on every return to the
  /// foreground, cheaply.
  CoachAvailabilityProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'coachAvailabilityProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachAvailabilityHash();

  @$internal
  @override
  $FutureProviderElement<Unit> $createElement($ProviderPointer pointer) =>
      $FutureProviderElement(pointer);

  @override
  FutureOr<Unit> create(Ref ref) {
    return coachAvailability(ref);
  }
}

String _$coachAvailabilityHash() => r'21cbe0160544cc80cfb905e7f37f32051ac8edb2';

/// Every stored coach session, newest first, read locally from
/// `CoachRepository`. The live session invalidates it after each save, and
/// "Delete coach history" after a delete.

@ProviderFor(coachSessionList)
final coachSessionListProvider = CoachSessionListProvider._();

/// Every stored coach session, newest first, read locally from
/// `CoachRepository`. The live session invalidates it after each save, and
/// "Delete coach history" after a delete.

final class CoachSessionListProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<CoachSession>>,
          List<CoachSession>,
          FutureOr<List<CoachSession>>
        >
    with
        $FutureModifier<List<CoachSession>>,
        $FutureProvider<List<CoachSession>> {
  /// Every stored coach session, newest first, read locally from
  /// `CoachRepository`. The live session invalidates it after each save, and
  /// "Delete coach history" after a delete.
  CoachSessionListProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'coachSessionListProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachSessionListHash();

  @$internal
  @override
  $FutureProviderElement<List<CoachSession>> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<List<CoachSession>> create(Ref ref) {
    return coachSessionList(ref);
  }
}

String _$coachSessionListHash() => r'f8e81789d4fa68060bfd4bc68f37adde23849ff6';

/// The stored session [id], or `null` if it isn't on this iPhone (any
/// more), for the read-only transcript.

@ProviderFor(coachStoredSession)
final coachStoredSessionProvider = CoachStoredSessionFamily._();

/// The stored session [id], or `null` if it isn't on this iPhone (any
/// more), for the read-only transcript.

final class CoachStoredSessionProvider
    extends
        $FunctionalProvider<
          AsyncValue<CoachSession?>,
          CoachSession?,
          FutureOr<CoachSession?>
        >
    with $FutureModifier<CoachSession?>, $FutureProvider<CoachSession?> {
  /// The stored session [id], or `null` if it isn't on this iPhone (any
  /// more), for the read-only transcript.
  CoachStoredSessionProvider._({
    required CoachStoredSessionFamily super.from,
    required String super.argument,
  }) : super(
         retry: _retryUnlessFailure,
         name: r'coachStoredSessionProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$coachStoredSessionHash();

  @override
  String toString() {
    return r'coachStoredSessionProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $FutureProviderElement<CoachSession?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CoachSession?> create(Ref ref) {
    final argument = this.argument as String;
    return coachStoredSession(ref, argument);
  }

  @override
  bool operator ==(Object other) {
    return other is CoachStoredSessionProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$coachStoredSessionHash() =>
    r'994c47116771b8ecee893ab1cc2d9620f7dbe7fa';

/// The stored session [id], or `null` if it isn't on this iPhone (any
/// more), for the read-only transcript.

final class CoachStoredSessionFamily extends $Family
    with $FunctionalFamilyOverride<FutureOr<CoachSession?>, String> {
  CoachStoredSessionFamily._()
    : super(
        retry: _retryUnlessFailure,
        name: r'coachStoredSessionProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The stored session [id], or `null` if it isn't on this iPhone (any
  /// more), for the read-only transcript.

  CoachStoredSessionProvider call(String id) =>
      CoachStoredSessionProvider._(argument: id, from: this);

  @override
  String toString() => r'coachStoredSessionProvider';
}

/// The one [CoachHistoryEpoch]. `keepAlive`: it must outlive every session
/// and the Settings card, or a recreated one would forget the delete.

@ProviderFor(coachHistoryEpoch)
final coachHistoryEpochProvider = CoachHistoryEpochProvider._();

/// The one [CoachHistoryEpoch]. `keepAlive`: it must outlive every session
/// and the Settings card, or a recreated one would forget the delete.

final class CoachHistoryEpochProvider
    extends
        $FunctionalProvider<
          CoachHistoryEpoch,
          CoachHistoryEpoch,
          CoachHistoryEpoch
        >
    with $Provider<CoachHistoryEpoch> {
  /// The one [CoachHistoryEpoch]. `keepAlive`: it must outlive every session
  /// and the Settings card, or a recreated one would forget the delete.
  CoachHistoryEpochProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachHistoryEpochProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachHistoryEpochHash();

  @$internal
  @override
  $ProviderElement<CoachHistoryEpoch> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CoachHistoryEpoch create(Ref ref) {
    return coachHistoryEpoch(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CoachHistoryEpoch value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CoachHistoryEpoch>(value),
    );
  }
}

String _$coachHistoryEpochHash() => r'a5bf468f9a4c11a5f9568b4e5e9d30ea43a807b8';
