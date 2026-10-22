import 'dart:async';

import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
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

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          accountStatusRepositoryProvider.overrideWithValue(repository),
        ],
        child: ShadcnApp(
          theme: steadyTheme,
          home: SignInModule(onOpenSettings: () => openSettingsCount++),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  String title(WidgetTester tester) =>
      tester.widget<Text>(find.byKey(const Key('signIn_title'))).data!;

  final checkAgain = find.byKey(const Key('signInButton_checkAgain'));
  final openSettings = find.byKey(const Key('signInButton_openSettings'));

  group('SignInModule copy', () {
    testWidgets('noAccount says what is wrong and how to fix it', (
      tester,
    ) async {
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      await pump(tester);

      expect(title(tester), 'Sign in to iCloud');
      expect(
        find.textContaining('needs to be signed in to iCloud'),
        findsOneWidget,
      );
      expect(find.textContaining('Sign in to your iPhone'), findsOneWidget);
      expect(find.text('Open Settings'), findsOneWidget);
      expect(find.text('Check again'), findsOneWidget);
    });

    testWidgets('on macOS, noAccount points to System Settings', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      addTearDown(() => debugDefaultTargetPlatformOverride = null);
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      await pump(tester);

      expect(find.textContaining('this Mac needs'), findsOneWidget);
      expect(find.textContaining('Open System Settings'), findsOneWidget);
      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('restricted explains the restriction without blame', (
      tester,
    ) async {
      repository.onAccountStatus = () => const Ok(AccountStatus.restricted);
      await pump(tester);

      expect(title(tester), 'iCloud is turned off on this device');
      expect(find.textContaining('Screen Time'), findsNWidgets(2));
    });

    const titles = {
      AccountStatus.temporarilyUnavailable: "iCloud isn't ready yet",
      AccountStatus.couldNotDetermine: "Couldn't reach iCloud",
      AccountStatus.notConfigured: "iCloud isn't set up in this build",
      AccountStatus.available: "You're signed in",
    };
    for (final MapEntry(key: status, value: expected) in titles.entries) {
      testWidgets('${status.name} has its own title', (tester) async {
        repository.onAccountStatus = () => Ok(status);
        await pump(tester);

        expect(title(tester), expected);
        expect(find.byKey(const Key('signIn_steps')), findsNothing);
      });
    }

    testWidgets('a Failure is shown in plain words', (tester) async {
      repository.onAccountStatus = () =>
          const Err(PlatformChannelFailure('channel down'));
      await pump(tester);

      expect(title(tester), "Couldn't reach iCloud");
      expect(find.textContaining('channel down'), findsOneWidget);
    });
  });

  group('SignInModule buttons', () {
    testWidgets('"Check again" re-reads the account status', (tester) async {
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      await pump(tester);
      expect(repository.accountStatusCalls, 1);

      repository.onAccountStatus = () => const Ok(AccountStatus.available);
      await tester.tap(checkAgain);
      await tester.pumpAndSettle();

      expect(repository.accountStatusCalls, 2);
      expect(title(tester), "You're signed in");
    });

    testWidgets('"Check again" is disabled while a read is in flight', (
      tester,
    ) async {
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      await pump(tester);

      final read = Completer<Result<AccountStatus>>();
      repository.onAccountStatus = () => read.future;
      await tester.tap(checkAgain);
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.widget<OutlineButton>(checkAgain).onPressed, isNull);
      await tester.tap(checkAgain, warnIfMissed: false);

      read.complete(const Ok(AccountStatus.noAccount));
      await tester.pumpAndSettle();

      expect(repository.accountStatusCalls, 2);
      expect(tester.widget<OutlineButton>(checkAgain).onPressed, isNotNull);
    });

    testWidgets('"Open Settings" calls onOpenSettings', (tester) async {
      repository.onAccountStatus = () => const Ok(AccountStatus.noAccount);
      await pump(tester);

      await tester.tap(openSettings);
      await tester.pumpAndSettle();

      expect(openSettingsCount, 1);
      // The module leaves opening Settings to the app layer.
      expect(repository.openAccountSettingsCalls, 0);
    });
  });
}
