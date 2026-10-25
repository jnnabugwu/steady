import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:account_presentation/account_presentation.dart';
import 'package:checkin_presentation/checkin_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/app_router.dart';
import 'package:steady/health_access.dart';
import 'package:steady/pdfium.dart';
import 'package:steady/providers.dart';
import 'package:steady/remote_changes.dart';
import 'package:ui_kit/ui_kit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  configurePdfium();
  // Built before runApp so the one-time migration below writes through the
  // same shared repository instance the app then uses.
  final container = ProviderContainer(
    overrides: [
      ...appProviderOverrides,
      dailyMetricStoreProvider.overrideWithValue(DailyMetricStore.swiftData),
    ],
  );
  await _migrateInterimFileStore(container);
  await _clearLegacyHealthFields(container);
  runApp(
    UncontrolledProviderScope(container: container, child: const SteadyApp()),
  );
}

/// Moves rows from the interim JSON file store into SwiftData, once (the
/// file is renamed afterwards). Any failure, including the support
/// directory lookup throwing, is logged, not fatal: the app still starts,
/// and the file is left in place, so the next launch retries.
Future<void> _migrateInterimFileStore(ProviderContainer container) async {
  final Result<int> result;
  try {
    final supportDir = await getApplicationSupportDirectory();
    result = await migrateFileStore(
      File('${supportDir.path}/daily_metrics.json'),
      container.read(dailyMetricRepositoryProvider),
    );
  } on Object catch (error, stackTrace) {
    developer.log(
      'Daily metrics migration failed',
      name: 'steady',
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }
  switch (result) {
    case Ok(value: 0):
      break;
    case Ok(:final value):
      developer.log('Migrated $value rows into SwiftData', name: 'steady');
    case Err(:final failure):
      developer.log(
        'Daily metrics migration failed: ${failure.message}',
        name: 'steady',
        error: failure.cause ?? failure,
      );
  }
}

/// Removes Apple Health values an older build stored in the iCloud-synced
/// store (`clearLegacyHealthFields`; App Store 5.1.3(ii)). Runs on every
/// launch, after the file migration so anything it copied is cleaned too:
/// once the store is clean it's one range read and no writes. Only on the
/// SwiftData store (iOS and macOS, CloudKit-backed); the in-memory store
/// has nothing an older build could have left. Any failure is logged, not
/// fatal, and the next launch retries.
Future<void> _clearLegacyHealthFields(ProviderContainer container) async {
  if (!Platform.isIOS && !Platform.isMacOS) return;
  if (container.read(dailyMetricStoreProvider) != DailyMetricStore.swiftData) {
    return;
  }
  final Result<int> result;
  try {
    result = await clearLegacyHealthFields(
      container.read(dailyMetricRepositoryProvider),
    );
  } on Object catch (error, stackTrace) {
    developer.log(
      'Clearing stored Apple Health values failed',
      name: 'steady',
      error: error,
      stackTrace: stackTrace,
    );
    return;
  }
  switch (result) {
    case Ok(value: 0):
      break;
    case Ok(:final value):
      developer.log(
        'Cleared stored Apple Health values from $value rows',
        name: 'steady',
      );
    case Err(:final failure):
      developer.log(
        'Clearing stored Apple Health values failed: ${failure.message}',
        name: 'steady',
        error: failure.cause ?? failure,
      );
  }
}

/// Root widget. DI is wired by the `ProviderScope` in [main] (see
/// `providers.dart`); routing comes from [routerProvider] (see
/// `app_router.dart`).
///
/// Also re-checks the iCloud account status whenever the app returns to the
/// foreground: the user may have just signed in (or out) in Settings. This
/// lives at the app root rather than in the banner, so a change made while
/// Steady is in the background is caught on any screen. The status never
/// redirects (CLAUDE.md §7); it only shows or hides the home screen's
/// iCloud sync banner.
///
/// It also rolls "today" (`checkInTodayProvider`) over to the new day, from
/// a timer set for the next local midnight and on every return to the
/// foreground, so the Today screen and its date-keyed cards don't stay on
/// yesterday when left open overnight.
///
/// It also starts [dailyMetricsRemoteRefreshProvider], so screens re-read
/// the store when CloudKit syncs in another device's rows (#73).
///
/// It also refreshes Apple Health (iOS only, `health_access.dart`) once at
/// launch and again on every return to the foreground: the first time it
/// asks for read permission, and every time it makes the screens showing
/// Health values read them live again, so today's steps stay current.
/// Nothing is synced or stored. Fire-and-forget: it never blocks the first
/// frame, and a failure is logged by the controller, not thrown. On macOS
/// Health isn't bound, so the call is a no-op.
class SteadyApp extends ConsumerStatefulWidget {
  /// Creates the root widget. Must sit under a `ProviderScope`.
  const SteadyApp({super.key});

  @override
  ConsumerState<SteadyApp> createState() => _SteadyAppState();
}

class _SteadyAppState extends ConsumerState<SteadyApp> {
  late final AppLifecycleListener _lifecycle;
  Timer? _midnight;

  @override
  void initState() {
    super.initState();
    // keepAlive, so one read keeps it listening for the app's lifetime.
    ref.read(dailyMetricsRemoteRefreshProvider);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        unawaited(
          ref.read(accountStatusControllerProvider.notifier).recheckAccount(),
        );
        _refreshHealth();
        _rollOverDay();
      },
    );
    _refreshHealth();
    _scheduleMidnight();
  }

  /// Moves `checkInTodayProvider` to the new day if the date has changed,
  /// then sets the timer for the next midnight again.
  void _rollOverDay() {
    ref.read(checkInTodayProvider.notifier).refreshToday();
    _scheduleMidnight();
  }

  /// Rolls the day over at the next local midnight, so a Today screen left
  /// open overnight moves to the new date. Owned by this widget, so it ends
  /// with the app.
  void _scheduleMidnight() {
    _midnight?.cancel();
    _midnight = Timer(
      ref.read(checkInTodayProvider.notifier).untilNextMidnight(),
      _rollOverDay,
    );
  }

  void _refreshHealth() => unawaited(
    ref.read(healthAccessControllerProvider.notifier).refreshHealthData(),
  );

  @override
  void dispose() {
    _midnight?.cancel();
    _lifecycle.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadcnApp.router(
      title: 'Steady',
      theme: steadyTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
