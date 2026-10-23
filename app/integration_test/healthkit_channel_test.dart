import 'dart:io';

import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:health_sync_data/health_sync_data.dart';
import 'package:health_sync_domain/health_sync_domain.dart';
import 'package:integration_test/integration_test.dart';

/// The real `steady/healthkit` channel (`ios/Runner/HealthKitChannel.swift`)
/// on an iOS simulator or device. iOS only: there's no macOS handler.
///
/// Needs no Health permission and never shows the permission sheet, which
/// an integration test can't tap through. On a fresh install it checks the
/// channel is registered and answers in the documented shapes; if the
/// sheet was already answered on this device, it also checks `dailyTotals`
/// returns one row per local day.
///
/// `flutter test integration_test/healthkit_channel_test.dart -d <simulator id>`
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final repository = MethodChannelHealthKitRepository();
  final today = DateTime.now();
  final start = DateTime(today.year, today.month, today.day - 6);

  testWidgets(
    'answers isAvailable, authorizationStatus and dailyTotals',
    skip: !Platform.isIOS,
    (_) async {
      final available = await repository.isAvailable();
      expect(available, isA<Ok<bool>>());
      expect((available as Ok<bool>).value, isTrue);

      final status = await repository.authorizationStatus();
      expect(status, isA<Ok<HealthAuthorizationStatus>>());

      final totals = await repository.dailyTotals(start, today);
      final value = (status as Ok<HealthAuthorizationStatus>).value;
      debugPrint('steady/healthkit authorizationStatus: $value');
      switch (value) {
        case HealthAuthorizationStatus.notDetermined:
          // Before the sheet, HealthKit refuses the query.
          expect(totals, isA<Err<List<HealthDayTotals>>>());
          final failure = (totals as Err<List<HealthDayTotals>>).failure;
          expect(failure, isA<PlatformChannelFailure>());
          expect(
            (failure as PlatformChannelFailure).code,
            HealthKitChannel.authorizationNotDeterminedCode,
          );
        case HealthAuthorizationStatus.requested:
          expect(totals, isA<Ok<List<HealthDayTotals>>>());
          final days = (totals as Ok<List<HealthDayTotals>>).value;
          expect(days.map((d) => d.date), [
            for (var i = 0; i < 7; i++)
              DateTime(start.year, start.month, start.day + i),
          ]);
        case HealthAuthorizationStatus.unavailable:
          fail('isAvailable was true');
      }
    },
  );
}
