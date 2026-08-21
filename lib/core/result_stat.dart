import 'package:meta/meta.dart';

/// How a [ResultStat]'s canonical integer should be rendered.
///
/// **A presentation enum, and deliberately not E02's `ScoreFormat`.** That one
/// is mirrored by the `runs.metric_kind` CHECK constraint, so adding `percent`
/// to it would be a schema migration to serve a label. This one never reaches
/// the database — a policy test says so.
enum StatFormat {
  /// The canonical value is a count of points.
  points,

  /// The canonical value is **milliseconds**.
  duration,

  /// The canonical value is **per mille** — 923 is 92.3%.
  ///
  /// Per mille rather than a double, so the canonical value stays an integer
  /// all the way through: a rounded percentage is a display decision, and
  /// making it here would freeze one locale's idea of precision.
  percent,

  /// The canonical value is a count of items.
  count,

  /// The canonical value is a streak MULTIPLIER, rendered as `×7`.
  ///
  /// Its own format rather than [count] with the sign glued on at the call
  /// site, for two reasons a game cannot solve on its own. The sign moves: the
  /// design draws `x7` in English and `۷×` in Persian, which is the bidi
  /// algorithm reordering a mixed run, so the shell has to isolate it. And the
  /// word is an ICU message with a plural, which only the shell can resolve.
  ///
  /// Added by E09, and the seam is what made it safe: `HudRow`'s switch is
  /// exhaustive with no `default:`, so a game declaring this format did not
  /// compile until the shell learnt to render it.
  multiplier,
}

/// One cell of the results trio: an ARB key and a canonical integer.
///
/// **Never a formatted string.** A stat holding `"۱۸٫۶ ثانیه"` goes stale the
/// moment the player changes language in Settings, and a stat holding
/// `"18.6s"` is an English sentence in four locales. E08 resolves [labelKey]
/// and formats [canonicalValue] at render, through the locale that is active
/// then.
@immutable
final class ResultStat {
  /// Creates a stat.
  const ResultStat({
    required this.labelKey,
    required this.canonicalValue,
    required this.format,
  });

  /// The ARB key naming this stat.
  final String labelKey;

  /// The value, in [format]'s canonical unit.
  final int canonicalValue;

  /// How to render [canonicalValue].
  final StatFormat format;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ResultStat &&
          other.labelKey == labelKey &&
          other.canonicalValue == canonicalValue &&
          other.format == format;

  @override
  int get hashCode => Object.hash(labelKey, canonicalValue, format);

  @override
  String toString() => 'ResultStat($labelKey, $canonicalValue, ${format.name})';
}
