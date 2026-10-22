import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:account_presentation/account_presentation.dart';
import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/app_router.dart';
import 'package:steady/pdfium.dart';
import 'package:steady/providers.dart';
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

/// Root widget. DI is wired by the `ProviderScope` in [main] (see
/// `providers.dart`); routing comes from [routerProvider] (see
/// `app_router.dart`).
///
/// Also re-checks the iCloud account status whenever the app returns to the
/// foreground: the user may have just signed in (or out) in Settings. This
/// lives at the app root rather than in `SignInModule`, so signing out
/// while Steady is in the background is caught on any screen, and the
/// router's redirect then moves the user.
class SteadyApp extends ConsumerStatefulWidget {
  /// Creates the root widget. Must sit under a `ProviderScope`.
  const SteadyApp({super.key});

  @override
  ConsumerState<SteadyApp> createState() => _SteadyAppState();
}

class _SteadyAppState extends ConsumerState<SteadyApp> {
  late final AppLifecycleListener _lifecycle;

  @override
  void initState() {
    super.initState();
    _lifecycle = AppLifecycleListener(
      onResume: () => unawaited(
        ref.read(accountStatusControllerProvider.notifier).recheckAccount(),
      ),
    );
  }

  @override
  void dispose() {
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
