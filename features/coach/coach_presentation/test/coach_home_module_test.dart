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

void main() {
  late FakeCoachModel model;
  late FakeCoachRepository repository;
  late int chats;
  late List<String> opened;

  final chat = CoachSession(
    id: 'c1',
    kind: CoachSessionKind.chat,
    startedAt: DateTime(2026, 10, 24, 20),
    summary: 'They went over the weekend.',
    messages: [
      CoachMessage(
        role: CoachMessageRole.user,
        text: 'How was Saturday?',
        at: DateTime(2026, 10, 24, 20),
      ),
      CoachMessage(
        role: CoachMessageRole.coach,
        text: 'You logged it fully.',
        at: DateTime(2026, 10, 24, 20, 1),
      ),
    ],
  );
  final unsummarised = CoachSession(
    id: 'c2',
    kind: CoachSessionKind.chat,
    startedAt: DateTime(2026, 10, 25, 9),
    messages: [
      CoachMessage(
        role: CoachMessageRole.user,
        text: 'Quick question about steps.',
        at: DateTime(2026, 10, 25, 9),
      ),
    ],
  );

  setUp(() {
    model = FakeCoachModel();
    repository = FakeCoachRepository();
    chats = 0;
    opened = [];
  });

  Future<void> pumpHome(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: coachTestOverrides(model: model, repository: repository),
        child: ShadcnApp(
          theme: steadyTheme,
          home: CoachHomeModule(
            onChatRequested: () => chats++,
            onSessionSelected: opened.add,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('available: offers a chat, with the medical note', (
    tester,
  ) async {
    await pumpHome(tester);
    expect(find.byKey(const Key('coachChatCard')), findsOneWidget);
    expect(find.text(CoachCopy.notMedicalAdvice), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('coachStartChat'))).height,
      greaterThanOrEqualTo(44),
    );
    await tester.tap(find.byKey(const Key('coachStartChat')));
    expect(chats, 1);
  });

  testWidgets('unavailable: says why instead, and can check again', (
    tester,
  ) async {
    model.availability = const Err(CoachModelNotReadyFailure());
    await pumpHome(tester);
    expect(find.byKey(const Key('coachChatCard')), findsNothing);
    expect(find.text('The coach is still getting ready'), findsOneWidget);
    expect(model.availabilityChecks, 1);

    model.availability = const Ok(CoachModelInfo(contextSize: 4096));
    await tester.tap(find.byKey(const Key('coachCheckAgain')));
    await tester.pumpAndSettle();
    expect(model.availabilityChecks, 2);
    expect(find.byKey(const Key('coachChatCard')), findsOneWidget);
  });

  testWidgets('a device that can never run it offers no "Check again"', (
    tester,
  ) async {
    model.availability = const Err(CoachDeviceNotEligibleFailure());
    await pumpHome(tester);
    expect(find.byKey(const Key('coachUnavailableCard')), findsOneWidget);
    expect(find.byKey(const Key('coachCheckAgain')), findsNothing);
    // History still shows on an iPhone that can't run the coach.
    expect(find.byKey(const Key('coachHistoryEmpty')), findsOneWidget);
  });

  testWidgets('no sessions yet says where they will be', (tester) async {
    await pumpHome(tester);
    expect(find.byKey(const Key('coachHistoryEmpty')), findsOneWidget);
  });

  testWidgets('lists past sessions newest first, with the summary or the '
      'first message, and opens one', (tester) async {
    repository.sessions.addAll([chat, unsummarised]);
    await pumpHome(tester);

    final newer = tester.getTopLeft(find.byKey(const Key('coachSession_c2')));
    final older = tester.getTopLeft(find.byKey(const Key('coachSession_c1')));
    expect(newer.dy, lessThan(older.dy));
    expect(find.text('Chat · Sat, Oct 24'), findsOneWidget);
    expect(find.text('They went over the weekend.'), findsOneWidget);
    expect(find.text('Quick question about steps.'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const Key('coachSession_c1'))).height,
      greaterThanOrEqualTo(44),
    );

    await tester.ensureVisible(find.byKey(const Key('coachSession_c1')));
    await tester.tap(find.byKey(const Key('coachSession_c1')));
    expect(opened, ['c1']);
  });

  testWidgets('a history that cannot be read says so', (tester) async {
    repository.onList = () async =>
        const Err(CoachHistoryUnreadableFailure('corrupt'));
    await pumpHome(tester);
    expect(find.byKey(const Key('coachHistoryError')), findsOneWidget);
  });

  group('transcript', () {
    Future<void> pumpTranscript(WidgetTester tester, String id) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: coachTestOverrides(model: model, repository: repository),
          child: ShadcnApp(
            theme: steadyTheme,
            home: CoachTranscriptModule(sessionId: id, onBack: () {}),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('shows the summary, then the conversation, read-only', (
      tester,
    ) async {
      repository.sessions.add(chat);
      await pumpTranscript(tester, 'c1');
      expect(find.byKey(const Key('coachTranscriptSummary')), findsOneWidget);
      expect(find.text('How was Saturday?'), findsOneWidget);
      expect(find.text('You logged it fully.'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.text('Sat, Oct 24'), findsOneWidget);
    });

    testWidgets('a session no longer stored says so', (tester) async {
      await pumpTranscript(tester, 'gone');
      expect(find.byKey(const Key('coachTranscriptMissing')), findsOneWidget);
    });

    testWidgets("the coach's bubble hangs left with its small corner bottom "
        "left; the person's mirrors it", (tester) async {
      repository.sessions.add(chat);
      await pumpTranscript(tester, 'c1');
      BorderRadiusGeometry? radius(String key) {
        final box = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byKey(Key(key)),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        return (box.decoration as BoxDecoration).borderRadius;
      }

      expect(radius('coachTranscriptMessage_1'), SteadyRadii.chatBubble);
      expect(
        radius('coachTranscriptMessage_0'),
        SteadyRadii.chatBubbleMirrored,
      );
      expect(SteadyRadii.chatBubble.bottomLeft, const Radius.circular(6));
      expect(
        SteadyRadii.chatBubbleMirrored.bottomRight,
        const Radius.circular(6),
      );
      final coachLeft = tester.getTopLeft(find.text('You logged it fully.')).dx;
      final userLeft = tester.getTopLeft(find.text('How was Saturday?')).dx;
      expect(coachLeft, lessThan(userLeft));
    });
  });
}
