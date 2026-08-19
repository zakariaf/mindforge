// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Persian (`fa`).
class AppLocalizationsFa extends AppLocalizations {
  AppLocalizationsFa([String locale = 'fa']) : super(locale);

  @override
  String get appTitle => 'MindForge';

  @override
  String get navPlay => 'بازی';

  @override
  String get navStats => 'آمار';

  @override
  String get navSettings => 'تنظیمات';

  @override
  String homeGreeting(String daypart) {
    String _temp0 = intl.Intl.selectLogic(
      daypart,
      {
        'morning': 'صبح بخیر',
        'afternoon': 'ظهر بخیر',
        'evening': 'عصر بخیر',
        'other': 'سلام',
      },
    );
    return '$_temp0';
  }

  @override
  String get homeReadyPrompt => 'آماده‌ی تمرین؟';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'زنجیره‌ی $count روزه',
      zero: 'هنوز زنجیره‌ای نیست',
    );
    return '$_temp0';
  }

  @override
  String get dailyMixTitle => 'ترکیب روزانه';

  @override
  String dailyMixSummary(int games, int minutes) {
    String _temp0 = intl.Intl.pluralLogic(
      games,
      locale: localeName,
      other: '$games بازی',
    );
    String _temp1 = intl.Intl.pluralLogic(
      minutes,
      locale: localeName,
      other: '$minutes دقیقه',
    );
    return '$_temp0، $_temp1';
  }

  @override
  String get yourGamesTitle => 'بازی‌های شما';

  @override
  String gamesUnlocked(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count باز شده',
    );
    return '$_temp0';
  }

  @override
  String get bestLabel => 'بهترین';

  @override
  String get comingSoon => 'به‌زودی';

  @override
  String get gameStroopRushName => 'شتاب استروپ';

  @override
  String get gameStroopRushTagline => 'رنگ را بزن، نه واژه را';

  @override
  String get gameSchulteGridName => 'جدول شولته';

  @override
  String get gameSchulteGridTagline => '۱ تا ۲۵ را سریع پیدا کن';

  @override
  String get gameNBackName => 'N-Back';

  @override
  String get gameTagsReactionFocus => 'واکنش · تمرکز';

  @override
  String gameAndDifficulty(String game, String difficulty) {
    return '$game · $difficulty';
  }

  @override
  String get yourBest => 'بهترین شما';

  @override
  String get gamesPlayed => 'بازی‌های انجام‌شده';

  @override
  String get difficultyTitle => 'سختی';

  @override
  String get difficultyChill => 'آرام';

  @override
  String get difficultyClassic => 'کلاسیک';

  @override
  String get difficultyBlitz => 'برق‌آسا';

  @override
  String get playButton => 'شروع';

  @override
  String get getReady => 'آماده باش';

  @override
  String get hudTime => 'زمان';

  @override
  String get hudScore => 'امتیاز';

  @override
  String get hudStreak => 'زنجیره';

  @override
  String get hudFound => 'یافته';

  @override
  String get hudNext => 'بعدی';

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
  String get colourRed => 'قرمز';

  @override
  String get colourBlue => 'آبی';

  @override
  String get colourGreen => 'سبز';

  @override
  String get colourYellow => 'زرد';

  @override
  String get resultsTitle => 'اجرای خوبی بود!';

  @override
  String get newPersonalBest => 'رکورد شخصی تازه';

  @override
  String get finalScore => 'امتیاز نهایی';

  @override
  String get accuracyLabel => 'دقت';

  @override
  String get avgReactionLabel => 'میانگین واکنش';

  @override
  String get unitMilliseconds => 'میلی‌ثانیه';

  @override
  String get longestStreakLabel => 'بلندترین زنجیره';

  @override
  String get playAgain => 'دوباره بازی';

  @override
  String get homeButton => 'خانه';

  @override
  String get statsTitle => 'آمار';

  @override
  String get statsAllTime => 'از ابتدا';

  @override
  String get bestScore => 'بهترین امتیاز';

  @override
  String get bestTime => 'بهترین زمان';

  @override
  String get timeTrained => 'زمان تمرین';

  @override
  String durationHoursMinutes(int hours, int minutes) {
    return '$hours ساعت و $minutes دقیقه';
  }

  @override
  String lastNRuns(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count اجرای آخر',
    );
    return '$_temp0';
  }

  @override
  String chartSubtitle(String game, String score) {
    return '$game · بهترین $score';
  }

  @override
  String get chartOldest => 'قدیمی‌ترین';

  @override
  String get chartLatest => 'تازه‌ترین';

  @override
  String get settingsTitle => 'تنظیمات';

  @override
  String get settingSound => 'صدا';

  @override
  String get settingHaptics => 'لرزش';

  @override
  String get settingReduceMotion => 'کاهش حرکت';

  @override
  String get settingColourBlind => 'پالت مناسب کوررنگی';

  @override
  String get toggleOn => 'روشن';

  @override
  String get toggleOff => 'خاموش';

  @override
  String get settingsLanguage => 'زبان';

  @override
  String get settingsLanguageSystem => 'استفاده از زبان دستگاه';

  @override
  String get aboutTitle => 'درباره‌ی MindForge';

  @override
  String get aboutTagline => 'مغزت را تمرین بده. بدون نیاز به وای‌فای.';

  @override
  String get pauseTitle => 'متوقف';

  @override
  String get pauseResume => 'ادامه';

  @override
  String get pauseQuit => 'پایان اجرا';

  @override
  String get languageNameEn => 'English';

  @override
  String get languageNameDe => 'Deutsch';

  @override
  String get languageNameFa => 'فارسی';

  @override
  String get languageNameCkb => 'کوردیی ناوەندی';
}
