// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cal_ai_health_card.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// Where "Not now" is remembered. In memory by default; `main.dart` binds a
/// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(calAiCardSnoozeStore)
final calAiCardSnoozeStoreProvider = CalAiCardSnoozeStoreProvider._();

/// Where "Not now" is remembered. In memory by default; `main.dart` binds a
/// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
///
/// `keepAlive`: cheap and stateless (D6).

final class CalAiCardSnoozeStoreProvider
    extends
        $FunctionalProvider<
          CalAiCardSnoozeStore,
          CalAiCardSnoozeStore,
          CalAiCardSnoozeStore
        >
    with $Provider<CalAiCardSnoozeStore> {
  /// Where "Not now" is remembered. In memory by default; `main.dart` binds a
  /// [FileCalAiCardSnoozeStore], like the shared store's SwiftData binding.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CalAiCardSnoozeStoreProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calAiCardSnoozeStoreProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calAiCardSnoozeStoreHash();

  @$internal
  @override
  $ProviderElement<CalAiCardSnoozeStore> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CalAiCardSnoozeStore create(Ref ref) {
    return calAiCardSnoozeStore(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CalAiCardSnoozeStore value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CalAiCardSnoozeStore>(value),
    );
  }
}

String _$calAiCardSnoozeStoreHash() =>
    r'4b4eaf1934610b2745d1de5efb4ed19138c9ba12';

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.

@ProviderFor(CalAiCardSnooze)
final calAiCardSnoozeProvider = CalAiCardSnoozeProvider._();

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.
final class CalAiCardSnoozeProvider
    extends $AsyncNotifierProvider<CalAiCardSnooze, DateTime?> {
  /// When "Not now" was last tapped on the card, or `null`.
  ///
  /// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
  /// it's one value, not a family.
  CalAiCardSnoozeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'calAiCardSnoozeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$calAiCardSnoozeHash();

  @$internal
  @override
  CalAiCardSnooze create() => CalAiCardSnooze();
}

String _$calAiCardSnoozeHash() => r'63ceec0d0684fde64de84eebf1fde592a61d5476';

/// When "Not now" was last tapped on the card, or `null`.
///
/// `keepAlive`: the snooze has to outlive the Today screen's rebuilds, and
/// it's one value, not a family.

