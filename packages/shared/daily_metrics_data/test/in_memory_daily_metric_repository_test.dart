import 'package:daily_metrics_data/daily_metrics_data.dart';

import 'package:daily_metrics_data/testing/daily_metric_repository_contract.dart';

void main() {
  runDailyMetricRepositoryContractTests(InMemoryDailyMetricRepository.new);
}
