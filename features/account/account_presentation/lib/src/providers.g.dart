// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
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

@ProviderFor(accountStatusRepository)
final accountStatusRepositoryProvider = AccountStatusRepositoryProvider._();

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

final class AccountStatusRepositoryProvider
    extends
        $FunctionalProvider<
          AccountStatusRepository,
          AccountStatusRepository,
          AccountStatusRepository
        >
    with $Provider<AccountStatusRepository> {
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
  AccountStatusRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'accountStatusRepositoryProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$accountStatusRepositoryHash();

  @$internal
  @override
  $ProviderElement<AccountStatusRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  AccountStatusRepository create(Ref ref) {
    return accountStatusRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(AccountStatusRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<AccountStatusRepository>(value),
    );
  }
}

String _$accountStatusRepositoryHash() =>
    r'6d7719618ab7c82dadbefab0fcbc4c43af017338';
