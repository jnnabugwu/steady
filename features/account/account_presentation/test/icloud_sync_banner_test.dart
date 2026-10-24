import 'dart:async';

import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

import 'helpers/fake_account_status_repository.dart';

void main() {
  late FakeAccountStatusRepository repository;
  late int openSettingsCount;

  setUp(() {
    repository = FakeAccountStatusRepository();
    openSettingsCount = 0;
  });

  Future<ProviderContainer> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusRepositoryProvider.overrideWithValue(repository),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: Scaffold(
            child: ICloudSyncBanner(onOpenSettings: () => openSettingsCount++),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return ProviderScope.containerOf(
      tester.element(find.byType(ICloudSyncBanner)),
    );
  }

  final banner = find.byKey(const Key('iCloudBanner'));
  const body =
      "Your data stays on this device and won't sync to your other devices.";

  group('shown when iCloud is not syncing', () {
    for (final (status, headline) in [
      (AccountStatus.noAccount, 'Not signed into iCloud.'),
      (AccountStatus.restricted, 'iCloud is turned off on this device.'),
      (
        AccountStatus.temporarilyUnavailable,
        "iCloud isn't available right now.",
      ),
    ]) {
      testWidgets(status.name, (tester) async {
        repository.onAccountStatus = () => Ok(status);
        await pump(tester);

        expect(banner, findsOneWidget);
        expect(find.text(headline), findsOneWidget);
        expect(find.text(body), findsOneWidget);
        expect(find.text('Open Settings'), findsOneWidget);
      });
    }
  });

  group('hidden', () {
    for (final status in [
      AccountStatus.available,
      AccountStatus.notConfigured,
      AccountStatus.couldNotDetermine,
    ]) {
      testWidgets('for ${status.name}', (tester) async {
        repository.onAccountStatus = () => Ok(status);
        await pump(tester);

        expect(banner, findsNothing);
      });
    }

    testWidgets('while the first read is loading', (tester) async {
      final answer = Completer<Result<AccountStatus>>();
      repository.onAccountStatus = () => answer.future;
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            accountStatusRepositoryProvider.overrideWithValue(repository),
          ],
          child: ShadcnApp(
            theme: steadyTheme,
            home: Scaffold(child: ICloudSyncBanner(onOpenSettings: () {})),
          ),
        ),
      );
      await tester.pump();

      expect(banner, findsNothing);
      answer.complete(const Ok(AccountStatus.noAccount));
      await tester.pumpAndSettle();
      expect(banner, findsOneWidget);
    });

    testWidgets('when the first read fails', (tester) async {
      repository.onAccountStatus = () =>
          const Err(PlatformChannelFailure('down'));
      await pump(tester);

      expect(banner, findsNothing);
    });
  });

  testWidgets('"Open Settings" calls onOpenSettings', (tester) async {
    repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
    await pump(tester);

    await tester.tap(find.byKey(const Key('iCloudBannerButton_openSettings')));
    await tester.pumpAndSettle();

    expect(openSettingsCount, 1);
  });

  // No tester.ensureSemantics(): testWidgets enables semantics by default
  // (semanticsEnabled) and owns that handle, so nothing leaks when an
  // expectation fails. A handle of our own can't be disposed via
  // addTearDown: the undisposed-handle check runs before tear-downs.
  testWidgets('the dismiss button is announced as "Dismiss"', (tester) async {
    repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
    await pump(tester);

    expect(
      tester.getSemantics(find.byKey(const Key('iCloudBannerButton_dismiss'))),
      matchesSemantics(
        label: 'Dismiss',
        isButton: true,
        hasEnabledState: true,
        isEnabled: true,
        hasTapAction: true,
        isFocusable: true,
        hasFocusAction: true,
      ),
    );
  });

  testWidgets('dismissing hides it for the session, even after a re-check', (
    tester,
  ) async {
    repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
    final container = await pump(tester);

    await tester.tap(find.byKey(const Key('iCloudBannerButton_dismiss')));
    await tester.pumpAndSettle();

    expect(banner, findsNothing);
    expect(container.read(iCloudBannerDismissalProvider), isTrue);

    await container
        .read(accountStatusControllerProvider.notifier)
        .recheckAccount();
    await tester.pumpAndSettle();

    expect(banner, findsNothing);
  });

  testWidgets('disappears when a re-check finds iCloud available', (
    tester,
  ) async {
    repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
    final container = await pump(tester);
    expect(banner, findsOneWidget);

    repository.onAccountStatus = () => const Ok(AccountStatus.available);
    await container
        .read(accountStatusControllerProvider.notifier)
        .recheckAccount();
    await tester.pumpAndSettle();

    expect(banner, findsNothing);
  });

  testWidgets('stays up (no flicker) while a re-check is loading', (
    tester,
  ) async {
    repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
    final container = await pump(tester);

    final answer = Completer<Result<AccountStatus>>();
    repository.onAccountStatus = () => answer.future;
    final pending = container
        .read(accountStatusControllerProvider.notifier)
        .recheckAccount();
    await tester.pump();

    expect(banner, findsOneWidget);
    answer.complete(const Ok(AccountStatus.noAccount));
    await pending;
  });

  test('ICloudBannerDismissal starts false and dismissing sets it', () {
    final container = ProviderContainer.test();

    expect(container.read(iCloudBannerDismissalProvider), isFalse);
    container
        .read(iCloudBannerDismissalProvider.notifier)
        .dismissICloudBanner();
    expect(container.read(iCloudBannerDismissalProvider), isTrue);
  });
}
