// Every colourRole/background pair is written out even when one half matches
// the fixture's default. These tests are ABOUT the pairing, and a test that
// names one side and leaves the other implicit reads as though only one side
// mattered.
// ignore_for_file: avoid_redundant_argument_values

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/game_definition.dart';

import '../support/fixture_game.dart';

void main() {
  group('the colour role and the background are paired', () {
    test('a mechanic game MUST sit on surfaceSunk', () {
      // sunburst-game-surfaces names this as the rule no switch can catch. On
      // the game accent, the identity colour sits behind the hues that ARE the
      // question — which is the whole mechanic of Stroop Rush.
      expect(
        () => fixtureGame(
          colourRole: BoardColourRole.mechanic,
          boardBackground: BoardBackground.gameAccent,
        ),
        throwsAssertionError,
      );

      expect(
        fixtureGame(
          colourRole: BoardColourRole.mechanic,
          boardBackground: BoardBackground.surfaceSunk,
        ).boardBackground,
        BoardBackground.surfaceSunk,
      );
    });

    test('and a decorative game may take either', () {
      // Colour is never its answer, so nothing is hidden behind the accent.
      for (final background in BoardBackground.values) {
        expect(
          fixtureGame(
            colourRole: BoardColourRole.decorative,
            boardBackground: background,
          ).boardBackground,
          background,
        );
      }
    });
  });

  group('what a definition must offer', () {
    test('at least one difficulty, or nothing can start it', () {
      expect(
        () => fixtureGame(difficulties: <Difficulty>[]),
        throwsAssertionError,
      );
    });

    test('and a locked game still declares an accent and an artwork', () {
      // The "coming soon" card shows neither, but unlocking it is a flag flip
      // rather than a new definition.
      final locked = fixtureGame(isLocked: true);

      expect(locked.isLocked, isTrue);
      expect(locked.buildArtwork, isNotNull);
      expect(locked.difficulties, isNotEmpty);
    });
  });

  group('the run limit', () {
    test('a timed game answers per difficulty', () {
      final game = fixtureGame(
        runLimitFor: (difficulty) => switch (difficulty) {
          Difficulty.chill => const Duration(seconds: 90),
          Difficulty.classic => const Duration(seconds: 60),
          Difficulty.blitz => const Duration(seconds: 30),
        },
      );

      expect(game.runLimitFor(Difficulty.chill), const Duration(seconds: 90));
      expect(game.runLimitFor(Difficulty.classic), const Duration(seconds: 60));
      expect(game.runLimitFor(Difficulty.blitz), const Duration(seconds: 30));
    });

    test('and an untimed game returns null for every one of them', () {
      // Schulte Grid ends when the last tile is found. Any shell-imposed limit
      // would cut the player off mid-board, which is why the limit lives on the
      // game rather than on the Difficulty enum.
      final game = fixtureGame(isTimed: false);

      for (final difficulty in Difficulty.values) {
        expect(game.runLimitFor(difficulty), isNull, reason: difficulty.name);
      }
    });

    test('and an untimed game cannot declare one at all', () {
      expect(
        () => fixtureGame(
          isTimed: false,
          runLimitFor: (_) => const Duration(seconds: 60),
        ),
        throwsAssertionError,
      );
    });

    test('and a timed game with no lookup is unlimited', () {
      // Stroop Rush ends on a round count reported through the snapshot, not on
      // a clock. "Timed" means the shell shows elapsed time, not that it stops
      // the run.
      final game = fixtureGame();

      for (final difficulty in Difficulty.values) {
        expect(game.runLimitFor(difficulty), isNull, reason: difficulty.name);
      }
    });
  });

  group('a definition carries ARB keys, never display strings', () {
    test('the constructor rejects anything that is not a key', () {
      for (final bad in <String>[
        'Stroop Rush',
        'stroop-rush',
        'ستروپ',
        'Title',
      ]) {
        expect(
          () => fixtureGame(
            strings: GameStringIds(
              titleKey: bad,
              taglineKey: 'gameStroopRushTagline',
              kickerKey: 'gameStroopRushKicker',
            ),
          ),
          throwsAssertionError,
          reason: bad,
        );
      }
    });

    test('and accepts lowerCamelCase ASCII', () {
      final game = fixtureGame();

      for (final key in game.strings.keys) {
        expect(RegExp(r'^[a-z][a-zA-Z0-9]*$').hasMatch(key), isTrue);
      }
    });
  });
}
