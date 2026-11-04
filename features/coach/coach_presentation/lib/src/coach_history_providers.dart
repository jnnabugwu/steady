import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_consent_controller.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_history_providers.g.dart';

/// A [Failure] was already mapped at the `_data` boundary: surface it at
/// once instead of retrying (CLAUDE.md §4).
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Whether the coach can run on this iPhone now, before anything is sent:
/// `unit`, or an `AsyncError` carrying the typed [CoachUnavailableFailure]
/// that says why not ([checkCoachAvailable]). Rebuilds when consent
/// changes (given, or withdrawn in Settings → Coach).
///
/// iPhone only: read it only where `coachSupportAvailableProvider` is
/// `true`, since the model isn't bound anywhere else. **Never calls the
/// network** (CLAUDE.md §11: the nudge and the Coach tab must not call the
/// model). Auto-dispose; the app invalidates it on every return to the
/// foreground, cheaply.
@Riverpod(retry: _retryUnlessFailure)
Future<Unit> coachAvailability(Ref ref) async =>
    switch (await checkCoachAvailable(
      consentGiven: await readCoachConsent(
        ref.watch(coachConsentGivenProvider.future),
      ),
      model: ref.watch(coachModelProvider),
    )) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };

/// The local checks before the coach may send anything, in order: the
/// person's consent ([coachConsentGivenProvider]'s value, first, so
/// nothing else runs without it), then the [model]'s own
/// (`CoachModel.checkAvailability`: a configured proxy, a verifiable
/// iPhone). Shared by [coachAvailabilityProvider] and the live session, so
/// the two can't drift.
ResultFuture<Unit> checkCoachAvailable({
  required bool consentGiven,
  required CoachModel model,
}) async {
  if (!consentGiven) return const Err(CoachConsentNotGivenFailure());
  return await model.checkAvailability();
}

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
/// "Delete coach history" succeeds. A session that opened before then saves
/// nothing more, so one still finishing its summary in the background
/// can't bring itself back after the delete (`CoachSessionController`).
///
/// While a delete runs, a session's save waits for it ([idle]) and then
/// checks the epoch: a delete that succeeds refuses it, one that fails
/// leaves every open session saving as before.
class CoachHistoryEpoch {
  var _value = 0;
  Completer<void>? _deleting;

  /// The current epoch: how many deletes have succeeded.
  int get value => _value;

  /// Completes once no delete is running.
  Future<void> get idle => _deleting?.future ?? Future<void>.value();

  /// Called by "Delete coach history" before it deletes anything.
  void beginDelete() => _deleting ??= Completer<void>();

  /// Called once the delete is over; moves to a new epoch only if it
  /// [succeeded].
  void endDelete({required bool succeeded}) {
    if (succeeded) _value++;
    final deleting = _deleting;
    _deleting = null;
    deleting?.complete();
  }
}

/// The one [CoachHistoryEpoch]. `keepAlive`: it must outlive every session
/// and the Settings card, or a recreated one would forget the delete.
@Riverpod(keepAlive: true)
CoachHistoryEpoch coachHistoryEpoch(Ref ref) => CoachHistoryEpoch();
