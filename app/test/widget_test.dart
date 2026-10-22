import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:steady/main.dart';
import 'package:steady/providers.dart';

void main() {
  testWidgets('renders the design system preview', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Steady'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
