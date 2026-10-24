// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `CheckInRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `checkin_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

@ProviderFor(checkInRepository)
final checkInRepositoryProvider = CheckInRepositoryProvider._();

/// The `CheckInRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `checkin_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).

final class CheckInRepositoryProvider
    extends
        $FunctionalProvider<
          CheckInRepository,
          CheckInRepository,
          CheckInRepository
        >
    with $Provider<CheckInRepository> {
  /// The `CheckInRepository` this feature reads and writes through.
  ///
  /// Typed against the domain interface only: this package never depends on
  /// `checkin_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
  /// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
  /// override it with a fake. Reading it without an override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless, so recreating one
  /// gains nothing (D6).
  CheckInRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInRepositoryHash();

  @$internal
  @override
  $ProviderElement<CheckInRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  CheckInRepository create(Ref ref) {
    return checkInRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInRepository>(value),
    );
  }
}

String _$checkInRepositoryHash() => r'0b972afee6d70d759b605ec3bc781363f55dd82b';

/// The read-only `MetricsRepository` the week share card reads through.
///
/// One range read covers the whole week: each `DailyMetric` row carries the
/// day's logging status plus the opt-in calories and steps. Typed against
/// `metrics_domain` only, never `metrics_data` or `metrics_presentation`
/// (CLAUDE.md §2–§3). `app/lib/providers.dart` overrides it so it reads the
/// shared `DailyMetricRepository`; tests override it with a fake. Reading it
/// without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).

@ProviderFor(weekMetricsRepository)
final weekMetricsRepositoryProvider = WeekMetricsRepositoryProvider._();

/// The read-only `MetricsRepository` the week share card reads through.
///
/// One range read covers the whole week: each `DailyMetric` row carries the
/// day's logging status plus the opt-in calories and steps. Typed against
/// `metrics_domain` only, never `metrics_data` or `metrics_presentation`
/// (CLAUDE.md §2–§3). `app/lib/providers.dart` overrides it so it reads the
/// shared `DailyMetricRepository`; tests override it with a fake. Reading it
/// without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless (D6).

final class WeekMetricsRepositoryProvider
    extends
        $FunctionalProvider<
          MetricsRepository,
          MetricsRepository,
          MetricsRepository
        >
    with $Provider<MetricsRepository> {
  /// The read-only `MetricsRepository` the week share card reads through.
  ///
  /// One range read covers the whole week: each `DailyMetric` row carries the
  /// day's logging status plus the opt-in calories and steps. Typed against
  /// `metrics_domain` only, never `metrics_data` or `metrics_presentation`
  /// (CLAUDE.md §2–§3). `app/lib/providers.dart` overrides it so it reads the
  /// shared `DailyMetricRepository`; tests override it with a fake. Reading it
  /// without an override throws.
  ///
  /// `keepAlive`: repositories are cheap and stateless (D6).
  WeekMetricsRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekMetricsRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekMetricsRepositoryHash();

  @$internal
  @override
  $ProviderElement<MetricsRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  MetricsRepository create(Ref ref) {
    return weekMetricsRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(MetricsRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<MetricsRepository>(value),
    );
  }
}

String _$weekMetricsRepositoryHash() =>
    r'1dacaf00efbbb200564fe8c0de87ad7715693297';

/// How a rendered week card leaves the app. Defaults to the system share
/// sheet ([shareViaSystemSheet]); tests override it so they never reach the
/// share_plus plugin.
///
/// `keepAlive`: a stateless function, so recreating it gains nothing. It
/// never holds the PNG; bytes are passed per call and dropped after.

@ProviderFor(weekCardSharer)
final weekCardSharerProvider = WeekCardSharerProvider._();

/// How a rendered week card leaves the app. Defaults to the system share
/// sheet ([shareViaSystemSheet]); tests override it so they never reach the
/// share_plus plugin.
///
/// `keepAlive`: a stateless function, so recreating it gains nothing. It
/// never holds the PNG; bytes are passed per call and dropped after.

final class WeekCardSharerProvider
    extends $FunctionalProvider<WeekCardSharer, WeekCardSharer, WeekCardSharer>
    with $Provider<WeekCardSharer> {
  /// How a rendered week card leaves the app. Defaults to the system share
  /// sheet ([shareViaSystemSheet]); tests override it so they never reach the
  /// share_plus plugin.
  ///
  /// `keepAlive`: a stateless function, so recreating it gains nothing. It
  /// never holds the PNG; bytes are passed per call and dropped after.
  WeekCardSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'weekCardSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$weekCardSharerHash();

  @$internal
  @override
  $ProviderElement<WeekCardSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  WeekCardSharer create(Ref ref) {
    return weekCardSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(WeekCardSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<WeekCardSharer>(value),
    );
  }
}

String _$weekCardSharerHash() => r'f541e8cf01b63a21af285437c74963169e2162ba';

