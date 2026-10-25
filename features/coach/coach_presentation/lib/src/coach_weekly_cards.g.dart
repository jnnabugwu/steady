// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'coach_weekly_cards.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The weekly session's readiness for the week it would look back on now
/// ([CheckWeeklyReadiness]). Check-in data only, no model.

@ProviderFor(weeklyReadiness)
final weeklyReadinessProvider = WeeklyReadinessProvider._();

/// The weekly session's readiness for the week it would look back on now
/// ([CheckWeeklyReadiness]). Check-in data only, no model.

final class WeeklyReadinessProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeeklyReadiness>,
          WeeklyReadiness,
          FutureOr<WeeklyReadiness>
        >
    with $FutureModifier<WeeklyReadiness>, $FutureProvider<WeeklyReadiness> {
  /// The weekly session's readiness for the week it would look back on now
  /// ([CheckWeeklyReadiness]). Check-in data only, no model.
  WeeklyReadinessProvider._()
    : super(
        from: null,
        argument: null,
        retry: _retryUnlessFailure,
        name: r'weeklyReadinessProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weeklyReadinessHash();

  @$internal
  @override
  $FutureProviderElement<WeeklyReadiness> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeeklyReadiness> create(Ref ref) {
    return weeklyReadiness(ref);
  }
}

String _$weeklyReadinessHash() => r'40fd9fb90e212549ee034ba1c2e158fe09e3edb5';

/// The day "Not tonight" was tapped on the nudge, or `null`. Kept in
/// memory: the nudge comes back the next day, or after a relaunch.
///
/// `keepAlive`: the dismissal has to outlive the Today screen's rebuilds.

@ProviderFor(CoachNudgeDismissal)
final coachNudgeDismissalProvider = CoachNudgeDismissalProvider._();

/// The day "Not tonight" was tapped on the nudge, or `null`. Kept in
/// memory: the nudge comes back the next day, or after a relaunch.
///
/// `keepAlive`: the dismissal has to outlive the Today screen's rebuilds.
final class CoachNudgeDismissalProvider
    extends $NotifierProvider<CoachNudgeDismissal, DateTime?> {
  /// The day "Not tonight" was tapped on the nudge, or `null`. Kept in
  /// memory: the nudge comes back the next day, or after a relaunch.
  ///
  /// `keepAlive`: the dismissal has to outlive the Today screen's rebuilds.
  CoachNudgeDismissalProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachNudgeDismissalProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachNudgeDismissalHash();

  @$internal
  @override
  CoachNudgeDismissal create() => CoachNudgeDismissal();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime?>(value),
    );
  }
}

String _$coachNudgeDismissalHash() =>
    r'41602008336aabb4320130a576f167f1d15c8aea';

/// The day "Not tonight" was tapped on the nudge, or `null`. Kept in
/// memory: the nudge comes back the next day, or after a relaunch.
///
/// `keepAlive`: the dismissal has to outlive the Today screen's rebuilds.

abstract class _$CoachNudgeDismissal extends $Notifier<DateTime?> {
  DateTime? build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime?, DateTime?>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime?, DateTime?>,
              DateTime?,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}

/// The week the Today nudge offers, or `null` for no nudge.
///
/// **Needs check-in data, not inference** (CLAUDE.md §11): it never calls
/// the model. There's a nudge on an iPhone, from Friday to Sunday, when the
/// last completed week passes the 4-of-7 rule, no weekly session has been
/// started since that week ended, and "Not tonight" wasn't tapped today.
/// Anything that can't be read means no nudge: it's an offer, never an
/// error.

@ProviderFor(coachNudge)
final coachNudgeProvider = CoachNudgeProvider._();

/// The week the Today nudge offers, or `null` for no nudge.
///
/// **Needs check-in data, not inference** (CLAUDE.md §11): it never calls
/// the model. There's a nudge on an iPhone, from Friday to Sunday, when the
/// last completed week passes the 4-of-7 rule, no weekly session has been
/// started since that week ended, and "Not tonight" wasn't tapped today.
/// Anything that can't be read means no nudge: it's an offer, never an
/// error.

final class CoachNudgeProvider
    extends
        $FunctionalProvider<
          AsyncValue<WeeklyReadiness?>,
          WeeklyReadiness?,
          FutureOr<WeeklyReadiness?>
        >
    with $FutureModifier<WeeklyReadiness?>, $FutureProvider<WeeklyReadiness?> {
  /// The week the Today nudge offers, or `null` for no nudge.
  ///
  /// **Needs check-in data, not inference** (CLAUDE.md §11): it never calls
  /// the model. There's a nudge on an iPhone, from Friday to Sunday, when the
  /// last completed week passes the 4-of-7 rule, no weekly session has been
  /// started since that week ended, and "Not tonight" wasn't tapped today.
  /// Anything that can't be read means no nudge: it's an offer, never an
  /// error.
  CoachNudgeProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'coachNudgeProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$coachNudgeHash();

  @$internal
  @override
  $FutureProviderElement<WeeklyReadiness?> $createElement(
    $ProviderPointer pointer,
  ) => $FutureProviderElement(pointer);

  @override
  FutureOr<WeeklyReadiness?> create(Ref ref) {
    return coachNudge(ref);
  }
}

String _$coachNudgeHash() => r'5bc2bf4ae450f30377df7c7545e0cbc6671ccba8';
