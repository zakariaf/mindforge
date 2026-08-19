import 'package:flutter/widgets.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_numbers.dart';
import 'package:mindforge/theme/sunburst_type.dart';

/// Every ARB message, rendered, with the sample arguments the reference
/// screens use.
///
/// **One table, two consumers.** `tool/dump_design_strings_test.dart` writes
/// the Persian half of it into the RTL reference screenshots;
/// `test/l10n/text_expansion_matrix_test.dart` lays all four locales out at
/// three text scales and four widths. A second copy of this table would let a
/// key be measured in one place and rendered in the other.
///
/// Getters with parameters cannot be called generically, which is why this is a
/// hand-written map rather than a reflection loop. `renderedStringCount` is
/// asserted against the generated class's real getter count, so a new ARB key
/// that nobody added here fails a test instead of going unmeasured.
///
/// **Numbers arrive PRE-FORMATTED.** gen-l10n interpolates an `int` placeholder
/// with Dart `toString()`, which is Latin digits in every locale — measured,
/// `streakDays` rendered `4` instead of `۴` before the placeholders changed
/// shape. The `int` survives only where ICU needs it to pick a plural branch.
Map<String, String> renderAllStrings(
  AppLocalizations l10n,
  SupportedLocale locale,
) {
  final fmt = LocaleNumbers(locale);
  String n(int value) => fmt.count(value);

  return <String, String>{
    'appTitle': l10n.appTitle,
    'navPlay': l10n.navPlay,
    'navStats': l10n.navStats,
    'navSettings': l10n.navSettings,
    'homeGreeting': l10n.homeGreeting('evening'),
    'homeReadyPrompt': l10n.homeReadyPrompt,
    'streakDays': l10n.streakDays(4, n(4)),
    'dailyMixTitle': l10n.dailyMixTitle,
    'dailyMixSummary': l10n.dailyMixSummary(4, 3, n(4), n(3)),
    'yourGamesTitle': l10n.yourGamesTitle,
    'gamesUnlocked': l10n.gamesUnlocked(2, n(2)),
    'bestLabel': l10n.bestLabel,
    'comingSoon': l10n.comingSoon,
    'gameStroopRushName': l10n.gameStroopRushName,
    'gameStroopRushTagline': l10n.gameStroopRushTagline,
    'gameSchulteGridName': l10n.gameSchulteGridName,
    'gameSchulteGridTagline': l10n.gameSchulteGridTagline,
    'gameNBackName': l10n.gameNBackName,
    'gameTagsReactionFocus': l10n.gameTagsReactionFocus,
    'gameAndDifficulty': l10n.gameAndDifficulty(
      l10n.difficultyClassic,
      l10n.gameStroopRushName,
    ),
    'yourBest': l10n.yourBest,
    'gamesPlayed': l10n.gamesPlayed,
    'difficultyTitle': l10n.difficultyTitle,
    'difficultyChill': l10n.difficultyChill,
    'difficultyClassic': l10n.difficultyClassic,
    'difficultyBlitz': l10n.difficultyBlitz,
    'playButton': l10n.playButton,
    'getReady': l10n.getReady,
    'hudTime': l10n.hudTime,
    'hudScore': l10n.hudScore,
    'hudStreak': l10n.hudStreak,
    'hudFound': l10n.hudFound,
    'hudNext': l10n.hudNext,
    'streakMultiplier': l10n.streakMultiplier(7, n(7)),
    'foundOfTotal': l10n.foundOfTotal(n(25), n(6)),
    'colourRed': l10n.colourRed,
    'colourBlue': l10n.colourBlue,
    'colourGreen': l10n.colourGreen,
    'colourYellow': l10n.colourYellow,
    'resultsTitle': l10n.resultsTitle,
    'newPersonalBest': l10n.newPersonalBest,
    'finalScore': l10n.finalScore,
    'accuracyLabel': l10n.accuracyLabel,
    'avgReactionLabel': l10n.avgReactionLabel,
    'unitMilliseconds': l10n.unitMilliseconds,
    'unitSeconds': l10n.unitSeconds,
    'longestStreakLabel': l10n.longestStreakLabel,
    'playAgain': l10n.playAgain,
    'homeButton': l10n.homeButton,
    'statsTitle': l10n.statsTitle,
    'statsAllTime': l10n.statsAllTime,
    'bestScore': l10n.bestScore,
    'bestTime': l10n.bestTime,
    'timeTrained': l10n.timeTrained,
    'durationHoursMinutes': l10n.durationHoursMinutes(n(12), n(3)),
    'lastNRuns': l10n.lastNRuns(7, n(7)),
    'chartSubtitle': l10n.chartSubtitle(n(1480), l10n.gameStroopRushName),
    'chartOldest': l10n.chartOldest,
    'chartLatest': l10n.chartLatest,
    'settingsTitle': l10n.settingsTitle,
    'settingSound': l10n.settingSound,
    'settingHaptics': l10n.settingHaptics,
    'settingReduceMotion': l10n.settingReduceMotion,
    'settingColourBlind': l10n.settingColourBlind,
    'toggleOn': l10n.toggleOn,
    'toggleOff': l10n.toggleOff,
    'settingsLanguage': l10n.settingsLanguage,
    'settingsLanguageSystem': l10n.settingsLanguageSystem,
    'aboutTitle': l10n.aboutTitle,
    'aboutTagline': l10n.aboutTagline,
    'pauseTitle': l10n.pauseTitle,
    'pauseResume': l10n.pauseResume,
    'pauseQuit': l10n.pauseQuit,
    'languageNameEn': l10n.languageNameEn,
    'languageNameDe': l10n.languageNameDe,
    'languageNameFa': l10n.languageNameFa,
    'languageNameCkb': l10n.languageNameCkb,
  };
}

