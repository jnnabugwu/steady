import 'package:coach_domain/coach_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

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
