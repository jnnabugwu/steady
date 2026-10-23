import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:steady/developer_card.dart';
import 'package:ui_kit/ui_kit.dart';

void main() {
  // `dailyMetricsStoreChannelName`; app/ doesn't depend on the plugin.
  const channel = MethodChannel('steady/daily_metrics');

  TestDefaultBinaryMessenger messenger() =>
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;

  tearDown(() => messenger().setMockMethodCallHandler(channel, null));

  Future<void> pumpSections(WidgetTester tester, List<Widget> sections) =>
      tester.pumpWidget(
        ShadcnApp(
          theme: steadyTheme,
          home: Column(children: sections),
        ),
      );

  // Tests run in debug mode, so `debugBuild` defaults to true here.
  group('developerSettingsSections', () {
    testWidgets('shows the Developer card in a debug build with the store', (
      tester,
    ) async {
      await pumpSections(
        tester,
        developerSettingsSections(hasNativeStore: true),
      );

      expect(find.text('Developer (debug builds only)'), findsOneWidget);
      expect(
        find.byKey(const Key('initializeCloudKitSchemaButton')),
        findsOneWidget,
      );
    });

    testWidgets('is empty outside a debug build', (tester) async {
      await pumpSections(
        tester,
        developerSettingsSections(debugBuild: false, hasNativeStore: true),
      );

      expect(find.byKey(const Key('developerCard')), findsNothing);
    });

    testWidgets('is empty without the native store', (tester) async {
      await pumpSections(
        tester,
        developerSettingsSections(hasNativeStore: false),
      );

      expect(find.byKey(const Key('developerCard')), findsNothing);
    });
  });

  group('DeveloperCard', () {
    testWidgets('shows a spinner, then the record types pushed', (
      tester,
    ) async {
      final reply = Completer<Object?>();
      messenger().setMockMethodCallHandler(channel, (call) {
        expect(call.method, 'initializeCloudKitSchema');
        return reply.future;
      });
      await pumpSections(tester, const [DeveloperCard()]);

      await tester.tap(find.byKey(const Key('initializeCloudKitSchemaButton')));
      await tester.pump();
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const Key('initializeCloudKitSchemaButton')),
        findsNothing,
      );

      reply.complete({
        'containerIdentifier': 'iCloud.com.jmagic.steady',
        'recordTypes': [
          {
            'name': 'CD_DailyMetricRecord',
            'fields': [
              {'name': 'CD_day', 'type': 'String'},
            ],
          },
        ],
      });
      await tester.pumpAndSettle();

      final text = tester
          .widget<Text>(find.byKey(const Key('cloudKitSchemaResult')))
          .data!;
      expect(text, contains('iCloud.com.jmagic.steady'));
      expect(text, contains('CD_DailyMetricRecord'));
      expect(text, contains('CD_day: String'));
      expect(
        find.byKey(const Key('initializeCloudKitSchemaButton')),
        findsOneWidget,
      );
    });

    testWidgets('shows the failure code and message', (tester) async {
      messenger().setMockMethodCallHandler(
        channel,
        (_) async => throw PlatformException(
          code: 'cloudkit_disabled',
          message: 'CloudKit is off',
        ),
      );
      await pumpSections(tester, const [DeveloperCard()]);

      await tester.tap(find.byKey(const Key('initializeCloudKitSchemaButton')));
      await tester.pumpAndSettle();

      expect(
        find.text('Failed (cloudkit_disabled): CloudKit is off'),
        findsOneWidget,
      );
    });
  });
}
