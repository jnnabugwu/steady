import 'package:coach_domain/coach_domain.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const secret = 'I ate 3,200 kcal and had 4 cravings';

  test('turns, requests and snapshots compare by value', () {
    expect(const CoachTurn.person('a'), const CoachTurn.person('a'));
    expect(const CoachTurn.person('a'), isNot(const CoachTurn.coach('a')));
    expect(
      const CoachTurn.app(WeeklyTopic.steps),
      const CoachTurn.app(WeeklyTopic.steps),
    );
    expect(
      const CoachRequest(
        kind: CoachRequestKind.chat,
        weekContext: 'w',
        turns: [CoachTurn.person('a')],
      ),
      const CoachRequest(
        kind: CoachRequestKind.chat,
        weekContext: 'w',
        turns: [CoachTurn.person('a')],
      ),
    );
    expect(
      const CoachReplySnapshot(text: 'a', stopReason: CoachStopReason.endTurn),
      isNot(const CoachReplySnapshot(text: 'a')),
    );
  });

  test("toString never prints what was said or the week's data", () {
    const request = CoachRequest(
      kind: CoachRequestKind.weekly,
      weekContext: secret,
      turns: [
        CoachTurn.app(WeeklyTopic.cravings),
        CoachTurn.coach(secret),
        CoachTurn.person(secret),
      ],
    );
    for (final value in <Object>[
      request,
      ...request.turns,
      const CoachReplySnapshot(text: secret),
    ]) {
      expect(value.toString(), isNot(contains(secret)), reason: '$value');
    }
    expect(request.toString(), contains('weekly'));
    expect(request.toString(), contains('turns: 3'));
    expect(request.turns.first.toString(), contains('cravings'));
  });
}
