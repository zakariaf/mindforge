import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';

import '../policy/support/source_text.dart';

void main() {
  group('the three difficulties', () {
    test('are declared in display order', () {
      // The order the segmented control paints them in, easiest first. A
      // reorder here silently reorders every difficulty picker in the app.
      expect(Difficulty.values, <Difficulty>[
        Difficulty.chill,
        Difficulty.classic,
        Difficulty.blitz,
      ]);
    });

    test('carry an ARB key, never a label', () {
      const expected = <Difficulty, String>{
        Difficulty.chill: 'difficultyChill',
        Difficulty.classic: 'difficultyClassic',
        Difficulty.blitz: 'difficultyBlitz',
      };

      expect(expected.keys.toSet(), Difficulty.values.toSet());

      for (final entry in expected.entries) {
        expect(entry.key.labelKey, entry.value);
      }
    });

    test('and no member holds a displayable sentence', () {
      // A key is lowerCamelCase with no spaces. A label is a word someone
      // translated, and a translated word on an enum is a word four locales
      // cannot change.
      for (final difficulty in Difficulty.values) {
        expect(
          RegExp(r'^[a-z][a-zA-Z]*$').hasMatch(difficulty.labelKey),
          isTrue,
          reason: '${difficulty.name} -> ${difficulty.labelKey}',
        );
      }
    });
  });

  group('what a difficulty deliberately does NOT carry', () {
    test('no run limit, so a game decides its own length', () {
      // A duration on this enum would force every game to be timed the same
      // way. Schulte Grid is not timed at all — it ends when the last tile is
      // found — and a `runLimit` here is what makes that a special case in the
      // shell rather than a property of the game.
      // Read off the source rather than the type: an enum's members are
      // getters, so a field-name walk returns nothing and would pass against a
      // Difficulty that carried a Duration.
      final source = File('lib/core/difficulty.dart').readAsStringSync();

      for (final banned in <String>[
        'Duration',
        'runLimit',
        'seconds',
        'millis',
      ]) {
        expect(
          withoutDartComments(source),
          isNot(contains(banned)),
          reason:
              'a run length here forces every game to be timed the same way, '
              'and Schulte Grid is not timed at all',
        );
      }
    });
  });

  group('the persisted token', () {
    test('is the enum name, not the key', () {
      // The `runs` table joins on this. It must survive a translation edit and
      // an ARB key rename alike.
      expect(
        Difficulty.values.map((d) => d.name).toList(),
        <String>['chill', 'classic', 'blitz'],
      );
    });
  });
}
