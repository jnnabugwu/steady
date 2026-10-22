import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:steady/app_router.dart';
import 'package:steady/design_system_preview.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';

/// Records every `cancelReminder` call, so a test can see which day the
/// route asked to cancel.
class _RecordingNotificationScheduler implements NotificationScheduler {
  final List<DateTime> cancelled = [];

  @override
  ResultFuture<Unit> scheduleEndOfDayReminder(DateTime date) async =>
      const Ok(unit);

  @override
  ResultFuture<Unit> cancelReminder(DateTime date) async {
    cancelled.add(date);
    return const Ok(unit);
  }
}

void main() {
  late _RecordingNotificationScheduler scheduler;

  setUp(() => scheduler = _RecordingNotificationScheduler());

  /// Pumps the real app, with the real override list plus the recording
  /// scheduler. If [coldStartLocation] is given, it is the platform's
  /// initial route, which is how the OS hands a tapped notification's deep
  /// link to a cold-started app.
  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? coldStartLocation,
  }) async {
    if (coldStartLocation != null) {
      tester.platformDispatcher.defaultRouteNameTestValue = coldStartLocation;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    }
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ...appProviderOverrides,
          notificationSchedulerProvider.overrideWithValue(scheduler),
        ],
        child: const SteadyApp(),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(SteadyApp)));
  }

  Future<LoggingStatus?> storedStatus(
    ProviderContainer container,
    DateTime day,
  ) async {
    final result = await container
        .read(dailyMetricRepositoryProvider)
        .getByDate(day);
    return (result as Ok<DailyMetric?>).value?.loggingStatus;
  }

  DateTime moduleDay(WidgetTester tester) {
    final date = tester.widget<CheckInModule>(find.byType(CheckInModule)).date;
    return DateTime(date.year, date.month, date.day);
  }

  bool sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  group('cold start', () {
    testWidgets('/ shows the home screen', (tester) async {
      await pumpApp(tester);

      expect(find.byType(DesignSystemPreview), findsOneWidget);
      expect(find.byType(CheckInModule), findsNothing);
    });

    testWidgets(
      '/checkin/2026-10-19 opens that day, logs to the shared store and '
      "cancels that day's reminder",
      (tester) async {
        final day = DateTime(2026, 10, 19);
        final container = await pumpApp(
          tester,
          coldStartLocation: '/checkin/2026-10-19',
        );

        expect(find.byType(CheckInModule), findsOneWidget);
        expect(moduleDay(tester), day);
        expect(find.text('Not checked in yet'), findsOneWidget);

        await tester.tap(find.byKey(const Key('checkInButton_logged')));
        await tester.pumpAndSettle();

        expect(find.text('Status: Logged'), findsOneWidget);
        expect(await storedStatus(container, day), LoggingStatus.logged);
        expect(scheduler.cancelled, hasLength(1));
        expect(sameDay(scheduler.cancelled.single, day), isTrue);
      },
    );

    testWidgets('a time component resolves to the same calendar day', (
      tester,
    ) async {
      final day = DateTime(2026, 10, 19);
      final container = await pumpApp(
        tester,
        coldStartLocation: '/checkin/2026-10-19T21:30:00',
      );

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(moduleDay(tester), day);

      await tester.tap(find.byKey(const Key('checkInButton_partial')));
      await tester.pumpAndSettle();

      expect(await storedStatus(container, day), LoggingStatus.partial);
      expect(scheduler.cancelled, hasLength(1));
      expect(sameDay(scheduler.cancelled.single, day), isTrue);
    });
  });

  group('CheckInRoute.location', () {
    test('encodes the calendar date only, as yyyy-MM-dd', () {
      expect(
        CheckInRoute(date: DateTime(2026, 10, 19)).location,
        '/checkin/2026-10-19',
      );
      expect(
        CheckInRoute(date: DateTime(2026, 10, 19, 21, 30, 15)).location,
        '/checkin/2026-10-19',
      );
      expect(
        CheckInRoute(date: DateTime(2026, 1, 5)).location,
        '/checkin/2026-01-05',
      );
    });

    testWidgets('round-trips back to the same day through the router', (
      tester,
    ) async {
      final day = DateTime(2026, 1, 5);
      final container = await pumpApp(tester);

      container
          .read(routerProvider)
          .go(CheckInRoute(date: DateTime(2026, 1, 5, 23, 59)).location);
      await tester.pumpAndSettle();

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(moduleDay(tester), day);
    });
  });
}
