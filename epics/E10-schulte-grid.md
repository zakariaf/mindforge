# E10 · Schulte Grid

| | |
|---|---|
| **Branch** | `epic/10-schulte-grid` |
| **Depends on** | E07, E08, E09 |
| **Unblocks** | E11 |
| **Status** | Not started |

## The epic

Ship the second game — Schulte Grid — entirely under `lib/games/schulte_grid/`, plus one appended
line in `lib/games/game_registry.dart` and ten ARB keys in **four** locales. The game supplies a
seeded scramble, a five-state tile machine, a board widget, a `GameDefinition` and a `BoardSnapshot`.
It inherits home, game detail, countdown, play scaffold, pause, results, stats and settings without a
line being added to any of them.

The deliverable is therefore two things at once: a playable game, and the **proof that the engine
seam holds**. Shipping this game must add **zero lines to `lib/features/**`**. That is a task with a
test (T10.9), not an aspiration. If it cannot be met, the seam is wrong: the fix is a game-agnostic
widening of `GameDefinition`/`BoardSnapshot` owned by E07, never a special case here.

This game is also the hardest localization case in the app, because **its content is numbers**. Under
`fa` and `ckb` the twenty-five tiles render Eastern Arabic numerals `۱`–`۲۵`, the `Found 6 / 25` and
`Next 7` cues render in the same block, and the elapsed-time score renders with a `٫` decimal
separator. None of that is a paint-time detail: the numerals have different advance widths and deeper
descenders than Latin digits, and the cell they must fit inside is fixed by the game's own rule (5×5),
so the fit is measured per locale or it is not verified at all.

Two decisions are recorded here because they will be questioned:

- **The scramble is locale-independent.** Generators produce integers; localisation happens at render.
  A golden vector must not change because the locale changed, and T10.1 asserts exactly that.
- **The grid does not mirror; the chrome around it does.** See T10.5.

iOS is the only shipping target. Everything below is built and verified on the iOS Simulator; Android
is deferred and nothing here claims parity with it.

## Why we need it

E09 built Stroop Rush against a shell that was designed alongside it, so nothing in E09 could
disprove the engine claim — the first game always fits. The second game is where an engine either
proves itself or forks. Schulte is deliberately the *opposite* game on every axis the seam touches:

| Axis | Stroop Rush | Schulte Grid |
|---|---|---|
| `GameColourRole` | `mechanic` — hue is the answer | `decorative` — hue is free |
| `boardBackground` | `BoardBackground.surfaceSunk` | `BoardBackground.gameAccent` (turquoise) |
| Wrong feedback | depth + ink strike bar, no `danger` | `danger` fill + paper glyph |
| `scoreFormat` | `ScoreFormat.points` → `1,480` / `1.480` / `۱٬۴۸۰` | `ScoreFormat.duration` → `18.6s` / `18,6 s` / `۱۸٫۶` + unit |
| Run end | the clock runs out | the board reports `outcome` |
| Difficulties | three | two |
| Board | one stimulus + four keys | 16 or 25 computed square cells |
| Localised content | words (colour names) | **numbers** — the tiles themselves |

Every one of those is a place a hidden `switch (gameId)` would surface. Without this epic the engine
claim in `CLAUDE.md` is untested marketing, `ScoreFormat.duration` has never rendered, the
`decorative` half of the accent contract has never been built, `BoardSnapshot.outcome` has never
ended a run, no board has ever rendered a non-Latin numeral, and E11 has only one game to sweep.

The last row is the one E04 could not cover on its own. E04 proved the *chrome* survives four locales;
only a board whose payload is digits proves the numeral pipeline reaches the canvas.

## Current state

Verified by `ls` and `git log` on `main` at 4 commits (`cb1c3e2`), plus the toolchain checked on this
machine.

- **The Flutter app is not scaffolded.** No `pubspec.yaml`, no `lib/`, no `test/`, no `tool/`, no
  `.github/`. Everything this epic touches is created by E01–E09 first. This epic's header names the
  three load-bearing edges (E07 engine core, E08 shell screens, E09 Stroop Rush); it transitively
  consumes E01 (package + CI + iOS target), E02 (persistence), E03 (tokens), E04 (localization and
  RTL foundation) and E05 (components) and names the exact symbols below.
- **Toolchain, verified:** Flutter 3.44.6 stable · Dart 3.12.2 · DevTools 2.57.0 · Xcode 26.6
  (17F113) · CocoaPods 1.15.2. Simulator runtimes: iOS 18.0, 18.6, 26.5.
