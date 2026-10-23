import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:failures/failures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel(dailyMetricsStoreChannelName);
  final calls = <MethodCall>[];

  void answer(Future<Object?> Function(MethodCall call) handler) =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) {
            calls.add(call);
            return handler(call);
          });

  setUp(calls.clear);

  tearDown(
    () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null),
  );

  Failure failureOf(Result<CloudKitSchemaReport> result) =>
      (result as Err<CloudKitSchemaReport>).failure;

  // Tests run in debug mode, so the default is the debug path.
  const tools = DailyMetricsStoreDeveloperTools();

  test('decodes the record types the native side pushed', () async {
    answer(
      (_) async => {
        'containerIdentifier': 'iCloud.com.jmagic.steady',
        'recordTypes': [
          {
            'name': 'CD_DailyMetricRecord',
            'fields': [
              {'name': 'CD_day', 'type': 'String'},
              {'name': 'CD_steps', 'type': 'Int(64)'},
            ],
          },
        ],
      },
    );

    final result = await tools.initializeCloudKitSchema();

    final report = (result as Ok<CloudKitSchemaReport>).value;
    expect(calls.single.method, 'initializeCloudKitSchema');
    expect(report.containerIdentifier, 'iCloud.com.jmagic.steady');
    expect(report.recordTypes.single.name, 'CD_DailyMetricRecord');
    expect(report.recordTypes.single.fields, {
      'CD_day': 'String',
      'CD_steps': 'Int(64)',
    });
  });

  for (final code in [
    'cloudkit_disabled',
    'schema_init_running',
    'schema_init_failed',
  ]) {
    test('a native $code error becomes a PlatformChannelFailure', () async {
      answer((_) async => throw PlatformException(code: code, message: 'nope'));

      final failure = failureOf(await tools.initializeCloudKitSchema());

      expect(failure, PlatformChannelFailure('nope', code: code));
    });
  }

  test('no plugin (or a release build) is not_available', () async {
    final failure = failureOf(await tools.initializeCloudKitSchema());

    expect(failure, isA<PlatformChannelFailure>());
    expect((failure as PlatformChannelFailure).code, 'not_available');
  });

  test('a malformed reply is an UnknownFailure', () async {
    answer((_) async => {'recordTypes': 'not a list'});

    final failure = failureOf(await tools.initializeCloudKitSchema());

    expect(failure, isA<UnknownFailure>());
  });

  test('a malformed field is an UnknownFailure', () async {
    answer(
      (_) async => {
        'containerIdentifier': 'iCloud.com.jmagic.steady',
        'recordTypes': [
          {
            'name': 'CD_DailyMetricRecord',
            'fields': [
              {'name': 'CD_day'},
            ],
          },
        ],
      },
    );

    final failure = failureOf(await tools.initializeCloudKitSchema());

    expect(failure, isA<UnknownFailure>());
  });

  test('outside a debug build, native is never called', () async {
    answer((_) async => fail('called native'));

    final failure = failureOf(
      await const DailyMetricsStoreDeveloperTools(debugBuild: false)
          .initializeCloudKitSchema(),
    );

    expect((failure as PlatformChannelFailure).code, 'not_available');
    expect(calls, isEmpty);
  });
}
