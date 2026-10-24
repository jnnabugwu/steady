import 'package:cravings_domain/src/craving_event.dart';
import 'package:failures/failures.dart';

/// Stores craving check-ins **on this device only**.
///
/// Implementations must never sync or back up events to iCloud: craving
/// events with an intensity and a reason like "stressed" read as health
/// data (App Store 5.1.3(ii)). See CLAUDE.md §7.
abstract class CravingRepository {
  /// Saves [event], replacing any stored event with the same `id`.
  ///
  /// Returns `Err(ValidationFailure)` if an intensity is outside 1 to 5.
  ResultFuture<Unit> save(CravingEvent event);

  /// Every event whose `startedAt` is at or after [start] and before [end],
  /// oldest first.
  ResultFuture<List<CravingEvent>> getBetween(DateTime start, DateTime end);

  /// Deletes every stored event ("Delete craving history" in Settings).
  ResultFuture<Unit> deleteAll();
}
