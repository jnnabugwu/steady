import 'package:metrics_domain/metrics_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `MetricsRepository` the weekly view and metrics history read from.
///
/// Typed against the domain interface only: this package never depends on
/// `metrics_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).
@Riverpod(keepAlive: true)
MetricsRepository metricsRepository(Ref ref) =>
    throw UnimplementedError('Override metricsRepositoryProvider in app/');
