/// Where a run is in its lifecycle.
///
/// The machine is a **pure, total function** decided here, before any notifier
/// exists: legality is a property of the pair, not of whatever the notifier
/// happened to check at the call site. Every one of the twenty-five cells has
/// an answer and a test names it.
enum RunPhase {
  /// Nothing has started. The play scaffold is mounted and waiting.
  idle,

  /// The 3-2-1 is running.
  countdown,

  /// The board is live and the ticker is advancing.
  playing,

  /// The pause sheet is up. The ticker is stopped, not slowed.
  paused,

  /// The run ended. **Terminal.**
  over;

  /// Whether this phase may become [next].
  ///
  /// Exhaustive over both enums with no `default:` and no `case _:`, so adding
  /// a sixth phase is a compile error here rather than a silently illegal edge
  /// somewhere else.
  ///
  /// **No phase transitions to itself.** A self-transition is either a no-op
  /// dressed as a state change — which makes a Riverpod listener fire for
  /// nothing — or a restart wearing the wrong name; `idle -> countdown` is how
  /// a run restarts.
  bool canTransitionTo(RunPhase next) => switch ((this, next)) {
    // Starting a run, and backing out of the countdown before it finishes.
    (RunPhase.idle, RunPhase.countdown) => true,
    (RunPhase.countdown, RunPhase.playing) => true,
    (RunPhase.countdown, RunPhase.idle) => true,

    // Pausing, resuming through a fresh countdown, and ending.
    (RunPhase.playing, RunPhase.paused) => true,
    (RunPhase.playing, RunPhase.over) => true,
    (RunPhase.paused, RunPhase.countdown) => true,
    (RunPhase.paused, RunPhase.over) => true,

    // Everything else, including all five self-transitions and every edge out
    // of `over`.
    (RunPhase.idle, _) => false,
    (RunPhase.countdown, _) => false,
    (RunPhase.playing, _) => false,
    (RunPhase.paused, _) => false,
    (RunPhase.over, _) => false,
  };
}
