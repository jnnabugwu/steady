import 'package:failures/src/failure.dart';

/// A `_data`-layer boundary mapping of a platform-channel error (e.g. a
/// caught `PlatformException`). UI never sees the raw platform exception.
class PlatformChannelFailure extends Failure {
  const PlatformChannelFailure(super.message, {this.code, super.cause});

  /// The platform exception's error code, if any.
  final String? code;

  @override
  List<Object?> get props => [message, code];
}
