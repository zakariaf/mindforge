import 'package:mindforge/l10n/app_localizations.dart';

/// One ARB key to one translated string, by name.
///
/// **gen-l10n produces getters, not a map**, so nothing can look a key up at
/// runtime and every place that stores an ARB key as data has to switch on it
/// somewhere. The question is how many somewheres.
///
/// It was three: the HUD's label switch, the results screen's label switch and
/// `game_strings.dart`'s switch — and that last one switched on the GAME ID
/// rather than on the keys the definition already declares, so it also had to
/// know every game by name. Adding Schulte Grid meant editing all three, and
/// missing one was a `StateError` on a live board rather than a compile error.
///
/// This is the one table. A new game adds rows here and nowhere else, and the
/// file is localization infrastructure rather than a shell screen — which is
/// what keeps `lib/features/**` free of any game's name.
///
/// **It throws rather than falling back to the key.** A slot naming a string
/// nobody translated is a shipping defect; printing `hudWhatever` on a live
/// board would look like a bug the player caused.
String arbString(AppLocalizations l10n, String key) => switch (key) {
  // Game names, taglines and kickers. A definition declares these three keys
  // in its `GameStringIds`; the shell reads them without knowing the game.
  'gameStroopRushName' => l10n.gameStroopRushName,
  'gameStroopRushTagline' => l10n.gameStroopRushTagline,
  'gameStroopRushKicker' => l10n.gameStroopRushKicker,
  'gameSchulteGridName' => l10n.gameSchulteGridName,
  'gameSchulteGridTagline' => l10n.gameSchulteGridTagline,
  'gameSchulteGridKicker' => l10n.gameSchulteGridKicker,

  // HUD slot labels. The two aliases are E07's older spelling, kept so a
  // stored snapshot from an earlier build still resolves.
  'hudTimeLabel' || 'hudTime' => l10n.hudTime,
  'hudScoreLabel' || 'hudScore' => l10n.hudScore,
  'hudStreak' => l10n.hudStreak,
  'hudFound' => l10n.hudFound,
  'hudNext' => l10n.hudNext,

  // Results trio labels.
  'accuracyLabel' => l10n.accuracyLabel,
  'avgReactionLabel' => l10n.avgReactionLabel,
  'longestStreakLabel' => l10n.longestStreakLabel,
  'schulteMissesLabel' => l10n.schulteMissesLabel,
  'schulteTilesLabel' => l10n.schulteTilesLabel,

  _ => throw StateError(
    'no string is registered for "$key". Add a row to arb_lookup.dart when a '
    'game introduces a label — gen-l10n cannot look a key up at runtime, so '
    'the ARB and this table are extended together.',
  ),
};
