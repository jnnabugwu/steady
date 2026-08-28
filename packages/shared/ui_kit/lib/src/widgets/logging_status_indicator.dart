import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';

import 'package:ui_kit/src/design_tokens.dart';

// `LoggingStatus` is the single source of truth in `daily_metrics_domain`
// (it types `DailyMetric.loggingStatus`); re-exported here so callers that
// only depend on `ui_kit` can pass it straight to [LoggingStatusIndicator]
// without a second, identically-named enum to alias and map.
export 'package:daily_metrics_domain/daily_metrics_domain.dart'
    show LoggingStatus;

/// Renders the three-state check-in status ladder (CLAUDE.md §4:
/// `CheckInLogged`/`CheckInPartial`/`CheckInSkipped`). Deliberately
/// single-hue, no red/yellow/green (§1 non-goal: no shame visuals).
extension on LoggingStatus {
  Color get color => switch (this) {
    LoggingStatus.logged => SteadyColors.statusLogged,
    LoggingStatus.partial => SteadyColors.statusPartial,
    LoggingStatus.skipped => SteadyColors.statusSkipped,
  };
}

/// A small colored dot indicating check-in status for a single day, per
/// §10's 3–8px small-indicator scale.
class LoggingStatusIndicator extends StatelessWidget {
  const LoggingStatusIndicator({required this.status, super.key});

  final LoggingStatus status;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
      child: const SizedBox(
        width: SteadyRadii.indicator,
        height: SteadyRadii.indicator,
      ),
    );
  }
}
