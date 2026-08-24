import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/bootstrap.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  configureDependencies();
  runApp(const SteadyApp());
}

/// Root widget. No routing/DI wiring yet (see `app_router.dart` /
/// `bootstrap.dart`) — this proves the design system compiles and renders
/// on both platform targets, per the ui_kit build step.
class SteadyApp extends StatelessWidget {
  const SteadyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const ShadcnApp(
      title: 'Steady',
      theme: steadyTheme,
      home: _DesignSystemPreview(),
    );
  }
}

class _DesignSystemPreview extends StatelessWidget {
  const _DesignSystemPreview();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      headers: [
        AppBar(title: Text('Steady')),
      ],
      child: Center(
        child: SteadyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Today', style: SteadyType.headline),
              SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  MetricAccentChip(
                    accent: MetricAccent.caloriesEaten,
                    label: 'Eaten',
                  ),
                  SizedBox(width: 8),
                  MetricAccentChip(
                    accent: MetricAccent.caloriesBurned,
                    label: 'Burned',
                  ),
                  SizedBox(width: 8),
                  MetricAccentChip(accent: MetricAccent.steps, label: 'Steps'),
                ],
              ),
              SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  LoggingStatusIndicator(status: LoggingStatus.logged),
                  SizedBox(width: 6),
                  LoggingStatusIndicator(status: LoggingStatus.partial),
                  SizedBox(width: 6),
                  LoggingStatusIndicator(status: LoggingStatus.skipped),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
