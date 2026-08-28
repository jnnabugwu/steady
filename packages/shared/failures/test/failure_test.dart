import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure subtypes', () {
    test('NotFoundFailure equality is based on message and cause', () {
      expect(
        const NotFoundFailure('missing'),
        const NotFoundFailure('missing'),
      );
      expect(
        const NotFoundFailure('missing'),
        isNot(const NotFoundFailure('other')),
      );
    });

    test('PlatformChannelFailure equality includes code', () {
      expect(
        const PlatformChannelFailure('channel error', code: 'E1'),
        const PlatformChannelFailure('channel error', code: 'E1'),
      );
      expect(
        const PlatformChannelFailure('channel error', code: 'E1'),
        isNot(const PlatformChannelFailure('channel error', code: 'E2')),
      );
    });

    test('ValidationFailure equality is based on message and cause', () {
      expect(
        const ValidationFailure('start must not be after end'),
        const ValidationFailure('start must not be after end'),
      );
    });

    test('UnknownFailure carries a cause', () {
      final cause = Exception('boom');
      final failure = UnknownFailure('unexpected', cause: cause);
      expect(failure.cause, cause);
    });
  });
}
