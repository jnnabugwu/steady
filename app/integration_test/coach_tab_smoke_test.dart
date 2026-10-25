// A device check, not a unit test: run on an iPhone or simulator with
// `flutter test integration_test/coach_tab_smoke_test.dart -d <device>`.
// ignore_for_file: avoid_print

import 'package:coach_presentation/coach_presentation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';

/// The Coach tab against the real `steady/coach` channel (#80): opens the
/// tab and prints what it shows. Where the model can't run (every
/// simulator so far), that's the typed reason's message; where it can, the
/// "Start a chat" card. `holdFor` keeps the screen up for a screenshot.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const holdFor = Duration(seconds: 15);

  testWidgets('the Coach tab shows availability from the real model', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Coach'));
    // The availability check is a real platform call.
    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 250));
    }
    expect(find.byType(CoachHomeModule), findsOneWidget);

    final unavailable = find.byKey(const Key('coachUnavailableCard'));
    if (unavailable.evaluate().isNotEmpty) {
      final texts = tester
          .widgetList<Text>(
            find.descendant(of: unavailable, matching: find.byType(Text)),
          )
          .map((t) => t.data);
      print('COACH UNAVAILABLE: ${texts.join(' | ')}');
    } else {
      expect(find.byKey(const Key('coachChatCard')), findsOneWidget);
      print('COACH AVAILABLE: the Start a chat card is showing');
    }
    print('HOLDING FOR SCREENSHOT');
    await tester.pump(holdFor);
  });
}
