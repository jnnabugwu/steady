import 'package:coach_domain/coach_domain.dart';
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
/// `keepAlive`: repositories are cheap and stateless (D6).
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
