# E08 · Stroop Rush

| | |
|---|---|
| **Branch** | `epic/08-stroop-rush` |
| **Depends on** | E01, E02, E03, E04, E05, E06, E07 |
| **Unblocks** | E09, E10 |
| **Status** | Not started |

## The epic

The first game. Everything Stroop Rush is lives under `lib/games/stroop_rush/`: a pure seeded round
generator, a scoring function with a streak multiplier, one `StroopBoardNotifier`, the board widget
tree, one `GameDefinition`, and one line appended to `gameRegistryProvider`. Zero lines change in
`lib/features/**`. The board is the rectangle below the play band's ink border and nothing else — it
publishes a `BoardSnapshot` upward and draws no HUD, no `Scaffold`, no route.

It also **removes the scaffolding E07 built to stand in for it**: `lib/games/placeholder/` exists only
so the shell was runnable and screenshot-comparable before a real game existed, its files carry
`// DELETE IN E08` on their first line, and T08.0 is this epic's first commit.

Two things make this game harder than "tap the right square". First, hue *is* the answer, so the
board is `GameColourRole.mechanic`: no chrome semantic slot (`accent`, `success`, `warning`,
`danger`, `gameStroop`) may appear inside the board rectangle, and no `play*`/`cb*` slot may leave
it. Second, the colour-blind setting is an input to round **generation**, not a paint-time swap: it
caps the answer pool to `{red, green, blue, yellow}` and is captured once into the round state, so a
mid-run Settings change cannot alter what the running round is asking. Both properties are pinned by
tests, because neither is visible in a screenshot.

## Why we need it

MindForge is an engine with nothing plugged into it. E06 built `RunNotifier`, `RunConfig`,
`BoardSnapshot` and `GameDefinition`; E07 built the eight shell screens around a seam that has never
carried a real game. Until a board exists, `PlayScaffoldScreen` renders an empty pane, the results
screen has no score to format, Stats has no rows, and the `GameDefinition` contract is a claim rather
than a fact.

Without this epic: E09 (Schulte Grid) has no precedent to prove the engine against — the whole
"Schulte ships without editing `lib/features/**`" thesis needs a first game to be the second game's
control. E10 has no gameplay surface to run its accessibility sweep over, and the two hardest
accessibility properties in the product — hue-free state encoding and the colour-blind answer path —
would ship unverified.

## Current state

Honest baseline, verified by `ls` on 2026-08-19:

- **No Flutter app exists.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Four commits on
  `main`: convention skills, three candidate design systems, the Sunburst Pop screenshots, and the
  five `sunburst-*` skills plus `CLAUDE.md`.
- `.claude/skills/` — 45 skills, including `sunburst-game-surfaces` whose
  `examples/stroop_board.dart` is a complete, compiling-shaped reference for this board, and
  `sunburst-motion-and-haptics/examples/feedback_moments.dart` whose `StroopRunNotifier` and
  `ShakeOnWrong` are this epic's commit-path and shake patterns.
- `design/sunburst-pop/screens/04-stroop-rush.png` — the target: pause icon button + "Stroop Rush" +
  "Classic" chip; coral play band with rays, dots, three HUD pills (TIME 0:23 / SCORE 1,240 /
  STREAK x7 in sunshine) and a striped 57% track; a 3px ink border; then a `surfaceSunk` field with a
  14% ink dot layer, a `surfaceRaised` stimulus card at `radiusXl` with an e3 shadow carrying
  "TAP THE COLOUR, NOT THE WORD" over the word BLUE printed in striped red, and a 2×2 grid of four
  92pt answer keys each with a 56pt ink-bordered pattern panel.
- `design/sunburst-pop/app.html` lines ~1040–1082 (screen 04) and its `.stim` / `.word` / `.pat--*` /
  `.answers` / `.ans` / `.playfill--stroop` rules are the authoritative layout; `system.html` §03 and
  §12 are the authoritative pattern and three-pass values.

**Everything this epic consumes must already exist when it starts.** Verify before the first commit,
and stop if any is missing rather than building it here:

| From | Must exist |
|---|---|
| E02 | `SunburstColors` (`PlayAnswer`, `PlayFill`, `answerColour`, `answerLabel`, `surfaceSunk`, `surfaceRaised`, `border`), `SunburstShape`, `SunburstMotion`, `SunburstType`, `lib/theme/game_accent.dart` (`GameAccent`, `GameColourRole`) |
| E03 | `PopSurface`, `PopElevation`, `kPopMinTarget`, `lib/core/hud_tone.dart`, and the test support: `test/support/harness.dart` (`Device`, `Device.all` at DPR 2), `test/support/fake_feedback_service.dart` (`FakeFeedbackService`), `test/support/load_app_fonts.dart` |
| E04 | `Moment`, `FeedbackService`, `feedbackServiceProvider`, `PressPhysics`, **`lib/shared/motion/shake_on_wrong.dart`** |
| E05 | `lib/core/score_format.dart` (`enum ScoreFormat { points, duration }` — the one score enum), `RunDraft`, `RunCommit` |
| E06 | `RunConfig` (`gameId`, `difficulty`, `seed`), `Difficulty`, `GameId`, `GameDefinition` (incl. `runLimitFor`), `BoardSnapshot`, `GameHud`, `HudSlot`, `RunOutcome`, `BoardBackground`, `gameRegistryProvider`, `clockProvider`, and the repo-owned PRNG: **`fnv1a64`, `SeededGenerator` and `seedFrom` from `lib/core/seeded_generator.dart`** |
| E07 | `PlayScaffoldScreen` and its `_BoardPane`, `RunNotifier`, the three-pill `GameHud` renderer, the progress track, `appLocalizationsProvider`, `lib/l10n/app_en.arb` |

**No fallbacks.** E06 is a hard dependency; if `lib/core/seeded_generator.dart` is missing, stop and fix
E06. Do not add `lib/core/random/seeded_rng.dart`, a `SeededRng` class or `lib/shared/determinism/` —
three names for one PRNG is how the frozen-vector guarantee in T08.2 becomes meaningless. The same
applies to `ShakeOnWrong`: it is E04's file at `lib/shared/motion/shake_on_wrong.dart` and this epic
wires it in rather than copying it under `lib/games/`.

## What we will achieve

A human can run `flutter run` on a 390×844 device, open Stroop Rush from Home, pick Classic, watch
3-2-1, and play a complete 30-round run: the word appears in a printed hue, four keys respond to
touch by pressing into the page, the right key lifts and holds, the wrong key sinks, wears an ink
strike bar and shakes twice, Score and Streak update in the HUD, the track fills, and at the last
round Results appears with the run persisted. Turning on Settings → "Colour-blind friendly palette"
and starting a *new* run produces a round whose answer set is drawn only from red/green/blue/yellow,
painted pink/orange/blue/yellow, and labelled to match what is painted.

Observable and checkable without the device:

- `flutter test` is green, including golden vectors that pin the first 24 rounds for six
  (seed × difficulty) pairs and two colour-blind pairs, computed from an independent oracle.
- `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` prints
  `OK: no Color declarations, stray theme imports, or tier crossings under lib/games`.
- `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` is green — proof the
  board neither navigates, nor builds a `Scaffold`/`AppBar`/`SafeArea`, nor owns a clock, and that no
  file under `lib/features/**` names `games/stroop_rush/`.
- A greyscale golden of the stimulus card plus the answer row answers "which key matches the word?"
  from pattern alone.
- `git diff --stat main -- lib/features/` is empty.
- The built screen at 390×844 matches `design/sunburst-pop/screens/04-stroop-rush.png` — chrome and
  board interior — in structure, spacing, surface construction, type role and sampled hex.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Rules 2 (dumb widgets), 3 (one ViewModel over immutable state), 8 (injected side effects), 10 (complexity limits) and 12 (RTL/a11y by construction) govern every task below. |
