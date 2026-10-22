// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through.
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).

@ProviderFor(dailyMetricRepository)
final dailyMetricRepositoryProvider = DailyMetricRepositoryProvider._();

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through.
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).

final class DailyMetricRepositoryProvider
    extends
        $FunctionalProvider<
          DailyMetricRepository,
          DailyMetricRepository,
          DailyMetricRepository
        >
    with $Provider<DailyMetricRepository> {
  /// The single shared `DailyMetricRepository` that checkin, metrics and
  /// pdf_import all read and write through.
  ///
  /// `keepAlive`: disposing it would lose the in-memory data and break the
  /// shared-store invariant (D6).
  DailyMetricRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyMetricRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyMetricRepositoryHash();

  @$internal
  @override
  $ProviderElement<DailyMetricRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyMetricRepository create(Ref ref) {
    return dailyMetricRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyMetricRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyMetricRepository>(value),
    );
  }
}

String _$dailyMetricRepositoryHash() =>
    r'547e0f3e434a590f1598268c98691f1011f1c0e3';

/// Schedules and cancels the end-of-day reminder.
///
/// Declared here rather than in a feature package: `notifications` is
/// headless (no `*_presentation` package), and the app layer is what reads
/// it, e.g. a route cancelling the reminder once a check-in completes
/// (CLAUDE.md §5).
///
/// `keepAlive`: cheap and stateless, so recreating it gains nothing (D6).

@ProviderFor(notificationScheduler)
final notificationSchedulerProvider = NotificationSchedulerProvider._();

/// Schedules and cancels the end-of-day reminder.
///
/// Declared here rather than in a feature package: `notifications` is
/// headless (no `*_presentation` package), and the app layer is what reads
/// it, e.g. a route cancelling the reminder once a check-in completes
/// (CLAUDE.md §5).
///
/// `keepAlive`: cheap and stateless, so recreating it gains nothing (D6).

final class NotificationSchedulerProvider
    extends
        $FunctionalProvider<
          NotificationScheduler,
          NotificationScheduler,
          NotificationScheduler
        >
    with $Provider<NotificationScheduler> {
  /// Schedules and cancels the end-of-day reminder.
  ///
  /// Declared here rather than in a feature package: `notifications` is
  /// headless (no `*_presentation` package), and the app layer is what reads
  /// it, e.g. a route cancelling the reminder once a check-in completes
  /// (CLAUDE.md §5).
  ///
  /// `keepAlive`: cheap and stateless, so recreating it gains nothing (D6).
  NotificationSchedulerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'notificationSchedulerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$notificationSchedulerHash();

  @$internal
  @override
  $ProviderElement<NotificationScheduler> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  NotificationScheduler create(Ref ref) {
    return notificationScheduler(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(NotificationScheduler value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<NotificationScheduler>(value),
    );
  }
}

String _$notificationSchedulerHash() =>
    r'1949c5df32c960e6f8b06613ee46d61ab425a93e';
