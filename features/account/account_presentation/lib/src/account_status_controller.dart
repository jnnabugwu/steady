import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'account_status_controller.g.dart';

/// Retry policy for [AccountStatusController].
///
/// A [Failure] has already been mapped at the `_data` boundary (CLAUDE.md
/// §9), so it is surfaced immediately as `AsyncError` instead of being
/// retried. Riverpod 3's default retry would otherwise hold the provider in
/// `AsyncLoading` for about 38 s first. Any other error falls back to
/// Riverpod's default retry.
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// This device's iCloud [AccountStatus].
///
/// Never gates the app (CLAUDE.md §7: iCloud is optional). It drives the
/// non-blocking `ICloudSyncBanner` on the home screen, and the app root
/// re-checks it on every return to the foreground.
///
/// **Lifetime: `keepAlive`.** It's app-wide state, not screen state: the
/// app root re-checks it on resume whichever screen is showing, and it
/// isn't a family, so keeping it alive holds exactly one instance.
/// Disposing it whenever the home screen went away would throw away the
/// last known status and re-read the platform channel on the way back.
///
/// Repository errors arrive as a typed [Failure] and are surfaced without
/// retrying; any other (unexpected) error goes through Riverpod's default
/// retry before it reaches `AsyncError`.
@Riverpod(keepAlive: true, retry: _retryUnlessFailure)
class AccountStatusController extends _$AccountStatusController {
  @override
  Future<AccountStatus> build() async {
    final result = await ref
        .watch(accountStatusRepositoryProvider)
        .accountStatus();
    return switch (result) {
      Ok(:final value) => value,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: AccountRechecked.
  ///
  /// Reads the account status again, for the app returning to the
  /// foreground (the user may have just signed in from
  /// Settings). The state goes `AsyncLoading` (keeping the previous value)
  /// and then `AsyncData` with the new status, or `AsyncError` carrying the
  /// repository's [Failure].
  ///
  /// Ignored while a read is already in flight (the initial read or another
  /// re-check), so rapid taps and resume events can't stack up channel
  /// calls, and after the provider has been disposed.
  Future<void> recheckAccount() async {
    if (!ref.mounted || state.isLoading) return;
    state = const AsyncLoading();
    final result = await ref
        .read(accountStatusRepositoryProvider)
        .accountStatus();
    if (!ref.mounted) return;
    state = switch (result) {
      Ok(:final value) => AsyncData(value),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}
