// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Central Kurdish (`ckb`).
class AppLocalizationsCkb extends AppLocalizations {
  AppLocalizationsCkb([String locale = 'ckb']) : super(locale);

  @override
  String get appTitle => 'MindForge';

  @override
  String get navPlay => 'یاری';

  @override
  String get navStats => 'ئاماری';

  @override
  String get navSettings => 'ڕێکخستن';

  @override
  String homeGreeting(String daypart) {
    String _temp0 = intl.Intl.selectLogic(
      daypart,
      {
        'morning': 'بەیانیت باش',
        'afternoon': 'نیوەڕۆت باش',
        'evening': 'ئێوارەت باش',
        'other': 'سڵاو',
      },
    );
    return '$_temp0';
  }

  @override
  String get homeReadyPrompt => 'ئامادەیت بۆ ڕاهێنان؟';

  @override
  String streakDays(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'زنجیرەی $formatted ڕۆژە',
      zero: 'هێشتا زنجیرە نییە',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixTitle => 'تێکەڵەی ڕۆژانە';

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
      other: '$formattedGames یاری',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$formattedMinutes خولەک',
    );
    return '$_temp0، $_temp1';
  }

  @override
  String dailyMixTodaysPick(String game) {
    return 'هەڵبژاردەی ئەمڕۆ: $game';
  }

  @override
  String get yourGamesTitle => 'یارییەکانت';

  @override
  String gamesUnlocked(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted کراوەتەوە',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'باشترین';

  @override
  String get comingSoon => 'بەم زووانە';

  @override
  String get gameStroopRushName => 'پەلەی ستروپ';

  @override
  String get gameStroopRushTagline => 'دەست بنێ بە ڕەنگەکە، نەک وشەکە';

  @override
  String get gameSchulteGridName => 'خشتەی شولتە';

  @override
  String get gameSchulteGridTagline => '۱ تا ۲۵ بە خێرایی بدۆزەرەوە';

  @override
  String get gameNBackName => 'N-Back';

  @override
  String get gameTagsReactionFocus => 'کاردانەوە · سەرنج';

  @override
  String gameAndDifficulty(String game, String difficulty) {
    return '$game · $difficulty';
  }

  @override
  String get yourBest => 'باشترینی تۆ';

  @override
  String get gamesPlayed => 'یارییە کراوەکان';

  @override
  String get difficultyTitle => 'ئاستی سەختی';

  @override
  String get difficultyChill => 'هێمن';

  @override
  String get difficultyClassic => 'کلاسیک';

  @override
  String get difficultyBlitz => 'خێرا';

  @override
  String get playButton => 'دەستپێکردن';

  @override
  String get getReady => 'ئامادە بە';

  @override
  String get hudTime => 'کات';

  @override
  String get hudScore => 'خاڵ';

  @override
  String get hudStreak => 'زنجیرە';

  @override
  String get hudFound => 'دۆزراوە';

  @override
  String get hudNext => 'دواتر';

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
  String get colourRed => 'سوور';

  @override
  String get colourBlue => 'شین';

  @override
  String get colourGreen => 'سەوز';

  @override
  String get colourYellow => 'زەرد';

  @override
  String get colourPurple => 'مۆر';

  @override
  String get colourOrange => 'نارەنجی';

  @override
  String get colourPink => 'پەمەیی';

  @override
  String get stroopWordRed => 'سوور';

  @override
  String get stroopWordBlue => 'شین';

  @override
  String get stroopWordGreen => 'سەوز';

  @override
  String get stroopWordYellow => 'زەرد';

  @override
  String get stroopWordPurple => 'مۆر';

  @override
  String get stroopWordOrange => 'نارەنجی';

  @override
  String get stroopWordPink => 'پەمەیی';

  @override
  String get stroopPrompt => 'دەست بنێ بە ڕەنگەکە، نەک وشەکە';

  @override
  String stroopStimulusValue(String word, String ink) {
    return '$word، بە ڕەنگی $ink چاپکراوە';
  }

  @override
  String get gameStroopRushKicker => 'کاردانەوە · سەرنج';

  @override
  String get resultsTitle => 'خولێکی باش بوو!';

  @override
  String get newPersonalBest => 'ڕیکۆردی نوێی کەسی';

  @override
  String get finalScore => 'خاڵی کۆتایی';

  @override
  String get accuracyLabel => 'وردی';

  @override
  String get avgReactionLabel => 'ناوەندی کاردانەوە';

  @override
  String get unitMilliseconds => 'میلی‌چرکە';

  @override
  String get unitSeconds => 'چ';

  @override
  String get longestStreakLabel => 'درێژترین زنجیرە';

  @override
  String get playAgain => 'دووبارە یاری بکە';

  @override
  String get homeButton => 'ماڵەوە';

  @override
  String get statsTitle => 'ئاماری';

  @override
  String get statsAllTime => 'لە سەرەتاوە';

  @override
  String get bestScore => 'باشترین خاڵ';

  @override
  String get bestTime => 'باشترین کات';

  @override
  String get timeTrained => 'کاتی ڕاهێنان';

  @override
  String durationHoursMinutes(String hours, String minutes) {
    return '$hours کاتژمێر و $minutes خولەک';
  }

  @override
  String lastNRuns(int count, String formatted) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$formatted خولی دوایی',
    );
    return '$_temp0';
  }

  @override
  String chartSubtitle(String game, String score) {
    return '$game · باشترین $score';
  }

  @override
  String get chartOldest => 'کۆنترین';

  @override
  String get chartLatest => 'نوێترین';

  @override
  String get settingsTitle => 'ڕێکخستن';

  @override
  String get settingSound => 'دەنگ';

  @override
  String get settingHaptics => 'لەرزین';

  @override
  String get settingReduceMotion => 'کەمکردنەوەی جوڵە';

  @override
  String get settingColourBlind => 'پاڵێتی گونجاو بۆ کوێری ڕەنگ';

  @override
  String get toggleOn => 'کراوە';

  @override
  String get toggleOff => 'داخراوە';

  @override
  String get settingsLanguage => 'زمان';

  @override
  String get settingsLanguageSystem => 'زمانی ئامێر بەکاربهێنە';

  @override
  String get aboutTitle => 'دەربارەی MindForge';

  @override
  String get aboutTagline => 'مێشکت ڕابهێنە. پێویستی بە وایفای نییە.';

  @override
  String get pauseTitle => 'وەستاو';

  @override
  String get pauseResume => 'بەردەوامبوون';

  @override
  String get pauseQuit => 'کۆتایی خول';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNameFa => 'فارسی';

  @override
  String get languageNameCkb => 'کوردیی ناوەندی';

  @override
  String get notFoundTitle => 'ئەم پەڕەیە نەماوە';

  @override
  String get settingColourBlindHelp =>
      'سوور دەگۆڕێت بە پەمەیی و سەوز بە پرتەقاڵی. شێوەکانی پڕکردنەوە هەمیشە کاران.';

  @override
  String get aboutVersion => 'وەشان';

  @override
  String get aboutOffline => 'هەمیشە بەبێ ئینتەرنێت کار دەکات';

  @override
  String get aboutOfflineBody =>
      'هیچ کۆدێکی تۆڕ لەم ئەپەدا نییە. هیچ شتێک دانالوود ناکرێت و هیچ شتێک نانێردرێت.';

  @override
  String get aboutPrivate => 'هیچ شتێک لە ئامێرەکەت دەرناچێت';

  @override
  String get aboutPrivateBody =>
      'بێ هەژمار، بێ شیکاری، بێ ڕاپۆرتی تێکچوون. خاڵەکانت لە یەک فایلدا لەسەر ئەم مۆبایلە دەمێننەوە.';

  @override
  String get aboutLicenceTitle => 'مۆڵەتنامە';

  @override
  String aboutLicenceBody(String licence) {
    return 'مایندفۆرج سەرچاوەکراوەیە، لەژێر $licence.';
  }

  @override
  String get aboutThirdParty => 'مۆڵەتنامە سەرچاوەکراوەکان';

  @override
  String get schulteMissesLabel => 'هەڵەکان';

  @override
  String get schulteTilesLabel => 'خانەکان';

  @override
  String get gameSchulteGridKicker => 'خولیاکردن · خێرایی';
}
