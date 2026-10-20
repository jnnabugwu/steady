import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure as Exception', () {
    test('a concrete Failure is an Exception', () {
      expect(const UnknownFailure('boom'), isA<Exception>());
    });

    test('can be thrown and caught as a Failure', () {
      expect(
        () => throw const NotFoundFailure('missing'),
        throwsA(
          isA<Failure>().having((f) => f.message, 'message', 'missing'),
        ),
      );
    });
  });
}
