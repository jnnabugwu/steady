import 'package:checkin_domain/checkin_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:metrics_domain/metrics_domain.dart';
import 'package:notifications_domain/notifications_domain.dart';
import 'package:pdf_import_domain/pdf_import_domain.dart';
import 'package:steady/bootstrap.dart';

void main() {
  setUp(configureDependencies);
  tearDown(getIt.reset);

  test('every repository interface resolves', () {
    expect(getIt.isRegistered<DailyMetricRepository>(), isTrue);
    expect(getIt.isRegistered<CheckInRepository>(), isTrue);
    expect(getIt.isRegistered<MetricsRepository>(), isTrue);
    expect(getIt.isRegistered<PdfImportRepository>(), isTrue);
    expect(getIt.isRegistered<NotificationScheduler>(), isTrue);
  });

  test('checkin and daily_metrics share the same underlying store', () async {
    final date = DateTime(2026, 8, 24);
    await getIt<CheckInRepository>().logCheckIn(date, CheckInStatus.logged);

    final result = await getIt<DailyMetricRepository>().getByDate(date);
    final row = (result as Ok<DailyMetric?>).value;

    expect(row?.loggingStatus, LoggingStatus.logged);
  });
}
