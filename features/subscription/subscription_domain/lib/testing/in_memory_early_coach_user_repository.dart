import 'package:failures/failures.dart';
import 'package:subscription_domain/subscription_domain.dart';

/// An [EarlyCoachUserRepository] held in memory, for tests. The same
/// contract runs against it and the file store in `subscription_data`.
/// Test-only: never bind it in the app.
class InMemoryEarlyCoachUserRepository implements EarlyCoachUserRepository {
  /// Creates a store holding [decided] (`null`: nothing decided yet).
  InMemoryEarlyCoachUserRepository({this.decided});

  /// What's stored now.
  bool? decided;

  /// When set, the next call returns `Err` of this failure and changes
  /// nothing, and this is cleared.
  Failure? failNextWith;

  @override
  ResultFuture<bool?> read() async => _failure<bool?>() ?? Ok(decided);

  @override
  ResultFuture<bool> decideOnce({required bool usedCoach}) async =>
      _failure<bool>() ?? Ok(decided ??= usedCoach);

  Err<T>? _failure<T>() {
    final failure = failNextWith;
    if (failure == null) return null;
    failNextWith = null;
    return Err(failure);
  }
}
