# The shell/game seam

Two types cross the boundary and nothing else: `GameDefinition` goes **down** (what the shell needs to
render eight screens for a game it has never heard of); `BoardSnapshot` comes **up** (what the shell
needs to render the HUD, the track and the end of the run).

```text
lib/
  features/                     # THE SHELL — authored once, never edited to add a game
    home/ game_detail/ play/ results/ stats/ settings/
    shell/widgets/              # RayHeader, HalftoneDots, PlayBand, GameHeroPanel,
                                #   DailyMixCard, StatBox, ScoreSlab, BestCard, Wordmark
  games/
    game_registry.dart          # the ONE file allowed to import every game
    stroop_rush/                # directory name matches stroopRushDefinition
      stroop_rush_definition.dart
      application/stroop_board_notifier.dart
      domain/stroop_run_state.dart
      ui/stroop_board.dart      # `ui/`, not `presentation/` — one layer name
    schulte_grid/ …             # same four, matching schulteGridDefinition
```

`lib/features/**` may import `games/game_registry.dart`. It may **never** import
`games/<a specific game>/…` — `scripts/check_shell_boundaries.sh` fails on it.

## Down: `GameDefinition`

```dart
// lib/games/game_definition.dart — owned by the shell, implemented per game.
typedef GameBoardBuilder = Widget Function(BuildContext context, RunConfig config);

/// Everything the eight shell screens need to render a game they do not know.
@immutable
final class GameDefinition {
  const GameDefinition({
    required this.id,
    required this.accent,
    required this.scoreFormat,
    required this.difficulties,
    required this.boardBackground,
    required this.buildBoard,
    required this.buildArtwork,
    required this.snapshotOf,
    this.isLocked = false,
  });

  final GameId id;                    // 'stroop_rush' — also the route segment and the DB key
  final GameAccent accent;            // sunburst-game-surfaces owns the enum and its token pair
  final ScoreFormat scoreFormat;      // points -> "1,480" · duration -> "18.6s"
  final List<Difficulty> difficulties;// >= 1, in display order; Difficulty carries its own lock flag
  final BoardBackground boardBackground; // surfaceSunk (Stroop) or gameAccent (Schulte)

  /// Renders the dashed "Coming soon" slot on Home and hides the game from Stats.
  /// A placeholder entry still declares an accent and an artwork — the locked card
  /// shows neither, but the day it unlocks nothing else changes.
  final bool isLocked;

  /// The board rectangle. Called ONLY from PlayScaffoldScreen.
  final GameBoardBuilder buildBoard;

  /// The 64pt tile inside the Home card's cream art frame. Decoration only.
  final WidgetBuilder buildArtwork;

  /// The live projection RunNotifier watches. A ProviderListenable, so the shell
  /// never learns which notifier shape the game chose.
  final ProviderListenable<BoardSnapshot> Function(RunConfig config) snapshotOf;

  // Localized strings are NOT fields: the shell resolves them from AppLocalizations
  // by `id` (l10n keys `game_<id>_title`, `_tagline`, `_kicker`), so a game ships no
  // English literals and `i18n-rtl-l10n`'s ARB parity gate covers it.
}
```

```dart
// lib/games/stroop_rush/stroop_rush_definition.dart
final stroopRushDefinition = GameDefinition(
  id: const GameId('stroop_rush'),
  accent: GameAccent.stroopCoral,
  scoreFormat: ScoreFormat.points,
  difficulties: Difficulty.values,
  boardBackground: BoardBackground.surfaceSunk,
  buildBoard: (context, config) => StroopBoard(config: config),
  buildArtwork: (context) => const StroopArtwork(),
  snapshotOf: (config) => stroopBoardNotifierProvider(config),
);
```

The registry is a plain list; the composition root overrides it (`state-management-riverpod` owns the
seam). Order is display order on Home and Stats.

```dart
// lib/games/game_registry.dart — the ONE file that names every game.
final gameRegistryProvider = Provider<List<GameDefinition>>(
  (ref) => [stroopRushDefinition, schulteGridDefinition],
);

final gameDefinitionProvider = Provider.family<GameDefinition, GameId>(
  (ref, id) => ref.watch(gameRegistryProvider).firstWhere((g) => g.id == id),
);
```

## Up: `BoardSnapshot`

