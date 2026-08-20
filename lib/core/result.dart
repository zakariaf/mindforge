import 'package:meta/meta.dart';
import 'package:mindforge/core/failure.dart';

/// The outcome of an operation that can fail recoverably: either an [Ok]
/// carrying a value of type [T], or an [Err] carrying a [Failure] of type [F].
///
/// Sealed, so a `switch` over it needs no `default:` and adding a third variant
/// is a compile error at every call site rather than a silently taken fallback.
///
/// Nothing recoverable throws. A method returning `Result` never completes with
/// an error; if it does, that is a bug in the method, not a failure mode of the
/// operation.
@immutable
sealed class Result<T, F extends Failure> {
  /// Creates a result.
  const Result();
}

/// A successful [Result] carrying [value].
@immutable
final class Ok<T, F extends Failure> extends Result<T, F> {
  /// Creates a successful result carrying [value].
  const Ok(this.value);

  /// The value the operation produced.
  final T value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Ok<T, F> && other.value == value;

  @override
  int get hashCode => Object.hash(Ok, value);

  @override
  String toString() => 'Ok($value)';
}

/// A failed [Result] carrying [failure].
@immutable
final class Err<T, F extends Failure> extends Result<T, F> {
  /// Creates a failed result carrying [failure].
  const Err(this.failure);

  /// Why the operation did not produce a value.
  final F failure;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Err<T, F> && other.failure == failure;

  @override
  int get hashCode => Object.hash(Err, failure);

  @override
  String toString() => 'Err(${failure.code})';
}

/// Combinators over [Result].
///
/// They live in an extension rather than on the sealed class so that adding one
/// never tempts anyone to add a variant-specific override alongside it.
extension ResultX<T, F extends Failure> on Result<T, F> {
  /// Collapses this result to a single value of type [R] by applying [onOk] to
  /// an [Ok] and [onErr] to an [Err].
  ///
  /// Both arms are required, which is the point: there is no way to handle the
  /// success case and forget the failure one.
  R fold<R>({
    required R Function(T value) onOk,
    required R Function(F failure) onErr,
  }) => switch (this) {
    Ok<T, F>(:final value) => onOk(value),
    Err<T, F>(:final failure) => onErr(failure),
  };

  /// Transforms an [Ok] value with [transform], passing an [Err] through
  /// **unchanged** — the identical failure instance, so its typed params
  /// survive.
  Result<R, F> map<R>(R Function(T value) transform) => switch (this) {
    Ok<T, F>(:final value) => Ok<R, F>(transform(value)),
    Err<T, F>(:final failure) => Err<R, F>(failure),
  };

  /// Whether this is an [Ok].
  bool get isOk => this is Ok<T, F>;
}
