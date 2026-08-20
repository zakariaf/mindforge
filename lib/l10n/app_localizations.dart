import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ckb.dart';
import 'app_localizations_de.dart';
import 'app_localizations_en.dart';
import 'app_localizations_fa.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ckb'),
    Locale('de'),
    Locale('en'),
    Locale('fa'),
  ];

  /// The application name and the wordmark at the top of Home and Settings. A proper noun: it stays 'MindForge' in ALL FOUR locales. In fa and ckb it is a Latin run inside RTL copy and is bidi-isolated at render.
  ///
  /// In en, this message translates to:
  /// **'MindForge'**
  String get appTitle;

  /// Bottom navigation tab leading to the game hub. A noun here, not a verb — it names a destination, unlike playButton which is an action.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get navPlay;

  /// Bottom navigation tab leading to the statistics screen.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Bottom navigation tab leading to settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Greeting at the top of Home, chosen by time of day. A select rather than a Dart switch in a widget, so a locale that greets differently at different hours can say so in its own ARB.
  ///
  /// In en, this message translates to:
  /// **'{daypart, select, morning{Good morning} afternoon{Good afternoon} evening{Good evening} other{Hello}}'**
  String homeGreeting(String daypart);

  /// Subtitle under the greeting on Home.
  ///
  /// In en, this message translates to:
  /// **'Ready to train?'**
  String get homeReadyPrompt;

  /// The streak chip on Home. A plural, not a concatenation: 'day' and 'days' differ in en, and Persian and Sorani have their own category rules. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =0{No streak yet} one{{formatted} day streak} other{{formatted} day streak}}'**
  String streakDays(int count, String formatted);

  /// Heading of the suggested-session card on Home and game detail.
  ///
  /// In en, this message translates to:
  /// **'Daily Mix'**
  String get dailyMixTitle;

  /// The Daily Mix summary line, e.g. '3 games, 4 minutes'. BOTH counts are pluralised inside ONE message: splicing two separately localized fragments is what produces ungrammatical output in languages that inflect the joiner. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{games, plural, one{{formattedGames} game} other{{formattedGames} games}}, {minutes, plural, one{{formattedMinutes} minute} other{{formattedMinutes} minutes}}'**
  String dailyMixSummary(
    int games,
    int minutes,
    String formattedGames,
    String formattedMinutes,
  );

  /// The Daily Mix summary line in v1, naming the one game today's seeded pick leads to. NOT '3 games, 4 minutes': the card routes to a single game, and a summary claiming three would be a sentence about software that does not exist. The game name arrives already resolved.
  ///
  /// In en, this message translates to:
  /// **'Today\'s pick: {game}'**
  String dailyMixTodaysPick(String game);

  /// Section heading above the game cards on Home. Sentence case.
  ///
  /// In en, this message translates to:
  /// **'Your games'**
  String get yourGamesTitle;

  /// Count chip beside the 'Your games' heading. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{formatted} unlocked} other{{formatted} unlocked}}'**
  String gamesUnlocked(int count, String formatted);

  /// Label on the best-score pill. Authored in capitals: casing belongs in the string table, and SunburstType.label is the only step that permits caps. A script with no letter case renders it in its normal form rather than being forced.
  ///
  /// In en, this message translates to:
  /// **'BEST'**
  String get bestLabel;

  /// Badge on a game card that is not yet playable.
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// The first game's name. A coined product name rather than a translation of one: 'Stroop' is the psychologist the task is named after and stays, while the second word is localized.
  ///
  /// In en, this message translates to:
  /// **'Stroop Rush'**
  String get gameStroopRushName;

  /// One line saying what the player does, on the Home card and under the game's hero.
  ///
  /// In en, this message translates to:
  /// **'Tap the colour, not the word'**
  String get gameStroopRushTagline;

  /// The name of the second game. Translated, for the same reason as gameStroopRushName.
  ///
  /// In en, this message translates to:
  /// **'Schulte Grid'**
  String get gameSchulteGridName;

  /// One-line description of Schulte Grid. The '1 to 25' is prose describing the fixed range of the grid, not a formatted value, so it is authored in the string.
  ///
  /// In en, this message translates to:
  /// **'Find 1 to 25, fast'**
  String get gameSchulteGridTagline;

  /// The name of the third game, shown as a coming-soon card.
  ///
  /// In en, this message translates to:
  /// **'N-Back'**
  String get gameNBackName;

  /// The category tags on a game detail header. The interpunct is authored in the string so an RTL locale can place it.
  ///
  /// In en, this message translates to:
  /// **'Reaction · Focus'**
  String get gameTagsReactionFocus;

  /// A game and its difficulty together, in the countdown and play headers. The separator is inside the message so an RTL locale can move it.
  ///
  /// In en, this message translates to:
  /// **'{game} · {difficulty}'**
  String gameAndDifficulty(String game, String difficulty);

  /// Label on the personal-best figure on game detail. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'YOUR BEST'**
  String get yourBest;

  /// Label on the run-count figure on game detail and on Stats. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'GAMES PLAYED'**
  String get gamesPlayed;

  /// Heading above the difficulty selector. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'DIFFICULTY'**
  String get difficultyTitle;

  /// The easiest difficulty. An adjective describing the pace, not a proper noun.
  ///
  /// In en, this message translates to:
  /// **'Chill'**
  String get difficultyChill;

  /// The default difficulty.
  ///
  /// In en, this message translates to:
  /// **'Classic'**
  String get difficultyClassic;

  /// The hardest and fastest difficulty.
  ///
  /// In en, this message translates to:
  /// **'Blitz'**
  String get difficultyBlitz;

  /// The primary button that starts a round. An imperative verb, as short as the language allows — it sits inside a fixed-width chunky button.
  ///
  /// In en, this message translates to:
  /// **'Play'**
  String get playButton;

  /// The line under the countdown numeral. The numeral itself is a formatted number, never part of this string.
  ///
  /// In en, this message translates to:
  /// **'Get ready'**
  String get getReady;

  /// HUD label above the elapsed or remaining clock.
  ///
  /// In en, this message translates to:
  /// **'TIME'**
  String get hudTime;

  /// HUD label above the running score.
  ///
  /// In en, this message translates to:
  /// **'SCORE'**
  String get hudScore;

  /// HUD label above the combo multiplier.
  ///
  /// In en, this message translates to:
  /// **'STREAK'**
  String get hudStreak;

  /// HUD label above the found-tile count in Schulte Grid.
  ///
  /// In en, this message translates to:
  /// **'FOUND'**
  String get hudFound;

  /// HUD label above the next number to find in Schulte Grid.
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get hudNext;

  /// The combo multiplier, e.g. '×7'. The MULTIPLICATION SIGN U+00D7, not the letter x: they are different characters and the letter does not exist in Arabic script. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, other{×{formatted}}}'**
  String streakMultiplier(int count, String formatted);

  /// How many tiles have been found out of the total, e.g. '6 / 25'. Both values are placeholders so the separator can change per locale. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{found} / {total}'**
  String foundOfTotal(String found, String total);

  /// A colour name. ONE key, TWO uses: it renders the Stroop stimulus word AND its answer-key label. The colour-word mismatch that IS the game is generated from semantic tokens and is locale-independent; only the rendering is localized.
  ///
  /// In en, this message translates to:
  /// **'Red'**
  String get colourRed;

  /// A colour name. ONE key, TWO uses: it renders the Stroop stimulus word AND its answer-key label. The colour-word mismatch that IS the game is generated from semantic tokens and is locale-independent; only the rendering is localized.
  ///
  /// In en, this message translates to:
  /// **'Blue'**
  String get colourBlue;

  /// A colour name. ONE key, TWO uses: it renders the Stroop stimulus word AND its answer-key label. The colour-word mismatch that IS the game is generated from semantic tokens and is locale-independent; only the rendering is localized.
  ///
  /// In en, this message translates to:
  /// **'Green'**
  String get colourGreen;

  /// A colour name. ONE key, TWO uses: it renders the Stroop stimulus word AND its answer-key label. The colour-word mismatch that IS the game is generated from semantic tokens and is locale-independent; only the rendering is localized.
  ///
  /// In en, this message translates to:
  /// **'Yellow'**
  String get colourYellow;

  /// A Stroop answer colour word, offered on Blitz only. It is BOTH the stimulus word and an answer-key label, so it has to read at 78pt and fit a 92pt key.
  ///
  /// In en, this message translates to:
  /// **'Purple'**
  String get colourPurple;

  /// A Stroop answer colour word. Offered on Blitz, and it is also the label PlayAnswer.green takes under the colour-blind palette, because that palette paints green as orange.
  ///
  /// In en, this message translates to:
  /// **'Orange'**
  String get colourOrange;

  /// A Stroop answer colour word that exists ONLY under the colour-blind palette: it is the label PlayAnswer.red takes there, because that palette paints red as pink. There is no PlayAnswer.pink and there must not be.
  ///
  /// In en, this message translates to:
  /// **'Pink'**
  String get colourPink;

  /// The colour word "Red" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourRed.
  ///
  /// In en, this message translates to:
  /// **'RED'**
  String get stroopWordRed;

  /// The colour word "Blue" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourBlue.
  ///
  /// In en, this message translates to:
  /// **'BLUE'**
  String get stroopWordBlue;

  /// The colour word "Green" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourGreen.
  ///
  /// In en, this message translates to:
  /// **'GREEN'**
  String get stroopWordGreen;

  /// The colour word "Yellow" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourYellow.
  ///
  /// In en, this message translates to:
  /// **'YELLOW'**
  String get stroopWordYellow;

  /// The colour word "Purple" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourPurple.
  ///
  /// In en, this message translates to:
  /// **'PURPLE'**
  String get stroopWordPurple;

  /// The colour word "Orange" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourOrange.
  ///
  /// In en, this message translates to:
  /// **'ORANGE'**
  String get stroopWordOrange;

  /// The colour word "Pink" in its STIMULUS display form — the 78pt three-pass glyph at the centre of the board. Upper case in Latin locales and the natural form in Arabic script, which has no case; a second form rather than toUpperCase(), which is a no-op there and wrong in German. The key label form is colourPink.
  ///
  /// In en, this message translates to:
  /// **'PINK'**
  String get stroopWordPink;

  /// The line above the Stroop stimulus. Cased in the ARB, upper in Latin locales and natural in Arabic script — the design tracks the Latin form at .15em, which SunburstType applies per script because letterSpacing severs the cursive joins Arabic depends on.
  ///
  /// In en, this message translates to:
  /// **'TAP THE COLOUR, NOT THE WORD'**
  String get stroopPrompt;

  /// What a screen reader announces instead of the painted glyph: the word, and the colour it is printed in. Both are Strings rather than ints — a decimalPattern int placeholder would send ckb through intl's missing symbol data and silently emit Latin digits — and the word order differs per language, which is the whole point of a placeholder.
  ///
  /// In en, this message translates to:
  /// **'{word}, printed in {ink}'**
  String stroopStimulusValue(String word, String ink);

  /// The tags line above the game's hero panel. Upper case in Latin locales and the natural form in Arabic script, which has no case.
  ///
  /// In en, this message translates to:
  /// **'REACTION · FOCUS'**
  String get gameStroopRushKicker;

  /// The heading on the results screen. Warm and short; it is celebratory, not an evaluation of the score.
  ///
  /// In en, this message translates to:
  /// **'Nice run!'**
  String get resultsTitle;

  /// Badge shown on results when the run beat every previous run in its scope.
  ///
  /// In en, this message translates to:
  /// **'New personal best'**
  String get newPersonalBest;

  /// Label above the large results score. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'FINAL SCORE'**
  String get finalScore;

  /// Label on the accuracy figure on results. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'ACCURACY'**
  String get accuracyLabel;

  /// Label on the mean reaction-time figure on results. Abbreviated in en because the tile is narrow; a language that cannot abbreviate should use the full word and let the tile grow. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'AVG REACTION'**
  String get avgReactionLabel;

  /// The millisecond unit, rendered as its OWN run beside the number. A separate key so the value and its unit are never hand-glued, which is what breaks in RTL.
  ///
  /// In en, this message translates to:
  /// **'ms'**
  String get unitMilliseconds;

  /// The seconds unit, rendered as its OWN run beside the number, e.g. "18.6" + "s". A separate key for the same reason as unitMilliseconds: a value hand-glued to its unit is what breaks in RTL.
  ///
  /// In en, this message translates to:
  /// **'s'**
  String get unitSeconds;

  /// Label on the best-combo figure on results. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'LONGEST STREAK'**
  String get longestStreakLabel;

  /// Button on results that starts another round of the same game and difficulty.
  ///
  /// In en, this message translates to:
  /// **'Play again'**
  String get playAgain;

  /// Button on results that returns to the hub.
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get homeButton;

  /// The statistics screen heading.
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get statsTitle;

  /// The scope chip on Stats, saying the figures below cover every run ever.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get statsAllTime;

  /// Label on the best-points figure on Stats. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'BEST SCORE'**
  String get bestScore;

  /// Label on the fastest-completion figure on Stats. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'BEST TIME'**
  String get bestTime;

  /// Label on the total-play-time figure on Stats. CASED IN THE ARB, never with toUpperCase() in Dart: casing is a language property. Persian and Sorani have no case at all, so their value stays in its natural form and the type step drops its tracking there — Arabic script is cursive and positive tracking breaks the joins. A Dart toUpperCase() would also be locale-blind about Turkish dotted i and German eszett.
  ///
  /// In en, this message translates to:
  /// **'TIME TRAINED'**
  String get timeTrained;

  /// A duration in hours and minutes, e.g. '3h 12m'. The unit markers are INSIDE the message so de can say '3 Std. 12 Min.' and fa can say its own form. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m'**
  String durationHoursMinutes(String hours, String minutes);

  /// Heading above the recent-runs chart on Stats. NUMERALS: Numbers arrive PRE-FORMATTED as Strings, through LocaleNumbers. gen-l10n interpolates an int placeholder with Dart toString(), which is Latin digits in every locale — measured: this key rendered "4" instead of "۴" in Persian. Adding format: to the placeholder is not the fix either: gen-l10n would emit NumberFormat(localeName), and NumberFormat("ckb") THROWS. Where a plural is involved the int stays so ICU can pick the branch; only the printed value is the String.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Last {formatted} run} other{Last {formatted} runs}}'**
  String lastNRuns(int count, String formatted);

  /// The subtitle under the chart heading, naming the game and its best score. The score arrives already formatted for the locale.
  ///
  /// In en, this message translates to:
  /// **'{game} · best {score}'**
  String chartSubtitle(String game, String score);

  /// Axis label at the older end of the recent-runs chart. Its POSITION mirrors in RTL; the word does not change.
  ///
  /// In en, this message translates to:
  /// **'Oldest'**
  String get chartOldest;

  /// Axis label at the newer end of the recent-runs chart.
  ///
  /// In en, this message translates to:
  /// **'Latest'**
  String get chartLatest;

  /// The settings screen heading.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Row label for the sound-effects toggle.
  ///
  /// In en, this message translates to:
  /// **'Sound'**
  String get settingSound;

  /// Row label for the haptic-feedback toggle.
  ///
  /// In en, this message translates to:
  /// **'Haptics'**
  String get settingHaptics;

  /// Row label for the reduce-motion toggle. This is the app's own setting, independent of the OS one; either turning motion off is enough.
  ///
  /// In en, this message translates to:
  /// **'Reduce motion'**
  String get settingReduceMotion;

  /// Row label for the colour-blind answer palette. It re-points gameplay answer colours only and never moves UI chrome.
  ///
  /// In en, this message translates to:
  /// **'Colour-blind friendly palette'**
  String get settingColourBlind;

  /// The on state of a toggle, printed INSIDE the switch track. Authored in capitals. Its rendered width is a hard layout constraint: German EIN and Persian روشن are wider, and the track grows rather than the text shrinking.
  ///
  /// In en, this message translates to:
  /// **'ON'**
  String get toggleOn;

  /// The off state of a toggle, printed inside the switch track. Same width constraint as toggleOn.
  ///
  /// In en, this message translates to:
  /// **'OFF'**
  String get toggleOff;

  /// Settings row label that opens the language picker. The noun, not 'choose a language'.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// The option in the language picker that clears the override and follows the system locale. THIS one is translated; the language names beside it are not.
  ///
  /// In en, this message translates to:
  /// **'Use device language'**
  String get settingsLanguageSystem;

  /// Heading of the about section in Settings.
  ///
  /// In en, this message translates to:
  /// **'About MindForge'**
  String get aboutTitle;

  /// The product tagline, in the about section. The second sentence is the promise: the app works with no network connection at all, ever.
  ///
  /// In en, this message translates to:
  /// **'Train your brain. No wifi needed.'**
  String get aboutTagline;

  /// Heading of the pause sheet. No reference PNG exists for this sheet; it comes from system.html section 10.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get pauseTitle;

  /// Button on the pause sheet that continues the run.
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get pauseResume;

  /// Button on the pause sheet that abandons the run. It discards the run rather than saving it, so the wording must not sound like 'finish'.
  ///
  /// In en, this message translates to:
  /// **'Quit run'**
  String get pauseQuit;

  /// A language name, as an ENDONYM. NOT TRANSLATED — this exact string appears in all four ARBs. A user who has accidentally set the app to a language they cannot read must still be able to find their own, and that is the entire purpose of this row.
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageNameEn;

  /// A language name, as an ENDONYM. NOT TRANSLATED — this exact string appears in all four ARBs. A user who has accidentally set the app to a language they cannot read must still be able to find their own, and that is the entire purpose of this row.
  ///
  /// In en, this message translates to:
  /// **'Deutsch'**
  String get languageNameDe;

  /// A language name, as an ENDONYM. NOT TRANSLATED — this exact string appears in all four ARBs. A user who has accidentally set the app to a language they cannot read must still be able to find their own, and that is the entire purpose of this row.
  ///
  /// In en, this message translates to:
  /// **'فارسی'**
  String get languageNameFa;

  /// A language name, as an ENDONYM. NOT TRANSLATED — this exact string appears in all four ARBs. A user who has accidentally set the app to a language they cannot read must still be able to find their own, and that is the entire purpose of this row.
  ///
  /// In en, this message translates to:
  /// **'کوردیی ناوەندی'**
  String get languageNameCkb;

  /// Shown when a location cannot be matched — a stale deep link or a mistyped URL. A screen rather than go_router default red error page, which is an English stack trace.
  ///
  /// In en, this message translates to:
  /// **'That screen has moved'**
  String get notFoundTitle;

  /// One line under the colour-blind toggle saying exactly what it changes. Without it the setting reads as if it turns the fill patterns on, which are always on.
  ///
  /// In en, this message translates to:
  /// **'Swaps red for pink and green for orange. The fill patterns are always on.'**
  String get settingColourBlindHelp;

  /// Label of the version row on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Version'**
  String get aboutVersion;

  /// Heading of the offline promise on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Works offline, always'**
  String get aboutOffline;

  /// The offline promise. It is literally true: the app contains no HTTP client.
  ///
  /// In en, this message translates to:
  /// **'There is no network code in this app. Nothing is downloaded and nothing is sent.'**
  String get aboutOfflineBody;

  /// Heading of the privacy promise on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Nothing leaves your device'**
  String get aboutPrivate;

  /// The privacy promise. No accounts, no telemetry, on-device storage only.
  ///
  /// In en, this message translates to:
  /// **'No account, no analytics, no crash reporting. Your scores live in one file on this phone.'**
  String get aboutPrivateBody;

  /// Heading of the licence block on the About screen.
  ///
  /// In en, this message translates to:
  /// **'Licence'**
  String get aboutLicenceTitle;

  /// The app own licence. The SPDX identifier is passed in rather than written into the ARB: it is a proper noun that is never translated, and it carries ASCII digits that the fa and ckb numeral gate rightly refuses.
  ///
  /// In en, this message translates to:
  /// **'MindForge is open source under {licence}.'**
  String aboutLicenceBody(String licence);

  /// Row that opens the platform third-party licence list.
  ///
  /// In en, this message translates to:
  /// **'Open-source licences'**
  String get aboutThirdParty;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ckb', 'de', 'en', 'fa'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ckb':
      return AppLocalizationsCkb();
    case 'de':
      return AppLocalizationsDe();
    case 'en':
      return AppLocalizationsEn();
    case 'fa':
      return AppLocalizationsFa();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
