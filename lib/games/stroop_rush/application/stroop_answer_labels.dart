import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/theme/sunburst_colors.dart';

/// The ARB key naming the colour [answer] is PAINTED as.
///
/// **The painted hue, not the enum name.** `SunburstColors.answerColour` paints
/// `PlayAnswer.green` as `cbOrange` under the colour-blind palette, so a key
/// labelled "Green" would be an orange key with the wrong word on it. In a game
/// that is ABOUT the word disagreeing with the colour, that mistake is
/// invisible by design — nothing on screen would look broken.
///
/// Blue and yellow keep their words because the palette keeps their hues; red
/// becomes pink and green becomes orange. There is no `PlayAnswer.pink`: pink
/// is what red BECOMES, not a fifth thing a round can offer.
///
/// A pure function of `(PlayAnswer, bool)`. It takes no `Locale` — the locale
/// reaches the label only through the [AppLocalizations] instance the View
/// already holds, which is why switching language mid-run re-renders and
/// re-deals nothing.
String answerWordKey(PlayAnswer answer, {required bool colourBlind}) =>
    switch ((answer, colourBlind)) {
      (PlayAnswer.red, true) => 'colourPink',
      (PlayAnswer.green, true) => 'colourOrange',
      (PlayAnswer.red, false) => 'colourRed',
      (PlayAnswer.green, false) => 'colourGreen',
      (PlayAnswer.blue, _) => 'colourBlue',
      (PlayAnswer.yellow, _) => 'colourYellow',
      // Blitz only, and never offered under the colour-blind palette — the
      // generator caps the pool before the first draw, so this arm is reached
      // only with the flag off. It answers for both anyway rather than
      // throwing: a total function has no unreachable arm to get wrong later.
      (PlayAnswer.purple, _) => 'colourPurple',
      (PlayAnswer.orange, _) => 'colourOrange',
    };

/// The colour word for [answer], resolved.
///
/// **`answerWord`, not `answerLabel`.** `SunburstColors.answerLabel` returns a
/// COLOUR — the ink or paper to draw a key's text in — and two different things
/// sharing a name is exactly the confusion `check_game_palette.sh` flags when
/// it sees the second one outside a board file. It was called `answerLabel`
/// first, and the gate said so.
///
/// gen-l10n has no dynamic key lookup — a key held as a string cannot become a
/// getter at runtime — so this is the same sanctioned shape as
/// `lib/l10n/game_strings.dart`: one switch, in one file, extended alongside
/// the ARB.
///
/// **No `toUpperCase()` anywhere.** It is a no-op in Arabic script, where there
/// is no case at all, and it is wrong in German, where `ß` uppercases to `SS`
/// and changes the length of the very string this game has to fit inside a key.
/// The design's uppercase forms live in the ARB values.
String answerWord(
  PlayAnswer answer, {
  required bool colourBlind,
  required AppLocalizations l10n,
}) => switch (answerWordKey(answer, colourBlind: colourBlind)) {
  'colourRed' => l10n.colourRed,
  'colourBlue' => l10n.colourBlue,
  'colourGreen' => l10n.colourGreen,
  'colourYellow' => l10n.colourYellow,
  'colourPurple' => l10n.colourPurple,
  'colourOrange' => l10n.colourOrange,
  'colourPink' => l10n.colourPink,
  // Not a fallback that renders the key. A colour with no word is a shipping
  // defect, and printing `colourTeal` on a live board would look like a bug
  // the player caused.
  final String key => throw StateError(
    'no colour word is registered for "$key". Add a row here when a '
    'PlayAnswer is added — gen-l10n cannot look a key up at runtime, so the '
    'two files are extended together.',
  ),
};

/// The word printed as the stimulus, in its display form.
///
/// **A second ARB group, not [answerWord] with a case applied.** The design
/// prints the stimulus at 78pt in caps and the key label in title case; casing
/// in Dart is a no-op in Arabic script, which has no case, and wrong in German,
/// where the eszett uppercases to a double S and changes the length of the very
/// string this game has to fit. In `fa` and `ckb` the two ARB values are
/// deliberately identical — the caller must not have to know which locale it
/// is in.
///
/// It resolves through the same swapped key as [answerWord], so a hue swapped
/// by the colour-blind palette is swapped in both places or in neither.
String stimulusWord(
  PlayAnswer answer, {
  required bool colourBlind,
  required AppLocalizations l10n,
}) => switch (answerWordKey(answer, colourBlind: colourBlind)) {
  'colourRed' => l10n.stroopWordRed,
  'colourBlue' => l10n.stroopWordBlue,
  'colourGreen' => l10n.stroopWordGreen,
  'colourYellow' => l10n.stroopWordYellow,
  'colourPurple' => l10n.stroopWordPurple,
  'colourOrange' => l10n.stroopWordOrange,
  'colourPink' => l10n.stroopWordPink,
  final String key => throw StateError(
    'no stimulus word is registered for "$key". The two groups are extended '
    'together: a colour with a key label and no stimulus form would render '
    'blank at 78pt.',
  ),
};
