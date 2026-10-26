import 'dart:math';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/coach_week_context.dart';
import 'package:coach_presentation/src/coach_weekly_readiness.dart';
import 'package:cravings_domain/cravings_domain.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `CoachRepository` coach sessions and transcripts are stored through.
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the device-only file store; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of quietly creating a store
/// (CLAUDE.md §11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: unlike most repositories (D6), the file store is stateful —
/// it owns the loaded sessions and the queue that serialises every write.
/// One instance has to own both, so disposing it mid-write is not an option.
@Riverpod(keepAlive: true)
CoachRepository coachRepository(Ref ref) =>
    throw UnimplementedError('Override coachRepositoryProvider in app/');

/// Whether this device has the coach at all: `true` on iOS only.
///
/// A platform fact, not the model's runtime availability (whether this
/// iPhone supports Apple Intelligence and the model is ready), which the
/// coach checks separately when a session starts. `false` by default;
/// `app/lib/providers.dart` sets it from the platform
/// (`appProviderOverridesFor(isIOS: ...)`), so tests can cover both. When
/// it's `false` the coach's Settings card renders nothing.
///
/// `keepAlive`: a constant for the app's lifetime.
@Riverpod(keepAlive: true)
bool coachSupportAvailable(Ref ref) => false;

/// The on-device model the coach talks through (Apple Foundation Models).
///
/// Typed against the domain interface only: this package never depends on
/// `coach_data` (CLAUDE.md §3). `app/lib/providers.dart` binds it on iOS
/// only, to the `steady/coach` channel; on macOS it stays unbound, so a Mac
/// path that reads it fails loudly instead of reaching for a model that
/// isn't there (§11). Tests override it with a fake. Reading it without an
/// override throws.
///
/// `keepAlive`: cheap and stateless (D6); the native side holds the
/// sessions.
@Riverpod(keepAlive: true)
CoachModel coachModel(Ref ref) =>
    throw UnimplementedError('Override coachModelProvider in app/ (iOS only)');

/// Check-in statuses, for the coach's context. Bound by the app to the
/// check-in feature's own repository (the same instance, so the same
/// shared store; CLAUDE.md §9). Typed against `checkin_domain` only.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CheckInRepository coachCheckInRepository(Ref ref) => throw UnimplementedError(
  'Override coachCheckInRepositoryProvider in app/ (iOS only)',
);

/// Calories eaten, for the coach's context. Bound by the app to the
/// metrics feature's repository (the same instance). Typed against
/// `metrics_domain` only.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
MetricsRepository coachMetricsRepository(Ref ref) => throw UnimplementedError(
  'Override coachMetricsRepositoryProvider in app/ (iOS only)',
);

/// Apple Health's daily totals, read live for the coach's context and
/// never stored, or `null` where there's no Health (CLAUDE.md §7). Bound
/// by the app to its one Health source.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
HealthKitRepository? coachHealthKitRepository(Ref ref) => null;

/// Craving check-ins, for the coach's context (counts, time of day and
/// reasons; never turned into calorie advice, #82), or `null` where
/// craving support isn't bound. Bound by the app to the cravings
/// feature's repository (the same instance, so the same device-only file).
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CravingRepository? coachCravingRepository(Ref ref) => null;

/// The current time, as the coach reads it.
typedef CoachClock = DateTime Function();

/// The clock the coach reads "now" from (session start, message times, the
/// context's days). Defaults to [DateTime.now]; tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CoachClock coachClock(Ref ref) => DateTime.now;

/// Makes a new, unique coach session id.
typedef CoachIdGenerator = String Function();

/// The id generator for new coach sessions: a random version 4 UUID by
/// default ([randomCoachSessionId]); tests pin it.
///
/// `keepAlive`: cheap and stateless (D6).
@Riverpod(keepAlive: true)
CoachIdGenerator coachIdGenerator(Ref ref) => randomCoachSessionId;

final Random _random = Random.secure();

/// A random version 4 UUID, e.g. `3f2b8c1e-9a4d-4c7e-8b21-5d0f6a7e9c13`.
String randomCoachSessionId() {
  final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40; // version 4
  bytes[8] = (bytes[8] & 0x3f) | 0x80; // RFC 4122 variant
  final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
      '${hex.substring(12, 16)}-${hex.substring(16, 20)}-${hex.substring(20)}';
}

/// The weekly session's gate: the 4-of-7 check-in rule (#81, CLAUDE.md
/// §4), over [coachCheckInRepositoryProvider].
@riverpod
CheckWeeklyReadiness coachWeeklyReadiness(Ref ref) =>
    CheckWeeklyReadiness(ref.watch(coachCheckInRepositoryProvider));

/// The use case that builds the coach's context from the four domains
/// above (CLAUDE.md §4: it combines several repositories).
@riverpod
BuildCoachWeekContext coachWeekContext(Ref ref) => BuildCoachWeekContext(
  checkIns: ref.watch(coachCheckInRepositoryProvider),
  metrics: ref.watch(coachMetricsRepositoryProvider),
  health: ref.watch(coachHealthKitRepositoryProvider),
  cravings: ref.watch(coachCravingRepositoryProvider),
);
