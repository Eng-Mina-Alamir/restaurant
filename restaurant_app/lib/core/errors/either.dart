/// A lightweight functional `Either` type used as the outcome type for
/// repository and use-case operations.
///
/// Mirroring the classic sealed `Result`/`Either` pattern, [Left] carries a
/// failure while [Right] carries a value. This keeps the domain layer free of
/// third-party functional dependencies and lets call sites pattern-match with
/// `switch`/`when`.
/// Base sealed class for an operation that can succeed ([Right]) or fail
/// ([Left]).
sealed class Either<L, R> {
  const Either();

  bool get isLeft => this is Left<L, R>;
  bool get isRight => this is Right<L, R>;

  /// Pattern-matches this [Either], invoking [onLeft] for a [Left] value and
  /// [onRight] for a [Right] value.
  TResult when<TResult>({
    required TResult Function(L value) onLeft,
    required TResult Function(R value) onRight,
  }) {
    return switch (this) {
      Left<L, R>(:final value) => onLeft(value),
      Right<L, R>(:final value) => onRight(value),
    };
  }
}

/// Failure side of an [Either]; carries the reason an operation failed.
final class Left<L, R> extends Either<L, R> {
  final L value;

  const Left(this.value);
}

/// Success side of an [Either]; carries the produced value.
final class Right<L, R> extends Either<L, R> {
  final R value;

  const Right(this.value);
}

/// Convenience helpers to construct [Left] / [Right] with reduced boilerplate.
///
/// Not strictly required since the constructors are public, but kept for
/// readability at repository boundaries.
Either<L, R> left<L, R>(L value) => Left<L, R>(value);

Either<L, R> right<L, R>(R value) => Right<L, R>(value);
