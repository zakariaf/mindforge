/// How far one False Light tile sits from the surface.
///
/// **Depth is the whole game, and it is the only channel.** The board carries
/// no text and no colour information: a tile is told apart from its neighbour
/// by whether the app's one light source lands on it, which is the same shape
/// language every raised surface in Sunburst Pop already uses. That makes it
/// the one board in the app that reads identically in English, German, Persian
/// and Sorani without a single string being translated.
///
/// Payload-free on purpose. A `pressed` case carrying a colour, a label or a
/// score would be the moment depth stopped being the only channel, and
/// `sunburst-game-surfaces` rule 4 read backwards: hue is never the only
/// channel here because hue is not a channel at all.
enum TileDepth {
  /// Standing proud of the board, lit from the app's one imaginary light.
  ///
  /// The distractor, and the majority of every field.
  raised,

  /// Pushed flat into the board, with no offset shadow to catch the light.
  ///
  /// The target. Sweeping every one of these is what finishes a field.
  pressed,
}
