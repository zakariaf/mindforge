// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'MindForge';

  @override
  String get navPlay => 'Play';

  @override
  String get navStats => 'Stats';

  @override
  String get navSettings => 'Settings';

  @override
  String homeGreeting(String daypart) {
    String _temp0 = intl.Intl.selectLogic(
      daypart,
      {
        'morning': 'Good morning',
        'afternoon': 'Good afternoon',
        'evening': 'Good evening',
        'other': 'Hello',
      },
    );
    return '$_temp0';
  }

  @override
  String get homeReadyPrompt => 'Ready to train?';

  @override
  String streakDays(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted day streak',
      one: '$formatted day streak',
      zero: 'No streak yet',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixTitle => 'Daily Mix';

  @override
  String dailyMixSummary(
    int games,
    int minutes,
    String formattedGames,
    String formattedMinutes,
  ) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$formattedGames games',
      one: '$formattedGames game',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$formattedMinutes minutes',
      one: '$formattedMinutes minute',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get yourGamesTitle => 'Your games';

  @override
  String gamesUnlocked(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted unlocked',
      one: '$formatted unlocked',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'BEST';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get gameStroopRushName => 'Stroop Rush';

  @override
  String get gameStroopRushTagline => 'Tap the colour, not the word';

  @override
  String get gameSchulteGridName => 'Schulte Grid';

  @override
  String get gameSchulteGridTagline => 'Find 1 to 25, fast';

  @override
  String get gameNBackName => 'N-Back';

  @override
  String get gameTagsReactionFocus => 'Reaction · Focus';

  @override
  String gameAndDifficulty(String game, String difficulty) {
    return '$game · $difficulty';
  }

  @override
  String get yourBest => 'Your best';

  @override
  String get gamesPlayed => 'Games played';

  @override
  String get difficultyTitle => 'Difficulty';

  @override
  String get difficultyChill => 'Chill';

  @override
  String get difficultyClassic => 'Classic';

  @override
  String get difficultyBlitz => 'Blitz';

  @override
  String get playButton => 'Play';

  @override
  String get getReady => 'Get ready';

  @override
  String get hudTime => 'Time';

  @override
  String get hudScore => 'Score';

  @override
  String get hudStreak => 'Streak';

  @override
  String get hudFound => 'Found';

  @override
  String get hudNext => 'Next';

  @override
  String streakMultiplier(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '×$formatted',
    );
    return '$_temp0';
  }

  @override
  String foundOfTotal(String found, String total) {
    return '$found / $total';
  }

  @override
  String get colourRed => 'Red';

  @override
  String get colourBlue => 'Blue';

  @override
  String get colourGreen => 'Green';

  @override
  String get colourYellow => 'Yellow';

  @override
  String get resultsTitle => 'Nice run!';

  @override
  String get newPersonalBest => 'New personal best';

  @override
  String get finalScore => 'Final score';

  @override
  String get accuracyLabel => 'Accuracy';

  @override
  String get avgReactionLabel => 'Avg reaction';

  @override
  String get unitMilliseconds => 'ms';

  @override
  String get unitSeconds => 's';

  @override
  String get longestStreakLabel => 'Longest streak';

  @override
  String get playAgain => 'Play again';

  @override
  String get homeButton => 'Home';

  @override
  String get statsTitle => 'Stats';

  @override
  String get statsAllTime => 'All time';

  @override
  String get bestScore => 'Best score';

  @override
  String get bestTime => 'Best time';

  @override
  String get timeTrained => 'Time trained';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '${hours}h ${minutes}m';
  }

  @override
  String lastNRuns(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Last $formatted runs',
      one: 'Last $formatted run',
    );
    return '$_temp0';
  }

  @override
  String chartSubtitle(String game, String score) {
    return '$game · best $score';
  }

  @override
  String get chartOldest => 'Oldest';

  @override
  String get chartLatest => 'Latest';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get settingSound => 'Sound';

  @override
  String get settingHaptics => 'Haptics';

  @override
  String get settingReduceMotion => 'Reduce motion';

  @override
  String get settingColourBlind => 'Colour-blind friendly palette';

  @override
  String get toggleOn => 'ON';

  @override
  String get toggleOff => 'OFF';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSystem => 'Use device language';

  @override
  String get aboutTitle => 'About MindForge';

  @override
  String get aboutTagline => 'Train your brain. No wifi needed.';

  @override
  String get pauseTitle => 'Paused';

  @override
  String get pauseResume => 'Resume';

  @override
  String get pauseQuit => 'Quit run';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNameFa => 'فارسی';

  @override
  String get languageNameCkb => 'کوردیی ناوەندی';

  @override
  String get gamePlaceholderCoralName => 'Reaction Lab';

  @override
  String get gamePlaceholderCoralTagline => 'Tap the odd one out';

  @override
  String get gamePlaceholderCoralKicker => 'REACTION';

  @override
  String get gamePlaceholderTurquoiseName => 'Grid Sweep';

  @override
  String get gamePlaceholderTurquoiseTagline => 'Find them in order';

  @override
  String get gamePlaceholderTurquoiseKicker => 'FOCUS';

  @override
  String get gamePlaceholderLockedName => 'Coming Soon';

  @override
  String get gamePlaceholderLockedTagline => 'Not yet unlocked';

  @override
  String get gamePlaceholderLockedKicker => 'SOON';

  @override
  String get notFoundTitle => 'That screen has moved';
}
