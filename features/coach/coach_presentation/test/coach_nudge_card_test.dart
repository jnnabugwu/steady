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

/// The Today nudge (#81): check-in data decides whether it exists; the
/// model only decides between "Talk now" and an explanation.
void main() {
  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late FakeCheckIns checkIns;
  late int talks;
  // Friday, Oct 23 2026, 8pm. The week is Oct 16 → 22.
  var now = DateTime(2026, 10, 23, 20);

  setUp(() {
    model = FakeCoachModel();
    repository = FakeCoachRepository();
    checkIns = FakeCheckIns({
      for (var d = 16; d <= 20; d++)
        DateTime(2026, 10, d): CheckInStatus.partial,
    });
    talks = 0;
    now = DateTime(2026, 10, 23, 20);
  });

  Future<void> pump(WidgetTester tester, {bool iPhone = true}) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: iPhone
            ? coachTestOverrides(
                model: model,
                repository: repository,
                checkIns: checkIns,
                now: () => now,
              )
            // The Mac: no coach bound at all. Reading the model would
            // throw, so the card must never read it.
            : const [],
        child: ShadcnApp(
          theme: steadyTheme,
          home: Center(child: CoachNudgeCard(onTalkNow: () => talks++)),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final card = find.byKey(const Key('coachNudgeCard'));

  testWidgets('Friday, a week with enough check-ins, model available: '
      'Talk now / Not tonight', (tester) async {
    await pump(tester);
    expect(card, findsOneWidget);
    expect(
      find.text(
        'Your weekly check-in for Oct 16 – 22 is ready: about 5 minutes '
        'on logging, steps, and one small thing to try.',
      ),
      findsOneWidget,
    );
    expect(
      tester.getSize(find.byKey(const Key('coachNudgeTalkNow'))).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.byKey(const Key('coachNudgeTalkNow')));
    expect(talks, 1);
    // The nudge never started a model session.
    expect(model.instructions, isEmpty);
  });

  testWidgets('Not tonight hides it for the rest of the day', (tester) async {
    await pump(tester);
    await tester.tap(find.byKey(const Key('coachNudgeNotTonight')));
    await tester.pumpAndSettle();
    expect(card, findsNothing);
  });

  testWidgets('model unavailable: a short explanation instead of Talk now', (
    tester,
  ) async {
    model.availability = const Err(CoachAppleIntelligenceNotEnabledFailure());
    await pump(tester);
    expect(card, findsOneWidget);
    expect(find.byKey(const Key('coachNudgeTalkNow')), findsNothing);
    expect(find.text('The coach needs Apple Intelligence'), findsOneWidget);
    expect(find.byKey(const Key('coachNudgeNotTonight')), findsOneWidget);
  });

  testWidgets('fewer than 4 of 7 days with a check-in: no nudge', (
    tester,
  ) async {
    checkIns.statuses.removeWhere((day, _) => day.day > 18);
    await pump(tester);
    expect(card, findsNothing);
  });

  testWidgets('Monday to Thursday: no nudge', (tester) async {
    now = DateTime(2026, 10, 26, 20); // Monday
    await pump(tester);
    expect(card, findsNothing);
  });

  testWidgets("once this week's weekly session was started: no nudge", (
    tester,
  ) async {
    repository.sessions.add(
      CoachSession(
        id: 'w',
        kind: CoachSessionKind.weekly,
        startedAt: DateTime(2026, 10, 23, 19),
      ),
    );
    await pump(tester);
    expect(card, findsNothing);
  });

  testWidgets("a chat doesn't count as the weekly session", (tester) async {
    repository.sessions.add(
      CoachSession(
        id: 'c',
        kind: CoachSessionKind.chat,
        startedAt: DateTime(2026, 10, 23, 19),
      ),
    );
    await pump(tester);
    expect(card, findsOneWidget);
  });

  testWidgets('the Mac: nothing, and the model is never read', (tester) async {
    await pump(tester, iPhone: false);
    expect(card, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('four check-ins but three days unreadable: no nudge', (
    tester,
  ) async {
    checkIns =
        FakeCheckIns({
            for (var d = 16; d <= 19; d++)
              DateTime(2026, 10, d): CheckInStatus.partial,
          })
          ..failingDays.addAll([
            for (var d = 20; d <= 22; d++) DateTime(2026, 10, d),
          ]);
    await pump(tester);
    expect(card, findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a check-in store that fails: no nudge, no error on Today', (
    tester,
  ) async {
    checkIns.failure = const UnknownFailure('down');
    await pump(tester);
    expect(card, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
