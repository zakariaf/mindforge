import 'package:meta/meta.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// One Stroop trial: a word, an ink, and four keys to answer with.
///
/// **It carries no string.** The colour *word* is a `PlayAnswer` and becomes
/// text only at render, through the ARB — which is what lets a golden vector be
/// byte-identical in English, German, Persian and Sorani while the screen shows
/// four different alphabets.
@immutable
final class StroopRound {
  /// Creates a round.
  const StroopRound({
    required this.index,
    required this.word,
    required this.ink,
    required this.options,
    required this.isColourBlindPalette,
  });

  /// Where this round sits in the run, from zero.
  final int index;

  /// The colour the printed word NAMES.
  ///
  /// It need not be on the board: naming a colour the player cannot tap is a
  /// legitimate trial, and it is the one the reflex most wants to answer.
  final PlayAnswer word;

  /// The colour the word is PRINTED IN. This is the answer.
  final PlayAnswer ink;

  /// The four keys, in the order they are laid out.
  ///
  /// Always four, always distinct, and always carrying four distinct
  /// [PlayFill]s — hue is never the only channel, so two keys a colour-blind
  /// player could not tell apart are never offered together.
  final List<PlayAnswer> options;

  /// Whether this round was generated for the colour-blind palette.
  ///
  /// **Captured onto the round, not read from settings at paint time.** A
  /// player who flips the setting mid-run keeps playing the round they were
  /// dealt; the change takes effect on the next run, which is the only
  /// behaviour that cannot rewrite a question after it was asked.
  final bool isColourBlindPalette;

  /// Whether the word names its own ink.
  bool get isCongruent => word == ink;

  /// This round as a stable string, for a golden vector.
  ///
  /// **Enum INDICES, never `name` and never `toString()`.** Both are one
  /// refactor away from a translated string, and a vector that moved with the
  /// language would mean localisation had leaked into generation. The field
  /// order is part of the contract: changing it invalidates every frozen row.
  String canonical() =>
      '$index:${word.index}:${ink.index}:'
      '${options.map((answer) => answer.index).join(',')}:'
      '${isColourBlindPalette ? 1 : 0}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StroopRound &&
          other.index == index &&
          other.word == word &&
          other.ink == ink &&
          other.isColourBlindPalette == isColourBlindPalette &&
          _sameOptions(other.options);

  bool _sameOptions(List<PlayAnswer> other) {
    if (other.length != options.length) return false;

    for (var i = 0; i < options.length; i++) {
      if (other[i] != options[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    index,
    word,
    ink,
    isColourBlindPalette,
    Object.hashAll(options),
  );

  @override
  String toString() => 'StroopRound(${canonical()})';
}
