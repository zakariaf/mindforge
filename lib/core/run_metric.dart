import 'package:meta/meta.dart';
import 'package:mindforge/core/score_format.dart';

/// The outcome of comparing two [RunMetric]s.
///
/// Sealed because the comparison is **total**: comparing points against
/// milliseconds is a real thing that can happen to a corrupt row, and it
/// returns a value rather than throwing.
@immutable
sealed class MetricComparison {
  /// Creates a comparison outcome.
  const MetricComparison();
}

/// Both metrics shared a [ScoreFormat] and the comparison succeeded.
@immutable
final class BetterThan extends MetricComparison {
  /// Creates a successful comparison whose answer is [isBetter].
  const BetterThan(this.isBetter);

  /// Whether the left-hand metric beats the right-hand one, in the direction
  /// its [ScoreFormat] defines.
  final bool isBetter;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BetterThan && other.isBetter == isBetter;

  @override
  int get hashCode => Object.hash(BetterThan, isBetter);

  @override
  String toString() => 'BetterThan($isBetter)';
}

/// The two metrics carried different [ScoreFormat]s, so there is no ordering
/// between them.
///
/// This is what a mixed-`metric_kind` scope surfaces instead of silently
/// comparing a point total against a millisecond count.
@immutable
final class ScoreFormatMismatch extends MetricComparison {
  /// Creates a mismatch between [left] and [right].
  const ScoreFormatMismatch(this.left, this.right);

  /// The left-hand operand's format.
  final ScoreFormat left;

  /// The right-hand operand's format.
  final ScoreFormat right;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ScoreFormatMismatch &&
          other.left == left &&
          other.right == right;

  @override
  int get hashCode => Object.hash(ScoreFormatMismatch, left, right);

  @override
  String toString() => 'ScoreFormatMismatch($left, $right)';
}

/// A score, as the integer the game produced plus the [ScoreFormat] that says
/// how to read it.
///
/// It carries **no formatter and no display string**, permanently. `1480`
/// renders as `1,480` in English, `1.480` in German and `۱٬۴۸۰` in Persian;
/// those are projections E04's `LocaleNumbers` owns, and a `toString` here that
/// looked like a display value is how one of them ends up in a database column.
@immutable
final class RunMetric {
  /// Creates a metric of [format] holding [value].
  const RunMetric({required this.format, required this.value});

  /// A [ScoreFormat.points] metric holding [value] points.
  const RunMetric.points(int value)
    : this(format: ScoreFormat.points, value: value);

  /// A [ScoreFormat.duration] metric holding [milliseconds].
  const RunMetric.duration(int milliseconds)
    : this(format: ScoreFormat.duration, value: milliseconds);

  /// How to read [value], and which direction is better.
  final ScoreFormat format;

  /// The raw integer: a point total for [ScoreFormat.points], a millisecond
  /// count for [ScoreFormat.duration]. Never negative.
  final int value;

  /// Whether this metric beats [other], in the direction [format] defines.
  ///
  /// Total: two different formats yield a [ScoreFormatMismatch] rather than a
  /// throw. This is the **one** place the MAX-versus-MIN direction is written
  /// down; the repository's personal-best read calls it rather than repeating
  /// the comparison in SQL.
  MetricComparison isBetterThan(RunMetric other) {
    if (format != other.format) {
      return ScoreFormatMismatch(format, other.format);
    }
    return BetterThan(
      switch (format) {
        ScoreFormat.points => value > other.value,
        ScoreFormat.duration => value < other.value,
      },
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunMetric && other.format == format && other.value == value;

  @override
  int get hashCode => Object.hash(format, value);

  @override
  String toString() => 'RunMetric(${format.name}, $value)';
}
