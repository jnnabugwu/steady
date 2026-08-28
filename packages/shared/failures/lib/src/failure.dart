import 'package:equatable/equatable.dart';

/// Base type for every typed failure a repository can return.
abstract class Failure extends Equatable {
  const Failure(this.message, {this.cause});

  /// A human-readable description of what went wrong.
  final String message;

  /// The underlying exception/error that caused this failure, if any.
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}
