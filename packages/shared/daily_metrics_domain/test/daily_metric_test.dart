import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('DailyMetric', () {
    test('equal when all fields match', () {
      final a = DailyMetric(
        date: DateTime(2026, 8, 24),
        caloriesEaten: 2000,
        loggingStatus: LoggingStatus.logged,
      );
      final b = DailyMetric(
        date: DateTime(2026, 8, 24),
        caloriesEaten: 2000,
        loggingStatus: LoggingStatus.logged,
      );
      expect(a, b);
    });

    test('caloriesEaten of 0 is distinct from null', () {
      final zero = DailyMetric(date: DateTime(2026, 8, 24), caloriesEaten: 0);
      final none = DailyMetric(date: DateTime(2026, 8, 24));
      expect(zero, isNot(none));
      expect(zero.caloriesEaten, 0);
      expect(none.caloriesEaten, isNull);
    });
  });
}
