import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_rules.dart';
import 'package:mindforge/ui/components/pop_surface.dart';

/// How big the grid is, and why Blitz is not offered.
void main() {
  group('the rules table', () {
    test('forDifficulty is exhaustive and total', () {
      // Every difficulty answers, including the one the game does not offer:
      // a table with a hole in it is a crash waiting for a deep link.
      expect(SchulteRules.forDifficulty(Difficulty.chill).gridSize, 4);
      expect(SchulteRules.forDifficulty(Difficulty.classic).gridSize, 5);
      expect(SchulteRules.forDifficulty(Difficulty.blitz).gridSize, 6);
    });

    test('and cellCount is the square', () {
      expect(SchulteRules.forDifficulty(Difficulty.chill).cellCount, 16);
      expect(SchulteRules.forDifficulty(Difficulty.classic).cellCount, 25);
    });

    test('schulteDifficulties is [chill, classic] — Blitz is absent', () {
      expect(schulteDifficulties, <Difficulty>[
        Difficulty.chill,
        Difficulty.classic,
      ]);
    });
  });

  group('Blitz is withheld, and the arithmetic says why', () {
    test('a 6x6 grid misses the tap floor on the narrowest device', () {
      // 320pt device, the conservative floor E05 kept: 280pt of board after
      // the shell's 20pt gutters, six columns, 8pt between them.
      expect(schulteCell(280, 6, 8), 40.0);
      expect(schulteCell(280, 6, 8), lessThan(kPopMinTarget));
    });

    test('and the shell own remaining lever does not save it', () {
      // Narrowing the gutter from 20 to 16 buys 8pt of board and still lands
      // short, so there is no layout change that rescues a 6x6 at 320.
      expect(schulteCell(288, 6, 8), closeTo(41.33, 0.01));
      expect(schulteCell(288, 6, 8), lessThan(kPopMinTarget));
    });

    test(
      'but on the narrowest iPhone SHIPPING, the tap floor alone clears',
      () {
        // 375pt — iPhone SE 2 and 3 — is the smallest device actually sold, and
        // there the cell is 49.17pt. Recorded honestly: the tap-target argument
        // does NOT withhold Blitz on any shipping iPhone, and stating otherwise
        // in a comment would be a reason nobody can check.
        //
        // The reason that does hold is T10.6's: at that cell the inner box is
        // 39.17pt, and a two-digit Eastern Arabic numeral does not fit it at an
        // accessible text scale. That is measured where it can be, on a board.
        expect(schulteCell(335, 6, 8), closeTo(49.17, 0.01));
        expect(schulteCell(335, 6, 8), greaterThan(kPopMinTarget));
      },
    );
  });
}
