import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

void main() {
  HealthDayTotals day(int d, [double? kg]) =>
      HealthDayTotals(date: DateTime(2026, 10, d), weightKg: kg);

  group('weightTrendKg', () {
    test('is null with no readings', () {
      expect(weightTrendKg([]), isNull);
      expect(weightTrendKg([day(20), day(21)]), isNull);
    });

    test('is the reading itself with one reading', () {
      expect(weightTrendKg([day(20), day(21, 80.5)]), 80.5);
    });

    test('moves a tenth of the way toward each later reading', () {
      // 80 → 80 + 0.1 × (82 − 80) = 80.2 → 80.2 + 0.1 × (79 − 80.2) = 80.08
      expect(
        weightTrendKg([day(20, 80), day(21, 82), day(22, 79)]),
        closeTo(80.08, 1e-9),
      );
    });

    test('skips days without a reading and sorts by date', () {
      final trend = weightTrendKg([day(22, 79), day(19), day(20, 80), day(21)]);
      // 80, then 79: 80 + 0.1 × (79 − 80).
      expect(trend, closeTo(79.9, 1e-9));
    });

    test('a single noisy day barely moves it', () {
      final steady = [for (var d = 1; d <= 20; d++) day(d, 80)];
      final trend = weightTrendKg([...steady, day(21, 82)])!;
      expect(trend, closeTo(80.2, 1e-9));
    });

    test('takes a custom smoothing', () {
      expect(
        weightTrendKg([day(20, 80), day(21, 82)], smoothing: 0.5),
        closeTo(81, 1e-9),
      );
    });
  });
}
