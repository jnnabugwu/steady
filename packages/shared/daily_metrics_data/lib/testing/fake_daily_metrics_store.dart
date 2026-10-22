import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// A Dart stand-in for the native `daily_metrics_store` plugin, so
/// `SwiftDataDailyMetricRepository` can be tested without a device.
///
/// Mirrors the channel contract in `package:daily_metrics_store`: rows are
/// kept as the full maps `put` sends, keyed on their `yyyy-MM-dd` date;
/// `range` is inclusive and sorted. Rows survive [uninstall] / [install],
/// which is how a test simulates an app restart.
///
/// Test-only (needs a `TestDefaultBinaryMessengerBinding`).
class FakeDailyMetricsStore {
  /// The stored rows, by `yyyy-MM-dd` date.
  final Map<String, Map<String, Object?>> rows = {};

  /// Every method call received, in order.
  final List<MethodCall> calls = [];

  /// When set, the next call fails with a `PlatformException` of this code,
  /// and this is cleared.
  String? failNextWithCode;

  /// When set, every call replies with this value instead of its result.
  Object? Function(MethodCall call)? replyOverride;

  static const _channel = MethodChannel(dailyMetricsStoreChannelName);

  TestDefaultBinaryMessenger get _messenger =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  /// Starts answering the `steady/daily_metrics` channel.
  void install() => _messenger.setMockMethodCallHandler(_channel, _handle);

  /// Stops answering, so calls fail with `MissingPluginException`.
  void uninstall() => _messenger.setMockMethodCallHandler(_channel, null);

  Future<Object?> _handle(MethodCall call) async {
    calls.add(call);
    final code = failNextWithCode;
    if (code != null) {
      failNextWithCode = null;
      throw PlatformException(code: code, message: 'fake failure');
    }
    final override = replyOverride;
    if (override != null) return override(call);

    final args = (call.arguments as Map<Object?, Object?>?) ?? const {};
    switch (call.method) {
      case 'get':
        return rows[args['date']! as String];
      case 'range':
        final start = args['start']! as String;
        final end = args['end']! as String;
        final days =
            rows.keys
                .where((d) => d.compareTo(start) >= 0 && d.compareTo(end) <= 0)
                .toList()
              ..sort();
        return [for (final d in days) rows[d]];
      case 'put':
        final row = Map<String, Object?>.from(args);
        rows[row['date']! as String] = row;
        return row;
      case 'remove':
        rows.remove(args['date']! as String);
        return null;
      case 'reset':
        rows.clear();
        return null;
      case 'useStore':
        return null;
    }
    throw MissingPluginException('No fake for ${call.method}');
  }
}
