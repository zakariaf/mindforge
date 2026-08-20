import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/run_config.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_board_state.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_rules.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_scramble.dart';
import 'package:mindforge/shared/feedback/feedback_service.dart';
import 'package:mindforge/shared/feedback/moment.dart';

/// The board's one owner.
///
/// **Two intents and nothing else.** `start()` is the countdown handing over,
/// `tapCell` is the player. Everything the shell reads is derived — the board
/// never navigates, never ends the run and never reads a clock.
///
/// **It does not watch the locale.** A language change mid-run would rebuild
/// this notifier, reroll the scramble under the player's hand and hand them a
/// different board than the one they were half way through.
final class SchulteBoardNotifier extends Notifier<SchulteBoardState> {
  /// Creates the board for [config].
  SchulteBoardNotifier(this.config);

  /// Which run is being played.
  final RunConfig config;

  @override
  SchulteBoardState build() => SchulteBoardState(
    cells: schulteScramble(
      seed: config.seed,
      size: SchulteRules.forDifficulty(config.difficulty).gridSize,
    ),
    nextValue: 1,
    // NOT STARTED. The run notifier builds this board at `start()`, which is
    // three seconds before the countdown ends; the tiles are visible and
    // must not be playable until the countdown says so.
    started: false,
    wrongTapId: 0,
  );

  /// The countdown has handed over.
  void start() {
    if (state.started) return;

    state = state.copyWith(started: true);
  }

  /// The player tapped the tile at [index].
  void tapCell(int index) {
    if (!state.started || state.isComplete) return;

    final value = state.cells[index];

    // ALREADY FOUND: not a mistake, and not an event. A player resting a
    // finger on a tile they cleared should feel nothing at all.
    if (value < state.nextValue) return;

    if (value != state.nextValue) {
      _fire(Moment.answerWrong);

      state = state.copyWith(
        wrongIndex: index,
        // A NEW IDENTITY on every wrong tap, so tapping the same wrong tile
        // twice shakes twice.
        wrongTapId: state.wrongTapId + 1,
        wrongCount: state.wrongCount + 1,
      );

      return;
    }

    // `tileNextCue` is a DECLARED SILENCE. The cue moving to the next number
    // is a consequence, not something the player did, and firing it here would
    // make every correct tap buzz twice.
    _fire(Moment.tileFound);

    state = state.copyWith(
      nextValue: state.nextValue + 1,
      // THE LATCH RESOLVES ON THE NEXT INTERACTION. A game owns no timer, and
      // `ShakeOnWrong` already owns how long the shake takes.
      clearWrong: true,
    );
  }

  void _fire(Moment moment) => ref.read(feedbackServiceProvider).fire(moment);
}

/// The board for one run.
///
/// The same modifier shape the Stroop notifier uses: autoDispose, family-keyed
/// by `RunConfig`, so "play again" is a new seed and therefore a new board.
// The lint wants the family's own type spelled out and Riverpod 3 exports no
// name for it — the same reason the Stroop family and the run family are
// declared this way.
// ignore: specify_nonobvious_property_types
final schulteBoardNotifierProvider = NotifierProvider.autoDispose
    .family<SchulteBoardNotifier, SchulteBoardState, RunConfig>(
      SchulteBoardNotifier.new,
    );
