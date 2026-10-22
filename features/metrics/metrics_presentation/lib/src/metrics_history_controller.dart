import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:metrics_presentation/src/providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'metrics_history_controller.g.dart';

/// Retry policy for [MetricsHistoryController].
///
/// A [Failure] has already been mapped at the `_data` boundary (CLAUDE.md
/// §9), so it is surfaced immediately as `AsyncError` instead of being
/// retried. Any other error falls back to Riverpod's default retry.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// The first day the history screen asks the repository for. Early enough
/// that every real import falls after it.
final _historyStart = DateTime(2000);

/// Every imported day, newest first, for the metrics history screen.
///
/// Auto-dispose (CLAUDE.md §4: screen controllers are screen-scoped). Reads
/// `metricsRepositoryProvider.getRange` from 2000-01-01 to today, inclusive.
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying.
///
/// No public methods: to reload (e.g. after a Cal AI import), callers
/// `ref.invalidate(metricsHistoryControllerProvider)`.
@Riverpod(retry: _retryUnlessFailure)
class MetricsHistoryController extends _$MetricsHistoryController {
  @override
  Future<List<DailyMetric>> build() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final result = await ref
        .watch(metricsRepositoryProvider)
        .getRange(_historyStart, today);
    return switch (result) {
      Ok(:final value) => _newestFirst(value),
      Err(:final failure) => throw failure,
    };
  }
}

/// An unmodifiable copy of [days], sorted newest first.
List<DailyMetric> _newestFirst(List<DailyMetric> days) => List.unmodifiable(
  <DailyMetric>[...days]..sort((a, b) => b.date.compareTo(a.date)),
);
