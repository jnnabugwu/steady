import 'package:failures/failures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unit is usable as a Result<Unit> value', () {
    const result = Ok<Unit>(unit);
    expect(result.fold((f) => null, (v) => v), isA<Unit>());
  });
}
