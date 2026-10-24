import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';
import 'package:steady/today_screen.dart';

void main() {
  testWidgets('home is the Today screen', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(TodayScreen), findsOneWidget);
  });
}
