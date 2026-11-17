import 'dart:async';
import 'dart:convert';

import 'package:coach_data/coach_data.dart';
import 'package:flutter_test/flutter_test.dart';

Future<List<CoachSseEvent>> parse(List<List<int>> chunks) =>
    coachSseEvents(Stream.fromIterable(chunks)).toList();

void main() {
  test('reads named events, one per blank line', () async {
    final events = await parse([
      utf8.encode(
        'event: snapshot\ndata: {"text":"Hi"}\n\n'
        'event: done\ndata: {"stopReason":"end_turn"}\n\n',
      ),
    ]);
    expect(events, const [
      CoachSseEvent('snapshot', '{"text":"Hi"}'),
      CoachSseEvent('done', '{"stopReason":"end_turn"}'),
    ]);
  });

  test('joins data lines, ignores comments and other fields, and names an '
      'unnamed event "message"', () async {
    final events = await parse([
      utf8.encode(
        ': keep-alive\n'
        'id: 7\n'
        'retry: 100\n'
        'data: one\n'
        'data:two\n'
        '\n',
      ),
    ]);
    expect(events, const [CoachSseEvent('message', 'one\ntwo')]);
  });

  test(r'accepts \r\n and \r line endings', () async {
    final events = await parse([
      utf8.encode('event: a\r\ndata: 1\r\n\r\nevent: b\rdata: 2\r\r'),
    ]);
    expect(events, const [CoachSseEvent('a', '1'), CoachSseEvent('b', '2')]);
  });

  test('a blank line with no data dispatches nothing', () async {
    expect(await parse([utf8.encode('event: lonely\n\n\n')]), isEmpty);
  });

  test('an event without its closing blank line is dropped at the end', () {
    expect(
      parse([utf8.encode('event: done\ndata: {"stopReason":"end_turn"}\n')]),
      completion(isEmpty),
    );
  });

  test('chunk boundaries can fall anywhere: mid-line, mid-CRLF, '
      'mid-character', () async {
    // Multi-byte UTF-8 (é is 2 bytes, 🙂 is 4) and CRLF line endings.
    final bytes = utf8.encode(
      'event: snapshot\r\ndata: {"text":"Café 🙂"}\r\n\r\n'
      'event: snapshot\ndata: {"text":"Café 🙂 done."}\n\n'
      'event: done\ndata: {"stopReason":"max_tokens"}\n\n',
    );
    const expected = [
      CoachSseEvent('snapshot', '{"text":"Café 🙂"}'),
      CoachSseEvent('snapshot', '{"text":"Café 🙂 done."}'),
      CoachSseEvent('done', '{"stopReason":"max_tokens"}'),
    ];
    for (var i = 1; i < bytes.length; i++) {
      final events = await parse([bytes.sublist(0, i), bytes.sublist(i)]);
      expect(events, expected, reason: 'split at byte $i');
    }
    // And one byte at a time.
    expect(
      await parse([
        for (final b in bytes) [b],
      ]),
      expected,
    );
  });

  test('malformed UTF-8 is an error on the stream', () {
    expect(
      parse([
        [...utf8.encode('data: '), 0xff, 0xfe, 10, 10],
      ]),
      throwsA(isA<FormatException>()),
    );
  });

  test('cancelling the events cancels the bytes', () async {
    var cancelled = false;
    final bytes = StreamController<List<int>>(onCancel: () => cancelled = true);
    final subscription = coachSseEvents(bytes.stream).listen((_) {});
    bytes.add(utf8.encode('data: x\n\n'));
    await pumpEventQueue();
    await subscription.cancel();
    expect(cancelled, isTrue);
  });

  test('toString leaves the data out', () {
    expect(
      const CoachSseEvent('snapshot', 'secret reply').toString(),
      isNot(contains('secret')),
    );
  });
}
