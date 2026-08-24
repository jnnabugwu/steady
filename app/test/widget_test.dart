import 'package:flutter_test/flutter_test.dart';

import 'package:steady/main.dart';

void main() {
  testWidgets('renders the design system preview', (tester) async {
    await tester.pumpWidget(const SteadyApp());
    await tester.pumpAndSettle();

    expect(find.text('Steady'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
  });
}
