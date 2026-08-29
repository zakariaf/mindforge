import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/false_light/application/light_board_notifier.dart';
import 'package:mindforge/games/false_light/ui/board/light_artwork.dart';
import 'package:mindforge/games/false_light/ui/board/light_hero_art.dart';
import 'package:mindforge/games/false_light/ui/false_light_board.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/theme/game_accent.dart';

/// False Light, as the engine sees it.
///
/// **The fourth game, and the one with nothing to localize on its board.** It
/// draws no text and no numeral, and its answer survives every hue being
/// removed — which is the axis no earlier game touched. (The grid it lays that
/// content out in still mirrors, like every grid in the app; it is the content
/// that does not move, not the geometry.) Stroop Rush's answer IS a hue; Schulte Grid's and
/// Digit Bridge's are numerals. This one's is depth.
///
/// It still declares three ARB keys and three tile-state strings, and the
/// asymmetry is the point: the CHROME is localized, the BOARD has nothing to
/// localize, and the tile strings exist only for a screen reader, because depth
/// is the one channel a reader cannot be shown.
final GameDefinition falseLightDefinition = GameDefinition(
  id: GameId('false_light'),
  accent: GameAccent.falseLight,
  // DECORATIVE, and more strongly than any other board: hue carries no meaning
  // here at all. The tiles are told apart by depth, so leaf is free to be
  // chrome — which is what lets the board sit ON the accent.
  colourRole: BoardColourRole.decorative,
  scoreFormat: ScoreFormat.points,
  scoreSource: ScoreSource.board,
  // TIMED, WITH NO LIMIT — the Stroop shape. The clock counts up and the run
  // ends when the fields do, so the board publishes the outcome.
  //
  // An earlier design flipped tiles on an interval and would have needed a run
  // limit and elapsed time inside `lib/games/**`. Neither exists: `RunConfig`
  // carries no clock and `RunNotifier._expiredOutcome()` is hardcoded to a trio
  // of zeros. Dealing fields needs neither.
  strings: const GameStringIds(
    titleKey: 'gameFalseLightName',
    taglineKey: 'gameFalseLightTagline',
    kickerKey: 'gameFalseLightKicker',
  ),
  // ALL THREE. The grid grows and the pressed share falls, so targets get
  // scarcer rather than tiles getting smaller — which is what keeps the 48pt
  // tap floor reachable at blitz on a 320pt phone.
  difficulties: Difficulty.values,
  boardBackground: BoardBackground.gameAccent,
  buildBoard: (context, run) => FalseLightBoard(run: run),
  buildArtwork: (context) => const LightArtwork(),
  buildHeroArt: (context) => const LightHeroArt(),
  // A SUBSCRIPTION, not a read — the shape every shipped game uses, for the
  // reason `bindBoard`'s own doc records: a `ref.watch` here re-runs the run's
  // build and resets the phase to idle on the first tap.
  bindBoard: (ref, run, onChanged) {
    ref.listen(lightBoardSnapshotProvider(run), (previous, next) {
      onChanged(next);
    });

    return ref.read(lightBoardSnapshotProvider(run));
  },
);