/// The clock the check-in screen reads "now" from, to tell which day of the
/// week's cairn is today (and so which days are still to come). Defaults to
/// [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(checkInClock)
final checkInClockProvider = CheckInClockProvider._();

/// The clock the check-in screen reads "now" from, to tell which day of the
/// week's cairn is today (and so which days are still to come). Defaults to
/// [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).

final class CheckInClockProvider
    extends $FunctionalProvider<CheckInClock, CheckInClock, CheckInClock>
    with $Provider<CheckInClock> {
  /// The clock the check-in screen reads "now" from, to tell which day of the
  /// week's cairn is today (and so which days are still to come). Defaults to
  /// [DateTime.now]; tests pin it.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  CheckInClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInClockHash();

  @$internal
  @override
  $ProviderElement<CheckInClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  CheckInClock create(Ref ref) {
    return checkInClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(CheckInClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<CheckInClock>(value),
    );
  }
}

String _$checkInClockHash() => r'0e8e9089716c792c9e7aeab6f7ee8efd6817c2fd';

/// Today's date (local midnight), as the check-in and cairn cards and the
/// app's Today screen read it. Built from [checkInClockProvider], so tests
/// pin it through the clock. The clock's value is read in local time, so a
/// UTC clock still gives the local calendar date.
///
/// **Rolls over at midnight** through [refreshToday]: the app root calls it
/// from a timer set for the next local midnight ([untilNextMidnight]) and on
/// every return to the foreground (a timer can fire late while the device
/// sleeps). A screen left open overnight then moves to the new day, and the
/// date-keyed families its watchers key on (`checkInControllerProvider`,
/// `weekCardControllerProvider`, ...) move with it. The timer lives in the
/// widget tree, not here, so it ends with the app's root widget.
///
/// `keepAlive`: one value for the whole app.

@ProviderFor(CheckInToday)
final checkInTodayProvider = CheckInTodayProvider._();

/// Today's date (local midnight), as the check-in and cairn cards and the
/// app's Today screen read it. Built from [checkInClockProvider], so tests
/// pin it through the clock. The clock's value is read in local time, so a
/// UTC clock still gives the local calendar date.
///
/// **Rolls over at midnight** through [refreshToday]: the app root calls it
/// from a timer set for the next local midnight ([untilNextMidnight]) and on
/// every return to the foreground (a timer can fire late while the device
/// sleeps). A screen left open overnight then moves to the new day, and the
/// date-keyed families its watchers key on (`checkInControllerProvider`,
/// `weekCardControllerProvider`, ...) move with it. The timer lives in the
/// widget tree, not here, so it ends with the app's root widget.
///
/// `keepAlive`: one value for the whole app.
final class CheckInTodayProvider
    extends $NotifierProvider<CheckInToday, DateTime> {
  /// Today's date (local midnight), as the check-in and cairn cards and the
  /// app's Today screen read it. Built from [checkInClockProvider], so tests
  /// pin it through the clock. The clock's value is read in local time, so a
  /// UTC clock still gives the local calendar date.
  ///
  /// **Rolls over at midnight** through [refreshToday]: the app root calls it
  /// from a timer set for the next local midnight ([untilNextMidnight]) and on
  /// every return to the foreground (a timer can fire late while the device
  /// sleeps). A screen left open overnight then moves to the new day, and the
  /// date-keyed families its watchers key on (`checkInControllerProvider`,
  /// `weekCardControllerProvider`, ...) move with it. The timer lives in the
  /// widget tree, not here, so it ends with the app's root widget.
  ///
  /// `keepAlive`: one value for the whole app.
  CheckInTodayProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'checkInTodayProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$checkInTodayHash();

  @$internal
  @override
  CheckInToday create() => CheckInToday();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DateTime value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DateTime>(value),
    );
  }
}

String _$checkInTodayHash() => r'b327da59413234c941e99468ba9b71d09f0c5deb';

/// Today's date (local midnight), as the check-in and cairn cards and the
/// app's Today screen read it. Built from [checkInClockProvider], so tests
/// pin it through the clock. The clock's value is read in local time, so a
/// UTC clock still gives the local calendar date.
///
/// **Rolls over at midnight** through [refreshToday]: the app root calls it
/// from a timer set for the next local midnight ([untilNextMidnight]) and on
/// every return to the foreground (a timer can fire late while the device
/// sleeps). A screen left open overnight then moves to the new day, and the
/// date-keyed families its watchers key on (`checkInControllerProvider`,
/// `weekCardControllerProvider`, ...) move with it. The timer lives in the
/// widget tree, not here, so it ends with the app's root widget.
///
/// `keepAlive`: one value for the whole app.

abstract class _$CheckInToday extends $Notifier<DateTime> {
  DateTime build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<DateTime, DateTime>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<DateTime, DateTime>,
              DateTime,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
