/// Health sync data layer: the `steady/healthkit` platform channel (iOS
/// only), and an in-memory implementation for tests.
library;

export 'src/health_kit_wire.dart'
    show HealthKitChannel, formatHealthDate, parseHealthDate;
export 'src/in_memory_health_kit_repository.dart';
export 'src/method_channel_health_kit_repository.dart';
