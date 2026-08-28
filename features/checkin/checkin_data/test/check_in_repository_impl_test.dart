import 'package:checkin_data/checkin_data.dart';
import 'package:checkin_domain/checkin_domain.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CheckInRepositoryImpl', () {
    test('logCheckIn then getStatus round-trips', () async {
      final repo = CheckInRepositoryImpl(InMemoryDailyMetricRepository());
      final date = DateTime(2026, 8, 24);

      await repo.logCheckIn(date, CheckInStatus.partial);
      final result = await repo.getStatus(date);

      expect((result as Ok<CheckInStatus?>).value, CheckInStatus.partial);
    });

    test('getStatus on an untouched date returns Ok(null)', () async {
      final repo = CheckInRepositoryImpl(InMemoryDailyMetricRepository());
      final result = await repo.getStatus(DateTime(2026, 8, 24));
      expect((result as Ok<CheckInStatus?>).value, isNull);
    });
  });
}
