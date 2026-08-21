/// What one tile is doing.
///
/// The board draws each of these differently, and `sunburst-game-surfaces`
/// rule 4 applies: no state is told apart by hue alone.
enum SchulteTileState {
  /// Waiting, and not the one being looked for.
  idle,

  /// The value the player is hunting right now.
  ///
  /// **A cue, not an answer.** It is what makes the board learnable on the
  /// first run; a player who does not need it stops seeing it.
  next,

  /// Already tapped, in order.
  found,

  /// Tapped out of order, until the next tap resolves the latch.
  wrong,

  /// On screen but not playable.
  ///
  /// **DERIVED.** No design state matrix names a trigger for it, because the
  /// design never drew the board behind a countdown. It exists because this
  /// engine builds the board when the run starts — which is three seconds
  /// before the run begins — and a board that accepted taps during 3-2-1 would
  /// hand out a free head start.
  disabled,
}
