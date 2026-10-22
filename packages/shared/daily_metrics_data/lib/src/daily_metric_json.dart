import 'package:daily_metrics_domain/daily_metrics_domain.dart';

/// Wire-format version written by [encodeDailyMetrics]. Bump only alongside
/// a reader that understands both versions.
const int dailyMetricsJsonVersion = 1;

/// Encodes [metrics] as the versioned JSON envelope persisted by
/// `FileDailyMetricRepository`:
///
/// ```json
/// {"version": 1, "metrics": [{"date": "2026-08-24", "caloriesEaten": 2000,
///   "caloriesBurnedActive": null, "caloriesBurnedBasal": null,
///   "steps": null, "loggingStatus": "logged"}]}
/// ```
///
/// Lives in the data package on purpose: domain entities have no `fromJson`
/// (CLAUDE.md §9).
Map<String, Object?> encodeDailyMetrics(Iterable<DailyMetric> metrics) => {
  'version': dailyMetricsJsonVersion,
  'metrics': [for (final m in metrics) encodeDailyMetric(m)],
};

/// Decodes the envelope written by [encodeDailyMetrics].
///
/// Throws [FormatException] for anything it doesn't fully understand
/// (wrong shape, unknown version, bad date, unknown logging status), so the
/// caller can refuse to overwrite a file it can't read.
List<DailyMetric> decodeDailyMetrics(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const FormatException('Expected a JSON object envelope');
  }
  final version = json['version'];
  if (version != dailyMetricsJsonVersion) {
    throw FormatException('Unsupported daily metrics version: $version');
  }
  final metrics = json['metrics'];
  if (metrics is! List<Object?>) {
    throw const FormatException('Expected "metrics" to be a list');
  }
  return [for (final m in metrics) decodeDailyMetric(m)];
}

/// Encodes one row as a map with `date` (`yyyy-MM-dd`) plus every field.
/// Also the row format of the `steady/daily_metrics` channel.
Map<String, Object?> encodeDailyMetric(DailyMetric m) => {
  'date': formatDailyMetricDate(m.date),
  'caloriesEaten': m.caloriesEaten,
  'caloriesBurnedActive': m.caloriesBurnedActive,
  'caloriesBurnedBasal': m.caloriesBurnedBasal,
  'steps': m.steps,
  'loggingStatus': m.loggingStatus?.name,
};

/// Decodes one row written by [encodeDailyMetric]. Throws
/// [FormatException] for a wrong shape, bad date or unknown logging status.
DailyMetric decodeDailyMetric(Object? json) {
  if (json is! Map<String, Object?>) {
    throw const FormatException('Expected each metric to be a JSON object');
  }
  return DailyMetric(
    date: _parseDate(json['date']),
    caloriesEaten: _optionalInt(json, 'caloriesEaten'),
    caloriesBurnedActive: _optionalInt(json, 'caloriesBurnedActive'),
    caloriesBurnedBasal: _optionalInt(json, 'caloriesBurnedBasal'),
    steps: _optionalInt(json, 'steps'),
    loggingStatus: _optionalLoggingStatus(json['loggingStatus']),
  );
}

int? _optionalInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value == null || value is int) return value as int?;
  throw FormatException('Expected "$key" to be an int or null', value);
}

LoggingStatus? _optionalLoggingStatus(Object? value) {
  if (value == null) return null;
  for (final status in LoggingStatus.values) {
    if (status.name == value) return status;
  }
  throw FormatException('Unknown loggingStatus', value);
}

final RegExp _datePattern = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$');

/// Formats [date]'s calendar day as `yyyy-MM-dd`.
String formatDailyMetricDate(DateTime date) {
  String two(int n) => n.toString().padLeft(2, '0');
  return '${date.year.toString().padLeft(4, '0')}-'
      '${two(date.month)}-${two(date.day)}';
}

/// Parses `yyyy-MM-dd` to local midnight. Rejects out-of-range parts rather
/// than letting `DateTime` silently roll them over (e.g. `2026-02-31`).
DateTime _parseDate(Object? value) {
  final match = value is String ? _datePattern.firstMatch(value) : null;
  if (match == null) {
    throw FormatException('Expected "date" as yyyy-MM-dd', value);
  }
  final year = int.parse(match.group(1)!);
  final month = int.parse(match.group(2)!);
  final day = int.parse(match.group(3)!);
  final date = DateTime(year, month, day);
  if (date.year != year || date.month != month || date.day != day) {
    throw FormatException('Invalid calendar date', value);
  }
  return date;
}
