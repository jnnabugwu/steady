/// A type with exactly one value, used in place of `void` as the value type
/// of a `Result` when a method only signals success or failure.
final class Unit {
  const Unit._();
}

/// The single [Unit] instance.
const unit = Unit._();
