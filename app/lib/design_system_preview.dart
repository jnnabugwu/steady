import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The current home screen: a preview proving the design system compiles
/// and renders on both platform targets, per the ui_kit build step. Served
/// at `/` by `HomeRoute` in `app_router.dart`.
class DesignSystemPreview extends StatelessWidget {
  /// Creates the design system preview.
  const DesignSystemPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      headers: const [AppBar(title: Text('Steady'))],
      child: Center(
        child: SteadyCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Today', style: SteadyType.headline),
              const SizedBox(height: 16),
              const Row(
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
              const SizedBox(height: 16),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Semantics(
                    label: 'Status: Logged',
                    child: const LoggingStatusIndicator(
                      status: LoggingStatus.logged,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    label: 'Status: Partial',
                    child: const LoggingStatusIndicator(
                      status: LoggingStatus.partial,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Semantics(
                    label: 'Status: Skipped',
                    child: const LoggingStatusIndicator(
                      status: LoggingStatus.skipped,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
