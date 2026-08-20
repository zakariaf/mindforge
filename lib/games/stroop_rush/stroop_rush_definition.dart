import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/stroop_rush/application/stroop_board_notifier.dart';
import 'package:mindforge/games/stroop_rush/ui/board/stroop_artwork.dart';
import 'package:mindforge/games/stroop_rush/ui/stroop_board.dart';
import 'package:mindforge/theme/game_accent.dart';

/// Stroop Rush, as the engine sees it.
///
/// **The whole of what the shell knows about this game.** Home cards, BEST
/// pills, difficulty lists, score formatting and the play chrome are all read
/// off this object; no file under `lib/features/**` names Stroop Rush, and
/// `git diff --stat main -- lib/features/` is how that claim is checked.
final GameDefinition stroopRushDefinition = GameDefinition(
  id: GameId('stroop_rush'),
  accent: GameAccent.stroop,
  // MECHANIC, not decorative: hue IS the answer here, so the gate that keeps
  // chrome slots out of the board rectangle applies to every pixel of it.
  colourRole: BoardColourRole.mechanic,
  scoreFormat: ScoreFormat.points,
  // THE BOARD SCORES. Points come from the answer sequence, not from a clock
  // the shell owns, which is what makes the run reproducible from its seed.
  scoreSource: ScoreSource.board,
  strings: const GameStringIds(
    titleKey: 'gameStroopRushName',
    taglineKey: 'gameStroopRushTagline',
    kickerKey: 'gameStroopRushKicker',
  ),
  difficulties: Difficulty.values,
  // The board is a sunken field with the stimulus card raised out of it, which
  // is the pairing `accent-contract.md` requires of a mechanic game: an accent
  // background would put a chrome colour behind the answer keys.
  boardBackground: BoardBackground.surfaceSunk,
  // TIMED — the default, and stated here because it is a decision rather than
  // an inheritance: screen 04 renders a TIME pill, so the shell clocks the run.
  // There is deliberately NO run limit. The run ends on the round count, which
  // the board owns; a limit would give the shell a second way to end it and the
  // two could disagree.
  buildBoard: (context, run) => StroopBoard(run: run),
  buildArtwork: (context) => const StroopArtwork(),
  // A SUBSCRIPTION, not a read. The shell is handed a listener so a board
  // update reaches it without the run rebuilding — a read here re-ran the
  // run's build and reset the phase, which is the defect E07 fixed.
  bindBoard: (ref, run, onChanged) {
    ref.listen(stroopBoardSnapshotProvider(run), (previous, next) {
      onChanged(next);
    });

    return ref.read(stroopBoardSnapshotProvider(run));
  },
);
