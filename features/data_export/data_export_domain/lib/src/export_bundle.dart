import 'dart:convert';

import 'package:coach_domain/coach_domain.dart';
import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/src/export_file.dart';
import 'package:data_export_domain/src/export_format.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_bundle.freezed.dart';

/// Everything one export holds, and how it's written as CSV or JSON.
///
/// That's the user's [dailyMetrics] rows, which carry both the metrics
/// (calories, steps) and the check-in `loggingStatus` (there is no separate
/// check-in table), and on the iPhone their [coachSessions]. The JSON shape
/// is versioned ([schemaVersion]).
///
/// **Coach sessions: date, kind and summary only** (decided 2026-10-24),
/// never the transcript. They're in the JSON only, as `coachSessions`; the
/// CSV stays one row per day. A summary may mention Health numbers the
/// coach discussed; that's accepted, since the export is a file the person
/// chooses to share, not iCloud storage (CLAUDE.md §7).
///
/// **Null is not zero.** A missing field is written as an empty CSV cell
/// and a JSON `null`, never `0`: "logged zero" and "nothing recorded" mean
/// different things (see `DailyMetric`).
@freezed
abstract class ExportBundle with _$ExportBundle {
  /// Creates an export bundle.
  const factory ExportBundle({
    /// When the export was made. Written to the JSON as UTC ISO 8601, and
    /// its local calendar date names the file.
    required DateTime exportedAt,

    /// The rows to export, in any order: both encoders sort by date.
    required List<DailyMetric> dailyMetrics,

    /// The coach sessions to export, in any order: the JSON lists them
    /// oldest first. `null` where this device has no coach (the Mac), so
    /// the JSON leaves the key out; an empty list is a coach with no
    /// sessions yet. Only each session's date, kind and summary are
    /// written.
    List<CoachSession>? coachSessions,
  }) = _ExportBundle;

  const ExportBundle._();

  /// The JSON export's format version. Bump it when the JSON shape changes
  /// in a way an importer has to know about.
  ///
  /// - 1: `exportedAt` and `dailyMetrics`.
  /// - 2: adds `coachSessions` ([coachSessionColumns]), present only in an
  ///   export made on a device with the coach (the iPhone).
  static const int schemaVersion = 2;

  /// CSV header and JSON object keys for one day, in their stable order.
  /// Named after the `DailyMetric` fields.
  static List<String> get columns => [for (final (name, _) in _fields) name];

  /// JSON object keys for one coach session, in their stable order. No
  /// transcript.
  static List<String> get coachSessionColumns => [
    for (final (name, _) in _coachFields) name,
  ];

  /// The file to hand to the share sheet for [format]:
  /// `steady-export-<yyyy-MM-dd>.<ext>`, dated by [exportedAt]'s local
  /// calendar date.
  ExportFile toFile(ExportFormat format) => ExportFile(
    fileName:
        'steady-export-${formatIsoDate(exportedAt)}.${format.fileExtension}',
    mimeType: format.mimeType,
    contents: switch (format) {
      ExportFormat.csv => encodeCsv(),
      ExportFormat.json => encodeJson(),
    },
  );

  /// One header line, then one line per day sorted by date. Lines end with
  /// CRLF (RFC 4180), cells are escaped with [encodeCsvField], and a null
  /// field is an empty cell.
  String encodeCsv() {
    final buffer = StringBuffer()..write(_csvLine(columns));
    for (final metric in _sortedMetrics) {
      buffer.write(
        _csvLine([for (final (_, read) in _fields) read(metric)?.toString()]),
      );
    }
    return buffer.toString();
  }

  /// `{"schemaVersion": 2, "exportedAt": ..., "dailyMetrics": [...],
  /// "coachSessions": [...]}`, indented, with one object per day sorted by
  /// date and every key present. A null field stays `null`.
  ///
  /// `coachSessions` is there only when [coachSessions] isn't `null`: one
  /// object per session (`date`, `kind`, `summary`), oldest first.
  String encodeJson() => const JsonEncoder.withIndent('  ').convert({
    'schemaVersion': schemaVersion,
    'exportedAt': exportedAt.toUtc().toIso8601String(),
    'dailyMetrics': [
      for (final metric in _sortedMetrics)
        {for (final (name, read) in _fields) name: read(metric)},
    ],
    if (coachSessions case final sessions?)
      'coachSessions': [
        for (final session in [...sessions]..sort(_oldestFirst))
          {for (final (name, read) in _coachFields) name: read(session)},
      ],
  });

  List<DailyMetric> get _sortedMetrics =>
      [...dailyMetrics]..sort((a, b) => a.date.compareTo(b.date));

  static int _oldestFirst(CoachSession a, CoachSession b) =>
      compareCoachSessionsNewestFirst(b, a);

  static String _csvLine(List<String?> cells) =>
      '${cells.map(encodeCsvField).join(',')}\r\n';
}

/// One day's fields, in column order: the shared source of truth for the
/// CSV header, CSV cells and JSON keys, so the two formats can't drift.
final List<(String, Object? Function(DailyMetric))> _fields = [
  ('date', (m) => formatIsoDate(m.date)),
  ('caloriesEaten', (m) => m.caloriesEaten),
  ('caloriesBurnedActive', (m) => m.caloriesBurnedActive),
  ('caloriesBurnedBasal', (m) => m.caloriesBurnedBasal),
  ('steps', (m) => m.steps),
  ('loggingStatus', (m) => m.loggingStatus?.name),
];

/// One coach session's exported fields, in key order: its local calendar
/// date (like a day's `date`), kind and summary. Never its messages.
final List<(String, Object? Function(CoachSession))> _coachFields = [
  ('date', (s) => formatIsoDate(s.startedAt)),
  ('kind', (s) => s.kind.name),
  ('summary', (s) => s.summary),
];

/// [date]'s calendar date as `yyyy-MM-dd`, ignoring any time of day.
///
/// The year is at least four digits, with a leading `-` before the year
/// zero (ISO 8601's astronomical numbering, as `DateTime` uses): year -5
/// is `-0005`, year 10000 is `10000`. The export reads every day a
/// `DateTime` can hold, so a year like -5 must not come out as `00-5`.
String formatIsoDate(DateTime date) {
  final sign = date.year < 0 ? '-' : '';
  final y = '$sign${date.year.abs().toString().padLeft(4, '0')}';
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// One RFC 4180 CSV cell: `null` becomes an empty cell, and a value
/// containing a comma, double quote, CR or LF is wrapped in double quotes
/// with any double quote inside doubled.
String encodeCsvField(String? value) {
  if (value == null) return '';
  if (!value.contains(RegExp('[",\r\n]'))) return value;
  return '"${value.replaceAll('"', '""')}"';
}
