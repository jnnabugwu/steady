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
class SteadyApp extends ConsumerWidget {
  /// Creates the root widget. Must sit under a `ProviderScope`.
  const SteadyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ShadcnApp.router(
      title: 'Steady',
      theme: steadyTheme,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
