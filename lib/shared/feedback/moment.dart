/// Every moment the app can acknowledge, named once.
///
/// A **moment** is a thing that happened, not a thing that plays. The catalog
/// is a closed set so that motion, haptics and sound are three columns of one
/// table rather than three sets of call sites that drift apart — and so that a
/// screen fires `Moment.answerCorrect` without knowing, or being able to
/// choose, what that feels like.
///
/// Transcribed from `sunburst-motion-and-haptics`' catalog table, in its order.
/// **E06 owns the map from a moment to its haptic, its sound and its
/// animation.** This file deliberately holds no behaviour: adding a case here
/// is a design decision, and an exhaustive `switch` in E06 is what makes that
/// decision impossible to forget.
///
/// Every moment carries a non-motion residue — a state that survives Sound off,
/// Haptics off and Reduce motion on — which is why the acknowledgement is never
/// only the animation.
enum Moment {
  /// A pressable surface took a pointer down.
  buttonPress,

  /// A tap resolved on a pressable surface.
  buttonCommit,

  /// Home built for the first time.
  homeCardEnter,

  /// A difficulty segment was chosen.
  difficultySelect,

  /// One of the three countdown beats.
  countdownBeat,

  /// The countdown finished and the board appeared.
  runStart,

  /// A correct answer was committed.
  answerCorrect,

  /// A wrong answer was committed.
  answerWrong,

  /// The correct Schulte tile was tapped.
  tileFound,

  /// The next Schulte tile became the target.
  tileNextCue,

  /// The streak crossed a multiple of five.
  streakMilestone,

  /// The clock crossed into its last five seconds.
  timerAlarm,

  /// The run ended, by answer or by clock.
  runEnd,

  /// The results screen settled.
  resultsReveal,

  /// The run beat the stored best.
  personalBest,

  /// A settings toggle flipped.
  toggleFlip,

  /// The pause sheet opened or closed.
  sheetTransition,

  /// Any route push or pop.
  routeTransition,
}
