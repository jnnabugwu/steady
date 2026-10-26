import 'package:coach_domain/coach_domain.dart';
import 'package:coach_presentation/coach_presentation.dart';
import 'package:failures/failures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show ProviderException;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the coach model is unbound until the app overrides it', () {
    final container = ProviderContainer.test();
    expect(
      () => container.read(coachModelProvider),
      throwsA(
        isA<ProviderException>().having(
          (e) => e.exception,
          'exception',
          isA<UnimplementedError>(),
        ),
      ),
    );
  });

  test('an override is what the coach reads', () {
    final model = _FakeCoachModel();
    final container = ProviderContainer.test(
      overrides: [coachModelProvider.overrideWithValue(model)],
    );
    expect(container.read(coachModelProvider), same(model));
  });
}

class _FakeCoachModel implements CoachModel {
  @override
  ResultFuture<CoachModelInfo> checkAvailability() async =>
      const Err(CoachDeviceNotEligibleFailure());

  @override
  ResultFuture<CoachModelSession> startSession({
    required String instructions,
  }) async => const Err(CoachDeviceNotEligibleFailure());

  @override
  Stream<Result<String>> streamResponse(
    CoachModelSession session,
    String prompt,
  ) => const Stream.empty();

  @override
  ResultFuture<Unit> cancelResponse(CoachModelSession session) async =>
      const Ok(unit);

  @override
  ResultFuture<Unit> endSession(CoachModelSession session) async =>
      const Ok(unit);
}
