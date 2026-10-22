import 'dart:async';

import 'package:checkin_domain/checkin_domain.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/fake_check_in_repository.dart';

void main() {
  final midnight = DateTime(2026, 8, 24);
  late FakeCheckInRepository repository;
  late int completedCount;

  setUp(() {
    repository = FakeCheckInRepository();
    completedCount = 0;
  });

  Widget module(DateTime date) => MaterialApp(
    home: CheckInModule(date: date, onCheckInCompleted: () => completedCount++),
  );

  Future<void> pumpInScope(WidgetTester tester, DateTime date) =>
      tester.pumpWidget(
        ProviderScope(
          overrides: [checkInRepositoryProvider.overrideWithValue(repository)],
          child: module(date),
        ),
      );

  group('CheckInModule', () {
    testWidgets('shows a spinner while loading, then the stored status', (
      tester,
    ) async {
      final completer = Completer<Result<CheckInStatus?>>();
      repository.onGetStatus = (_) => completer.future;

      await pumpInScope(tester, midnight);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(const Ok(CheckInStatus.logged));
      await tester.pumpAndSettle();

      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(find.text('Status: Logged'), findsOneWidget);
    });

    testWidgets('tapping a button logs it and fires onCheckInCompleted once', (
      tester,
    ) async {
      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();
      expect(find.text('Not checked in yet'), findsOneWidget);

      await tester.tap(find.byKey(const Key('checkInButton_partial')));
      await tester.pumpAndSettle();

      expect(repository.logCheckInCalls, [(midnight, CheckInStatus.partial)]);
      expect(find.text('Status: Partial'), findsOneWidget);
      expect(completedCount, 1);
    });

    testWidgets('renders the Failure when loading fails', (tester) async {
      repository.onGetStatus = (_) =>
          const Err(PlatformChannelFailure('channel down'));

      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load check-in: channel down'),
        findsOneWidget,
      );
    });

    testWidgets('a failed log renders the Failure and does not complete', (
      tester,
    ) async {
      repository.onLogCheckIn = (_, _) =>
          const Err(UnknownFailure('write failed'));

      await pumpInScope(tester, midnight);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('checkInButton_skipped')));
      await tester.pumpAndSettle();

      expect(
        find.text('Could not load check-in: write failed'),
        findsOneWidget,
      );
      expect(completedCount, 0);
    });
  });

  group('date normalization', () {
    testWidgets('09:00 and 18:00 on the same day share one provider', (
      tester,
    ) async {
      final container = ProviderContainer.test(
        overrides: [checkInRepositoryProvider.overrideWithValue(repository)],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: module(DateTime(2026, 8, 24, 9)),
        ),
      );
      await tester.pumpAndSettle();
      final morning = container.read(checkInControllerProvider(midnight));

      await tester.tap(find.byKey(const Key('checkInButton_logged')));
      await tester.pumpAndSettle();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: module(DateTime(2026, 8, 24, 18)),
        ),
      );
      await tester.pumpAndSettle();

      // One provider, keyed on midnight, built once: the 18:00 module sees
      // the status logged from the 09:00 module without re-reading.
      expect(morning, isA<AsyncData<CheckInStatus?>>());
      expect(container.exists(checkInControllerProvider(midnight)), isTrue);
      expect(
        container.exists(checkInControllerProvider(DateTime(2026, 8, 24, 9))),
        isFalse,
      );
      expect(
        container.exists(checkInControllerProvider(DateTime(2026, 8, 24, 18))),
        isFalse,
      );
      expect(repository.getStatusCalls, [midnight]);
      expect(find.text('Status: Logged'), findsOneWidget);
    });
  });

  group('auto-dispose', () {
    testWidgets('the provider is disposed once the module leaves the tree', (
      tester,
    ) async {
      final container = ProviderContainer.test(
        overrides: [checkInRepositoryProvider.overrideWithValue(repository)],
      );
      Widget scoped(Widget child) =>
          UncontrolledProviderScope(container: container, child: child);

      await tester.pumpWidget(scoped(module(midnight)));
      await tester.pumpAndSettle();
      expect(container.exists(checkInControllerProvider(midnight)), isTrue);

      // Simulate the screen popping: replace the module with another widget.
      await tester.pumpWidget(scoped(const MaterialApp(home: SizedBox())));
      await tester.pumpAndSettle();

      expect(container.exists(checkInControllerProvider(midnight)), isFalse);

      // Returning to the screen builds a fresh provider that re-reads.
      await tester.pumpWidget(scoped(module(midnight)));
      await tester.pumpAndSettle();
      expect(repository.getStatusCalls, [midnight, midnight]);
    });
  });
}
