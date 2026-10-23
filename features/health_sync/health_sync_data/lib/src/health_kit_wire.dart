import 'package:health_sync_domain/health_sync_domain.dart';

/// The `steady/healthkit` platform channel's contract, shared by
/// `MethodChannelHealthKitRepository` and the Swift handler in
/// `app/ios/Runner/HealthKitChannel.swift`. Change both sides together.
///
/// iOS only: nothing on macOS answers this channel.
abstract final class HealthKitChannel {
  /// The channel name.
  static const name = 'steady/healthkit';

  /// No arguments. Returns a bool: `HKHealthStore.isHealthDataAvailable()`.
  static const isAvailableMethod = 'isAvailable';

  /// No arguments. Returns `unavailable`, `notDetermined` or `requested`
  /// (see [healthAuthorizationStatusFromWire]).
  static const authorizationStatusMethod = 'authorizationStatus';

  /// No arguments. Shows the read-only permission sheet (step count, active
  /// energy, basal energy) if needed. Returns `null`; errors are
  /// `FlutterError`s.
  static const requestAuthorizationMethod = 'requestAuthorization';

  /// Arguments `{start: 'yyyy-MM-dd', end: 'yyyy-MM-dd'}`, inclusive local
  /// calendar days. Returns a list with one map per day:
  /// `{date: 'yyyy-MM-dd', steps: int?, activeKcal: int?, basalKcal: int?}`,
  /// where `null` means no samples of that type that day.
  static const dailyTotalsMethod = 'dailyTotals';

  /// The `FlutterError` code the native side uses when Health isn't
  /// available on the device.
  static const unavailableCode = 'unavailable';

  /// The `FlutterError` code for `dailyTotals` called before the permission
  /// sheet was ever shown.
  static const authorizationNotDeterminedCode = 'authorizationNotDetermined';
}

/// Maps the `authorizationStatus` wire string. Anything unknown, including
/// `null`, is [HealthAuthorizationStatus.notDetermined]: asking again is
/// harmless, since iOS shows the sheet at most once per type.
HealthAuthorizationStatus healthAuthorizationStatusFromWire(Object? raw) =>
    switch (raw) {
      'unavailable' => HealthAuthorizationStatus.unavailable,
      'requested' => HealthAuthorizationStatus.requested,
      'notDetermined' => HealthAuthorizationStatus.notDetermined,
      _ => HealthAuthorizationStatus.notDetermined,
    };

/// Formats [date]'s local calendar day as `yyyy-MM-dd`.
String formatHealthDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

final _wireDate = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Parses a `yyyy-MM-dd` wire date to local midnight. Throws
/// [FormatException] for anything else, including impossible dates such
/// as `2026-02-30`.
DateTime parseHealthDate(Object? raw) {
  final match = raw is String ? _wireDate.firstMatch(raw) : null;
  if (match == null) {
    throw FormatException('Expected a yyyy-MM-dd date', raw);
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Not a calendar date', raw);
  }
  return date;
}

/// Decodes the `dailyTotals` reply. Throws [FormatException] if it isn't a
/// list of maps in the documented shape; the repository maps that to an
/// `UnknownFailure` rather than writing half-understood data.
///
/// Hand-written rather than a freezed DTO, like the `steady/daily_metrics`
/// row format in `daily_metrics_data`: four flat fields don't need codegen.
List<HealthDayTotals> healthDayTotalsFromWire(Object? raw) {
  if (raw is! List<Object?>) {
    throw FormatException('Expected a list of days', raw);
  }
  return [
    for (final row in raw)
      if (row is Map<Object?, Object?>)
        HealthDayTotals(
          date: parseHealthDate(row['date']),
          steps: _count(row, 'steps'),
          caloriesBurnedActive: _count(row, 'activeKcal'),
          caloriesBurnedBasal: _count(row, 'basalKcal'),
        )
      else
        throw FormatException('Expected each day to be a map', row),
  ];
}

/// A non-negative whole number, or `null`. A `double` is accepted and
/// rounded, in case the native side ever sends an unrounded sum.
int? _count(Map<Object?, Object?> row, String key) {
  final value = row[key];
  if (value == null) return null;
  if (value is num && value.isFinite && value >= 0) return value.round();
  throw FormatException('Expected "$key" to be a non-negative number', value);
}
