import 'package:daily_metrics_domain/daily_metrics_domain.dart';

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
