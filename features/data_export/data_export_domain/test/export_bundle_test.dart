import 'dart:convert';

import 'package:coach_domain/coach_domain.dart';
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

  group('formatIsoDate', () {
    test('pads the year to four digits', () {
      expect(formatIsoDate(DateTime(2026, 1, 5)), '2026-01-05');
      expect(formatIsoDate(DateTime(1, 2, 3)), '0001-02-03');
      expect(formatIsoDate(DateTime(0, 12, 31)), '0000-12-31');
    });

    test('a negative year keeps its sign in front of the padded digits', () {
      expect(formatIsoDate(DateTime(-5, 6, 7)), '-0005-06-07');
      expect(formatIsoDate(DateTime(-271821, 4, 21)), '-271821-04-21');
    });

    test('a year past 9999 is written in full', () {
      expect(formatIsoDate(DateTime(10000)), '10000-01-01');
      expect(formatIsoDate(DateTime(275760, 9, 12)), '275760-09-12');
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
      expect(json['schemaVersion'], 2);
      expect(ExportBundle.schemaVersion, 2);
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

  group('coach sessions', () {
    final transcript = [
      CoachMessage(
        role: CoachMessageRole.user,
        text: 'Something only the coach heard',
        at: DateTime(2026, 10, 23, 19),
      ),
    ];
    final weekly = CoachSession(
      id: 'w',
      kind: CoachSessionKind.weekly,
      // Late evening local: the date is the local calendar date.
      startedAt: DateTime(2026, 10, 23, 23, 30),
      endedAt: DateTime(2026, 10, 23, 23, 45),
      summary: 'Steps held at about 8,000; Thursday was "partial".',
      messages: transcript,
    );
    final chat = CoachSession(
      id: 'c',
      kind: CoachSessionKind.chat,
      startedAt: DateTime(2026, 10, 20, 8),
      messages: transcript,
    );

    ExportBundle withCoach(List<CoachSession>? sessions) => ExportBundle(
      exportedAt: exportedAt,
      dailyMetrics: [fullDay],
      coachSessions: sessions,
    );

    Map<String, Object?> decode(ExportBundle b) =>
        jsonDecode(b.encodeJson()) as Map<String, Object?>;

    test('JSON: date, kind and summary per session, oldest first', () {
      final json = decode(withCoach([weekly, chat]));

      expect(json.keys, [
        'schemaVersion',
        'exportedAt',
        'dailyMetrics',
        'coachSessions',
      ]);
      expect(ExportBundle.coachSessionColumns, ['date', 'kind', 'summary']);
      expect(json['coachSessions'], [
        {'date': '2026-10-20', 'kind': 'chat', 'summary': null},
        {
          'date': '2026-10-23',
          'kind': 'weekly',
          'summary': 'Steps held at about 8,000; Thursday was "partial".',
        },
      ]);
    });

    test('JSON never carries the transcript', () {
      final encoded = withCoach([weekly, chat]).encodeJson();
      expect(encoded, isNot(contains('Something only the coach heard')));
      expect(encoded, isNot(contains('messages')));
      expect(encoded, isNot(contains('endedAt')));
    });

    test('JSON: an empty list is a coach with no sessions yet', () {
      expect(decode(withCoach(const []))['coachSessions'], isEmpty);
    });

    test('JSON: no coach on this device (null) leaves the key out', () {
      expect(decode(withCoach(null)).containsKey('coachSessions'), isFalse);
      expect(decode(bundle([fullDay])).containsKey('coachSessions'), isFalse);
    });

    final unreadable = ExportBundle(
      exportedAt: exportedAt,
      dailyMetrics: [fullDay],
      coachHistoryUnreadable: true,
    );

    test('JSON: unreadable coach history is null, distinct from [] and '
        'absent, and the daily rows are all there', () {
      final json = decode(unreadable);
      expect(json.containsKey('coachSessions'), isTrue);
      expect(json['coachSessions'], isNull);
      expect(json['schemaVersion'], 2);
      expect(json['dailyMetrics'], decode(bundle([fullDay]))['dailyMetrics']);

      final states = [
        decode(withCoach(const []))['coachSessions'],
        json['coachSessions'],
        decode(withCoach(null)).containsKey('coachSessions'),
      ];
      expect(states, [isEmpty, isNull, isFalse]);
    });

    test('CSV is unchanged by unreadable coach history', () {
      expect(unreadable.encodeCsv(), bundle([fullDay]).encodeCsv());
    });

    test('unreadable coach history carries no sessions', () {
      expect(
        () => ExportBundle(
          exportedAt: exportedAt,
          dailyMetrics: const [],
          coachSessions: const [],
          coachHistoryUnreadable: true,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('CSV is unchanged by coach sessions: one row per day', () {
      expect(
        withCoach([weekly, chat]).encodeCsv(),
        bundle([fullDay]).encodeCsv(),
      );
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
