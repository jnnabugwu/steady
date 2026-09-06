import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Result', () {
    test('Ok.fold calls onOk with the value', () {
      const result = Ok<int>(42);
      final folded = result.fold((f) => -1, (v) => v);
      expect(folded, 42);
    });

    test('Err.fold calls onErr with the failure', () {
      const failure = ValidationFailure('bad input');
      const result = Err<int>(failure);
      final folded = result.fold((f) => f.message, (v) => 'unreachable');
      expect(folded, 'bad input');
    });
  });
}
