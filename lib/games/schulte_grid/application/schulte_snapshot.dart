import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/hud_tone.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/core/run_outcome.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_board_notifier.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_board_state.dart';

/// What the shell reads off a Schulte board.
///
/// **Integers cross this seam, never rendered text.** The Found pill is a
/// fraction — a numerator and a denominator — and the shell turns that into
/// `6 / 25` or `۶ / ۲۵` with the locale's own digits, its own separator and a
/// bidi isolate. A board that formatted the pair itself would be making three
/// decisions that belong to the locale, and this board's payload is numbers, so
/// the temptation is real.
///
/// It does not read a clock. The Time pill declares the shell as its source and
/// the shell fills it, because a game that measured the run would drift from
/// the ticker across a pause.
// The lint wants the family's own type spelled out and Riverpod 3 exports no
// name for it — the same reason the board family is declared this way.
// ignore: specify_nonobvious_property_types
final schulteSnapshotProvider = Provider.autoDispose
    .family<BoardSnapshot, RunConfig>((ref, config) {
      final state = ref.watch(schulteBoardNotifierProvider(config));

      return BoardSnapshot(
        hud: GameHud(
          // TIME is the shell's, and the slot says so.
          leading: const HudSlot(
            labelKey: 'hudTime',
            canonicalValue: 0,
            format: StatFormat.duration,
            source: HudSource.runClock,
          ),
          middle: HudSlot(
            labelKey: 'hudFound',
            canonicalValue: state.foundCount,
            format: StatFormat.fraction,
            total: state.cellCount,
          ),
          // THE ONE HIGHLIGHT. `next` is the cue that makes the board
          // learnable on a first run, and highlighting anything else would
          // compete with it. `alarm` is never a game's to reach for: whether
          // time is running out is the shell's judgement against the run
          // limit the shell owns.
          trailing: HudSlot(
            labelKey: 'hudNext',
            canonicalValue: state.isComplete
                ? state.cellCount
                : state.nextValue,
            format: StatFormat.count,
            tone: HudTone.highlight,
          ),
        ),
        // GEOMETRY, NOT TEXT. The track's width is a double in every language.
        progress: state.foundCount / state.cellCount,
        score: state.foundCount,
        correctCount: state.foundCount,
        wrongCount: state.wrongCount,
        // THE BOARD ENDS THIS RUN, which is the opposite of Stroop Rush: there
        // the clock runs out and the shell decides. Here the last tile is the
        // ending, and the shell reads it off this field.
        outcome: state.isComplete ? _outcomeOf(state) : null,
      );
    });

/// The three stats the results screen shows for a finished board.
///
/// **Not Stroop's three.** Accuracy is shared vocabulary and reuses the shell's
/// own ARB row; the other two are this game's — how many taps went astray, and
/// the board that was cleared. The tiles stat is a fraction, which is what puts
/// `StatFormat.fraction` on the results screen as well as in the HUD.
RunOutcome _outcomeOf(SchulteBoardState state) {
  final taps = state.foundCount + state.wrongCount;

  return RunOutcome.completed(
    // PER MILLE, StatFormat.percent's canonical unit: a rounded percentage is
    // a display decision and making it here would freeze one locale's idea of
    // precision.
    first: ResultStat(
      labelKey: 'accuracyLabel',
      format: StatFormat.percent,
      canonicalValue: taps == 0 ? 0 : (state.foundCount * 1000) ~/ taps,
    ),
    second: ResultStat(
      labelKey: 'schulteMissesLabel',
      format: StatFormat.count,
      canonicalValue: state.wrongCount,
    ),
    third: ResultStat(
      labelKey: 'schulteTilesLabel',
      format: StatFormat.fraction,
      canonicalValue: state.foundCount,
      total: state.cellCount,
    ),
  );
}