abstract class _$CalAiCardSnooze extends $AsyncNotifier<DateTime?> {
  FutureOr<DateTime?> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<DateTime?>, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<DateTime?>, DateTime?>,
              AsyncValue<DateTime?>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// Which Health prompt Today shows for the Health window ending on [day]
/// (local midnight): at most one, so the Cal AI card and the tiles' pill
/// can never both ask.
///
/// - **None** on the Mac (no Health), while Health's status is loading, and
///   where Health is unavailable.
/// - **The Cal AI card** when all of these hold: screen 2's answer is
///   `calAi` or there's none (no record, unreadable, or still loading, as
///   for the import button); "Not now" isn't in force (and the snooze has
///   been read); and either Health hasn't been asked yet, or it has and
///   the window has been read with no dietary energy in it.
/// - **The pill** when the card isn't showing and Health's permission sheet
///   hasn't been shown (`notDetermined`).
///
/// Before the sheet, what Health returns isn't consulted: HealthKit gives
/// nothing until it's allowed.

@ProviderFor(todayHealthPrompt)
final todayHealthPromptProvider = TodayHealthPromptFamily._();

/// Which Health prompt Today shows for the Health window ending on [day]
/// (local midnight): at most one, so the Cal AI card and the tiles' pill
/// can never both ask.
///
/// - **None** on the Mac (no Health), while Health's status is loading, and
///   where Health is unavailable.
/// - **The Cal AI card** when all of these hold: screen 2's answer is
///   `calAi` or there's none (no record, unreadable, or still loading, as
///   for the import button); "Not now" isn't in force (and the snooze has
///   been read); and either Health hasn't been asked yet, or it has and
///   the window has been read with no dietary energy in it.
/// - **The pill** when the card isn't showing and Health's permission sheet
///   hasn't been shown (`notDetermined`).
///
/// Before the sheet, what Health returns isn't consulted: HealthKit gives
/// nothing until it's allowed.

final class TodayHealthPromptProvider
    extends
        $FunctionalProvider<
          TodayHealthPrompt,
          TodayHealthPrompt,
          TodayHealthPrompt
        >
    with $Provider<TodayHealthPrompt> {
  /// Which Health prompt Today shows for the Health window ending on [day]
  /// (local midnight): at most one, so the Cal AI card and the tiles' pill
  /// can never both ask.
  ///
  /// - **None** on the Mac (no Health), while Health's status is loading, and
  ///   where Health is unavailable.
  /// - **The Cal AI card** when all of these hold: screen 2's answer is
  ///   `calAi` or there's none (no record, unreadable, or still loading, as
  ///   for the import button); "Not now" isn't in force (and the snooze has
  ///   been read); and either Health hasn't been asked yet, or it has and
  ///   the window has been read with no dietary energy in it.
  /// - **The pill** when the card isn't showing and Health's permission sheet
  ///   hasn't been shown (`notDetermined`).
  ///
  /// Before the sheet, what Health returns isn't consulted: HealthKit gives
  /// nothing until it's allowed.
  TodayHealthPromptProvider._({
    required TodayHealthPromptFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: null,
         name: r'todayHealthPromptProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$todayHealthPromptHash();

  @override
  String toString() {
    return r'todayHealthPromptProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  $ProviderElement<TodayHealthPrompt> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  TodayHealthPrompt create(Ref ref) {
    final argument = this.argument as DateTime;
    return todayHealthPrompt(ref, argument);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(TodayHealthPrompt value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<TodayHealthPrompt>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is TodayHealthPromptProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$todayHealthPromptHash() => r'd4c17dfd0fe3191319b350de0ce7cfe98f909f3b';

/// Which Health prompt Today shows for the Health window ending on [day]
/// (local midnight): at most one, so the Cal AI card and the tiles' pill
/// can never both ask.
///
/// - **None** on the Mac (no Health), while Health's status is loading, and
///   where Health is unavailable.
/// - **The Cal AI card** when all of these hold: screen 2's answer is
///   `calAi` or there's none (no record, unreadable, or still loading, as
///   for the import button); "Not now" isn't in force (and the snooze has
///   been read); and either Health hasn't been asked yet, or it has and
///   the window has been read with no dietary energy in it.
/// - **The pill** when the card isn't showing and Health's permission sheet
///   hasn't been shown (`notDetermined`).
///
/// Before the sheet, what Health returns isn't consulted: HealthKit gives
/// nothing until it's allowed.

final class TodayHealthPromptFamily extends $Family
    with $FunctionalFamilyOverride<TodayHealthPrompt, DateTime> {
  TodayHealthPromptFamily._()
    : super(
        retry: null,
        name: r'todayHealthPromptProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// Which Health prompt Today shows for the Health window ending on [day]
  /// (local midnight): at most one, so the Cal AI card and the tiles' pill
  /// can never both ask.
  ///
  /// - **None** on the Mac (no Health), while Health's status is loading, and
  ///   where Health is unavailable.
  /// - **The Cal AI card** when all of these hold: screen 2's answer is
  ///   `calAi` or there's none (no record, unreadable, or still loading, as
  ///   for the import button); "Not now" isn't in force (and the snooze has
  ///   been read); and either Health hasn't been asked yet, or it has and
  ///   the window has been read with no dietary energy in it.
  /// - **The pill** when the card isn't showing and Health's permission sheet
  ///   hasn't been shown (`notDetermined`).
  ///
  /// Before the sheet, what Health returns isn't consulted: HealthKit gives
  /// nothing until it's allowed.

  TodayHealthPromptProvider call(DateTime day) =>
      TodayHealthPromptProvider._(argument: day, from: this);

  @override
  String toString() => r'todayHealthPromptProvider';
}
