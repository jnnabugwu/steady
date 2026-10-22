import 'package:checkin_domain/checkin_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `CheckInRepository` this feature reads and writes through.
///
/// Typed against the domain interface only: this package never depends on
/// `checkin_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the real implementation in `appProviderOverrides` (CLAUDE.md §9); tests
/// override it with a fake. Reading it without an override throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).
@Riverpod(keepAlive: true)
CheckInRepository checkInRepository(Ref ref) =>
    throw UnimplementedError('Override checkInRepositoryProvider in app/');
