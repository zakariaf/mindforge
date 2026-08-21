import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_tile_state.dart';

/// One Schulte board, at one moment.
///
/// **Every field is a number or a flag; none is a String.** This board's
/// payload IS numbers — the tiles are the numbers 1..n² — so the temptation to
/// cache "۱۷" on the state is real and would be wrong the moment the locale
/// changed under it. Values are integers here and localized at render, and
/// `schulte_board_state_test` greps this file to keep it that way.
@immutable
final class SchulteBoardState {
  /// Creates a board.
  const SchulteBoardState({
    required this.cells,
    required this.nextValue,
    required this.started,
    this.wrongCount = 0,
    this.wrongIndex,
  });

  /// The scrambled values, in reading order.
  final List<int> cells;

  /// The value the player is hunting.
  final int nextValue;

  /// Whether the countdown has handed over.
  final bool started;

  /// The tile tapped out of order, until the next tap resolves it.
  ///
  /// **Cleared by the next interaction, not by a timer.** A game owns no
  /// clock — `sunburst-shell-screens` rule 3 — and a raw `Duration` under
  /// `lib/games/**` fails `check_motion_tokens.sh`. `ShakeOnWrong` owns the
  /// 480ms the shake takes; the state just remembers which tile it was.
  final int? wrongIndex;

  /// How many taps landed out of order, over the whole run.
  ///
  /// **It is also the shake's identity.** Tapping the same tile wrongly twice
  /// is two mistakes and has to feel like two, and a widget key that does not
  /// change makes the second look to the animation like a rebuild of the
  /// first. A separate `wrongTapId` field started at zero and was incremented
  /// on the same line as this one, so it was arithmetically this number
  /// wearing a second name.
  final int wrongCount;

  /// A counter that changes on every wrong tap.
  ///
  /// Tapping the same wrong tile twice is two answers and has to feel like
  /// two. Without an identity that changes, the second tap looks to the
  /// animation like a rebuild of the first.

  /// How many tiles the board holds.
  int get cellCount => cells.length;

  /// Cells per side.
  int get columnCount => math.sqrt(cellCount).round();

  /// How many values have been found.
  int get foundCount => nextValue - 1;

  /// Whether every value has been found.
  bool get isComplete => nextValue > cellCount;

  /// What the tile at [index] is doing.
  ///
  /// **Precedence, in this order: disabled, found, wrong, next, idle.** Found
  /// beats wrong deliberately — the latch outlives the tap that set it, so a
  /// tile the player already found must not flash red because a stale index
  /// still points at it.
  SchulteTileState stateOf(int index) {
    if (!started) return SchulteTileState.disabled;

    final value = cells[index];

    if (value < nextValue) return SchulteTileState.found;
    if (index == wrongIndex) return SchulteTileState.wrong;
    if (value == nextValue) return SchulteTileState.next;

    return SchulteTileState.idle;
  }

  /// A copy with the named parts replaced.
  ///
  /// `wrongIndex` takes a `clearWrong` flag rather than a nullable sentinel:
  /// `copyWith(wrongIndex: null)` cannot mean "clear it" and "leave it" at
  /// once, and every correct tap needs the first.
  SchulteBoardState copyWith({
    List<int>? cells,
    int? nextValue,
    bool? started,
    int? wrongIndex,
    bool clearWrong = false,
    int? wrongCount,
  }) => SchulteBoardState(
    cells: cells ?? this.cells,
    nextValue: nextValue ?? this.nextValue,
    started: started ?? this.started,
    wrongIndex: clearWrong ? null : (wrongIndex ?? this.wrongIndex),
    wrongCount: wrongCount ?? this.wrongCount,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SchulteBoardState &&
          _sameCells(other.cells, cells) &&
          other.nextValue == nextValue &&
          other.started == started &&
          other.wrongIndex == wrongIndex &&
          other.wrongCount == wrongCount;

  /// Whether two cell lists hold the same values in the same order.
  ///
  /// Written out rather than `listEquals`, which lives in
  /// `package:flutter/foundation.dart`: this directory is checked by
  /// `check-determinism-bans.sh` for being Flutter-free, and a generator that
  /// can reach Flutter can reach an unseeded random and a wall clock too.
  static bool _sameCells(List<int> a, List<int> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;

    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }

    return true;
  }

  @override
  int get hashCode => Object.hash(
    Object.hashAll(cells),
    nextValue,
    started,
    wrongIndex,
    wrongCount,
  );
}
