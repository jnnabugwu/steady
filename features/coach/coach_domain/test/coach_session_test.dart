import 'package:coach_domain/coach_domain.dart';
import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final start = DateTime(2026, 10, 23, 19);

  CoachSession session({
    String id = 's1',
    DateTime? startedAt,
    DateTime? endedAt,
  }) => CoachSession(
    id: id,
    kind: CoachSessionKind.weekly,
    startedAt: startedAt ?? start,
    endedAt: endedAt,
  );

  group('CoachSession', () {
    test('starts with an empty transcript and no summary', () {
      final s = session();
      expect(s.messages, isEmpty);
      expect(s.endedAt, isNull);
      expect(s.summary, isNull);
    });

    test('compares by value, transcript included', () {
      final message = CoachMessage(
        role: CoachMessageRole.coach,
        text: 'How did the week feel?',
        at: start,
      );
      expect(
        session().copyWith(messages: [message]),
        session().copyWith(messages: [message]),
      );
      expect(session().copyWith(messages: [message]), isNot(session()));
    });
  });

  group('validateCoachSession', () {
    test('accepts an open or ended session', () {
      expect(validateCoachSession(session()), isNull);
      expect(validateCoachSession(session(endedAt: start)), isNull);
      expect(
        validateCoachSession(
          session(endedAt: start.add(const Duration(minutes: 15))),
        ),
        isNull,
      );
    });

    test('rejects an empty id', () {
      expect(validateCoachSession(session(id: '')), isA<ValidationFailure>());
    });

    test('rejects an end before the start', () {
      expect(
        validateCoachSession(
          session(endedAt: start.subtract(const Duration(seconds: 1))),
        ),
        isA<ValidationFailure>(),
      );
    });
  });

  test('compareCoachSessionsNewestFirst: newest first, ties by id', () {
    final sessions = [
      session(id: 'b', startedAt: DateTime(2026, 10, 20)),
      session(id: 'old', startedAt: DateTime(2026, 9, 30)),
      session(id: 'a', startedAt: DateTime(2026, 10, 20)),
      session(id: 'new', startedAt: DateTime(2026, 10, 23)),
    ]..sort(compareCoachSessionsNewestFirst);
    expect(sessions.map((s) => s.id), ['new', 'a', 'b', 'old']);
  });

  test('history failures are typed Failures', () {
    expect(
      const CoachHistoryUnreadableFailure('bad'),
      isA<Failure>().having((f) => f.message, 'message', 'bad'),
    );
    expect(const CoachHistoryStorageFailure('io'), isA<Failure>());
  });
}
