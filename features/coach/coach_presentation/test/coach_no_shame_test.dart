import 'package:checkin_domain/checkin_domain.dart';
import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/coach_container.dart';
import 'helpers/fake_coach_model.dart';
import 'helpers/fake_coach_repository.dart';
import 'helpers/fake_domains.dart';

/// #82's UI review, as a test: every coach screen state, checked for the
/// no-shame rules. No streaks, scores, grades or praise/blame words in the
/// app's own copy, and no red, yellow or green: only the teal ladder and
/// neutrals.
///
/// (The model's replies aren't the app's copy; the instructions guard
/// those, in `coach_instructions_test.dart`.)
void main() {
  final forbidden = RegExp(
    r'\b(streaks?|score[sd]?|grades?|graded|great job|well done|proud|'
    'failed to log|failure|missed|good day|bad day|cheat|willpower|'
    r'on track|off track|behind|perfect)\b',
    caseSensitive: false,
  );

  /// Saturated red, yellow or green. The coach palette is teal (≈172°)
  /// and near-neutral greys.
  bool trafficLight(Color color) {
    final hsv = HSVColor.fromColor(color);
    if (hsv.saturation < 0.35 || hsv.value < 0.25 || color.a < 0.05) {
      return false;
    }
    final hue = hsv.hue;
    return hue < 20 ||
        hue > 340 ||
        (hue > 40 && hue < 70) ||
        (hue > 90 && hue < 150);
  }

  void review(WidgetTester tester, String screen) {
    for (final text in tester.widgetList<Text>(find.byType(Text))) {
      final data = text.data ?? text.textSpan?.toPlainText() ?? '';
      expect(forbidden.hasMatch(data), isFalse, reason: '$screen: "$data"');
      if (text.style?.color case final color?) {
        expect(trafficLight(color), isFalse, reason: '$screen: "$data"');
      }
    }
    for (final box in tester.widgetList<DecoratedBox>(
      find.byType(DecoratedBox),
    )) {
      if (box.decoration case BoxDecoration(:final color?)) {
        expect(trafficLight(color), isFalse, reason: screen);
      }
    }
  }

  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late FakeCheckIns checkIns;
  // Friday: the nudge shows, the week is Oct 16 → 22.
  final friday = DateTime(2026, 10, 23, 20);

  setUp(() {
    model = FakeCoachModel();
    repository = FakeCoachRepository([
      CoachSession(
        id: 'w',
        kind: CoachSessionKind.weekly,
        startedAt: DateTime(2026, 10, 9, 20),
        summary: 'They looked at weekends and picked an evening snack plan.',
        messages: [
          CoachMessage(
            role: CoachMessageRole.user,
            text: 'Weekends were hard.',
            at: DateTime(2026, 10, 9, 20),
          ),
        ],
      ),
    ]);
    checkIns = FakeCheckIns({
      for (var d = 16; d <= 21; d++)
        DateTime(2026, 10, d): CheckInStatus.values[d % 3],
    });
  });

  Future<void> pump(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: coachTestOverrides(
          model: model,
          repository: repository,
          checkIns: checkIns,
          cravings: FakeCravings([craving('c', DateTime(2026, 10, 18, 21))]),
          now: () => friday,
        ),
        child: ShadcnApp(theme: steadyTheme, home: child),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('the Coach tab, available and not', (tester) async {
    await pump(
      tester,
      CoachHomeModule(
        onChatRequested: () {},
        onWeeklyRequested: () {},
        onSessionSelected: (_) {},
      ),
    );
    review(tester, 'Coach tab');
    model.availability = const Err(CoachDeviceNotEligibleFailure());
    await pump(
      tester,
      CoachHomeModule(
        onChatRequested: () {},
        onWeeklyRequested: () {},
        onSessionSelected: (_) {},
      ),
    );
    review(tester, 'Coach tab, unavailable');
  });

  testWidgets('a thin week on the Coach tab', (tester) async {
    checkIns.statuses.clear();
    await pump(
      tester,
      CoachHomeModule(
        onChatRequested: () {},
        onWeeklyRequested: () {},
        onSessionSelected: (_) {},
      ),
    );
    expect(find.byKey(const Key('coachWeeklyText')), findsOneWidget);
    review(tester, 'Coach tab, thin week');
  });

  testWidgets('the nudge, available and not', (tester) async {
    await pump(tester, Center(child: CoachNudgeCard(onTalkNow: () {})));
    expect(find.byKey(const Key('coachNudgeCard')), findsOneWidget);
    review(tester, 'nudge');
    model.availability = const Err(CoachModelNotReadyFailure());
    await pump(tester, Center(child: CoachNudgeCard(onTalkNow: () {})));
    review(tester, 'nudge, unavailable');
  });

  testWidgets('a weekly session: intro, topics, help line, summary', (
    tester,
  ) async {
    await pump(
      tester,
      CoachSessionModule(kind: CoachSessionKind.weekly, onClosed: () {}),
    );
    review(tester, 'weekly intro');

    await tester.tap(find.byKey(const Key('coachWeeklyBegin')));
    await tester.pumpAndSettle();
    model.failNext = const CoachInferenceFailure(
      'g',
      reason: CoachInferenceFailureReason.guardrailViolation,
    );
    await tester.enterText(find.byKey(const Key('coachMessageField')), 'Hi');
    await tester.tap(find.byKey(const Key('coachSend')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coachHelpCard')), findsOneWidget);
    review(tester, 'weekly, guardrail');

    await tester.tap(find.byKey(const Key('coachSessionEnd')));
    await tester.pumpAndSettle();
    review(tester, 'weekly, ended');
  });

  testWidgets('a thin week in the session', (tester) async {
    checkIns.statuses.clear();
    await pump(
      tester,
      CoachSessionModule(kind: CoachSessionKind.weekly, onClosed: () {}),
    );
    expect(find.byKey(const Key('coachNotEnoughCheckIns')), findsOneWidget);
    review(tester, 'weekly, thin week');
  });

  testWidgets('a past session', (tester) async {
    await pump(tester, CoachTranscriptModule(sessionId: 'w', onBack: () {}));
    review(tester, 'transcript');
  });
}
