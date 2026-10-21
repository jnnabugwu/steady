import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';

void main() {
  group('WeeklyBucket.days', () {
    final weekStart = DateTime(2026, 10, 19);
    final monday = DailyMetric(date: DateTime(2026, 10, 19), steps: 1000);
    final tuesday = DailyMetric(date: DateTime(2026, 10, 20), steps: 2000);

    test('mutating the list passed in does not change the bucket', () {
      final input = [monday];
      final bucket = WeeklyBucket(weekStart: weekStart, days: input);

      input.add(tuesday);

      expect(bucket.days, [monday]);
      expect(bucket.totalSteps, 1000);
      expect(bucket, WeeklyBucket(weekStart: weekStart, days: [monday]));
    });

    test('is unmodifiable: add throws UnsupportedError', () {
      final bucket = WeeklyBucket(weekStart: weekStart, days: [monday]);

      expect(() => bucket.days.add(tuesday), throwsUnsupportedError);
    });
  });
}
