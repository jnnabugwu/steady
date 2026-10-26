import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

void main() {
  group('HealthDayTotals.isEmpty', () {
    test('is true only when every value is null', () {
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
      expect(HealthDayTotals(date: day, weightKg: 80).isEmpty, isFalse);
    });
  });

  group('HealthDayTotals.hasActivity', () {
    test('is steps or energy, not weight', () {
      final day = DateTime(2026, 10, 23);
      expect(HealthDayTotals(date: day, weightKg: 80).hasActivity, isFalse);
      expect(HealthDayTotals(date: day, steps: 0).hasActivity, isTrue);
      expect(
        HealthDayTotals(date: day, caloriesBurnedBasal: 1).hasActivity,
        isTrue,
      );
    });
  });
}
