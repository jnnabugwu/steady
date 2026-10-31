import 'package:analytics/analytics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

void main() {
  group('AnalyticsEvent', () {
    test('every property is a label, a yes/no or a count', () {
      final events = [
        AnalyticsEvent.healthConnected(steps: true, caloriesEaten: false),
        AnalyticsEvent.checkInLogged(status: 'partial'),
        AnalyticsEvent.pdfImported(days: 7, sample: false),
        AnalyticsEvent.pdfImportFailed(stage: PdfImportStage.save),
        for (final reason in CoachAvailabilityReason.values)
          AnalyticsEvent.coachAvailability(reason: reason),
        AnalyticsEvent.cravingFlowFinished,
      ];
      for (final event in events) {
        for (final value in event.properties.values) {
          expect(value, anyOf(isA<String>(), isA<bool>(), isA<int>()));
        }
      }
    });

    test('names and properties are the ones PostHog receives', () {
      expect(
        AnalyticsEvent.checkInLogged(status: 'skipped'),
        isA<AnalyticsEvent>()
            .having((e) => e.name, 'name', 'check_in_logged')
            .having((e) => e.properties, 'properties', {'status': 'skipped'}),
      );
      expect(
        AnalyticsEvent.coachAvailability(
          reason: CoachAvailabilityReason.modelNotReady,
        ).properties,
        {'available': false, 'reason': 'modelNotReady'},
      );
      expect(
        AnalyticsEvent.healthConnected(
          steps: true,
          caloriesEaten: false,
        ).properties,
        {'steps': true, 'calories_eaten': false},
      );
      expect(
        AnalyticsEvent.pdfImportFailed(stage: PdfImportStage.parse).properties,
        {'stage': 'parse'},
      );
    });

    test('an unknown check-in status fails in debug', () {
      expect(
        () => AnalyticsEvent.checkInLogged(status: '1850 kcal'),
        throwsA(isA<AssertionError>()),
      );
    });

    test('equal name and properties are equal', () {
      expect(
        AnalyticsEvent.pdfImported(days: 3, sample: true),
        AnalyticsEvent.pdfImported(days: 3, sample: true),
      );
      expect(
        AnalyticsEvent.pdfImported(days: 3, sample: true),
        isNot(AnalyticsEvent.pdfImported(days: 4, sample: true)),
      );
    });
  });

  test('analyticsProvider sends nothing unless overridden', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(analyticsProvider), isA<NoAnalytics>());
  });
}