```dart
// lib/features/play/domain/board_snapshot.dart — the game's only upward channel.
@immutable
final class BoardSnapshot {
  const BoardSnapshot({required this.hud, this.progress, this.outcome});

  /// Exactly three slots. The shell renders them as HudPills, left to right.
  final GameHud hud;

  /// 0..1 for the progress track, or null to hide the track for this game.
  final double? progress;

  /// Non-null EXACTLY when the run is finished. Setting it is the game's whole
  /// vocabulary for "I am done" — it never navigates and never sets a phase.
  final RunOutcome? outcome;
}

@immutable
final class GameHud {
  const GameHud(this.slotA, this.slotB, this.slotC);
  final HudSlot slotA, slotB, slotC;
}

@immutable
final class HudSlot {
  const HudSlot({required this.label, required this.value, this.tone = HudTone.neutral});
  final String label;   // already localized, already uppercase-cased by the pill
  final String value;   // already formatted — no NumberFormat in the widget layer
  final HudTone tone;   // neutral | highlight | alarm
}

/// system.html §10 "HUD stat pill": neutral = `.hstat` surfaceRaised + e1 with a `textSecondary`
/// label · highlight = `.hstat.hot` accent (sunshine) with both lines `textPrimary` · alarm =
/// "Alarm (under 5s)" with `colors.danger` and both lines `colors.surfaceRaised`.
///
/// The alarm is DERIVED and deliberately not the gallery's `.hstat.bad` coral: coral is
/// `colors.gameStroop`, which is also the play-band fill the HUD sits on, so the pill would vanish
/// on the Stroop board. Paper on `danger` measures 5.07:1 while the pill's default
/// `textPrimary`/`textSecondary` measure 3.03:1 and 1.53:1 on it — which is why BOTH lines invert
/// together. `sunburst-motion-and-haptics` owns the derivation (`Moment.timerAlarm`) and
/// `sunburst-components` renders the pill; a game never sets this tone.
enum HudTone { neutral, highlight, alarm }
```

`RunNotifier` composes `hud.slotA` with its own clock: the time pill is the shell's value, not the
game's, and the game leaves `slotA.value` empty for a timed run (`DERIVED` — app.html shows a Time pill
on both play screens; making the shell author it is this skill's call, so pause cannot desynchronise it).

## What the shell hands the board

```dart
// lib/features/play/domain/run_config.dart — the only thing a board is given.
@immutable
final class RunConfig {
  const RunConfig({required this.gameId, required this.difficulty, required this.seed});

  final GameId gameId;
  final Difficulty difficulty;   // chill | classic | blitz
  final int seed;                // from seededRandomProvider — see seeded-determinism-and-golden-vectors

  // Value equality, so it is a safe Riverpod family key. copyWith/==/hashCode elided.
}
```

The board reads `config` and its own notifier. It does **not** read `runNotifierProvider`: the shell's
phase is not board state, and a board that watches it will try to render a countdown.

## Forbidden in `lib/games/**`

Rows 1–5 are grep rules in `scripts/check_shell_boundaries.sh`, row 6 in `sunburst-tokens`'
`check_raw_values.sh`; rows 7–8 are review rules no grep can see. None is a style preference.

| Forbidden | Why | Instead |
|---|---|---|
| `import 'package:go_router/…'`, `context.go`, `context.push`, `Navigator.*` | a game that navigates owns a back stack it cannot test | set `BoardSnapshot.outcome`; the shell routes |
| `Scaffold(`, `AppBar(`, `PopScope(` | the shell already built the screen; a nested `Scaffold` breaks `SafeArea` and a nested `PopScope` wins on Android and leaks the run | return the board's content |
| `HudPill`, `PopProgressBar`, `PlayBand`, `PauseSheet`, `CountdownScreen`, `PopBottomNav` | two HUDs drift by a frame under fast taps | fill `GameHud`; set `progress` |
| `Timer.periodic`, `Ticker`/`createTicker`, `Stopwatch` for run timing | pause must stop exactly one clock | read `elapsed` from the snapshot the shell folds in |
| `SafeArea(`, and a 20pt gutter `Padding` (review-only) | `PlayScaffoldScreen` applied both | fill the constraints you are given |
| A `Color(0x…)` or `Colors.*` (caught by `check_raw_values.sh`) | owned by `sunburst-game-surfaces` | `SunburstColors.of(context)` |
| Writing a run to the repository | the shell owns the single write path, so persist-then-transition stays one step | return a `RunOutcome` |
| Reading `runNotifierProvider` | the phase is not board state | read `config` and your own notifier |

## Adding a game: the whole diff

1. `lib/games/<id>/` — definition, board notifier, board widget, artwork.
2. One `GameAccent` case + its `*Deep` token partner (`sunburst-game-surfaces`).
3. Three ARB keys: `game_<id>_title`, `_tagline`, `_kicker`.
4. One line appended to `gameRegistryProvider`.

Zero lines in `lib/features/**`. If a change to the shell was required, the seam is wrong — widen
`GameDefinition` with a field, do not special-case the screen.
