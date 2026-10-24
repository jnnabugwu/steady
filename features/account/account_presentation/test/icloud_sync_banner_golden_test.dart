import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_account_status_repository.dart';
import 'helpers/golden.dart';

/// The banner's golden surface: phone width, banner height plus room.
const bannerGoldenSize = Size(390, 200);

/// Pumps the banner for [status] at [bannerGoldenSize].
Future<void> pumpBannerGolden(WidgetTester tester, AccountStatus status) async {
  await loadGoldenFonts();
  useGoldenSurface(tester, size: bannerGoldenSize);
  final repository = FakeAccountStatusRepository()
    ..onAccountStatus = () => Ok(status);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accountStatusRepositoryProvider.overrideWithValue(repository),
      ],
      child: ShadcnApp(
        theme: steadyTheme,
        home: Scaffold(
          child: Align(
            alignment: Alignment.topCenter,
            child: ICloudSyncBanner(onOpenSettings: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('ICloudSyncBanner goldens', skip: goldenSkip, () {
    for (final status in [
      AccountStatus.noAccount,
      AccountStatus.temporarilyUnavailable,
    ]) {
      testWidgets(status.name, (tester) async {
        await pumpBannerGolden(tester, status);
        await expectLater(
          find.byType(Scaffold),
          matchesGoldenFile('goldens/icloud_sync_banner_${status.name}.png'),
        );
      });
    }
  });
}
