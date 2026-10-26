import 'package:failures/failures.dart';

/// The stored coach history exists but can't be read: it isn't in the
/// format Steady writes. The store is left untouched, never overwritten,
/// so nothing in it is lost; "Delete coach history" still removes it.
class CoachHistoryUnreadableFailure extends Failure {
  /// Creates a [CoachHistoryUnreadableFailure].
  const CoachHistoryUnreadableFailure(super.message, {super.cause});
}

/// The coach history store couldn't be found, read, written or deleted
/// (a file-system error). Nothing was changed; trying again may work.
class CoachHistoryStorageFailure extends Failure {
  /// Creates a [CoachHistoryStorageFailure].
  const CoachHistoryStorageFailure(super.message, {super.cause});
}
