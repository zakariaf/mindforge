/// The nine sounds the design names.
///
/// **Names only.** No asset ships, no audio package is depended on and no
/// player exists: the slots are declared so the catalog is complete and so a
/// later epic wires nine known cues rather than inventing them per screen.
enum SoundCue {
  /// A correct answer landing.
  pop,

  /// A selection.
  tick,

  /// A run starting.
  go,

  /// A wrong answer.
  thud,

  /// A tile being found.
  click,

  /// A streak milestone.
  chime,

  /// The clock running low.
  alert,

  /// A run ending.
  end,

  /// A personal best.
  fanfare,
}
