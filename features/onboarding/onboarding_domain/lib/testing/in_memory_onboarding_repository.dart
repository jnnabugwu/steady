import 'package:failures/failures.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

/// An [OnboardingRepository] held in memory, for tests.
///
/// It lives in the domain package (under `lib/testing/`, not exported from
/// `onboarding_domain.dart`) so presentation tests can use it without
/// depending on `onboarding_data`, which FFCA doesn't allow. It isn't a
/// guess at the real store's behaviour: `onboarding_data`'s tests run the
/// shared contract (`package:onboarding_data/testing/...`) against this and
/// `FileOnboardingRepository` alike. Test-only: never bind it in the app.
class InMemoryOnboardingRepository implements OnboardingRepository {
  /// Creates a repository holding [initial].
  InMemoryOnboardingRepository([
    OnboardingState initial = OnboardingState.initial,
  ]) : _state = initial;

  OnboardingState _state;

  /// What's stored now.
  OnboardingState get state => _state;

  /// When set, the next call returns `Err` of this failure and changes
  /// nothing, and this is cleared.
  Failure? failNextWith;

  @override
  ResultFuture<OnboardingState> read() async => _failure() ?? Ok(_state);

  @override
  ResultFuture<OnboardingState> saveAboutMe(AboutMe aboutMe) async {
    if (_failure() case final failure?) return failure;
    if (!isValidAboutMeNote(aboutMe.note)) {
      return const Err(
        ValidationFailure(
          'An About me note is at most $aboutMeNoteMaxChars characters',
        ),
      );
    }
    return Ok(_state = _state.copyWith(aboutMe: aboutMe));
  }

  @override
  ResultFuture<OnboardingState> markCompleted() async =>
      _failure() ?? Ok(_state = _state.copyWith(completed: true));

  Err<OnboardingState>? _failure() {
    final failure = failNextWith;
    if (failure == null) return null;
    failNextWith = null;
    return Err(failure);
  }
}