/// One slot on a reference screen: the type step a string is rendered at, and
/// how many lines the design gives it.
typedef TypeSlot = ({String step, int lines});

/// The slot every ARB key occupies on `design/sunburst-pop/screens/*.png`.
///
/// Hand-written and asserted complete: a key with no entry here would be
/// rendered at no step and measured by nothing.
///
/// `lines` is the budget the **layout must tolerate**, not the line count on
/// the reference screen. Every display heading is declared at 2 because a
/// heading wrapping once is normal and a heading wrapping twice is a break —
/// measured, `resultsTitle` already takes two lines in Sorani on a 320pt phone
/// at the design text size, and three at 2.0x. Declaring 1 there would make the
/// matrix fail on correct behaviour and stop reporting the real one.
///
/// The four settings-toggle labels are declared at 2 for the same reason: the
/// label sits beside a toggle, so it wraps rather than truncating. The
/// pseudo-locale lane found `settingColourBlind` needing the second line on a
/// 320pt phone at 1.4x expansion, which is where German is heading.
const Map<String, TypeSlot> kTypeSlots = <String, TypeSlot>{
  'appTitle': (step: 'displayL', lines: 1),
  'navPlay': (step: 'label', lines: 1),
  'navStats': (step: 'label', lines: 1),
  'navSettings': (step: 'label', lines: 1),
  'homeGreeting': (step: 'title', lines: 1),
  'homeReadyPrompt': (step: 'body', lines: 2),
  'streakDays': (step: 'label', lines: 1),
  'dailyMixTitle': (step: 'title', lines: 1),
  'dailyMixSummary': (step: 'caption', lines: 2),
  'yourGamesTitle': (step: 'title', lines: 1),
  'gamesUnlocked': (step: 'caption', lines: 1),
  'bestLabel': (step: 'label', lines: 1),
  'comingSoon': (step: 'label', lines: 1),
  'gameStroopRushName': (step: 'title', lines: 1),
  'gameStroopRushTagline': (step: 'caption', lines: 2),
  'gameSchulteGridName': (step: 'title', lines: 1),
  'gameSchulteGridTagline': (step: 'caption', lines: 2),
  'gameNBackName': (step: 'title', lines: 1),
  'gameTagsReactionFocus': (step: 'label', lines: 1),
  'gameAndDifficulty': (step: 'caption', lines: 1),
  'yourBest': (step: 'label', lines: 1),
  'gamesPlayed': (step: 'label', lines: 1),
  'difficultyTitle': (step: 'displayL', lines: 1),
  'difficultyChill': (step: 'title', lines: 1),
  'difficultyClassic': (step: 'title', lines: 1),
  'difficultyBlitz': (step: 'title', lines: 1),
  'playButton': (step: 'button', lines: 1),
  'getReady': (step: 'displayXl', lines: 2),
  'hudTime': (step: 'label', lines: 1),
  'hudScore': (step: 'label', lines: 1),
  'hudStreak': (step: 'label', lines: 1),
  'hudFound': (step: 'label', lines: 1),
  'hudNext': (step: 'label', lines: 1),
  'streakMultiplier': (step: 'numericHud', lines: 1),
  'foundOfTotal': (step: 'numericHud', lines: 1),
  'colourRed': (step: 'button', lines: 1),
  'colourBlue': (step: 'button', lines: 1),
  'colourGreen': (step: 'button', lines: 1),
  'colourYellow': (step: 'button', lines: 1),
  'resultsTitle': (step: 'displayXl', lines: 2),
  'newPersonalBest': (step: 'label', lines: 1),
  'finalScore': (step: 'label', lines: 1),
  'accuracyLabel': (step: 'caption', lines: 1),
  'avgReactionLabel': (step: 'caption', lines: 1),
  'unitMilliseconds': (step: 'caption', lines: 1),
  'unitSeconds': (step: 'caption', lines: 1),
  'longestStreakLabel': (step: 'caption', lines: 1),
  'playAgain': (step: 'button', lines: 1),
  'homeButton': (step: 'button', lines: 1),
  'statsTitle': (step: 'displayL', lines: 1),
  'statsAllTime': (step: 'title', lines: 1),
  'bestScore': (step: 'caption', lines: 1),
  'bestTime': (step: 'caption', lines: 1),
  'timeTrained': (step: 'caption', lines: 1),
  'durationHoursMinutes': (step: 'numericHud', lines: 1),
  'lastNRuns': (step: 'title', lines: 1),
  'chartSubtitle': (step: 'caption', lines: 2),
  'chartOldest': (step: 'label', lines: 1),
  'chartLatest': (step: 'label', lines: 1),
  'settingsTitle': (step: 'displayL', lines: 1),
  'settingSound': (step: 'body', lines: 2),
  'settingHaptics': (step: 'body', lines: 2),
  'settingReduceMotion': (step: 'body', lines: 2),
  'settingColourBlind': (step: 'body', lines: 2),
  'toggleOn': (step: 'label', lines: 1),
  'toggleOff': (step: 'label', lines: 1),
  'settingsLanguage': (step: 'body', lines: 1),
  'settingsLanguageSystem': (step: 'caption', lines: 1),
  'aboutTitle': (step: 'title', lines: 1),
  'aboutTagline': (step: 'caption', lines: 2),
  'pauseTitle': (step: 'displayXl', lines: 2),
  'pauseResume': (step: 'button', lines: 1),
  'pauseQuit': (step: 'button', lines: 1),
  'languageNameEn': (step: 'body', lines: 1),
  'languageNameDe': (step: 'body', lines: 1),
  'languageNameFa': (step: 'body', lines: 1),
  'languageNameCkb': (step: 'body', lines: 1),
};

TextStyle styleForStep(SunburstType type, String step) => switch (step) {
  'scoreHero' => type.scoreHero,
  'displayXl' => type.displayXl,
  'displayL' => type.displayL,
  'title' => type.title,
  'numericHud' => type.numericHud,
  'button' => type.button,
  'body' => type.body,
  'caption' => type.caption,
  'label' => type.label,
  'stimulus' => type.stimulus,
  _ => throw ArgumentError.value(step, 'step', 'not a SunburstType step'),
};
