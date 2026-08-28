import 'package:failures/src/failure.dart';

/// Catch-all for an unexpected exception at the `_data`-layer boundary.
class UnknownFailure extends Failure {
  const UnknownFailure(super.message, {super.cause});
}
