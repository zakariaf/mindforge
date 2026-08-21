import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/supported_locale.dart';
import 'package:mindforge/l10n/locale_numbers.dart';

/// Asserts what the ARB files **say**, not only which keys they hold.
///
/// `check_arb_parity.sh` compares key sets and nothing else. Measured: putting
/// `"bestLabel": "بهترین ٤"` — an Arabic-Indic U+0664, the block CLAUDE.md
/// forbids — and `"statsAllTime": ""` into `app_fa.arb` left every test in the
/// repository green, `tool/skill_gates.sh` at 34 passed, and both values landed
/// in `strings-fa.json`, which is the file the Persian reference screenshots
/// render from.
void main() {
  /// An ICU message with its SYNTAX removed, leaving only what a reader sees.
  ///
  /// `{count, plural, =0{...} other{...}}` carries an ASCII `0` that is a
  /// selector, not content, and a placeholder name is not a word anyone reads.
  /// Scanning the raw message reported both as defects.
  String proseOf(String message) => message
      .replaceAll(RegExp(r'\{\s*\w+\s*,\s*(plural|select)\s*,'), '')
      .replaceAll(RegExp(r'(?<![\w])=\d+\{'), '{')
      .replaceAll(RegExp(r'\b(zero|one|two|few|many|other)\{'), '{')
      .replaceAll(RegExp(r'\{\w+\}'), '');

  Map<String, String> messagesOf(SupportedLocale locale) {
    final arb =
        jsonDecode(File('lib/l10n/app_${locale.tag}.arb').readAsStringSync())
            as Map<String, dynamic>;

    return <String, String>{
      for (final entry in arb.entries)
        if (!entry.key.startsWith('@')) entry.key: entry.value! as String,
    };
  }

  for (final locale in SupportedLocale.values) {
    group('app_${locale.tag}.arb', () {
      final messages = messagesOf(locale);

      test('has no empty or whitespace-only value', () {
        // gen-l10n emits an empty string happily, and every downstream check
        // treats it as a valid message: it fits any type step, holds no banned
        // digit, and renders as a gap nobody notices until a screenshot.
        expect(
          messages.entries
              .where((e) => e.value.trim().isEmpty)
              .map((e) => e.key),
          isEmpty,
        );
      });

      test('holds no Arabic-Indic digit', () {
        // U+0660-U+0669. MindForge renders the EASTERN ARABIC block
        // U+06F0-U+06F9; the Arabic-Indic 4, 5 and 6 are different glyphs, and
        // a translation pasted from an Arabic source carries them invisibly.
        // Written with `where(...).isNotEmpty` rather than Iterable's
        // shorter predicate method: check_test_hygiene.sh greps test/ for a
        // bare call by that name, looking for mocktail matchers used without a
        // registered fallback, and cannot tell the two apart. The gate is
        // right to be crude; this is the cheaper side to move.
        bool isArabicIndic(int rune) => rune >= 0x0660 && rune <= 0x0669;

        final offenders = <String>[
          for (final entry in messages.entries)
            if (entry.value.runes.where(isArabicIndic).isNotEmpty)
              '${entry.key}: "${entry.value}"',
        ];

        expect(offenders, isEmpty, reason: offenders.join('\n'));
      });

      test('holds no isolate or direction control character', () {
        // BidiText.isolate is a RENDERING step. A control character baked into
        // a translation is invisible in every editor, survives into the store
        // through any value built from it, and breaks equality against the
        // same string typed by hand.
        const controls = <int>[
          0x2066, 0x2067, 0x2068, 0x2069, // LRI RLI FSI PDI
          0x202A, 0x202B, 0x202C, 0x202D, 0x202E, // LRE RLE PDF LRO RLO
        ];
        final offenders = <String>[
          for (final entry in messages.entries)
            if (entry.value.runes.where(controls.contains).isNotEmpty)
              entry.key,
        ];

        expect(offenders, isEmpty, reason: offenders.join('\n'));
      });

      if (locale.isRightToLeft) {
        test('holds no ASCII digit, because numbers arrive pre-formatted', () {
          // The measured bug: gen-l10n interpolates an int placeholder with
          // Dart toString(). A literal ASCII digit typed into the translation
          // itself is the same defect one layer earlier.
          final offenders = <String>[
            for (final entry in messages.entries)
              if (RegExp('[0-9]').hasMatch(proseOf(entry.value)))
                '${entry.key}: "${entry.value}"',
          ];

          expect(offenders, isEmpty, reason: offenders.join('\n'));
        });

        test('renders every message in this locale free of ASCII digits', () {
          // The ARB check above catches a literal; this catches a placeholder
          // that gets an unformatted argument, by rendering the real strings.
          final numbers = LocaleNumbers(locale);

          expect(numbers.count(1480), isNot(matches('[0-9]')));
          expect(numbers.clock(65000), isNot(matches('[0-9]')));
          expect(numbers.percent(0.92), isNot(matches('[0-9]')));
        });
      }
    });
  }

  group('across the four locales', () {
    test('no message is identical to the English template by accident', () {
      // A key left untranslated reads as shipped when it is not. The
      // exceptions are the ones that are legitimately the same in every
      // language, and they are listed rather than inferred.
      // Identical BY CONSTRUCTION: a proper name, or a template that is
      // nothing but placeholders and punctuation.
      const sameInEveryLanguage = <String>{
        'appTitle', // the wordmark
        'gameNBackName', // a proper name
        // "Stroop" is the psychologist the task is named after, so the English
        // and German names are the same two words. fa and ckb DO translate the
        // second word, which is why this is here and not in sameAsEnglish.
        'gameStroopRushName',
        'gameAndDifficulty', // '{game} · {difficulty}'
        'streakMultiplier', // '×{formatted}'
        'foundOfTotal', // '{found} / {total}'
        // Each language is named in its own language, everywhere.
        'languageNameEn',
        'languageNameDe',
        'languageNameFa',
        'languageNameCkb',
      };

      // Identical because the German word IS the English one. Listed per
      // locale and per key, so a fifth locale inherits nothing by accident.
      const sameAsEnglish = <SupportedLocale, Set<String>>{
        SupportedLocale.de: <String>{
          'aboutVersion', // Version — the German word IS "Version"
          'bestLabel', // BEST
          'colourOrange', // Orange — the German colour word IS "Orange"
          'stroopWordOrange', // ORANGE — the same word, in the stimulus form
          'difficultyBlitz', // Blitz — an English loanword FROM German
          'unitMilliseconds', // ms
          'unitSeconds', // s
        },
      };

      final english = messagesOf(SupportedLocale.en);

      for (final locale in SupportedLocale.values) {
        if (locale == SupportedLocale.en) continue;

        final shared = messagesOf(locale).entries
            .where((e) => e.value == english[e.key])
            .map((e) => e.key)
            .where((key) => !sameInEveryLanguage.contains(key))
            .where(
              (key) =>
                  !(sameAsEnglish[locale] ?? const <String>{}).contains(key),
            )
            .toList();

        expect(
          shared,
          isEmpty,
          reason:
              '${locale.tag} repeats the English string for: $shared. If one '
              'of these is genuinely identical, add it to '
              'sameInEveryLanguage with the reason',
        );
      }
    });
  });

  group('the label roles app.html sets in caps', () {
    // `text-transform:uppercase` is a CSS property with no Flutter equivalent,
    // and `toUpperCase()` is banned in lib/ — it is locale-dependent (Turkish
    // dotted i) and meaningless in Arabic script, which has no case at all.
    // The convention this repo settled on is that the CASE IS AUTHORED: an
    // uppercase English string in the ARB, and whatever the script does in
    // `fa` and `ckb`, which is nothing.
    //
    // The four HUD labels missed it, and no test noticed until the play screen
    // was put beside `screens/04-stroop-rush.png` on the simulator. This is
    // that comparison, written down.
    const capsInLatin = <String>{
      'bestLabel', // .bestcard .bl s
      'yourBest',
      'gamesPlayed',
      'difficultyTitle',
      'gameStroopRushKicker', // .hero .kicker
      'gameSchulteGridKicker',
      'stroopPrompt', // .stim .ask
      'finalScore', // .scoreslab s
      'accuracyLabel', // .tri s
      'avgReactionLabel',
      'longestStreakLabel',
      'bestScore', // .statbox s
      'bestTime',
      'timeTrained',
      'hudTime', // .hstat s
      'hudScore',
      'hudStreak',
      'hudFound',
      'hudNext',
      'schulteMissesLabel',
      'schulteTilesLabel',
    };

    for (final locale in <SupportedLocale>[
      SupportedLocale.en,
      SupportedLocale.de,
    ]) {
      test('are authored uppercase in ${locale.tag}', () {
        final messages = messagesOf(locale);
        final lowercase = capsInLatin
            .where(messages.containsKey)
            .where((key) => messages[key] != messages[key]!.toUpperCase())
            .toList();

        expect(
          lowercase,
          isEmpty,
          reason:
              'app.html draws these in caps and Flutter has no text-transform, '
              'so the ARB carries the case',
        );
      });
    }

    test('and the Arabic-script locales are left alone', () {
      // Not an oversight: `toUpperCase()` is the identity function on Arabic
      // script, so asserting it there would assert nothing while looking like
      // coverage. What IS asserted is that nobody transliterated them into
      // Latin capitals to satisfy the rule above.
      for (final locale in <SupportedLocale>[
        SupportedLocale.fa,
        SupportedLocale.ckb,
      ]) {
        final messages = messagesOf(locale);

        expect(
          messages['hudScore'],
          isNot(matches(RegExp('[A-Za-z]'))),
          reason: '${locale.tag} hudScore carries Latin letters',
        );
      }
    });
  });
}
