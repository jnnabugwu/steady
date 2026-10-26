import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_history_providers.g.dart';

/// A [Failure] was already mapped at the `_data` boundary: surface it at
/// once instead of retrying (CLAUDE.md §4).
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Whether the on-device model can run on this iPhone now: its
/// [CoachModelInfo], or an `AsyncError` carrying the typed
/// [CoachModelUnavailableFailure] that says why not.
///
/// iPhone only: read it only where `coachSupportAvailableProvider` is
/// `true`, since the model isn't bound anywhere else. Auto-dispose; the app
/// invalidates it on every return to the foreground, since the person may
/// have turned Apple Intelligence on in Settings meanwhile.
@Riverpod(retry: _retryUnlessFailure)
Future<CoachModelInfo> coachAvailability(Ref ref) async =>
    switch (await ref.watch(coachModelProvider).checkAvailability()) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };

/// Every stored coach session, newest first, read locally from
/// `CoachRepository`. The live session invalidates it after each save, and
/// "Delete coach history" after a delete.
@Riverpod(retry: _retryUnlessFailure)
Future<List<CoachSession>> coachSessionList(Ref ref) async =>
    switch (await ref.watch(coachRepositoryProvider).listSessions()) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };

/// The stored session [id], or `null` if it isn't on this iPhone (any
/// more), for the read-only transcript.
@Riverpod(retry: _retryUnlessFailure)
Future<CoachSession?> coachStoredSession(Ref ref, String id) async =>
    switch (await ref.watch(coachRepositoryProvider).getSession(id)) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };

/// Which coach history a live session belongs to: moves on each time
/// "Delete coach history" starts. A session that opened before then saves
/// nothing more, so one still finishing its summary in the background
/// can't bring itself back after the delete (`CoachSessionController`).
class CoachHistoryEpoch {
  var _value = 0;

  /// The current epoch.
  int get value => _value;

  /// Moves to a new epoch. Called by "Delete coach history" before it
  /// deletes anything.
  void advance() => _value++;
}

/// The one [CoachHistoryEpoch]. `keepAlive`: it must outlive every session
/// and the Settings card, or a recreated one would forget the delete.
@Riverpod(keepAlive: true)
CoachHistoryEpoch coachHistoryEpoch(Ref ref) => CoachHistoryEpoch();
