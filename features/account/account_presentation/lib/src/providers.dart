import 'package:account_domain/account_domain.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'providers.g.dart';

/// The `AccountStatusRepository` this feature reads through.
///
/// Typed against the domain interface only: this package never depends on
/// `account_data` (CLAUDE.md §3). `app/lib/providers.dart` overrides it with
/// the platform-channel implementation in `appProviderOverrides` (CLAUDE.md
/// §9); tests override it with a fake. Reading it without an override
/// throws.
///
/// `keepAlive`: repositories are cheap and stateless, so recreating one
/// gains nothing (D6).
@Riverpod(keepAlive: true)
AccountStatusRepository accountStatusRepository(Ref ref) =>
    throw UnimplementedError(
      'Override accountStatusRepositoryProvider in app/',
    );
