// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_history_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Whether the on-device model can run on this iPhone now: its
/// [CoachModelInfo], or an `AsyncError` carrying the typed
/// [CoachModelUnavailableFailure] that says why not.
///
/// iPhone only: read it only where `coachSupportAvailableProvider` is
/// `true`, since the model isn't bound anywhere else. Auto-dispose; the app
/// invalidates it on every return to the foreground, since the person may
/// have turned Apple Intelligence on in Settings meanwhile.

@ProviderFor(coachAvailability)
final coachAvailabilityProvider = CoachAvailabilityProvider._();

/// Whether the on-device model can run on this iPhone now: its
/// [CoachModelInfo], or an `AsyncError` carrying the typed
/// [CoachModelUnavailableFailure] that says why not.
///
/// iPhone only: read it only where `coachSupportAvailableProvider` is
/// `true`, since the model isn't bound anywhere else. Auto-dispose; the app
/// invalidates it on every return to the foreground, since the person may
/// have turned Apple Intelligence on in Settings meanwhile.

final class CoachAvailabilityProvider
    extends
        $FunctionalProvider<
          AsyncValue<CoachModelInfo>,
          CoachModelInfo,
          FutureOr<CoachModelInfo>
        >
    with $FutureModifier<CoachModelInfo>, $FutureProvider<CoachModelInfo> {
  /// Whether the on-device model can run on this iPhone now: its
  /// [CoachModelInfo], or an `AsyncError` carrying the typed
  /// [CoachModelUnavailableFailure] that says why not.
  ///
  /// iPhone only: read it only where `coachSupportAvailableProvider` is
  /// `true`, since the model isn't bound anywhere else. Auto-dispose; the app
  /// invalidates it on every return to the foreground, since the person may
  /// have turned Apple Intelligence on in Settings meanwhile.
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
  $FutureProviderElement<CoachModelInfo> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<CoachModelInfo> create(Ref ref) {
    return coachAvailability(ref);
  }
}

String _$coachAvailabilityHash() => r'2ba330f544666ffd49e156dc7c9ff983641aca7b';

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
