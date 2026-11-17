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
    OnboardingRecord initial = OnboardingRecord.initial,
  ]) : _record = initial;

  OnboardingRecord _record;

  /// What's stored now.
  OnboardingRecord get record => _record;

  /// When set, the next call returns `Err` of this failure and changes
  /// nothing, and this is cleared. For an unreadable store, use
  /// [makeUnreadable] instead: it also changes what the next write does.
  Failure? failNextWith;

  bool _unreadable = false;

  /// Makes the store act like a corrupt file: [read] returns
  /// `Err(OnboardingUnreadableFailure)` until the next write, which starts
  /// from [OnboardingRecord.whenUnreadable], as `FileOnboardingRepository`
  /// does.
  void makeUnreadable() => _unreadable = true;

  @override
  ResultFuture<OnboardingRecord> read() async {
    if (_failure() case final failure?) return failure;
    if (_unreadable) {
      return const Err(
        OnboardingUnreadableFailure('In-memory onboarding store unreadable'),
      );
    }
    return Ok(_record);
  }

  @override
  ResultFuture<OnboardingRecord> saveAboutMe(AboutMe aboutMe) async {
    if (_failure() case final failure?) return failure;
    final note = trimAboutMeNote(aboutMe.note);
    if (!isValidAboutMeNote(note)) {
      return const Err(
        ValidationFailure(
          'An About me note is at most $aboutMeNoteMaxChars characters',
        ),
      );
    }
    final stored = aboutMe.copyWith(note: note);
    return Ok(_write((r) => r.copyWith(aboutMe: stored)));
  }

  @override
  ResultFuture<OnboardingRecord> saveStep(OnboardingStep step) async =>
      _failure() ?? Ok(_write((r) => r.copyWith(step: step)));

  @override
  ResultFuture<OnboardingRecord> markCompleted() async =>
      _failure() ?? Ok(_write((r) => r.copyWith(completed: true, step: null)));

  OnboardingRecord _write(OnboardingRecord Function(OnboardingRecord) change) {
    final current = _unreadable ? OnboardingRecord.whenUnreadable : _record;
    _unreadable = false;
    return _record = change(current);
  }

  Err<OnboardingRecord>? _failure() {
    final failure = failNextWith;
    if (failure == null) return null;
    failNextWith = null;
    return Err(failure);
  }
}
