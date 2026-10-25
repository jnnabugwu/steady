import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_coach_repository.dart';

void main() {
  late FakeCoachRepository repository;

  setUp(() {
    repository = FakeCoachRepository([
      CoachSession(
        id: 'a',
        kind: CoachSessionKind.chat,
        startedAt: DateTime(2026, 10, 22, 19),
        summary: 'A short chat.',
      ),
    ]);
  });

  Future<void> pump(WidgetTester tester, {bool available = true}) async {
    tester.view.physicalSize = const Size(390, 1200) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          coachRepositoryProvider.overrideWithValue(repository),
          coachSupportAvailableProvider.overrideWithValue(available),
        ],
        child: const ShadcnApp(
          theme: steadyTheme,
          home: Scaffold(
            child: SingleChildScrollView(child: CoachSettingsCard()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tapDelete(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('coachDeleteHistoryButton')));
    await tester.pumpAndSettle();
  }

  testWidgets('renders nothing where the coach is off (macOS)', (tester) async {
    await pump(tester, available: false);
    expect(find.byKey(const Key('coachSettingsCard')), findsNothing);
    expect(find.text('Delete coach history'), findsNothing);
  });

  testWidgets('says where coach conversations are kept', (tester) async {
    await pump(tester);
    expect(find.text('Coach'), findsOneWidget);
    expect(
      find.text(
        "Coach conversations stay on this iPhone. Steady doesn't sync "
        "them. If your iPhone backs up to iCloud, they're included in "
        'that backup, like other app data.',
      ),
      findsOneWidget,
    );
    expect(find.byKey(const Key('coachDeleteStatus')), findsNothing);
  });

  testWidgets('delete asks first; cancelling keeps everything', (tester) async {
    await pump(tester);
    await tapDelete(tester);

    expect(find.text('Delete coach history?'), findsOneWidget);
    expect(
      find.text(
        'This removes every coach conversation and summary on this '
        'iPhone. It can’t be undone.',
      ),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const Key('coachDeleteCancel')));
    await tester.pumpAndSettle();

    expect(find.text('Delete coach history?'), findsNothing);
    expect(repository.deleteAllCalls, 0);
    expect(repository.sessions, hasLength(1));
    expect(find.byKey(const Key('coachDeleteStatus')), findsNothing);
  });

  testWidgets('confirming deletes the history and says so', (tester) async {
    await pump(tester);
    await tapDelete(tester);
    await tester.tap(find.byKey(const Key('coachDeleteConfirm')));
    await tester.pumpAndSettle();

    expect(repository.deleteAllCalls, 1);
    expect(repository.sessions, isEmpty);
    expect(find.text('Coach history deleted.'), findsOneWidget);
  });

  testWidgets('a failed delete says so, and can be retried', (tester) async {
    repository.onDeleteAll = () async =>
        const Err(CoachHistoryStorageFailure('locked'));
    await pump(tester);
    await tapDelete(tester);
    await tester.tap(find.byKey(const Key('coachDeleteConfirm')));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't delete coach history. Try again."),
      findsOneWidget,
    );
    expect(repository.sessions, hasLength(1));

    repository.onDeleteAll = null;
    await tapDelete(tester);
    await tester.tap(find.byKey(const Key('coachDeleteConfirm')));
    await tester.pumpAndSettle();
    expect(find.text('Coach history deleted.'), findsOneWidget);
    expect(repository.sessions, isEmpty);
  });

  testWidgets('the delete control is labelled and at least 44pt tall', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await pump(tester);
    expect(
      tester.getSize(find.byKey(const Key('coachDeleteHistoryButton'))).height,
      greaterThanOrEqualTo(44),
    );
    expect(find.bySemanticsLabel('Delete coach history'), findsOneWidget);
    semantics.dispose();
  });
}
