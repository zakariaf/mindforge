/// A registry of fake games, for the shell tests.
///
/// **The shell must be testable without the shipped registry, and until E09 it
/// was not.** E08's screens were driven through `lib/games/placeholder/` — real
/// definitions, real ARB keys — so eighteen test files named a shipped game and
/// every one of them would have had to change when that game was deleted. That
/// is a seam defect and E09 T09.0 predicted it: a shell test asserts what the
/// SHELL does with a definition, and which definitions ship is not its subject.
///
/// The one thing that made a fake impossible was `gameStringsProvider`, which
/// resolves an id to ARB getters and throws for an unknown one — correctly, so
/// an unregistered game cannot render as a blank card. [fixtureGameStrings] is
/// the test-side resolver that pairs with a fake registry, and `pumpShellApp`
/// installs it whenever a test supplies its own games.
library;

import 'package:flutter/widgets.dart';
import 'package:mindforge/core/board_snapshot.dart';
import 'package:mindforge/core/difficulty.dart';
import 'package:mindforge/core/game_id.dart';
import 'package:mindforge/core/result_stat.dart';
import 'package:mindforge/core/score_format.dart';
import 'package:mindforge/games/game_definition.dart';
import 'package:mindforge/l10n/game_strings.dart';
import 'package:mindforge/theme/game_accent.dart';

/// A board that plays nothing and reports a constant.
const _idleSnapshot = BoardSnapshot(
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

/// Builds a fake definition.
///
/// Every argument has a default, so a test names only the property it is about
/// — which is what keeps the reason a test exists visible in its own setup.
GameDefinition fixtureDefinition({
  required String id,
  GameAccent accent = GameAccent.stroop,
  ScoreFormat scoreFormat = ScoreFormat.points,
  List<Difficulty>? difficulties,
  bool isLocked = false,
  BoardBackground boardBackground = BoardBackground.surfaceSunk,
  RunLimitLookup? runLimitFor,
  Widget Function(BuildContext context, dynamic run)? buildBoard,
}) => GameDefinition(
  id: GameId(id),
  accent: accent,
  colourRole: BoardColourRole.decorative,
  scoreFormat: scoreFormat,
  scoreSource: ScoreSource.board,
  // The keys are never resolved: fixtureGameStrings answers by id. They are
  // real keys anyway, so a definition built here still satisfies the
  // registry-localization test's shape.
  strings: const GameStringIds(
    titleKey: 'appTitle',
    taglineKey: 'appTitle',
    kickerKey: 'appTitle',
  ),
  difficulties: difficulties ?? Difficulty.values,
  boardBackground: boardBackground,
  isLocked: isLocked,
  runLimitFor: runLimitFor,
  buildBoard: buildBoard == null
      ? (context, run) => const SizedBox.shrink()
      : (context, run) => buildBoard(context, run),
  buildArtwork: (context) => const SizedBox.shrink(),
  buildHeroArt: (context) => const SizedBox.shrink(),
  bindBoard: (ref, run, onChanged) => _idleSnapshot,
);

/// The unlocked, points-scored fixture.
final GameDefinition fixtureAlpha = fixtureDefinition(id: 'fixture_alpha');

/// The unlocked, time-scored fixture, in the other accent.
final GameDefinition fixtureBeta = fixtureDefinition(
  id: 'fixture_beta',
  accent: GameAccent.schulte,
  scoreFormat: ScoreFormat.duration,
);

/// The locked fixture, so the shell's "coming soon" slot has a subject.
final GameDefinition fixtureLocked = fixtureDefinition(
  id: 'fixture_locked',
  isLocked: true,
);

/// The three fixtures, in display order: two playable and one locked.
///
/// The same SHAPE the shipped registry has — which is what a shell test is
/// actually about — with none of its content.
List<GameDefinition> fixtureRegistry() => <GameDefinition>[
  fixtureAlpha,
  fixtureBeta,
  fixtureLocked,
];

/// Resolves a fixture definition's strings, by id.
///
/// Deterministic and untranslated, on purpose. Whether a game's NAME is
/// translated is `game_strings.dart`'s subject and the ARB parity test's; a
/// shell test that asserted a translated fake title would be asserting its own
/// fixture.
GameStrings fixtureGameStrings(GameDefinition definition) => GameStrings(
  title: 'Title ${definition.id.value}',
  tagline: 'Tagline ${definition.id.value}',
  kicker: 'KICKER ${definition.id.value}',
);
