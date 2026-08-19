/// How a game's score is interpreted, and therefore which direction is better.
///
/// The **one** score vocabulary in the project. `GameDefinition.scoreFormat`
/// (E07) imports this enum, and the `runs.metric_kind` column stores
/// `ScoreFormat.name` exactly — a second enum beside it would be one rename
/// away from a silent mismatch on the single column that decides MAX versus MIN.
enum ScoreFormat {
  /// A point total. **Higher is better.** Stored as an integer count.
  points,

  /// An elapsed time in milliseconds. **Lower is better.** Stored as an integer
  /// millisecond count, never as a rounded `18.6`.
  duration,
}
