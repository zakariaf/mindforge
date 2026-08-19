@Tags(['tool'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/app_localizations.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

/// Writes `design/sunburst-pop/rtl/strings-fa.json` from the **live** Persian
/// localisations.
///
/// It is a test rather than a script because the generated localisations import
/// `package:flutter/widgets.dart` and only `flutter test` can load them. It is
/// tagged `tool` and excluded from the default lane, because it WRITES — and a
/// gate that regenerates what it checks asserts nothing.
///
/// CI runs it and then diffs the output. Editing an ARB without re-dumping is
/// therefore a build failure, which is what keeps the reference screenshots and
/// the app **one** source rather than two that drift.
///
///   flutter test --tags tool tool/dump_design_strings_test.dart
void main() {
  test('dump the fa strings the RTL reference screens render', () async {
    final fa = await AppLocalizations.delegate.load(const Locale('fa'));

    // Numbers arrive PRE-FORMATTED. gen-l10n interpolates an int placeholder
    // with Dart toString(), which is Latin digits in every locale — measured,
    // streakDays rendered "4" instead of "۴" before this changed.
    String n(int value) => LocaleNumbers.count(value, SupportedLocale.fa);

    // Every message the eight screens use, with the sample arguments declared
    // in app.html's data-l10n-args. Keys with no arguments are rendered
    // directly; the rest are listed here because a getter with parameters
    // cannot be called generically.
    final strings = <String, String>{
      'appTitle': fa.appTitle,
      'navPlay': fa.navPlay,
      'navStats': fa.navStats,
      'navSettings': fa.navSettings,
      'homeGreeting': fa.homeGreeting('evening'),
      'homeReadyPrompt': fa.homeReadyPrompt,
      'streakDays': fa.streakDays(4, n(4)),
      'dailyMixTitle': fa.dailyMixTitle,
      'dailyMixSummary': fa.dailyMixSummary(4, 3, n(4), n(3)),
      'yourGamesTitle': fa.yourGamesTitle,
      'gamesUnlocked': fa.gamesUnlocked(2, n(2)),
      'bestLabel': fa.bestLabel,
      'comingSoon': fa.comingSoon,
      'gameStroopRushName': fa.gameStroopRushName,
      'gameStroopRushTagline': fa.gameStroopRushTagline,
      'gameSchulteGridName': fa.gameSchulteGridName,
      'gameSchulteGridTagline': fa.gameSchulteGridTagline,
      'gameNBackName': fa.gameNBackName,
      'gameTagsReactionFocus': fa.gameTagsReactionFocus,
      'gameAndDifficulty': fa.gameAndDifficulty(
        fa.difficultyClassic,
        fa.gameStroopRushName,
      ),
      'yourBest': fa.yourBest,
      'gamesPlayed': fa.gamesPlayed,
      'difficultyTitle': fa.difficultyTitle,
      'difficultyChill': fa.difficultyChill,
      'difficultyClassic': fa.difficultyClassic,
      'difficultyBlitz': fa.difficultyBlitz,
      'playButton': fa.playButton,
      'getReady': fa.getReady,
      'hudTime': fa.hudTime,
      'hudScore': fa.hudScore,
      'hudStreak': fa.hudStreak,
      'hudFound': fa.hudFound,
      'hudNext': fa.hudNext,
      'streakMultiplier': fa.streakMultiplier(7, n(7)),
      'foundOfTotal': fa.foundOfTotal(n(25), n(6)),
      'colourRed': fa.colourRed,
      'colourBlue': fa.colourBlue,
      'colourGreen': fa.colourGreen,
      'colourYellow': fa.colourYellow,
      'resultsTitle': fa.resultsTitle,
      'newPersonalBest': fa.newPersonalBest,
      'finalScore': fa.finalScore,
      'accuracyLabel': fa.accuracyLabel,
      'avgReactionLabel': fa.avgReactionLabel,
      'unitMilliseconds': fa.unitMilliseconds,
      'longestStreakLabel': fa.longestStreakLabel,
      'playAgain': fa.playAgain,
      'homeButton': fa.homeButton,
      'statsTitle': fa.statsTitle,
      'statsAllTime': fa.statsAllTime,
      'bestScore': fa.bestScore,
      'bestTime': fa.bestTime,
      'timeTrained': fa.timeTrained,
      'durationHoursMinutes': fa.durationHoursMinutes(n(12), n(3)),
      'lastNRuns': fa.lastNRuns(7, n(7)),
      'chartSubtitle': fa.chartSubtitle(
        LocaleNumbers.count(1480, SupportedLocale.fa),
        fa.gameStroopRushName,
      ),
      'chartOldest': fa.chartOldest,
      'chartLatest': fa.chartLatest,
      'settingsTitle': fa.settingsTitle,
      'settingSound': fa.settingSound,
      'settingHaptics': fa.settingHaptics,
      'settingReduceMotion': fa.settingReduceMotion,
      'settingColourBlind': fa.settingColourBlind,
      'toggleOn': fa.toggleOn,
      'toggleOff': fa.toggleOff,
      'settingsLanguage': fa.settingsLanguage,
      'settingsLanguageSystem': fa.settingsLanguageSystem,
      'aboutTitle': fa.aboutTitle,
      'aboutTagline': fa.aboutTagline,
      'pauseTitle': fa.pauseTitle,
      'pauseResume': fa.pauseResume,
      'pauseQuit': fa.pauseQuit,
      'languageNameEn': fa.languageNameEn,
      'languageNameDe': fa.languageNameDe,
      'languageNameFa': fa.languageNameFa,
      'languageNameCkb': fa.languageNameCkb,
    };

    // The literal values on the reference screens, each formatted through
    // LocaleNumbers exactly as the app would. A Latin digit surviving into an
    // RTL screenshot means one of these was missed.
    const fa_ = SupportedLocale.fa;
    final numbers = <String, String>{
      // Every distinct data-num value in app.html's eight figures. The Schulte
      // TILES are in here because the tiles ARE the numbers: a Latin digit on
      // that board is not a cosmetic slip, it is the game rendered in the
      // wrong script. test/policy/rtl_screens_test.dart asserts this map
      // covers every data-num node, so a new one cannot be missed.
      '1': n(1),
      '2': n(2),
      '3': n(3),
      '4': n(4),
      '5': n(5),
      '6': n(6),
      '7': n(7),
      '8': n(8),
      '9': n(9),
      '10': n(10),
      '11': n(11),
      '12': n(12),
      '13': n(13),
      '14': n(14),
      '15': n(15),
      '16': n(16),
      '17': n(17),
      '18': n(18),
      '19': n(19),
      '20': n(20),
      '21': n(21),
      '22': n(22),
      '23': n(23),
      '24': n(24),
      '25': n(25),
      '128': n(128),
      '640': n(640),
      '780': n(780),
      '860': n(860),
      '940': n(940),
      '1120': n(1120),
      '1180': n(1180),
      '1310': n(1310),
      '1480': n(1480),
      '1,480': n(1480),
      '1,240': n(1240),
      '18.6s': '${LocaleNumbers.seconds(18600, fa_)}${fa.unitSeconds}',
      '0:23': LocaleNumbers.clock(23000, fa_),
      '0:12.4':
          '${LocaleNumbers.clock(12000, fa_)}'
          '${LocaleNumbers.seconds(400, fa_).substring(1)}',
      '92%': LocaleNumbers.percent(0.92, fa_),
    };

    final file = File('design/sunburst-pop/rtl/strings-fa.json');
    file.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(<String, Object>{
        '_note': 'GENERATED by tool/dump_design_strings_test.dart from '
            'lib/l10n/app_fa.arb and lib/l10n/locale_numbers.dart. Do not '
            'hand-edit: CI regenerates it and diffs the result, so an ARB '
            'change without a re-dump fails the build.',
        'strings': strings,
        'numbers': numbers,
      })}\n',
    );

    expect(file.existsSync(), isTrue);
  });
}
