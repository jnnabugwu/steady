import 'dart:async';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel(dailyMetricsStoreChangesChannelName);
  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger().setMockStreamHandler(channel, null));

  /// Lets queued platform messages and microtasks run.
  Future<void> settle() => Future<void>.delayed(Duration.zero);

  test('emits one event per native event', () async {
    late MockStreamHandlerEventSink sink;
    messenger().setMockStreamHandler(
      channel,
      MockStreamHandler.inline(onListen: (_, events) => sink = events),
    );

    var count = 0;
    final subscription = dailyMetricsRemoteChanges().listen((_) => count++);
    await settle();
    sink
      ..success(1)
      ..success(2);
    await settle();

    expect(count, 2);
    await subscription.cancel();
  });

  test('cancelling the subscription cancels the native stream', () async {
    var listens = 0;
    var cancels = 0;
    messenger().setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (_, _) => listens++,
        onCancel: (_) => cancels++,
      ),
    );

    final subscription = dailyMetricsRemoteChanges().listen((_) {});
    await settle();
    await subscription.cancel();
    await settle();

    expect((listens, cancels), (1, 1));
  });

  test(
    'a native error event is swallowed, and later events still arrive',
    () async {
      late MockStreamHandlerEventSink sink;
      messenger().setMockStreamHandler(
        channel,
        MockStreamHandler.inline(onListen: (_, events) => sink = events),
      );

      var count = 0;
      final errors = <Object>[];
      final subscription = dailyMetricsRemoteChanges().listen(
        (_) => count++,
        onError: errors.add,
      );
      await settle();
      sink
        ..error(code: 'fetch_failed', message: 'boom')
        ..success(1);
      await settle();

      expect(errors, isEmpty);
      expect(count, 1);
      await subscription.cancel();
    },
  );

  test('a failed native listen is swallowed', () async {
    messenger().setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (_, _) =>
            throw PlatformException(code: 'unknown', message: 'boom'),
      ),
    );

    final errors = <Object>[];
    final subscription = dailyMetricsRemoteChanges().listen(
      (_) {},
      onError: errors.add,
    );
    await settle();

    expect(errors, isEmpty);
    await subscription.cancel();
  });

  test('without the plugin it is empty and never throws', () async {
    final events = <void>[];
    final errors = <Object>[];
    final done = Completer<void>();
    dailyMetricsRemoteChanges().listen(
      events.add,
      onError: errors.add,
      onDone: done.complete,
    );

    await done.future.timeout(const Duration(seconds: 1));
    expect(events, isEmpty);
    expect(errors, isEmpty);
  });

  test('the native side ending the stream closes it', () async {
    late MockStreamHandlerEventSink sink;
    messenger().setMockStreamHandler(
      channel,
      MockStreamHandler.inline(onListen: (_, events) => sink = events),
    );

    final done = Completer<void>();
    dailyMetricsRemoteChanges().listen((_) {}, onDone: done.complete);
    await settle();
    sink.endOfStream();

    await done.future.timeout(const Duration(seconds: 1));
  });
}
