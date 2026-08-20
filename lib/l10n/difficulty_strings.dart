import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/l10n/app_localizations.dart';

/// The ARB label for [difficulty].
///
/// **One switch, not one per screen.** Game detail, the countdown and the
/// results header all print a difficulty, and the same three-arm switch was
/// written three times — three places to extend the day a fourth difficulty
/// lands, and two of them would have been found by a compile error rather than
/// by a reader.
///
/// A switch over the ENUM rather than a map keyed by `labelKey`: gen-l10n
/// cannot resolve a key at runtime, so this is the same sanctioned shape as
/// `game_strings.dart`, and it is exhaustive with no `default:` — a fourth
/// difficulty does not compile until someone translates it.
String difficultyLabel(AppLocalizations l10n, Difficulty difficulty) =>
    switch (difficulty) {
      Difficulty.chill => l10n.difficultyChill,
      Difficulty.classic => l10n.difficultyClassic,
      Difficulty.blitz => l10n.difficultyBlitz,
    };
