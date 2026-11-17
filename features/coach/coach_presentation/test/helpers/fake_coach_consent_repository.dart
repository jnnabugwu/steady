import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';

/// An in-memory [CoachConsentRepository] that records every call.
class FakeCoachConsentRepository implements CoachConsentRepository {
  FakeCoachConsentRepository({this.agreed});

  /// The agreed version, as stored.
  int? agreed;

  /// The next write's failure (consumed by one write).
  Failure? failNext;

  /// Held by every write until completed, when set: lets a test look at the
  /// state while a write is in flight.
  Completer<void>? holdWrites;

  /// Every call, in order: `read`, `give <version>`, `withdraw`.
  final List<String> calls = [];

  @override
  ResultFuture<int?> readAgreedVersion() async {
    calls.add('read');
    return Ok(agreed);
  }

  @override
  ResultFuture<Unit> giveConsent(int version) async {
    calls.add('give $version');
    return await _write(() => agreed = version);
  }

  @override
  ResultFuture<Unit> withdrawConsent() async {
    calls.add('withdraw');
    return await _write(() => agreed = null);
  }

  Future<Result<Unit>> _write(void Function() apply) async {
    if (holdWrites case final hold?) await hold.future;
    if (failNext case final failure?) {
      failNext = null;
      return Err(failure);
    }
    apply();
    return const Ok(unit);
  }
}
