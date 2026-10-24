import 'package:cravings_presentation/src/craving_week_controller.dart';
import 'package:cravings_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'craving_history_controller.g.dart';

/// Settings' "Delete craving history".
///
/// `AsyncData(false)` until a delete succeeds, then `AsyncData(true)`;
/// `AsyncLoading` while deleting; an `AsyncError` carrying the [Failure]
/// if it fails. Screen-scoped, so auto-dispose (CLAUDE.md §4).
@riverpod
class CravingHistoryController extends _$CravingHistoryController {
  @override
  Future<bool> build() async => false;

  /// Domain event: CravingHistoryDeleted.
  ///
  /// Deletes every craving check-in on this iPhone, then refreshes the
  /// home screen's weekly line. Ignored while a delete is in flight.
  Future<void> deleteCravingHistory() async {
    if (state.isLoading) return;
    state = const AsyncLoading();
    final Result<Unit> result;
    try {
      result = await ref.read(cravingRepositoryProvider).deleteAll();
    } on Object catch (error, stackTrace) {
      if (!ref.mounted) return;
      state = AsyncError(
        error is Failure
            ? error
            : UnknownFailure('Deleting craving history failed.', cause: error),
        stackTrace,
      );
      return;
    }
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => const AsyncData(true),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
    ref.invalidate(cravingWeekControllerProvider);
  }
}
