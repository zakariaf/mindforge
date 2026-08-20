import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/schulte_grid/application/schulte_snapshot.dart';
import 'package:mindforge/games/schulte_grid/domain/schulte_rules.dart';
import 'package:mindforge/games/schulte_grid/ui/board/schulte_artwork.dart';
import 'package:mindforge/games/schulte_grid/ui/schulte_board.dart';
import 'package:mindforge/theme/game_accent.dart';

/// Schulte Grid, as the engine sees it.
///
/// **The second game, and therefore the proof.** Stroop Rush was built against
/// a shell designed alongside it; this one is the opposite game on every axis
/// the seam touches — a decorative accent instead of a mechanic one, an accent
/// background instead of a sunken field, a duration score instead of points,
/// two difficulties instead of three, and a run the BOARD ends instead of one
/// the clock does. Every one of those is a place a hidden `switch (gameId)`
/// would have surfaced.
final GameDefinition schulteGridDefinition = GameDefinition(
  id: GameId('schulte_grid'),
  accent: GameAccent.schulte,
  // DECORATIVE: hue carries no meaning on this board. The tiles are told apart
  // by their numbers, so turquoise is free to be chrome — which is what lets
  // the board sit ON the accent instead of in a sunken field.
  colourRole: BoardColourRole.decorative,
  // THE FIRST DURATION SCORE IN THE APP. Faster is better, so the run's own
  // elapsed time is the score and the shell owns it.
  scoreFormat: ScoreFormat.duration,
  scoreSource: ScoreSource.runClock,
  strings: const GameStringIds(
    titleKey: 'gameSchulteGridName',
    taglineKey: 'gameSchulteGridTagline',
    kickerKey: 'gameSchulteGridKicker',
  ),
  // TWO OF THREE. Blitz would be 6x6; schulte_rules.dart carries the
  // arithmetic that withholds it, as a test rather than a comment.
  difficulties: schulteDifficulties,
  boardBackground: BoardBackground.gameAccent,
  buildBoard: (context, run) => SchulteBoard(run: run),
  buildArtwork: (context) => const SchulteArtwork(),
  buildHeroArt: (context) => const SchulteArtwork(),
  // A SUBSCRIPTION, not a read — the same shape Stroop uses, for the same
  // reason: a read here re-runs the run's build and resets the phase.
  bindBoard: (ref, run, onChanged) {
    ref.listen(schulteSnapshotProvider(run), (previous, next) {
      onChanged(next);
    });

    return ref.read(schulteSnapshotProvider(run));
  },
);
