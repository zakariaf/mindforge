import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/digit_bridge/application/bridge_board_notifier.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_artwork.dart';
import 'package:mindforge/games/digit_bridge/ui/board/bridge_hero_art.dart';
import 'package:mindforge/games/digit_bridge/ui/digit_bridge_board.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/theme/game_accent.dart';

/// Digit Bridge, as the engine sees it.
///
/// **The third game, and the first added after the engine shipped.** Stroop
/// Rush was built against a shell designed alongside it and Schulte Grid was
/// the opposite game on every axis the seam touched; this one was written
/// against the registry contract alone, months later, by a reader of
/// `GameDefinition` rather than of the shell.
///
/// The axis it stresses that neither of the others did: **its stimulus script
/// is chosen by the round rather than by the locale.** Every other numeral in
/// the app renders in the reader's own system. Half of this board deliberately
/// does not, because a cross-script matching game whose two sides both took the
/// locale's answer would render them identically and have no question on it.
final GameDefinition digitBridgeDefinition = GameDefinition(
  id: GameId('digit_bridge'),
  accent: GameAccent.digitBridge,
  // DECORATIVE: hue carries no meaning on this board. The chips are told apart
  // by their numerals, so lilac is free to be chrome — which is what lets the
  // board sit ON the accent instead of in a sunken field.
  colourRole: BoardColourRole.decorative,
  scoreFormat: ScoreFormat.points,
  scoreSource: ScoreSource.board,
  // TIMED, WITH NO LIMIT — the Stroop shape. The clock counts up and the run
  // ends when the rounds do, so the board publishes the outcome.
  //
  // Stated rather than left to a `runLimitFor`, and the reason is measured:
  // `RunNotifier._expiredOutcome()` is hardcoded to 0% / 0 / 0ms and no shipped
  // game has ever declared a limit, so the first game to declare one would ship
  // a results trio of zeros. Giving the board the end condition keeps the
  // outcome real without editing a shell file.
  strings: const GameStringIds(
    titleKey: 'gameDigitBridgeName',
    taglineKey: 'gameDigitBridgeTagline',
    kickerKey: 'gameDigitBridgeKicker',
  ),
  // ALL THREE. Difficulty is carried by the length of the numeral, which scales
  // smoothly; there is no arithmetic that withholds one the way Schulte's 6x6
  // is withheld.
  difficulties: Difficulty.values,
  boardBackground: BoardBackground.gameAccent,
  buildBoard: (context, run) => DigitBridgeBoard(run: run),
  buildArtwork: (context) => const BridgeArtwork(),
  buildHeroArt: (context) => const BridgeHeroArt(),
  // A SUBSCRIPTION, not a read — the shape both shipped games use, for the
  // reason `bindBoard`'s own doc records: a `ref.watch` here re-runs the run's
  // build and resets the phase to idle on the first tap.
  bindBoard: (ref, run, onChanged) {
    ref.listen(bridgeBoardSnapshotProvider(run), (previous, next) {
      onChanged(next);
    });

    return ref.read(bridgeBoardSnapshotProvider(run));
  },
);
