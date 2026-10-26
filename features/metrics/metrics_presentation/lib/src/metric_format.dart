import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:health_sync_domain/health_sync_domain.dart';

/// Active + basal calories burned, or `null` when neither is recorded.
int? caloriesBurned(DailyMetric day) {
  final active = day.caloriesBurnedActive;
  final basal = day.caloriesBurnedBasal;
  if (active == null && basal == null) return null;
  return (active ?? 0) + (basal ?? 0);
}

/// Formats [value] with comma thousands separators, e.g. 1330 -> "1,330".
String formatThousands(int value) {
  final digits = value.abs().toString();
  final buffer = StringBuffer(value < 0 ? '-' : '');
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

/// Pounds in a kilogram (the international avoirdupois pound).
const double _poundsPerKilogram = 2.20462262185;

/// Formats [kg] in [unit] to one decimal place, as a value and its unit
/// label: `('82.4', 'kg')`, `('181.7', 'lb')`, or for stones `('12 st 13.7',
/// 'lb')`.
({String value, String unit}) formatWeight(double kg, WeightUnit unit) {
  switch (unit) {
    case WeightUnit.kilograms:
      return (value: kg.toStringAsFixed(1), unit: 'kg');
    case WeightUnit.pounds:
      return (value: (kg * _poundsPerKilogram).toStringAsFixed(1), unit: 'lb');
    case WeightUnit.stones:
      // Whole tenths of a pound first, so 13.96 lb rounds up to the next
      // stone instead of showing "14.0 lb".
      final tenths = (kg * _poundsPerKilogram * 10).round();
      final stones = tenths ~/ 140;
      final pounds = (tenths % 140) / 10;
      return (value: '$stones st ${pounds.toStringAsFixed(1)}', unit: 'lb');
  }
}
