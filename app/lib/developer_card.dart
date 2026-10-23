import 'dart:async';
import 'dart:io';

import 'package:daily_metrics_data/daily_metrics_data.dart';
import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import 'package:ui_kit/ui_kit.dart';

/// The Settings sections only debug builds get: today just
/// [DeveloperCard]. Empty in release and profile builds, and on platforms
/// without the native store (tests, anything but iOS and macOS).
///
/// [debugBuild] and [hasNativeStore] are for tests.
List<Widget> developerSettingsSections({
  bool debugBuild = kDebugMode,
  bool? hasNativeStore,
}) {
  final native = hasNativeStore ?? (Platform.isIOS || Platform.isMacOS);
  return debugBuild && native ? const [DeveloperCard()] : const [];
}

/// "Developer (debug builds only)": one button that pushes the full
/// SwiftData schema to the CloudKit development environment (#93,
/// `docs/cloudkit_schema.md`), then shows the record types it covered or
/// the error.
///
/// Plain widget state on purpose: it's a one-shot developer action, never a
/// domain event (CLAUDE.md §4).
class DeveloperCard extends StatefulWidget {
  /// Creates the card. [tools] is for tests.
  const DeveloperCard({
    this.tools = const DailyMetricsStoreDeveloperTools(),
    super.key,
  });

  /// The native store's developer tools.
  final DailyMetricsStoreDeveloperTools tools;

  @override
  State<DeveloperCard> createState() => _DeveloperCardState();
}

class _DeveloperCardState extends State<DeveloperCard> {
  bool _running = false;
  Result<CloudKitSchemaReport>? _result;

  Future<void> _initializeSchema() async {
    setState(() {
      _running = true;
      _result = null;
    });
    final result = await widget.tools.initializeCloudKitSchema();
    if (!mounted) return;
    setState(() {
      _running = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    return SteadyCard(
      key: const Key('developerCard'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Developer (debug builds only)',
            style: SteadyType.cardTitle,
          ),
          const SizedBox(height: 8),
          const Text(
            'Creates every DailyMetricRecord field in the CloudKit '
            'development schema, using a throwaway store. Then check them '
            'in CloudKit Console before deploying (docs/cloudkit_schema.md).',
            style: SteadyType.body,
          ),
          const SizedBox(height: 16),
          if (_running)
            const CircularProgressIndicator()
          else
            OutlineButton(
              key: const Key('initializeCloudKitSchemaButton'),
              onPressed: () => unawaited(_initializeSchema()),
              child: const Text('Initialize CloudKit schema'),
            ),
          if (result != null) ...[
            const SizedBox(height: 16),
            Text(
              _describe(result),
              key: const Key('cloudKitSchemaResult'),
              style: SteadyType.body,
            ),
          ],
        ],
      ),
    );
  }

  static String _describe(Result<CloudKitSchemaReport> result) =>
      switch (result) {
        Ok(:final value) => [
          'Initialized in ${value.containerIdentifier}:',
          for (final type in value.recordTypes) ...[
            type.name,
            for (final MapEntry(:key, :value) in type.fields.entries)
              '  $key: $value',
          ],
        ].join('\n'),
        Err(failure: PlatformChannelFailure(:final code, :final message)) =>
          'Failed ($code): $message',
        Err(:final failure) => 'Failed: ${failure.message}',
      };
}
