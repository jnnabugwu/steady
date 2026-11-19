import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:onboarding_domain/onboarding_domain.dart';
import 'package:onboarding_presentation/onboarding_presentation.dart';
import 'package:onboarding_presentation/src/onboarding_widgets.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/recording_onboarding_repository.dart';

/// Settings → About me (#172): each answer editable on its own, saved
/// through `saveAboutMe`, cleared back to skipped, the paid badge on the
/// coach's answers, a failed save kept on screen, and the note's limit.
void main() {
  late RecordingOnboardingRepository repository;
  late int changed;
  late int backs;

  /// A finished onboarding with every answer given: what Settings sees.
  const answered = OnboardingRecord(
    completed: true,
    aboutMe: AboutMe(
      voice: CoachVoice.gentle,
      tracking: FoodTracking.calAi,
      activities: {OnboardingActivity.tennis, OnboardingActivity.walks},
      weekends: WeekendShape.busier,
      hardParts: {HardPart.eatingOut},
      note: 'I work nights twice a month',
    ),
  );

  Future<void> pumpEditor(
    WidgetTester tester, {
    OnboardingRecord record = answered,
    void Function(RecordingOnboardingRepository)? arrange,
  }) async {
    tester.view
      ..physicalSize = const Size(390 * 3, 844 * 3)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repository = RecordingOnboardingRepository(record);
    arrange?.call(repository);
    changed = 0;
    backs = 0;
    final container = ProviderContainer.test(
      overrides: [onboardingRepositoryProvider.overrideWithValue(repository)],
    );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: ShadcnApp(
          theme: steadyTheme,
          home: AboutMeModule(
            onBack: () => backs++,
            onAboutMeChanged: () => changed++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder byKey(String key) => find.byKey(Key(key));
  Finder option(Enum value) => byKey('aboutMeOption_${value.name}');

  Future<void> tap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  bool rowSelected(WidgetTester tester, Enum value) =>
      tester.widget<OnboardingChoiceRow>(option(value)).selected;

  bool chipSelected(WidgetTester tester, OnboardingActivity value) =>
      tester.widget<OnboardingChip>(option(value)).selected;

  AboutMe stored() => repository.record.aboutMe;

  String noteOnScreen(WidgetTester tester) =>
      tester.widget<TextField>(byKey('aboutMeNoteField')).controller!.text;

  /// The fields of what's stored, as the wire codes the coach proxy will
  /// receive (docs/design/onboarding.md, "About me").
  Map<String, Object?> storedCodes() {
    final a = stored();
    return {
      'voice': a.voice?.name,
      'tracking': a.tracking?.name,
      'activities': a.activities.map((x) => x.name).toSet(),
      'weekends': a.weekends?.name,
      'hardParts': a.hardParts.map((x) => x.name).toSet(),
      'note': a.note,
    };
  }

  testWidgets('opens with the stored answers chosen and the note filled in', (
    tester,
  ) async {
    await pumpEditor(tester);

    expect(find.text(OnboardingCopy.aboutMeTitle), findsOneWidget);
    expect(rowSelected(tester, FoodTracking.calAi), isTrue);
    expect(rowSelected(tester, FoodTracking.justStarting), isFalse);
    expect(chipSelected(tester, OnboardingActivity.tennis), isTrue);
    expect(chipSelected(tester, OnboardingActivity.gym), isFalse);
    expect(rowSelected(tester, WeekendShape.busier), isTrue);
    expect(rowSelected(tester, HardPart.eatingOut), isTrue);
    expect(rowSelected(tester, CoachVoice.gentle), isTrue);
    expect(find.text('I work nights twice a month'), findsOneWidget);
    // Reading saved nothing.
    expect(repository.calls, ['read']);
  });

  group('each answer saves its code on its own, and never touches whether '
      'onboarding is done', () {
    testWidgets('food tracking', (tester) async {
      await pumpEditor(tester);
      for (final tracking in FoodTracking.values.reversed) {
        await tap(tester, option(tracking));
        expect(storedCodes()['tracking'], tracking.name);
        expect(rowSelected(tester, tracking), isTrue);
      }
      // Only tracking changed.
      expect(stored(), answered.aboutMe.copyWith(tracking: FoodTracking.calAi));
      expect(repository.record.completed, isTrue);
      expect(repository.record.step, isNull);
      expect(repository.calls.where((c) => c != 'saveAboutMe'), ['read']);
    });

    testWidgets('activities', (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(OnboardingActivity.gym));
      await tap(tester, option(OnboardingActivity.tennis));
      expect(storedCodes()['activities'], {'walks', 'gym'});
      expect(chipSelected(tester, OnboardingActivity.gym), isTrue);
      expect(chipSelected(tester, OnboardingActivity.tennis), isFalse);
      expect(
        stored(),
        answered.aboutMe.copyWith(
          activities: {OnboardingActivity.walks, OnboardingActivity.gym},
        ),
      );
    });

    testWidgets('weekends', (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(WeekendShape.mixed));
      expect(storedCodes()['weekends'], 'mixed');
      expect(rowSelected(tester, WeekendShape.busier), isFalse);
      expect(stored(), answered.aboutMe.copyWith(weekends: WeekendShape.mixed));
    });

    testWidgets('what gets in the way', (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(HardPart.feelingJudged));
      await tap(tester, option(HardPart.weekends));
      expect(storedCodes()['hardParts'], {
        'eatingOut',
        'feelingJudged',
        'weekends',
      });
    });

    testWidgets("the coach's voice", (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(CoachVoice.playful));
      expect(storedCodes()['voice'], 'playful');
      expect(stored(), answered.aboutMe.copyWith(voice: CoachVoice.playful));
    });

    testWidgets('the note, trimmed like the store keeps it', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(
        byKey('aboutMeNoteField'),
        '  Tennis on Tuesdays ',
      );
      await tester.pumpAndSettle();
      expect(storedCodes()['note'], 'Tennis on Tuesdays');
      expect(repository.record.completed, isTrue);
    });

    testWidgets('a first answer over a record with none', (tester) async {
      await pumpEditor(
        tester,
        record: const OnboardingRecord(step: OnboardingStep.voice),
      );
      await tap(tester, option(FoodTracking.otherHealthApp));
      expect(stored(), const AboutMe(tracking: FoodTracking.otherHealthApp));
      // Mid-flow stays mid-flow: the editor doesn't finish onboarding.
      expect(repository.record.completed, isFalse);
      expect(repository.record.step, OnboardingStep.voice);
    });
  });

  group('clearing an answer puts it back to skipped', () {
    testWidgets('a single answer: tap the chosen one again', (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(FoodTracking.calAi));
      await tap(tester, option(WeekendShape.busier));
      await tap(tester, option(CoachVoice.gentle));

      expect(stored().tracking, isNull);
      expect(stored().weekends, isNull);
      expect(stored().voice, isNull);
      for (final value in [
        ...FoodTracking.values,
        ...WeekendShape.values,
        ...CoachVoice.values,
      ]) {
        expect(rowSelected(tester, value), isFalse, reason: value.name);
      }
    });

    testWidgets('a multi-select: untick every one', (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(OnboardingActivity.tennis));
      await tap(tester, option(OnboardingActivity.walks));
      await tap(tester, option(HardPart.eatingOut));

      expect(stored().activities, isEmpty);
      expect(stored().hardParts, isEmpty);
    });

    testWidgets('the note: empty it, or leave only spaces', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(byKey('aboutMeNoteField'), '   ');
      await tester.pumpAndSettle();
      expect(stored().note, isNull);

      await tester.enterText(byKey('aboutMeNoteField'), 'x');
      await tester.pumpAndSettle();
      await tester.enterText(byKey('aboutMeNoteField'), '');
      await tester.pumpAndSettle();
      expect(stored().note, isNull);
    });

    testWidgets('every answer cleared is an empty About me', (tester) async {
      await pumpEditor(tester);
      await tap(tester, option(FoodTracking.calAi));
      await tap(tester, option(OnboardingActivity.tennis));
      await tap(tester, option(OnboardingActivity.walks));
      await tap(tester, option(WeekendShape.busier));
      await tap(tester, option(HardPart.eatingOut));
      await tap(tester, option(CoachVoice.gentle));
      await tester.enterText(byKey('aboutMeNoteField'), '');
      await tester.pumpAndSettle();

      expect(stored().isEmpty, isTrue);
      expect(repository.record.completed, isTrue);
    });
  });

  testWidgets('the paid badge sits on the voice and the note only', (
    tester,
  ) async {
    await pumpEditor(tester);
    Finder badgeIn(String section) =>
        find.descendant(of: byKey(section), matching: find.byType(PaidBadge));
    expect(badgeIn('aboutMeVoice'), findsOneWidget);
    expect(badgeIn('aboutMeNote'), findsOneWidget);
    for (final section in [
      'aboutMeTracking',
      'aboutMeWeek',
      'aboutMeHardParts',
    ]) {
      expect(badgeIn(section), findsNothing, reason: section);
    }
    expect(find.byType(PaidBadge), findsNWidgets(2));
  });

  group('a failed save', () {
    testWidgets('keeps the edit on screen and shows the quiet line', (
      tester,
    ) async {
      await pumpEditor(tester);
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await tap(tester, option(FoodTracking.justStarting));

      expect(rowSelected(tester, FoodTracking.justStarting), isTrue);
      expect(rowSelected(tester, FoodTracking.calAi), isFalse);
      expect(byKey('aboutMeSaveFailed'), findsOneWidget);
      // Its own line, not the flow's ("…later in Settings"): this is
      // Settings.
      expect(find.text(OnboardingCopy.aboutMeSaveFailed), findsOneWidget);
      expect(find.text(OnboardingCopy.saveFailed), findsNothing);
      expect(byKey('onboardingSaveFailed'), findsNothing);
      // Nothing was stored.
      expect(stored().tracking, FoodTracking.calAi);
    });

    testWidgets('the next edit saves it with the rest, and the line goes', (
      tester,
    ) async {
      await pumpEditor(tester);
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await tap(tester, option(FoodTracking.justStarting));
      await tap(tester, option(CoachVoice.direct));

      expect(byKey('aboutMeSaveFailed'), findsNothing);
      expect(stored().tracking, FoodTracking.justStarting);
      expect(stored().voice, CoachVoice.direct);
    });

    testWidgets('of the note keeps the text in the field', (tester) async {
      await pumpEditor(tester);
      repository.store.failNextWith = const OnboardingStorageFailure('disk');
      await tester.enterText(byKey('aboutMeNoteField'), 'Night shifts');
      await tester.pumpAndSettle();

      expect(find.text('Night shifts'), findsOneWidget);
      expect(byKey('aboutMeSaveFailed'), findsOneWidget);
      expect(stored().note, 'I work nights twice a month');
    });
  });

  group('the note limit', () {
    testWidgets('the field stops at aboutMeNoteMaxChars, and that much is '
        'stored', (tester) async {
      await pumpEditor(tester);
      await tester.enterText(
        byKey('aboutMeNoteField'),
        'a' * (aboutMeNoteMaxChars + 50),
      );
      await tester.pumpAndSettle();

      expect(noteOnScreen(tester), 'a' * aboutMeNoteMaxChars);
      expect(stored().note, 'a' * aboutMeNoteMaxChars);
      expect(byKey('aboutMeSaveFailed'), findsNothing);
    });

    testWidgets('counted in code points, as the store counts: an emoji '
        'with a skin tone is two, and what shows is what is saved', (
      tester,
    ) async {
      await pumpEditor(tester);
      await tester.enterText(
        byKey('aboutMeNoteField'),
        '👍🏽' * aboutMeNoteMaxChars,
      );
      await tester.pumpAndSettle();

      // Half of them fit: the field stops where the store does.
      const fits = aboutMeNoteMaxChars ~/ 2;
      expect(noteOnScreen(tester), '👍🏽' * fits);
      expect(stored().note, '👍🏽' * fits);
      expect(byKey('aboutMeSaveFailed'), findsNothing);
    });

    testWidgets('never splits an emoji from its skin tone at the limit', (
      tester,
    ) async {
      await pumpEditor(tester);
      // One code point short of the limit, then a two-code-point emoji:
      // it doesn't fit, so none of it goes in.
      final almost = 'a' * (aboutMeNoteMaxChars - 1);
      await tester.enterText(byKey('aboutMeNoteField'), '$almost👍🏽');
      await tester.pumpAndSettle();

      expect(noteOnScreen(tester), almost);
      expect(stored().note, almost);
    });
  });

  group('saving', () {
    testWidgets('tells the app after each change is saved', (tester) async {
      await pumpEditor(tester);
      expect(changed, 0);
      await tap(tester, option(FoodTracking.otherHealthApp));
      expect(changed, 1);
      await tap(tester, option(HardPart.travel));
      expect(changed, 2);
    });

    testWidgets("an edit's callback comes once it's stored", (tester) async {
      await pumpEditor(tester, arrange: (r) => r.holdWrites = Completer());
      await tap(tester, option(FoodTracking.justStarting));
      expect(changed, 0);
      expect(stored().tracking, FoodTracking.calAi);

      repository.holdWrites!.complete();
      await tester.pumpAndSettle();
      expect(stored().tracking, FoodTracking.justStarting);
      expect(changed, 1);
    });

    testWidgets('edits made during a save are written together, latest last', (
      tester,
    ) async {
      await pumpEditor(tester, arrange: (r) => r.holdWrites = Completer());
      await tap(tester, option(FoodTracking.justStarting));
      for (final text in ['N', 'Ni', 'Nig', 'Nigh', 'Night']) {
        await tester.enterText(byKey('aboutMeNoteField'), text);
        await tester.pump();
      }
      await tap(tester, option(CoachVoice.direct));

      repository.holdWrites!.complete();
      await tester.pumpAndSettle();
      // One write in flight, then one with everything since.
      expect(repository.calls.where((c) => c == 'saveAboutMe'), hasLength(2));
      expect(
        stored(),
        answered.aboutMe.copyWith(
          tracking: FoodTracking.justStarting,
          voice: CoachVoice.direct,
          note: 'Night',
        ),
      );
      expect(changed, 7);
    });

    testWidgets('leaving right after an edit still saves it, and still tells '
        'the app', (tester) async {
      await pumpEditor(tester, arrange: (r) => r.holdWrites = Completer());
      await tap(tester, option(FoodTracking.otherHealthApp));
      await tester.pumpWidget(const SizedBox.shrink());

      repository.holdWrites!.complete();
      await tester.pumpAndSettle();
      expect(stored().tracking, FoodTracking.otherHealthApp);
      expect(changed, 1);
    });
  });

  group('reading', () {
    testWidgets('a failed read offers to try again', (tester) async {
      await pumpEditor(
        tester,
        arrange: (r) =>
            r.store.failNextWith = const OnboardingStorageFailure('disk'),
      );
      expect(byKey('aboutMeReadFailed'), findsOneWidget);
      expect(find.text(OnboardingCopy.readFailed), findsOneWidget);

      await tap(tester, byKey('aboutMeTryAgain'));
      expect(byKey('aboutMeReadFailed'), findsNothing);
      expect(rowSelected(tester, FoodTracking.calAi), isTrue);
    });

    testWidgets('an unreadable record opens with nothing answered, and an '
        'edit replaces it, done', (tester) async {
      await pumpEditor(
        tester,
        record: OnboardingRecord.initial,
        arrange: (r) => r.store.makeUnreadable(),
      );
      for (final tracking in FoodTracking.values) {
        expect(rowSelected(tester, tracking), isFalse);
      }
      await tap(tester, option(FoodTracking.calAi));
      expect(
        repository.record,
        const OnboardingRecord(
          completed: true,
          aboutMe: AboutMe(tracking: FoodTracking.calAi),
        ),
      );
    });
  });

  testWidgets('back is the app’s', (tester) async {
    await pumpEditor(tester);
    await tap(tester, byKey('aboutMeBack'));
    expect(backs, 1);
  });

  testWidgets('the Settings row is called "About me" and opens the editor', (
    tester,
  ) async {
    var opened = 0;
    await tester.pumpWidget(
      ShadcnApp(
        theme: steadyTheme,
        home: AboutMeSettingsCard(onOpen: () => opened++),
      ),
    );
    expect(find.text('About me'), findsOneWidget);
    expect(find.bySemanticsLabel('About me'), findsOneWidget);
    await tester.tap(byKey('aboutMeSettingsRow'));
    expect(opened, 1);
  });
}
