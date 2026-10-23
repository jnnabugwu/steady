import 'dart:async';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = EventChannel(dailyMetricsStoreChangesChannelName);
  const methods = MethodChannel(dailyMetricsStoreChangesChannelName);
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

  test('the native side ending the stream closes it, and still cancels the '
      'native stream', () async {
    late MockStreamHandlerEventSink sink;
    var cancels = 0;
    messenger().setMockStreamHandler(
      channel,
      MockStreamHandler.inline(
        onListen: (_, events) => sink = events,
        onCancel: (_) => cancels++,
      ),
    );

    final done = Completer<void>();
    dailyMetricsRemoteChanges().listen((_) {}, onDone: done.complete);
    await settle();
    sink.endOfStream();

    await done.future.timeout(const Duration(seconds: 1));
    await settle();
    // Otherwise the plugin's observer and event sink stay registered.
    expect(cancels, 1);
  });

  group('a failed native listen (fake time)', () {
    /// Fails the native `listen` the first [failures] times; counts calls.
    /// Returns a getter for the counts, and the sink once a listen succeeds.
    ({int listens, int cancels, MockStreamHandlerEventSink? sink}) Function()
    nativeFailing(int failures) {
      var listens = 0;
      var cancels = 0;
      MockStreamHandlerEventSink? sink;
      messenger().setMockStreamHandler(
        channel,
        MockStreamHandler.inline(
          onListen: (_, events) {
            listens++;
            if (listens <= failures) {
              throw PlatformException(code: 'unknown', message: 'boom');
            }
            sink = events;
          },
          onCancel: (_) => cancels++,
        ),
      );
      return () => (listens: listens, cancels: cancels, sink: sink);
    }

    test('is retried after 1 s, 2 s, 4 s, until one succeeds', () {
      fakeAsync((async) {
        final native = nativeFailing(3);
        var count = 0;
        final errors = <Object>[];
        final subscription = dailyMetricsRemoteChanges().listen(
          (_) => count++,
          onError: errors.add,
        );

        async.flushMicrotasks();
        expect(native().listens, 1);
        async.elapse(const Duration(milliseconds: 999));
        expect(native().listens, 1);
        async.elapse(const Duration(milliseconds: 1));
        expect(native().listens, 2);
        async.elapse(const Duration(seconds: 2));
        expect(native().listens, 3);
        async.elapse(const Duration(seconds: 4));
        expect(native().listens, 4);

        // Succeeded: no more retries, and events arrive.
        async.elapse(const Duration(minutes: 10));
        expect(native().listens, 4);
        native().sink!.success(1);
        async.flushMicrotasks();
        expect(count, 1);
        expect(errors, isEmpty);

        unawaited(subscription.cancel());
        async.flushMicrotasks();
        expect(native().cancels, 1);
      });
    });

    test('backs off to at most 60 s, without giving up', () {
      fakeAsync((async) {
        final native = nativeFailing(1 << 30);
        final subscription = dailyMetricsRemoteChanges().listen((_) {});

        // 1 + 2 + 4 + 8 + 16 + 32 = 63 s: the initial listen and 6 retries.
        async.elapse(const Duration(seconds: 63));
        expect(native().listens, 7);
        async.elapse(const Duration(milliseconds: 59999));
        expect(native().listens, 7);
        async.elapse(const Duration(milliseconds: 1));
        expect(native().listens, 8);
        async.elapse(const Duration(minutes: 60));
        expect(native().listens, 68);

        unawaited(subscription.cancel());
        async.flushMicrotasks();
      });
    });

    test('cancelling stops the retries, and cancels natively', () {
      fakeAsync((async) {
        final native = nativeFailing(1 << 30);
        final subscription = dailyMetricsRemoteChanges().listen((_) {});
        async.elapse(const Duration(milliseconds: 1500));
        expect(native().listens, 2);

        unawaited(subscription.cancel());
        async.elapse(const Duration(minutes: 10));

        expect(native().listens, 2);
        expect(native().cancels, 1);
      });
    });

    test('a listen that fails after its listener cancelled is not retried', () {
      fakeAsync((async) {
        final failing = Completer<void>();
        var listens = 0;
        messenger().setMockMethodCallHandler(methods, (call) async {
          if (call.method == 'listen') {
            listens++;
            await failing.future;
            throw PlatformException(code: 'unknown', message: 'boom');
          }
          return null;
        });
        addTearDown(() => messenger().setMockMethodCallHandler(methods, null));

        final subscription = dailyMetricsRemoteChanges().listen((_) {});
        async.flushMicrotasks();
        unawaited(subscription.cancel());
        async.flushMicrotasks();
        failing.complete();
        async.elapse(const Duration(minutes: 10));

        expect(listens, 1);
      });
    });

    test('without the plugin: closes, no retry, no cancel', () {
      fakeAsync((async) {
        final calls = <String>[];
        messenger().setMockMethodCallHandler(methods, (call) async {
          calls.add(call.method);
          throw MissingPluginException();
        });
        addTearDown(() => messenger().setMockMethodCallHandler(methods, null));

        var done = false;
        dailyMetricsRemoteChanges().listen((_) {}, onDone: () => done = true);
        async.elapse(const Duration(minutes: 10));

        expect(done, isTrue);
        expect(calls, ['listen']);
      });
    });
  });
}
