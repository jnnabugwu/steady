import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';

void main() {
  testWidgets('home is the metrics history', (tester) async {
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MetricsHistoryModule), findsOneWidget);
  });
}
