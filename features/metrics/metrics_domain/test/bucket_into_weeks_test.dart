import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';

DailyMetric _metricFor(DateTime date) => DailyMetric(date: date, steps: 1);

void main() {
  group('bucketIntoWeeks', () {
    test('empty input returns empty list', () {
      expect(bucketIntoWeeks([]), isEmpty);
    });

    test('7 consecutive days (Mon-Sun) bucket into 1 full week', () {
      // 2026-08-17 is a Monday.
      final days = List.generate(
        7,
        (i) => _metricFor(DateTime(2026, 8, 17 + i)),
      );

      final buckets = bucketIntoWeeks(days);

      expect(buckets, hasLength(1));
      expect(buckets.single.weekStart, DateTime(2026, 8, 17));
      expect(buckets.single.days, hasLength(7));
    });

    test('3 days bucket into 1 partial week', () {
      final days = List.generate(
        3,
        (i) => _metricFor(DateTime(2026, 8, 17 + i)),
      );

      final buckets = bucketIntoWeeks(days);

      expect(buckets, hasLength(1));
      expect(buckets.single.days, hasLength(3));
    });

    test('14 days split correctly at the anchor-weekday boundary', () {
      // 2026-08-17 is a Monday; 14 days spans exactly two Mon-Sun weeks.
      final days = List.generate(
        14,
        (i) => _metricFor(DateTime(2026, 8, 17 + i)),
      );

      final buckets = bucketIntoWeeks(days);

      expect(buckets, hasLength(2));
      expect(buckets[0].weekStart, DateTime(2026, 8, 17));
      expect(buckets[0].days, hasLength(7));
      expect(buckets[1].weekStart, DateTime(2026, 8, 24));
      expect(buckets[1].days, hasLength(7));
    });

    test('respects a non-default anchorWeekday', () {
      // 2026-08-19 is a Wednesday.
      final days = [
        _metricFor(DateTime(2026, 8, 18)), // Tue, prior week
        _metricFor(DateTime(2026, 8, 19)), // Wed, new anchor week
      ];

      final buckets = bucketIntoWeeks(days, anchorWeekday: DateTime.wednesday);

      expect(buckets, hasLength(2));
      expect(buckets[1].weekStart, DateTime(2026, 8, 19));
    });
  });
}
