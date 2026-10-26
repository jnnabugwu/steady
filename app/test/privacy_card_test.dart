import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/main.dart';
import 'package:steady/privacy_card.dart';
import 'package:steady/providers.dart';

/// Settings' "Privacy" card: the in-app privacy policy link App Store
/// guideline 5.1.1(i) asks for, in the real app on the real override list.
void main() {
  final card = find.byKey(const Key('privacyCard'));
  final button = find.byKey(const Key('privacyPolicyButton'));
  final fallback = find.byKey(const Key('privacyPolicyFallback'));

  Future<List<Uri>> pumpSettings(
    WidgetTester tester, {
    bool opens = true,
  }) async {
    final opened = <Uri>[];
    tester.platformDispatcher.defaultRouteNameTestValue = '/settings';
    addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    final container = ProviderContainer(
      overrides: [
        ...appProviderOverrides,
        appLinkOpenerProvider.overrideWithValue((uri) async {
          opened.add(uri);
          return opens;
        }),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(button, 200);
    return opened;
  }

  testWidgets('Settings links to the privacy policy, the same address as '
      'the store listing', (tester) async {
    final opened = await pumpSettings(tester);
    expect(card, findsOneWidget);
    expect(tester.getSize(button).height, greaterThanOrEqualTo(44));

    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(opened, [
      Uri.parse(
        'https://github.com/jnnabugwu/steady/blob/main/docs/PRIVACY.md',
      ),
    ]);
    expect(fallback, findsNothing);
  });

  testWidgets("when the link can't open, the address is shown instead", (
    tester,
  ) async {
    await pumpSettings(tester, opens: false);
    await tester.tap(button);
    await tester.pumpAndSettle();
    expect(fallback, findsOneWidget);
    expect(find.textContaining(privacyPolicyUrl.toString()), findsOneWidget);
  });
}
