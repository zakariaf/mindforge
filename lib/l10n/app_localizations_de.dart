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
  String streakDays(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted Tage Serie',
      one: '$formatted Tag Serie',
      zero: 'Noch keine Serie',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixTitle => 'Tagesmix';

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
      other: '$formattedGames Spiele',
      one: '$formattedGames Spiel',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$formattedMinutes Minuten',
      one: '$formattedMinutes Minute',
    );
    return '$_temp0, $_temp1';
  }

  @override
  String dailyMixTodaysPick(String game) {
    return 'Heutige Auswahl: $game';
  }

  @override
  String get yourGamesTitle => 'Deine Spiele';

  @override
  String gamesUnlocked(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted freigeschaltet',
      one: '$formatted freigeschaltet',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'BEST';

  @override
  String get comingSoon => 'Demnächst';

  @override
  String get gameStroopRushName => 'Stroop Rush';

  @override
  String get gameStroopRushTagline => 'Tippe auf die Farbe, nicht auf das Wort';

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
  String get yourBest => 'DEINE BESTLEISTUNG';

  @override
  String get gamesPlayed => 'GESPIELTE RUNDEN';

  @override
  String get difficultyTitle => 'SCHWIERIGKEIT';

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
  String get hudTime => 'ZEIT';

  @override
  String get hudScore => 'PUNKTE';

  @override
  String get hudStreak => 'SERIE';

  @override
  String get hudFound => 'GEFUNDEN';

  @override
  String get hudNext => 'NÄCHSTE';

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
  String get colourRed => 'Rot';

  @override
  String get colourBlue => 'Blau';

  @override
  String get colourGreen => 'Grün';

  @override
  String get colourYellow => 'Gelb';

  @override
  String get colourPurple => 'Lila';

  @override
  String get colourOrange => 'Orange';

  @override
  String get colourPink => 'Rosa';

  @override
  String get stroopWordRed => 'ROT';

  @override
  String get stroopWordBlue => 'BLAU';

  @override
  String get stroopWordGreen => 'GRÜN';

  @override
  String get stroopWordYellow => 'GELB';

  @override
  String get stroopWordPurple => 'LILA';

  @override
  String get stroopWordOrange => 'ORANGE';

  @override
  String get stroopWordPink => 'ROSA';

  @override
  String get stroopPrompt => 'TIPPE AUF DIE FARBE, NICHT AUF DAS WORT';

  @override
  String stroopStimulusValue(String word, String ink) {
    return '$word, gedruckt in $ink';
  }

  @override
  String get gameStroopRushKicker => 'REAKTION · FOKUS';

  @override
  String get resultsTitle => 'Starker Lauf!';

  @override
  String get newPersonalBest => 'Neue Bestleistung';

  @override
  String get finalScore => 'ENDPUNKTZAHL';

  @override
  String get accuracyLabel => 'GENAUIGKEIT';

  @override
  String get avgReactionLabel => 'Ø REAKTION';

  @override
  String get unitMilliseconds => 'ms';

  @override
  String get unitSeconds => 's';

  @override
  String get longestStreakLabel => 'LÄNGSTE SERIE';

  @override
  String get playAgain => 'Nochmal spielen';

  @override
  String get homeButton => 'Start';

  @override
  String get statsTitle => 'Statistik';

  @override
  String get statsAllTime => 'Gesamt';

  @override
  String get bestScore => 'BESTE PUNKTZAHL';

  @override
  String get bestTime => 'BESTE ZEIT';

  @override
  String get timeTrained => 'TRAININGSZEIT';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours Std. $minutes Min.';
  }

  @override
  String lastNRuns(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Letzte $formatted Runden',
      one: 'Letzte $formatted Runde',
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

  @override
  String get notFoundTitle => 'Diesen Bildschirm gibt es nicht mehr';

  @override
  String get settingColourBlindHelp =>
      'Tauscht Rot gegen Pink und Grün gegen Orange. Die Füllmuster sind immer an.';

  @override
  String get aboutVersion => 'Version';

  @override
  String get aboutOffline => 'Funktioniert immer offline';

  @override
  String get aboutOfflineBody =>
      'Diese App enthält keinen Netzwerkcode. Es wird nichts geladen und nichts gesendet.';

  @override
  String get aboutPrivate => 'Nichts verlässt dein Gerät';

  @override
  String get aboutPrivateBody =>
      'Kein Konto, keine Analyse, keine Absturzberichte. Deine Ergebnisse liegen in einer Datei auf diesem Telefon.';

  @override
  String get aboutLicenceTitle => 'Lizenz';

  @override
  String aboutLicenceBody(String licence) {
    return 'MindForge ist quelloffen unter $licence.';
  }

  @override
  String get aboutThirdParty => 'Open-Source-Lizenzen';

  @override
  String get schulteMissesLabel => 'FEHLER';

  @override
  String get schulteTilesLabel => 'FELDER';
}
