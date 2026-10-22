import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:flutter/services.dart';

/// Test-only controls on the native `daily_metrics_store`, so integration
/// tests run against real SwiftData without touching the user's data.
///
/// Raw `PlatformException`s are allowed through here on purpose: a test
/// should fail loudly if it can't isolate itself.
abstract final class DailyMetricsStoreTestControl {
  static const _channel = MethodChannel(dailyMetricsStoreChannelName);

  /// Reopens the native store on the local test store [name]
  /// (`[A-Za-z0-9_-]+`). Test stores never use CloudKit. Always reopens,
  /// even for the same name, so calling it again reads back what actually
  /// reached disk. A null [name] switches back to the real store, which
  /// then opens lazily on its next use.
  static Future<void> useStore(String? name) =>
      _channel.invokeMethod<void>('useStore', {'name': name});

  /// Deletes every record in the current test store. Refused
  /// (`not_test_store`) on the real store, without opening it.
  static Future<void> reset() => _channel.invokeMethod<void>('reset');

  /// Inserts [row] as a separate record without de-duplicating, as if
  /// another device had created the same day. Refused on the real store.
  static Future<void> insertRecord(
    Map<String, Object?> row, {
    required DateTime modifiedAt,
  }) => _channel.invokeMethod<void>('insertRecordForTesting', {
    'row': row,
    'modifiedAtMillis': modifiedAt.millisecondsSinceEpoch,
  });
}
