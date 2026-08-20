/// How hard a run is, in display order.
///
/// **It carries an ARB key and nothing else.** In particular it carries no run
/// limit: a duration here would force every game to be timed the same way, and
/// Schulte Grid is not timed at all — it ends when the last tile is found. A
/// `runLimit` on this enum is exactly what turns that into a special case in
/// the shell instead of a property of the game, so `GameDefinition` owns the
/// length and this enum owns the name.
///
/// The `name` is what is persisted — the `runs` table joins on it — and the
/// [labelKey] is what is rendered. They are deliberately different strings: a
/// translation edit must never move a join key, and an ARB key rename must
/// never orphan a row.
enum Difficulty {
  /// Longest, most forgiving.
  chill,

  /// The default.
  classic,

  /// Shortest, hardest.
  blitz;

  /// The ARB key whose translation names this difficulty.
  ///
  /// A key, never a label. A word on an enum is a word four locales cannot
  /// change.
  String get labelKey => switch (this) {
    Difficulty.chill => 'difficultyChill',
    Difficulty.classic => 'difficultyClassic',
    Difficulty.blitz => 'difficultyBlitz',
  };
}
