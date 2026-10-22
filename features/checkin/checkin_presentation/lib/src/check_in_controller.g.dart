// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'check_in_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// One calendar day's check-in status.
///
/// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
/// normalize [date] to midnight before using it as the key, or the same day
/// at two different times becomes two providers. `CheckInModule` does this.
///
/// `null` data means nothing has been logged for that day yet. Errors are
/// always a typed [Failure].

@ProviderFor(CheckInController)
final checkInControllerProvider = CheckInControllerFamily._();

/// One calendar day's check-in status.
///
/// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
/// normalize [date] to midnight before using it as the key, or the same day
/// at two different times becomes two providers. `CheckInModule` does this.
///
/// `null` data means nothing has been logged for that day yet. Errors are
/// always a typed [Failure].
final class CheckInControllerProvider
    extends $AsyncNotifierProvider<CheckInController, CheckInStatus?> {
  /// One calendar day's check-in status.
  ///
  /// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
  /// normalize [date] to midnight before using it as the key, or the same day
  /// at two different times becomes two providers. `CheckInModule` does this.
  ///
  /// `null` data means nothing has been logged for that day yet. Errors are
  /// always a typed [Failure].
  CheckInControllerProvider._({
    required CheckInControllerFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: _retryUnlessFailure,
         name: r'checkInControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$checkInControllerHash();

  @override
  String toString() {
    return r'checkInControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  CheckInController create() => CheckInController();

  @override
  bool operator ==(Object other) {
    return other is CheckInControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$checkInControllerHash() => r'0460d37773c281fd2026de9052d66f51b54c4b76';

/// One calendar day's check-in status.
///
/// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
/// normalize [date] to midnight before using it as the key, or the same day
/// at two different times becomes two providers. `CheckInModule` does this.
///
/// `null` data means nothing has been logged for that day yet. Errors are
/// always a typed [Failure].

final class CheckInControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          CheckInController,
          AsyncValue<CheckInStatus?>,
          CheckInStatus?,
          FutureOr<CheckInStatus?>,
          DateTime
        > {
  CheckInControllerFamily._()
    : super(
        retry: _retryUnlessFailure,
        name: r'checkInControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// One calendar day's check-in status.
  ///
  /// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
  /// normalize [date] to midnight before using it as the key, or the same day
  /// at two different times becomes two providers. `CheckInModule` does this.
  ///
  /// `null` data means nothing has been logged for that day yet. Errors are
  /// always a typed [Failure].

  CheckInControllerProvider call(DateTime date) =>
      CheckInControllerProvider._(argument: date, from: this);

  @override
  String toString() => r'checkInControllerProvider';
}

/// One calendar day's check-in status.
///
/// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
/// normalize [date] to midnight before using it as the key, or the same day
/// at two different times becomes two providers. `CheckInModule` does this.
///
/// `null` data means nothing has been logged for that day yet. Errors are
/// always a typed [Failure].

abstract class _$CheckInController extends $AsyncNotifier<CheckInStatus?> {
  late final _$args = ref.$arg as DateTime;
  DateTime get date => _$args;

  FutureOr<CheckInStatus?> build(DateTime date);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<CheckInStatus?>, CheckInStatus?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<CheckInStatus?>, CheckInStatus?>,
              AsyncValue<CheckInStatus?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
