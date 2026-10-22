import 'dart:convert';

import 'package:daily_metrics_domain/daily_metrics_domain.dart';
import 'package:data_export_domain/data_export_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  // 2026-10-22 09:30 local: the local calendar date names the file.
  final exportedAt = DateTime(2026, 10, 22, 9, 30);

  final fullDay = DailyMetric(
    date: DateTime(2026, 10, 19),
    caloriesEaten: 1850,
    caloriesBurnedActive: 420,
    caloriesBurnedBasal: 1700,
    steps: 8123,
    loggingStatus: LoggingStatus.logged,
  );
  final sparseDay = DailyMetric(
    date: DateTime(2026, 10, 20),
    caloriesEaten: 0,
    loggingStatus: LoggingStatus.partial,
  );
  final emptyDay = DailyMetric(date: DateTime(2026, 10, 21));

  ExportBundle bundle(List<DailyMetric> rows) =>
      ExportBundle(exportedAt: exportedAt, dailyMetrics: rows);

  group('encodeCsv', () {
    test('writes the header in a stable column order', () {
      expect(ExportBundle.columns, [
        'date',
        'caloriesEaten',
        'caloriesBurnedActive',
        'caloriesBurnedBasal',
        'steps',
        'loggingStatus',
      ]);
      expect(
        bundle(const []).encodeCsv(),
        'date,caloriesEaten,caloriesBurnedActive,caloriesBurnedBasal,'
        'steps,loggingStatus\r\n',
      );
    });

    test('one CRLF-terminated row per day, sorted by date', () {
      final csv = bundle([emptyDay, fullDay, sparseDay]).encodeCsv();

      expect(csv.split('\r\n'), [
        ExportBundle.columns.join(','),
        '2026-10-19,1850,420,1700,8123,logged',
        '2026-10-20,0,,,,partial',
        '2026-10-21,,,,,',
        '',
      ]);
    });

    test('null is an empty cell and 0 stays 0', () {
      final rows = bundle([sparseDay]).encodeCsv().split('\r\n');

      // caloriesEaten was logged as 0; the burned/steps fields were never
      // recorded, so they're empty rather than 0.
      expect(rows[1].split(','), ['2026-10-20', '0', '', '', '', 'partial']);
    });

    test('dates are yyyy-MM-dd, ignoring any time of day', () {
      final csv = bundle([
        DailyMetric(date: DateTime(2026, 1, 5, 23, 59), steps: 1),
      ]).encodeCsv();

      expect(csv.split('\r\n')[1], startsWith('2026-01-05,'));
    });
  });

  group('encodeCsvField', () {
    test('null is an empty cell', () {
      expect(encodeCsvField(null), '');
    });

    test('plain values are written as-is', () {
      expect(encodeCsvField('1850'), '1850');
      expect(encodeCsvField(''), '');
      expect(encodeCsvField('logged'), 'logged');
    });

    test('commas, quotes, CR and LF are quoted, inner quotes doubled', () {
      expect(encodeCsvField('a,b'), '"a,b"');
      expect(encodeCsvField('say "hi"'), '"say ""hi"""');
      expect(encodeCsvField('line1\nline2'), '"line1\nline2"');
      expect(encodeCsvField('line1\r\nline2'), '"line1\r\nline2"');
      expect(encodeCsvField('"'), '""""');
    });
  });

  group('encodeJson', () {
    Map<String, Object?> decode(ExportBundle b) =>
        jsonDecode(b.encodeJson()) as Map<String, Object?>;

    test('has a versioned top-level shape', () {
      final json = decode(bundle(const []));

      expect(json.keys, ['schemaVersion', 'exportedAt', 'dailyMetrics']);
      expect(json['schemaVersion'], 1);
      expect(ExportBundle.schemaVersion, 1);
      expect(json['exportedAt'], exportedAt.toUtc().toIso8601String());
      expect(json['exportedAt'], endsWith('Z'));
      expect(json['dailyMetrics'], isEmpty);
    });

    test('one object per day, sorted by date, every key present', () {
      final json = decode(bundle([emptyDay, sparseDay, fullDay]));
      final days = (json['dailyMetrics']! as List).cast<Map<String, Object?>>();

      expect(days.map((d) => d['date']), [
        '2026-10-19',
        '2026-10-20',
        '2026-10-21',
      ]);
      for (final day in days) {
        expect(day.keys, ExportBundle.columns);
      }
      expect(days[0], {
        'date': '2026-10-19',
        'caloriesEaten': 1850,
        'caloriesBurnedActive': 420,
        'caloriesBurnedBasal': 1700,
        'steps': 8123,
        'loggingStatus': 'logged',
      });
    });

    test('preserves null, distinct from 0', () {
      final json = decode(bundle([sparseDay, emptyDay]));
      final days = (json['dailyMetrics']! as List).cast<Map<String, Object?>>();

      expect(days[0], {
        'date': '2026-10-20',
        'caloriesEaten': 0,
        'caloriesBurnedActive': null,
        'caloriesBurnedBasal': null,
        'steps': null,
        'loggingStatus': 'partial',
      });
      expect(days[1].values.skip(1), everyElement(isNull));
    });
  });

  group('toFile', () {
    test('csv: dated .csv file with text/csv contents', () {
      final b = bundle([fullDay]);
      final file = b.toFile(ExportFormat.csv);

      expect(file.fileName, 'steady-export-2026-10-22.csv');
      expect(file.mimeType, 'text/csv');
      expect(file.contents, b.encodeCsv());
    });

    test('json: dated .json file with application/json contents', () {
      final b = bundle([fullDay]);
      final file = b.toFile(ExportFormat.json);

      expect(file.fileName, 'steady-export-2026-10-22.json');
      expect(file.mimeType, 'application/json');
      expect(file.contents, b.encodeJson());
    });

    test('bytes are the UTF-8 encoded contents', () {
      final file = bundle([fullDay]).toFile(ExportFormat.csv);

      expect(utf8.decode(file.bytes), file.contents);
    });
  });
}
