/// The files allowed to pin a `Directionality`, and the phrase each must use to
/// explain itself.
///
/// **One list, imported by both tests that police it.** It used to be three
/// literal copies across two files, requiring two DIFFERENT phrases — E12 had
/// to add one path to all three and write both phrases into the same doc
/// comment. Running the check twice is deliberate (`stroop_tier_policy_test`
/// says why: a rule that only fails in CI is found an hour late); maintaining
/// the DATA twice was not.
///
/// The phrase requirement is the point of the list. A sanctioned exception with
/// no reasoning beside it is an exception nobody can review, so a file gets on
/// here by explaining itself at the line where it pins.
const kDirectionalityIslands = <String, String>{
  // The language sheet names each language in its own script, so the sheet's
  // rows do not follow the app's direction.
  'lib/features/settings/ui/language_sheet.dart': 'own direction',
  // E10. Schulte Grid's grid is a coordinate space rather than a text flow: the
  // scramble is uniform over positions, so mirroring it yields another scramble
  // and nothing else, while making cell 0 stop meaning a screen position in half
  // the app's locales. The chrome around it still mirrors.
  'lib/games/schulte_grid/ui/schulte_board.dart': 'coordinate space',
  // E12. A Digit Bridge numeral is a coordinate space too: the most significant
  // digit is on the left in BOTH systems the game bridges, which is why Unicode
  // gives Eastern Arabic digits a strong left-to-right bidi class. Every numeral
  // on that board goes through this one widget.
  'lib/games/digit_bridge/ui/board/bridge_numeral.dart': 'coordinate space',
};

/// The paths on the list, for a membership check.
Set<String> get kDirectionalityIslandFiles =>
    kDirectionalityIslands.keys.toSet();
