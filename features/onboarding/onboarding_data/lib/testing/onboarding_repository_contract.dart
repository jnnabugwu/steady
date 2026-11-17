import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';

/// Runs the shared `OnboardingRepository` contract against whatever [build]
/// constructs, each test on a fresh, empty store: `FileOnboardingRepository`
/// on a temp file and the domain's `InMemoryOnboardingRepository`, so the
/// in-memory one that presentation tests use behaves like the real store by
/// construction.
///
/// [makeUnreadable] puts what [build] last returned into the unreadable
/// state (a corrupt file, or the in-memory store's `makeUnreadable`), for
/// the tests of what a write over it does. Other corrupt-file details, and
/// restarts, are the file store's own tests. Lives under `lib/testing/` so
/// `app/` can import it. Test-only: never import it from `lib/src/`.
void runOnboardingRepositoryContractTests(
  OnboardingRepository Function() build, {
  required Future<void> Function(OnboardingRepository repo) makeUnreadable,
}) {
  T ok<T>(Result<T> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final failure) => fail('Expected Ok, got $failure'),
  };

  const answers = AboutMe(
    voice: CoachVoice.playful,
    tracking: FoodTracking.calAi,
    activities: {OnboardingActivity.tennis, OnboardingActivity.walks},
    weekends: WeekendShape.mixed,
    hardParts: {HardPart.eatingOut, HardPart.feelingJudged},
    note: 'I work nights twice a month',
  );

  group('OnboardingRepository contract', () {
    test('an empty store is a first launch', () async {
      expect(ok(await build().read()), OnboardingRecord.initial);
    });

    test('saveAboutMe stores the answers and returns the record', () async {
      final repo = build();
      final saved = ok(await repo.saveAboutMe(answers));
      expect(saved, const OnboardingRecord(aboutMe: answers));
      expect(ok(await repo.read()), saved);
    });

    test('saveAboutMe alone does not complete onboarding', () async {
      final repo = build();
      await repo.saveAboutMe(answers);
      expect(ok(await repo.read()).completed, isFalse);
    });

    test('saveAboutMe replaces the answers, it does not merge', () async {
      final repo = build();
      await repo.saveAboutMe(answers);
      const fewer = AboutMe(voice: CoachVoice.direct);
      await repo.saveAboutMe(fewer);
      expect(ok(await repo.read()).aboutMe, fewer);
    });

    test('markCompleted completes it and keeps the answers', () async {
      final repo = build();
      await repo.saveAboutMe(answers);
      final completed = ok(await repo.markCompleted());
      expect(
        completed,
        const OnboardingRecord(completed: true, aboutMe: answers),
      );
      expect(ok(await repo.read()), completed);
    });

    test('markCompleted with nothing answered (skipped to the end)', () async {
      final repo = build();
      ok(await repo.markCompleted());
      expect(
        ok(await repo.read()),
        OnboardingRecord.initial.copyWith(completed: true),
      );
    });

    test('markCompleted again changes nothing', () async {
      final repo = build();
      await repo.saveAboutMe(answers);
      final once = ok(await repo.markCompleted());
      expect(ok(await repo.markCompleted()), once);
      expect(ok(await repo.read()), once);
    });

    test('editing About me after completion keeps it completed', () async {
      // Settings → About me, after onboarding.
      final repo = build();
      await repo.saveAboutMe(answers);
      await repo.markCompleted();
      final edited = answers.copyWith(
        voice: CoachVoice.gentle,
        hardParts: {HardPart.travel},
        note: null,
      );
      final saved = ok(await repo.saveAboutMe(edited));
      expect(saved, OnboardingRecord(completed: true, aboutMe: edited));
      expect(ok(await repo.read()), saved);
    });

    test('clearing every answer after completion keeps it completed', () async {
      final repo = build();
      await repo.saveAboutMe(answers);
      await repo.markCompleted();
      await repo.saveAboutMe(AboutMe.empty);
      expect(
        ok(await repo.read()),
        OnboardingRecord.initial.copyWith(completed: true),
      );
    });

    test('a note at the limit, in code points, is saved', () async {
      final repo = build();
      final note = '😀' * aboutMeNoteMaxChars;
      ok(await repo.saveAboutMe(AboutMe(note: note)));
      expect(ok(await repo.read()).aboutMe.note, note);
    });

    test('a note over the limit is refused and nothing changes', () async {
      final repo = build();
      await repo.saveAboutMe(answers);
      await repo.markCompleted();
      final before = ok(await repo.read());

      final result = await repo.saveAboutMe(
        AboutMe(note: 'a' * (aboutMeNoteMaxChars + 1)),
      );
      expect(result, isA<Err<OnboardingRecord>>());
      expect(
        (result as Err<OnboardingRecord>).failure,
        isA<ValidationFailure>(),
      );
      expect(ok(await repo.read()), before);
    });

    test('every code of every answer round-trips', () async {
      final repo = build();
      final everything = AboutMe(
        activities: OnboardingActivity.values.toSet(),
        hardParts: HardPart.values.toSet(),
      );
      await repo.saveAboutMe(everything);
      expect(ok(await repo.read()).aboutMe, everything);

      for (final voice in CoachVoice.values) {
        for (final tracking in FoodTracking.values) {
          for (final weekends in WeekendShape.values) {
            final one = AboutMe(
              voice: voice,
              tracking: tracking,
              weekends: weekends,
            );
            await repo.saveAboutMe(one);
            expect(ok(await repo.read()).aboutMe, one);
          }
        }
      }
    });

    group('step', () {
      test('saveStep stores it and returns the record', () async {
        final repo = build();
        final saved = ok(await repo.saveStep(OnboardingStep.week));
        expect(saved, const OnboardingRecord(step: OnboardingStep.week));
        expect(ok(await repo.read()), saved);
      });

      test('saveStep keeps the answers, and saveAboutMe the step', () async {
        final repo = build();
        await repo.saveAboutMe(answers);
        await repo.saveStep(OnboardingStep.hardParts);
        const fewer = AboutMe(voice: CoachVoice.gentle);
        final saved = ok(await repo.saveAboutMe(fewer));
        expect(
          saved,
          const OnboardingRecord(
            step: OnboardingStep.hardParts,
            aboutMe: fewer,
          ),
        );
        expect(ok(await repo.read()), saved);
      });

      test('saveStep replaces the step, back or forward', () async {
        final repo = build();
        await repo.saveStep(OnboardingStep.voice);
        await repo.saveStep(OnboardingStep.tracking);
        expect(ok(await repo.read()).step, OnboardingStep.tracking);
      });

      test('every step round-trips', () async {
        final repo = build();
        for (final step in OnboardingStep.values) {
          await repo.saveStep(step);
          expect(ok(await repo.read()).step, step);
        }
      });

      test('markCompleted clears the step and keeps the answers', () async {
        final repo = build();
        await repo.saveAboutMe(answers);
        await repo.saveStep(OnboardingStep.cairn);
        final completed = ok(await repo.markCompleted());
        expect(
          completed,
          const OnboardingRecord(completed: true, aboutMe: answers),
        );
        expect(ok(await repo.read()), completed);
      });
    });

    group('a write over an unreadable store', () {
      test('read reports it as OnboardingUnreadableFailure', () async {
        final repo = build();
        await makeUnreadable(repo);
        expect(
          await repo.read(),
          isA<Err<OnboardingRecord>>().having(
            (e) => e.failure,
            'failure',
            isA<OnboardingUnreadableFailure>(),
          ),
        );
      });

      test('saveAboutMe starts from done: completed, no step', () async {
        final repo = build();
        await repo.saveStep(OnboardingStep.week);
        await makeUnreadable(repo);
        final saved = ok(await repo.saveAboutMe(answers));
        expect(
          saved,
          const OnboardingRecord(completed: true, aboutMe: answers),
        );
        expect(ok(await repo.read()), saved);
      });

      test('saveStep starts from done, too', () async {
        // Odd but consistent: the app treats an unreadable store as done,
        // so it shouldn't be in the flow to save a step. If it is, the
        // replacement still agrees with what the app showed.
        final repo = build();
        await makeUnreadable(repo);
        final saved = ok(await repo.saveStep(OnboardingStep.voice));
        expect(
          saved,
          const OnboardingRecord(completed: true, step: OnboardingStep.voice),
        );
        expect(ok(await repo.read()), saved);
      });

      test('markCompleted is completed, with nothing answered', () async {
        final repo = build();
        await repo.saveAboutMe(answers);
        await makeUnreadable(repo);
        expect(ok(await repo.markCompleted()), OnboardingRecord.whenUnreadable);
        expect(ok(await repo.read()), OnboardingRecord.whenUnreadable);
      });

      test('a refused note still changes nothing', () async {
        final repo = build();
        await makeUnreadable(repo);
        final result = await repo.saveAboutMe(
          AboutMe(note: 'a' * (aboutMeNoteMaxChars + 1)),
        );
        expect((result as Err).failure, isA<ValidationFailure>());
        expect(
          (await repo.read() as Err).failure,
          isA<OnboardingUnreadableFailure>(),
        );
      });
    });
  });
}
