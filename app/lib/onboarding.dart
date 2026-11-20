/// Onboarding's app-side wiring (#161, docs/design/onboarding.md): whether
/// the flow shows at launch, and what Today reads from its answers.
///
/// **Who sees it:** everyone, once, 1.0 users included: no
/// `onboarding.json` reads as not completed. iPhone only:
/// [onboardingSupportAvailableProvider] is `false` everywhere else, and
/// then nothing here reads the repository.
///
/// **Decided once per launch** ([OnboardingLaunchCheck], started by the
/// app root, `main.dart`). It shows only when all of these hold:
///
/// - the launch is an ordinary one: the platform's initial route is `/`,
///   not a link such as `/checkin/<date>` (a link opens; onboarding waits
///   for the next ordinary launch);
/// - the record says not completed. An unreadable file counts as done
///   (`OnboardingRecord.whenUnreadable`); a storage failure, or a read
///   slower than [onboardingLaunchReadTimeout], means not this launch;
/// - when the answer arrives, the app is still on Today with nothing
///   pushed over it (the person hasn't moved on).
///
/// The first frame never waits for it: Today draws first and the flow
/// replaces it once the read answers. After that one decision nothing
/// re-checks, so leaving or finishing never leads back into the flow
/// during the session (no redirect runs on navigation).
library;

import 'dart:async';
import 'dart:developer' as developer;

import 'package:failures/failures.dart';
import 'package:metrics_presentation/metrics_presentation.dart'
    show TodayMetricsEmptyHint;
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:steady/providers.dart';

part 'onboarding.g.dart';

/// How long the launch decision waits for `onboarding.json`. A read slower
/// than this (a few hundred bytes normally take milliseconds) skips
/// onboarding for this launch rather than holding Today back for long.
const onboardingLaunchReadTimeout = Duration(seconds: 1);

/// Whether onboarding should show, from [repository]'s record (see the
/// library comment). Never throws: only a readable record that says not
/// completed is a yes. [OnboardingLaunchCheck] adds the time limit.
Future<bool> shouldShowOnboardingAtLaunch(
  OnboardingRepository repository,
) async {
  try {
    switch (await repository.read()) {
      case Ok(:final value):
        return !value.completed;
      case Err(failure: OnboardingUnreadableFailure()):
        // A damaged file never puts the flow in front of anyone.
        return !OnboardingRecord.whenUnreadable.completed;
      case Err(:final failure):
        _log('Onboarding not shown: ${failure.message}', failure.cause);
        return false;
    }
  } on Object catch (error) {
    _log('Onboarding not shown: reading its record failed', error);
    return false;
  }
}

/// This launch's onboarding decision: [shouldShowOnboardingAtLaunch], or
/// `false` once the time limit (by default
/// [onboardingLaunchReadTimeout]) passes first. Started by the app root, which
/// calls [cancel] when it goes away, so no timer outlives it.
final class OnboardingLaunchCheck {
  /// Starts reading [repository]'s record.
  OnboardingLaunchCheck(
    OnboardingRepository repository, {
    Duration timeout = onboardingLaunchReadTimeout,
  }) {
    _deadline = Timer(timeout, () {
      if (!_due.isCompleted) {
        _log('Onboarding not shown: reading its record took too long', null);
      }
      _finish(show: false);
    });
    unawaited(
      shouldShowOnboardingAtLaunch(repository)
          .then((show) => _finish(show: show)),
    );
  }

  final _due = Completer<bool>();
  late final Timer _deadline;

  /// Whether to show onboarding this launch. Completes once.
  Future<bool> get due => _due.future;

  /// Stops waiting: [due] completes with `false` if it hasn't yet.
  void cancel() => _finish(show: false);

  void _finish({required bool show}) {
    _deadline.cancel();
    if (!_due.isCompleted) _due.complete(show);
  }
}

void _log(String message, Object? error) =>
    developer.log(message, name: 'steady.onboarding', error: error);

/// How the person tracks food, from onboarding screen 2 or Settings → About
/// me, or `null`: not answered, no onboarding on this device, or the record
/// couldn't be read.
///
/// **The one source** for everything on Today that follows the answer
/// ([todayImportButtonShownProvider], [todayMetricsEmptyHintProvider] and
/// `todayHealthPromptProvider`): whoever writes the record invalidates
/// this, and they all follow. The onboarding route does on the way out,
/// and Settings → About me after every edit (`AboutMeRoute`), so Today
/// changes straight away, without a relaunch.
///
/// Auto-dispose: read again whenever Today is built afresh too.
@riverpod
Future<FoodTracking?> onboardingFoodTracking(Ref ref) async {
  if (!ref.watch(onboardingSupportAvailableProvider)) return null;
  final result = await ref.watch(onboardingRepositoryProvider).read();
  return switch (result) {
    Ok(:final value) => value.aboutMe.tracking,
    Err() => null,
  };
}

/// What Today's empty-metrics card says, from screen 2's answer: the Cal AI
/// import for `calAi` and no answer (also while loading, or unreadable), a
/// note that another food app's calories come through Apple Health for
/// `otherHealthApp`, and no ask at all for `justStarting`.
@riverpod
TodayMetricsEmptyHint todayMetricsEmptyHint(Ref ref) =>
    switch (ref.watch(onboardingFoodTrackingProvider).value) {
      FoodTracking.otherHealthApp => TodayMetricsEmptyHint.healthApp,
      FoodTracking.justStarting => TodayMetricsEmptyHint.justStarting,
      FoodTracking.calAi || null => TodayMetricsEmptyHint.calAiImport,
    };

/// Whether Today's header shows the Cal AI import button
/// (docs/design/onboarding.md, screen 2: the answer decides it). Hidden
/// only for someone who said they track with another Health app, or are
/// just starting; shown for Cal AI, no answer, and while the answer is
/// still being read. The Week tab's header keeps its import button for
/// everyone.
@riverpod
bool todayImportButtonShown(Ref ref) =>
    switch (ref.watch(onboardingFoodTrackingProvider).value) {
      FoodTracking.otherHealthApp || FoodTracking.justStarting => false,
      FoodTracking.calAi || null => true,
    };
