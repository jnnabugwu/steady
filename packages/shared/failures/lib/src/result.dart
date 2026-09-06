import 'package:failures/src/failure.dart';

/// Shorthand for the return type of every async repository method in this
/// codebase: a `Future` of a `Result<T>`. Purely a typedef -- interchangeable
/// with `Future<Result<T>>` everywhere, no behavior change.
typedef ResultFuture<T> = Future<Result<T>>;

/// The outcome of an operation that can fail: either a success value of
/// type [T], or a [Failure].
sealed class Result<T> {
  const Result();

  /// Reduces this [Result] to a single value by calling [onErr] or [onOk]
  /// depending on which case this is.
  R fold<R>(R Function(Failure failure) onErr, R Function(T value) onOk) =>
      switch (this) {
        Ok<T>(value: final v) => onOk(v),
        Err<T>(failure: final f) => onErr(f),
      };
}

/// A successful [Result] carrying [value].
final class Ok<T> extends Result<T> {
  const Ok(this.value);

  /// The success value.
  final T value;
}

/// A failed [Result] carrying [failure].
final class Err<T> extends Result<T> {
  const Err(this.failure);

  /// The failure that occurred.
  final Failure failure;
}
