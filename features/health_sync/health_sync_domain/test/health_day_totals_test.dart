import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

void main() {
  group('HealthDayTotals.isEmpty', () {
    test('is true only when all three values are null', () {
      final day = DateTime(2026, 10, 23);
      expect(HealthDayTotals(date: day).isEmpty, isTrue);
      expect(HealthDayTotals(date: day, steps: 0).isEmpty, isFalse);
      expect(
        HealthDayTotals(date: day, caloriesBurnedActive: 1).isEmpty,
        isFalse,
      );
      expect(
        HealthDayTotals(date: day, caloriesBurnedBasal: 1).isEmpty,
        isFalse,
      );
    });
  });
}
