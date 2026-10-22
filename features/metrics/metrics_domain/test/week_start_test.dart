import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';

void main() {
  group('weekStartFor', () {
    test('defaults to the Friday anchor (Friday-Thursday window)', () {
      // 2026-10-22 is a Thursday, the last day of the week starting Fri 16th.
      expect(weekStartFor(DateTime(2026, 10, 22)), DateTime(2026, 10, 16));
    });

    test('an anchor day is its own week start', () {
      expect(weekStartFor(DateTime(2026, 10, 16)), DateTime(2026, 10, 16));
    });

    test('drops the time of day', () {
      expect(
        weekStartFor(DateTime(2026, 10, 22, 18, 30)),
        DateTime(2026, 10, 16),
      );
    });

    test('crosses a month boundary', () {
      // Thu 2026-10-01 belongs to the week starting Fri 2026-09-25.
      expect(weekStartFor(DateTime(2026, 10)), DateTime(2026, 9, 25));
    });

    test('crosses a year boundary', () {
      // Thu 2026-01-01 belongs to the week starting Fri 2025-12-26.
      expect(weekStartFor(DateTime(2026)), DateTime(2025, 12, 26));
      // Sun 2027-01-03 belongs to the week starting Fri 2027-01-01.
      expect(weekStartFor(DateTime(2027, 1, 3)), DateTime(2027));
    });

    test('lands on midnight across a DST change', () {
      // US DST ends Sun 2026-11-01; the week started Fri 2026-10-30.
      final start = weekStartFor(DateTime(2026, 11, 1, 12));
      expect(start, DateTime(2026, 10, 30));
      expect(start.hour, 0);
    });

    test('honors a custom anchor', () {
      expect(
        weekStartFor(DateTime(2026, 10, 22), anchorWeekday: DateTime.monday),
        DateTime(2026, 10, 19),
      );
    });
  });
}
