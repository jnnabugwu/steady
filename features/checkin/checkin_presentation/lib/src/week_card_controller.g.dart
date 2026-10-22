// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'week_card_controller.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The data for one week's share card.
///
/// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
/// `keepAlive`: one provider per week, freed when the share dialog closes.
/// Callers must pass a normalized week start from [weekCardStart], or two
/// days of the same week become two providers.
///
/// Reads the week with a single `getRange` call. A repository error
/// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
/// never shown empty as if it were real data.
///
/// State is only the card's data ([WeekCardData]); rendered PNG bytes are
/// passed through [shareWeek] and never stored here.

@ProviderFor(WeekCardController)
final weekCardControllerProvider = WeekCardControllerFamily._();

/// The data for one week's share card.
///
/// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
/// `keepAlive`: one provider per week, freed when the share dialog closes.
/// Callers must pass a normalized week start from [weekCardStart], or two
/// days of the same week become two providers.
///
/// Reads the week with a single `getRange` call. A repository error
/// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
/// never shown empty as if it were real data.
///
/// State is only the card's data ([WeekCardData]); rendered PNG bytes are
/// passed through [shareWeek] and never stored here.
final class WeekCardControllerProvider
    extends $AsyncNotifierProvider<WeekCardController, WeekCardData> {
  /// The data for one week's share card.
  ///
  /// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
  /// `keepAlive`: one provider per week, freed when the share dialog closes.
  /// Callers must pass a normalized week start from [weekCardStart], or two
  /// days of the same week become two providers.
  ///
  /// Reads the week with a single `getRange` call. A repository error
  /// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
  /// never shown empty as if it were real data.
  ///
  /// State is only the card's data ([WeekCardData]); rendered PNG bytes are
  /// passed through [shareWeek] and never stored here.
  WeekCardControllerProvider._({
    required WeekCardControllerFamily super.from,
    required DateTime super.argument,
  }) : super(
         retry: retryUnlessFailure,
         name: r'weekCardControllerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$weekCardControllerHash();

  @override
  String toString() {
    return r'weekCardControllerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  WeekCardController create() => WeekCardController();

  @override
  bool operator ==(Object other) {
    return other is WeekCardControllerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$weekCardControllerHash() =>
    r'333330fdcdaf03a49ecc38d1c8971296f483c1cd';

/// The data for one week's share card.
///
/// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
/// `keepAlive`: one provider per week, freed when the share dialog closes.
/// Callers must pass a normalized week start from [weekCardStart], or two
/// days of the same week become two providers.
///
/// Reads the week with a single `getRange` call. A repository error
/// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
/// never shown empty as if it were real data.
///
/// State is only the card's data ([WeekCardData]); rendered PNG bytes are
/// passed through [shareWeek] and never stored here.

final class WeekCardControllerFamily extends $Family
    with
        $ClassFamilyOverride<
          WeekCardController,
          AsyncValue<WeekCardData>,
          WeekCardData,
          FutureOr<WeekCardData>,
          DateTime
        > {
  WeekCardControllerFamily._()
    : super(
        retry: retryUnlessFailure,
        name: r'weekCardControllerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  /// The data for one week's share card.
  ///
  /// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
  /// `keepAlive`: one provider per week, freed when the share dialog closes.
  /// Callers must pass a normalized week start from [weekCardStart], or two
  /// days of the same week become two providers.
  ///
  /// Reads the week with a single `getRange` call. A repository error
  /// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
  /// never shown empty as if it were real data.
  ///
  /// State is only the card's data ([WeekCardData]); rendered PNG bytes are
  /// passed through [shareWeek] and never stored here.

  WeekCardControllerProvider call(DateTime weekStart) =>
      WeekCardControllerProvider._(argument: weekStart, from: this);

  @override
  String toString() => r'weekCardControllerProvider';
}

/// The data for one week's share card.
///
/// An auto-dispose family keyed on [weekStart] (CLAUDE.md §4), never
/// `keepAlive`: one provider per week, freed when the share dialog closes.
/// Callers must pass a normalized week start from [weekCardStart], or two
/// days of the same week become two providers.
///
/// Reads the week with a single `getRange` call. A repository error
/// arrives as a typed [Failure] in `AsyncError` (no retry), so the card is
/// never shown empty as if it were real data.
///
/// State is only the card's data ([WeekCardData]); rendered PNG bytes are
/// passed through [shareWeek] and never stored here.

abstract class _$WeekCardController extends $AsyncNotifier<WeekCardData> {
  late final _$args = ref.$arg as DateTime;
  DateTime get weekStart => _$args;

  FutureOr<WeekCardData> build(DateTime weekStart);
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<WeekCardData>, WeekCardData>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<WeekCardData>, WeekCardData>,
              AsyncValue<WeekCardData>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, () => build(_$args));
  }
}
