import 'package:daily_metrics_store/daily_metrics_store.dart';
import 'package:failures/failures.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// One CloudKit record type the schema initializer covered, in CloudKit's
/// names: `CD_DailyMetricRecord` with fields like `CD_day` (`String`).
@immutable
class CloudKitRecordType {
  /// Creates a record type description.
  const CloudKitRecordType({required this.name, required this.fields});

  /// The record type, e.g. `CD_DailyMetricRecord`.
  final String name;

  /// Field name to CloudKit Console type label (`String`, `Int(64)`,
  /// `Date/Time`), sorted by name.
  final Map<String, String> fields;

  @override
  String toString() => '$name $fields';
}

/// What a successful [DailyMetricsStoreDeveloperTools.initializeCloudKitSchema]
/// pushed.
@immutable
class CloudKitSchemaReport {
  /// Creates a report.
  const CloudKitSchemaReport({
    required this.containerIdentifier,
    required this.recordTypes,
  });

  /// The iCloud container, e.g. `iCloud.com.jmagic.steady`.
  final String containerIdentifier;

  /// Every record type pushed, sorted by name.
  final List<CloudKitRecordType> recordTypes;
}

/// Debug-build tools on the native `daily_metrics_store` (#93). Not for
/// any user-facing flow.
///
/// Errors come back as `Err`, never thrown: a `PlatformException` becomes
/// `PlatformChannelFailure` with its code (`cloudkit_disabled`,
/// `schema_init_running`, `schema_init_failed`, ...); no plugin, or a
/// release build where the native method doesn't exist, becomes
/// `PlatformChannelFailure` coded `not_available`; a reply that doesn't
/// decode becomes `UnknownFailure`.
class DailyMetricsStoreDeveloperTools {
  /// Creates the tools over `channel` (the real `steady/daily_metrics` by
  /// default). `debugBuild` is for tests; it defaults to [kDebugMode].
  const DailyMetricsStoreDeveloperTools({
    this._channel = const MethodChannel(dailyMetricsStoreChannelName),
    this._debugBuild = kDebugMode,
  });

  final MethodChannel _channel;
  final bool _debugBuild;

  /// Pushes every field of the SwiftData model to the CloudKit
  /// **development** schema, whether or not any record holds a value in
  /// it, through a throwaway store (never the user's data). Takes up to
  /// tens of seconds. See `docs/cloudkit_schema.md` for what to check in
  /// CloudKit Console afterwards.
  ///
  /// In a release build this returns `Err` without calling native.
  ResultFuture<CloudKitSchemaReport> initializeCloudKitSchema() async {
    if (!_debugBuild) return const Err(_notAvailable);
    try {
      final reply = await _channel.invokeMethod<Object?>(
        'initializeCloudKitSchema',
      );
      return Ok(_decodeReport(reply));
    } on PlatformException catch (e) {
      return Err(
        PlatformChannelFailure(
          e.message ?? 'CloudKit schema initialization failed',
          code: e.code,
          cause: e,
        ),
      );
    } on MissingPluginException catch (e) {
      return Err(
        PlatformChannelFailure(
          _notAvailable.message,
          code: _notAvailable.code,
          cause: e,
        ),
      );
    } on FormatException catch (e) {
      return Err(
        UnknownFailure('Schema initializer sent a malformed reply', cause: e),
      );
    }
  }

  static const _notAvailable = PlatformChannelFailure(
    'CloudKit schema initialization is only in debug builds on iOS and macOS',
    code: 'not_available',
  );
}

CloudKitSchemaReport _decodeReport(Object? reply) {
  if (reply case {
    'containerIdentifier': final String container,
    'recordTypes': final List<Object?> types,
  }) {
    return CloudKitSchemaReport(
      containerIdentifier: container,
      recordTypes: [for (final type in types) _decodeRecordType(type)],
    );
  }
  throw FormatException('Expected {containerIdentifier, recordTypes}', reply);
}

CloudKitRecordType _decodeRecordType(Object? type) {
  if (type case {'name': final String name, 'fields': final List<Object?> fs}) {
    final fields = <String, String>{};
    for (final field in fs) {
      if (field case {'name': final String name, 'type': final String type}) {
        fields[name] = type;
      } else {
        throw FormatException('Expected a {name, type} field', field);
      }
    }
    return CloudKitRecordType(name: name, fields: fields);
  }
  throw FormatException('Expected a {name, fields} record type', type);
}
