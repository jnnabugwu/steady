// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// The `DailyMetricRepository` the export reads every row from.
///
/// Typed against the shared domain interface only: this package never
/// depends on a `*_data` package (CLAUDE.md §3). `app/lib/providers.dart`
/// overrides it with `ref.watch(dailyMetricRepositoryProvider)`, the single
/// shared store (CLAUDE.md §9), so the export sees exactly what checkin and
/// pdf_import wrote. Reading it without an override throws.
///
/// `keepAlive`: the shared store must not be disposed (D6).

@ProviderFor(exportDailyMetricRepository)
final exportDailyMetricRepositoryProvider =
    ExportDailyMetricRepositoryProvider._();

/// The `DailyMetricRepository` the export reads every row from.
///
/// Typed against the shared domain interface only: this package never
/// depends on a `*_data` package (CLAUDE.md §3). `app/lib/providers.dart`
/// overrides it with `ref.watch(dailyMetricRepositoryProvider)`, the single
/// shared store (CLAUDE.md §9), so the export sees exactly what checkin and
/// pdf_import wrote. Reading it without an override throws.
///
/// `keepAlive`: the shared store must not be disposed (D6).

final class ExportDailyMetricRepositoryProvider
    extends
        $FunctionalProvider<
          DailyMetricRepository,
          DailyMetricRepository,
          DailyMetricRepository
        >
    with $Provider<DailyMetricRepository> {
  /// The `DailyMetricRepository` the export reads every row from.
  ///
  /// Typed against the shared domain interface only: this package never
  /// depends on a `*_data` package (CLAUDE.md §3). `app/lib/providers.dart`
  /// overrides it with `ref.watch(dailyMetricRepositoryProvider)`, the single
  /// shared store (CLAUDE.md §9), so the export sees exactly what checkin and
  /// pdf_import wrote. Reading it without an override throws.
  ///
  /// `keepAlive`: the shared store must not be disposed (D6).
  ExportDailyMetricRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportDailyMetricRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportDailyMetricRepositoryHash();

  @$internal
  @override
  $ProviderElement<DailyMetricRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  DailyMetricRepository create(Ref ref) {
    return exportDailyMetricRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(DailyMetricRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<DailyMetricRepository>(value),
    );
  }
}

String _$exportDailyMetricRepositoryHash() =>
    r'ee986f305e2fad42b87d4083785b7e165f1bc34c';

/// Hands the finished export file to the system share sheet.
///
/// Defaults to the real `share_plus` implementation, which needs no
/// app-level binding. Tests override it so they never reach the plugin.
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(exportFileSharer)
final exportFileSharerProvider = ExportFileSharerProvider._();

/// Hands the finished export file to the system share sheet.
///
/// Defaults to the real `share_plus` implementation, which needs no
/// app-level binding. Tests override it so they never reach the plugin.
///
/// `keepAlive`: cheap and stateless (D6).

final class ExportFileSharerProvider
    extends
        $FunctionalProvider<
          ExportFileSharer,
          ExportFileSharer,
          ExportFileSharer
        >
    with $Provider<ExportFileSharer> {
  /// Hands the finished export file to the system share sheet.
  ///
  /// Defaults to the real `share_plus` implementation, which needs no
  /// app-level binding. Tests override it so they never reach the plugin.
  ///
  /// `keepAlive`: cheap and stateless (D6).
  ExportFileSharerProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportFileSharerProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportFileSharerHash();

  @$internal
  @override
  $ProviderElement<ExportFileSharer> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportFileSharer create(Ref ref) {
    return exportFileSharer(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportFileSharer value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportFileSharer>(value),
    );
  }
}

String _$exportFileSharerHash() => r'354a7be18b202d40c608c1669d1d934df433e40c';

/// The clock the export reads "now" from. Defaults to [DateTime.now].
///
/// `keepAlive`: cheap and stateless (D6).

@ProviderFor(exportClock)
final exportClockProvider = ExportClockProvider._();

/// The clock the export reads "now" from. Defaults to [DateTime.now].
///
/// `keepAlive`: cheap and stateless (D6).

final class ExportClockProvider
    extends $FunctionalProvider<ExportClock, ExportClock, ExportClock>
    with $Provider<ExportClock> {
  /// The clock the export reads "now" from. Defaults to [DateTime.now].
  ///
  /// `keepAlive`: cheap and stateless (D6).
  ExportClockProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'exportClockProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$exportClockHash();

  @$internal
  @override
  $ProviderElement<ExportClock> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  ExportClock create(Ref ref) {
    return exportClock(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(ExportClock value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<ExportClock>(value),
    );
  }
}

String _$exportClockHash() => r'379d7a27c3f1abe0e43159a40b5d9d522d50c216';