- **The canonical device already exists:** simulator `MindForge iPhone 14`, UDID
  `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6. It is **exactly 390×844 logical points**, which is
  the geometry `capture-screens.sh` rendered the reference PNGs at. No iPhone 16-class simulator
  matches (iPhone 16 is 393×852, 16 Pro is 402×874), so every screenshot comparison in this epic uses
  this device or it is not an honest comparison.

  ```bash
  xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
  flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
  ```

- `.claude/skills/` — 45 skills. Two carry worked Schulte code that this epic must reconcile:
  - `.claude/skills/sunburst-game-surfaces/examples/schulte_board.dart` — a full board, tile,
    `NextRingPainter` and `TileGlyph`. **It is wrong on three points now**: it wraps the board in a
    `ColoredBox(GameAccent.schulteTurquoise.base(colors))` and in a `SunburstShape.gutter` `Padding`
    (both already applied by the shell's `_BoardPane`, see Risks), and it renders the tile value with
    a bare `'$value'` interpolation, which ships Latin digits to a Persian player.
  - `.claude/skills/sunburst-motion-and-haptics/examples/feedback_moments.dart` — `SchulteTile`,
    `ShakeOnWrong`, and the `tileFound`/`tileNextCue` split (two visuals, one haptic).
- `.claude/skills/sunburst-game-surfaces/references/board-states-and-layout.md` — the five-row tile
  state matrix and the cell-sizing table. The five states are implemented by **E05's `PopGridTile`**
  (`PopGridTileState { idle, next, found, wrong, disabled }`, shipped in T05.8 with its own goldens and
  greyscale proof); this epic maps onto it rather than re-implementing the matrix.
- `.claude/skills/sunburst-shell-screens/references/shell-game-boundary.md` — `GameDefinition`,
  `BoardSnapshot`, `GameHud`, `HudSlot`, `RunConfig`, and the "Adding a game: the whole diff" list
  that ends "Zero lines in `lib/features/**`".
- `.claude/skills/i18n-rtl-l10n/` — the contract this epic's numeral work is written against, plus the
  two gate scripts that now both run: `scripts/check_i18n_bans.sh` and `scripts/check_arb_parity.sh`.
  `references/numerals-and-calendars.md` is the authority for the digit blocks and the separator trap.
- **From E04, consumed by name and never re-created:** `lib/l10n/app_en.arb` (template) and its
  `app_de.arb` / `app_fa.arb` / `app_ckb.arb` siblings; `LocaleNumbers.forLocale(Locale)` with `ckb` pinned to
  `fa`; `localeNumbersProvider` (the `BuildContext`-free formatter a `CustomPainter` scene needs);
  `AsciiNumerals.normalize(String)`; the FSI/PDI helpers `Bidi.isolate` / `Bidi.isolateLtr`;
  `localeProvider`; `appLocalizationsProvider` (the `BuildContext`-free string accessor a snapshot
  provider needs); and the custom `ckb` `LocalizationsDelegate`. The per-script `fontFamilyFallback`
  cascade on `SunburstType` is **E03 T03.9's**, not E04's.
- `design/sunburst-pop/screens/05-schulte-grid.png` — the LTR target. Board is 5×5 with 12px gaps, six
  found tiles, `next` = 7, HUD row `Time / Found / Next` with `Next` on the highlight tone, progress
  track at 24% (= 6/25).
- `design/sunburst-pop/screens/rtl/05-schulte-grid.png` — the RTL target, produced by E04 from a
  `dir="rtl"` Persian variant of `app.html` via the extended `capture-screens.sh`. It is the
  comparison target for RTL work exactly as the LTR set is for LTR.
- `design/sunburst-pop/app.html` §5 — `.playfill--schulte{background:var(--turquoise);padding-top:20px}`,
  `.grid5{gap:12px}`, `.tile`, `.tile.found`, `.tile.next`. `system.html` §10 is authoritative for
  the hexes behind them.
- No epic before this one has been executed; `epics/` is created by these files.

## What we will achieve

A reader can tell this epic is done by doing all of the following on
`MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`).

1. Launch in English. Home shows two unlocked game cards; the second is **Schulte Grid** on turquoise
   with a mini-grid artwork tile and a BEST pill formatted as a duration.
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
7. Switch Settings → Language to **فارسی**. Without a restart: the chrome mirrors, the tiles read
   `۱`–`۲۵`, the HUD reads `۶ / ۲۵` and `۷`, the elapsed time reads `۱۸٫۶` plus its localized unit,
   **and the grid itself does not mirror** — tile index 0 is still top-left. The board's hard offset
   shadow still falls down-and-right.
8. Switch to **کوردیی ناوەندی** (`ckb`). Nothing throws, the tiles still read `۱`–`۲۵`, and no glyph
   is a tofu box.
9. Switch to **Deutsch**. Every label still fits its pill at text scale 1.3; nothing is ellipsised and
   nothing is shrunk.
10. `bash tool/check_no_shell_edits.sh` prints `OK: lib/features/** untouched` — the whole diff is
    `lib/games/schulte_grid/**`, one line of `lib/games/game_registry.dart`, `lib/l10n/app_*.arb`,
    `test/**` and `tool/**`.
11. `flutter test` is green, including golden vectors that are byte-identical across all four locales,
    a state-channel test proving every tile-state pair differs in ≥3 non-hue channels, a greyscale
    golden, cell-geometry tests at 320/360/375/390/430, and a per-locale glyph-fit test.
12. Every gate under `Gates that must pass` exits 0, including `check_arb_parity.sh` over four ARBs.
13. `screens/05-schulte-grid.png`, `screens/rtl/05-schulte-grid.png` and — as a regression re-check —
    `screens/04-stroop-rush.png` and `screens/rtl/04-stroop-rush.png` have all been compared and signed
    off in the PR body with the visual checklist.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `i18n-rtl-l10n` | The largest single addition to this epic. Owns: the ten ARB keys across `en`/`de`/`fa`/`ckb` with key + placeholder parity; `nullable-getter: false`; the per-locale `NumberFormat` with `ckb` pinned to `fa` because `intl` ships no `ckb` number symbols and silently falls back to Latin; the Persian block U+06F0–06F9 versus the Arabic block U+0660–0669 (Persian `۴۵۶` is not Arabic `٤٥٦`, and shipping the wrong one is a defect); `AsciiNumerals.normalize` before any parse; the FSI/PDI isolate helper for the `6 / 25` compound; Directional-only geometry; the LTR-pinned island for a locale-invariant coordinate space (which is what the grid is); the ban on rendering numeral goldens with Ahem; and both gate scripts. |
| `sunburst-game-surfaces` | Owns everything this epic builds below the play band's ink border: the `GameAccent.schulteTurquoise` claim, `GameColourRole.decorative`, the five-row tile state matrix, the `cell(12) >= kPopMinTarget ? 12 : 8` gap derivation, the ban on `FittedBox`/clamped scalers in favour of a smaller BASE style, and `scripts/check_game_palette.sh`. |
| `sunburst-shell-screens` | Owns the seam: `GameDefinition`, `BoardSnapshot`, `GameHud`/`HudSlot`/`HudTone`, `RunConfig`, `_BoardPane` (which owns the board's background and insets — the game must not re-apply them), the ban list under `lib/games/**`, rule 11's no-shrink-to-fit, and the zero-lines rule this epic proves. |
| `sunburst-tokens` | Fixes the slot names the board reads — `gameSchulte`, `gameSchulteDeep`, `accent`, `surface`, `surfaceSunk`, `surfaceRaised`, `danger`, `border`, `borderDisabled`, `textPrimary`, `textDisabled` — bans a raw `Duration(milliseconds:)` anywhere outside `lib/theme/**` (which is why the wrong-tap latch has no timer), and bans a raw `fontFamily:`/`fontSize:`, which is why the Arabic-script face reaches the tile through `SunburstType`'s per-locale `fontFamilyFallback` cascade and never through a literal here. |
| `sunburst-components` | `PopSurface` is what a tile is; `PopElevation` (`flat`/`e1`/`e2`) is the depth vocabulary; `kPopMinTarget` (48) is the floor the gap derivation is written against; the disabled shape (`surfaceSunk` + `borderDisabled` + an e1 shadow repainted in `borderDisabled`) is what `enabled: false` does; and rule 5 — the hit area does not move with the visual press. |
| `sunburst-motion-and-haptics` | Names the three moments this board spends — `Moment.tileFound` (`selectionClick`), `Moment.tileNextCue` (a declared silence), `Moment.answerWrong` (two 240ms shake cycles, `lightImpact`) — the reduce-motion residue each keeps, and `routeTransition`'s directional slide, which is the one place in the run flow that *does* follow `Directionality`. |
| `seeded-determinism-and-golden-vectors` | The scramble is derived content: injected key, one entropy source, an owned SplitMix64 PRNG salted per feature, a frozen generator version, and a committed golden-vector table regenerated only by `tool/`, never by CI. Rule 4's "entropy has exactly one source" is what makes the locale-independence test provable rather than hopeful. |
| `testing-strategy` | Pushes the scramble and the tile machine to the pure tier (`package:test`), drives the notifier headlessly with `ProviderContainer`, requires bare-`implements` fakes for `FeedbackService`, requires seeded fuzz against an independent oracle, and requires the round-trip property that `AsciiNumerals.normalize(format(n)) == n` for every locale. |
| `widget-golden-and-a11y-testing` | `useDevice`/`pumpApp` pin the device presets at DPR 2 (the default 800×600 surface would make every cell pass); one `testWidgets` per (device, scale, locale) tuple because overflow reports once per RenderObject; the two golden lanes — Ahem for geometry and mirroring, **real fonts via `loadAppFonts()` for the Persian numeral lane**, because Ahem renders no Persian digit and would bless an em-square; pure-Dart WCAG on colour values, never `meetsGuideline` on pixels. |
| `state-management-riverpod` | `SchulteBoardNotifier` is a family `Notifier` over one immutable state with `void` intent methods; `snapshotOf` returns a `ProviderListenable`; the state holds `int`s and never a formatted string; no `DateTime.now()` anywhere — the game owns no clock. |
| `widget-composition` | Class-not-method extraction for `SchulteGrid`/`SchulteTile`/`TileGlyph`; computed cell sizing from `LayoutBuilder` constraints; the `GridView` cross-axis/main-axis spacing trap; rule 5 — **no `NumberFormat` inside `build()`**, so the twenty-five labels are formatted once per (cells, locale) above the tiles; `ValueKey(value)` identity so a re-tap cannot act on a stale capture. |
| `accessibility-as-code` | The 48px target floor the gap step defends, `Semantics` on every tile carrying the **localized** numeral, the outright ban on `withClampedTextScaling`/`FittedBox`/`TextOverflow.ellipsis` to make a two-digit glyph fit, and the ≥3-non-hue-channel rule the state matrix satisfies. |
| `custom-canvas-and-gestures` | `NextRingPainter` is a `CustomPainter`: dumb, fed an immutable value, `shouldRepaint` as one value compare, zero allocation in `paint()`, invisible to semantics — and it must not read `Directionality`, because the ring is concentric and has no direction to follow. Also owns the LTR-pinned-subtree pattern the grid uses. |
| `dart3-idioms-and-coding-standards` | `SchulteTileState` is a payload-free `enum` switched exhaustively with no `default:`; `SchulteBoardState`/`SchulteRules`/`SchulteTileVisual` are hand-rolled `@immutable` `final class` values; `schulteScramble` and `repairNaturalPositions` are total and never throw. |
| `async-safety` | `tapCell`/`start` return `void` so the arrow-callback `Future`-drop hole is unreachable from `onTap`, and `ref.onDispose` cancels nothing the board should not own in the first place. |
| `persistence-drift` | T10.3 only, and only the in-memory engine: `NativeDatabase.memory()` with `addTearDown(db.close)` for the end-to-end scoring test. Also rule 5 — the run row stores `durationMs` as a canonical integer; localized numerals never reach the database. |
| `project-structure-and-packages` | T10.9's zero-lines proof is a structure claim: `lib/games/<id>/` holds the definition plus `application/`, `domain/` and `ui/`, `test/` mirrors `lib/` 1:1, and no file under `lib/features/**` may import a specific game. Supplies `check_import_boundaries.sh`. |

## Tasks

### T10.1 — Seeded scramble, rules table and locale-independent golden vectors

**Goal.** A frozen, pure, seeded scramble for an n×n Schulte board, plus the difficulty→grid-size
table, with the arithmetic that withholds Blitz recorded as a test — and with the locale-independence
of the whole generator asserted rather than assumed.

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
- `SplitMix64 matches its published vectors` — only if E07 did not already ship this test.

`test/games/schulte_grid/domain/schulte_scramble_locale_test.dart` — **the new locale gate**:
- `the scramble is identical under en, de, fa and ckb` — run `schulteScramble(seed: 42, size: 5)`
  inside `withLocale` for each of `Locale('en')`, `Locale('de')`, `Locale('fa')`,
  `Locale('ckb')` (or, since the generator takes no locale at all, inside a `ProviderContainer` with
  `localeProvider` overridden to each) and assert the four `List<int>` results are `==`. The point of
  the test is not that it can fail today — it is that it fails the day someone formats inside the
  generator.
- `no file under lib/games/schulte_grid/domain imports intl or AppLocalizations` — a source grep,
  because the previous test only catches a formatter that *changes* the output; one that stringifies
  identically in two locales would slip through.
- `the frozen vector table is locale-independent` — replay the whole vector table under all four
  locales; every fingerprint is unchanged.

`test/games/schulte_grid/domain/schulte_scramble_vectors.dart` + `..._vectors_test.dart`
- A committed `const List<SchulteScrambleVector>` of `(seed, size, fingerprint, firstCell,
  naturalPositions, note)`. Fingerprint is `fnv1a64(cells.join(','))`. Rows: seed 0, 1, 2, 42,
  999999, `0x7FFFFFFFFFFFFFFF` at size 5; seeds 0 and 1 at size 4; seeds 0..3 at size 3
  (hand-computed). Asserted with `==`, never a tolerance. `cells.join(',')` uses `int.toString()`,
  which is ASCII by definition and locale-invariant — state that in the header comment, because
  "join a list of numbers" is exactly where a well-meaning refactor would introduce a formatter.
- `production agrees with the independent oracle` — `test/games/schulte_grid/domain/schulte_oracle.dart`
  reimplements SplitMix64 in `BigInt` arithmetic and the shuffle as list-removal rather than in-place
  swaps; seeds 0..499 × sizes {3, 4, 5} must agree. The vector table's header comment states
  honestly that only the four hand-computed size-3 rows are a genuinely independent anchor; the rest
  are regression pins that prove "nothing changed", never "this is right".

`test/games/schulte_grid/domain/schulte_rules_test.dart`
- `forDifficulty is exhaustive and total` — chill→4, classic→5, blitz→6, with no `default:`.
- `schulteDifficulties is [chill, classic]` — Blitz is absent.
- `blitz is withheld, and the arithmetic says why` — three assertions, not one:
  `schulteCell(280, 6, 8) == 40.0` (320pt device, the retained conservative floor) is under
  `kPopMinTarget`; the shell's remaining lever (gutter 20→16) gives `schulteCell(288, 6, 8) == 41.33`,
  still short; **but** `schulteCell(335, 6, 8)` is `closeTo(49.17, 0.01)` — on the narrowest iPhone
  actually shipping (375pt, iPhone SE 2/3) the tap-target floor alone no longer withholds Blitz. The
  test records that honestly and points at T10.6, where the second reason lives: at that cell the
  inner box is 39.17pt and a two-digit Eastern Arabic numeral does not fit it at an accessible text
  scale. The reason lives in a test so it cannot be forgotten or overstated.

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

The PRNG is **E07's, at `lib/core/seeded_generator.dart`**: `fnv1a64`, `final class SeededGenerator`
(SplitMix64) and `seedFrom`. Import those names from that path. There is no `SeededRng`, no
`lib/core/random/`, no `lib/shared/determinism/`, and no "if E07 did not ship it" fallback — E07 is a
hard dependency and E09 already consumed the same three symbols. A second generator would give the two
games different draw sequences from the same seed and quietly void both frozen-vector tables.

`lib/games/schulte_grid/domain/schulte_rules.dart`: `final class SchulteRules` with
`final int gridSize`, `int get cellCount`, `static SchulteRules forDifficulty(Difficulty)`, and
`const List<Difficulty> schulteDifficulties = [Difficulty.chill, Difficulty.classic]`.

`tool/update_schulte_vectors.dart` rewrites the vector table and prints old-vs-new metrics per
changed row. CI never runs it.

**Files.** `lib/games/schulte_grid/domain/schulte_scramble.dart`,
`lib/games/schulte_grid/domain/schulte_rules.dart`, `tool/update_schulte_vectors.dart`,
`test/games/schulte_grid/domain/schulte_scramble_test.dart`,
`test/games/schulte_grid/domain/schulte_scramble_locale_test.dart`,
`test/games/schulte_grid/domain/schulte_scramble_vectors.dart`,
`test/games/schulte_grid/domain/schulte_scramble_vectors_test.dart`,
`test/games/schulte_grid/domain/schulte_oracle.dart`,
`test/games/schulte_grid/domain/schulte_rules_test.dart`.

**Skills.** `seeded-determinism-and-golden-vectors`, `testing-strategy`,
`dart3-idioms-and-coding-standards`, `sunburst-game-surfaces` (the 48px arithmetic), `i18n-rtl-l10n`
(the locale-independence boundary: generate integers, localize at render).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/schulte_grid/domain/` green.
- [ ] `.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib`
      exits 0 — no `Random()`, no `DateTime.now()` on the generation path.
- [ ] The vector table's header comment states which rows are independently derived **and** that
      fingerprints are locale-invariant by construction.
- [ ] `dart run tool/update_schulte_vectors.dart` produces a zero-line diff on a clean tree.
- [ ] `lib/games/schulte_grid/domain/` imports neither `package:intl` nor `AppLocalizations`.

**Commits.**
1. `feat(schulte): seeded scramble with a bounded natural-position repair` (+ its tests)
2. `test(schulte): freeze the scramble with golden vectors and a BigInt oracle` (+ `tool/update_schulte_vectors.dart`)
3. `test(schulte): the scramble and its vectors are identical in en, de, fa and ckb`
4. `feat(schulte): rules table — chill 4x4, classic 5x5, blitz withheld` (+ its tests)

---

### T10.2 — Tile state machine and board notifier

**Goal.** The five-state tile machine over one immutable board state, driven by a family `Notifier`
whose only intents are `start()` and `tapCell(int)`, holding integers and never a formatted string.

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
- `the state carries no formatted text` — every field of `SchulteBoardState` is an `int`, a `bool` or
  a `List<int>`; there is no `String` field. Asserted by a source grep in the same file, so the day
  someone caches a display label on the state — which would make it wrong the moment the locale
  changes — the test fails instead of the UI.
- `the same seed produces the same state under all four locales` — build the notifier in four
  containers with `localeProvider` overridden to `en`/`de`/`fa`/`ckb`; the resulting
  `SchulteBoardState` values are `==`.

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
`.autoDispose.family` — **copy the exact modifier shape E07/E09 used for the Stroop notifier**
rather than inventing one. The notifier does **not** watch `localeProvider`: a locale change must not
rebuild the board mid-run, because that would reroll the scramble under the player's hand.

**Files.** `lib/games/schulte_grid/domain/schulte_tile_state.dart`,
`lib/games/schulte_grid/domain/schulte_board_state.dart`,
`lib/games/schulte_grid/application/schulte_board_notifier.dart`,
`test/games/schulte_grid/application/schulte_board_notifier_test.dart`,
`test/games/schulte_grid/domain/schulte_board_state_test.dart`,
`test/support/fake_feedback_service.dart` (E05 T05.2's file — imported, never re-created; E09 uses the
same one).

**Skills.** `state-management-riverpod`, `dart3-idioms-and-coding-standards`, `testing-strategy`,
`async-safety`, `sunburst-motion-and-haptics`, `i18n-rtl-l10n` (why the state holds no `String`).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/schulte_grid/` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh` exits 0.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` exits 0 — no
      `Stopwatch(`, `Ticker(`, `Timer.periodic(` or `runNotifierProvider` under `lib/games/**`.
- [ ] Both intent methods return `void`.
- [ ] `SchulteBoardState` declares no `String` field, and the notifier does not watch `localeProvider`.

**Commits.**
1. `feat(schulte): immutable board state with a five-state tile machine` (+ its tests)
2. `feat(schulte): board notifier — start gate, in-order tap, wrong latch` (+ its tests)

---

### T10.3 — BoardSnapshot projection, localized HUD values and elapsed-time scoring

**Goal.** Publish the three HUD slots, the 0..1 progress and the terminal `outcome`, with every value
formatted through the one per-locale formatter and bidi-isolated, and prove the run lands in Results
formatted as a duration in each of the four locales.

**Tests first (TDD).** `test/games/schulte_grid/application/schulte_snapshot_test.dart`
- `slotA carries the Time label and an empty value` — the shell authors the clock (rule 4); a game
  that fills it would desynchronise across pause.
- `slotB renders the found/total pair per locale` — one expectation per locale, not one expectation
  plus a note. After six finds on a 25-tile board:

  | Locale | Expected `slotB.value` (isolate characters stripped for the assert) |
  |---|---|
  | `en` | `6 / 25` |
  | `de` | `6 / 25` |
  | `fa` | `۶ / ۲۵` |
  | `ckb` | `۶ / ۲۵` |

  and a second assertion on the raw string: under `fa`/`ckb` every digit rune is in
  U+06F0–U+06F9 — **not** U+0660–U+0669, which is the Arabic block and the wrong glyphs for a
  Persian or Sorani reader.
- `slotB is bidi-isolated` — the raw `slotB.value` begins with U+2066 (LRI) and ends with U+2069
  (PDI). Without it the spaces around the slash are neutrals that take the paragraph direction, and
  `۶ / ۲۵` renders as `۲۵ / ۶` inside an RTL line. This is the failure the isolate exists to prevent
  and it is invisible in an LTR test run, so it is asserted on the string, not eyeballed in a golden.
- `slotC is the next value, tone highlight, and is the only highlight` — `1` / `1` / `۱` / `۱` for
  en/de/fa/ckb at run start; assert exactly one slot is `HudTone.highlight` and that **no** slot is
  `HudTone.alarm` (the alarm is the shell's).
- `ckb does not silently fall back to Latin digits` — the named `ckb` test. `intl` ships no `ckb`
  number symbols, so an unpinned `NumberFormat.decimalPattern('ckb')` resolves to the default and
  emits `6 / 25`. Assert the U+06Fx block explicitly for `ckb`, separately from `fa`, so the pin is
  proven rather than inherited.
- `values round-trip through AsciiNumerals.normalize` — for every locale and every count 0..25,
  `int.parse(AsciiNumerals.normalize(stripIsolates(slotB.value).split('/').first.trim())) == foundCount`.
- `progress is foundCount / cellCount` — 6/25 == 0.24, matching `app.html`'s 24% track; 0.0 at start,
  1.0 exactly once. `progress` is a `double` and is **not** localized — it is geometry, not text.
- `outcome is null until the last tile and non-null exactly once` — driven from a seeded scramble.

`test/games/schulte_grid/schulte_run_scoring_test.dart` — the end-to-end scoring gate:
- `a completed Schulte run is persisted and reads back as a duration` — headless `ProviderContainer`
  with `clockProvider.overrideWithValue(Clock.fixed(...))` advanced by 18.6s and an in-memory drift
  database (`NativeDatabase.memory()`, `addTearDown(db.close)`); play 1..25; assert the persisted row
  exists and that its `durationMs` column is the ASCII integer `18600` — **never a formatted
  string** — then assert the shell's `ScoreFormat.duration` formatter renders it per locale: `18.6s`
  under `en`, a `,` decimal separator under `de`, and under `fa`/`ckb` the numeric run `۱۸٫۶` with the
  U+066B decimal separator followed by the unit from the shell's own ARB key. The unit word itself is
  E08's string, not this epic's; assert the numeric run and the digit block, and let E08's own test
  own the word.
- `an abandoned run persists nothing` — leave the run mid-board; assert no row.

**Implementation.** `lib/games/schulte_grid/application/schulte_snapshot.dart` exposing
`schulteSnapshotProvider`, a `Provider.autoDispose.family<BoardSnapshot, RunConfig>` that watches the
board notifier **and** `localeProvider`, and projects
`BoardSnapshot(hud: GameHud(slotA, slotB, slotC), progress: ..., outcome: ...)`. Labels come from
`AppLocalizations`; read it via `ref.watch(appLocalizationsProvider)`, which **E04 ships** in
`lib/l10n/` precisely because a snapshot provider has no `BuildContext`. There is no conditional here:
if it is missing, that is an E04 gap to fix in E04.

Numeric values are **pre-formatted Strings passed as ARB placeholders**, never `int` placeholders with
`"format": "decimalPattern"`. That is not a style preference: gen-l10n resolves a `decimalPattern`
placeholder through `intl`'s own symbol lookup for the message's locale, and `intl` has no `ckb`
symbols, so the `ckb` message would silently emit Latin digits while `fa` looked correct — the exact
defect D3 exists to prevent. Format with `ref.watch(localeNumbersProvider)` (E04's `LocaleNumbers`
with `ckb` pinned to `fa`), isolate with E04's `Bidi.isolateLtr`, then pass the resulting `String`:

```dart
final fmt = ref.watch(localeNumbersProvider);
final l10n = ref.watch(appLocalizationsProvider);
final found = l10n.schulteFoundValue(
  isolateLtr('${fmt.format(state.foundCount)} / ${fmt.format(state.cellCount)}'),
);
```

Before writing `outcome`, read how the shell derives the displayed score for `ScoreFormat.duration`
(`lib/features/results/`, `lib/features/stats/`, `lib/data/`). E07's `RunNotifier._finish` builds a
`RunDraft` carrying `durationMs: _ticker.elapsed.inMilliseconds` and calls
`runRepositoryProvider.saveRun(draft)`, which returns `Result<RunCommit, DataFailure>`. So the expected
shape is: Schulte returns `RunOutcome.completed(score: foundCount)` and the shell formats the run's
`durationMs` for a `ScoreFormat.duration` game. If the shell instead formats `outcome.score`, carry
elapsed milliseconds there. Whichever it is, the value crossing the seam is a canonical integer and
**zero features lines** change — see Risks.

**Files.** `lib/games/schulte_grid/application/schulte_snapshot.dart`,
`test/games/schulte_grid/application/schulte_snapshot_test.dart`,
`test/games/schulte_grid/schulte_run_scoring_test.dart`.

**Skills.** `sunburst-shell-screens`, `state-management-riverpod`, `i18n-rtl-l10n`,
`testing-strategy`, `persistence-drift` (in-memory engine only — read it if the scoring test needs
the DB harness E02 built).

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` and
`design/sunburst-pop/screens/rtl/05-schulte-grid.png` — HUD row only: three pills, labels
`Time` / `Found` / `Next`, the third on sunshine, and the progress track at 24%. In the RTL shot the
pill order mirrors (Time on the right) while the value inside each pill still reads left-to-right.
Compare structure → spacing rhythm → surface construction → type role → sampled hex.

**Done when.**
- [ ] Both test files green, with the per-locale expectations named above rather than a single
      English assertion.
- [ ] `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4` at classic difficulty shows
      `Found 0 / 25`, `Next 1` and an empty track in `en`, and `۰ / ۲۵` / `۱` in `fa` and `ckb`.
- [ ] Completing the board reaches Results with a duration-formatted score in all four locales.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` exits 0 over four ARBs.

**Commits.**
1. `feat(schulte): BoardSnapshot projection — three HUD slots and progress` (+ its tests)
2. `feat(schulte): HUD values through LocaleNumbers, bidi-isolated` (+ the four-locale tests)
3. `test(schulte): a completed run persists 18600ms and renders per locale`

---

### T10.4 — GameDefinition, artwork, registry entry and ARB keys in four locales

**Goal.** Make Schulte visible to all eight shell screens as **data**, by appending one line to the
registry — and give it a complete, parity-checked string set in `en`, `de`, `fa` and `ckb`.

**Tests first (TDD).** `test/games/schulte_grid/schulte_grid_definition_test.dart`
- `the registry exposes stroop_rush then schulte_grid, in that order`.
- `schulte declares decorative and gameAccent, and the two are in step` —
  `GameColourRole.decorative` ⇒ `BoardBackground.gameAccent`. No `switch` can catch a mismatch, so
  this test is the catch.
- `the accent is schulteTurquoise and resolves to gameSchulte / gameSchulteDeep`.
- `scoreFormat is ScoreFormat.duration`.
- `difficulties is [chill, classic]`.
- `every registry entry resolves a non-empty l10n title, tagline and kicker in every supported
  locale` — loops `gameRegistry` × `AppLocalizations.supportedLocales` (`en`, `de`, `fa`, `ckb`), so a
  future game that forgets an ARB key fails here rather than rendering blank on Home, and a locale
  that ships a key as an empty string fails too.
- `no localized Schulte string is identical to its English source in fa or ckb` — a crude but real
  untranslated-copy tripwire for the two locales nobody on the team reads. Proper nouns are exempted
  by an explicit allow-list of keys, and the allow-list is reviewed in the PR.
- `ink on the two Schulte fills clears 4.5:1` — pure-Dart WCAG on colour values:
  `textPrimary` on `gameSchulte` (7.2:1) and on `gameSchulteDeep` (5.1:1). Never `meetsGuideline` on
  pixels.

`test/games/schulte_grid/ui/schulte_artwork_test.dart`
- `the artwork renders inside 64x64 with no overflow at text scale 2.0` and declares no `Color`.
- `the artwork is direction-agnostic` — pumped under `TextDirection.ltr` and `TextDirection.rtl` the
  rendered geometry is identical. A 3×3 of mini-tiles with one accented has no reading order; if it
  mirrors, something in it used a physical side.

**Implementation.** `lib/games/schulte_grid/schulte_grid_definition.dart` — the `final
schulteGridDefinition = GameDefinition(...)` with `id: const GameId('schulte_grid')`,
`accent: GameAccent.schulteTurquoise`, `scoreFormat: ScoreFormat.duration`,
`difficulties: schulteDifficulties`, `boardBackground: BoardBackground.gameAccent`,
`buildBoard: (context, config) => SchulteBoard(config: config)`,
`buildArtwork: (context) => const SchulteArtwork()`,
`snapshotOf: (config) => schulteSnapshotProvider(config)`.

`lib/games/schulte_grid/ui/schulte_artwork.dart` — the 64pt Home-card tile: a 3×3 of nested
mini-tiles at `shape.borderWidthNested`, one of them `accent`. Decoration only, no `Color` literals,
`EdgeInsetsDirectional` only.

`lib/games/game_registry.dart` — append `schulteGridDefinition` to the list. One line.

`lib/l10n/app_en.arb` (template) **and every sibling `app_de.arb`, `app_fa.arb`, `app_ckb.arb`** — ten
keys. Copy the exact key shape E09 used for `game_stroop_rush_*`; do not invent a second convention.

| Key | Kind | Placeholders |
|---|---|---|
| `game_schulte_grid_title` | Home card / hero title | — |
| `game_schulte_grid_tagline` | Home card subtitle | — |
| `game_schulte_grid_kicker` | Detail screen kicker | — |
| `schulteFoundLabel` | HUD slot B label | — |
| `schulteFoundValue` | HUD slot B value | `{pair}` **String**, pre-formatted + isolated |
| `schulteNextLabel` | HUD slot C label | — |
| `schulteNextValue` | HUD slot C value | `{value}` **String**, pre-formatted + isolated |
| `schulteTileLabel` | tile `semanticLabel` | `{value}` **String** |
| `schulteNextTileHint` | `Semantics(hint:)` on the `next` tile | — |
| `schulteFoundTileLabel` | tile `semanticLabel` once found | `{value}` **String** |

Every numeric placeholder is typed `String`, not `int` with `"format": "decimalPattern"` — see T10.3
for why `ckb` breaks under the `int` form. Each key carries an `@key` block with a `description`
written for a translator who cannot see the screen ("HUD label above the count of tiles already
found; fits a 100pt pill at text scale 1.3").

`de` is authored as the length stress case: German is the longest of the four and `schulteFoundLabel`
/ `schulteNextLabel` are the two strings the three-across HUD row has least room for. If a German
label does not fit at text scale 1.3, the fix is the smaller BASE style in T10.6 — never a shorter
translation invented to fit, and never an ellipsis.

**Files.** `lib/games/schulte_grid/schulte_grid_definition.dart`,
`lib/games/schulte_grid/ui/schulte_artwork.dart`, `lib/games/game_registry.dart`,
`lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`, `lib/l10n/app_ckb.arb`,
`test/games/schulte_grid/schulte_grid_definition_test.dart`,
`test/games/schulte_grid/ui/schulte_artwork_test.dart`.

**Skills.** `sunburst-shell-screens`, `sunburst-game-surfaces`, `i18n-rtl-l10n`, `sunburst-tokens`,
`widget-golden-and-a11y-testing`.

**Screenshot check.** `design/sunburst-pop/screens/01-home.png` and
`design/sunburst-pop/screens/rtl/01-home.png` — the second game card: turquoise fill behind a 3px ink
border, the cream art frame and its tile, the "2 unlocked" section label, and the BEST pill; in the
RTL shot the card's internal row order mirrors while the artwork does not. Also
`02-game-detail.png` and `rtl/02-game-detail.png` for the turquoise hero, checking that the difficulty
list renders two rows without the segmented control looking broken in either direction. Compare
structure → spacing rhythm → surface construction → type role → sampled hex.

**Done when.**
- [ ] Home shows two unlocked cards in all four locales; the diff to `lib/features/**` is still empty.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean —
      `nullable-getter: false` makes a missing key a compile error.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` exits 0: four files, same
      keys, same placeholder names.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` exits 0.
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` exits 0.
- [ ] The `fa` and `ckb` strings are flagged in the PR as **awaiting native review** (see Risks).

**Commits.**
1. `feat(l10n): Schulte Grid strings in en, de, fa and ckb`
2. `feat(schulte): GameDefinition and Home artwork` (+ its tests)
3. `feat(games): register Schulte Grid`

---

### T10.5 — Eastern Arabic numerals on the tiles, and the grid's direction

**Goal.** Render the tile value through the one per-locale formatter, and record — with a test — the
decision that the grid does not mirror while everything around it does.

**The decision, and its reasoning.** A Schulte grid is a **visual search field**, not a text flow. The
numbers are placed by a scramble that is uniform over positions; there is no first cell, no reading
order, and the whole point of the exercise is that the player cannot scan systematically. Mirroring it
would therefore convey nothing to a Persian or Sorani player that it does not already convey — a
mirrored scramble is just another scramble — while costing three real things:

1. **Cell index would stop meaning a screen position.** `cells[0]` is top-left in `en` and top-right
   in `fa`, so every geometry assertion, every `getRect` test, the reference PNG, and the golden
   vector's relationship to what is on screen all fork per direction.
2. **The reference screenshots would fork for no visual reason.** `rtl/05-schulte-grid.png` already
   differs from `05-schulte-grid.png` in the chrome; a mirrored board would additionally make the
   board interior locale-dependent, and the board interior is the one part of this screen that is
   supposed to be identical everywhere.
3. **Nothing in the numeral mirrors either.** `۲۵` is written most-significant-digit-first, exactly
   like `25`; a two-digit Eastern Arabic numeral is an LTR run inside an RTL paragraph. So the cell's
   *content* does not mirror even when the page does.

The counter-argument is real and is recorded rather than dismissed: a Persian reader's habitual first
glance is top-right, so under `fa` the player's eye starts on `cells[4]` rather than `cells[0]`. That
is a difference in where a *bad* strategy starts, not in the task — Schulte is practised with a fixed
central gaze — and it is not worth the three costs above. If a native reviewer disagrees, the change is
one `Directionality` island and a second reference PNG, and it is E11's to make.

`GridView` mirrors its cross axis from the ambient `Directionality`, so "does not mirror" is not the
default and is not free: the grid subtree is pinned `Directionality(textDirection: TextDirection.ltr)`
— the sanctioned locale-invariant-coordinate-space island from `i18n-rtl-l10n` — and everything
outside it (HUD, top bar, progress track, pause affordance) mirrors from the locale as usual.

**Tests first (TDD).** `test/games/schulte_grid/ui/schulte_tile_label_test.dart` (pure)
- `schulteTileLabel formats through the locale's own numbering system` — for values 1..25:

  | Locale | `1` | `7` | `25` |
  |---|---|---|---|
  | `en` | `1` | `7` | `25` |
  | `de` | `1` | `7` | `25` |
  | `fa` | `۱` | `۷` | `۲۵` |
  | `ckb` | `۱` | `۷` | `۲۵` |

- `fa and ckb emit the Persian block, never the Arabic block` — every rune of every `fa`/`ckb` label
  is in U+06F0–U+06F9. A label containing U+0660–U+0669 fails. **This is the named digit-block test.**
- `no tile label carries a grouping separator` — `25` must never become `۲۵` with a thousands mark or
  `de`'s `.`; the values are 1..25, but the assertion pins the formatter's configuration rather than
  the arithmetic.
- `every label round-trips` — `int.parse(AsciiNumerals.normalize(label)) == value` for all four locales and
  all 25 values.
- `labels are formatted once per (cells, locale), not per tile` — the label list is built above the
  tiles; a `NumberFormat` construction inside a tile `build()` is a `widget-composition` rule 5
  violation and a per-frame allocation on 25 widgets.

`test/games/schulte_grid/ui/schulte_grid_direction_test.dart`
- `the grid does not mirror` — pump the board under `Locale('fa')` and under `Locale('en')`; assert
  `tester.getTopLeft(find.byKey(ValueKey(cells[0])))` is the same offset in both, and that the tile
  at the visual top-left holds the same *value* in both. **This is the named direction test.**
- `the chrome around the grid does mirror` — the same pump asserts the HUD row's slot order is
  reversed under `fa`. (The HUD is the shell's; this asserts the board did not accidentally pin its
  own ancestors LTR.)
- `the hard offset shadow does not mirror` — resolve the tile's `BoxShadow` under `fa` and assert
  `offset == Offset(3, 3)` for e1, unchanged from `en`. The shadow is a light-source constant, not a
  reading-direction property; the same holds for the found tile's resting translate `(2, 2)` and for
  `NextRingPainter`, which is concentric and reads no direction at all. Asserted on values, because it
  is the thing a reviewer will query and a golden alone cannot answer.
- `no physical-side geometry survives in the board subtree` — a source grep over
  `lib/games/schulte_grid/` for `EdgeInsets.only(left:`, `Alignment.centerLeft`, `TextAlign.left`,
  `Positioned(left:` and `BorderRadius.only(topLeft:`. This mirrors `check_i18n_bans.sh` into
  `flutter test` so CI catches it even if a gate script is dropped.

**Implementation.**
`lib/games/schulte_grid/ui/schulte_tile_label.dart` — pure:
`List<String> schulteTileLabels(List<int> cells, NumberFormat fmt)`, returning one already-formatted
label per cell. No `intl` locale lookup here; the caller supplies E04's formatter, so `ckb`'s pin to
`fa` is honoured in exactly one place in the app.

`SchulteGrid` reads `ref.watch(localeNumbersProvider)` once, computes the label list once, and hands
each `const SchulteTile` its own `String`. The tile's `semanticLabel` is `l10n.schulteTileLabel(label)`
— the localized numeral, so VoiceOver in Persian reads `۷` and not `7`.

The grid subtree is wrapped:

```dart
// The board is a coordinate space, not a text flow: cells[i] must sit at the same
// screen position in every locale (see the decision above). The chrome outside this
// island still mirrors from the resolved locale.
Directionality(
  textDirection: TextDirection.ltr,
  child: SchulteGrid(...),
)
```

The Arabic-script face reaches the glyph through `SunburstType`'s per-locale `fontFamilyFallback`
cascade, declared in `lib/theme/` by E04. Nothing under `lib/games/**` names a font — a `fontFamily:`
there fails `check_raw_values.sh`, and that ban is the point.

**Files.** `lib/games/schulte_grid/ui/schulte_tile_label.dart`, edits to
`lib/games/schulte_grid/ui/schulte_board.dart` and `lib/games/schulte_grid/ui/schulte_tile.dart`,
`test/games/schulte_grid/ui/schulte_tile_label_test.dart`,
`test/games/schulte_grid/ui/schulte_grid_direction_test.dart`.

**Skills.** `i18n-rtl-l10n`, `widget-composition`, `custom-canvas-and-gestures` (the LTR-pinned
subtree), `accessibility-as-code`, `sunburst-tokens`.

**Screenshot check.** `design/sunburst-pop/screens/rtl/05-schulte-grid.png` — the whole point of this
task is visible in that file and in no other: the top bar, HUD row and progress track mirrored, the
board interior identical to `05-schulte-grid.png` except that the glyphs are `۱`–`۲۵`, and the hard
shadow still falling down-and-right on every tile.

**Done when.**
- [ ] Both test files green with the per-locale label table asserted, not sampled.
- [ ] On `MindForge iPhone 14`, switching Settings → Language between the four locales re-renders the
      board live, with no restart and no throw — including `ckb`.
- [ ] No tofu box on any tile in `fa` or `ckb`.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` exits 0.
- [ ] The no-mirror decision and its counter-argument are in the PR body, not only in this file.

**Commits.**
1. `feat(schulte): tile labels through the per-locale numeral formatter` (+ its tests)
2. `feat(schulte): pin the grid LTR — the board is a coordinate space, not a text flow` (+ its tests)

---

### T10.6 — The board widget, computed cell sizing and the per-locale glyph fit

**Goal.** A square 4×4 or 5×5 board sized from the slot's constraints against the 48px floor, that
re-applies neither the gutter nor the background the shell already painted — and whose glyph is
proven to fit inside the cell **in every locale**, at every supported text scale, with no clamp.

**Tests first (TDD).**
`test/games/schulte_grid/ui/schulte_grid_metrics_test.dart` (pure, no widget binding) — the table
from `references/board-states-and-layout.md`, `closeTo(x, 1e-9)`. **The cell is locale-invariant**:
it is derived from the slot, not from a glyph, and this table is asserted once.

| side | columns | expected gap | expected cell |
|---|---|---|---|
| 280 (320pt screen, conservative floor) | 5 | 8 | 49.6 |
| 320 (360pt) | 5 | 12 | 54.4 |
| 335 (375pt, iPhone SE 2/3 — narrowest shipping iPhone) | 5 | 12 | 57.4 |
| 350 (390pt, the canonical simulator) | 5 | 12 | 60.4 |
| 390 (430pt) | 5 | 12 | 68.4 |
| 280 | 4 | 12 | 61.0 |
| 280 | 6 | 8 | 40.0 — below `kPopMinTarget` |
| 335 | 6 | 8 | 49.17 — clears the floor; see T10.1's honest note |

- `the gap step is derived from the floor, not from a width` — assert `schulteGap` returns 12 exactly
  when `schulteCell(side, n, 12) >= kPopMinTarget` and 8 otherwise, for a sweep of sides 240..440.

`test/games/schulte_grid/ui/schulte_glyph_fit_test.dart` — **the new per-locale gate**, `loadAppFonts()`
in `setUpAll` because Ahem's fixed em-square would make every locale identical and the test worthless:
- `the widest label of each locale fits the inner box` — for each device, each locale, and each text
  scale in {1.0, 1.3, 2.0}: build the 25 labels, `TextPainter`-measure **all of them** (the widest is
  not assumed to be `25` — in an Arabic-script face it may not be), and assert both `width` and
  `height` of the widest are ≤ the inner box (`cell − 2×borderWidth − 2×2` padding: 39.6 at 320pt,
  44.4 at 360pt, 47.4 at 375pt, 50.4 at 390pt, 58.4 at 430pt).
- `the base style steps down rather than being clamped` — where the `numericHud` (22) measurement
  exceeds the box, assert the chosen style is `button` (18) and that `MediaQuery.textScalerOf` was
  applied on top of it. Assert the absence of `FittedBox`, `TextOverflow.ellipsis` and
  `withClampedTextScaling` anywhere in the subtree.
- `the fit outcome is recorded per locale` — the test prints a table of (device × locale × scale →
  chosen style, measured width, box width) via `printOnFailure`, and the PR body carries the run. This
  is a **measurement, not an assumption**: whether an Eastern Arabic two-digit label at 18pt fits a
  39.6pt box depends on the face E04 selected, and this epic must not guess it.
- `the 6x6 inner box cannot hold a two-digit fa/ckb label` — the second, locale-driven reason Blitz is
  withheld even on a 375pt device where the tap floor clears: measure at cell 49.17 → inner 39.17 and
  record the result. If it *does* fit, say so in the PR and hand Blitz to E11 as an open scope
  question rather than repeating an argument the numbers no longer support.

`test/games/schulte_grid/ui/schulte_board_test.dart` — **one `testWidgets` per (device, scale, locale)
tuple, never a loop inside a test** (overflow reports once per RenderObject):
- devices 320×640, 360×800, 375×667, 390×844, 430×932, all at **DPR 2** (E03's presets, the geometry
  `capture-screens.sh` rendered the reference PNGs at) — via `useDevice` + `pumpApp` with
  `addTearDown(view.reset)`; the board is pumped inside a `SizedBox` matching `_BoardPane`'s slot
  (screen width − 2×20 gutter). 320 is retained as a conservative floor below anything iOS ships,
  because it is what keeps the gap derivation honest.
- each asserts: 25 `SchulteTile`s present; every `getSize` is square and ≥ 48 on both axes; tiles in
  a row share `top` and tiles in a column share `left` (`moreOrLessEquals`, epsilon 0.5);
  `tester.takeException()` is null.
- the locale axis is `en` / `de` / `fa` / `ckb`; the scale axis is 1.0 / 1.3 / 2.0 on 360, 375 and 390.
- `the board applies no gutter and no background` — no `ColoredBox` and no `SafeArea` descendant of
  `SchulteBoard`, and no `Padding` equal to `SunburstShape.gutter` on the board's own subtree.
  `_BoardPane` owns both.
- `the grid does not clip` — the `GridView`'s `clipBehavior` is `Clip.none`, or the e1 shadow and the
  5pt ring are sheared off.
- `a tap routes to tapCell with the tapped index` — with an overridden notifier, under `fa` as well as
  `en`, proving the LTR-pinned island did not desynchronise pointer mapping from paint.
- `tiles are keyed by value` — `ValueKey(value)`, so a re-tap cannot act on a stale capture.

**Implementation.**
`lib/games/schulte_grid/ui/schulte_grid_metrics.dart` — pure:
`double schulteCell(double side, int columns, double gap)` and
`double schulteGap(double side, int columns)` returning `SunburstShape.space3` (12) unless that drops
the cell under `kPopMinTarget`, then `SunburstShape.space2` (8).

`lib/games/schulte_grid/ui/schulte_board.dart` — `SchulteBoard extends ConsumerWidget`: a
`LayoutBuilder` → `SizedBox.square(dimension: min(maxWidth, maxHeight))` → the LTR island from T10.5 →
`SchulteGrid`. **No `ColoredBox`, no gutter `Padding`, no `SafeArea`.**
`SchulteGrid` — `GridView.builder` with `shrinkWrap: true`,
`physics: const NeverScrollableScrollPhysics()`, `clipBehavior: Clip.none`,
`SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: columnCount, crossAxisSpacing: gap,
mainAxisSpacing: gap)`, `key: ValueKey(cells[i])`, `onTap: () => ref.read(provider.notifier).tapCell(i)`.
`SchulteGrid` watches the whole `SchulteBoardState`; per-tile `.select` is deliberately not used —
25 const tiles rebuild for free, and `flutter-performance` says measure before optimising.

`lib/games/schulte_grid/ui/schulte_tile.dart` — `SchulteTile` composing **E05's `PopGridTile`**, not
`PopSurface` directly. E05 T05.8 shipped `PopGridTile` with
`enum PopGridTileState { idle, next, found, wrong, disabled }` — the Schulte machine exactly — plus five
state goldens, the greyscale state-collision proof, the double ring on `next`, the permanent `(2,2)`
found offset, the `borderDisabled` e1 shadow and the 64→60 adaptive sizing. Composing it means this epic
inherits all of that instead of rebuilding it, and the catalog does not carry a fourteenth class nothing
uses. `SchulteTile` therefore does four things: map `SchulteTileState` onto `PopGridTileState` (a 1:1
map, both enums carry the same five cases), pass the **already-localized label** and the
`semanticLabel`, and wrap the whole tile in E06's `ShakeOnWrong` keyed on `wrongTapId`. There is **no
`schulte_tile_visual.dart`** — the resolver is `PopGridTile`'s public `visualFor`, and T10.7's
channel-count test asserts against that one function so the proof exists in a single place.
`TileGlyph` measures the label against the inner box and steps `type.numericHud` → `type.button` —
never `FittedBox`, never a clamped scaler, never `fontSize:`. The measurement uses the label it is
actually going to paint, so the step fires on the Persian string when the Persian string is what is
wide.

**Files.** `lib/games/schulte_grid/ui/schulte_grid_metrics.dart`,
`lib/games/schulte_grid/ui/schulte_board.dart`, `lib/games/schulte_grid/ui/schulte_tile.dart`,
`lib/games/schulte_grid/ui/next_ring_painter.dart`,
`test/games/schulte_grid/ui/schulte_grid_metrics_test.dart`,
`test/games/schulte_grid/ui/schulte_glyph_fit_test.dart`,
`test/games/schulte_grid/ui/schulte_board_test.dart`.

**Skills.** `sunburst-game-surfaces`, `sunburst-components`, `widget-composition`,
`widget-golden-and-a11y-testing`, `accessibility-as-code`, `custom-canvas-and-gestures`,
`i18n-rtl-l10n`.

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` and
`design/sunburst-pop/screens/rtl/05-schulte-grid.png` — board interior: 5 columns, 12pt gaps,
`radiusMd` 16 corners, 3px ink border, e1 hard shadow with zero blur, found tiles at
`gameSchulteDeep` offset (2,2) with no shadow, the `next` tile on `accent` with a 2pt cream then 3pt
ink ring, and the board inset (gutter 20 / top 20 / bottom 26) painted by `_BoardPane`. The two files
must differ **only** in the glyph block and in the chrome above the board. Compare structure →
spacing rhythm → surface construction → type role → sampled hex.

**Done when.**
- [ ] Every (device × scale × locale) test green with no overflow.
- [ ] The glyph-fit table is recorded in the PR body, per locale, with the chosen base style per cell.
- [ ] `.claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` exits 0.
- [ ] `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` exits 0.
- [ ] `.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib` exits 0.
- [ ] `.claude/skills/widget-composition/scripts/check-widget-composition.sh` exits 0.
- [ ] Every tile at 320pt measures ≥ 48pt on both axes on the simulator, in all four locales.

**Commits.**
1. `feat(schulte): cell and gap derived from the slot against the 48px floor` (+ metrics tests)
2. `feat(schulte): the board — square grid, tile and next-tile ring` (+ widget tests)
3. `test(schulte): geometry at 320/360/375/390/430 x scale 1.0/1.3/2.0 x en/de/fa/ckb`
4. `test(schulte): measured glyph fit per locale, with the base-style step recorded`

---

### T10.7 — Tile state channels, goldens and semantics

**Goal.** Make "every state differs in ≥3 non-hue channels" an asserted number rather than a claim,
and back it with a greyscale golden, a real-font Persian golden and a screen-reader pass in four
locales.

**Tests first (TDD).** `test/games/schulte_grid/ui/schulte_tile_visual_test.dart`
- `the state map is a total bijection onto PopGridTileState` — every `SchulteTileState` maps to a
  distinct `PopGridTileState` and every `PopGridTileState` is reached; an exhaustive `switch` with no
  `default:`, so a sixth Schulte state is a compile error rather than a silently reused tile.
- `every ordered pair of distinct states differs in at least three non-hue channels` — loop
  `SchulteTileState.values` × itself, resolve each through `popStateOf` into **E05's `visualFor`**, and
  for each pair count differences across `{elevation, offset, scale, borderColor, glyphColor, hasRing}`;
  assert ≥ 3 with the pair printed in `reason:`. **This is the greyscale guarantee**, and it is asserted
  against the one resolver both the catalog and this game read.
- `no state is distinguished by fill alone`.
- `no state is distinguished by direction` — `visualFor` returns the same value under `ltr` and `rtl`.
- `found and disabled recede by fill, never by opacity` — `visualFor` exposes no opacity, and the
  widget test asserts no `Opacity` descendant of `SchulteTile` in any state.
- `disabled keeps an e1 shadow repainted in borderDisabled` — not `flat`; matching
  `.btn[disabled]{box-shadow:3px 3px 0 var(--ink-3)}` and every other disabled surface.
- contrast, pure Dart WCAG on values: `textPrimary` on `surface` ≥ 4.5, on `accent` ≥ 4.5, on
  `gameSchulteDeep` ≥ 4.5 (5.1:1); `surfaceRaised` on `danger` ≥ 4.5 (5.07:1); `textDisabled` on
  `surfaceSunk` ≥ 3.0 (3.40:1) with the WCAG 1.4.3 disabled-control exemption named in `reason:`.

`test/games/schulte_grid/ui/schulte_tile_golden_test.dart`, `@Tags(['golden'])`, `loadAppFonts()`
- **Ahem geometry lane**: one golden per `SchulteTileState` (5 files), LTR, `en`. Proves depth,
  offset, ring and border geometry; proves nothing about glyphs.
- **Real-font lane, pinned OS**: one golden of the full board mid-run at 390×844 under `en`, and one
  under `fa`. The `fa` file is the only artefact in the repository that proves the Persian numerals
  actually shape and that the bundled Arabic-script face is reached — Ahem renders no Persian digit,
  so this lane may never be run with it.
- **`ckb` real-font lane**: the same board under `ckb`. Its tiles are digits, so it should be
  byte-identical to the `fa` board; assert that, because a difference means the `ckb` locale resolved
  a different fallback face and the two locales would drift apart on every other screen too.
- **Greyscale lane**: the `en` board through a saturation-0 `ColorFiltered`. The review question is
  "what state is every tile in?" answered from that file alone.
- **RTL chrome lane**: the board plus its HUD under `Locale('fa')`, confirming the chrome mirrors, the
  grid does not, and the ring and hard shadow do not.

`test/games/schulte_grid/ui/schulte_a11y_test.dart`, per locale
- `every tile is labelled with its number in the active locale` — `find.bySemanticsLabel('7')` under
  `en`/`de` and `find.bySemanticsLabel('۷')` under `fa`/`ckb`. A Persian UI that speaks `7` to
  VoiceOver is the audio equivalent of a Latin-digit tile.
- `an idle tile is a button and a found tile is not` — a resolved tile drops `onTap`.
- `the next tile carries its cue in a non-visual channel` — the ring is invisible to a screen reader,
  so the next tile carries `schulteNextTileHint`; a found tile carries `schulteFoundTileLabel`.
- `traversal is reading order, and reading order is grid order in every locale` — 
  `simulatedAccessibilityTraversal` yields the cells in index order 0..n²−1 under all four locales,
  because the grid is LTR-pinned and its traversal must agree with its paint. A traversal that
  reverses under `fa` while the paint does not is the exact desynchronisation the pin exists to
  prevent, so this assertion is the pin's screen-reader half.
- `await expectLater(tester, meetsGuideline(androidTapTargetGuideline))` as an advisory tripwire only
  — the `getSize` loop in T10.6 is the gate.

**Implementation.** The visual resolver is **E05's**: `PopGridTileVisual visualFor(PopGridTileState,
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
off against `system.html` §10/§11 and the state matrix, and that limit is stated in the PR body. The
`fa` state colours are compared against `design/sunburst-pop/screens/rtl/05-schulte-grid.png` — the
hexes are identical by construction, and any difference means the theme read a locale.

**Done when.**
- [ ] The channel-count test passes for all 20 ordered pairs.
- [ ] The greyscale golden answers "what state is every tile in" with no colour.
- [ ] The `fa` real-font golden shows shaped Persian numerals and no tofu; the `ckb` golden is
      byte-identical to it.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` exits 0.
- [ ] No `Opacity`, `withOpacity`, `FittedBox`, `TextOverflow.ellipsis` or `withClampedTextScaling`
      anywhere under `lib/games/schulte_grid/`.
- [ ] Goldens were blessed in the pinned environment only; CI runs no `--update-goldens`.

**Commits.**
1. `feat(schulte): the tile state map onto PopGridTile` (+ the channel-count test)
2. `feat(schulte): semantics for idle, next, found and disabled tiles, per locale` (+ a11y tests)
3. `test(schulte): tile, board, greyscale, fa/ckb real-font and RTL-chrome goldens`

---

### T10.8 — Motion and haptics

**Goal.** Wire `tileFound`, `tileNextCue` and `answerWrong` with one haptic per tap and an end state
that survives reduce motion — and that does not change with the locale.

**Tests first (TDD).** `test/games/schulte_grid/ui/schulte_tile_motion_test.dart`
- `a correct tap fires exactly one moment` — `Moment.tileFound`; `tileNextCue` fires none, because
  two tiles changing is still one committed event. A rattle on a 25-tile board is the bug.
- `a wrong tap fires Moment.answerWrong exactly once and never heavyImpact` — `heavyImpact` is spent
  on `Moment.personalBest` and nowhere else.
- `the shake runs exactly two cycles and stops` — `pump(motion.durCelebrate)` twice, then assert the
  translation is back to zero. Never `pumpAndSettle`.
- `the shake axis does not mirror` — under `Locale('fa')` the shake is still ±4px on the horizontal
  axis with the same sign sequence as under `en`. A shake is a physical wobble, not a directional
  gesture; mirroring it would be a change nobody asked for and one no golden would catch.
- `under MediaQuery.disableAnimations the tile is at its end state on the first pump` — reduce motion
  collapses to `Duration.zero`, never to a shorter duration; the shake is skipped entirely and the
  `danger` fill + paper glyph is the residue that carries the meaning.
- `a found tile rests at pressTranslate(e1) = (2,2) with no shadow, under reduce motion too, in every
  locale` — the resting offset is state, not animation, and it is not mirrored.
- `disposing mid-shake does not resume` — pump one cycle, dispose, assert no pending timer.

**Implementation.** `SchulteTile` gets an `AnimatedContainer` over `motion.resolve(context,
motion.durState)` on `motion.easeOut` for the fill/shadow cross, and is wrapped in **E06's
`ShakeOnWrong` from `lib/shared/motion/shake_on_wrong.dart`**, keyed on `wrongTapId`. That is the one
copy in the repository — E06 T06.8 created it and E09's answer key wraps the same widget. Do not add
one under `lib/games/**` and do not create `lib/ui/motion/`; E06 T06.9's policy test fails on a second
declaration. Every duration and curve is read off `SunburstMotion.of(context)`; the haptic is fired
from the notifier through `ref.read(feedbackServiceProvider).fire(...)`, never `HapticFeedback.*`.

**Files.** edits to `lib/games/schulte_grid/ui/schulte_tile.dart`,
`test/games/schulte_grid/ui/schulte_tile_motion_test.dart`. (No new file: the shake is E06's.)

**Skills.** `sunburst-motion-and-haptics`, `sunburst-tokens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `async-safety`.

**Screenshot check.** n/a — `05-schulte-grid.png` and `rtl/05-schulte-grid.png` are end states only
and cannot verify motion, press physics or haptics. The two motion consequences that *are* end states
— the found tile's resting (2,2) offset and the `next` tile's ring — are compared in T10.6 and T10.7.

**Done when.**
- [ ] `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` exits 0 — no
      raw `Duration(`/`Curves.`/`Cubic(` and no `HapticFeedback.` under `lib/games/**`.
- [ ] One tap on the simulator's paired device produces exactly one haptic tick. (Haptics cannot be
      felt on the Simulator; this box is ticked on hardware or it is explicitly deferred to E11's
      device pass and said so in the PR.)
- [ ] With Reduce Motion on, the board is still fully playable and every state still readable, in all
      four locales.

**Commits.**
1. `feat(schulte): tileFound, tileNextCue and the wrong-tap shake` (+ its tests)

---

### T10.9 — The zero-lines proof

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
- `no ARB key names a game outside its own game_<id>_* prefix` — the shell's own strings must not
  have grown a Schulte-specific message; if one did, the shell is naming a game in a fifth place the
  greps above do not reach.

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
  echo "      The fix is a game-agnostic widening of GameDefinition/BoardSnapshot in E07,"
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
this epic found a seam defect owned by E07.

**Files.** `test/policy/engine_seam_test.dart`, `tool/check_no_shell_edits.sh`.

**Skills.** `sunburst-shell-screens`, `testing-strategy`, `project-structure-and-packages`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/policy/` green.
- [ ] `bash tool/check_no_shell_edits.sh` prints `OK` and its output is in the PR body.
- [ ] `git diff --stat $(git merge-base origin/main HEAD)...HEAD` shows changes only under
      `lib/games/schulte_grid/`, `lib/games/game_registry.dart` (one line), `lib/l10n/app_*.arb`,
      `test/` and `tool/`. **Nothing under `lib/core/`, `lib/shared/`, `lib/theme/` or `lib/ui/`** — the
      PRNG is E07's, the shake is E06's, the tile is E05's, and `appLocalizationsProvider`,
      `LocaleNumbers`, `Bidi.isolateLtr` and the per-locale font cascade are E04's. A diff touching any of
      them means this epic rebuilt something it should have imported; fix that before the PR, or, if
      the shared component genuinely could not express the need, widen it game-agnostically and say so.

**Commits.**
1. `test(policy): the shell may never name a specific game`
2. `chore(tool): check_no_shell_edits.sh — a game adds zero lines to lib/features`

---

### T10.10 — Screenshot sign-off for 05 in both directions, and the 04 regression re-check

**Goal.** Sign the board off against both its references, and prove the shared chrome did not regress
on the game that already shipped, in both directions.

**Tests first (TDD).** Not TDD-able as a `dart test`: this is a human visual comparison against a
rendered PNG, and everything about it that a test *can* express — geometry, contrast, semantics,
numerals, goldens — is already asserted in T10.5–T10.8. The one automatable piece is added first: a
reference-board golden per direction, so the comparison is reproducible rather than dependent on
whatever seed the tester happened to play.

`test/games/schulte_grid/ui/schulte_reference_board_golden_test.dart`, `@Tags(['golden'])`,
`loadAppFonts()`
- `the reference board renders at 390x844 in en` — construct `SchulteBoardState` directly with the
  exact cells from `app.html` screen 05 (`14,3,22,9,17 / 6,25,11,1,20 / 19,8,15,4,12 / 2,23,7,18,10 /
  21,13,5,24,16`) and `nextValue: 7`, so six tiles are `found`, one is `next`, and the golden is
  byte-comparable with the reference by eye.
- `the reference board renders at 390x844 in fa` — the same state, the same seed, the same six found
  tiles, the same `next` tile, rendered under `Locale('fa')`. This is the file that goes beside
  `design/sunburst-pop/screens/rtl/05-schulte-grid.png`.

**Implementation.** Procedure, not code:
1. Boot the canonical device and run on it — nothing else is a valid comparison surface:
   ```bash
   xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4     # MindForge iPhone 14, iOS 18.6, 390x844
   flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
   ```
   iPhone 16 (393×852) and 16 Pro (402×874) do **not** match the reference geometry; using one makes
   every spacing comparison a guess.
2. Run the two reference-board goldens and open each beside its PNG:
   `05-schulte-grid.png` for `en`, `rtl/05-schulte-grid.png` for `fa`.
3. Play Schulte at Classic on the simulator in `en`, screenshot the play screen; switch Settings →
   Language to فارسی and screenshot it again. Note that the simulator rasterises at 3× while the
   reference PNGs were rendered at 2× — this comparison is structure, spacing, construction, type
   role and sampled hex, never a pixel diff, so the raster scale is irrelevant and must not be
   "corrected" by rescaling either image.
4. Compare, in this order — **structure** (same regions, same order, same relative heights: status
   strip, top bar with pause glyph + title + difficulty chip, turquoise play band with rays and
   halftone dots, HUD row, progress track, board pane) → **spacing rhythm** (gutter 20, board top 20,
   board bottom 26, tile gap 12) → **surface construction** (3px ink border and the correct hard
   shadow step everywhere; zero blur; zero spread) → **type role** (display face on the tile glyph,
   tabular figures, HUD label vs value steps) → **sampled hex** (`#FFF8EC`, `#12A79A`, `#FFC53D`,
   `#22C7B8`, `#2B1B4D`).
5. In the `fa` pass, additionally confirm: chrome mirrored, board **not** mirrored, glyphs `۱`–`۲۵`
   with no tofu, `۶ / ۲۵` in the found pill reading count-then-total, hard shadow still down-right.
   Repeat the pass in `ckb` and in `de`; `ckb` is checked for the same things plus "nothing threw on
   the locale switch", and `de` is checked for label fit in the HUD row at text scale 1.3.
6. **Re-check `04-stroop-rush.png` and `rtl/04-stroop-rush.png`.** The top bar, chip, play band
   height, HUD row and track are shared code; anything this epic changed in `lib/l10n/` can move them
   — a new ARB key cannot, but an edited shared one can, and a bad merge can. Run Stroop at 390×844 in
   `en` and `fa` and compare against both references. Any difference is a regression introduced here.
7. Copy `.claude/skills/sunburst-game-surfaces/templates/new_game_visual_checklist.md` into the PR
   body and tick it in order, once per direction.
8. A difference is an implementation defect. If a reference is genuinely wrong, edit
   `design/sunburst-pop/app.html` (and its RTL variant), re-run `design/sunburst-pop/capture-screens.sh`,
   and commit the regenerated PNGs — both `screens/` and `screens/rtl/` — with the change as a
   deliberate design decision.

**Files.** `test/games/schulte_grid/ui/schulte_reference_board_golden_test.dart`,
`test/games/schulte_grid/ui/goldens/reference_board_en_390x844.png`,
`test/games/schulte_grid/ui/goldens/reference_board_fa_390x844.png`; conditionally
`design/sunburst-pop/app.html`, `design/sunburst-pop/screens/*.png` and
`design/sunburst-pop/screens/rtl/*.png`.

**Skills.** `sunburst-game-surfaces`, `sunburst-shell-screens`, `sunburst-components`,
`sunburst-tokens`, `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`.

**Screenshot check.** `design/sunburst-pop/screens/05-schulte-grid.png` and
`design/sunburst-pop/screens/rtl/05-schulte-grid.png` (chrome **and** board interior), plus
`design/sunburst-pop/screens/04-stroop-rush.png` and
`design/sunburst-pop/screens/rtl/04-stroop-rush.png` (chrome only, as a regression check).

**Done when.**
- [ ] Both reference-board goldens are committed and match their PNGs by eye across all five
      comparison steps.
- [ ] Stroop at 390×844 still matches `04-stroop-rush.png` and `rtl/04-stroop-rush.png`.
- [ ] The `ckb` and `de` passes are recorded in the PR body even though they have no reference PNG of
      their own — what was checked, and against what.
- [ ] The visual checklist is in the PR body per direction, with every box ticked or explicitly waived.
- [ ] Any design change is a committed `app.html` + regenerated `screens/*.png` **and**
      `screens/rtl/*.png` set, never a silent drift.

**Commits.**
1. `test(schulte): reference-board goldens at 390x844 in en and fa`
2. `design(sunburst-pop): <what changed> and re-rendered screens` — **only if** step 8 fires.

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 T01.11 built
bash tool/skill_gates.sh

# this epic's named spot-checks, run individually so a failure names itself
# Sunburst design gates
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart

# Localization and RTL — both scripts, not one twice
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                              lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                             lib/l10n

# Architecture, determinism, test hygiene
.claude/skills/flutter-architecture/scripts/check_architecture.sh                    lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh     lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh
.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh       lib
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh           lib
.claude/skills/widget-composition/scripts/check-widget-composition.sh
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh                        lib test
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh          lib test

# This epic's headline gate
bash tool/check_no_shell_edits.sh

# iOS build on the canonical device
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
```

`check_arb_parity.sh` is a **real gate from this epic on** and is no longer skipped: `lib/l10n/` holds
four ARBs from E04, so the script's "no locale ARB files beside the template" exit-2 path (E01 T01.9,
ADR 0001) is unreachable. Every key this epic adds is added to all four files in the same commit, or
the gate fails.

CI (created in E01) runs the first block plus `bash tool/skill_gates.sh`, which is the only sanctioned
way to run the skill scripts — a bare `for s in .claude/skills/*/scripts/*.sh` loop cannot exit 0.
Add a `verify_feature.sh lib/games/schulte_grid` row to the runner's run table beside E08's and E09's.
`tool/check_no_shell_edits.sh` is run locally and its output pasted into the PR body — it is
branch-scoped and must not become a permanent CI gate that blocks future shell epics. The `flutter run`
line is not a CI step: CI has no simulator, and this epic does not pretend otherwise.

## Risks and open questions

1. **`ckb` may throw on locale switch, and this board is where it would land.** `flutter_localizations`
   ships `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations` for a fixed locale list and `ckb`
   is very likely not in it; a missing delegate throws at runtime the moment the locale resolves.
   **Decision:** the custom `LocalizationsDelegate` that serves our ARB strings for `ckb` while
   delegating Material/Cupertino to the nearest supported script neighbour (`fa`, else `ar`) is
   **E04's**, and E04 owns the test that switching to `ckb` does not throw and that verifies the actual
   shipped delegate list at build time rather than assuming it. This epic's obligation is narrower and
   still real: T10.5's manual pass and T10.10's step 5 must exercise the switch **while a Schulte run
   is on screen**, because a board mid-run is the widest live subtree in the app and the most likely
   place a missing delegate surfaces. If it throws, it is an E04 defect — report it there; do not add a
   delegate under `lib/games/**`.
2. **`intl` has no `ckb` number symbols.** `NumberFormat.decimalPattern('ckb')` resolves to the default
   and emits Latin digits, silently. **Decision:** `ckb` is pinned to `fa` in E04's `LocaleNumbers`
   (same U+06Fx block, same separators), and T10.3 and T10.5 assert the digit block for `ckb`
   *separately* from `fa` so the pin is proven rather than inherited. Do not add a `-u-nu-` extension:
   `intl` drops the unicode `-u` extension during fallback, so it buys nothing.
3. **Sorani glyph coverage of the display face is not assumed.** Vazirmatn covers Persian and Sorani;
   Lalezar is the closest OFL chunky display candidate to Fredoka but its coverage of the
   Sorani-specific letters (ڕ ڵ ۆ ێ ھ) is unverified. **E04 owns that verification and records the
   outcome**; this epic reads whatever `SunburstType`'s per-locale cascade resolves. Tiles are digits
   only, so both candidates cover them — but `schulteFoundLabel`, `schulteNextLabel` and the two
   semantics strings are Sorani words and will expose a gap. If E04 fell back to Vazirmatn Bold for
   display, say so in the PR: the Fredoka personality does not survive translation, and in `fa`/`ckb`
   the identity is carried by the shape language (3px ink border, hard offset shadow, press-down, the
   palette), not by the typeface. Do not present the font swap as neutral.
4. **The `fa` and `ckb` translations have had no native review.** The Schulte strings are short but not
   trivial: "Found" and "Next" are terminology, not vocabulary, and a Sorani string that reads as
   machine output is worse than an English one because it looks finished. **Open:** ship this epic with
   the four ARBs complete and the `fa`/`ckb` values flagged `NEEDS NATIVE REVIEW` in the PR and in each
   `@key` description; E11 must not sign the release off until a native speaker has read them. Nothing
   in this epic may describe the translation as done.
5. **`SunburstType` has no tile slot, and `fa`/`ckb` make the gap worse.** `system.html` §10 draws the
   tile glyph at 24pt display/700 with tabular figures; `sunburst-tokens` owes `tileGlyph` (24) and
   `tileGlyphCompact` (18) and has shipped neither. **Decision:** use `numericHud` (22) and `button`
   (18), which renders 2pt small, and let T10.6's measured fit decide where the step fires per locale.
   Eastern Arabic two-digit labels are wider and taller than their Latin equivalents at the same point
   size, so the step will fire earlier in `fa`/`ckb` — possibly at 1.3 where `en` reaches 2.0. Log it
   as a **BLOCKER** for `design-review-workflow` in E11 and as a token request to `sunburst-tokens`.
   Never paper over it with a `fontSize:` — that fails `check_raw_values.sh` and the ban is the point.
6. **The no-mirror decision will be questioned.** Recorded in full in T10.5 with its counter-argument.
   **Open** only in one direction: if a native `fa`/`ckb` reviewer says the grid should mirror, the
   change is one `Directionality` island plus a second reference PNG, and it belongs to E11, not to a
   late edit here.
7. **`ScoreFormat.duration` may not be wired end to end.** E07's `RunNotifier._finish` puts
   `durationMs: _ticker.elapsed.inMilliseconds` on the `RunDraft` it hands `saveRun`, but
   `RunOutcome.completed(score:)` also carries a number, and the shell must choose which one it
   formats — and now also which locale it formats it in. **Decision:** read `lib/features/results/`,
   `lib/features/stats/` and `lib/data/` before writing T10.3; supply whichever field makes Results
   read `18.6s` in `en` and `۱۸٫۶` + unit in `fa` **without touching `lib/features/**`**. If neither
   path works, it is an E07/E08 seam defect — raise it with that epic's owner, widen the seam
   generically, and record it in the PR. Do not patch a shell screen.
8. **`appLocalizationsProvider` is E04's and already exists.** The snapshot needs localized HUD labels
   and has no `BuildContext`, so E04 ships the provider in `lib/l10n/` alongside `LocaleNumbers`,
   `AsciiNumerals.normalize` and the isolate helpers. This epic imports them. Do not add a second copy under
   `lib/games/**` or `lib/features/**`; if any is genuinely absent, that is an E04 defect to fix in E04.
9. **The `sunburst-game-surfaces` Schulte example contradicts the shell, and now also the numerals.**
   `examples/schulte_board.dart` wraps the board in a `ColoredBox` of the accent and in a
   `SunburstShape.gutter` `Padding`; `sunburst-shell-screens`' `_BoardPane` already paints the
   background from `GameDefinition.boardBackground` and already applies gutter 20 / top 20 /
   bottom 26, and `sunburst-game-surfaces` rule 8 says the slot arrives with the gutter removed. It
   also renders the tile value as a bare `'$value'`. **Decision:** the shell wins — the board applies
   neither wrapper — and the label goes through `LocaleNumbers`. Doing both wrappers would give a
   240pt board at 320pt and a 44.4pt cell, breaking the 48px floor the whole gap derivation exists to
   defend. Flag all three points to the skill owner.
10. **Blitz at 6×6: the floor argument is weaker than it was, and this file says so.** At the retained
    320pt conservative floor the 6-column cell is 40.0pt and fails `kPopMinTarget`. But iOS's narrowest
    shipping phone is 375pt (iPhone SE 2/3), where the 8pt gap gives 49.17pt and clears it. **Decision:**
    Schulte still offers Chill (4×4) and Classic (5×5) only — it matches `app.html` and the reference
    screenshots, and T10.6 measures whether a two-digit Eastern Arabic label fits the resulting 39.17pt
    inner box at an accessible text scale. That measurement, not the tap floor, is the honest reason on
    iOS. Record the number in the PR's "deliberately left out" section; if it fits, hand Blitz to E11
    as an open scope question rather than repeating an argument the arithmetic no longer supports.
11. **Directory name.** The brief says `lib/games/schulte/`; `references/shell-game-boundary.md` and
    the `game_<id>_*` ARB convention require the directory to match the `GameId`. **Decision:**
    `lib/games/schulte_grid/` with `GameId('schulte_grid')`, matching the `schulte_grid/` shown in the
    seam reference and the `stroop_rush/` E09 shipped.
12. **Riverpod modifier order.** `NotifierProvider.autoDispose.family` vs `.family.autoDispose` and
    `FamilyNotifier` vs a plain `Notifier` differ across Riverpod 3.x docs. **Decision:** copy the
    exact shape E07/E09 used for `stroopBoardNotifierProvider`; do not introduce a second convention.
    E09 is a declared dependency of this epic partly for this reason: `stroopBoardNotifierProvider` is
    the precedent, `test/games/game_registry_test.dart` asserts `stroop_rush` **then** `schulte_grid`,
    and T10.10 step 6 re-checks `04-stroop-rush.png` for chrome regressions this epic could introduce.
13. **`PopGridTile` is E05's, and this epic is its only consumer.** E05 T05.8 shipped it with the five
    Schulte states, the public `visualFor` resolver, five state goldens and the greyscale
    state-collision proof. **Decision:** `SchulteTile` composes it and maps `SchulteTileState` 1:1;
    there is no `schulte_tile_visual.dart`. Building a second resolver here would leave the catalog
    carrying a class nothing uses and the greyscale guarantee asserted in two places that can disagree.
    If `PopGridTile` cannot express a state, widen it in `lib/ui/` with a test — that is a component
    change, and it is the only kind of `lib/ui/` edit T10.9's zero-lines proof tolerates.
14. **Golden lane flakiness, now with real script shaping.** Real-font goldens are byte-stable only on
    the pinned OS, and the `fa`/`ckb` lane additionally depends on the exact bundled font *file*, so a
    font version bump re-baselines it. **Decision:** bless in that one environment, pin the font files
    in `pubspec.yaml` and commit them, and record the blessing environment (macOS version, Flutter
    3.44.6) in the golden directory's README. CI verifies and never runs `--update-goldens`.
15. **The wrong-tile latch has no timeout.** It clears on the next tap, because the game may not own a
    clock and a raw `Duration` under `lib/games/**` fails `check_motion_tokens.sh`. A player who taps
    wrong and then walks away leaves a red tile on screen. **Open:** acceptable, or does it want a
    shell-supplied hold duration on `GameDefinition`? Ask in the PR; do not add a timer unilaterally.
16. **What this epic does not verify.** No Android: it is deferred, and nothing here has been run on
    it. No physical device: the Simulator renders no haptics and its Persian text rendering is Core
    Text on macOS, not on iOS hardware — close, but not proof. Both belong to E11's device pass, and
    neither may be ticked here.

## Definition of done

- [ ] Branch `epic/10-schulte-grid` cut from `main`, granular commits, tests committed with the code
      they cover.
- [ ] All ten tasks complete with their "Done when" boxes ticked.
- [ ] Schulte Grid is playable end to end on `MindForge iPhone 14`
      (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, 390×844, iOS 18.6): Home card → detail → countdown →
      5×5 board → Results with a duration score → Stats — in `en`, `de`, `fa` **and** `ckb`.
- [ ] `bash tool/check_no_shell_edits.sh` prints `OK`, and `test/policy/engine_seam_test.dart` is
      green — **zero lines added to `lib/features/**`**.
- [ ] Scramble golden vectors committed, with an honest header comment about which rows are
      independently derived, and asserted byte-identical across all four locales.
- [ ] Every tile-state pair proven to differ in ≥3 non-hue channels **through E05's `PopGridTile`
      resolver**, plus a greyscale golden; no second visual resolver, no second `ShakeOnWrong`, no
      second PRNG, no second number formatter.
- [ ] Tiles render `۱`–`۲۵` in `fa` and `ckb` from the U+06F0–U+06F9 block, asserted per value; the
      `6 / 25` HUD compound is bidi-isolated; every displayed number round-trips through
      `AsciiNumerals.normalize`.
- [ ] The grid does not mirror, the chrome does, and the hard offset shadow does not — each asserted
      on values, not eyeballed.
- [ ] Cell geometry verified at 320/360/375/390/430 and text scale 1.0/1.3/2.0 **× four locales**, with
      no clamp, no `FittedBox`, no ellipsis; the measured glyph-fit table is in the PR body.
- [ ] `check_arb_parity.sh` green over four ARBs; `check_i18n_bans.sh` green over `lib`.
- [ ] `05-schulte-grid.png` and `rtl/05-schulte-grid.png` compared (chrome and board interior);
      `04-stroop-rush.png` and `rtl/04-stroop-rush.png` re-compared with no regression; the visual
      checklist is in the PR body per direction.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] Every command under **Gates that must pass** exits 0.
- [ ] PR opened explaining what changed, why, how it was verified, which screens were compared (05 and
      04, LTR and RTL), and what was deliberately left out: Blitz 6×6 with the honest 375pt arithmetic;
      the `tileGlyph` token gap; `wrong`/`disabled` having no reference PNG; `de`/`ckb` having no
      reference PNG of their own; the `fa`/`ckb` strings awaiting native review; Android; and haptics,
      which the Simulator cannot produce.
- [ ] CI green on the PR.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
