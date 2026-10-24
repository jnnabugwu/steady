import 'package:checkin_domain/checkin_domain.dart';
import 'package:ui_kit/ui_kit.dart';

/// Maps to `ui_kit`'s status ladder for the swatches and stones.
/// Presentation-only: `CheckInStatus` stays its own domain enum.
LoggingStatus loggingStatusFor(CheckInStatus status) => switch (status) {
  CheckInStatus.logged => LoggingStatus.logged,
  CheckInStatus.partial => LoggingStatus.partial,
  CheckInStatus.skipped => LoggingStatus.skipped,
};
