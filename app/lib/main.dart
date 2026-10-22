import 'dart:async';

import 'package:account_presentation/account_presentation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/app_router.dart';
import 'package:steady/providers.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  runApp(
    ProviderScope(overrides: appProviderOverrides, child: const SteadyApp()),
  );
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
