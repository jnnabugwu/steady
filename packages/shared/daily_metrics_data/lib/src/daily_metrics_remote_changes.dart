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
///   stream closes, so it behaves as empty. No retry, no `cancel`.
/// - **A failed native `listen`** is logged and retried while anyone is
///   listening, with capped backoff (1 s, 2 s, 4 s, ... then every 60 s,
///   unlimited attempts), so the app's lifetime subscription isn't left
///   permanently deaf. Cancelling stops the retries.
/// - **Other native errors** (a `cancel` failure or an error event) are
///   logged and swallowed. A missed refresh only leaves a screen stale until
///   its next read; it is never worth failing the app over.
///
/// Tearing down the Dart listener always sends the native `cancel`, even
/// after the native side ended the stream or a `listen` failed, so the
/// plugin never keeps its observer and event sink registered. Native
/// `cancel` is idempotent.
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
  // Bumped on every listen and cancel, so a `listen` that fails after its
  // listener is gone (or replaced) schedules nothing.
  var generation = 0;
  Timer? retry;
  var hasPlugin = true;

  Future<void> activate(int listenGeneration, int attempt) async {
    try {
      await methods.invokeMethod<void>('listen');
    } on MissingPluginException {
      // No native store here, so nothing will ever change remotely.
      hasPlugin = false;
      binaryMessenger().setMessageHandler(name, null);
      await controller.close();
    } on Object catch (error) {
      _log(
        'Listening for remote changes failed (attempt ${attempt + 1})',
        error,
      );
      if (listenGeneration != generation) return;
      retry = Timer(_retryDelay(attempt), () {
        retry = null;
        unawaited(activate(listenGeneration, attempt + 1));
      });
    }
  }

  controller = StreamController<void>.broadcast(
    onListen: () {
      final listenGeneration = ++generation;
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
      unawaited(activate(listenGeneration, 0));
    },
    // Also runs once the stream has closed and its listeners are done.
    onCancel: () async {
      generation++;
      retry?.cancel();
      retry = null;
      binaryMessenger().setMessageHandler(name, null);
      if (!hasPlugin) return;
      try {
        await methods.invokeMethod<void>('cancel');
      } on Object catch (error) {
        _log('Cancelling remote changes failed', error);
      }
    },
  );
  return controller.stream;
}

/// 1 s, 2 s, 4 s, ... capped at 60 s, for the 0-based [attempt] that failed.
Duration _retryDelay(int attempt) =>
    Duration(seconds: attempt >= 6 ? 60 : 1 << attempt);

void _log(String message, Object error) =>
    developer.log(message, name: 'steady.daily_metrics', error: error);
