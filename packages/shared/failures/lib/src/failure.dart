import 'package:equatable/equatable.dart';

/// Base type for every typed failure a repository can return.
///
/// Implements [Exception] so a Notifier can `throw` a [Failure] into
/// `AsyncValue.error` without tripping `only_throw_errors` (CLAUDE.md §4,
/// §9). Still hand-written, not freezed: freezed would compare `cause`.
abstract class Failure extends Equatable implements Exception {
  const Failure(this.message, {this.cause});

  /// A human-readable description of what went wrong.
  final String message;

  /// The underlying exception/error that caused this failure, if any.
  ///
  /// Diagnostic context only — deliberately **excluded from [props]**. At
  /// the `_data`-layer boundary `cause` is a freshly-caught exception
  /// instance, and most exception types compare by identity, so including
  /// it would make two failures for the same logical error (same [message],
  /// different `cause` instance) unequal. Equality is the stable [message]
  /// (plus any subclass discriminator like a `code`).
  final Object? cause;

  @override
  List<Object?> get props => [message];
}
