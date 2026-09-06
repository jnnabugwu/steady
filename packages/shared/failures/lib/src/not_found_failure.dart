import 'package:failures/src/failure.dart';

/// A single-record lookup by id that was expected to exist did not.
class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}
