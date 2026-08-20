import 'package:flutter/widgets.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/features/play/domain/board_snapshot.dart';
import 'package:mindforge/features/play/domain/result_stat.dart';
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
  isTimed: isTimed,
  isLocked: isLocked,
  runLimitFor: runLimitFor,
  buildBoard: (context, run) => const SizedBox.shrink(),
  buildArtwork: (context) => const SizedBox.shrink(),
  snapshotOf: (ref, run) => const BoardSnapshot(
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
  ),
);
