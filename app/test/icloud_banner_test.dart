import 'dart:async';

import 'package:account_data/account_data.dart';
import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:metrics_presentation/metrics_presentation.dart';
import 'package:pdf_import_presentation/pdf_import_presentation.dart';
import 'package:steady/app_router.dart';
import 'package:steady/main.dart';
import 'package:steady/providers.dart';

/// iCloud is optional (CLAUDE.md §7): a banner, not a gate. End to end with
/// the real [appProviderOverrides] (so the real
/// `MethodChannelAccountStatusRepository`) and the `steady/account` platform
/// channel mocked at the messenger, the way the Swift side would answer.
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

  final home = find.byType(MetricsHistoryModule);
  final importScreen = find.byType(PdfImportModule);
  final banner = find.byKey(const Key('iCloudBanner'));
  final dismiss = find.byKey(const Key('iCloudBannerButton_dismiss'));
  final openSettings = find.byKey(const Key('iCloudBannerButton_openSettings'));

  String location(ProviderContainer container) =>
      container.read(routerProvider).state.uri.toString();

  Future<void> resumeApp(WidgetTester tester) async {
    tester.binding
      ..handleAppLifecycleStateChanged(AppLifecycleState.inactive)
      ..handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();
  }

  const allStatuses = [
    'available',
    'noAccount',
    'restricted',
    'temporarilyUnavailable',
    'couldNotDetermine',
    'notConfigured',
    'someFutureStatus',
  ];

  group('never redirects', () {
    for (final status in allStatuses) {
      testWidgets('cold start at / with $status stays home', (tester) async {
        nativeStatus = () => status;
        final container = await pumpApp(tester);

        expect(home, findsOneWidget);
        expect(location(container), '/');
      });

      testWidgets('/checkin/<date> with $status opens the check-in', (
        tester,
      ) async {
        nativeStatus = () => status;
        await pumpApp(tester, coldStartLocation: '/checkin/2026-10-19');

        expect(find.byType(CheckInModule), findsOneWidget);
      });

      testWidgets('/import with $status opens the import screen', (
        tester,
      ) async {
        nativeStatus = () => status;
        await pumpApp(tester, coldStartLocation: '/import');

        expect(importScreen, findsOneWidget);
      });
    }

    testWidgets('malformed /checkin/garbage with noAccount still goes home', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      final container = await pumpApp(
        tester,
        coldStartLocation: '/checkin/garbage',
      );

      expect(tester.takeException(), isNull);
      expect(home, findsOneWidget);
      expect(location(container), '/');
    });

    test('there is no /sign-in route', () {
      // Every route's full path, including those inside the app shell's
      // branches. Child paths are relative, so each is joined onto its
      // nearest GoRoute ancestor's path.
      String join(String parent, String child) {
        if (child.startsWith('/')) return child;
        final base = parent.endsWith('/') ? parent : '$parent/';
        return '$base$child';
      }

      Iterable<String> fullPaths(Iterable<RouteBase> routes, String parent) =>
          routes.expand((r) {
            final path = r is GoRoute ? join(parent, r.path) : parent;
            return [if (r is GoRoute) path, ...fullPaths(r.routes, path)];
          });
      final paths = fullPaths($appRoutes, '/').toList();

      expect(paths, isNot(contains('/sign-in')));
      expect(paths.where((p) => p.endsWith('sign-in')), isEmpty);
      expect(paths, contains('/'));
      expect(paths, contains('/checkin/:date'));
    });

    testWidgets('signing out while on the pushed import screen stays there', (
      tester,
    ) async {
      final container = await pumpApp(tester);
      await tester.tap(find.byKey(const Key('importButton_header')));
      await tester.pumpAndSettle();

      nativeStatus = () => 'noAccount';
      await resumeApp(tester);

      expect(importScreen, findsOneWidget);
      expect(location(container), '/import');
    });
  });

  group('banner on the home screen', () {
    for (final status in [
      'noAccount',
      'restricted',
      'temporarilyUnavailable',
    ]) {
      testWidgets('shown for $status', (tester) async {
        nativeStatus = () => status;
        await pumpApp(tester);

        expect(banner, findsOneWidget);
        expect(
          find.text(
            "Your data stays on this device and won't sync to your other "
            'devices.',
          ),
          findsOneWidget,
        );
      });
    }

    testWidgets('noAccount uses the "Not signed into iCloud." headline', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester);

      expect(find.text('Not signed into iCloud.'), findsOneWidget);
    });

    for (final status in [
      'available',
      'notConfigured',
      'couldNotDetermine',
      'someFutureStatus',
    ]) {
      testWidgets('hidden for $status', (tester) async {
        nativeStatus = () => status;
        await pumpApp(tester);

        expect(home, findsOneWidget);
        expect(banner, findsNothing);
      });
    }

    testWidgets('hidden when the channel errors', (tester) async {
      nativeStatus = () =>
          throw PlatformException(code: 'E_CK', message: 'CloudKit down');
      await pumpApp(tester);

      expect(home, findsOneWidget);
      expect(banner, findsNothing);
    });

    testWidgets('hidden while loading, shown once settled', (tester) async {
      final answer = Completer<Object?>();
      nativeStatus = () => answer.future;
      await pumpApp(tester, settle: false);
      await tester.pump();

      expect(home, findsOneWidget);
      expect(banner, findsNothing);

      answer.complete('noAccount');
      await tester.pumpAndSettle();

      expect(banner, findsOneWidget);
    });

    testWidgets('dismissing hides it for the session, also across screens', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      final container = await pumpApp(tester);

      await tester.tap(dismiss);
      await tester.pumpAndSettle();
      expect(banner, findsNothing);

      // Away to settings and back, and a resume re-check that's still
      // signed out: it stays dismissed.
      const SettingsRoute().go(tester.element(home));
      await tester.pumpAndSettle();
      container.read(routerProvider).go('/');
      await tester.pumpAndSettle();
      await resumeApp(tester);

      expect(home, findsOneWidget);
      expect(banner, findsNothing);
    });

    testWidgets('disappears after signing in and returning to the app', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester);
      expect(banner, findsOneWidget);

      // The user signed in from Settings and came back.
      nativeStatus = () => 'available';
      await resumeApp(tester);

      expect(banner, findsNothing);
      expect(home, findsOneWidget);
      expect(nativeCalls.where((m) => m == 'accountStatus'), hasLength(2));
    });

    testWidgets('appears after signing out in the background', (tester) async {
      await pumpApp(tester);
      expect(banner, findsNothing);

      nativeStatus = () => 'noAccount';
      await resumeApp(tester);

      expect(banner, findsOneWidget);
    });

    testWidgets('"Open Settings" asks the native side to open them', (
      tester,
    ) async {
      nativeStatus = () => 'noAccount';
      await pumpApp(tester);

      await tester.tap(openSettings);
      await tester.pumpAndSettle();

      expect(nativeCalls, contains(AccountChannel.openAccountSettingsMethod));
    });

    testWidgets('a failed "Open Settings" is reported, not dropped', (
      tester,
    ) async {
      messenger().setMockMethodCallHandler(channel, (call) async {
        if (call.method == AccountChannel.openAccountSettingsMethod) {
          throw PlatformException(code: 'E_OPEN', message: 'no pane');
        }
        return 'noAccount';
      });
      await pumpApp(tester);

      await tester.tap(openSettings);
      await tester.pumpAndSettle();

      expect(tester.takeException(), isA<Exception>());
    });
  });

  test('the dismissal starts false in a fresh container (next launch)', () {
    final container = ProviderContainer.test(overrides: appProviderOverrides);

    expect(container.read(iCloudBannerDismissalProvider), isFalse);
  });
}
