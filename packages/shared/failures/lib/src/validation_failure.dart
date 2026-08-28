import 'package:failures/src/failure.dart';

/// An input-shape violation caught before ever reaching a datasource.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {super.cause});
}
