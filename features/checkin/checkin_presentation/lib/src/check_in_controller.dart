import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_in_controller.g.dart';

/// Retry policy for [CheckInController].
///
/// A [Failure] has already been mapped at the `_data` boundary (CLAUDE.md
/// §9), so it is surfaced immediately as `AsyncError` instead of being
/// retried. Riverpod 3's default retry would otherwise keep the provider in
/// `AsyncLoading` for up to 10 attempts before the UI saw the error. Any
/// other error falls back to Riverpod's default retry.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// One calendar day's check-in status.
///
/// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
/// normalize [date] to midnight before using it as the key, or the same day
/// at two different times becomes two providers. `CheckInModule` does this.
///
/// `null` data means nothing has been logged for that day yet. Errors are
/// always a typed [Failure].
@Riverpod(retry: _retryUnlessFailure)
class CheckInController extends _$CheckInController {
  @override
  Future<CheckInStatus?> build(DateTime date) async {
    final result = await ref.watch(checkInRepositoryProvider).getStatus(date);
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: CheckInLogged / CheckInPartial / CheckInSkipped.
  ///
  /// Records [status] for this provider's [date]. On success the state
  /// becomes `AsyncData(status)`; on failure it becomes an `AsyncError`
  /// carrying the repository's [Failure].
  Future<void> logCheckIn(CheckInStatus status) async {
    state = const AsyncLoading();
    final result = await ref
        .read(checkInRepositoryProvider)
        .logCheckIn(date, status);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => AsyncData(status),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
