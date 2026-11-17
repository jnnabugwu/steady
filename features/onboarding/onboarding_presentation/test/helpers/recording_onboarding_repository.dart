import 'dart:async';

import 'package:failures/failures.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_domain/testing/in_memory_onboarding_repository.dart';

/// The domain's [InMemoryOnboardingRepository] (which `onboarding_data`
/// runs the same contract against as the file store), plus a log of every
/// call and a way to hold writes mid-flight.
class RecordingOnboardingRepository implements OnboardingRepository {
  /// Creates a repository holding [initial].
  RecordingOnboardingRepository([
    OnboardingRecord initial = OnboardingRecord.initial,
  ]) : store = InMemoryOnboardingRepository(initial);

  /// The store behind it.
  final InMemoryOnboardingRepository store;

  /// Every call, in order: `read`, `saveAboutMe`, `saveStep:<code>`,
  /// `markCompleted`.
  final List<String> calls = [];

  /// When set, every write waits for it before reaching [store].
  Completer<void>? holdWrites;

  /// What's stored now.
  OnboardingRecord get record => store.record;

  Future<void> _hold() async {
    if (holdWrites case final hold?) await hold.future;
  }

  @override
  ResultFuture<OnboardingRecord> read() {
    calls.add('read');
    return store.read();
  }

  @override
  ResultFuture<OnboardingRecord> saveAboutMe(AboutMe aboutMe) async {
    calls.add('saveAboutMe');
    await _hold();
    return await store.saveAboutMe(aboutMe);
  }

  @override
  ResultFuture<OnboardingRecord> saveStep(OnboardingStep step) async {
    calls.add('saveStep:${step.name}');
    await _hold();
    return await store.saveStep(step);
  }

  @override
  ResultFuture<OnboardingRecord> markCompleted() async {
    calls.add('markCompleted');
    await _hold();
    return await store.markCompleted();
  }
}
