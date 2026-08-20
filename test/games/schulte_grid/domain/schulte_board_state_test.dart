import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_board_state.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';

/// One immutable board, and the five states a tile can be in.
void main() {
  /// A 2x2 board whose cells are `[3, 1, 4, 2]`.
  SchulteBoardState boardWith({
    int nextValue = 1,
    bool started = true,
    int? wrongIndex,
    int wrongTapId = 0,
  }) => SchulteBoardState(
    cells: const <int>[3, 1, 4, 2],
    nextValue: nextValue,
    started: started,
    wrongIndex: wrongIndex,
    wrongTapId: wrongTapId,
  );

  group('stateOf', () {
    test('is disabled everywhere until the board starts', () {
      // WHAT `disabled` IS FOR. The board is built when the run starts, which
      // is behind the countdown — it is on screen, and it must not be
      // playable, for three seconds before the run begins.
      final board = boardWith(started: false);

      for (var i = 0; i < board.cellCount; i++) {
        expect(board.stateOf(i), SchulteTileState.disabled);
      }
    });

    test('marks the tile holding nextValue, and leaves the rest idle', () {
      // cells are [3, 1, 4, 2]; 1 lives at index 1.
      final board = boardWith();

      expect(board.stateOf(1), SchulteTileState.next);
      expect(board.stateOf(0), SchulteTileState.idle);
      expect(board.stateOf(2), SchulteTileState.idle);
      expect(board.stateOf(3), SchulteTileState.idle);
    });

    test('and a value already passed reads found', () {
      // nextValue 3 means 1 and 2 are behind us: index 1 holds 1, index 3
      // holds 2, and index 0 holds 3, which is next.
      final board = boardWith(nextValue: 3);

      expect(board.stateOf(1), SchulteTileState.found);
      expect(board.stateOf(3), SchulteTileState.found);
      expect(board.stateOf(0), SchulteTileState.next);
    });

    test('and a found tile is never wrong, whatever the latch says', () {
      // PRECEDENCE, asserted directly. The latch is cleared on the next tap
      // rather than by a timer the game is not allowed to own, so a stale
      // index can outlive the tap that set it — and a tile the player has
      // already found must not flash red because of it.
      final board = boardWith(nextValue: 3, wrongIndex: 1);

      expect(board.stateOf(1), SchulteTileState.found);
    });

    test('and disabled beats everything', () {
      final board = boardWith(nextValue: 3, wrongIndex: 0, started: false);

      expect(board.stateOf(0), SchulteTileState.disabled);
      expect(board.stateOf(1), SchulteTileState.disabled);
    });

    test('is total over every index of every reachable state', () {
      // A `switch` with no `default:` is only total if every combination
      // reaches a case. Walked rather than argued.
      for (final started in <bool>[true, false]) {
        for (var next = 1; next <= 5; next++) {
          for (final wrong in <int?>[null, 0, 1, 2, 3]) {
            final board = boardWith(
              nextValue: next,
              started: started,
              wrongIndex: wrong,
            );

            for (var i = 0; i < board.cellCount; i++) {
              expect(board.stateOf(i), isA<SchulteTileState>());
            }
          }
        }
      }
    });
  });

  group('the derived counts', () {
    test('foundCount trails nextValue by one, and completion is the last', () {
      expect(boardWith().foundCount, 0);
      expect(boardWith().isComplete, isFalse);
      expect(boardWith(nextValue: 4).foundCount, 3);
      expect(boardWith(nextValue: 4).isComplete, isFalse);
      expect(boardWith(nextValue: 5).foundCount, 4);
      expect(boardWith(nextValue: 5).isComplete, isTrue);
    });

    test('and columnCount is the square root of the cell count', () {
      expect(boardWith().columnCount, 2);
      expect(
        SchulteBoardState(
          cells: List<int>.generate(25, (i) => i + 1),
          nextValue: 1,
          started: true,
          wrongTapId: 0,
        ).columnCount,
        5,
      );
    });
  });

  group('the state itself', () {
    test('carries no formatted text — every field is a number or a flag', () {
      // A cached display label would be wrong the moment the locale changed,
      // and this board's payload IS numbers, so the temptation is real. The
      // grep is what fails instead of the screen.
      final source =
          File(
                'lib/games/schulte_grid/domain/schulte_board_state.dart',
              )
              .readAsStringSync()
              .split('\n')
              .where(
                (line) =>
                    !line.trimLeft().startsWith('//') &&
                    !line.trimLeft().startsWith('///'),
              )
              .join('\n');

      expect(
        RegExp(r'\bfinal String[?\s]').hasMatch(source),
        isFalse,
        reason: 'a String field on the board state is a formatted value',
      );
    });

    test('and compares by value', () {
      expect(boardWith(), boardWith());
      expect(boardWith().hashCode, boardWith().hashCode);
      expect(boardWith(nextValue: 2), isNot(boardWith()));
    });
  });
}
