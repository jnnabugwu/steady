import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';

/// An in-memory [CoachRepository] that records calls. Set [onDeleteAll] to
/// make a delete fail or wait.
class FakeCoachRepository implements CoachRepository {
  FakeCoachRepository([Iterable<CoachSession> sessions = const []])
    : sessions = [...sessions];

  /// What's stored, in save order.
  final List<CoachSession> sessions;

  /// How many times [deleteAll] was called.
  int deleteAllCalls = 0;

  /// Overrides [deleteAll]'s result; `null` clears and returns Ok.
  Future<Result<Unit>> Function()? onDeleteAll;

  /// Overrides [listSessions]'s result; `null` lists what's stored.
  Future<Result<List<CoachSession>>> Function()? onList;

  @override
  ResultFuture<List<CoachSession>> listSessions() async {
    if (onList case final onList?) return await onList();
    return Ok([...sessions]..sort(compareCoachSessionsNewestFirst));
  }

  @override
  ResultFuture<CoachSession?> getSession(String id) async =>
      Ok(sessions.where((s) => s.id == id).firstOrNull);

  /// Overrides [saveSession]'s result; `null` stores and returns Ok.
  Future<Result<Unit>> Function(CoachSession session)? onSave;

  @override
  ResultFuture<Unit> saveSession(CoachSession session) async {
    if (onSave case final onSave?) return await onSave(session);
    sessions
      ..removeWhere((s) => s.id == session.id)
      ..add(session);
    return const Ok(unit);
  }

  @override
  ResultFuture<Unit> deleteAll() async {
    deleteAllCalls++;
    if (onDeleteAll case final onDeleteAll?) return await onDeleteAll();
    sessions.clear();
    return const Ok(unit);
  }
}
