// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The JSON file the interim [dailyMetricRepository] persists to, or `null`
/// for an in-memory store.
///
/// `null` by default, so tests built from [appProviderOverrides] stay
/// in-memory and touch no disk. `main.dart` overrides it with a file in the
/// app-support directory, which needs an async `path_provider` lookup before
/// `runApp`.

@ProviderFor(dailyMetricsFile)
final dailyMetricsFileProvider = DailyMetricsFileProvider._();

/// The JSON file the interim [dailyMetricRepository] persists to, or `null`
/// for an in-memory store.
///
/// `null` by default, so tests built from [appProviderOverrides] stay
/// in-memory and touch no disk. `main.dart` overrides it with a file in the
/// app-support directory, which needs an async `path_provider` lookup before
/// `runApp`.

final class DailyMetricsFileProvider
    extends $FunctionalProvider<File?, File?, File?>
    with $Provider<File?> {
  /// The JSON file the interim [dailyMetricRepository] persists to, or `null`
  /// for an in-memory store.
  ///
  /// `null` by default, so tests built from [appProviderOverrides] stay
  /// in-memory and touch no disk. `main.dart` overrides it with a file in the
  /// app-support directory, which needs an async `path_provider` lookup before
  /// `runApp`.
  DailyMetricsFileProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'dailyMetricsFileProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$dailyMetricsFileHash();

  @$internal
  @override
  $ProviderElement<File?> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  File? create(Ref ref) {
    return dailyMetricsFile(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(File? value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<File?>(value),
    );
  }
}

String _$dailyMetricsFileHash() => r'678c982433771b0f413af2d20a42d09eeee7aa4d';

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through.
///
/// Interim: backed by a local JSON file when [dailyMetricsFile] is set,
/// until the SwiftData + CloudKit datasource replaces it (#43). That swap
/// changes only this body.
///
/// `keepAlive`: disposing it would lose the in-memory data and break the
/// shared-store invariant (D6).

@ProviderFor(dailyMetricRepository)
final dailyMetricRepositoryProvider = DailyMetricRepositoryProvider._();

/// The single shared `DailyMetricRepository` that checkin, metrics and
/// pdf_import all read and write through.
///
/// Interim: backed by a local JSON file when [dailyMetricsFile] is set,
/// until the SwiftData + CloudKit datasource replaces it (#43). That swap
/// changes only this body.
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
  /// Interim: backed by a local JSON file when [dailyMetricsFile] is set,
  /// until the SwiftData + CloudKit datasource replaces it (#43). That swap
  /// changes only this body.
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
    r'b49cf68b0c82b3c536a51851c405d4d6cbf37b18';

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
