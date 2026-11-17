import 'package:failures/failures.dart';

/// The stored onboarding state exists but can't be read: it isn't in the
/// format Steady writes. The next write replaces it
/// (`OnboardingRepository`).
class OnboardingUnreadableFailure extends Failure {
  /// Creates an [OnboardingUnreadableFailure].
  const OnboardingUnreadableFailure(super.message, {super.cause});
}

/// The onboarding store couldn't be found, read or written (a file-system
/// error). Nothing was changed; trying again may work.
class OnboardingStorageFailure extends Failure {
  /// Creates an [OnboardingStorageFailure].
  const OnboardingStorageFailure(super.message, {super.cause});
}
