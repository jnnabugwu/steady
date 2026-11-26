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
      // 80, then 79 two days later: a 2-day gap moves it 1 − 0.9² = 0.19.
      expect(trend, closeTo(80 + 0.19 * (79 - 80), 1e-9));
    });

    test('a day without a reading never counts as a reading', () {
      // The same two readings, with or without empty days between them in
      // the input: only the calendar gap matters.
      expect(
        weightTrendKg([day(20, 80), day(21), day(22, 79)]),
        weightTrendKg([day(20, 80), day(22, 79)]),
      );
    });

    test('after a gap, a reading moves it as far as missed days would', () {
      // 190 lb 29 days ago, 180 lb today (in kg): 1 − 0.9^29 ≈ 0.953 of the
      // way, about 180.5 lb, where a per-reading step would have said 189.
      const lb = 0.45359237;
      final trend = weightTrendKg([
        HealthDayTotals(date: DateTime(2026, 9, 30), weightKg: 190 * lb),
        HealthDayTotals(date: DateTime(2026, 10, 29), weightKg: 180 * lb),
      ])!;
      expect(trend / lb, closeTo(180.47, 0.01));
    });

    test('daily weigh-ins step a tenth each day, as before', () {
      final gapAware = weightTrendKg([day(1, 80), day(2, 82)]);
      expect(gapAware, closeTo(80.2, 1e-9));
    });

    test('counts calendar days across a daylight-saving change', () {
      // US clocks fall back on 2026-11-01: Oct 31 to Nov 2 is still 2 days.
      final trend = weightTrendKg([
        HealthDayTotals(date: DateTime(2026, 10, 31), weightKg: 80),
        HealthDayTotals(date: DateTime(2026, 11, 2), weightKg: 79),
      ]);
      expect(trend, closeTo(80 - 0.19, 1e-9));
    });

    test('two readings on the same day count as a one-day step', () {
      final trend = weightTrendKg([day(20, 80), day(20, 82)]);
      expect(trend, closeTo(80.2, 1e-9));
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
