import 'dart:convert';

import 'package:flutter/foundation.dart';

/// One server-sent event: its name (`event:`, or `message` when absent) and
/// its data (every `data:` line, joined with newlines).
@immutable
class CoachSseEvent {
  /// Creates an event.
  const CoachSseEvent(this.event, this.data);

  /// The event's name.
  final String event;

  /// The event's data.
  final String data;

  @override
  bool operator ==(Object other) =>
      other is CoachSseEvent && other.event == event && other.data == data;

  @override
  int get hashCode => Object.hash(event, data);

  /// The name and the data's length only: the data can be reply text.
  @override
  String toString() => 'CoachSseEvent($event, ${data.length} chars)';
}

/// The events in a server-sent event byte stream, per the WHATWG
/// `text/event-stream` format: UTF-8, lines ended by `\n`, `\r\n` or `\r`,
/// an event dispatched at each blank line. Chunk boundaries can fall
/// anywhere, mid-line or mid-character.
///
/// Comment lines (`:`) and fields other than `event` and `data` are
/// ignored. An event left without its closing blank line when the stream
/// ends is dropped, as the format says; the proxy ends every event with one.
/// Malformed UTF-8 is an error on the stream.
///
/// Cancelling the subscription cancels [bytes].
Stream<CoachSseEvent> coachSseEvents(Stream<List<int>> bytes) {
  final decoder = _SseDecoder();
  return bytes
      .transform(utf8.decoder)
      .transform(const LineSplitter())
      .expand(decoder.addLine);
}

class _SseDecoder {
  String? _event;
  final List<String> _data = [];

  /// The events [line] completes: none, or one at a blank line.
  List<CoachSseEvent> addLine(String line) {
    if (line.isEmpty) {
      final event = _data.isEmpty
          ? null
          : CoachSseEvent(_event ?? 'message', _data.join('\n'));
      _event = null;
      _data.clear();
      return [?event];
    }
    if (line.startsWith(':')) return const [];
    final colon = line.indexOf(':');
    final field = colon < 0 ? line : line.substring(0, colon);
    var value = colon < 0 ? '' : line.substring(colon + 1);
    if (value.startsWith(' ')) value = value.substring(1);
    switch (field) {
      case 'event':
        _event = value;
      case 'data':
        _data.add(value);
    }
    return const [];
  }
}
