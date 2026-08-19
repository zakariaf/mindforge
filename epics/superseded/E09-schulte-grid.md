> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E10-schulte-grid.md`](../E10-schulte-grid.md) — **E10 · Schulte Grid**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E09 · Schulte Grid

| | |
|---|---|
| **Branch** | `epic/09-schulte-grid` |
| **Depends on** | E01, E02, E03, E04, E05, E06, E07, E08 |
| **Unblocks** | E10 |
| **Status** | Not started |

## The epic

Ship the second game — Schulte Grid — entirely under `lib/games/schulte_grid/`, plus one appended
line in `lib/games/game_registry.dart` and five ARB keys. The game supplies a seeded scramble, a
five-state tile machine, a board widget, a `GameDefinition` and a `BoardSnapshot`. It inherits home,
game detail, countdown, play scaffold, pause, results, stats and settings without a line being added
to any of them.

The deliverable is therefore two things at once: a playable game, and the **proof that the engine
seam holds**. Shipping this game must add **zero lines to `lib/features/**`**. That is a task with a
test (T09.8), not an aspiration. If it cannot be met, the seam is wrong: the fix is a game-agnostic
widening of `GameDefinition`/`BoardSnapshot` owned by E06, never a special case here.

## Why we need it

E08 built Stroop Rush against a shell that was designed alongside it, so nothing in E08 could
disprove the engine claim — the first game always fits. The second game is where an engine either
proves itself or forks. Schulte is deliberately the *opposite* game on every axis the seam touches:

| Axis | Stroop Rush | Schulte Grid |
|---|---|---|
| `GameColourRole` | `mechanic` — hue is the answer | `decorative` — hue is free |
| `boardBackground` | `BoardBackground.surfaceSunk` | `BoardBackground.gameAccent` (turquoise) |
| Wrong feedback | depth + ink strike bar, no `danger` | `danger` fill + paper glyph |
| `scoreFormat` | `ScoreFormat.points` → "1,480" | `ScoreFormat.duration` → "18.6s" |
| Run end | the clock runs out | the board reports `outcome` |
| Difficulties | three | two |
| Board | one stimulus + four keys | 16 or 25 computed square cells |

Every one of those is a place a hidden `switch (gameId)` would surface. Without this epic the engine
claim in `CLAUDE.md` is untested marketing, `ScoreFormat.duration` has never rendered, the
`decorative` half of the accent contract has never been built, `BoardSnapshot.outcome` has never
ended a run, and E10 has only one game to sweep.

## Current state

Verified by `ls` and `git log` on `main` at 4 commits (`cb1c3e2`):

- **The Flutter app is not scaffolded.** No `pubspec.yaml`, no `lib/`, no `test/`, no `tool/`, no
  `.github/`. Everything this epic touches is created by E01–E08 first.
- `.claude/skills/` — 45 skills. Two carry worked Schulte code that this epic must reconcile:
  - `.claude/skills/sunburst-game-surfaces/examples/schulte_board.dart` — a full board, tile,
    `NextRingPainter` and `TileGlyph`. **It is wrong on two points**: it wraps the board in a
    `ColoredBox(GameAccent.schulteTurquoise.base(colors))` and in a `SunburstShape.gutter` `Padding`.
    `sunburst-shell-screens`' `_BoardPane` already paints the background from
    `GameDefinition.boardBackground` and already applies gutter 20 / top 20 / bottom 26, and
    `sunburst-game-surfaces` rule 8 says the slot handed to the board has the gutter removed. The
    shell wins; see Risks.
  - `.claude/skills/sunburst-motion-and-haptics/examples/feedback_moments.dart` — `SchulteTile`,
    `ShakeOnWrong`, and the `tileFound`/`tileNextCue` split (two visuals, one haptic).
- `.claude/skills/sunburst-game-surfaces/references/board-states-and-layout.md` — the five-row tile
  state matrix and the cell-sizing table. The five states are implemented by **E03's `PopGridTile`**
  (`PopGridTileState { idle, next, found, wrong, disabled }`, shipped in T03.8 with its own goldens and
  greyscale proof); this epic maps onto it rather than re-implementing the matrix.
- `.claude/skills/sunburst-shell-screens/references/shell-game-boundary.md` — `GameDefinition`,
  `BoardSnapshot`, `GameHud`, `HudSlot`, `RunConfig`, and the "Adding a game: the whole diff" list
  that ends "Zero lines in `lib/features/**`".
- `design/sunburst-pop/screens/05-schulte-grid.png` — the target. Board is 5×5 with 12px gaps, six
  found tiles, `next` = 7, HUD row `Time / Found / Next` with `Next` on the highlight tone, progress
  track at 24% (= 6/25).
- `design/sunburst-pop/app.html` §5 — `.playfill--schulte{background:var(--turquoise);padding-top:20px}`,
  `.grid5{gap:12px}`, `.tile`, `.tile.found`, `.tile.next`. `system.html` §10 is authoritative for
  the hexes behind them.
- No epic before this one has been executed; `epics/` is created by this file.

## What we will achieve

A reader can tell this epic is done by doing all of the following:

1. Run the app on a 390×844 device. Home shows two unlocked game cards; the second is **Schulte
   Grid** on turquoise with a mini-grid artwork tile and a BEST pill formatted as a duration.
2. Tap it. Game detail shows a turquoise hero and a difficulty list with **two** entries
   (Chill, Classic) — not three, and not a broken three-up control.
3. Play Classic. The 3-2-1 runs, then a 5×5 turquoise board appears with the shell's HUD above it:
   `Time` (shell clock), `Found 0 / 25`, `Next 1` on the sunshine highlight pill, and an empty track.
4. Tap 1. The tile sinks flat into `gameSchulteDeep` at (2,2) with no shadow, tile 2 lifts to e2 with
   a cream-then-ink double ring, `Found` reads `1 / 25`, `Next` reads `2`, the track moves to 4%, and
   exactly one `selectionClick` fires.
5. Tap the wrong tile. It turns `danger` with a paper glyph and shakes twice at 240ms. The run does
   **not** end, `Found` does **not** move, and the latch clears on the next tap.
6. Tap 25. Results appears showing the elapsed time formatted as `18.6s`, and Stats records it under
   Schulte Grid.
7. `bash tool/check_no_shell_edits.sh` prints `OK: lib/features/** untouched` — the whole diff is
   `lib/games/schulte_grid/**`, one line of `lib/games/game_registry.dart`, `lib/l10n/app_*.arb`,
   `test/**` and `tool/**`.
8. `flutter test` is green, including golden vectors for the scramble, a state-channel test proving
   every tile-state pair differs in ≥3 non-hue channels, a greyscale golden, and cell-geometry tests
   at 320/360/390/430.
9. Every gate under `Gates that must pass` exits 0.
10. `05-schulte-grid.png` and `04-stroop-rush.png` have both been compared and signed off in the PR
    body with the visual checklist.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `sunburst-game-surfaces` | Owns everything this epic builds below the play band's ink border: the `GameAccent.schulteTurquoise` claim, `GameColourRole.decorative`, the five-row tile state matrix, the `cell(12) >= kPopMinTarget ? 12 : 8` gap derivation, and `scripts/check_game_palette.sh`. |
| `sunburst-shell-screens` | Owns the seam: `GameDefinition`, `BoardSnapshot`, `GameHud`/`HudSlot`/`HudTone`, `RunConfig`, `_BoardPane` (which owns the board's background and insets — the game must not re-apply them), the ban list under `lib/games/**`, and the zero-lines rule this epic proves. |
| `sunburst-tokens` | Fixes the slot names the board reads — `gameSchulte`, `gameSchulteDeep`, `accent`, `surface`, `surfaceSunk`, `surfaceRaised`, `danger`, `border`, `borderDisabled`, `textPrimary`, `textDisabled` — and bans a raw `Duration(milliseconds:)` anywhere outside `lib/theme/**`, which is why the wrong-tap latch has no timer. |
| `sunburst-components` | `PopSurface` is what a tile is; `PopElevation` (`flat`/`e1`/`e2`) is the depth vocabulary; `kPopMinTarget` (48) is the floor the gap derivation is written against; the disabled shape (`surfaceSunk` + `borderDisabled` + an e1 shadow repainted in `borderDisabled`) is what `enabled: false` does. |
| `sunburst-motion-and-haptics` | Names the three moments this board spends — `Moment.tileFound` (`selectionClick`), `Moment.tileNextCue` (a declared silence), `Moment.answerWrong` (two 240ms shake cycles, `lightImpact`) — and the reduce-motion residue each keeps. |
| `seeded-determinism-and-golden-vectors` | The scramble is derived content: injected key, one entropy source, an owned SplitMix64 PRNG salted per feature, a frozen generator version, and a committed golden-vector table regenerated only by `tool/`, never by CI. |
| `testing-strategy` | Pushes the scramble and the tile machine to the pure tier (`package:test`), drives the notifier headlessly with `ProviderContainer`, requires bare-`implements` fakes for `FeedbackService`, and requires seeded fuzz against an independent oracle. |
| `widget-golden-and-a11y-testing` | `useDevice`/`pumpApp` pin `Device.all` — 320/360/390/430 at DPR 2, E02's presets and the reference-PNG geometry (the default 800×600 surface would make every cell pass); one `testWidgets` per (device, scale) tuple because overflow reports once per RenderObject; two golden lanes; pure-Dart WCAG on colour values, never `meetsGuideline` on pixels. |
| `state-management-riverpod` | `SchulteBoardNotifier` is a family `Notifier` over one immutable state with `void` intent methods; `snapshotOf` returns a `ProviderListenable`; no `DateTime.now()` anywhere — the game owns no clock. |
| `widget-composition` | Class-not-method extraction for `SchulteGrid`/`SchulteTile`/`TileGlyph`, computed cell sizing from `LayoutBuilder` constraints, the `GridView` cross-axis/main-axis spacing trap, `ValueKey(value)` identity so a re-tap cannot act on a stale capture. |
| `accessibility-as-code` | The 48px target floor the gap step defends, `Semantics` on every tile, the outright ban on `withClampedTextScaling`/`FittedBox`/`TextOverflow.ellipsis` to make a two-digit glyph fit, and the ≥3-non-hue-channel rule the state matrix satisfies. |
| `custom-canvas-and-gestures` | `NextRingPainter` is a `CustomPainter`: dumb, fed an immutable value, `shouldRepaint` as one value compare, zero allocation in `paint()`, and invisible to semantics (the ring's meaning is spoken by the sibling `Semantics` node instead). |
| `i18n-rtl-l10n` | The three `game_schulte_grid_*` keys plus `schulteFoundLabel`/`schulteNextLabel`/`schulteNextTileHint`, ARB key parity across every locale, `EdgeInsetsDirectional` only, and per-locale `NumberFormat` for the `6 / 25` HUD value so the board is not English-numeral-only. |
| `dart3-idioms-and-coding-standards` | `SchulteTileState` is a payload-free `enum` switched exhaustively with no `default:`; `SchulteBoardState`/`SchulteRules`/`SchulteTileVisual` are hand-rolled `@immutable` `final class` values; `schulteScramble` and `repairNaturalPositions` are total and never throw. |
| `async-safety` | `tapCell`/`start` return `void` so the arrow-callback `Future`-drop hole is unreachable from `onTap`, and `ref.onDispose` cancels nothing the board should not own in the first place. |
| `persistence-drift` | T09.3 only, and only the in-memory engine: `NativeDatabase.memory()` with `addTearDown(db.close)` for the end-to-end scoring test that proves a completed run lands as a row and reads back as `18.6s`. This epic writes no table and no DAO. |
| `project-structure-and-packages` | T09.8's zero-lines proof is a structure claim: `lib/games/<id>/` holds the definition plus `application/`, `domain/` and `ui/`, `test/` mirrors `lib/` 1:1, and no file under `lib/features/**` may import a specific game. Supplies `check_import_boundaries.sh`. |

## Tasks

### T09.1 — Seeded scramble, rules table and golden vectors

**Goal.** A frozen, pure, seeded scramble for an n×n Schulte board, plus the difficulty→grid-size
table, with the arithmetic that withholds Blitz recorded as a test.

**Tests first (TDD).**
`test/games/schulte_grid/domain/schulte_scramble_test.dart`
- `scramble is a permutation of 1..n^2` — seeds 0..1999 × sizes {4, 5}; `sorted(cells)` equals
  `[1..n²]`. Fails if a repair pass ever duplicates or drops a value.
- `scramble is deterministic` — the same `(seed, size)` twice returns an identical list; 2000
  distinct seeds produce ≥ 1990 distinct fingerprints.
- `no scramble leaves more than kMaxNaturalPositions numbers in natural position` — seeds 0..4999 ×
  sizes {4, 5}; `naturalPositionCount(cells) <= 2`, with the seed printed in `reason:` so a failure
  is its own repro. **This is the named threshold test.**
- `some scrambles do leave one number in place` — at least one seed in 0..4999 yields a count of 1,
  proving we did not silently ship a full derangement (which is itself a detectable pattern).
- `repairNaturalPositions is total, sound and idempotent` — exhaustive over all 120 permutations of
  length 5 and all 5040 of length 7: the result is a permutation, its count is ≤ 2, and repairing
  twice equals repairing once.
- `SplitMix64 matches its published vectors` — only if E06 did not already ship this test.

`test/games/schulte_grid/domain/schulte_scramble_vectors.dart` + `..._vectors_test.dart`
- A committed `const List<SchulteScrambleVector>` of `(seed, size, fingerprint, firstCell,
  naturalPositions, note)`. Fingerprint is `fnv1a64(cells.join(','))`. Rows: seed 0, 1, 2, 42,
  999999, `0x7FFFFFFFFFFFFFFF` at size 5; seeds 0 and 1 at size 4; seeds 0..3 at size 3
  (hand-computed). Asserted with `==`, never a tolerance.
- `production agrees with the independent oracle` — `test/games/schulte_grid/domain/schulte_oracle.dart`
  reimplements SplitMix64 in `BigInt` arithmetic and the shuffle as list-removal rather than in-place
  swaps; seeds 0..499 × sizes {3, 4, 5} must agree. The vector table's header comment states
  honestly that only the four hand-computed size-3 rows are a genuinely independent anchor; the rest
  are regression pins that prove "nothing changed", never "this is right".

`test/games/schulte_grid/domain/schulte_rules_test.dart`
- `forDifficulty is exhaustive and total` — chill→4, classic→5, blitz→6, with no `default:`.
- `schulteDifficulties is [chill, classic]` — Blitz is absent.
- `blitz is withheld because a 6x6 cell breaks the 48px floor` — at the 320pt board width of 280
  (320 − 2×20 gutter), `schulteCell(280, 6, 8) == 40.0`, `< kPopMinTarget`; and the shell's remaining
  levers (gutter 20→16) give 288, `schulteCell(288, 6, 8) == 41.33`, still short. The reason lives in
  a test so it cannot be forgotten.

**Implementation.**
`lib/games/schulte_grid/domain/schulte_scramble.dart`:
`const int kSchulteGeneratorVersion = 1;`, `const int kMaxNaturalPositions = 2;`,
`const int kScrambleAttempts = 8;`, `List<int> schulteScramble({required int seed, required int size})`,
`int naturalPositionCount(List<int> cells)`, `List<int> repairNaturalPositions(List<int> cells)`.
The seed is derived once: `fnv1a64('schulte_grid:v$kSchulteGeneratorVersion:$size') ^ seed`, mixed
through SplitMix64, then Durstenfeld Fisher–Yates descending. Draw order is part of the contract.
Rejection-resample from the same stream while the count exceeds the threshold, up to
`kScrambleAttempts`; then `repairNaturalPositions` makes the function total by swapping each
offending index with the next index whose swap introduces no new natural position.

The PRNG is **E06's, at `lib/core/seeded_generator.dart`**: `fnv1a64`, `final class SeededGenerator`
(SplitMix64) and `seedFrom`. Import those names from that path. There is no `SeededRng`, no
`lib/core/random/`, no `lib/shared/determinism/`, and no "if E06 did not ship it" fallback — E06 is a
hard dependency and E08 already consumed the same three symbols. A second generator would give the two
games different draw sequences from the same seed and quietly void both frozen-vector tables.

`lib/games/schulte_grid/domain/schulte_rules.dart`: `final class SchulteRules` with
`final int gridSize`, `int get cellCount`, `static SchulteRules forDifficulty(Difficulty)`, and
`const List<Difficulty> schulteDifficulties = [Difficulty.chill, Difficulty.classic]`.

`tool/update_schulte_vectors.dart` rewrites the vector table and prints old-vs-new metrics per
changed row. CI never runs it.

**Files.** `lib/games/schulte_grid/domain/schulte_scramble.dart`,
`lib/games/schulte_grid/domain/schulte_rules.dart`, `tool/update_schulte_vectors.dart`,
`test/games/schulte_grid/domain/schulte_scramble_test.dart`,
`test/games/schulte_grid/domain/schulte_scramble_vectors.dart`,
`test/games/schulte_grid/domain/schulte_scramble_vectors_test.dart`,
`test/games/schulte_grid/domain/schulte_oracle.dart`,
`test/games/schulte_grid/domain/schulte_rules_test.dart`.

**Skills.** `seeded-determinism-and-golden-vectors`, `testing-strategy`,
`dart3-idioms-and-coding-standards`, `sunburst-game-surfaces` (the 48px arithmetic).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/schulte_grid/domain/` green.
- [ ] `.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib`
      exits 0 — no `Random()`, no `DateTime.now()` on the generation path.
- [ ] The vector table's header comment states which rows are independently derived.
- [ ] `dart run tool/update_schulte_vectors.dart` produces a zero-line diff on a clean tree.

**Commits.**
1. `feat(schulte): seeded scramble with a bounded natural-position repair` (+ its tests)
2. `test(schulte): freeze the scramble with golden vectors and a BigInt oracle` (+ `tool/update_schulte_vectors.dart`)
3. `feat(schulte): rules table — chill 4x4, classic 5x5, blitz withheld on the 48px floor` (+ its tests)

---

### T09.2 — Tile state machine and board notifier

**Goal.** The five-state tile machine over one immutable board state, driven by a family `Notifier`
whose only intents are `start()` and `tapCell(int)`.

**Tests first (TDD).** `test/games/schulte_grid/application/schulte_board_notifier_test.dart`,
headless `ProviderContainer` with `feedbackServiceProvider` overridden by a bare-`implements`
`FakeFeedbackService` that records every `Moment`:
- `before start, every tile is disabled and tapCell is a no-op` — `stateOf(i)` is
  `SchulteTileState.disabled` for all i; a tap leaves state identical and records no moment. (This is
  what `disabled` is *for*: the board exists behind the countdown before `RunNotifier` calls
  `start()`. **DERIVED** — the state matrix marks the row derived and names no trigger.)
- `tapping the next value marks it found and advances` — `stateOf` for that index becomes `found`,
  `nextValue` increments, `foundCount` increments, and the tile holding the new `nextValue` becomes
  `next`.
- `tapping out of order registers as wrong without ending the run` — `stateOf(i) == wrong`,
  `nextValue` unchanged, `foundCount` unchanged, `isComplete` false. **This is the named test.**
- `a second wrong tap on the same tile increments wrongTapId` — so the shake replays rather than
  being swallowed by an unchanged state value.
- `the wrong latch clears on the next tap, right or wrong` — the game owns no timer: a raw
  `Duration(milliseconds:)` under `lib/games/**` fails `check_motion_tokens.sh`, and a clock is
  banned by the seam. The latch resolves on the next interaction and `ShakeOnWrong` owns the 480ms.
- `tapping an already-found tile does nothing and fires no moment`.
- `one tap fires exactly one moment` — `tileFound` only; `tileNextCue` is a declared silence.
- `stateOf precedence: a found tile is never wrong` — set `wrongIndex` to a found index and assert
  `found` wins.
- `playing 1..n^2 in order completes in exactly cellCount taps` — seeded fuzz over seeds 0..199 at
  sizes 4 and 5, driving from the scramble; `isComplete` true, `nextValue == cellCount + 1`.
- `stateOf is total` — every index of every reachable state returns a case; the `switch` carries no
  `default:`.

**Implementation.**
`lib/games/schulte_grid/domain/schulte_tile_state.dart` —
`enum SchulteTileState { idle, next, found, wrong, disabled }`.

`lib/games/schulte_grid/domain/schulte_board_state.dart` — `@immutable final class SchulteBoardState`
with `final List<int> cells`, `final int nextValue`, `final bool started`, `final int? wrongIndex`,
`final int wrongTapId`; getters `foundCount` (`nextValue - 1`), `cellCount`, `columnCount`
(`sqrt(cellCount).round()`), `isComplete`; `SchulteTileState stateOf(int index)` in precedence order
disabled → found → wrong → next → idle; value equality and `copyWith`.

`lib/games/schulte_grid/application/schulte_board_notifier.dart` —
`final class SchulteBoardNotifier extends FamilyNotifier<SchulteBoardState, RunConfig>`; `build`
scrambles from `config.seed` and `SchulteRules.forDifficulty(config.difficulty).gridSize`;
`void start()`; `void tapCell(int index)` firing
`ref.read(feedbackServiceProvider).fire(Moment.tileFound)` or `Moment.answerWrong`. Provider is a
`.autoDispose.family` — **copy the exact modifier shape E06/E08 used for the Stroop notifier**
rather than inventing one.

**Files.** `lib/games/schulte_grid/domain/schulte_tile_state.dart`,
`lib/games/schulte_grid/domain/schulte_board_state.dart`,
`lib/games/schulte_grid/application/schulte_board_notifier.dart`,
`test/games/schulte_grid/application/schulte_board_notifier_test.dart`,
`test/games/schulte_grid/domain/schulte_board_state_test.dart`,
`test/support/fake_feedback_service.dart` (E03 T03.2's file — imported, never re-created; E08 uses the
same one).

**Skills.** `state-management-riverpod`, `dart3-idioms-and-coding-standards`, `testing-strategy`,
`async-safety`, `sunburst-motion-and-haptics`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/schulte_grid/` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh` exits 0.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` exits 0 — no
      `Stopwatch(`, `Ticker(`, `Timer.periodic(` or `runNotifierProvider` under `lib/games/**`.
- [ ] Both intent methods return `void`.

**Commits.**
1. `feat(schulte): immutable board state with a five-state tile machine` (+ its tests)
2. `feat(schulte): board notifier — start gate, in-order tap, wrong latch` (+ its tests)

---

### T09.3 — BoardSnapshot projection and elapsed-time scoring

**Goal.** Publish the three HUD slots, the 0..1 progress and the terminal `outcome`, and prove the
run lands in Results formatted as a duration.

**Tests first (TDD).** `test/games/schulte_grid/application/schulte_snapshot_test.dart`
- `slotA carries the Time label and an empty value` — the shell authors the clock (rule 4); a game
  that fills it would desynchronise across pause.
- `slotB reads "6 / 25" after six finds` and reformats per locale — the same assertion under
  `Locale('ar')` must produce Arabic-Indic numerals, proving the value went through `NumberFormat`
  and not string interpolation.
- `slotC is the next value, tone highlight, and is the only highlight` — assert exactly one slot is
  `HudTone.highlight` and that **no** slot is `HudTone.alarm` (the alarm is the shell's).
- `progress is foundCount / cellCount` — 6/25 == 0.24, matching `app.html`'s 24% track; 0.0 at start,
  1.0 exactly once.
- `outcome is null until the last tile and non-null exactly once` — driven from a seeded scramble.

`test/games/schulte_grid/schulte_run_scoring_test.dart` — the end-to-end scoring gate:
- `a completed Schulte run is persisted and reads back as a duration` — headless `ProviderContainer`
  with `clockProvider.overrideWithValue(Clock.fixed(...))` advanced by 18.6s and an in-memory drift
  database (`NativeDatabase.memory()`, `addTearDown(db.close)`); play 1..25; assert the persisted row
  exists, and that the shell's formatter for `ScoreFormat.duration` renders `18.6s`.
- `an abandoned run persists nothing` — leave the run mid-board; assert no row.

**Implementation.** `lib/games/schulte_grid/application/schulte_snapshot.dart` exposing
`schulteSnapshotProvider`, a `Provider.autoDispose.family<BoardSnapshot, RunConfig>` that watches the
board notifier and projects `BoardSnapshot(hud: GameHud(slotA, slotB, slotC), progress: ..., outcome: ...)`.
Labels come from `AppLocalizations`; read it via `ref.watch(appLocalizationsProvider)`, which **E07
T07.1 ships** in `lib/l10n/game_strings.dart` beside `gameStringsProvider` precisely because a snapshot
provider has no `BuildContext`. There is no conditional here: if it is missing, that is an E07 gap to
fix in E07.

Before writing `outcome`, read how the shell derives the displayed score for `ScoreFormat.duration`
(`lib/features/results/`, `lib/features/stats/`, `lib/data/`). E06's `RunNotifier._finish` builds a
`RunDraft` carrying `durationMs: _ticker.elapsed.inMilliseconds` and calls
`runRepositoryProvider.saveRun(draft)`, which returns `Result<RunCommit, DataFailure>`. So the expected
shape is: Schulte returns `RunOutcome.completed(score: foundCount)` and the shell formats the run's
`durationMs` for a `ScoreFormat.duration` game. If the shell instead formats `outcome.score`, carry
elapsed milliseconds there. Whichever it is, **zero features lines** — see Risks.

**Files.** `lib/games/schulte_grid/application/schulte_snapshot.dart`,
`test/games/schulte_grid/application/schulte_snapshot_test.dart`,
`test/games/schulte_grid/schulte_run_scoring_test.dart`.

**Skills.** `sunburst-shell-screens`, `state-management-riverpod`, `i18n-rtl-l10n`,
`testing-strategy`, `persistence-drift` (in-memory engine only — read it if the scoring test needs
the DB harness E05 built).

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` — HUD row only: three pills,
labels `Time` / `Found` / `Next`, the third on sunshine, and the progress track at 24%. Compare
structure → spacing rhythm → surface construction → type role → sampled hex.

**Done when.**
- [ ] Both test files green.
- [ ] `flutter run` at classic difficulty shows `Found 0 / 25`, `Next 1` and an empty track.
- [ ] Completing the board reaches Results with a duration-formatted score.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean —
      `nullable-getter: false` is the one-locale gate. `check_arb_parity.sh` stays skipped: it needs a
      sibling `app_*.arb` and exits 2 on a template-only directory (E01 T01.10, ADR 0001).

**Commits.**
1. `feat(schulte): BoardSnapshot projection — three HUD slots and progress` (+ its tests)
2. `test(schulte): a completed run persists and reads back as 18.6s`

---

### T09.4 — GameDefinition, artwork, registry entry and ARB keys

**Goal.** Make Schulte visible to all eight shell screens as **data**, by appending one line to the
registry.

**Tests first (TDD).** `test/games/schulte_grid/schulte_grid_definition_test.dart`
- `the registry exposes stroop_rush then schulte_grid, in that order`.
- `schulte declares decorative and gameAccent, and the two are in step` —
  `GameColourRole.decorative` ⇒ `BoardBackground.gameAccent`. No `switch` can catch a mismatch, so
  this test is the catch.
- `the accent is schulteTurquoise and resolves to gameSchulte / gameSchulteDeep`.
- `scoreFormat is ScoreFormat.duration`.
- `difficulties is [chill, classic]`.
- `every registry entry resolves a non-empty l10n title, tagline and kicker` — loops the registry, so
  a future game that forgets an ARB key fails here rather than rendering blank on Home.
- `ink on the two Schulte fills clears 4.5:1` — pure-Dart WCAG on colour values:
  `textPrimary` on `gameSchulte` (7.2:1) and on `gameSchulteDeep` (5.1:1). Never `meetsGuideline` on
  pixels.

`test/games/schulte_grid/ui/schulte_artwork_test.dart`
- `the artwork renders inside 64x64 with no overflow at text scale 2.0` and declares no `Color`.

**Implementation.** `lib/games/schulte_grid/schulte_grid_definition.dart` — the `final
schulteGridDefinition = GameDefinition(...)` with `id: const GameId('schulte_grid')`,
`accent: GameAccent.schulteTurquoise`, `scoreFormat: ScoreFormat.duration`,
`difficulties: schulteDifficulties`, `boardBackground: BoardBackground.gameAccent`,
`buildBoard: (context, config) => SchulteBoard(config: config)`,
`buildArtwork: (context) => const SchulteArtwork()`,
`snapshotOf: (config) => schulteSnapshotProvider(config)`.

`lib/games/schulte_grid/ui/schulte_artwork.dart` — the 64pt Home-card tile: a 3×3 of nested
mini-tiles at `shape.borderWidthNested`, one of them `accent`. Decoration only, no `Color` literals.

`lib/games/game_registry.dart` — append `schulteGridDefinition` to the list. One line.

`lib/l10n/app_en.arb` (and every sibling `app_*.arb`) — `game_schulte_grid_title`,
`game_schulte_grid_tagline`, `game_schulte_grid_kicker`, `schulteFoundLabel`, `schulteNextLabel`,
`schulteNextTileHint`, `schulteFoundTileLabel`. Copy the exact key shape E08 used for
`game_stroop_rush_*`; do not invent a second convention.

**Files.** `lib/games/schulte_grid/schulte_grid_definition.dart`,
`lib/games/schulte_grid/ui/schulte_artwork.dart`, `lib/games/game_registry.dart`,
`lib/l10n/app_*.arb`, `test/games/schulte_grid/schulte_grid_definition_test.dart`,
`test/games/schulte_grid/ui/schulte_artwork_test.dart`.

**Skills.** `sunburst-shell-screens`, `sunburst-game-surfaces`, `i18n-rtl-l10n`, `sunburst-tokens`,
`widget-golden-and-a11y-testing`.

**Screenshot check.** `design/sunburst-pop/screens/01-home.png` — the second game card: turquoise
fill behind a 3px ink border, the cream art frame and its tile, the "2 unlocked" section label, and
the BEST pill. Also `02-game-detail.png` for the turquoise hero, checking that the difficulty list
renders two rows without the segmented control looking broken. Compare structure → spacing rhythm →
surface construction → type role → sampled hex.

**Done when.**
- [ ] Home shows two unlocked cards; the diff to `lib/features/**` is still empty.
- [ ] `dart run build_runner build --delete-conflicting-outputs` regenerates `AppLocalizations` and
      `flutter analyze --fatal-infos` is clean.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean —
      `nullable-getter: false` is the one-locale gate. `check_arb_parity.sh` stays skipped: it needs a
      sibling `app_*.arb` and exits 2 on a template-only directory (E01 T01.10, ADR 0001).
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` exits 0.

**Commits.**
1. `feat(l10n): Schulte Grid title, tagline, kicker and board labels`
2. `feat(schulte): GameDefinition and Home artwork` (+ its tests)
3. `feat(games): register Schulte Grid`

---

### T09.5 — The board widget and computed cell sizing

**Goal.** A square 4×4 or 5×5 board sized from the slot's constraints against the 48px floor, that
re-applies neither the gutter nor the background the shell already painted.

**Tests first (TDD).**
`test/games/schulte_grid/ui/schulte_grid_metrics_test.dart` (pure, no widget binding) — the table
from `references/board-states-and-layout.md`, `closeTo(x, 1e-9)`:

| side | columns | expected gap | expected cell |
|---|---|---|---|
| 280 (320pt screen) | 5 | 8 | 49.6 |
| 320 (360pt) | 5 | 12 | 54.4 |
| 350 (390pt) | 5 | 12 | 60.4 |
| 390 (430pt) | 5 | 12 | 68.4 |
| 280 | 4 | 12 | 61.0 |
| 280 | 6 | 8 | 40.0 — below `kPopMinTarget`, which is why Blitz is not offered |

- `the gap step is derived from the floor, not from a width` — assert `schulteGap` returns 12 exactly
  when `schulteCell(side, n, 12) >= kPopMinTarget` and 8 otherwise, for a sweep of sides 240..440.

`test/games/schulte_grid/ui/schulte_board_test.dart` — **one `testWidgets` per (device, scale)
tuple, never a loop inside a test** (overflow reports once per RenderObject):
- `Device.all` — 320×640, 360×800, 390×844, 430×932, all at **DPR 2** (E02's presets, the geometry
  `capture-screens.sh` rendered the reference PNGs at) — via `useDevice` + `pumpApp` with
  `addTearDown(view.reset)`; the board is pumped inside a `SizedBox` matching `_BoardPane`'s slot
  (screen width − 2×20 gutter).
- each asserts: 25 `SchulteTile`s present; every `getSize` is square and ≥ 48 on both axes; tiles in
  a row share `top` and tiles in a column share `left` (`moreOrLessEquals`, epsilon 0.5);
  `tester.takeException()` is null.
- text-scale matrix at 1.0 / 1.3 / 2.0 on 360 and 390: no overflow, and the glyph's `getRect` fits
  inside the cell's inner box (border 3 ×2 + 2 padding). Assert the base style **steps down** at 2.0
  rather than being clamped.
- `the board applies no gutter and no background` — no `ColoredBox` and no `SafeArea` descendant of
  `SchulteBoard`, and no `Padding` equal to `SunburstShape.gutter` on the board's own subtree.
  `_BoardPane` owns both.
- `the grid does not clip` — the `GridView`'s `clipBehavior` is `Clip.none`, or the e1 shadow and the
  5pt ring are sheared off.
- `a tap routes to tapCell with the tapped index` — with an overridden notifier.
- `tiles are keyed by value` — `ValueKey(value)`, so a re-tap cannot act on a stale capture.

**Implementation.**
`lib/games/schulte_grid/ui/schulte_grid_metrics.dart` — pure:
`double schulteCell(double side, int columns, double gap)` and
`double schulteGap(double side, int columns)` returning `SunburstShape.space3` (12) unless that drops
the cell under `kPopMinTarget`, then `SunburstShape.space2` (8).

`lib/games/schulte_grid/ui/schulte_board.dart` — `SchulteBoard extends ConsumerWidget`: a
`LayoutBuilder` → `SizedBox.square(dimension: min(maxWidth, maxHeight))` → `SchulteGrid`. **No
`ColoredBox`, no gutter `Padding`, no `SafeArea`.**
`SchulteGrid` — `GridView.builder` with `shrinkWrap: true`,
`physics: const NeverScrollableScrollPhysics()`, `clipBehavior: Clip.none`,
`SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columnCount, crossAxisSpacing: gap,
mainAxisSpacing: gap)`, `key: ValueKey(cells[i])`, `onTap: () => ref.read(provider.notifier).tapCell(i)`.
`SchulteGrid` watches the whole `SchulteBoardState`; per-tile `.select` is deliberately not used —
25 const tiles rebuild for free, and `flutter-performance` says measure before optimising.

`lib/games/schulte_grid/ui/schulte_tile.dart` — `SchulteTile` composing **E03's `PopGridTile`**, not
`PopSurface` directly. E03 T03.8 shipped `PopGridTile` with
`enum PopGridTileState { idle, next, found, wrong, disabled }` — the Schulte machine exactly — plus five
state goldens, the greyscale state-collision proof, the double ring on `next`, the permanent `(2,2)`
found offset, the `borderDisabled` e1 shadow and the 64→60 adaptive sizing. Composing it means this epic
inherits all of that instead of rebuilding it, and the catalog does not carry a fourteenth class nothing
uses. `SchulteTile` therefore does three things: map `SchulteTileState` onto `PopGridTileState` (a 1:1
map, both enums carry the same five cases), pass the glyph and the `semanticLabel`, and wrap the whole
tile in E04's `ShakeOnWrong` keyed on `wrongTapId`. There is **no `schulte_tile_visual.dart`** — the
resolver is `PopGridTile`'s public `visualFor`, and T09.6's channel-count test asserts against that one
function so the proof exists in a single place. `TileGlyph` measures `type.numericHud` against the inner
box and steps to `type.button` — never `FittedBox`, never a clamped scaler, never `fontSize:`.

**Files.** `lib/games/schulte_grid/ui/schulte_grid_metrics.dart`,
`lib/games/schulte_grid/ui/schulte_board.dart`, `lib/games/schulte_grid/ui/schulte_tile.dart`,
`lib/games/schulte_grid/ui/next_ring_painter.dart`,
`test/games/schulte_grid/ui/schulte_grid_metrics_test.dart`,
`test/games/schulte_grid/ui/schulte_board_test.dart`.

**Skills.** `sunburst-game-surfaces`, `sunburst-components`, `widget-composition`,
`widget-golden-and-a11y-testing`, `accessibility-as-code`, `custom-canvas-and-gestures`.

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` — board interior: 5 columns,
12pt gaps, `radiusMd` 16 corners, 3px ink border, e1 hard shadow with zero blur, found tiles at
`gameSchulteDeep` offset (2,2) with no shadow, the `next` tile on `accent` with a 2pt cream then 3pt
ink ring, and the board inset (gutter 20 / top 20 / bottom 26) painted by `_BoardPane`. Compare
structure → spacing rhythm → surface construction → type role → sampled hex.

**Done when.**
- [ ] All four device tests and all six scale tests green with no overflow.
- [ ] `.claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` exits 0.
- [ ] `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` exits 0.
- [ ] `.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib` exits 0.
- [ ] `.claude/skills/widget-composition/scripts/check-widget-composition.sh` exits 0.
- [ ] Every tile at 320pt measures ≥ 48pt on both axes on a real device.

**Commits.**
1. `feat(schulte): cell and gap derived from the slot against the 48px floor` (+ metrics tests)
2. `feat(schulte): the board — square grid, tile and next-tile ring` (+ widget tests)
3. `test(schulte): tile geometry at 320/360/390/430 and text scale 1.0/1.3/2.0`

---

### T09.6 — Tile state channels, goldens and semantics

**Goal.** Make "every state differs in ≥3 non-hue channels" an asserted number rather than a claim,
and back it with a greyscale golden and a screen-reader pass.

**Tests first (TDD).** `test/games/schulte_grid/ui/schulte_tile_visual_test.dart`
- `the state map is a total bijection onto PopGridTileState` — every `SchulteTileState` maps to a
  distinct `PopGridTileState` and every `PopGridTileState` is reached; an exhaustive `switch` with no
  `default:`, so a sixth Schulte state is a compile error rather than a silently reused tile.
- `every ordered pair of distinct states differs in at least three non-hue channels` — loop
  `SchulteTileState.values` × itself, resolve each through `popStateOf` into **E03's `visualFor`**, and
  for each pair count differences across `{elevation, offset, scale, borderColor, glyphColor, hasRing}`;
  assert ≥ 3 with the pair printed in `reason:`. **This is the greyscale guarantee**, and it is asserted
  against the one resolver both the catalog and this game read.
- `no state is distinguished by fill alone`.
- `found and disabled recede by fill, never by opacity` — `visualFor` exposes no opacity, and the
  widget test asserts no `Opacity` descendant of `SchulteTile` in any state.
- `disabled keeps an e1 shadow repainted in borderDisabled` — not `flat`; matching
  `.btn[disabled]{box-shadow:3px 3px 0 var(--ink-3)}` and every other disabled surface.
- contrast, pure Dart WCAG on values: `textPrimary` on `surface` ≥ 4.5, on `accent` ≥ 4.5, on
  `gameSchulteDeep` ≥ 4.5 (5.1:1); `surfaceRaised` on `danger` ≥ 4.5 (5.07:1); `textDisabled` on
  `surfaceSunk` ≥ 3.0 (3.40:1) with the WCAG 1.4.3 disabled-control exemption named in `reason:`.

`test/games/schulte_grid/ui/schulte_tile_golden_test.dart`, `@Tags(['golden'])`, `loadAppFonts()`
- Ahem geometry lane: one golden per `SchulteTileState` (5 files).
- Real-font lane, pinned OS: one golden of the full board mid-run at 390×844.
- Greyscale lane: the same board through a saturation-0 `ColorFiltered`. The review question is
  "what state is every tile in?" answered from that file alone.
- RTL lane: the board under `Directionality(textDirection: TextDirection.rtl)`, confirming reading
  order mirrors and the ring/shadow do not.

`test/games/schulte_grid/ui/schulte_a11y_test.dart`
- `every tile is labelled with its number` — `find.bySemanticsLabel('7')`.
- `an idle tile is a button and a found tile is not` — a resolved tile drops `onTap`.
- `the next tile carries its cue in a non-visual channel` — the ring is invisible to a screen reader,
  so the next tile carries `schulteNextTileHint`; a found tile carries `schulteFoundTileLabel`.
- `traversal is reading order` — `simulatedAccessibilityTraversal` yields 1..n² in grid order.
- `await expectLater(tester, meetsGuideline(androidTapTargetGuideline))` as an advisory tripwire only
  — the `getSize` loop in T09.5 is the gate.

**Implementation.** The visual resolver is **E03's**: `PopGridTileVisual visualFor(PopGridTileState,
SunburstColors, SunburstShape)` in `lib/ui/components/pop_grid_tile.dart`, an exhaustive `switch` with
no `default:`. This epic adds only the 1:1 state map
`PopGridTileState popStateOf(SchulteTileState)` in `schulte_tile_state.dart`, and nothing under
`lib/games/schulte_grid/` picks a colour. Semantics are authored on `PopGridTile`'s `semanticLabel`
plus a sibling `Semantics(hint:)` for `next`; the `CustomPaint` ring is inside `ExcludeSemantics`.
If a state genuinely needs a channel `PopGridTile` does not resolve, widen the component in `lib/ui/`
with a test — do not fork a second resolver here.

**Files.** `lib/games/schulte_grid/domain/schulte_tile_state.dart` (+ the state map; edits to
`schulte_tile.dart`), `test/games/schulte_grid/ui/schulte_tile_visual_test.dart`,
`test/games/schulte_grid/ui/schulte_tile_golden_test.dart`,
`test/games/schulte_grid/ui/schulte_a11y_test.dart`,
`test/games/schulte_grid/ui/goldens/*.png`.

**Skills.** `sunburst-game-surfaces`, `sunburst-tokens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `custom-canvas-and-gestures`, `i18n-rtl-l10n`.

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` — sample the four states the
PNG actually shows: idle `#FFF8EC`, found `#12A79A`, next `#FFC53D`, border `#2B1B4D`. `wrong` and
`disabled` have no reference PNG (the mock has no wrong tile and no pre-start board); they are signed
off against `system.html` §10/§11 and the state matrix, and that limit is stated in the PR body.

**Done when.**
- [ ] The channel-count test passes for all 20 ordered pairs.
- [ ] The greyscale golden answers "what state is every tile in" with no colour.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` exits 0.
- [ ] No `Opacity`, `withOpacity`, `FittedBox`, `TextOverflow.ellipsis` or `withClampedTextScaling`
      anywhere under `lib/games/schulte_grid/`.
- [ ] Goldens were blessed in the pinned environment only; CI runs no `--update-goldens`.

**Commits.**
1. `feat(schulte): tile visual channels as a value type` (+ the channel-count test)
2. `feat(schulte): semantics for idle, next, found and disabled tiles` (+ a11y tests)
3. `test(schulte): tile, board, greyscale and RTL goldens`

---

### T09.7 — Motion and haptics

**Goal.** Wire `tileFound`, `tileNextCue` and `answerWrong` with one haptic per tap and an end state
that survives reduce motion.

**Tests first (TDD).** `test/games/schulte_grid/ui/schulte_tile_motion_test.dart`
- `a correct tap fires exactly one moment` — `Moment.tileFound`; `tileNextCue` fires none, because
  two tiles changing is still one committed event. A rattle on a 25-tile board is the bug.
- `a wrong tap fires Moment.answerWrong exactly once and never heavyImpact` — `heavyImpact` is spent
  on `Moment.personalBest` and nowhere else.
- `the shake runs exactly two cycles and stops` — `pump(motion.durCelebrate)` twice, then assert the
  translation is back to zero. Never `pumpAndSettle`.
- `under MediaQuery.disableAnimations the tile is at its end state on the first pump` — reduce motion
  collapses to `Duration.zero`, never to a shorter duration; the shake is skipped entirely and the
  `danger` fill + paper glyph is the residue that carries the meaning.
- `a found tile rests at pressTranslate(e1) = (2,2) with no shadow, under reduce motion too` — the
  resting offset is state, not animation.
- `disposing mid-shake does not resume` — pump one cycle, dispose, assert no pending timer.

**Implementation.** `SchulteTile` gets an `AnimatedContainer` over `motion.resolve(context,
motion.durState)` on `motion.easeOut` for the fill/shadow cross, and is wrapped in **E04's
`ShakeOnWrong` from `lib/shared/motion/shake_on_wrong.dart`**, keyed on `wrongTapId`. That is the one
copy in the repository — E04 T04.8 created it and E08's answer key wraps the same widget. Do not add
one under `lib/games/**` and do not create `lib/ui/motion/`; E04 T04.9's policy test fails on a second
declaration. Every duration and curve is read off `SunburstMotion.of(context)`; the haptic is fired
from the notifier through `ref.read(feedbackServiceProvider).fire(...)`, never `HapticFeedback.*`.

**Files.** edits to `lib/games/schulte_grid/ui/schulte_tile.dart`,
`test/games/schulte_grid/ui/schulte_tile_motion_test.dart`. (No new file: the shake is E04's.)

**Skills.** `sunburst-motion-and-haptics`, `sunburst-tokens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `async-safety`.

**Screenshot check.** n/a — `05-schulte-grid.png` is an end state only and cannot verify motion,
press physics or haptics. The two motion consequences that *are* end states — the found tile's
resting (2,2) offset and the `next` tile's ring — are compared in T09.5 and T09.6.

**Done when.**
- [ ] `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` exits 0 — no
      raw `Duration(`/`Curves.`/`Cubic(` and no `HapticFeedback.` under `lib/games/**`.
- [ ] One tap on device produces exactly one haptic tick.
- [ ] With Reduce Motion on, the board is still fully playable and every state still readable.

**Commits.**
1. `feat(schulte): tileFound, tileNextCue and the wrong-tap shake` (+ its tests)

---

### T09.8 — The zero-lines proof

**Goal.** Turn "shipping a game adds zero lines to `lib/features/**`" into two things that fail
loudly: a durable policy test in `flutter test`, and a branch-scoped diff check run before the PR.

**Tests first (TDD).** `test/policy/engine_seam_test.dart` — reads the source tree; no widget
binding:
- `no file under lib/features names a specific game` — strip `//` and `///` comments (the shell may
  *explain* itself with an example; it may not *execute* on a game name), then assert no
  case-insensitive match for `schulte`, `stroop`, `nback` or `n_back` in the remaining source. Print
  the offending file and line.
- `no file under lib/features imports a specific game` — no `import`/`export` of `games/<id>/...`;
  `games/game_registry.dart` is the one legal target. This mirrors `check_shell_boundaries.sh` into
  `flutter test` so CI catches it even if a gate script is dropped.
- `game_registry.dart is the only file that names more than one game` — count files under `lib/`
  importing two or more `games/<id>/` paths; assert exactly one, and assert it is the registry.
- `every game in the registry ships the same four artefacts` — for each entry, the directory
  `lib/games/<id>/` exists and contains a `<id>_definition.dart`, an `application/`, a `domain/` and
  a `ui/`. A future game that fits the seam passes for free.

**Implementation.** `tool/check_no_shell_edits.sh`:

```bash
#!/usr/bin/env bash
# Usage: tool/check_no_shell_edits.sh [base_ref]   (default: origin/main)
# Shipping a game must add zero lines to lib/features/**.
set -euo pipefail
BASE_REF="${1:-origin/main}"
BASE="$(git merge-base "$BASE_REF" HEAD)"
CHANGED="$(git diff --name-only "$BASE"...HEAD -- lib/features || true)"
if [ -n "$CHANGED" ]; then
  printf '%s\n' "$CHANGED"
  echo "FAIL: shipping a game must add zero lines to lib/features/**."
  echo "      The fix is a game-agnostic widening of GameDefinition/BoardSnapshot in E06,"
  echo "      never a special case in a shell screen."
  exit 1
fi
echo "OK: lib/features/** untouched by $(git rev-parse --abbrev-ref HEAD)."
```

Not wired into CI: a permanent "no PR may touch `lib/features`" gate would block every future shell
epic. It is a required pre-PR step whose output is pasted into the PR body. The durable half is the
policy test, which CI already runs via `flutter test`.

**If the script fails**, stop. Do not edit a shell screen. Record what the shell could not express,
widen `GameDefinition`/`BoardSnapshot` with a field no game name appears in, and note in the PR that
this epic found a seam defect owned by E06.

**Files.** `test/policy/engine_seam_test.dart`, `tool/check_no_shell_edits.sh`.

**Skills.** `sunburst-shell-screens`, `testing-strategy`, `project-structure-and-packages`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/policy/` green.
- [ ] `bash tool/check_no_shell_edits.sh` prints `OK` and its output is in the PR body.
- [ ] `git diff --stat $(git merge-base origin/main HEAD)...HEAD` shows changes only under
      `lib/games/schulte_grid/`, `lib/games/game_registry.dart` (one line), `lib/l10n/`, `test/` and
      `tool/`. **Nothing under `lib/core/`, `lib/shared/` or `lib/ui/`** — the PRNG is E06's, the shake
      is E04's, the tile is E03's, and `appLocalizationsProvider` is E07's. A diff touching any of them
      means this epic rebuilt something it should have imported; fix that before the PR, or, if the
      shared component genuinely could not express the need, widen it game-agnostically and say so.

**Commits.**
1. `test(policy): the shell may never name a specific game`
2. `chore(tool): check_no_shell_edits.sh — a game adds zero lines to lib/features`

---

### T09.9 — Screenshot sign-off for 05, and the 04 regression re-check

**Goal.** Sign the board off against its reference, and prove the shared chrome did not regress on
the game that already shipped.

**Tests first (TDD).** Not TDD-able as a `dart test`: this is a human visual comparison against a
rendered PNG, and everything about it that a test *can* express — geometry, contrast, semantics,
goldens — is already asserted in T09.5–T09.7. The one automatable piece is added first: a
reference-board golden so the comparison is reproducible rather than dependent on whatever seed the
tester happened to play.

`test/games/schulte_grid/ui/schulte_reference_board_golden_test.dart`, `@Tags(['golden'])`
- `the reference board renders at 390x844` — construct `SchulteBoardState` directly with the exact
  cells from `app.html` screen 05 (`14,3,22,9,17 / 6,25,11,1,20 / 19,8,15,4,12 / 2,23,7,18,10 /
  21,13,5,24,16`) and `nextValue: 7`, so six tiles are `found`, one is `next`, and the golden is
  byte-comparable with the reference by eye.

**Implementation.** Procedure, not code:
1. Run the reference-board golden and open it beside `design/sunburst-pop/screens/05-schulte-grid.png`.
2. Run the app on a 390×844 logical device (iPhone 14 simulator, or `flutter run -d macos` with the
   window sized to match), play Schulte at Classic, and screenshot the play screen.
3. Compare both, in this order — **structure** (same regions, same order, same relative heights:
   status strip, top bar with pause glyph + title + difficulty chip, turquoise play band with rays
   and halftone dots, HUD row, progress track, board pane) → **spacing rhythm** (gutter 20, board top
   20, board bottom 26, tile gap 12) → **surface construction** (3px ink border and the correct hard
   shadow step everywhere; zero blur; zero spread) → **type role** (Fredoka display on the tile
   glyph, tabular figures, HUD label vs value steps) → **sampled hex** (`#FFF8EC`, `#12A79A`,
   `#FFC53D`, `#22C7B8`, `#2B1B4D`).
4. **Re-check `04-stroop-rush.png`.** The top bar, chip, play band height, HUD row and track are
   shared code; anything this epic changed in `lib/ui/` or `lib/l10n/` can move them. Run Stroop at
   390×844 and compare against the reference. Any difference is a regression introduced here.
5. Copy `.claude/skills/sunburst-game-surfaces/templates/new_game_visual_checklist.md` into the PR
   body and tick it in order.
6. A difference is an implementation defect. If a reference is genuinely wrong, edit
   `design/sunburst-pop/app.html`, re-run `design/sunburst-pop/capture-screens.sh`, and commit the
   regenerated PNGs with the change as a deliberate design decision.

**Files.** `test/games/schulte_grid/ui/schulte_reference_board_golden_test.dart`,
`test/games/schulte_grid/ui/goldens/reference_board_390x844.png`; conditionally
`design/sunburst-pop/app.html` and `design/sunburst-pop/screens/*.png`.

**Skills.** `sunburst-game-surfaces`, `sunburst-shell-screens`, `sunburst-components`,
`sunburst-tokens`, `widget-golden-and-a11y-testing`.

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` (chrome **and** board
interior) and `design/sunburst-pop/screens/04-stroop-rush.png` (chrome only, as a regression check).

**Done when.**
- [ ] The reference-board golden is committed and matches `05-schulte-grid.png` by eye across all
      five comparison steps.
- [ ] Stroop at 390×844 still matches `04-stroop-rush.png`.
- [ ] The visual checklist is in the PR body with every box ticked or explicitly waived.
- [ ] Any design change is a committed `app.html` + regenerated `screens/*.png` pair, never a silent
      drift.

**Commits.**
1. `test(schulte): reference-board golden at 390x844`
2. `design(sunburst-pop): <what changed> and re-rendered screens` — **only if** step 6 fires.

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 T01.8 built
bash tool/skill_gates.sh

# this epic's named spot-checks, run individually so a failure names itself
# Sunburst design gates
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart

# Architecture, determinism, i18n, test hygiene
.claude/skills/flutter-architecture/scripts/check_architecture.sh                    lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh     lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh
.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh       lib
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh           lib
.claude/skills/widget-composition/scripts/check-widget-composition.sh
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                              lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                              lib
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh                        lib test
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh          lib test

# This epic's headline gate
bash tool/check_no_shell_edits.sh
```

CI (created in E01) runs the first block plus `bash tool/skill_gates.sh`, which is the only sanctioned
way to run the skill scripts — a bare `for s in .claude/skills/*/scripts/*.sh` loop cannot exit 0.
Add a `verify_feature.sh lib/games/schulte_grid` row to the runner's run table beside E07's and E08's.
`tool/check_no_shell_edits.sh` is run locally and its output pasted into the PR body — it is
branch-scoped and must not become a permanent CI gate that blocks future shell epics.

## Risks and open questions

1. **`ScoreFormat.duration` may not be wired end to end.** E06's `RunNotifier._finish` puts
   `durationMs: _ticker.elapsed.inMilliseconds` on the `RunDraft` it hands `saveRun`, but
   `RunOutcome.completed(score:)` also carries a number, and the shell must choose which one it formats.
   **Decision:** read `lib/features/results/`,
   `lib/features/stats/` and `lib/data/` before writing T09.3; supply whichever field makes the
   Results screen read `18.6s` **without touching `lib/features/**`**. If neither path works, it is
   an E06/E07 seam defect — raise it with the E06 owner, widen the seam generically, and record it in
   the PR. Do not patch a shell screen.
2. **`appLocalizationsProvider` is E07's and already exists.** The snapshot needs localized HUD labels
   and has no `BuildContext`, so E07 T07.1 ships the provider in `lib/l10n/game_strings.dart` alongside
   `gameStringsProvider`. This epic imports it. Do not add a second one under `lib/features/**` or
   anywhere else; if it is genuinely absent, that is an E07 defect to fix in E07.
3. **`SunburstType` has no tile slot.** `system.html` §10 draws the tile glyph at 24pt display/700
   with tabular figures; `sunburst-tokens` owes `tileGlyph` (24) and `tileGlyphCompact` (18) and has
   shipped neither. **Decision:** use `numericHud` (22) and `button` (18), which renders 2pt small,
   and verify the board only to ~1.5× text scale. Log it as a **BLOCKER** for `design-review-workflow`
   in E10 and as a token request to `sunburst-tokens`. Never paper over it with a `fontSize:` — that
   fails `check_raw_values.sh` and the ban is the point.
4. **The `sunburst-game-surfaces` Schulte example contradicts the shell.**
   `examples/schulte_board.dart` wraps the board in a `ColoredBox` of the accent and in a
   `SunburstShape.gutter` `Padding`; `sunburst-shell-screens`' `_BoardPane` already paints the
   background from `GameDefinition.boardBackground` and already applies gutter 20 / top 20 /
   bottom 26, and `sunburst-game-surfaces` rule 8 says the slot arrives with the gutter removed.
   **Decision:** the shell wins — the board applies neither. Doing both would give a 240pt board at
   320pt and a 44.4pt cell, breaking the 48px floor the whole gap derivation exists to defend. Flag
   the example to the skill owner.
5. **Blitz cannot ship at 6×6.** At the 320pt floor the board is 280pt wide and a 6-column cell is
   40.0pt at the 8pt gap — 8pt under `kPopMinTarget`. Dropping the shell gutter 20→16 gives 41.33pt,
   still short, and the next lever (collapsing the play band) changes every game and belongs to
   `sunburst-shell-screens`. **Decision:** Schulte offers Chill (4×4) and Classic (5×5) only; Blitz is
   a recorded omission in the PR's "deliberately left out" section, with the arithmetic pinned by a
   test in T09.1.
6. **Directory name.** The brief says `lib/games/schulte/`; `references/shell-game-boundary.md` and
   the `game_<id>_*` ARB convention require the directory to match the `GameId`. **Decision:**
   `lib/games/schulte_grid/` with `GameId('schulte_grid')`, matching the `schulte_grid/` shown in the
   seam reference and the `stroop_rush/` E08 shipped.
7. **Riverpod modifier order.** `NotifierProvider.autoDispose.family` vs `.family.autoDispose` and
   `FamilyNotifier` vs a plain `Notifier` differ across Riverpod 3.x docs. **Decision:** copy the
   exact shape E06/E08 used for `stroopBoardNotifierProvider`; do not introduce a second convention.
   E08 is a declared dependency of this epic partly for this reason: `stroopBoardNotifierProvider` is
   the precedent, `test/games/game_registry_test.dart` asserts `stroop_rush` **then** `schulte_grid`,
   and T09.9 step 4 re-checks `04-stroop-rush.png` for chrome regressions this epic could introduce.
10. **`PopGridTile` is E03's, and this epic is its only consumer.** E03 T03.8 shipped it with the five
   Schulte states, the public `visualFor` resolver, five state goldens and the greyscale
   state-collision proof. **Decision:** `SchulteTile` composes it and maps `SchulteTileState` 1:1;
   there is no `schulte_tile_visual.dart`. Building a second resolver here would leave the catalog
   carrying a class nothing uses and the greyscale guarantee asserted in two places that can disagree.
   If `PopGridTile` cannot express a state, widen it in `lib/ui/` with a test — that is a component
   change, and it is the only kind of `lib/ui/` edit T09.8's zero-lines proof tolerates.
8. **Golden lane flakiness.** Real-font goldens are byte-stable only on the pinned OS. **Decision:**
   bless them in that one environment; CI verifies and never runs `--update-goldens`.
9. **The wrong-tile latch has no timeout.** It clears on the next tap, because the game may not own a
   clock and a raw `Duration` under `lib/games/**` fails `check_motion_tokens.sh`. A player who taps
   wrong and then walks away leaves a red tile on screen. **Open:** acceptable, or does it want a
   shell-supplied hold duration on `GameDefinition`? Ask in the PR; do not add a timer unilaterally.

## Definition of done

- [ ] Branch `epic/09-schulte-grid` cut from `main`, granular commits, tests committed with the code
      they cover.
- [ ] All nine tasks complete with their "Done when" boxes ticked.
- [ ] Schulte Grid is playable end to end: Home card → detail → countdown → 5×5 board → Results with
      a duration score → Stats.
- [ ] `bash tool/check_no_shell_edits.sh` prints `OK`, and `test/policy/engine_seam_test.dart` is
      green — **zero lines added to `lib/features/**`**.
- [ ] Scramble golden vectors committed, with an honest header comment about which rows are
      independently derived.
- [ ] Every tile-state pair proven to differ in ≥3 non-hue channels **through E03's `PopGridTile`
      resolver**, plus a greyscale golden; no second visual resolver, no second `ShakeOnWrong`, no
      second PRNG.
- [ ] Cell geometry verified at 320/360/390/430 and text scale 1.0/1.3/2.0, with no clamp, no
      `FittedBox`, no ellipsis.
- [ ] `05-schulte-grid.png` compared (chrome and board interior) and `04-stroop-rush.png` re-compared
      with no regression; the visual checklist is in the PR body.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Every command under **Gates that must pass** exits 0.
- [ ] PR opened explaining what changed, why, how it was verified, which screens were compared
      (05 and 04), and what was deliberately left out (Blitz 6×6 and the reason; the `tileGlyph`
      token gap; `wrong`/`disabled` having no reference PNG).
- [ ] CI green on the PR.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
