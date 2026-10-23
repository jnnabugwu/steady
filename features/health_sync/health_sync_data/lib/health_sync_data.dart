/// Health sync data layer: the `steady/healthkit` platform channel (iOS
/// only).
library;

export 'src/health_kit_wire.dart'
    show HealthKitChannel, formatHealthDate, parseHealthDate;
export 'src/method_channel_health_kit_repository.dart';
