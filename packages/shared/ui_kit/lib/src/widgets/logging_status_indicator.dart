import 'package:shadcn_flutter/shadcn_flutter.dart';

import '../design_tokens.dart';

/// The three-state check-in status ladder (CLAUDE.md §4:
/// `CheckInLogged`/`CheckInPartial`/`CheckInSkipped`) — cross-feature
/// vocabulary shared by `checkin` and `metrics`, kept here rather than in
/// either feature's presentation package. Deliberately single-hue, no
/// red/yellow/green (§1 non-goal: no shame visuals).
enum LoggingStatus { logged, partial, skipped }

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
