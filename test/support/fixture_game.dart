import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/theme/game_accent.dart';

/// A minimal [GameDefinition] for tests.
///
/// **It lives under `test/`, and that is the whole point of the epic.** The
/// proof that the engine seam works is a game the shell has never heard of,
/// driven through a complete run, adding zero lines to `lib/features/**`.
GameDefinition fixtureGame({
  String id = 'fixture_game',
  BoardColourRole colourRole = BoardColourRole.decorative,
  BoardBackground boardBackground = BoardBackground.surfaceSunk,
  List<Difficulty>? difficulties,
  bool isTimed = true,
  ScoreSource scoreSource = ScoreSource.board,
  bool isLocked = false,
  RunLimitLookup? runLimitFor,
  GameStringIds? strings,
}) => GameDefinition(
  id: GameId(id),
  accent: GameAccent.stroop,
  colourRole: colourRole,
  scoreFormat: ScoreFormat.points,
  strings:
      strings ??
      const GameStringIds(
        titleKey: 'gameStroopRushName',
        taglineKey: 'gameStroopRushTagline',
        kickerKey: 'gameTagsReactionFocus',
      ),
  difficulties: difficulties ?? Difficulty.values,
  boardBackground: boardBackground,
  scoreSource: scoreSource,
  isTimed: isTimed,
  isLocked: isLocked,
  runLimitFor: runLimitFor,
  buildBoard: (context, run) => const SizedBox.shrink(),
  buildArtwork: (context) => const SizedBox.shrink(),
  buildHeroArt: (context) => const SizedBox.shrink(),
  bindBoard: (ref, run, onChanged) {
    // A REAL SUBSCRIPTION, the way a game wires one. The first fixture returned
    // a constant, which meant it never invalidated anything — and the seam
    // test passed against a shape that reset the run on the first board update.
    ref.listen(fixtureBoardProvider, (_, next) => onChanged(next));

    return ref.read(fixtureBoardProvider);
  },
);

/// The fixture board a test publishes through.
class FixtureBoard extends Notifier<BoardSnapshot> {
  @override
  BoardSnapshot build() => const BoardSnapshot(
    hud: GameHud(
      leading: HudSlot(
        labelKey: 'hudScore',
        canonicalValue: 0,
        format: StatFormat.points,
      ),
      middle: HudSlot(
        labelKey: 'hudTime',
        canonicalValue: 0,
        format: StatFormat.duration,
      ),
    ),
  );

  /// Publishes [snapshot] and returns it, the way a board reports a move.
  ///
  /// Returns rather than being a setter so a test can publish and assert in one
  /// expression, and so the lints stop arguing about which shape a one-line
  /// state change should take.
  BoardSnapshot publish(BoardSnapshot snapshot) => state = snapshot;
}

/// The fixture game's board.
final NotifierProvider<FixtureBoard, BoardSnapshot> fixtureBoardProvider =
    NotifierProvider<FixtureBoard, BoardSnapshot>(FixtureBoard.new);
