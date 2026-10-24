import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/src/providers.dart';
import 'package:checkin_presentation/src/retry_unless_failure.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'check_in_controller.g.dart';

/// One calendar day's check-in status.
///
/// An auto-dispose family keyed on [date] (CLAUDE.md §4). Callers must
/// normalize [date] to midnight before using it as the key, or the same day
/// at two different times becomes two providers. `CheckInModule` does this.
///
/// `null` data means nothing has been logged for that day yet. Repository
/// errors arrive as a typed [Failure] and are surfaced without retrying; any
/// other (unexpected) error goes through Riverpod's default retry before it
/// reaches `AsyncError`.
@Riverpod(retry: retryUnlessFailure)
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
  /// carrying the repository's [Failure]. If the repository throws instead
  /// of returning a `Result`, the state still leaves loading: it becomes an
  /// `AsyncError` carrying the thrown [Failure], or an [UnknownFailure]
  /// wrapping anything else, so the next call can retry.
  ///
  /// The loading and error states keep the last saved status as their
  /// `value` (Riverpod's notifier `state` setter carries the previous value
  /// over), so the screen can keep showing it while a change is in flight
  /// and after one fails.
  ///
  /// Ignored while the state is loading (the initial read or another write
  /// still in flight), so rapid taps can't start concurrent writes, and
  /// after the provider has been disposed.
  Future<void> logCheckIn(CheckInStatus status) async {
    if (!ref.mounted || state.isLoading) return;
    state = const AsyncLoading();
    final Result<Unit> result;
    try {
      result = await ref
          .read(checkInRepositoryProvider)
          .logCheckIn(date, status);
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;
      final failure = error is Failure
          ? error
          : UnknownFailure('Saving the check-in failed.', cause: error);
      state = AsyncError(failure, stackTrace);
      return;
    }
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => AsyncData(status),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
