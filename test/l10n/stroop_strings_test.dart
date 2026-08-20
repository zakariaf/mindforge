import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../policy/support/source_text.dart';
import '../support/locale_matrix.dart';

/// Every string Stroop Rush shows, in four locales.
///
/// The colour words are not chrome. They are the stimulus and the four answers,
/// and their lengths differ by a factor of two across the shipped locales —
/// `Rot` is three characters and `پرتەقاڵی` is eight — inside a label box fixed
/// by a 92pt key that also carries a 56pt pattern panel.
void main() {
  Map<String, dynamic> arb(String tag) =>
      jsonDecode(File('lib/l10n/app_$tag.arb').readAsStringSync())
          as Map<String, dynamic>;

  /// The seven colour words, in their stimulus display form.
  const stimulusKeys = <String>[
    'stroopWordRed',
    'stroopWordBlue',
    'stroopWordGreen',
    'stroopWordYellow',
    'stroopWordPurple',
    'stroopWordOrange',
    'stroopWordPink',
  ];

  /// The same seven, in their key-label form.
  const labelKeys = <String>[
    'colourRed',
    'colourBlue',
    'colourGreen',
    'colourYellow',
    'colourPurple',
    'colourOrange',
    'colourPink',
  ];

  const otherKeys = <String>['stroopPrompt', 'stroopStimulusValue'];

  group('every Stroop key exists in all four locales', () {
    for (final tag in localeMatrix) {
      test('$tag has all of them', () {
        final messages = arb(tag);

        for (final key in <String>[
          ...stimulusKeys,
          ...labelKeys,
          ...otherKeys,
        ]) {
          expect(
            messages.containsKey(key),
            isTrue,
            reason: '$key is missing from app_$tag.arb',
          );
          expect((messages[key] as String).trim(), isNotEmpty, reason: key);
        }
      });
    }
  });

  group('the two display forms are genuinely two', () {
    test(
      'in Latin locales the stimulus form is upper and the label is not',
      () {
        // TWO GROUPS RATHER THAN ONE PLUS toUpperCase(). The design prints the
        // stimulus at 78pt in caps and the key label in title case; uppercasing
        // in Dart is a no-op in Arabic script and wrong in German, where ß
        // becomes SS and changes the length of the very string that has to fit
        // inside a key.
        for (final tag in <String>['en', 'de']) {
          final messages = arb(tag);

          for (var i = 0; i < stimulusKeys.length; i++) {
            final word = messages[stimulusKeys[i]] as String;
            final label = messages[labelKeys[i]] as String;

            expect(
              word,
              word.toUpperCase(),
              reason: '${stimulusKeys[i]} in $tag is not the upper form',
            );
            expect(
              label,
              isNot(equals(label.toUpperCase())),
              reason: '${labelKeys[i]} in $tag should be title case',
            );
          }
        }
      },
    );

    test('and in Arabic-script locales the two forms are identical', () {
      // Arabic script has no case at all, so a second form would be the same
      // string twice — and the keys still exist, because the CALLER must not
      // have to know which locale it is in.
      for (final tag in <String>['fa', 'ckb']) {
        final messages = arb(tag);

        for (var i = 0; i < stimulusKeys.length; i++) {
          expect(
            messages[stimulusKeys[i]],
            messages[labelKeys[i]],
            reason: '${stimulusKeys[i]} vs ${labelKeys[i]} in $tag',
          );
        }
      }
    });
  });

  group('the stimulus announcement', () {
    test('uses both placeholders, in every locale', () {
      // Word order differs per language and that is the whole point of a
      // placeholder: "{word}, printed in {ink}" is not a sentence a
      // concatenation can build.
      for (final tag in localeMatrix) {
        final value = arb(tag)['stroopStimulusValue'] as String;

        expect(value, contains('{word}'), reason: tag);
        expect(value, contains('{ink}'), reason: tag);
      }
    });

    test('and its placeholders are Strings, never ints', () {
      // A `format: decimalPattern` int placeholder would send ckb through
      // intl's missing symbol data and silently emit Latin digits. These two
      // are colour words rather than numbers, and the type says so.
      final meta = arb('en')['@stroopStimulusValue'] as Map<String, dynamic>;
      final placeholders = meta['placeholders'] as Map<String, dynamic>;

      for (final name in <String>['word', 'ink']) {
        expect(
          (placeholders[name] as Map<String, dynamic>)['type'],
          'String',
          reason: name,
        );
      }
    });
  });

  group('the drafts are marked as drafts', () {
    for (final tag in <String>['fa', 'ckb']) {
      test('$tag carries the native-review marker on every Stroop message', () {
        // Committed so the layout can be tested against realistic lengths, and
        // marked so nobody mistakes a machine draft for a reviewed
        // translation. Risk 3 in the epic.
        final messages = arb(tag);

        for (final key in <String>[...stimulusKeys, ...otherKeys]) {
          expect(
            messages['@$key'],
            isNotNull,
            reason: '$key has no metadata in app_$tag.arb',
          );
          expect(
            (messages['@$key'] as Map<String, dynamic>)['x-review'],
            'native-speaker-pending',
            reason: key,
          );
        }
      });
    }
  });

  group('nothing in the game cases a string in Dart', () {
    test('no toUpperCase or toLowerCase under lib/games/stroop_rush', () {
      final offenders = <String>[];

      for (final entity in Directory(
        'lib/games/stroop_rush',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;

        // COMMENT-STRIPPED. The rule is about code, and the file that obeys
        // it most carefully is the one that explains why at the top — a scan
        // over raw text makes the explanation the violation.
        final code = withoutDartComments(entity.readAsStringSync());

        if (code.contains('toUpperCase(') || code.contains('toLowerCase(')) {
          offenders.add(entity.path);
        }
      }

      expect(
        offenders,
        isEmpty,
        reason:
            'casing is a language property: it is a no-op in Arabic script and '
            'wrong in German. The cased form belongs in the ARB',
      );
    });

    test('and no letterSpacing either — tracking is a theme decision', () {
      // Flutter's letterSpacing inserts advance after every glyph, which
      // visually severs the cursive joins Arabic script depends on. The .15em
      // the design puts on the Latin prompt is a theme decision, applied
      // per-script by SunburstType, and a board that set its own would apply
      // it to all four.
      final offenders = <String>[];

      for (final entity in Directory(
        'lib/games/stroop_rush',
      ).listSync(recursive: true)) {
        if (entity is! File || !entity.path.endsWith('.dart')) continue;
        if (withoutDartComments(
          entity.readAsStringSync(),
        ).contains('letterSpacing')) {
          offenders.add(entity.path);
        }
      }

      expect(offenders, isEmpty);
    });
  });
}
