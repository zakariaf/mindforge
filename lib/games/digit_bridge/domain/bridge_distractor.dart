/// How a wrong candidate on the Digit Bridge board differs from the target.
///
/// **The taxonomy is the difficulty.** Six random numbers would make the board
/// a spot-the-shape exercise a player could win without reading either script;
/// six near-misses force an actual digit-by-digit comparison across two
/// numbering systems, which is the whole task.
///
/// Every kind is defined over the DIGITS of the target, never over its value.
/// `472` and `427` are 45 apart and one transposition away, and it is the
/// second number that describes the difficulty.
enum BridgeDistractor {
  /// Two adjacent digits swapped: `472` -> `427`.
  ///
  /// The hardest kind to catch across scripts, because the digit multiset is
  /// unchanged — a reader who recognises the *set* of glyphs without ordering
  /// them will take it.
  transposition,

  /// One digit replaced by a different one: `472` -> `672`.
  ///
  /// The kind a reader who has genuinely learnt the other script rejects
  /// fastest, which is why it is the one that keeps the board fair.
  substitution,

  /// The same digits in a different, non-adjacent order: `472` -> `724`.
  ///
  /// A transposition is technically a reordering; this names the ones that are
  /// not reachable by a single adjacent swap, so the two kinds do not collapse.
  reordering,

  /// A digit added or dropped: `472` -> `472` becomes `47` or `4723`.
  ///
  /// The only kind that changes the *length* of the run, so it is the one a
  /// player can reject peripherally — which is what makes it the easy rung the
  /// other three are measured against.
  lengthChange,
}
