import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Opt-in: pushes the full DailyMetricRecord schema to the CloudKit
/// **development** environment of the signed build's container, through a
/// throwaway store (never the user's data), the same as Settings →
/// Developer → Initialize CloudKit schema (#93, `docs/cloudkit_schema.md`).
///
/// Skipped unless asked for, since it talks to real CloudKit:
///
/// `flutter test integration_test/cloudkit_schema_init_test.dart -d macos
/// --dart-define=RUN_CLOUDKIT_SCHEMA_INIT=true`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  const run = bool.fromEnvironment('RUN_CLOUDKIT_SCHEMA_INIT');

  testWidgets(
    'initializes the CloudKit development schema',
    (_) async {
      final result = await const DailyMetricsStoreDeveloperTools()
          .initializeCloudKitSchema();

      switch (result) {
        case Ok(:final value):
          // A real-run report: printing the result is the point.
          // ignore: avoid_print
          print('CloudKit schema initialized in ${value.containerIdentifier}');
          for (final type in value.recordTypes) {
            // Same: the printed report is the output.
            // ignore: avoid_print
            print('  $type');
          }
          expect(value.recordTypes.map((t) => t.name), [
            'CD_DailyMetricRecord',
          ]);
          expect(value.recordTypes.single.fields, {
            'CD_caloriesBurnedActive': 'Int(64)',
            'CD_caloriesBurnedBasal': 'Int(64)',
            'CD_caloriesEaten': 'Int(64)',
            'CD_day': 'String',
            'CD_entityName': 'String',
            'CD_loggingStatus': 'String',
            'CD_modifiedAt': 'Date/Time',
            'CD_steps': 'Int(64)',
          });
        case Err(:final failure):
          fail(
            'CloudKit schema initialization failed: $failure '
            '${failure.message}',
          );
      }
    },
    skip: !run,
    timeout: const Timeout(Duration(minutes: 3)),
  );
}
