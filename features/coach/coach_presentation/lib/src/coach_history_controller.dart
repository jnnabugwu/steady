import 'package:coach_presentation/src/coach_history_providers.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_history_controller.g.dart';

/// Settings' "Delete coach history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).
@riverpod
class CoachHistoryController extends _$CoachHistoryController {
  @override
  Future<bool> build() async => false;

  /// Domain event: CoachHistoryDeleted.
  ///
  /// Deletes every coach session, transcripts and summaries included, on
  /// this iPhone. A session still open, or finishing its summary in the
  /// background, saves nothing after this ([coachHistoryEpochProvider]).
  /// Ignored while a delete is in flight, or once disposed.
  Future<void> deleteCoachHistory() async {
    if (!ref.mounted || state.isLoading) return;
    state = const AsyncLoading();
    // Before the delete, so a save that starts while it runs waits for it
    // rather than queuing behind it; only a delete that succeeds moves the
    // epoch on, so a failed one leaves open sessions saving.
    final epoch = ref.read(coachHistoryEpochProvider)..beginDelete();
    final Result<Unit> result;
    try {
      result = await ref.read(coachRepositoryProvider).deleteAll();
      epoch.endDelete(succeeded: result is Ok);
    } on Object catch (error, stackTrace) {
      epoch.endDelete(succeeded: false);
      if (!ref.mounted) return;
      state = AsyncError(
        error is Failure
            ? error
            : UnknownFailure('Deleting coach history failed.', cause: error),
        stackTrace,
      );
      return;
    }
    if (!ref.mounted) return;
    // The Coach tab's list of past sessions is now empty, and an open
    // transcript has nothing left to show.
    if (result is Ok) {
      ref
        ..invalidate(coachSessionListProvider)
        ..invalidate(coachStoredSessionProvider);
    }
    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
