/// The three placeholder definitions the shell renders before a real game
/// exists.
///
/// **E09 deletes this file in its first commit**, along with
/// `lib/games/placeholder/` and the nine ARB keys they name. They are here so
/// the eight screens are renderable, testable and screenshot-comparable against
/// both reference sets in four locales before Stroop Rush is written — which is
/// what stops E09 from being the epic that discovers the shell needs a field
/// nobody added.
///
/// They obey every rule in the shell/game boundary rather than dodging it: no
/// chrome, no navigation, no clock, no raw colour, ARB keys instead of strings.
/// A placeholder that cheated would prove nothing about the seam.
library;

import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/games/placeholder/ui/placeholder_board.dart';
import 'package:mindforge/theme/game_accent.dart';
import 'package:mindforge/ui/glyphs/sunburst_glyph.dart';

/// A never-ending board, reported once and never updated.
///
/// A placeholder has no state to publish, so `bindBoard` subscribes to nothing
/// and returns a constant. A real game listens to its own provider — see
/// `GameDefinition.bindBoard`, which documents why the difference matters.
const _idleSnapshot = BoardSnapshot(
  hud: GameHud(
    leading: HudSlot(
      labelKey: 'hudScoreLabel',
      canonicalValue: 0,
      format: StatFormat.points,
    ),
    middle: HudSlot(
      labelKey: 'hudTimeLabel',
      canonicalValue: 0,
      format: StatFormat.duration,
    ),
  ),
);

/// The coral placeholder: unlocked, points-scored, all three difficulties.
final GameDefinition placeholderCoralDefinition = GameDefinition(
  id: GameId('placeholder_coral'),
  accent: GameAccent.stroop,
  colourRole: BoardColourRole.decorative,
  scoreFormat: ScoreFormat.points,
  scoreSource: ScoreSource.board,
  strings: const GameStringIds(
    titleKey: 'gamePlaceholderCoralName',
    taglineKey: 'gamePlaceholderCoralTagline',
    kickerKey: 'gamePlaceholderCoralKicker',
  ),
  difficulties: Difficulty.values,
  boardBackground: BoardBackground.surfaceSunk,
  // Milliseconds, per RunLimitLookup: the engine measures every stored or
  // compared span as an integer, and a round length is a game rule rather than
  // a design token.
  runLimitFor: (difficulty) => switch (difficulty) {
    Difficulty.chill => 90000,
    Difficulty.classic => 60000,
    Difficulty.blitz => 30000,
  },
  buildBoard: (context, run) =>
      PlaceholderBoard(run: run, accent: GameAccent.stroop),
  buildArtwork: (context) =>
      const SunburstGlyphIcon(SunburstGlyph.go, size: 28),
  bindBoard: (ref, run, onChanged) => _idleSnapshot,
);

/// The turquoise placeholder: unlocked, untimed, scored by the run clock.
///
/// The pairing Schulte Grid will take — untimed, `ScoreFormat.duration`,
/// `ScoreSource.runClock` — so the shell is exercised against both score
/// sources before a real game uses either.
final GameDefinition placeholderTurquoiseDefinition = GameDefinition(
  id: GameId('placeholder_turquoise'),
  accent: GameAccent.schulte,
  colourRole: BoardColourRole.decorative,
  scoreFormat: ScoreFormat.duration,
  scoreSource: ScoreSource.runClock,
  strings: const GameStringIds(
    titleKey: 'gamePlaceholderTurquoiseName',
    taglineKey: 'gamePlaceholderTurquoiseTagline',
    kickerKey: 'gamePlaceholderTurquoiseKicker',
  ),
  difficulties: Difficulty.values,
  boardBackground: BoardBackground.gameAccent,
  isTimed: false,
  buildBoard: (context, run) =>
      PlaceholderBoard(run: run, accent: GameAccent.schulte),
  buildArtwork: (context) =>
      const SunburstGlyphIcon(SunburstGlyph.navPlay, size: 28),
  bindBoard: (ref, run, onChanged) => _idleSnapshot,
);

/// The locked slot.
///
/// It still declares an accent, artwork and a difficulty list: unlocking a game
/// is a flag flip, not a new definition. The home hub draws it as a "coming
/// soon" card rather than hiding it, which is why the registry returns its list
/// unfiltered.
final GameDefinition placeholderLockedDefinition = GameDefinition(
  id: GameId('placeholder_locked'),
  accent: GameAccent.stroop,
  colourRole: BoardColourRole.decorative,
  scoreFormat: ScoreFormat.points,
  scoreSource: ScoreSource.board,
  strings: const GameStringIds(
    titleKey: 'gamePlaceholderLockedName',
    taglineKey: 'gamePlaceholderLockedTagline',
    kickerKey: 'gamePlaceholderLockedKicker',
  ),
  difficulties: Difficulty.values,
  boardBackground: BoardBackground.surfaceSunk,
  isLocked: true,
  buildBoard: (context, run) =>
      PlaceholderBoard(run: run, accent: GameAccent.stroop),
  buildArtwork: (context) =>
      const SunburstGlyphIcon(SunburstGlyph.lock, size: 28),
  bindBoard: (ref, run, onChanged) => _idleSnapshot,
);

/// The three, in display order.
List<GameDefinition> placeholderDefinitions() => <GameDefinition>[
  placeholderCoralDefinition,
  placeholderTurquoiseDefinition,
  placeholderLockedDefinition,
];
