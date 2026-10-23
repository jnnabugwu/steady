import 'dart:async';
import 'dart:developer' as developer;

import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:flutter/services.dart';

/// Fires each time the SwiftData store changes through something other than
/// this app's own writes: in practice, CloudKit importing rows another
/// device wrote (#73). An event carries no data; a listener re-reads.
///
/// Backed by the `daily_metrics_store` plugin's
/// [dailyMetricsStoreChangesChannelName] EventChannel (contract in
/// `package:daily_metrics_store`), which debounces bursts natively.
///
/// A broadcast stream that never errors and never throws:
///
/// - **No plugin** (unit tests, a platform without it): the native `listen`
///   call fails with `MissingPluginException`; that is logged and the
///   stream closes, so it behaves as empty.
/// - **A native error** (a `listen`/`cancel` failure or an error event) is
///   logged and swallowed. A missed refresh only leaves a screen stale until
///   its next read; it is never worth failing the app over.
///
/// This speaks the EventChannel protocol directly rather than through
/// `EventChannel.receiveBroadcastStream`, because that reports a failed
/// `listen` through `FlutterError.reportError` instead of the stream, which
/// would fail every test that runs without the plugin.
///
/// Not on `DailyMetricRepository`: refreshing screens is the app's job
/// (it alone may know about several features, CLAUDE.md §3/§5), and no
/// feature needs to know the store syncs.
Stream<void> dailyMetricsRemoteChanges({BinaryMessenger? messenger}) {
  const name = dailyMetricsStoreChangesChannelName;
  const codec = StandardMethodCodec();
  BinaryMessenger binaryMessenger() =>
      messenger ?? ServicesBinding.instance.defaultBinaryMessenger;
  final methods = MethodChannel(name, codec, messenger);

  late final StreamController<void> controller;
  controller = StreamController<void>.broadcast(
    onListen: () async {
      binaryMessenger().setMessageHandler(name, (data) async {
        if (data == null) {
          // The native side ended the stream.
          await controller.close();
          return null;
        }
        try {
          codec.decodeEnvelope(data);
          controller.add(null);
        } on Object catch (error) {
          _log('Remote-change event failed', error);
        }
        return null;
      });
      try {
        await methods.invokeMethod<void>('listen');
      } on MissingPluginException {
        // No native store here, so nothing will ever change remotely.
        binaryMessenger().setMessageHandler(name, null);
        await controller.close();
      } on Object catch (error) {
        _log('Listening for remote changes failed', error);
      }
    },
    onCancel: () async {
      binaryMessenger().setMessageHandler(name, null);
      if (controller.isClosed) return;
      try {
        await methods.invokeMethod<void>('cancel');
      } on Object catch (error) {
        _log('Cancelling remote changes failed', error);
      }
    },
  );
  return controller.stream;
}

void _log(String message, Object error) =>
    developer.log(message, name: 'steady.daily_metrics', error: error);
