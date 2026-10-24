import 'package:cravings_domain/cravings_domain.dart';
import 'package:failures/failures.dart';

/// An in-memory [CravingRepository] that records calls. Set [onSave] or
/// [onDeleteAll] to make a call fail or wait.
class FakeCravingRepository implements CravingRepository {
  FakeCravingRepository([Iterable<CravingEvent> events = const []])
    : events = [...events];

  /// What's stored, in save order.
  final List<CravingEvent> events;

  /// Every event passed to [save], in order.
  final List<CravingEvent> saveCalls = [];

  /// How many times [deleteAll] was called.
  int deleteAllCalls = 0;

  /// Overrides [save]'s result; `null` stores the event and returns Ok.
  Future<Result<Unit>> Function(CravingEvent event)? onSave;

  /// Overrides [deleteAll]'s result; `null` clears and returns Ok.
  Future<Result<Unit>> Function()? onDeleteAll;

  /// Overrides [getBetween]'s result.
  Future<Result<List<CravingEvent>>> Function()? onGetBetween;

  @override
  ResultFuture<Unit> save(CravingEvent event) async {
    saveCalls.add(event);
    if (onSave case final onSave?) return await onSave(event);
    events
      ..removeWhere((e) => e.id == event.id)
      ..add(event);
    return const Ok(unit);
  }

  @override
  ResultFuture<List<CravingEvent>> getBetween(
    DateTime start,
    DateTime end,
  ) async {
    if (onGetBetween case final onGetBetween?) return await onGetBetween();
    return Ok([
      for (final e in events)
        if (!e.startedAt.isBefore(start) && e.startedAt.isBefore(end)) e,
    ]);
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    deleteAllCalls++;
    if (onDeleteAll case final onDeleteAll?) return await onDeleteAll();
    events.clear();
    return const Ok(unit);
  }
}
