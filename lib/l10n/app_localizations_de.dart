// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'MindForge';

  @override
  String get navPlay => 'Spielen';

  @override
  String get navStats => 'Statistik';

  @override
  String get navSettings => 'Einstellungen';

  @override
  String homeGreeting(String daypart) {
    String _temp0 = intl.Intl.selectLogic(
      daypart,
      {
        'morning': 'Guten Morgen',
        'afternoon': 'Guten Tag',
        'evening': 'Guten Abend',
        'other': 'Hallo',
      },
    );
    return '$_temp0';
  }

  @override
  String get homeReadyPrompt => 'Bereit zum Training?';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count Tage Serie',
      one: '$count Tag Serie',
      zero: 'Noch keine Serie',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixTitle => 'Tagesmix';

  @override
  String dailyMixSummary(int games, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games Spiele',
      one: '$games Spiel',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes Minuten',
      one: '$minutes Minute',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String get yourGamesTitle => 'Deine Spiele';

  @override
  String gamesUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count freigeschaltet',
      one: '$count freigeschaltet',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'BEST';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get gameStroopRushName => 'Stroop-Rausch';

  @override
  String get gameStroopRushTagline => 'Tippe die Farbe, nicht das Wort';

  @override
  String get gameSchulteGridName => 'Schulte-Tabelle';

  @override
  String get gameSchulteGridTagline => 'Finde 1 bis 25, schnell';

  @override
  String get gameNBackName => 'N-Back';

  @override
  String get gameTagsReactionFocus => 'Reaktion · Fokus';

  @override
  String gameAndDifficulty(String game, String difficulty) {
    return '$game · $difficulty';
  }

  @override
  String get yourBest => 'Deine Bestleistung';

  @override
  String get gamesPlayed => 'Gespielte Runden';

  @override
  String get difficultyTitle => 'Schwierigkeit';

  @override
  String get difficultyChill => 'Locker';

  @override
  String get difficultyClassic => 'Klassisch';

  @override
  String get difficultyBlitz => 'Blitz';

  @override
  String get playButton => 'Los';

  @override
  String get getReady => 'Bereit machen';

  @override
  String get hudTime => 'Zeit';

  @override
  String get hudScore => 'Punkte';

  @override
  String get hudStreak => 'Serie';

  @override
  String get hudFound => 'Gefunden';

  @override
  String get hudNext => 'Nächste';

  @override
  String streakMultiplier(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '×$count',
    );
    return '$_temp0';
  }

  @override
  String foundOfTotal(int found, int total) {
    return '$found / $total';
  }

  @override
  String get colourRed => 'Rot';

  @override
  String get colourBlue => 'Blau';

  @override
  String get colourGreen => 'Grün';

  @override
  String get colourYellow => 'Gelb';

  @override
  String get resultsTitle => 'Starker Lauf!';

  @override
  String get newPersonalBest => 'Neue Bestleistung';

  @override
  String get finalScore => 'Endpunktzahl';

  @override
  String get accuracyLabel => 'Genauigkeit';

  @override
  String get avgReactionLabel => 'Ø Reaktion';

  @override
  String get unitMilliseconds => 'ms';

  @override
  String get longestStreakLabel => 'Längste Serie';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get homeButton => 'Start';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsAllTime => 'Gesamt';

  @override
  String get bestScore => 'Beste Punktzahl';

  @override
  String get bestTime => 'Beste Zeit';

  @override
  String get timeTrained => 'Trainingszeit';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String lastNRuns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Letzte $count Runden',
      one: 'Letzte $count Runde',
    );
    return '$_temp0';
  }

  @override
  String chartSubtitle(String game, String score) {
    return '$game · Bestwert $score';
  }

  @override
  String get chartOldest => 'Älteste';

  @override
  String get chartLatest => 'Neueste';

  @override
  String get settingsTitle => 'Einstellungen';

  @override
  String get settingSound => 'Ton';

  @override
  String get settingHaptics => 'Haptik';

  @override
  String get settingReduceMotion => 'Bewegung reduzieren';

  @override
  String get settingColourBlind => 'Farbenblindfreundliche Palette';

  @override
  String get toggleOn => 'EIN';

  @override
  String get toggleOff => 'AUS';

  @override
  String get settingsLanguage => 'Sprache';

  @override
  String get settingsLanguageSystem => 'Gerätesprache verwenden';

  @override
  String get aboutTitle => 'Über MindForge';

  @override
  String get aboutTagline => 'Trainiere dein Gehirn. Kein WLAN nötig.';

  @override
  String get pauseTitle => 'Pausiert';

  @override
  String get pauseResume => 'Fortsetzen';

  @override
  String get pauseQuit => 'Runde beenden';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNameFa => 'فارسی';

  @override
  String get languageNameCkb => 'کوردیی ناوەندی';
}
