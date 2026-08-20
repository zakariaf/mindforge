/// Which physical axis a moment's motion travels along.
///
/// The vocabulary exists so that "does this mirror?" is answered once, by the
/// catalog, rather than at every animation site — and so the answer is about
/// **physics** rather than about which locale is loaded.
enum MotionAxis {
  /// Nothing translates.
  ///
  /// A scale pop, a colour cross-fade, a shadow stepping between elevations.
  /// There is no direction to mirror because there is no travel.
  none,

  /// Along the **reading** axis.
  ///
  /// The only value that mirrors. A route sliding in from the direction you
  /// read towards, a toggle knob travelling to the far end of its track, the
  /// horizontal shake of a wrong answer — all of these mean "forward" or
  /// "sideways" in the reader's terms, so all of them swap under RTL.
  inline,

  /// Along the screen's fixed vertical axis.
  ///
  /// A card rising into place, a sheet coming up from the bottom edge. Up is
  /// up in every language.
  vertical,

  /// Along the **light-source** axis.
  ///
  /// The axis the hard offset shadow defines — one imaginary light for the
  /// whole app, fixed at the top-start of the page. A pressed surface travels
  /// down its own shadow, and that shadow is a property of the design's
  /// lighting, **not** of reading direction. A Persian build whose buttons
  /// pressed up and to the left would be a bug, not a localization.
  fixed;

  /// Whether motion along this axis swaps direction under RTL.
  ///
  /// Exhaustive with no `default:`, so a fifth axis cannot be added without
  /// someone deciding what it means for direction.
  bool get mirrorsUnderRtl => switch (this) {
    MotionAxis.inline => true,
    MotionAxis.none || MotionAxis.vertical || MotionAxis.fixed => false,
  };
}
