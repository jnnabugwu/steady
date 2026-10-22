import 'dart:async';

import 'package:account_data/account_data.dart';
import 'package:account_domain/account_domain.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:steady/app_router.dart';
import 'package:steady/design_system_preview.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';

/// The iCloud account gate (#53), end to end: the real
/// [appProviderOverrides] (so the real `MethodChannelAccountStatusRepository`)
/// with the `steady/account` platform channel mocked at the messenger, the
/// way the Swift side would answer.
void main() {
  const channel = MethodChannel(AccountChannel.name);

  /// What the mocked native side answers to `accountStatus`. A [Completer]
  /// holds the answer back, to observe the loading state.
  late FutureOr<Object?> Function() nativeStatus;
  late List<String> nativeCalls;

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  setUp(() {
    nativeCalls = [];
    nativeStatus = () => 'available';
    messenger().setMockMethodCallHandler(channel, (call) async {
      nativeCalls.add(call.method);
      return switch (call.method) {
        AccountChannel.accountStatusMethod => await nativeStatus(),
        _ => null,
      };
    });
  });

  tearDown(() => messenger().setMockMethodCallHandler(channel, null));

  Future<ProviderContainer> pumpApp(
    WidgetTester tester, {
    String? coldStartLocation,
    bool settle = true,
  }) async {
    if (coldStartLocation != null) {
      tester.platformDispatcher.defaultRouteNameTestValue = coldStartLocation;
      addTearDown(tester.platformDispatcher.clearDefaultRouteNameTestValue);
    }
    await tester.pumpWidget(
      ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
    );
    if (settle) await tester.pumpAndSettle();
    return ProviderScope.containerOf(tester.element(find.byType(SteadyApp)));
  }

  final home = find.byType(DesignSystemPreview);
  final signIn = find.byType(SignInModule);
  final checkAgain = find.byKey(const Key('signInButton_checkAgain'));

  String location(ProviderContainer container) =>
      container.read(routerProvider).state.uri.toString();

  Future<void> resumeApp(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  group('cold start at /', () {
    testWidgets('noAccount goes to /sign-in', (tester) async {
      nativeStatus = () => 'noAccount';
      final container = await pumpApp(tester);

      expect(signIn, findsOneWidget);
      expect(home, findsNothing);
      expect(location(container), '/sign-in');
      expect(find.text('Sign in to iCloud'), findsOneWidget);
    });

    testWidgets('restricted goes to /sign-in', (tester) async {
      nativeStatus = () => 'restricted';
      await pumpApp(tester);

      expect(signIn, findsOneWidget);
    });

    testWidgets('available stays home', (tester) async {
      final container = await pumpApp(tester);

      expect(home, findsOneWidget);
      expect(signIn, findsNothing);
      expect(location(container), '/');
    });

    for (final status in [
      'notConfigured',
      'couldNotDetermine',
      'temporarilyUnavailable',
      'someFutureStatus',
    ]) {
      testWidgets('$status stays home, never sign-in', (tester) async {
        nativeStatus = () => status;
        await pumpApp(tester);

        expect(home, findsOneWidget);
        expect(signIn, findsNothing);
      });
    }

    testWidgets('a channel error stays home', (tester) async {
      nativeStatus = () =>
          throw PlatformException(code: 'E_CK', message: 'CloudKit down');
      await pumpApp(tester);

      expect(home, findsOneWidget);
      expect(signIn, findsNothing);
    });

    testWidgets('no native handler at all stays home', (tester) async {
      messenger().setMockMethodCallHandler(channel, null);
      await pumpApp(tester);

      expect(home, findsOneWidget);
      expect(signIn, findsNothing);
    });

    testWidgets('loading never redirects; the settled status does', (
      tester,
    ) async {
      final answer = Completer<Object?>();
      nativeStatus = () => answer.future;
      final container = await pumpApp(tester, settle: false);
      await tester.pump();

      expect(container.read(accountStatusControllerProvider).isLoading, isTrue);
      expect(home, findsOneWidget);
      expect(signIn, findsNothing);

      answer.complete('noAccount');
      await tester.pumpAndSettle();

      expect(signIn, findsOneWidget);
    });
  });

  group('deep links', () {
    testWidgets('/checkin/<date> with noAccount goes to /sign-in', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      final container = await pumpApp(
        tester,
        coldStartLocation: '/checkin/2026-10-19',
      );

      expect(signIn, findsOneWidget);
      expect(find.byType(CheckInModule), findsNothing);
      expect(location(container), '/sign-in');
    });

    testWidgets('/checkin/<date> with available opens the check-in', (
      tester,
    ) async {
      await pumpApp(tester, coldStartLocation: '/checkin/2026-10-19');

      expect(find.byType(CheckInModule), findsOneWidget);
    });

    testWidgets('/checkin/<date> with notConfigured opens the check-in', (
      tester,
    ) async {
      nativeStatus = () => 'notConfigured';
      await pumpApp(tester, coldStartLocation: '/checkin/2026-10-19');

      expect(find.byType(CheckInModule), findsOneWidget);
      expect(signIn, findsNothing);
    });

    for (final status in ['available', 'notConfigured']) {
      testWidgets('malformed /checkin/garbage still goes home ($status)', (
        tester,
      ) async {
        nativeStatus = () => status;
        await pumpApp(tester, coldStartLocation: '/checkin/garbage');

        expect(tester.takeException(), isNull);
        expect(home, findsOneWidget);
        expect(find.byType(CheckInModule), findsNothing);
      });
    }

    testWidgets('malformed /checkin/garbage with noAccount goes to sign-in', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester, coldStartLocation: '/checkin/garbage');

      expect(tester.takeException(), isNull);
      expect(signIn, findsOneWidget);
    });

    testWidgets('/sign-in with notConfigured goes home', (tester) async {
      nativeStatus = () => 'notConfigured';
      final container = await pumpApp(tester, coldStartLocation: '/sign-in');

      expect(home, findsOneWidget);
      expect(location(container), '/');
    });
  });

  group('status changes', () {
    testWidgets('flipping to available on /sign-in goes home ("Check again")', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      final container = await pumpApp(tester);
      final router = container.read(routerProvider);
      expect(signIn, findsOneWidget);

      nativeStatus = () => 'available';
      await tester.tap(checkAgain);
      await tester.pumpAndSettle();

      expect(home, findsOneWidget);
      expect(signIn, findsNothing);
      expect(location(container), '/');
      // The redirect re-ran through refreshListenable; the router itself
      // was not rebuilt.
      expect(container.read(routerProvider), same(router));
    });

    testWidgets('a still-signed-out re-check stays on /sign-in', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester);

      await tester.tap(checkAgain);
      await tester.pumpAndSettle();

      expect(signIn, findsOneWidget);
      expect(nativeCalls.where((m) => m == 'accountStatus'), hasLength(2));
    });

    testWidgets('a failed re-check on /sign-in stays there', (tester) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester);

      nativeStatus = () => throw PlatformException(code: 'E_CK');
      await tester.tap(checkAgain);
      await tester.pumpAndSettle();

      expect(signIn, findsOneWidget);
      expect(find.text("Couldn't reach iCloud"), findsOneWidget);
    });

    testWidgets('returning to the foreground re-checks and goes home', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester);
      expect(signIn, findsOneWidget);

      // The user signed in from Settings and came back.
      nativeStatus = () => 'available';
      await resumeApp(tester);

      expect(home, findsOneWidget);
      expect(nativeCalls.where((m) => m == 'accountStatus'), hasLength(2));
    });

    testWidgets('signing out while in the background is caught on resume', (
      tester,
    ) async {
      await pumpApp(tester);
      expect(home, findsOneWidget);

      nativeStatus = () => 'noAccount';
      await resumeApp(tester);

      expect(signIn, findsOneWidget);
    });
  });

  testWidgets('"Open Settings" asks the native side to open them', (
    tester,
  ) async {
    nativeStatus = () => 'noAccount';
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('signInButton_openSettings')));
    await tester.pumpAndSettle();

    expect(nativeCalls, contains(AccountChannel.openAccountSettingsMethod));
  });

  testWidgets('a failed "Open Settings" is reported, not dropped', (
    tester,
  ) async {
    nativeStatus = () => 'noAccount';
    messenger().setMockMethodCallHandler(channel, (call) async {
      if (call.method == AccountChannel.openAccountSettingsMethod) {
        throw PlatformException(code: 'E_OPEN', message: 'no pane');
      }
      return 'noAccount';
    });
    await pumpApp(tester);

    await tester.tap(find.byKey(const Key('signInButton_openSettings')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isA<Exception>());
  });

  group('redirectForAccount', () {
    final locations = [
      '/',
      '/sign-in',
      '/checkin/2026-10-19',
      '/checkin/garbage',
    ];

    String? redirect(String location, AsyncValue<AccountStatus> status) =>
        redirectForAccount(Uri.parse(location), status);

    test('noAccount and restricted send every other location to /sign-in', () {
      for (final status in [
        AccountStatus.noAccount,
        AccountStatus.restricted,
      ]) {
        for (final location in locations) {
          expect(
            redirect(location, AsyncData(status)),
            location == '/sign-in' ? isNull : '/sign-in',
            reason: '$status at $location',
          );
        }
      }
    });

    test('non-blocking statuses never send anyone to /sign-in', () {
      for (final status in [
        AccountStatus.available,
        AccountStatus.notConfigured,
        AccountStatus.couldNotDetermine,
        AccountStatus.temporarilyUnavailable,
      ]) {
        for (final location in locations.where((l) => l != '/sign-in')) {
          expect(
            redirect(location, AsyncData(status)),
            isNull,
            reason: '$status at $location',
          );
        }
      }
    });

    test('/sign-in is left for / only once nothing needs signing in to', () {
      expect(
        redirect('/sign-in', const AsyncData(AccountStatus.available)),
        '/',
      );
      expect(
        redirect('/sign-in', const AsyncData(AccountStatus.notConfigured)),
        '/',
      );
      expect(
        redirect('/sign-in', const AsyncData(AccountStatus.couldNotDetermine)),
        isNull,
      );
      expect(
        redirect(
          '/sign-in',
          const AsyncData(AccountStatus.temporarilyUnavailable),
        ),
        isNull,
      );
    });

    test(
      'loading and error never redirect, even with a previous value',
      () async {
        // Real states from the controller, not hand-built ones: a re-check
        // after noAccount is loading-with-previous, and a failed re-check
        // is error-with-previous.
        final repository = InMemoryAccountStatusRepository(
          status: AccountStatus.noAccount,
        );
        final container = ProviderContainer.test(
          overrides: [
            accountStatusRepositoryProvider.overrideWithValue(repository),
          ],
        );
        await container.read(accountStatusControllerProvider.future);
        final notifier = container.read(
          accountStatusControllerProvider.notifier,
        );

        final pending = notifier.recheckAccount();
        final loadingWithPrevious = container.read(
          accountStatusControllerProvider,
        );
        await pending;
        repository.failure = const PlatformChannelFailure('down');
        await notifier.recheckAccount();
        final errorWithPrevious = container.read(
          accountStatusControllerProvider,
        );

        expect(loadingWithPrevious, isA<AsyncLoading<AccountStatus>>());
        expect(loadingWithPrevious.value, AccountStatus.noAccount);
        expect(errorWithPrevious, isA<AsyncError<AccountStatus>>());
        expect(errorWithPrevious.value, AccountStatus.noAccount);

        for (final location in locations) {
          expect(redirect(location, const AsyncLoading()), isNull);
          expect(redirect(location, loadingWithPrevious), isNull);
          expect(
            redirect(location, AsyncError(Exception('down'), StackTrace.empty)),
            isNull,
          );
          expect(redirect(location, errorWithPrevious), isNull);
        }
      },
    );
  });
}
