import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'craving_week_controller.g.dart';

/// Retry policy: a [Failure] was already mapped at the `_data` boundary, so
/// it surfaces at once (the home line just stays hidden) instead of
/// Riverpod 3's default retry holding the provider in `AsyncLoading`.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// The last seven days of craving check-ins, summarized for the home
/// screen ([summarizeCravingWeek]).
///
/// Screen-scoped, so auto-dispose (CLAUDE.md §4). A saved check-in and
/// "Delete craving history" both invalidate it. Never built where craving
/// support isn't offered (the home section checks first).
@Riverpod(retry: _retryUnlessFailure)
class CravingWeekController extends _$CravingWeekController {
  @override
  Future<CravingWeekSummary> build() async {
    final now = ref.watch(cravingClockProvider)();
    final window = cravingWeekWindow(now);
    final result = await ref
        .watch(cravingRepositoryProvider)
        .getBetween(window.start, window.end);
    return switch (result) {
      Ok(:final value) => summarizeCravingWeek(value, now: now),
      Err(:final failure) => throw failure,
    };
  }
}

/// The home screen's gentle line, e.g. "3 cravings this week, mostly in the
/// evening", or `null` when there were none. Never mentions outcomes.
String? cravingWeekLine(CravingWeekSummary summary) {
  final count = summary.count;
  if (count == 0) return null;
  final noun = count == 1 ? '1 craving' : '$count cravings';
  final when = switch (summary.mostly) {
    null => null,
    CravingTimeOfDay.morning => 'in the morning',
    CravingTimeOfDay.afternoon => 'in the afternoon',
    CravingTimeOfDay.evening => 'in the evening',
    CravingTimeOfDay.night => 'at night',
  };
  if (when == null) return '$noun this week';
  return count == 1
      ? '$noun this week, $when'
      : '$noun this week, mostly $when';
}
