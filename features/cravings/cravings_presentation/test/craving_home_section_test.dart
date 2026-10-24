import 'package:cravings_domain/cravings_domain.dart';
import 'package:cravings_presentation/cravings_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_craving_repository.dart';

CravingEvent _at(DateTime startedAt, CravingOutcome outcome) => CravingEvent(
  id: startedAt.toIso8601String(),
  startedAt: startedAt,
  intensityBefore: 3,
  reasons: const {},
  tookMinute: false,
  outcome: outcome,
);

void main() {
  final now = DateTime(2026, 10, 23, 12);

  group('cravingWeekLine', () {
    test('nothing to say for an empty week', () {
      expect(cravingWeekLine(const CravingWeekSummary(count: 0)), isNull);
    });

    test('count and the majority time of day', () {
      expect(
        cravingWeekLine(
          const CravingWeekSummary(count: 3, mostly: CravingTimeOfDay.evening),
        ),
        '3 cravings this week, mostly in the evening',
      );
      expect(
        cravingWeekLine(
          const CravingWeekSummary(count: 2, mostly: CravingTimeOfDay.night),
        ),
        '2 cravings this week, mostly at night',
      );
    });

    test('one craving reads naturally', () {
      expect(
        cravingWeekLine(
          const CravingWeekSummary(count: 1, mostly: CravingTimeOfDay.morning),
        ),
        '1 craving this week, in the morning',
      );
    });

    test('no majority: just the count', () {
      expect(
        cravingWeekLine(const CravingWeekSummary(count: 4)),
        '4 cravings this week',
      );
    });
  });

  group('CravingHomeSection', () {
    late FakeCravingRepository repository;
    late int requested;

    setUp(() {
      repository = FakeCravingRepository();
      requested = 0;
    });

    Future<void> pump(WidgetTester tester, {required bool available}) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            cravingRepositoryProvider.overrideWithValue(repository),
            cravingSupportAvailableProvider.overrideWithValue(available),
            cravingClockProvider.overrideWithValue(() => now),
          ],
          child: ShadcnApp(
            theme: steadyTheme,
            home: Scaffold(
              child: CravingHomeSection(onCravingRequested: () => requested++),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('renders nothing where craving support is off (macOS)', (
      tester,
    ) async {
      await pump(tester, available: false);
      expect(find.byKey(const Key('cravingEntryButton')), findsNothing);
      expect(find.text('Having a craving?'), findsNothing);
    });

    testWidgets('on iOS: the button, and no line for an empty week', (
      tester,
    ) async {
      await pump(tester, available: true);
      expect(find.text('Having a craving?'), findsOneWidget);
      expect(find.byKey(const Key('cravingWeekLine')), findsNothing);

      await tester.tap(find.byKey(const Key('cravingEntryButton')));
      expect(requested, 1);
    });

    testWidgets('shows the gentle weekly line, with no outcome counts', (
      tester,
    ) async {
      repository.events.addAll([
        _at(DateTime(2026, 10, 20, 19), CravingOutcome.passed),
        _at(DateTime(2026, 10, 21, 20), CravingOutcome.havingIt),
        _at(DateTime(2026, 10, 22, 8), CravingOutcome.passed),
        // Eight days ago: not this week.
        _at(DateTime(2026, 10, 15, 19), CravingOutcome.passed),
      ]);
      await pump(tester, available: true);
      expect(
        find.text('3 cravings this week, mostly in the evening'),
        findsOneWidget,
      );
      expect(find.textContaining('passed'), findsNothing);
    });

    testWidgets('a failed read leaves the line out but keeps the button', (
      tester,
    ) async {
      repository.onGetBetween = () async =>
          const Err(UnknownFailure('unreadable'));
      await pump(tester, available: true);
      expect(find.byKey(const Key('cravingWeekLine')), findsNothing);
      expect(find.byKey(const Key('cravingEntryButton')), findsOneWidget);
    });
  });
}
