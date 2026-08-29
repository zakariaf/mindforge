import 'package:meta/meta.dart';
import 'package:mindforge/games/digit_bridge/domain/bridge_distractor.dart';

/// One Digit Bridge trial: a target numeral, and six candidates to match it.
///
/// **It carries no string and no script.** The target and the candidates are
/// integers; which numbering system each side renders in is decided at paint
/// time from [targetOnReaderScript] and the ambient locale. That is what lets a
/// golden vector be byte-identical in English, German, Persian and Sorani while
/// the board shows two different numbering systems at once.
@immutable
final class BridgeRound {
  /// Creates a round.
  const BridgeRound({
    required this.index,
    required this.target,
    required this.candidates,
    required this.correctIndex,
    required this.kinds,
    required this.targetOnReaderScript,
  });

  /// Where this round sits in the run, from zero.
  final int index;

  /// The number the player is asked to find.
  final int target;

  /// The six chips, in the order they are laid out.
  ///
  /// Exactly one equals [target]; the other five are near-misses drawn from
  /// [BridgeDistractor]. All six are distinct, so a round can never be won by
  /// tapping the duplicate.
  final List<int> candidates;

  /// Which chip is the target.
  final int correctIndex;

  /// How each chip differs from the target, `null` for the target itself.
  ///
  /// Parallel to [candidates] by index.
  ///
  /// **Generated evidence, and nothing renders it.** It exists so
  /// `bridge_round_generator_test` can assert the MIX — that a chip labelled a
  /// transposition really is one adjacent swap of the target — which is the
  /// only way to check the taxonomy is doing the work its doc claims. Deriving
  /// it at test time instead would be a second implementation of the taxonomy
  /// grading the first.
  final List<BridgeDistractor?> kinds;

  /// Whether the TARGET renders in the reader's own numbering system.
  ///
  /// When true the target takes the locale's script and the chips take the
  /// other; when false they swap. Seeded, so the player cannot learn that one
  /// side is always theirs and stop reading the other.
  ///
  /// **Relative to the reader, not absolute.** An absolute pin — "the target is
  /// always Latin" — would give a Persian player a board with no familiar side
  /// in half the rounds and an English player one with no unfamiliar side. The
  /// game is always "translate from or to what you know", in every locale.
  final bool targetOnReaderScript;

  /// This round as a stable string, for a golden vector.
  ///
  /// **Integers and enum indices, never `name` and never a formatted numeral.**
  /// A vector that moved with the language would mean localisation had leaked
  /// into generation, which for this game of all games is the defect to be
  /// most afraid of. The field order is part of the contract: changing it
  /// invalidates every frozen row.
  String canonical() =>
      '$index:$target:${candidates.join(',')}:$correctIndex:'
      '${kinds.map((kind) => kind?.index ?? -1).join(',')}:'
      '${targetOnReaderScript ? 1 : 0}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BridgeRound &&
          other.index == index &&
          other.target == target &&
          other.correctIndex == correctIndex &&
          other.targetOnReaderScript == targetOnReaderScript &&
          _sameList<int>(other.candidates, candidates) &&
          _sameList<BridgeDistractor?>(other.kinds, kinds);

  static bool _sameList<T>(List<T> a, List<T> b) {
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    index,
    target,
    correctIndex,
    targetOnReaderScript,
    Object.hashAll(candidates),
    Object.hashAll(kinds),
  );

  @override
  String toString() => 'BridgeRound(${canonical()})';
}