| `sunburst-game-surfaces` | Owns this epic. Rule 2 (the two-tier boundary), rule 3 (correct/wrong are never coloured on a `mechanic` board), rule 4 (the CVD flag drives generation), rule 5 (`PlayFill` on key *and* glyph), rule 6 (the three-pass stimulus), rule 10 (`BoardSnapshot`, no HUD), rule 11 (three slots, one highlight). `references/board-states-and-layout.md` carries the key/stimulus state matrix; `examples/stroop_board.dart` is the reference implementation. |
| `sunburst-tokens` | Every hex, radius, shadow step and duration the board spends, and the four-place procedure (field + constructor + `copyWith` + `lerp` + the const instance) for the `SunburstShape`/`SunburstType` slots T08.6 and T08.7 must add. Rule 6 states why the stimulus is never a bare `Text`. |
| `sunburst-components` | `PopSurface` is the only surface constructor; `PopElevation` the only elevation vocabulary; rule 6 carries the answer-key exception — a resolved key drops its `onTap`, it never passes `enabled: false`. Rule 10 fixes the 48px target floor on the fill box, not the shadow. |
| `sunburst-shell-screens` | `references/shell-game-boundary.md` is the exact `GameDefinition` / `BoardSnapshot` / `RunConfig` contract, the `lib/games/<id>/{definition, application, domain, ui}` layout, and the forbidden-in-`lib/games/**` table this epic is measured against. |
| `sunburst-motion-and-haptics` | The moment rows this board fires: `answerCorrect`, `answerWrong` (two explicit `forward(from: 0)` calls, never `repeat`), `streakMilestone` (latched to multiples of 5), and rule 5 — the stimulus cross-fades in place and never animates in, because an entrance is added to the player's reaction time. |
| `seeded-determinism-and-golden-vectors` | Rules 4–7 (one entropy source, hash + mix, frozen salts), 9 (a shipped generator is frozen), 10–12 (the vector table, the independent oracle, CI verifies and never blesses). This is what makes a run reproducible from a bug report. |
| `state-management-riverpod` | `StroopBoardNotifier` as one `Notifier` over one immutable state with value equality, family-keyed by `RunConfig` and `autoDispose`; intent methods only; `ref.watch(...select(...))` in the View. Rule 10 bans `DateTime.now()` in state logic. |
| `custom-canvas-and-gestures` | The stimulus glyph and the pattern panel are `CustomPainter`s: the View/Painter/Scene split, `shouldRepaint` as one value compare, zero allocation inside `paint()`, and `ExcludeSemantics` + a sibling `Semantics` node speaking the display value over custom-drawn pixels. |
| `widget-golden-and-a11y-testing` | `test/support/harness.dart`, `useDevice` before `pumpApp`, the one-`testWidgets`-per-tuple overflow matrix, the fit assertion goldens cannot make, and the greyscale/RTL golden lanes with `loadAppFonts()`. |
| `testing-strategy` | Pure round generation and scoring are `package:test` unit and property tests, never `pumpWidget`; the notifier is driven headlessly with `ProviderContainer`; fakes are bare `implements`, not mocks. |
| `accessibility-as-code` | Rule 6 (never encode state through colour alone) is the whole reason for `PlayFill`; rules 4–5 ban the clamp/`FittedBox`/ellipsis escape hatches the 78pt stimulus will tempt; rule 8 fixes the tap-target floor. |
| `dart3-idioms-and-coding-standards` | `StroopRound`, `StroopDifficultyProfile`, `StroopScore` and `StroopBoardState` are immutable `final class`es with value equality; the `AnswerKeyState` switch is exhaustive with no `default:`; generation and scoring are total functions; the complexity table (method ≤30, `build()` ≤80, file ≤300) is why the board splits into six files. |
| `widget-composition` | Extracted `const` widget classes, never `_buildX()` methods; the `GridView` cross/main-axis spacing trap; `EdgeInsetsDirectional` only; `clipBehavior: Clip.none` so the hard shadow is not sheared off. |
| `i18n-rtl-l10n` | The prompt, the seven answer labels, the two HUD labels and the stimulus semantic value are ARB keys appended to `lib/l10n/app_en.arb`; `nullable-getter:false` makes a missing key a compile error, which is the gate that bites at one locale (`check_arb_parity.sh` needs a sibling ARB — see Gates); the score is formatted with a per-locale `NumberFormat` in the notifier, never in a widget. |
| `flutter-architecture` | T08.9 places the definition, `application/`, `domain/` and `ui/` in the downward-only DAG and proves `lib/features/**` gained nothing; also the rule that `lib/games/**` may import `lib/core/`, `lib/theme/`, `lib/ui/` and `lib/shared/` but never `lib/features/`. |
| `scaffold-feature-module` | T08.9 only: the fixed folder shape a game module takes and `scripts/verify_feature.sh`, run against `lib/games/stroop_rush` as one directory (it takes one, not the repo root). |
| `ci-pipeline-and-gates` | T08.8's source-level policy tests are the sanctioned grep-gate class: the three-criteria bar, comment-stripping, accumulate-and-fail-once, and a reason a stranger can act on. |

## Tasks

### T08.0 — Remove the placeholder registry
**Goal.** Delete the scaffolding E07 built to stand in for a real game, in this epic's **first commit**,
so the shell is never carrying both.

**Why first and not last.** E07 T07.1 shipped `lib/games/placeholder/` with `// DELETE IN E08` on the
first line of every file and recorded in its Risk 2 that "E08's first commit removes the directory and
the ARB key groups. If E08 ships without removing it, that is a review reject on E08." Doing it first
also means every test below runs against a registry that holds only real games, so a Home-screen
expectation written mid-epic does not have to be rewritten at the end.

