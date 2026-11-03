import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/src/providers.dart';
import 'package:failures/failures.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'coach_consent_controller.g.dart';

/// A [Failure] was already mapped at the `_data` boundary: surface it at
/// once instead of retrying (CLAUDE.md §4).
Duration? _retryUnlessFailure(int retryCount, Object error) =>
    error is Failure ? null : ProviderContainer.defaultRetry(retryCount, error);

/// Whether the person has agreed to what the coach sends, to whom and for
/// what, in the **current** version of the consent text
/// ([CoachConsent.currentVersion]; App Store 5.1.2). An agreement to an
/// earlier version doesn't count, so a bumped version asks again.
///
/// **Nothing reaches the proxy unless this is a settled `true`**
/// ([isCoachConsentGiven]): the coach screens check it before they offer a
/// session (`coachAvailability`, `CoachSessionController`), the session
/// checks it before every request and stops a reply in flight when it turns
/// `false`, and the hosted model checks it again before every request
/// (`app/lib/providers.dart` binds its `consentGiven` to this provider).
///
/// Read from [coachConsentRepositoryProvider], the device-only store; with
/// none bound (the Mac, a test), not given.
///
/// `keepAlive`: the one answer for the whole app, which every coach screen
/// and the model read.
@Riverpod(keepAlive: true, retry: _retryUnlessFailure)
class CoachConsentGiven extends _$CoachConsentGiven {
  @override
  Future<bool> build() async {
    final repository = ref.watch(coachConsentRepositoryProvider);
    if (repository == null) return false;
    return switch (await repository.readAgreedVersion()) {
      Ok(:final value) => value == CoachConsent.currentVersion,
      Err(:final failure) => throw failure,
    };
  }

  /// Domain event: CoachConsentGiven.
  ///
  /// "Allow and continue" on the consent screen (or the Settings switch
  /// turned on, through it): records agreement to
  /// [CoachConsent.currentVersion]. Ignored while loading or once disposed.
  Future<void> giveCoachConsent() => _write(
    (repository) => repository.giveConsent(CoachConsent.currentVersion),
    given: true,
  );

  /// Domain event: CoachConsentWithdrawn.
  ///
  /// The Settings switch turned off. The coach stops at once: the state is
  /// loading (so not given, [isCoachConsentGiven]) from this method's first
  /// line, before the store is written, which stops any reply in flight
  /// (`CoachSessionController`) and every new request. Conversations stay;
  /// "Delete coach history" is separate. Ignored while loading or once
  /// disposed.
  Future<void> withdrawCoachConsent() =>
      _write((repository) => repository.withdrawConsent(), given: false);

  Future<void> _write(
    ResultFuture<Unit> Function(CoachConsentRepository repository) write, {
    required bool given,
  }) async {
    if (!ref.mounted || state.isLoading) return;
    final repository = ref.read(coachConsentRepositoryProvider);
    state = const AsyncLoading();
    final result = repository == null
        ? const Err<Unit>(
            CoachConsentStorageFailure('No coach consent store on this device'),
          )
        : await write(repository);
    if (!ref.mounted) return;
    state = switch (result) {
      Ok() => AsyncData(given),
      Err(:final failure) => AsyncError(failure, StackTrace.current),
    };
  }
}

/// Whether [consent] (`coachConsentGivenProvider`'s state) lets the coach
/// send anything: only a settled `true`. Loading (including a withdrawal
/// being written) and an error are both "no".
bool isCoachConsentGiven(AsyncValue<bool> consent) => switch (consent) {
  AsyncData(value: true) => true,
  _ => false,
};

/// The consent answer once it's read: `true` only for a yes. A store that
/// can't be read is "no".
Future<bool> readCoachConsent(Future<bool> consent) async {
  try {
    return await consent;
  } on Object {
    return false;
  }
}
