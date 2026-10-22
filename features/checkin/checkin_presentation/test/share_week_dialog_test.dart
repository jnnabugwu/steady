import 'dart:async';
import 'dart:typed_data';

import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_check_in_repository.dart';
import 'helpers/fake_metrics_repository.dart';

/// Reads a PNG's IHDR width and height (big-endian, bytes 16–23).
(int, int) _pngSize(Uint8List png) {
  final header = ByteData.sublistView(png);
  return (header.getUint32(16), header.getUint32(20));
}

void main() {
  // Monday; its Friday-Thursday week starts Fri 2026-08-21.
  final day = DateTime(2026, 8, 24);
  late FakeMetricsRepository metrics;
  late RecordingSharer sharer;

  setUp(() {
    metrics = FakeMetricsRepository(
      onGetRange: (_, _) => Ok([
        DailyMetric(
          date: DateTime(2026, 8, 21),
          loggingStatus: LoggingStatus.logged,
          caloriesEaten: 1850,
          steps: 8204,
        ),
        DailyMetric(
          date: DateTime(2026, 8, 24),
          loggingStatus: LoggingStatus.partial,
        ),
      ]),
    );
    sharer = RecordingSharer();
  });

  Future<void> tapShareWeek(WidgetTester tester, {bool settle = true}) async {
    await tester.tap(find.byKey(const Key('shareWeekButton')));
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      // A loading spinner never settles; pump past the dialog transition.
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
    }
  }

  Future<void> openDialog(WidgetTester tester, {bool settle = true}) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          checkInRepositoryProvider.overrideWithValue(FakeCheckInRepository()),
          weekMetricsRepositoryProvider.overrideWithValue(metrics),
          weekCardSharerProvider.overrideWithValue(sharer.call),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: CheckInModule(date: day, onCheckInCompleted: () {}),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tapShareWeek(tester, settle: settle);
  }

  Future<void> toggleNumbers(WidgetTester tester) async {
    await tester.tap(find.byKey(const Key('shareWeekNumbersSwitch')));
    await tester.pumpAndSettle();
  }

  /// Taps Share and waits for the share seam. The PNG render is real engine
  /// work, so it has to run outside the test's fake-async zone.
  Future<void> share(WidgetTester tester) async {
    final before = sharer.calls.length;
    await tester.runAsync(() async {
      await tester.tap(find.byKey(const Key('shareWeekConfirmButton')));
      final deadline = DateTime.now().add(const Duration(seconds: 10));
      while (sharer.calls.length == before &&
          DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 10));
      }
    });
    await tester.pumpAndSettle();
  }

  PrimaryButton shareButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('shareWeekConfirmButton')));

  OutlineButton cancelButton(WidgetTester tester) =>
      tester.widget(find.byKey(const Key('shareWeekCancelButton')));

  group('renderWeekCardPng', () {
    testWidgets(
      'returns a Failure, not a throw, when drawing throws an Error',
      (tester) async {
        final key = GlobalKey();
        await tester.pumpWidget(
          RepaintBoundary(
            key: key,
            child: const SizedBox(width: 10, height: 10),
          ),
        );
        // toImage asserts the boundary has been painted; an AssertionError is
        // an Error, not an Exception.
        key.currentContext!.findRenderObject()!.markNeedsPaint();

        final result = await renderWeekCardPng(key);

        expect(
          result,
          isA<Err<Uint8List>>().having(
            (e) => e.failure,
            'failure',
            isA<UnknownFailure>().having(
              (f) => f.cause,
              'cause',
              isA<AssertionError>(),
            ),
          ),
        );
      },
    );
  });

  group('Share week from the check-in screen', () {
    testWidgets('previews the week with one range read', (tester) async {
      await openDialog(tester);

      expect(find.text('Share your week'), findsOneWidget);
      expect(find.byType(WeekCard), findsOneWidget);
      expect(find.text('Fri Aug 21 – Thu Aug 27'), findsOneWidget);
      expect(metrics.getRangeCalls, [
        (DateTime(2026, 8, 21), DateTime(2026, 8, 27)),
      ]);
    });

    testWidgets('calories and steps are off by default, shown when toggled', (
      tester,
    ) async {
      await openDialog(tester);

      expect(find.text('1,850 cal'), findsNothing);
      expect(find.text('8,204 steps'), findsNothing);

      await toggleNumbers(tester);

      expect(find.text('1,850 cal'), findsOneWidget);
      expect(find.text('8,204 steps'), findsOneWidget);
    });

    testWidgets('shares a 1080x1350 PNG named for the week, then closes', (
      tester,
    ) async {
      // Not the test default of 3.0, so a render that used the device's
      // pixel ratio instead of WeekCard.pixelRatio would come out the
      // wrong size.
      tester.view.devicePixelRatio = 2;
      addTearDown(tester.view.resetDevicePixelRatio);
      await openDialog(tester);

      await share(tester);

      expect(sharer.calls, hasLength(1));
      final call = sharer.calls.single;
      expect(call.fileName, 'steady-week-2026-08-21.png');
      // PNG signature.
      expect(call.png.sublist(0, 8), [137, 80, 78, 71, 13, 10, 26, 10]);
      expect(_pngSize(call.png), (1080, 1350));
      // Anchored at the Share button, for iPad's popover.
      expect(call.origin, isNotNull);
      expect(call.origin!.isEmpty, isFalse);
      expect(find.text('Share your week'), findsNothing);
    });

    testWidgets('the shared PNG changes when calories and steps are on', (
      tester,
    ) async {
      await openDialog(tester);
      await share(tester);

      await tapShareWeek(tester);
      await toggleNumbers(tester);
      await share(tester);

      expect(sharer.calls, hasLength(2));
      final [withoutNumbers, withNumbers] = [
        for (final call in sharer.calls) call.png,
      ];

      expect(withNumbers, isNot(equals(withoutNumbers)));
    });

    testWidgets('a failed share keeps the dialog open with the Failure', (
      tester,
    ) async {
      sharer.result = const Err(PlatformChannelFailure('sheet unavailable'));
      await openDialog(tester);

      await share(tester);

      expect(find.text("Couldn't share: sheet unavailable"), findsOneWidget);
      expect(find.text('Share your week'), findsOneWidget);
      expect(shareButton(tester).onPressed, isNotNull);
    });

    testWidgets('Cancel is disabled while a share is in flight', (
      tester,
    ) async {
      final sheet = Completer<void>();
      sharer
        ..hold = sheet.future
        ..result = const Err(PlatformChannelFailure('sheet unavailable'));
      await openDialog(tester);
      expect(cancelButton(tester).onPressed, isNotNull);

      // Returns once the share sheet is "up", i.e. the sharer was called.
      await share(tester);

      expect(cancelButton(tester).onPressed, isNull);
      expect(shareButton(tester).onPressed, isNull);

      sheet.complete();
      await tester.pumpAndSettle();

      expect(find.text("Couldn't share: sheet unavailable"), findsOneWidget);
      expect(cancelButton(tester).onPressed, isNotNull);
    });

    testWidgets('dismissing the dialog mid-render neither shares nor throws', (
      tester,
    ) async {
      await openDialog(tester);
      final dialogContext = tester.element(find.byType(ShareWeekDialog));

      // Start the share; it stops at the render, which needs real time.
      await tester.tap(find.byKey(const Key('shareWeekConfirmButton')));
      await tester.pump();
      expect(cancelButton(tester).onPressed, isNull);

      // Dismiss another way (barrier / Escape) before the render finishes.
      unawaited(closeOverlay<void>(dialogContext));
      await tester.pumpAndSettle();
      expect(find.byType(ShareWeekDialog), findsNothing);

      // Let the render finish against the disposed dialog.
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 500)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(sharer.calls, isEmpty);
    });

    testWidgets('a repository failure shows the error, not an empty card', (
      tester,
    ) async {
      metrics.onGetRange = (_, _) =>
          const Err(PlatformChannelFailure('store down'));

      await openDialog(tester);

      expect(find.text("Couldn't load this week: store down"), findsOneWidget);
      expect(find.byType(WeekCard), findsNothing);
      expect(shareButton(tester).onPressed, isNull);
    });

    testWidgets('Share is disabled while the week is loading', (tester) async {
      final pending = Completer<Result<List<DailyMetric>>>();
      metrics.onGetRange = (_, _) => pending.future;

      await openDialog(tester, settle: false);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.byType(WeekCard), findsNothing);
      expect(shareButton(tester).onPressed, isNull);

      pending.complete(const Ok([]));
      await tester.pumpAndSettle();
      expect(find.byType(WeekCard), findsOneWidget);
      expect(shareButton(tester).onPressed, isNotNull);
    });
  });
}
