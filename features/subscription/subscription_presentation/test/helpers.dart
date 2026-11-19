import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:subscription_domain/testing/in_memory_subscription_repository.dart';
import 'package:subscription_presentation/subscription_presentation.dart';
import 'package:ui_kit/ui_kit.dart';

/// "Now" in every test here.
final testNow = DateTime(2026, 11, 20, 9);

/// Pumps [child] at iPhone size over [store], with the subscription
/// supported unless [supported] is false, at [textScale] (Dynamic Type).
Future<void> pumpWithStore(
  WidgetTester tester,
  InMemorySubscriptionRepository store,
  Widget child, {
  bool supported = true,
  List<Override> overrides = const [],
  double textScale = 1,
}) async {
  tester.view.physicalSize = const Size(390, 844) * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        subscriptionRepositoryProvider.overrideWithValue(store),
        subscriptionSupportAvailableProvider.overrideWithValue(supported),
        ...overrides,
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: Builder(
          builder: (context) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: TextScaler.linear(textScale)),
            child: child,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

/// Scrolls to and taps [key], then settles.
Future<void> tapKey(WidgetTester tester, String key) async {
  await tester.ensureVisible(find.byKey(Key(key)));
  await tester.tap(find.byKey(Key(key)));
  await tester.pumpAndSettle();
}

/// Every Text on screen, joined.
String allText(WidgetTester tester) => tester
    .widgetList<Text>(find.byType(Text))
    .map((t) => t.data ?? t.textSpan?.toPlainText() ?? '')
    .join('\n');
