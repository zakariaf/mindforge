import 'package:meta/meta.dart';
import 'package:mindforge/core/score_format.dart';

/// Renders a canonical score value as display text.
///
/// **It holds no formatter and imports nothing outside `lib/core/`.** The two
/// number closures arrive from E04's single `LocaleNumbers` and the unit
/// pattern arrives from the ARB, so this file cannot construct a
/// `NumberFormat`, cannot read an ambient locale and cannot know the word for
/// "seconds". That is the rule E02 and E04 each assert from their own side, and
/// this is the file most likely to break it: it is the one place in the engine
/// whose whole job is to produce a string a person reads.
///
/// The unit is composed rather than concatenated by hand. `18.6` and `s` are
/// two runs, and gluing a value to its unit is what breaks in RTL — the ARB
/// pattern decides where the unit goes, per locale.
@immutable
final class ScoreFormatter {
  /// Creates a formatter from the closures a locale supplies.
  const ScoreFormatter({
    required this.formatPoints,
    required this.formatSeconds,
    required this.durationLabel,
  });

  /// Renders a point total, grouped, with no fraction digits.
  final String Function(int points) formatPoints;

  /// Renders a duration in milliseconds as seconds with one fraction digit.
  final String Function(int milliseconds) formatSeconds;

  /// Composes a rendered seconds value with its unit, per the ARB pattern.
  final String Function(String secondsText) durationLabel;

  /// Renders [value] the way [format] says to.
  ///
  /// The canonical value is an integer in both cases — points, or elapsed
  /// milliseconds — because that is what the `runs` table stores and what a
  /// golden vector freezes. A formatted string never travels back down.
  String format(ScoreFormat format, int value) => switch (format) {
    ScoreFormat.points => formatPoints(value),
    ScoreFormat.duration => durationLabel(formatSeconds(value)),
  };
}
