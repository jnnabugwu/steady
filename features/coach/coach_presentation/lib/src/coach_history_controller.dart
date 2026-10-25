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
  /// this iPhone. Ignored while a delete is in flight, or once disposed.
  Future<void> deleteCoachHistory() async {
    if (!ref.mounted || state.isLoading) return;
    state = const AsyncLoading();
    final Result<Unit> result;
    try {
      result = await ref.read(coachRepositoryProvider).deleteAll();
    } on Object catch (error, stackTrace) {
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
    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
