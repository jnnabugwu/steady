import 'package:cravings_domain/cravings_domain.dart';
import 'package:flutter_test/flutter_test.dart';

CravingEvent _event(DateTime startedAt, {String? id}) => CravingEvent(
  id: id ?? startedAt.toIso8601String(),
  startedAt: startedAt,
  intensityBefore: 3,
  reasons: const {},
  tookMinute: false,
  outcome: CravingOutcome.notSure,
);

void main() {
  group('cravingTimeOfDay', () {
    final cases = <int, CravingTimeOfDay>{
      0: CravingTimeOfDay.night,
      4: CravingTimeOfDay.night,
      5: CravingTimeOfDay.morning,
      11: CravingTimeOfDay.morning,
      12: CravingTimeOfDay.afternoon,
      16: CravingTimeOfDay.afternoon,
      17: CravingTimeOfDay.evening,
      21: CravingTimeOfDay.evening,
      22: CravingTimeOfDay.night,
      23: CravingTimeOfDay.night,
    };
    for (final MapEntry(key: hour, value: bucket) in cases.entries) {
      test('$hour:59 is ${bucket.name}', () {
        expect(cravingTimeOfDay(DateTime(2026, 10, 23, hour, 59)), bucket);
      });
    }
  });

  group('cravingWeekWindow', () {
    test('is the seven calendar days ending today', () {
      final window = cravingWeekWindow(DateTime(2026, 10, 23, 15, 30));
      expect(window.start, DateTime(2026, 10, 17));
      expect(window.end, DateTime(2026, 10, 24));
    });

    test('crosses a month boundary', () {
      final window = cravingWeekWindow(DateTime(2026, 11, 2, 8));
      expect(window.start, DateTime(2026, 10, 27));
      expect(window.end, DateTime(2026, 11, 3));
    });
  });

  group('summarizeCravingWeek', () {
    final now = DateTime(2026, 10, 23, 20);

    test('an empty week has no count and no time of day', () {
      expect(
        summarizeCravingWeek(const [], now: now),
        const CravingWeekSummary(count: 0),
      );
    });

    test('counts only events in the window', () {
      final summary = summarizeCravingWeek([
        _event(DateTime(2026, 10, 16, 23, 59)), // the day before: out
        _event(DateTime(2026, 10, 17)), // first moment: in
        _event(DateTime(2026, 10, 23, 19)), // today: in
        _event(DateTime(2026, 10, 24)), // tomorrow: out
      ], now: now);
      expect(summary.count, 2);
    });

    test('names the majority time of day', () {
      final summary = summarizeCravingWeek([
        _event(DateTime(2026, 10, 20, 18)),
        _event(DateTime(2026, 10, 21, 21, 30)),
        _event(DateTime(2026, 10, 22, 9)),
      ], now: now);
      expect(
        summary,
        const CravingWeekSummary(count: 3, mostly: CravingTimeOfDay.evening),
      );
    });

    test('a single event is its own majority', () {
      final summary = summarizeCravingWeek([
        _event(DateTime(2026, 10, 23, 1)),
      ], now: now);
      expect(
        summary,
        const CravingWeekSummary(count: 1, mostly: CravingTimeOfDay.night),
      );
    });

    test('no time of day when nothing has more than half', () {
      final tie = summarizeCravingWeek([
        _event(DateTime(2026, 10, 20, 18)),
        _event(DateTime(2026, 10, 21, 9)),
      ], now: now);
      expect(tie, const CravingWeekSummary(count: 2));

      final plurality = summarizeCravingWeek([
        _event(DateTime(2026, 10, 20, 18)),
        _event(DateTime(2026, 10, 21, 19)),
        _event(DateTime(2026, 10, 21, 9)),
        _event(DateTime(2026, 10, 22, 13)),
      ], now: now);
      expect(plurality, const CravingWeekSummary(count: 4));
    });

    test('ignores outcomes entirely', () {
      final summary = summarizeCravingWeek([
        _event(DateTime(2026, 10, 20, 18)).copyWith(
          outcome: CravingOutcome.passed,
        ),
        _event(DateTime(2026, 10, 21, 18)).copyWith(
          outcome: CravingOutcome.havingIt,
        ),
      ], now: now);
      expect(
        summary,
        const CravingWeekSummary(count: 2, mostly: CravingTimeOfDay.evening),
      );
    });
  });

  group('CravingEvent', () {
    test('intensity validation', () {
      expect(isValidCravingIntensity(0), isFalse);
      expect(isValidCravingIntensity(1), isTrue);
      expect(isValidCravingIntensity(5), isTrue);
      expect(isValidCravingIntensity(6), isFalse);
    });

    test('asserts intensities are 1 to 5', () {
      expect(
        () => _event(DateTime(2026)).copyWith(intensityBefore: 0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => _event(DateTime(2026)).copyWith(intensityAfter: 6),
        throwsA(isA<AssertionError>()),
      );
    });

    test('value equality includes reasons', () {
      final a = _event(DateTime(2026)).copyWith(
        reasons: {CravingReason.bored, CravingReason.tired},
      );
      final b = _event(DateTime(2026)).copyWith(
        reasons: {CravingReason.tired, CravingReason.bored},
      );
      expect(a, b);
      expect(a, isNot(_event(DateTime(2026))));
    });
  });
}
