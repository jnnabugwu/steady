import 'dart:async';

import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_coach_consent_repository.dart';

void main() {
  late FakeCoachConsentRepository consent;
  late int given;
  late int notNow;

  setUp(() {
    consent = FakeCoachConsentRepository();
    given = 0;
    notNow = 0;
  });

  Future<void> pump(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [coachConsentRepositoryProvider.overrideWithValue(consent)],
        child: ShadcnApp(
          theme: steadyTheme,
          home: CoachConsentModule(
            onConsentGiven: () => given++,
            onNotNow: () => notNow++,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> tap(WidgetTester tester, String key) async {
    await tester.ensureVisible(find.byKey(Key(key)));
    await tester.tap(find.byKey(Key(key)));
    await tester.pump();
  }

  bool enabled(WidgetTester tester, String key) {
    final button = tester.widget(find.byKey(Key(key)));
    return switch (button) {
      PrimaryButton(:final onPressed) => onPressed != null,
      OutlineButton(:final onPressed) => onPressed != null,
      IconButton(:final onPressed) => onPressed != null,
      _ => fail('not a button: $button'),
    };
  }

  testWidgets("shows the whole consent text: who, what's sent, and why", (
    tester,
  ) async {
    await pump(tester);
    for (final line in [
      CoachConsent.title,
      CoachConsent.intro,
      ...CoachConsent.items,
      CoachConsent.use,
      CoachConsent.closing,
      CoachConsent.allow,
      CoachConsent.notNow,
    ]) {
      expect(find.text(line), findsOneWidget, reason: line);
    }
    for (final key in ['coachConsentAllow', 'coachConsentNotNow']) {
      expect(
        tester.getSize(find.byKey(Key(key))).height,
        greaterThanOrEqualTo(44),
      );
    }
  });

  testWidgets('"Allow and continue" saves the current version, then calls '
      'back', (tester) async {
    await pump(tester);
    await tap(tester, 'coachConsentAllow');
    await tester.pumpAndSettle();
    expect(consent.agreed, CoachConsent.currentVersion);
    expect(given, 1);
    expect(notNow, 0);
  });

  testWidgets('"Not now" and Close change nothing', (tester) async {
    await pump(tester);
    await tap(tester, 'coachConsentNotNow');
    await tap(tester, 'coachConsentClose');
    expect(notNow, 2);
    expect(given, 0);
    expect(consent.calls, ['read']);
  });

  testWidgets('while the answer is saved, every button waits, Close '
      'included', (tester) async {
    await pump(tester);
    consent.holdWrites = Completer<void>();
    await tap(tester, 'coachConsentAllow');
    for (final key in [
      'coachConsentAllow',
      'coachConsentNotNow',
      'coachConsentClose',
    ]) {
      expect(enabled(tester, key), isFalse, reason: key);
    }
    consent.holdWrites!.complete();
    await tester.pumpAndSettle();
    expect(given, 1);
    expect(notNow, 0);
  });

  testWidgets("a save that doesn't work says so, and doesn't call back", (
    tester,
  ) async {
    await pump(tester);
    consent.failNext = const CoachConsentStorageFailure('disk');
    await tap(tester, 'coachConsentAllow');
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('coachConsentError')), findsOneWidget);
    expect(given, 0);
    expect(enabled(tester, 'coachConsentAllow'), isTrue);

    await tap(tester, 'coachConsentAllow');
    await tester.pumpAndSettle();
    expect(given, 1);
    expect(consent.agreed, CoachConsent.currentVersion);
  });
}
