import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_coach_consent_repository.dart';
import 'helpers/fake_coach_repository.dart';

void main() {
  late FakeCoachRepository repository;
  late FakeCoachConsentRepository consent;
  late int consentAsks;
  // What the app's consent screen does when the switch asks: by default
  // nothing (the person tapped "Not now").
  late void Function(WidgetRef ref) onAsk;

  setUp(() {
    repository = FakeCoachRepository([
      CoachSession(
        id: 'a',
        kind: CoachSessionKind.chat,
        startedAt: DateTime(2026, 10, 22, 19),
        summary: 'A short chat.',
      ),
    ]);
    consent = FakeCoachConsentRepository(agreed: CoachConsent.currentVersion);
    consentAsks = 0;
    onAsk = (_) {};
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
          coachConsentRepositoryProvider.overrideWithValue(consent),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: Scaffold(
            child: SingleChildScrollView(
              child: Consumer(
                builder: (context, ref, _) => CoachSettingsCard(
                  onConsentRequested: () {
                    consentAsks++;
                    onAsk(ref);
                  },
                ),
              ),
            ),
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

  bool switchOn(WidgetTester tester) =>
      tester.widget<Switch>(find.byKey(const Key('coachConsentSwitch'))).value;

  ProviderContainer containerOf(WidgetTester tester) =>
      ProviderScope.containerOf(tester.element(find.byType(CoachSettingsCard)));

  group('the coach switch', () {
    testWidgets('is on with consent for the current version, with the line '
        'on what it sends', (tester) async {
      await pump(tester);
      expect(switchOn(tester), isTrue);
      expect(find.text(CoachConsent.settingsLine), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const Key('coachConsentSwitch'))).height,
        greaterThanOrEqualTo(44),
      );
    });

    testWidgets('is off without it, and for an earlier version', (
      tester,
    ) async {
      consent.agreed = CoachConsent.currentVersion - 1;
      await pump(tester);
      expect(switchOn(tester), isFalse);
    });

    testWidgets('off: withdraws at once, keeps the history', (tester) async {
      await pump(tester);
      await tester.tap(find.byKey(const Key('coachConsentSwitch')));
      await tester.pumpAndSettle();
      expect(switchOn(tester), isFalse);
      expect(consent.agreed, isNull);
      expect(consent.calls, ['read', 'withdraw']);
      expect(consentAsks, 0);
      expect(repository.sessions, hasLength(1));
      expect(find.byKey(const Key('coachConsentError')), findsNothing);
    });

    testWidgets('while the withdrawal is written it already reads as off, '
        'and the switch waits', (tester) async {
      await pump(tester);
      consent.holdWrites = Completer<void>();
      await tester.tap(find.byKey(const Key('coachConsentSwitch')));
      await tester.pump();
      expect(switchOn(tester), isFalse);
      expect(
        isCoachConsentGiven(
          containerOf(tester).read(coachConsentGivenProvider),
        ),
        isFalse,
      );
      final pending = tester.widget<Switch>(
        find.byKey(const Key('coachConsentSwitch')),
      );
      expect(pending.onChanged, isNull);
      consent.holdWrites!.complete();
      await tester.pumpAndSettle();
      expect(consent.agreed, isNull);
    });

    testWidgets('on: asks through the consent screen and changes nothing '
        'by itself ("Not now")', (tester) async {
      consent.agreed = null;
      await pump(tester);
      await tester.tap(find.byKey(const Key('coachConsentSwitch')));
      await tester.pumpAndSettle();
      expect(consentAsks, 1);
      expect(switchOn(tester), isFalse);
      expect(consent.calls, ['read']);
    });

    testWidgets('round trip: on through the consent screen, then off', (
      tester,
    ) async {
      consent.agreed = null;
      onAsk = (ref) => unawaited(
        ref.read(coachConsentGivenProvider.notifier).giveCoachConsent(),
      );
      await pump(tester);
      expect(switchOn(tester), isFalse);

      await tester.tap(find.byKey(const Key('coachConsentSwitch')));
      await tester.pumpAndSettle();
      expect(switchOn(tester), isTrue);
      expect(consent.agreed, CoachConsent.currentVersion);

      await tester.tap(find.byKey(const Key('coachConsentSwitch')));
      await tester.pumpAndSettle();
      expect(switchOn(tester), isFalse);
      expect(consent.agreed, isNull);
      expect(consent.calls, [
        'read',
        'give ${CoachConsent.currentVersion}',
        'withdraw',
      ]);
    });

    testWidgets("a withdrawal that can't be saved says so, and the coach "
        'stays off here', (tester) async {
      await pump(tester);
      consent.failNext = const CoachConsentStorageFailure('disk');
      await tester.tap(find.byKey(const Key('coachConsentSwitch')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('coachConsentError')), findsOneWidget);
      expect(switchOn(tester), isFalse);
      expect(
        isCoachConsentGiven(
          containerOf(tester).read(coachConsentGivenProvider),
        ),
        isFalse,
      );
      expect(consent.agreed, CoachConsent.currentVersion);

      // "Save again" retries the withdrawal, and the error goes.
      await tester.tap(find.byKey(const Key('coachConsentRetry')));
      await tester.pumpAndSettle();
      expect(consent.agreed, isNull);
      expect(consent.calls, ['read', 'withdraw', 'withdraw']);
      expect(find.byKey(const Key('coachConsentError')), findsNothing);
      expect(switchOn(tester), isFalse);
    });
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

  testWidgets('the delete control is teal, never red (coach colour rule)', (
    tester,
  ) async {
    await pump(tester);
    final button = find.byKey(const Key('coachDeleteHistoryButton'));
    final icon = tester.widget<Icon>(
      find.descendant(of: button, matching: find.byType(Icon)),
    );
    expect(icon.color, SteadyColors.accentTeal);
    final label = tester.widget<Text>(
      find.descendant(of: button, matching: find.text('Delete coach history')),
    );
    expect(label.style?.color, SteadyColors.accentTeal);

    await tapDelete(tester);
    // The dialog's Delete is a PrimaryButton, whose fill is the theme's
    // primary: the teal accent.
    final confirm = find.byKey(const Key('coachDeleteConfirm'));
    expect(tester.widget(confirm), isA<PrimaryButton>());
    expect(steadyTheme.colorScheme.primary, SteadyColors.accentTeal);
    expect(find.byType(DestructiveButton), findsNothing);
  });
}
