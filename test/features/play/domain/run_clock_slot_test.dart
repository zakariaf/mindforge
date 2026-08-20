import 'package:flutter_test/flutter_test.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/features/play/domain/run_phase.dart';
import 'package:mindforge/features/play/domain/run_state.dart';

/// Who fills the TIME pill.
///
/// **The board says the slot exists; the shell says what is in it.** A game has
/// no clock of its own — `sunburst-shell-screens` rule 3 — so a board that
/// wanted to show elapsed time could only publish a zero and hope. Stroop Rush
/// did exactly that, with a comment saying the shell owned the value, and
/// nothing ever substituted it: the pill read 0:00 for the whole run.
void main() {
  final config = RunConfig(
    gameId: GameId('stroop_rush'),
    difficulty: Difficulty.classic,
    seed: 1,
  );

  RunState stateWith(Duration elapsed, HudSource source) => RunState(
    config: config,
    phase: RunPhase.playing,
    elapsed: elapsed,
    snapshot: BoardSnapshot(
      hud: GameHud(
        leading: HudSlot(
          labelKey: 'hudTime',
          canonicalValue: 0,
          format: StatFormat.duration,
          source: source,
        ),
        middle: const HudSlot(
          labelKey: 'hudScore',
          canonicalValue: 120,
          format: StatFormat.points,
        ),
      ),
    ),
  );

  test('a runClock slot is filled with the run elapsed', () {
    final state = stateWith(const Duration(seconds: 83), HudSource.runClock);

    expect(state.hud.leading.canonicalValue, 83000);
  });

  test('and a board slot is passed through untouched', () {
    final state = stateWith(const Duration(seconds: 83), HudSource.board);

    expect(state.hud.leading.canonicalValue, 0);
  });

  test('and nothing else about the slot is rewritten', () {
    final state = stateWith(const Duration(seconds: 5), HudSource.runClock);

    expect(state.hud.leading.labelKey, 'hudTime');
    expect(state.hud.leading.format, StatFormat.duration);
    expect(state.hud.leading.tone, HudTone.neutral);
    expect(state.hud.middle.canonicalValue, 120, reason: 'the board own value');
  });
}