**Tests first (TDD).** The deletions *are* red-first: removing the directory breaks
`test/games/placeholder_registry_test.dart` and E07's `home_screen_test.dart` expectations, and that is
the signal. Before deleting, update those tests to their post-placeholder shape:
- delete `test/games/placeholder_registry_test.dart` entirely — its subject is gone;
- in `test/features/home/home_screen_test.dart` (E07's file, edited here) the fake-registry expectation
  drops from "three cards for the fake registry" to whatever the fakes now hold; the test drives
  `fakeAlphaDefinition`/`fakeBetaDefinition`, not the placeholder definitions, so this is an expectation
  edit and not a rewrite. **If it turns out to be a rewrite, the shell was reading the real registry
  where it should have been reading the fakes** — fix that, and say so in the PR.
- `test/games/game_registry_test.dart` asserts the registry is empty again until T08.9 appends
  Stroop Rush.

**Implementation.** `git rm -r lib/games/placeholder/`; drop the three placeholder entries from
`lib/games/game_registry.dart`; remove the twelve `game_placeholder_*` keys from `lib/l10n/app_en.arb`
and their entries in `lib/l10n/game_strings.dart`; run `flutter gen-l10n`. Nothing else in
`lib/features/**` changes — if it must, that is a seam defect to report, not to patch.

**Files.** `lib/games/placeholder/**` (deleted), `lib/games/game_registry.dart`,
`lib/l10n/app_en.arb`, `lib/l10n/game_strings.dart`, `lib/l10n/app_localizations*.dart` (regenerated),
`test/games/placeholder_registry_test.dart` (deleted), `test/games/game_registry_test.dart`,
`test/features/home/home_screen_test.dart`.

**Skills.** `sunburst-shell-screens`, `i18n-rtl-l10n`, `testing-strategy`.

**Screenshot check.** n/a — but note that until T08.9 lands, Home renders **zero** game cards. That is
expected mid-epic and is not a comparison against `01-home.png`; the Home comparison is T08.9's.

**Done when.**
- [ ] `ls lib/games/` shows no `placeholder/`; `grep -rn "placeholder" lib/ test/` returns nothing.
- [ ] `flutter test` green; `flutter analyze --fatal-infos` clean after `flutter gen-l10n`.
- [ ] `git diff --stat main -- lib/features/` shows only `home_screen_test.dart`'s sibling under
      `test/` — no `lib/features/**` source line changed.

**Commits.**
1. `Remove the E07 placeholder registry, its board and its strings`

---

### T08.1 — Difficulty profiles, the round value type, and the seeded generator
**Goal.** Turn `(seed, difficulty, isColourBlindPalette)` into a reproducible sequence of
`StroopRound`s with no Flutter import and no clock read.

**Tests first (TDD).** `test/games/stroop_rush/domain/stroop_round_generator_test.dart`:
- `generates the profile's round count for every difficulty` — asserts `rounds.length ==
  profile.roundCount` for chill/classic/blitz.
- `the same seed and difficulty produce byte-identical rounds twice` — two generator runs, canonical
  strings compared with `equals`; any reintroduced ambient randomness fails here.
- `a different seed produces a different sequence` — 64 consecutive seeds, asserts fewer than 2
  collisions on the first round's `(word, ink)` pair, printing the seed in `reason:`.
- `the ink is always among the offered options` — seeded fuzz, 500 seeds × 3 difficulties.
- `every offered set has four distinct hues and four distinct PlayFills` — the invariant that
  resolves `gameplay-palette-and-cvd.md`'s "the Blitz six-set collides": blitz draws 4 from a pool of
  6, so `{blue, purple}` (both solid) and `{red, orange}` (both stripe) can never both be offered.
- `the incongruent share matches the profile within tolerance` — 2000 rounds per difficulty, asserts
  the measured share is within 0.05 of `profile.incongruentShare`.
- `a congruent round names its own ink and an incongruent one never does` — exhaustive over the
  generated set.
- `test/games/stroop_rush/domain/stroop_difficulty_profile_test.dart`: `roundCount`,
  `incongruentShare` and `multiplierCap` are monotonic across chill → classic → blitz, and every
  `Difficulty` case has a profile (exhaustive switch, no `default:`).

**Implementation.**
- `lib/games/stroop_rush/domain/stroop_difficulty_profile.dart` — `final class
  StroopDifficultyProfile` (`roundCount`, `pool`, `incongruentShare`, `multiplierCap`) and
  `profileFor(Difficulty)` as an exhaustive switch. Values are **DERIVED** (`app.html` shows only the
  "Classic" chip and a 57% track) and marked as such at the point of use: chill 20 / pool
  `{red, blue, green, yellow}` / 0.60 / ×2; classic 30 / same pool / 0.75 / ×4; blitz 40 / pool plus
  `purple, orange` / 0.90 / ×6. Screen 04's track at 57% with 17 answered rounds is consistent with a
  classic count of 30 — consistency, not derivation.
- `lib/games/stroop_rush/domain/stroop_round.dart` — `final class StroopRound` (`index`,
  `word: PlayAnswer`, `ink: PlayAnswer`, `options: List<PlayAnswer>`, `isColourBlindPalette`), value
  equality, `bool get isCongruent => word == ink`, and `String canonical()` with fixed field order
  and enum **indices** (never `toString()`).
- `lib/games/stroop_rush/domain/stroop_round_generator.dart` — `const kStroopFeatureSalt`
  (a frozen 64-bit constant) and `const kStroopGeneratorVersion = 1`;
  `List<StroopRound> generateStroopRounds({required int seed, required Difficulty difficulty,
  required bool isColourBlindPalette})`. Seed derivation is `fnv1a64('stroop_rush:$seed') ^
  kStroopFeatureSalt ^ difficulty.index`, mixed through `SeededGenerator` (SplitMix64) from
  `lib/core/seeded_generator.dart`. Draw order is fixed and
  documented as a contract: options first (rejection-sampled until four distinct `PlayFill`s), then
  the ink from the options, then congruency, then the word. Total function — it never throws.

**Files.** `lib/games/stroop_rush/domain/stroop_difficulty_profile.dart`,
`lib/games/stroop_rush/domain/stroop_round.dart`,
`lib/games/stroop_rush/domain/stroop_round_generator.dart`,
`test/games/stroop_rush/domain/stroop_difficulty_profile_test.dart`,
`test/games/stroop_rush/domain/stroop_round_generator_test.dart`
The PRNG is imported from `lib/core/seeded_generator.dart` (E06) — this task adds no generator file
and no fallback.

**Skills.** `seeded-determinism-and-golden-vectors`, `dart3-idioms-and-coding-standards`,
`testing-strategy`, `sunburst-game-surfaces`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/stroop_rush/domain/` green.
- [ ] `.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/games/stroop_rush/domain` exits 0.
- [ ] No `package:flutter` import under `lib/games/stroop_rush/domain/`.
- [ ] Every DERIVED number carries a one-line reason at its declaration.

**Commits.**
1. `test(stroop): difficulty profile and round generation invariants` (red)
2. `feat(stroop): difficulty profiles and the StroopRound value type`
3. `feat(stroop): seeded round generator with a frozen salt and draw order`

---

### T08.2 — Golden vectors: rounds pinned per seed × difficulty
**Goal.** Freeze what each `(seed, difficulty, cvd)` means, so a refactor that renames a variable
cannot quietly change what a player was asked.

**Tests first (TDD).** `test/games/stroop_rush/domain/stroop_golden_vectors_test.dart` —
`the generator reproduces every frozen vector`: for each row, generate the sequence, fingerprint the
first 24 rounds, `expect(fingerprint, equals(v.fingerprint))` and
`expect(incongruentCount, equals(v.incongruentCount))` with `reason: v.note`. Rows cover the range
boundaries a bug hides behind: seed `0`, seed `1`, a mid-range seed, `0x7FFFFFFF`, each × classic;
plus chill and blitz at the mid-range seed; plus two rows with `isColourBlindPalette: true`. A second
test, `the vector table has no duplicate fingerprints`, catches a copy-paste row.

**Implementation.**
- `test/games/stroop_rush/domain/stroop_vectors.dart` — `final class StroopRoundVector` (`seed`,
  `difficulty`, `isColourBlindPalette`, `fingerprint`, `incongruentCount`, `note`) and
  `const stroopRoundVectors = <StroopRoundVector>[...]`, with a header comment naming the oracle.
- `test/games/stroop_rush/domain/oracle/stroop_reference_generator.dart` — the **independent
  oracle**: a slower, brute-force transcription of the specification (SplitMix64 constants written
  from the published paper, options built by full enumeration and filtering rather than rejection
  sampling), used only to compute the table. Where it is genuinely a re-transcription rather than a
  second design, say so in the header comment and treat those rows as regression pins.
- `tool/update_stroop_vectors.dart` — prints the regenerated table to stdout for a human to paste and
  read as a diff. It is never run by CI.

**Files.** `test/games/stroop_rush/domain/stroop_vectors.dart`,
`test/games/stroop_rush/domain/oracle/stroop_reference_generator.dart`,
`test/games/stroop_rush/domain/stroop_golden_vectors_test.dart`, `tool/update_stroop_vectors.dart`.

**Skills.** `seeded-determinism-and-golden-vectors`, `testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Ten vector rows committed, each with a `note` saying why the row exists.
- [ ] The oracle imports nothing from `lib/games/stroop_rush/domain/stroop_round_generator.dart`.
- [ ] `tool/update_stroop_vectors.dart` appears in no workflow file.
- [ ] Flipping one constant in the generator turns the vector test red (verify by hand, then revert).

**Commits.**
1. `test(stroop): independent reference generator for golden vectors`
2. `test(stroop): freeze round vectors for eight seed/difficulty pairs`
3. `chore(stroop): local-only vector regeneration command`

---

### T08.3 — The colour-blind generation path
**Goal.** Make the colour-blind flag change the **answer set**, captured once at round start — not a
paint-time substitution.

**Tests first (TDD).** `test/games/stroop_rush/domain/stroop_colour_blind_test.dart`:
- `with the flag on, no round offers purple or orange` — all three difficulties, 500 seeds; this is
  the test that fails if the flag is only read at paint time, because blitz's pool would still draw
  them.
- `blitz under the flag generates the same pool as classic` — the four CB slots are the whole set.
- `the same seed produces a different sequence with the flag on` — proves generation, not rendering,
  branched.
- `every round records the flag it was generated under` — `round.isColourBlindPalette` equals the
  input for every round in the sequence.
- `the label follows the painted hue, not the enum name` —
  `answerLabelKey(PlayAnswer.green, colourBlind: true) == 'play_answer_orange'` and
  `answerLabelKey(PlayAnswer.red, colourBlind: true) == 'play_answer_pink'`; with the flag off they
  are `play_answer_green` / `play_answer_red`.
- `the offered set still has four distinct fills under the flag` — patterns are not part of the
  setting.

**Implementation.**
- Extend `generateStroopRounds` to intersect the profile pool with
  `{red, green, blue, yellow}` when `isColourBlindPalette` is true, **before** the first draw, and
  stamp the flag onto every `StroopRound`.
- `lib/games/stroop_rush/application/stroop_answer_labels.dart` —
  `String answerLabelKey(PlayAnswer a, {required bool colourBlind})` and
  `String answerLabel(PlayAnswer a, {required bool colourBlind, required AppLocalizations l10n})`.
  This file names `PlayAnswer` only; it never names a `play*`/`cb*` slot, `answerColour` or
  `answerLabel(` on `SunburstColors`, so it stays legal outside `board/`.
- ARB keys `play_answer_red|blue|green|yellow|purple|orange|pink` in `lib/l10n/app_en.arb`.

**Files.** `lib/games/stroop_rush/domain/stroop_round_generator.dart` (changed),
`lib/games/stroop_rush/domain/stroop_round.dart` (changed),
`lib/games/stroop_rush/application/stroop_answer_labels.dart`, `lib/l10n/app_en.arb`,
`test/games/stroop_rush/domain/stroop_colour_blind_test.dart`.

**Skills.** `sunburst-game-surfaces`, `seeded-determinism-and-golden-vectors`, `i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface). The setting's own preview row is
`08-settings.png` and belongs to E07.

**Done when.**
- [ ] The two colour-blind rows added to the vector table in T08.2 still pass.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean
      — `nullable-getter: false` makes a missing key a compile error, which is the real gate at one
      locale. `check_arb_parity.sh` stays skipped (it needs a sibling `app_*.arb`; verified exit 2).
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` green — proof
      `stroop_answer_labels.dart` did not smuggle a gameplay slot outside `board/`.

**Commits.**
1. `test(stroop): the colour-blind flag caps the generated answer set` (red)
2. `feat(stroop): capture the colour-blind flag into round generation`
3. `feat(stroop): answer label keys follow the painted hue under the flag`

---

### T08.4 — Scoring and the streak multiplier
**Goal.** One total, pure function from `(score, correct)` to a new score, with a streak multiplier
that is derived, never stored twice.

**Tests first (TDD).** `test/games/stroop_rush/domain/stroop_scoring_test.dart`:
- `a correct answer increments the streak and adds base × multiplier` — table test over streaks
  0..19 against a hand-computed expected value.
- `a wrong answer resets the streak to zero and adds no points` — including from a streak above the
  multiplier cap.
- `the multiplier is monotonic in the streak and never exceeds the profile cap` — exhaustive over
  streaks 0..200 for all three profiles.
- `points never decrease over any answer sequence` — seeded fuzz, 1000 random correct/wrong
  sequences of length 40, printing the sequence in `reason:`.
- `bestStreak equals the maximum prefix streak` — checked against an independent `fold` oracle in the
  test file.
- `a perfect run scores the oracle total` — the acceptance row: 30 consecutive correct answers under
  the classic profile equals a brute-force sum computed in the test.

**Implementation.** `lib/games/stroop_rush/domain/stroop_scoring.dart`:
`final class StroopScore` (`points`, `streak`, `bestStreak`, `correct`, `wrong`) with value equality
and `const StroopScore.zero()`; `int streakMultiplier(int streak, {required int cap}) =>
math.min(1 + streak ~/ kStroopStreakStep, cap)`;
`StroopScore applyAnswer(StroopScore s, {required bool isCorrect, required
StroopDifficultyProfile profile})`. Constants `kStroopBasePoints = 40` and `kStroopStreakStep = 5`
are **DERIVED** — screen 04 shows 1,240 points at 17 of 30 rounds with a streak of 7, which the ×1–×4
ramp lands in the neighbourhood of; the `score + 20` in
`sunburst-motion-and-haptics/examples/feedback_moments.dart` is illustrative, not a token. These live
in the domain, not in `lib/theme/`.

**Files.** `lib/games/stroop_rush/domain/stroop_scoring.dart`,
`test/games/stroop_rush/domain/stroop_scoring_test.dart`.

**Skills.** `dart3-idioms-and-coding-standards`, `testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/stroop_rush/domain/stroop_scoring_test.dart` green.
- [ ] `streakMultiplier` is a pure function of `(streak, cap)`; the multiplier is not a field on
      `StroopScore` (derive, don't store).
- [ ] `applyAnswer` returns a new instance on every call — no in-place mutation.

**Commits.**
1. `test(stroop): scoring invariants and the streak multiplier ramp` (red)
2. `feat(stroop): StroopScore and the streak multiplier`

---

### T08.5 — `StroopBoardNotifier` and the `BoardSnapshot`
**Goal.** One family-keyed notifier that owns the deck, the score, the key states and the latches,
and publishes exactly one `BoardSnapshot` — three HUD slots, a progress value, and an outcome.

**Tests first (TDD).** `test/games/stroop_rush/application/stroop_board_notifier_test.dart`, driven
headlessly with `ProviderContainer` and E03's `FakeFeedbackService` from
`test/support/fake_feedback_service.dart` (bare `implements`, records the moments it was handed):
- `build seeds the deck from RunConfig and starts on round 0`.
- `a correct submit advances the round, adds points and fires answerCorrect`.
- `a wrong submit holds the round, marks the tapped key rejected, resets the streak and fires
  answerWrong` — and asserts the state records `wrongKeyIndex`, so exactly one key shakes.
- `the streak milestone fires once per crossing` — 12 correct answers produce exactly two
  `Moment.streakMilestone` events and ten `Moment.answerCorrect`, never both on one answer.
- `the milestone does not re-fire after the streak dips and returns` — the latch test.
- `the snapshot exposes three slots, at most one highlight, and never HudTone.alarm` — over 40
  answers.
- `progress is answered rounds over the profile's round count` — `0.0` at start, `1.0` at the end.
- `outcome is null until the last round and then carries the final points` — and the notifier makes
  no further state writes after it is set.
- `the board never reads the run phase` — asserted statically in T08.9's policy test; here, assert
  that overriding `runNotifierProvider` with a throwing stub does not break the notifier.
- `the score is formatted once, in the notifier` — `slotB.value` is `'1,240'` for 1240 under `en`.

**Implementation.**
- `lib/games/stroop_rush/domain/stroop_board_state.dart` — `final class StroopBoardState`
  (`rounds`, `index`, `score`, `keyStates: List<AnswerKeyState>`, `wrongKeyIndex`, `lastMilestone`,
  `isColourBlindPalette`) with value equality and `copyWith`; `enum AnswerKeyState { idle, accepted,
  rejected, locked }`.
- `lib/games/stroop_rush/application/stroop_board_notifier.dart` —
  `final class StroopBoardNotifier extends Notifier<StroopBoardState>` behind
  `stroopBoardNotifierProvider = NotifierProvider.autoDispose.family<...>` keyed by `RunConfig`;
  intent method `void submit(int optionIndex)`; a derived `BoardSnapshot get snapshot` exposed
  through `stroopBoardSnapshotProvider(config)` so `GameDefinition.snapshotOf` has a
  `ProviderListenable<BoardSnapshot>` to hand the shell. Haptics go through
  `ref.read(feedbackServiceProvider).fire(...)` on the commit frame, once, with the milestone
  **replacing** the correct-answer tick rather than stacking on it.
- HUD slots: A = Time (label localized, value `''` — the shell composes it from its own clock),
  B = Score (`NumberFormat` in the notifier), C = Streak (`x{n}`, `HudTone.highlight` when the
  multiplier is above 1, i.e. streak ≥ 5; **DERIVED**, matching screen 04's sunshine STREAK pill).
- ARB keys `hud_score`, `hud_streak`, `hud_streak_value` (ICU `x{count}`).

**Files.** `lib/games/stroop_rush/domain/stroop_board_state.dart`,
`lib/games/stroop_rush/application/stroop_board_notifier.dart`, `lib/l10n/app_en.arb`,
`test/games/stroop_rush/application/stroop_board_notifier_test.dart`,
`test/support/fake_feedback_service.dart` (E03 T03.2's file — imported, not re-created).

**Skills.** `state-management-riverpod`, `sunburst-shell-screens`, `sunburst-motion-and-haptics`,
`testing-strategy`, `i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface — the HUD it feeds is compared in T08.9).

**Done when.**
- [ ] No `Timer`, `Ticker`, `Stopwatch`, `DateTime.now()` or `runNotifierProvider` read anywhere in
      `lib/games/stroop_rush/`.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh` green.
- [ ] The notifier holds no `BuildContext` and constructs no collaborator.

**Commits.**
1. `test(stroop): board notifier commit path, latches and snapshot shape` (red)
2. `feat(stroop): StroopBoardState and the answer key state machine`
3. `feat(stroop): StroopBoardNotifier publishing a BoardSnapshot`

---

### T08.6 — The stimulus: the three-pass glyph and its pattern geometry
**Goal.** Paint the word as ink stroke → hue fill → ink `PlayFill` clipped to the glyph, so a yellow
stimulus reads at ink-on-cream 14.55:1 and every hue is separable in greyscale.

**Tests first (TDD).**
- `test/theme/sunburst_shape_test.dart` (extended): the new pattern-geometry slots survive
  `copyWith` and interpolate in `lerp` — the classic slot-added-but-forgotten-in-`lerp` rot.
- `test/games/stroop_rush/ui/stroop_word_painter_test.dart`:
  `shouldRepaint is false for an identical scene and true for each changed field` — one case per
  field of the scene value type; `paint allocates no Paint` — the painter's `Paint` fields are `final`
  and the **identical instances** are used across two `paint()` calls on a recording canvas, matching
  E07 T07.2's `halftone_dots_test.dart`. (`Picture.approximateBytesUsed` measures recorded ops, not Dart
  allocations, and would pass over a painter that allocates a fresh `Paint` per frame — the structural
  gate is `check_painter_hygiene.sh`.) `the outline pass is drawn before the fill pass` — verified with
  a recording `Canvas` fake that logs draw calls in order.
- `test/games/stroop_rush/ui/stimulus_glyph_golden_test.dart` (`@Tags(['golden'])`,
  `setUpAll(loadAppFonts)`): one golden per answer × palette at scale 1.0, and one **greyscale**
  golden (a `ColorFiltered` matrix wrapper) of all four default answers side by side. The greyscale
  acceptance question, recorded in the test's doc comment: *from this image alone, can each glyph be
  told from the others?*
- `test/games/stroop_rush/ui/stimulus_text_scale_test.dart`: one `testWidgets` per
  (device, scale) tuple over `Device.all` × `[1.0, 1.3, 1.5, 2.0, 3.0]` — never a loop inside one
  test, because overflow reports once per `RenderObject`. Asserts `takeException(), isNull` **and**
  that the painted glyph's measured height fits inside the stimulus card's inner box.

**Implementation.**
- `lib/theme/sunburst_shape.dart` (changed) — add the pattern-geometry slots the painter needs, all
  **DERIVED** from `system.html` §03's CSS and each marked as such: `dotPitch` 10, `dotRadius` 2.6,
  `ringPitch` 7, `ringBandWidth` 3, `glyphStrokeWidth` 6. `stripePitch` 9 and `stripeAngle` 45
  already ship. Four places plus the const instance, per `sunburst-tokens` rule 12.
- `lib/theme/sunburst_type.dart` (changed) — add `stimulusCompact` (**DERIVED**, ~54) so the board
  absorbs large text by choosing a smaller *base* style. Never a clamp, a `FittedBox` or an ellipsis.
- `lib/games/stroop_rush/ui/board/play_fill.dart` — `void paintPlayFill(Canvas, Rect, PlayFill,
  Color fill, Color ink, {required PlayFillGeometry geometry, required bool maskToExisting})`, the
  one implementation shared by the glyph and the 56pt key panel, so the two can never disagree.
  Exhaustive switch over `PlayFill`, no `default:`.
- `lib/games/stroop_rush/ui/board/stroop_word_painter.dart` — `final class StroopWordScene`
  (immutable, value equality) and `StroopWordPainter extends CustomPainter` whose `shouldRepaint` is
  `old.scene != scene`. Three `TextPainter`s built in the constructor; `paint()` allocates nothing.
- `lib/games/stroop_rush/ui/board/stimulus_glyph.dart` — the View: measures with
  `MediaQuery.textScalerOf`, picks `type.stimulus` or `type.stimulusCompact` by measured fit, wraps
  the `CustomPaint` in `RepaintBoundary` and `ExcludeSemantics`.
- `lib/games/stroop_rush/ui/board/stimulus_card.dart` — the `PopSurface` slab: `surfaceRaised`,
  `radiusXl`, `PopElevation.e3`, the 14% ink dot layer, the 12px uppercase `textSecondary` prompt,
  and the sibling `Semantics(label: prompt, value: '{word}, {inkLabel}')`. Announcing the ink is the
  only way the board is operable with a screen reader; that it makes the task trivial is a recorded
  product decision, restated in a comment at the node. The card cross-fades between rounds with
  `AnimatedSwitcher` at `durState`/`easeOut` — no slide, no scale, no stagger.

**Files.** `lib/theme/sunburst_shape.dart`, `lib/theme/sunburst_type.dart`,
`lib/games/stroop_rush/ui/board/play_fill.dart`,
`lib/games/stroop_rush/ui/board/stroop_word_painter.dart`,
`lib/games/stroop_rush/ui/board/stimulus_glyph.dart`,
`lib/games/stroop_rush/ui/board/stimulus_card.dart`, plus the five test files above and
`test/theme/sunburst_shape_test.dart`.

**Skills.** `custom-canvas-and-gestures`, `sunburst-tokens`, `sunburst-game-surfaces`,
`widget-golden-and-a11y-testing`, `accessibility-as-code`, `sunburst-motion-and-haptics`.

**Screenshot check.** `design/sunburst-pop/screens/04-stroop-rush.png`, the stimulus card region
only. Compare in order: **structure** (prompt line, then the word, card ends flush with the 20pt
gutter) → **spacing rhythm** (52 top / 18 between prompt and word / 58 bottom padding from
`app.html .stim`) → **surface construction** (3px ink border, `radiusXl` 28, e3 (8,8) hard shadow at
zero blur, the 14% dot layer) → **type role** (Fredoka 700 at 78, prompt Fredoka 600 at 12 uppercase
with .15em tracking) → **sampled hex** (`surfaceRaised`, `border` `#2B1B4D`, `playRed` `#D81E2C`, and
the 5px/4px stripe pitch measured on the glyph).

**Done when.**
- [ ] `.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib` reports no
      hard violations, and every `WARN` line is either resolved or answered in the PR body.
- [ ] `.claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` green — no raw geometry left
      in the painter.
- [ ] `.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh lib/theme/sunburst_colors.dart` green.
- [ ] The greyscale golden is committed and a human has answered the acceptance question in the PR.
- [ ] No `FittedBox`, `TextOverflow.ellipsis`, `withClampedTextScaling` or `textScaleFactor` anywhere
      in the epic's diff.

**Commits.**
1. `test(theme): pattern geometry and stimulusCompact slots round-trip lerp` (red)
2. `feat(theme): pattern geometry slots and the compact stimulus type step`
3. `test(stroop): word painter scene equality and draw order` (red)
4. `feat(stroop): three-pass stimulus glyph with the PlayFill pattern pass`
5. `feat(stroop): stimulus card, prompt and screen-reader value`
6. `test(stroop): greyscale and text-scale coverage for the stimulus`

---

### T08.7 — Answer keys, board assembly, motion and haptics
**Goal.** Four pressable answer keys and the board that holds them, with every state separated by at
least three non-hue channels and no chrome slot anywhere inside the rectangle.

**Tests first (TDD).**
- `test/games/stroop_rush/ui/stroop_answer_key_test.dart`:
  `each state renders its documented channels` — one case per `AnswerKeyState`, asserting the
  `PopSurface`'s `elevation`, the `Transform.translate` offset and the presence/absence of the strike
  bar: idle (e2, zero, no bar) · accepted (e3, zero, no bar) · rejected (flat, (2,2), bar) · locked
  (flat, zero, no bar).
  `the fill is the answer colour in every state` — the test that fails the moment someone "helpfully"
  paints a wrong key `danger`.
  `a resolved key drops its onTap and never passes enabled: false` — asserts
  `PopSurface.enabled == true` while `onTap == null`, because the disabled shape would swap the fill
  to `surfaceSunk` and erase the answer.
  `no Opacity or opacity-bearing wrapper appears in the key subtree`.
  `the label colour comes from answerLabel, not the call site` — ink on yellow, paper on the rest.
- `test/games/stroop_rush/ui/stroop_board_test.dart`:
  `tapping a key calls submit with that option index and nothing else` — the intent is the board's
  only upward call.
  `the board draws no HudPill, Scaffold, AppBar, SafeArea or progress bar`.
  `every key's fill box is at least kPopMinTarget on both axes` — an explicit `getSize` loop, at
  320 / 360 / 390 / 430 px.
  `the 2×2 grid sets clipBehavior: Clip.none` — otherwise the e2 shadow is sheared off.
  `keys in a row share a top and keys in a column share a left` — `moreOrLessEquals(epsilon: 0.5)`.
- `test/games/stroop_rush/ui/shake_wiring_test.dart`: `a wrong key is wrapped in E04's ShakeOnWrong and
  keyed on the wrong-tap id` — the widget itself is E04's and its two-cycle/dispose/reduce-motion
  behaviour is already asserted in `test/shared/motion/shake_on_wrong_test.dart`. What this epic tests
  is the **wiring**: the shake re-plays on a second wrong tap on the same key (the id changed), and
  under `disableAnimations` it is skipped while the sunk state and the ink strike bar still apply —
  driven with `pump(Duration)`, never `pumpAndSettle`. Re-asserting E04's cycle count here would be a
  second copy of a test for a widget this epic does not own.
- `test/games/stroop_rush/ui/stroop_board_a11y_test.dart`: each key exposes
  `isSemantics(isButton: true, label: <localized answer label>, hasTapAction: true)`, and traversal
  order is authored, not inherited.

**Implementation.**
- `lib/theme/sunburst_shape.dart` (changed) — the key geometry slots, **DERIVED** from `app.html`
  `.ans`/`.ans .key`: `answerKeyHeight` 92, `answerKeyPanelWidth` 56, `answerStrikeHeight` 6. Same
  four-places-plus-const-instance procedure.
- `lib/games/stroop_rush/ui/board/play_fill_painter.dart` — the 56pt panel painter, `shouldRepaint`
  as one value compare, delegating to `paintPlayFill` from T08.6.
- `lib/games/stroop_rush/ui/board/answer_key.dart` — `StroopAnswerKey`: `PopSurface` at
  `radiusLg`, fill `colors.answerColour(answer, colourBlind: …)`, an exhaustive switch from
  `AnswerKeyState` to `(PopElevation, Offset, bool isStruck)` with no `default:`, the ink-bordered
  pattern panel, the ink strike bar, and `Text(label, style: type.button.copyWith(color:
  colors.answerLabel(answer)))`. Never `success`, never `danger`, never `enabled: false`.
- **No `shake_on_wrong.dart` under `lib/games/`.** `ShakeOnWrong` is E04's, at
  `lib/shared/motion/shake_on_wrong.dart` — two explicit `forward(from: 0)` calls, controller disposed,
  duration from `motion.resolve(context, motion.durCelebrate)` — and E09's tile wraps the same widget.
  `StroopAnswerKey` imports it and passes `key: ValueKey(state.wrongTapId)`; a per-game copy is exactly
  the divergence `sunburst-motion-and-haptics` rule 2 exists to prevent, and E04 T04.9's policy test
  fails on a second declaration.
- `lib/games/stroop_rush/ui/stroop_board.dart` — the entry widget named by `GameDefinition.buildBoard`
  (`*_board.dart`, so the palette gate allows its slot reads): a `ConsumerWidget` reading one
  `.select` slice, a `ColoredBox(colors.surfaceSunk)` field with the 14% ink dot layer, the stimulus
  card, a 16pt gap, and a 2×2 `GridView.builder` at `crossAxisSpacing`/`mainAxisSpacing`
  `SunburstShape.space3` with `mainAxisExtent: shape.answerKeyHeight` and `clipBehavior: Clip.none`.
  No `SafeArea`, no gutter of its own beyond `app.html`'s 0/20/26 board padding.

**Files.** `lib/theme/sunburst_shape.dart`, `lib/games/stroop_rush/ui/stroop_board.dart`,
`lib/games/stroop_rush/ui/board/answer_key.dart`,
`lib/games/stroop_rush/ui/board/play_fill_painter.dart`, plus the four test files above.

**Skills.** `sunburst-game-surfaces`, `sunburst-components`, `sunburst-motion-and-haptics`,
`widget-composition`, `accessibility-as-code`, `widget-golden-and-a11y-testing`.

**Screenshot check.** `design/sunburst-pop/screens/04-stroop-rush.png`, the answer grid region.
Compare: **structure** (2×2, key order Red / Blue / Green / Yellow reading start-to-end) → **spacing
rhythm** (12pt gap both axes, 92pt key height, card-to-grid gap 16) → **surface construction** (3px
ink border, e2 (5,5) hard shadow, `radiusLg` 22, the 56pt panel closed by a 3px ink divider, patterns
at their pitches: stripe 5/4 at 45°, dots r2.6 on a 10pt lattice, rings 3pt bands on a 7pt period) →
**type role** (Fredoka 700 at 22 for labels) → **sampled hex** (`playRed`/`playBlue`/`playGreen`/
`playYellow`, paper labels except ink on yellow).

**Done when.**
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` green.
- [ ] `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` green.
- [ ] `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` green.
- [ ] `AnimationController.repeat(` appears nowhere in the diff, and `grep -rn 'class ShakeOnWrong' lib/`
      returns exactly one line, in `lib/shared/motion/`.
- [ ] Every key's fill box ≥ 48pt at 320px, verified by the `getSize` loop.

**Commits.**
1. `feat(theme): answer key geometry slots`
2. `test(stroop): answer key state channels and the enabled-false ban` (red)
3. `feat(stroop): Stroop answer key with its pattern panel and strike bar`
4. `test(stroop): the wrong key wires E04's ShakeOnWrong and re-plays per wrong tap` (red)
5. `feat(stroop): wire ShakeOnWrong into the answer key with the ink strike residue`
6. `test(stroop): board layout, tap targets and intent wiring` (red)
7. `feat(stroop): StroopBoard field, stimulus and 2x2 answer grid`

---

### T08.8 — The tier proof, the greyscale proof and the text-scale matrix
**Goal.** Prove mechanically what no screenshot can show: no gameplay colour is chrome anywhere on
the play screen, no chrome semantic slot is inside the board, and every answer is separable by
pattern alone.

**Tests first (TDD).** These *are* the deliverable; the "implementation" is whatever fixes them.
- `test/policy/stroop_tier_policy_test.dart` — a source-level policy test (the class
  `ci-pipeline-and-gates` sanctions): every file under `lib/games/stroop_rush/` that names
  `answerColour`/`answerLabel`/`play*`/`cb*` is either `*_board.dart` or under a `board/` directory;
  no file under `lib/games/` names `Color(0x`, `Colors.`, `go_router`, `Navigator.`, `Scaffold(`,
  `AppBar(`, `HudPill`, `Stopwatch(`, `Timer.periodic(` or `runNotifierProvider`; no file under
  `lib/features/` imports `games/stroop_rush/`. It duplicates the shell scripts on purpose, so a
  `flutter test` run alone catches the regression.
- `test/games/stroop_rush/ui/stroop_tier_test.dart` — the runtime half. Pump
  `PlayScaffoldScreen` with `stroopRushDefinition` at 390×844, then:
  `no gameplay colour appears outside the board subtree` — collect the `fill` of every `PopSurface`
  and the `color` of every `ColoredBox`/`DecoratedBox` **not** descended from `StroopBoard`, assert
  the set is disjoint from `{playRed, playBlue, playGreen, playYellow, playPurple, playOrange,
  cbPink, cbOrange, cbBlue, cbYellow}`.
  `no chrome semantic slot appears inside the board subtree` — the same walk restricted to
  descendants of `StroopBoard`, asserted disjoint from `{accent, accentAlt, accentDeep, success,
  successDeep, warning, danger, gameStroop, gameStroopDeep}`. `danger` **is** `playRed`, so this
  assertion is written on the slot the widget read, recorded via a test-only `SunburstColors` probe
  that tags each slot — comparing raw hexes would pass a `danger` fill on a red key.
  `the board draws no HUD pill and the shell draws no answer key`.
- `test/games/stroop_rush/ui/stroop_greyscale_golden_test.dart` (`@Tags(['golden'])`) — one greyscale
  golden of the stimulus card plus the four keys, under both palettes. Acceptance question recorded
  in the doc comment: *from this image alone, can each key be matched to the word?* If the answer is
  "only by reading the labels", the pattern pass is broken.
- `test/games/stroop_rush/ui/stroop_overflow_matrix_test.dart` — `Device.all` ×
  `[1.0, 1.3, 1.5, 2.0, 3.0]` × `[false, true]` bold, one `testWidgets` per tuple,
  `setUpAll(loadAppFonts)`, asserting `takeException(), isNull` **and** a fit assertion on the label
  box of every key.

**Implementation.** A test-only slot probe in `test/support/slot_probe.dart` that maps a rendered
`Color` back to the `SunburstColors` field(s) that carry it, returning **all** matches so the
`danger`/`playRed` collision is reported rather than silently resolved. Any defect the four tests
surface is fixed in T08.6/T08.7's files, not worked around in the test.

**Files.** `test/policy/stroop_tier_policy_test.dart`,
`test/games/stroop_rush/ui/stroop_tier_test.dart`,
`test/games/stroop_rush/ui/stroop_greyscale_golden_test.dart`,
`test/games/stroop_rush/ui/stroop_overflow_matrix_test.dart`, `test/support/slot_probe.dart`.

**Skills.** `sunburst-game-surfaces`, `widget-golden-and-a11y-testing`, `testing-strategy`,
`accessibility-as-code`, `ci-pipeline-and-gates`.

**Screenshot check.** `design/sunburst-pop/screens/04-stroop-rush.png` at text scale 1.0 as the
control; the 1.3 / 2.0 renders have no reference and are judged against the rules, not the PNG — a
layout that only works at 1.0 is a defect even though the reference cannot show it.

**Done when.**
- [ ] All four test files green, and each was seen red first by temporarily introducing the defect it
      guards (a `danger` fill on a wrong key, a `playRed` HUD pill) and reverting.
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` green.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh` green, and no
      `takeException()` swallow, `ignoreOverflowErrors` or `FlutterError.onError` assignment exists.
- [ ] `--update-goldens` appears in no committed script or workflow.

**Commits.**
1. `test(policy): pin the Stroop tier boundary at source level`
2. `test(stroop): no gameplay colour as chrome, no chrome slot in the board`
3. `test(stroop): greyscale golden proves pattern-only separability`
4. `test(stroop): overflow and fit matrix across devices, scales and bold`

---

### T08.9 — `GameDefinition`, the registry, artwork, and the full-screen comparison
**Goal.** Plug Stroop Rush into the engine with one appended registry line and zero edits under
`lib/features/**`, then sign the screen off against its reference.

**Tests first (TDD).**
- `test/games/game_registry_test.dart` (extended): `the registry exposes stroop_rush` with
  `accent == GameAccent.stroopCoral`, `scoreFormat == ScoreFormat.points`,
  `boardBackground == BoardBackground.surfaceSunk`, `difficulties == Difficulty.values`,
  `isLocked == false`.
- `test/games/stroop_rush/stroop_rush_definition_test.dart`:
  `a mechanic game declares BoardBackground.surfaceSunk` — the one pairing no `switch` can catch, per
  `accent-contract.md`; asserted for every registry entry, so E09 inherits it.
  `buildBoard returns a StroopBoard for a RunConfig` and `snapshotOf yields a BoardSnapshot`.
  `the definition holds no English literal` — title, tagline and kicker resolve from ARB by id.
- `test/l10n/arb_parity_test.dart` (extended): the ten keys this epic adds exist in every locale.
- `test/features/home/home_screen_test.dart` (extended, shell-owned file): the Stroop card renders
  from registry data — proof the shell was not edited to know about this game.

**Implementation.**
- `lib/games/stroop_rush/stroop_rush_definition.dart` — `final stroopRushDefinition =
  GameDefinition(id: const GameId('stroop_rush'), accent: GameAccent.stroopCoral, scoreFormat:
  ScoreFormat.points, difficulties: Difficulty.values, boardBackground:
  BoardBackground.surfaceSunk, isTimed: true, runLimitFor: null, buildBoard: …, buildArtwork: …,
  snapshotOf: …)` — `isTimed` because screen 04 renders a TIME pill; `runLimitFor: null` because the
  board ends the run on round count, not the shell on a clock (Risk 2).
- `lib/games/game_registry.dart` (changed) — one appended entry.
- `lib/games/stroop_rush/ui/stroop_artwork.dart` — the 64pt Home-card tile: four 5pt-radius quads
  with a 2pt (`borderWidthNested`) ink edge, in the four default answer hues, per `app.html`
  `.gart .quad i`. **See the risk below** — this file reads the gameplay palette outside a board, and
  needs the gate decision resolved before it is committed.
- ARB keys `game_stroop_rush_title`, `game_stroop_rush_tagline`, `game_stroop_rush_kicker`,
  `stroop_prompt`, `stroop_stimulus_value`.

**Files.** `lib/games/stroop_rush/stroop_rush_definition.dart`, `lib/games/game_registry.dart`,
`lib/games/stroop_rush/ui/stroop_artwork.dart`, `lib/l10n/app_en.arb`, plus the four test files above.

**Skills.** `sunburst-shell-screens`, `sunburst-game-surfaces`, `i18n-rtl-l10n`,
`flutter-architecture`, `scaffold-feature-module`.

**Screenshot check.** The full-screen sign-off, and the last gate before the PR:
`design/sunburst-pop/screens/04-stroop-rush.png` at 390×844 — **chrome and board interior together**.
Order: **structure** (top bar → coral play band with rays, dots, three pills, track → 3px ink border
→ `surfaceSunk` field with the dot layer → stimulus card → 16pt gap → 2×2 keys, optically centred in
the remaining space) → **spacing rhythm** (20pt gutter, 20pt field top padding, 26pt field bottom
padding) → **surface construction** (every raised surface: 3px ink border, correct hard-shadow step,
zero blur, zero spread) → **type role** → **sampled hex** (`gameStroop` `#FF6B5A`, `gameStroopDeep`
`#E8452F` rays, `surfaceSunk` `#FFEEDA` field, `surfaceRaised` card, the four `play*` keys).
Also compare `design/sunburst-pop/screens/01-home.png` for the Stroop card and its quad artwork.
A difference is an implementation defect; if the reference is genuinely wrong, edit `app.html`,
re-run `design/sunburst-pop/capture-screens.sh`, and commit the regenerated PNGs as a deliberate
design change in the same PR.

**Done when.**
- [ ] `git diff --stat main -- lib/features/` is empty.
- [ ] A screenshot of the built screen at 390×844 is attached to the PR beside the reference.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean
      — `nullable-getter: false` makes a missing key a compile error, which is the real gate at one
      locale. `check_arb_parity.sh` stays skipped (it needs a sibling `app_*.arb`; verified exit 2).
- [ ] A full run is played end to end on a 390×844 simulator and the run row lands in the database.

**Commits.**
1. `test(stroop): definition, registry entry and colour-role parity` (red)
2. `feat(stroop): GameDefinition and Home card artwork`
3. `feat(stroop): register Stroop Rush in the game registry`
4. `feat(l10n): Stroop Rush strings and answer labels`
5. `fix(stroop): reference-screen differences from the 04 comparison` (only if the comparison finds any)

## Gates that must pass

Run from the repo root, in this order, before the PR and again after `/simplify` and `/code-review`:

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
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart

.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/games/stroop_rush/domain
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib
.claude/skills/flutter-architecture/scripts/check_architecture.sh
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh
.claude/skills/widget-composition/scripts/check-widget-composition.sh
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                    lib
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh
```

`check_game_palette.sh` is the named gate for this epic and must print
`OK: no Color declarations, stray theme imports, or tier crossings under lib/games`.

`bash tool/skill_gates.sh` is the authoritative sweep, locally and in CI — never a
`for s in .claude/skills/*/scripts/*.sh` loop, which cannot exit 0 (29 of 49 fail argument-less, five
can never pass that way). Add a `verify_feature.sh lib/games/stroop_rush` row alongside E07's per-feature
rows in the runner's run table; `check_arb_parity.sh` stays in the skip table with its measured
one-locale reason.

## Risks and open questions

1. **The Home artwork reads the gameplay palette outside a board — and the gate forbids it.**
   `app.html .gart .quad i` paints the four quads in `--play-red/blue/green/yellow`, and
   `01-home.png` confirms it, but `check_game_palette.sh` rule 3 fails any gameplay-slot read outside
   a `*_board.dart` / `board/` file. **Decision needed from Zakaria.** Recommended default: keep the
   artwork visually identical to the reference and widen the gate's board allowance to
   `*_artwork.dart`, with the reason written into the script comment — four decorative aria-hidden
   swatches on Home are not a hint, because nobody is being timed there. The alternatives are worse:
   filing the artwork under `board/` makes the path lie, and redrawing it in neutral ink contradicts
   the reference. Reversal cost is one line in one script.
2. **Who fills the progress track, and who ends the run.** This epic decides Stroop Rush is a **fixed
   round count**, not a fixed duration: the board owns `progress` (answered / roundCount) and ends the
   run via `BoardSnapshot.outcome`, the only end signal the contract gives a game. Screen 04's 57% track
   with 17 of 30 answered is consistent with that reading. **The seam already supports both**, because
   E06 T06.3/T06.5 moved run length off the `Difficulty` enum and onto
   `GameDefinition.runLimitFor(Difficulty)`, nullable: `stroopRushDefinition` declares
   `isTimed: true` (screen 04 renders a TIME pill at 0:23, so the shell shows its clock) with
   `runLimitFor` returning `null` (the shell does not cut the run off). Confirm the reading with Zakaria
   before T08.1; if Stroop should instead be a 60-second run, that is one `runLimitFor` closure here,
   not an E06/E07 change.
3. **Blitz's six answers versus four ink patterns.** `gameplay-palette-and-cvd.md` records the
   collision: `purple` and `blue` are both `solid`, `red` and `orange` both `stripe`. This epic
   resolves it without new tokens by drawing four options from the six-colour pool under the
   constraint that the four `PlayFill`s are distinct. The cost: `{blue, purple}` and `{red, orange}`
   are mutually exclusive within one round, so blitz never offers all six at once. If the design
   later wants six keys, that is two new ink patterns authored in `sunburst-tokens` **and** a board
   layout `app.html` does not have — a design change, not a code change.
4. **`stimulusCompact` is derived and unmeasured.** A six-letter word at 78pt and text scale 2.0
   needs roughly 580pt against ~320pt available. `sunburst-tokens` owes a measured `stimulusCompact`;
   this epic adds ~54 as a derivation. Until it is measured against the design, the board is verified
   to about 1.5× and the gap is logged as a BLOCKER for E10's `design-review-workflow` sweep, not
   papered over with a clamp.
5. **The golden vector oracle may be a re-transcription, not a second design.** The generator is a
   short specification, so an "independent" implementation risks being the same code written twice.
   Mitigation: build the oracle by full enumeration where the production path uses rejection
   sampling, and state plainly in the table's header comment which rows are regression pins ("nothing
   changed") rather than correctness proofs ("this is right").
6. **64-bit integer arithmetic assumes a native target.** SplitMix64 and FNV-1a-64 do not behave the
   same compiled to JavaScript. MindForge ships iOS and Android only; record that as the reason the
   generator is allowed 64-bit ints, and if a web target is ever added, the generator must be
   re-implemented in 32-bit halves and re-versioned with a cutover, never edited in place.
7. **Announcing the ink makes the game trivial for a screen-reader user.** The stimulus `Semantics`
   value says "BLUE, red". There is no way to make the board operable non-visually without it. It is
   a recorded product decision, restated at the node, and it belongs in E10's review — not something
   to quietly "fix" by hiding the value.
8. **`lib/games/stroop_rush/` versus the brief's `lib/games/stroop/`.** The epic brief says
   `lib/games/stroop/`; `sunburst-shell-screens/references/shell-game-boundary.md` requires the
   directory name to match the definition and the `GameId`, which is `stroop_rush` (it is also the
   route segment and the DB key). This epic follows the skill. If Zakaria prefers the shorter folder,
   the `GameId`, the route and the ARB key prefixes move with it.

## Definition of done

- [ ] Branch `epic/08-stroop-rush` cut from `main`; every task's commits landed in order, tests
      committed with the code they cover.
- [ ] All ten tasks' "Done when" boxes ticked, T08.0 first.
- [ ] **`lib/games/placeholder/` is gone**, along with its registry entries, its ARB keys and its test;
      `grep -rn "placeholder" lib/ test/` returns nothing.
- [ ] `lib/games/stroop_rush/` contains the definition, `application/`, `domain/` and `ui/` and
      nothing else — no `shake_on_wrong.dart`, no PRNG; `git diff --stat main -- lib/features/` is empty.
- [ ] `test/` mirrors `lib/`; the golden vector table, the greyscale golden and the tier tests are
      committed.
- [ ] Every DERIVED value is marked as such at its declaration with a one-line reason.
- [ ] Screen 04 compared at 390×844, chrome and board interior, in the order structure → spacing →
      surface construction → type → hex; the comparison screenshot is in the PR body. Any reference
      change went through `app.html` + `capture-screens.sh` and is committed here.
- [ ] Screen 01 compared for the Stroop card and artwork.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed (or each dismissal justified in the PR).
- [ ] Every gate in "Gates that must pass" green locally.
- [ ] PR opened with a body stating: what changed, why, how it was verified, which screens were
      compared, the three DERIVED decisions taken (round count, base points, `stimulusCompact`), and
      what was deliberately left out (six-key Blitz, a timed run mode, `N-Back`).
- [ ] CI green on the PR (the pipeline E01 created).
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, `git pull` done.
- [ ] E09 can start: the `GameDefinition` seam carried a real game and needed no shell edit.
