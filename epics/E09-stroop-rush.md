# E09 · Stroop Rush

| | |
|---|---|
| **Branch** | `epic/09-stroop-rush` |
| **Depends on** | E07, E08 |
| **Unblocks** | E10, E11 |
| **Status** | Not started |

## The epic

The first game. Everything Stroop Rush is lives under `lib/games/stroop_rush/`: a pure seeded round
generator, a scoring function with a streak multiplier, one `StroopBoardNotifier`, the board widget
tree, one `GameDefinition`, and one line appended to `gameRegistryProvider`. Zero lines change in
`lib/features/**`. The board is the rectangle below the play band's ink border and nothing else — it
publishes a `BoardSnapshot` upward and draws no HUD, no `Scaffold`, no route.

It also **removes the scaffolding E08 built to stand in for it**: `lib/games/placeholder/` exists only
so the shell was runnable and screenshot-comparable before a real game existed, its files carry
`// DELETE IN E09` on their first line, and T09.0 is this epic's first commit.

Three things make this game harder than "tap the right square".

First, hue *is* the answer, so the board is `GameColourRole.mechanic`: no chrome semantic slot
(`accent`, `success`, `warning`, `danger`, `gameStroop`) may appear inside the board rectangle, and no
`play*`/`cb*` slot may leave it.

Second, the colour-blind setting is an input to round **generation**, not a paint-time swap: it caps
the answer pool to `{red, green, blue, yellow}` and is captured once into the round state, so a
mid-run Settings change cannot alter what the running round is asking.

Third — new since E04 landed — **the game is words, and words localize.** Stroop Rush ships in `en`,
`de`, `fa` and `ckb`. The stimulus word and the four answer labels come from ARB. Two of the four
locales are right-to-left Arabic script, where letters **join**, where no Latin face has coverage,
where `letterSpacing` visibly breaks the cursive connection, and where `toUpperCase()` is a no-op that
still corrupts German. The mechanic itself does not move: the colour–word mismatch is generated from
semantic `PlayAnswer` tokens, so a golden vector is byte-identical under all four locales and only the
rendering is localized. All three properties are pinned by tests, because none of them is visible in a
screenshot.

**iOS only.** Android is deferred and this epic makes no claim about it. The build, the run and the
screenshot sign-off happen on the iOS Simulator.

## Why we need it

MindForge is an engine with nothing plugged into it. E07 built `RunNotifier`, `RunConfig`,
`BoardSnapshot` and `GameDefinition`; E08 built the eight shell screens around a seam that has never
carried a real game. Until a board exists, `PlayScaffoldScreen` renders an empty pane, the results
screen has no score to format, Stats has no rows, and the `GameDefinition` contract is a claim rather
than a fact.

It is also the first time E04's localization layer is asked to carry something other than chrome.
Chrome strings are labels on boxes; here the string **is** the stimulus the player is being timed on,
painted through a three-pass `CustomPainter`, in a script the design system was never drawn for. If
the Arabic-script stimulus is illegible or the answer labels do not fit their keys, the game is
unplayable in half the shipped locales and no LTR screenshot will ever show it.

Without this epic: E10 (Schulte Grid) has no precedent to prove the engine against — the whole
"Schulte ships without editing `lib/features/**`" thesis needs a first game to be the second game's
control. E11 has no gameplay surface to run its accessibility and locale sweep over, and the three
hardest properties in the product — hue-free state encoding, the colour-blind answer path, and
Arabic-script rendering of a timed stimulus — would ship unverified.

## Current state

Honest baseline, verified by `ls` and by the toolchain check on 2026-08-19:

- **No Flutter app exists.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`, no `ios/`. Four
  commits on `main`: convention skills, three candidate design systems, the Sunburst Pop screenshots,
  and the five `sunburst-*` skills plus `CLAUDE.md`.
- Toolchain, verified on this machine: Flutter **3.44.6** stable · Dart **3.12.2** · DevTools 2.57.0 ·
  Xcode **26.6** (17F113) · CocoaPods **1.15.2**. Simulator runtimes present: iOS 18.0, 18.6, 26.5.
- The canonical device already exists and is the only honest screenshot target:
  **`MindForge iPhone 14`**, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, **exactly
  390×844 logical points**. iPhone 16 is 393×852 and 16 Pro is 402×874 — neither can be compared
  against a 390×844 reference PNG. Boot with
  `xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4`, run with
  `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`.
- `.claude/skills/` — 45 skills, including `sunburst-game-surfaces` whose
  `examples/stroop_board.dart` is a complete, compiling-shaped reference for this board, and
  `sunburst-motion-and-haptics/examples/feedback_moments.dart` whose `StroopRunNotifier` and
  `ShakeOnWrong` are this epic's commit-path and shake patterns.
- `design/sunburst-pop/screens/04-stroop-rush.png` — the LTR target: pause icon button +
  "Stroop Rush" + "Classic" chip; coral play band with rays, dots, three HUD pills
  (TIME 0:23 / SCORE 1,240 / STREAK x7 in sunshine) and a striped 57% track; a 3px ink border; then a
  `surfaceSunk` field with a 14% ink dot layer, a `surfaceRaised` stimulus card at `radiusXl` with an
  e3 shadow carrying "TAP THE COLOUR, NOT THE WORD" over the word BLUE printed in striped red, and a
  2×2 grid of four 92pt answer keys each with a 56pt ink-bordered pattern panel.
- `design/sunburst-pop/app.html` lines ~1040–1082 (screen 04) and its `.stim` / `.word` / `.pat--*` /
  `.answers` / `.ans` / `.playfill--stroop` rules are the authoritative layout; `system.html` §03 and
  §12 are the authoritative pattern and three-pass values.
- **`design/sunburst-pop/screens/rtl/` does not exist today.** E04 produces it: a `dir="rtl"` Persian
  variant of `app.html` captured by the extended `capture-screens.sh`. `screens/rtl/04-stroop-rush.png`
  is a hard input to this epic — if it is missing when the epic starts, stop and finish E04.

**Everything this epic consumes must already exist when it starts.** Verify before the first commit,
and stop if any is missing rather than building it here:

| From | Must exist |
|---|---|
| E02 (persistence) | `lib/core/score_format.dart` (`enum ScoreFormat { points, duration }` — the one score enum), `RunDraft`, `RunCommit`, and the persisted settings the locale override rides on |
| E03 (tokens) | `SunburstColors` (`PlayAnswer`, `PlayFill`, `answerColour`, `answerLabel`, `surfaceSunk`, `surfaceRaised`, `border`), `SunburstShape`, `SunburstMotion`, `SunburstType` with `SunburstScript`/`scriptOf`/`forScript`/`arabicLineFactor`, `lib/theme/game_accent.dart` (`GameAccent`, `GameColourRole`), **the bundled Arabic-script faces and the per-script `fontFamilyFallback` cascade** (T03.7 + T03.9), and `test/support/load_app_fonts.dart` + `dart_test.yaml`'s `golden` tag |
| E04 (localization) | `lib/l10n/app_en.arb` **plus `app_de.arb`, `app_fa.arb`, `app_ckb.arb`**; `l10n.yaml` with `nullable-getter: false`; `appLocalizationsProvider` and `localeProvider`; the **`ckb` delegate** that serves our ARB while delegating Material/Cupertino to `fa` (else `ar`); `LocaleNumbers.forLocale(Locale)` and `AsciiNumerals.normalize(String)`; the FSI/PDI helpers `Bidi.isolate` / `Bidi.isolateLtr` / `Bidi.isolateRtl`; `design/sunburst-pop/screens/rtl/*.png`; `test/support/harness.dart`'s `LocaleCase` / `LocaleCase.all` / `pumpLocalized` (E04 T04.10 extended E03's one harness — **there is no `test/support/locales.dart`**) |
| E05 (components) | `PopSurface`, `PopElevation`, `kPopMinTarget`, `lib/core/hud_tone.dart`, and the test support: `test/support/harness.dart` (`Device`, `Device.all` at DPR 2), `test/support/fake_feedback_service.dart` (`FakeFeedbackService`), `test/support/load_app_fonts.dart` (loading the Latin **and** Arabic-script faces) |
| E06 (motion) | `Moment`, `FeedbackService`, `feedbackServiceProvider`, `PressPhysics`, **`lib/shared/motion/shake_on_wrong.dart`** |
| E07 (engine core) | `RunConfig` (`gameId`, `difficulty`, `seed`), `Difficulty`, `GameId`, `GameDefinition` (incl. `runLimitFor`), `BoardSnapshot`, `GameHud`, `HudSlot`, `RunOutcome`, `BoardBackground`, `gameRegistryProvider`, `clockProvider`, and the repo-owned PRNG: **`fnv1a64`, `SeededGenerator` and `seedFrom` from `lib/core/seeded_generator.dart`** |
| E08 (shell) | `PlayScaffoldScreen` and its `_BoardPane`, `RunNotifier`, the three-pill `GameHud` renderer, the progress track |

If E04 named any of its files differently, **use E04's names**. A second `LocaleNumbers`, a second
bidi helper or a per-game copy of the `ckb` delegate is exactly the divergence this epic exists to
avoid — the same rule that already applies to the PRNG and to `ShakeOnWrong`.

**No fallbacks.** E07 is a hard dependency; if `lib/core/seeded_generator.dart` is missing, stop and
fix E07. Do not add `lib/core/random/seeded_rng.dart`, a `SeededRng` class or `lib/shared/determinism/`
— three names for one PRNG is how the frozen-vector guarantee in T09.2 becomes meaningless. The same
applies to `ShakeOnWrong`: it is E06's file at `lib/shared/motion/shake_on_wrong.dart` and this epic
wires it in rather than copying it under `lib/games/`.

## What we will achieve

A human can run `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`, open Stroop Rush from Home,
pick Classic, watch 3-2-1, and play a complete 30-round run: the word appears in a printed hue, four
keys respond to touch by pressing into the page, the right key lifts and holds, the wrong key sinks,
wears an ink strike bar and shakes twice, Score and Streak update in the HUD, the track fills, and at
the last round Results appears with the run persisted. Turning on Settings → "Colour-blind friendly
palette" and starting a *new* run produces a round whose answer set is drawn only from
red/green/blue/yellow, painted pink/orange/blue/yellow, and labelled to match what is painted.

Then they switch Settings → Language to **فارسی** without restarting, and play the same run: the
layout mirrors, the answer key that was top-left is now top-right, the stimulus reads قرمز printed in
blue, the score pill reads `۱٬۲۴۰`, the streak pill reads `×۷`, the hard offset shadows still fall
down-and-right, and nothing is shrunk, clipped or ellipsized. The same again in **کوردیی ناوەندی** and
in **Deutsch**, where every label is roughly a third longer.

Observable and checkable without the device:

- `flutter test` is green, including golden vectors that pin the first 24 rounds for six
  (seed × difficulty) pairs and two colour-blind pairs, computed from an independent oracle, **and
  proven byte-identical under `en`, `de`, `fa` and `ckb`**.
- `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` passes over four locales —
  it is no longer skipped for want of a sibling ARB.
- `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` passes: no `EdgeInsets.only(left:)`,
  no `Alignment.centerLeft`, no `TextAlign.left`, no `BorderRadius.only(topLeft:)` anywhere in the
  board.
- `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` prints
  `OK: no Color declarations, stray theme imports, or tier crossings under lib/games`.
- `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` is green — proof the
  board neither navigates, nor builds a `Scaffold`/`AppBar`/`SafeArea`, nor owns a clock, and that no
  file under `lib/features/**` names `games/stroop_rush/`.
- A greyscale golden of the stimulus card plus the answer row answers "which key matches the word?"
  from pattern alone, in `en` and in `fa`.
- `git diff --stat main -- lib/features/` is empty.
- The built screen at 390×844 matches `design/sunburst-pop/screens/04-stroop-rush.png` (LTR, `en`)
  **and** `design/sunburst-pop/screens/rtl/04-stroop-rush.png` (RTL, `fa`) — chrome and board interior
  — in structure, spacing, surface construction, type role and sampled hex.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Rules 2 (dumb widgets), 3 (one ViewModel over immutable state), 8 (injected side effects), 10 (complexity limits) and 12 (RTL/a11y by construction) govern every task below. |
| `i18n-rtl-l10n` | Now co-owns this epic. Rule 1 (`nullable-getter: false` makes a missing key a compile error), rule 2 (key + placeholder parity across `en`/`de`/`fa`/`ckb`, gated by `check_arb_parity.sh`), rule 4 (direction is a locale consequence — never a hardcoded root `Directionality`), rule 5 (directional-only geometry, gated by `check_i18n_bans.sh`), rule 7 (normalize to ASCII before any parse), rule 8 (one FSI/PDI helper for mixed runs like `×7`), rule 9 (bundled fonts with a fallback cascade covering Arabic script). `references/rtl-and-bidi.md` carries the allow/ban table and the "load real fonts, never Ahem, for the shaping lane" rule; `references/numerals-and-calendars.md` carries the `fa`/`ar` digit-block distinction and the `ckb`-has-no-intl-symbols trap. |
| `sunburst-game-surfaces` | Owns this epic. Rule 2 (the two-tier boundary), rule 3 (correct/wrong are never coloured on a `mechanic` board), rule 4 (the CVD flag drives generation), rule 5 (`PlayFill` on key *and* glyph), rule 6 (the three-pass stimulus), rule 10 (`BoardSnapshot`, no HUD), rule 11 (three slots, one highlight). `references/board-states-and-layout.md` carries the key/stimulus state matrix and the exact three passes; `examples/stroop_board.dart` is the reference implementation. |
| `sunburst-tokens` | Every hex, radius, shadow step and duration the board spends, and the four-places-plus-const-instance procedure (rule 12) for the `SunburstShape`/`SunburstType` slots T09.7, T09.8 and T09.9 must add. Rule 6 states why the stimulus is never a bare `Text`; rule 10 fixes the bundled-font rule the Arabic-script cascade extends. |
| `sunburst-components` | `PopSurface` is the only surface constructor; `PopElevation` the only elevation vocabulary; rule 6 carries the answer-key exception — a resolved key drops its `onTap`, it never passes `enabled: false`. Rule 10 fixes the 48px target floor on the fill box, not the shadow. Rule 1 is why the hard shadow is a `BoxShadow` offset, not a directional inset — the thing that does **not** mirror. |
| `sunburst-shell-screens` | `references/shell-game-boundary.md` is the exact `GameDefinition` / `BoardSnapshot` / `RunConfig` contract, the `lib/games/<id>/{definition, application, domain, ui}` layout, and the forbidden-in-`lib/games/**` table this epic is measured against. Rule 4 fixes the three HUD slots this game fills. |
| `sunburst-motion-and-haptics` | The moment rows this board fires: `answerCorrect`, `answerWrong` (two explicit `forward(from: 0)` calls, never `repeat`), `streakMilestone` (latched to multiples of 5), and rule 3 — a press is a state, its transform is the only animation, and reduce-motion drops the transform but keeps the shadow collapse. |
| `seeded-determinism-and-golden-vectors` | Rules 4–7 (one entropy source, hash + mix, frozen salts), 9 (a shipped generator is frozen), 10–12 (the vector table, the independent oracle, CI verifies and never blesses). This is what makes a run reproducible from a bug report — and, in T09.2, what proves the locale cannot reach the generator. |
| `state-management-riverpod` | `StroopBoardNotifier` as one `Notifier` over one immutable state with value equality, family-keyed by `RunConfig` and `autoDispose`; intent methods only; `ref.watch(...select(...))` in the View. Rule 4 (derive, don't store) is why the multiplier is a function; rule 10 bans `DateTime.now()` in state logic. |
| `custom-canvas-and-gestures` | The stimulus glyph and the pattern panel are `CustomPainter`s: the View/Painter/Scene split, `shouldRepaint` as one value compare, zero allocation inside `paint()`, `ExcludeSemantics` + a sibling `Semantics` node. Rule 9 (never format or shape numerals inside `paint()`) and rule 11 (geometry is direction-agnostic; only chrome mirrors) are the two that decide how the glyph behaves under RTL. `references/text-and-shapes.md` owns the measured `TextPainter` fit and the unconstrained-layout gotcha. |
| `widget-golden-and-a11y-testing` | `test/support/harness.dart`, `useDevice` before `pumpApp`, the one-`testWidgets`-per-tuple overflow matrix (rule 6 — overflow reports once per `RenderObject`), the fit assertion goldens cannot make (rule 7), and rule 11: two golden lanes, `loadAppFonts()` on both, and a real-font lane that is the **only** thing that proves Arabic script joins. |
| `testing-strategy` | Pure round generation and scoring are `package:test` unit and property tests, never `pumpWidget`; the notifier is driven headlessly with `ProviderContainer`; fakes are bare `implements`, not mocks. |
| `accessibility-as-code` | Rule 6 (never encode state through colour alone) is the whole reason for `PlayFill`; rules 4–5 ban the clamp/`FittedBox`/ellipsis escape hatches the 78pt stimulus and the eight-letter Sorani label will both tempt; rule 8 fixes the tap-target floor; rule 10 is why `boldText` is a tuple in the matrix. |
| `dart3-idioms-and-coding-standards` | `StroopRound`, `StroopDifficultyProfile`, `StroopScore` and `StroopBoardState` are immutable `final class`es with value equality; the `AnswerKeyState` switch is exhaustive with no `default:`; generation and scoring are total functions; the complexity table (method ≤30, `build()` ≤80, file ≤300) is why the board splits into seven files. |
| `widget-composition` | Extracted `const` widget classes, never `_buildX()` methods; the `GridView` cross/main-axis spacing trap; rule 12 — directional geometry and theme-sourced style only; `clipBehavior: Clip.none` so the hard shadow is not sheared off. Rule 5 is why `NumberFormat` never appears in a `build()`. |
| `flutter-architecture` | T09.11 places the definition, `application/`, `domain/` and `ui/` in the downward-only DAG and proves `lib/features/**` gained nothing; also the rule that `lib/games/**` may import `lib/core/`, `lib/l10n/`, `lib/theme/`, `lib/ui/` and `lib/shared/` but never `lib/features/`. |
| `scaffold-feature-module` | T09.11 only: the fixed folder shape a game module takes and `scripts/verify_feature.sh`, run against `lib/games/stroop_rush` as one directory (it takes one, not the repo root). |
| `ci-pipeline-and-gates` | T09.10's source-level policy tests are the sanctioned grep-gate class: rule 7's three-criteria bar, comment-stripping, accumulate-and-fail-once, and a reason a stranger can act on. Rule 9 is why `--update-goldens` never enters a script. |

## Tasks

### T09.0 — Remove the placeholder registry
**Goal.** Delete the scaffolding E08 built to stand in for a real game, in this epic's **first commit**,
so the shell is never carrying both.

**Why first and not last.** E08 T08.1 shipped `lib/games/placeholder/` with `// DELETE IN E09` on the
first line of every file and recorded in its Risk 2 that "E09's first commit removes the directory and
the ARB key groups. If E09 ships without removing it, that is a review reject on E09." Doing it first
also means every test below runs against a registry that holds only real games, so a Home-screen
expectation written mid-epic does not have to be rewritten at the end.

**Tests first (TDD).** The deletions *are* red-first: removing the directory breaks
`test/games/placeholder_registry_test.dart` and E08's `home_screen_test.dart` expectations, and that is
the signal. Before deleting, update those tests to their post-placeholder shape:
- delete `test/games/placeholder_registry_test.dart` entirely — its subject is gone;
- in `test/features/home/home_screen_test.dart` (E08's file, edited here) the fake-registry expectation
  drops from "three cards for the fake registry" to whatever the fakes now hold; the test drives
  `fakeAlphaDefinition`/`fakeBetaDefinition`, not the placeholder definitions, so this is an expectation
  edit and not a rewrite. **If it turns out to be a rewrite, the shell was reading the real registry
  where it should have been reading the fakes** — fix that, and say so in the PR.
- `test/games/game_registry_test.dart` asserts the registry is empty again until T09.11 appends
  Stroop Rush.
- `test/l10n/arb_parity_test.dart` (E04's file) asserts the twelve `game_placeholder_*` keys are gone
  from **all four** ARBs, not just from the template. A key deleted from `app_en.arb` and left in
  `app_fa.arb` is an *extra* key and fails `check_arb_parity.sh` — which now actually runs.

**Implementation.** `git rm -r lib/games/placeholder/`; drop the three placeholder entries from
`lib/games/game_registry.dart`; remove the twelve `game_placeholder_*` keys from **each of**
`lib/l10n/app_en.arb`, `app_de.arb`, `app_fa.arb`, `app_ckb.arb` and their entries in
`lib/l10n/game_strings.dart`; run `flutter gen-l10n`. Nothing else in `lib/features/**` changes — if it
must, that is a seam defect to report, not to patch.

**Files.** `lib/games/placeholder/**` (deleted), `lib/games/game_registry.dart`,
`lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`, `lib/l10n/app_ckb.arb`,
`lib/l10n/game_strings.dart`, `lib/l10n/app_localizations*.dart` (regenerated),
`test/games/placeholder_registry_test.dart` (deleted), `test/games/game_registry_test.dart`,
`test/l10n/arb_parity_test.dart`, `test/features/home/home_screen_test.dart`.

**Skills.** `sunburst-shell-screens`, `i18n-rtl-l10n`, `testing-strategy`.

**Screenshot check.** n/a — but note that until T09.11 lands, Home renders **zero** game cards. That is
expected mid-epic and is not a comparison against `01-home.png` or `rtl/01-home.png`; the Home
comparison is T09.11's.

**Done when.**
- [ ] `ls lib/games/` shows no `placeholder/`; `grep -rn "placeholder" lib/ test/` returns nothing.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` green over four locales.
- [ ] `flutter test` green; `flutter analyze --fatal-infos` clean after `flutter gen-l10n`.
- [ ] `git diff --stat main -- lib/features/` shows only `home_screen_test.dart`'s sibling under
      `test/` — no `lib/features/**` source line changed.

**Commits.**
1. `Remove the E08 placeholder registry, its board and its strings in all four locales`

---

### T09.1 — Difficulty profiles, the round value type, and the seeded generator
**Goal.** Turn `(seed, difficulty, isColourBlindPalette)` into a reproducible sequence of
`StroopRound`s with no Flutter import, no clock read and **no locale input of any kind**.

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
- `no round carries a string` — reflection-free structural assertion: `StroopRound.canonical()`
  contains only ASCII digits and separators, and `PlayAnswer` is compared by `index`, never by
  `toString()` or `name`. This is the test that fails if a localized label is ever smuggled into the
  domain.
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
  and enum **indices** (never `toString()`, never `name` — both are a step from a translated string).
- `lib/games/stroop_rush/domain/stroop_round_generator.dart` — `const kStroopFeatureSalt`
  (a frozen 64-bit constant) and `const kStroopGeneratorVersion = 1`;
  `List<StroopRound> generateStroopRounds({required int seed, required Difficulty difficulty,
  required bool isColourBlindPalette})`. Seed derivation is `fnv1a64('stroop_rush:$seed') ^
  kStroopFeatureSalt ^ difficulty.index`, mixed through `SeededGenerator` (SplitMix64) from
  `lib/core/seeded_generator.dart`. Draw order is fixed and documented as a contract: options first
  (rejection-sampled until four distinct `PlayFill`s), then the ink from the options, then congruency,
  then the word. Total function — it never throws. **It takes no `Locale`, no `AppLocalizations`, and
  imports nothing from `lib/l10n/`.**

**Files.** `lib/games/stroop_rush/domain/stroop_difficulty_profile.dart`,
`lib/games/stroop_rush/domain/stroop_round.dart`,
`lib/games/stroop_rush/domain/stroop_round_generator.dart`,
`test/games/stroop_rush/domain/stroop_difficulty_profile_test.dart`,
`test/games/stroop_rush/domain/stroop_round_generator_test.dart`.
The PRNG is imported from `lib/core/seeded_generator.dart` (E07) — this task adds no generator file
and no fallback.

**Skills.** `seeded-determinism-and-golden-vectors`, `dart3-idioms-and-coding-standards`,
`testing-strategy`, `sunburst-game-surfaces`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/games/stroop_rush/domain/` green.
- [ ] `.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/games/stroop_rush/domain` exits 0.
- [ ] No `package:flutter`, no `package:intl` and no `lib/l10n/` import under
      `lib/games/stroop_rush/domain/` — verified by `grep`, and re-verified structurally in T09.10.
- [ ] Every DERIVED number carries a one-line reason at its declaration.

**Commits.**
1. `test(stroop): difficulty profile and round generation invariants` (red)
2. `feat(stroop): difficulty profiles and the StroopRound value type`
3. `feat(stroop): seeded round generator with a frozen salt and draw order`

---

### T09.2 — Golden vectors: rounds pinned per seed × difficulty, and identical in every locale
**Goal.** Freeze what each `(seed, difficulty, cvd)` means, so a refactor that renames a variable
cannot quietly change what a player was asked — and prove that changing the app's locale cannot change
it either.

**Tests first (TDD).** `test/games/stroop_rush/domain/stroop_golden_vectors_test.dart` —
- `the generator reproduces every frozen vector`: for each row, generate the sequence, fingerprint the
  first 24 rounds, `expect(fingerprint, equals(v.fingerprint))` and
  `expect(incongruentCount, equals(v.incongruentCount))` with `reason: v.note`. Rows cover the range
  boundaries a bug hides behind: seed `0`, seed `1`, a mid-range seed, `0x7FFFFFFF`, each × classic;
  plus chill and blitz at the mid-range seed; plus two rows with `isColourBlindPalette: true`.
- `the vector table has no duplicate fingerprints` — catches a copy-paste row.
- **`the vectors are identical under en, de, fa and ckb`** — the locale-invariance test D3 demands.
  For each of `LocaleCase.all` (`en`, `de`, `fa`, `ckb`), set `Intl.defaultLocale` to that tag **and**
  install the matching `NumberFormat` as the ambient formatter, then regenerate every vector row and
  assert the fingerprint is unchanged. Failure modes it catches, both of which are one careless commit
  away: a `PlayAnswer.name` that got localized, and a fingerprint built by `String` interpolation of an
  `int` under an ambient `Intl.defaultLocale = 'fa'`, which would emit `۱۲` and change the hash. The
  fingerprint helper itself must therefore be built from `int.toRadixString(16)`, never from
  `NumberFormat` and never from `'$i'`.

**Implementation.**
- `test/games/stroop_rush/domain/stroop_vectors.dart` — `final class StroopRoundVector` (`seed`,
  `difficulty`, `isColourBlindPalette`, `fingerprint`, `incongruentCount`, `note`) and
  `const stroopRoundVectors = <StroopRoundVector>[...]`, with a header comment naming the oracle and
  stating that the table is locale-free by construction.
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

**Skills.** `seeded-determinism-and-golden-vectors`, `testing-strategy`, `i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Ten vector rows committed, each with a `note` saying why the row exists.
- [ ] The locale-invariance test runs all ten rows × four locales = 40 assertions and is green.
- [ ] The oracle imports nothing from `lib/games/stroop_rush/domain/stroop_round_generator.dart`.
- [ ] `tool/update_stroop_vectors.dart` appears in no workflow file.
- [ ] Flipping one constant in the generator turns the vector test red (verify by hand, then revert).
- [ ] Setting `Intl.defaultLocale = 'fa'` around the fingerprint helper does **not** turn it red
      (verify by hand) — if it does, the helper is formatting instead of hashing.

**Commits.**
1. `test(stroop): independent reference generator for golden vectors`
2. `test(stroop): freeze round vectors for eight seed/difficulty pairs`
3. `test(stroop): prove the vectors are identical in en, de, fa and ckb`
4. `chore(stroop): local-only vector regeneration command`

---

### T09.3 — The colour-blind generation path
**Goal.** Make the colour-blind flag change the **answer set**, captured once at round start — not a
paint-time substitution — and make the label follow the painted hue in every locale.

**Tests first (TDD).** `test/games/stroop_rush/domain/stroop_colour_blind_test.dart`:
- `with the flag on, no round offers purple or orange` — all three difficulties, 500 seeds; this is
  the test that fails if the flag is only read at paint time, because blitz's pool would still draw
  them.
- `blitz under the flag generates the same pool as classic` — the four CB slots are the whole set.
- `the same seed produces a different sequence with the flag on` — proves generation, not rendering,
  branched.
- `every round records the flag it was generated under` — `round.isColourBlindPalette` equals the
  input for every round in the sequence.
- `the label key follows the painted hue, not the enum name` —
  `answerLabelKey(PlayAnswer.green, colourBlind: true) == 'play_answer_orange'` and
  `answerLabelKey(PlayAnswer.red, colourBlind: true) == 'play_answer_pink'`; with the flag off they
  are `play_answer_green` / `play_answer_red`. Key selection is a pure function of
  `(PlayAnswer, bool)` and never of the locale.
- `the offered set still has four distinct fills under the flag` — patterns are not part of the
  setting.

**Implementation.**
- Extend `generateStroopRounds` to intersect the profile pool with
  `{red, green, blue, yellow}` when `isColourBlindPalette` is true, **before** the first draw, and
  stamp the flag onto every `StroopRound`.
- `lib/games/stroop_rush/application/stroop_answer_labels.dart` —
  `String answerLabelKey(PlayAnswer a, {required bool colourBlind})`,
  `String answerLabel(PlayAnswer a, {required bool colourBlind, required AppLocalizations l10n})` and
  `String stimulusWord(PlayAnswer a, {required bool colourBlind, required AppLocalizations l10n})`.
  This file names `PlayAnswer` only; it never names a `play*`/`cb*` slot, `answerColour` or
  `answerLabel(` on `SunburstColors`, so it stays legal outside `board/`. The two lookups are separate
  because the design uses two different display forms (see T09.5) and **`toUpperCase()` is banned** —
  it is a no-op in Arabic script and wrong in German (`ß`).

**Files.** `lib/games/stroop_rush/domain/stroop_round_generator.dart` (changed),
`lib/games/stroop_rush/domain/stroop_round.dart` (changed),
`lib/games/stroop_rush/application/stroop_answer_labels.dart`,
`test/games/stroop_rush/domain/stroop_colour_blind_test.dart`.

**Skills.** `sunburst-game-surfaces`, `seeded-determinism-and-golden-vectors`, `i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface). The setting's own preview row is `08-settings.png` /
`rtl/08-settings.png` and belongs to E08.

**Done when.**
- [ ] The two colour-blind rows added to the vector table in T09.2 still pass, in all four locales.
- [ ] `answerLabelKey` and `stimulusWord` take no `Locale` argument — the locale reaches them only
      through the `AppLocalizations` instance the View already holds.
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` green — proof
      `stroop_answer_labels.dart` did not smuggle a gameplay slot outside `board/`.

**Commits.**
1. `test(stroop): the colour-blind flag caps the generated answer set` (red)
2. `feat(stroop): capture the colour-blind flag into round generation`
3. `feat(stroop): answer label keys follow the painted hue under the flag`

---

### T09.4 — Scoring and the streak multiplier
**Goal.** One total, pure function from `(score, correct)` to a new score, with a streak multiplier
that is derived, never stored twice. No formatting here — points are integers until T09.6 renders them.

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
- `StroopScore holds no formatted string` — every field is an `int`; the class has no `String` member
  and no `NumberFormat` import. The regression this pins is "someone put the display value on the
  value type", which would then be wrong the moment the locale changes mid-run.

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

### T09.5 — The colour words in four locales, and the answer-key label fit
**Goal.** Author every string this game shows in `en`, `de`, `fa` and `ckb`, and prove the longest
label in each locale fits its key at every width and text scale **without shrinking anything**.

**Why it is its own task.** The colour words are not chrome. They are the stimulus and the four
answers; their lengths differ by a factor of two across the shipped locales (`Rot` is three
characters, `پرتەقاڵی` is eight), and the answer key's label box is fixed by a 92pt key that also
carries a 56pt pattern panel. Authoring the strings and asserting the layout in one task keeps the
translation and the box that has to hold it in the same diff.

**The strings.** Twenty-two keys × four locales. Two display forms, deliberately separate, because
`toUpperCase()` is banned:

| Key group | `en` | `de` | `fa` | `ckb` |
|---|---|---|---|---|
| `stroop_word_red` … (stimulus, display form) | RED, BLUE, GREEN, YELLOW, PURPLE, ORANGE, PINK | ROT, BLAU, GRÜN, GELB, LILA, ORANGE, ROSA | قرمز، آبی، سبز، زرد، بنفش، نارنجی، صورتی | سوور، شین، سەوز، زەرد، مۆر، پرتەقاڵی، پەمەیی |
| `play_answer_red` … (key label) | Red, Blue, Green, Yellow, Purple, Orange, Pink | Rot, Blau, Grün, Gelb, Lila, Orange, Rosa | same as the word form | same as the word form |
| `stroop_prompt` | Tap the colour, not the word | Tippe auf die Farbe, nicht auf das Wort | روی رنگ بزن، نه روی کلمه | دەست بنێ بە ڕەنگەکە، نەک وشەکە |
| `stroop_stimulus_value` | `{word}, printed in {ink}` | `{word}, gedruckt in {ink}` | `{word}، چاپ‌شده با رنگ {ink}` | `{word}، بە ڕەنگی {ink} چاپکراوە` |
| `hud_score`, `hud_streak`, `hud_streak_value` | Score, Streak, `x{count}` | Punkte, Serie, `x{count}` | امتیاز، رشته، `×{count}` | خاڵ، زنجیره، `×{count}` |
| `game_stroop_rush_title/tagline/kicker` | authored per locale | authored per locale | authored per locale | authored per locale |

The `fa` and `ckb` columns are **machine-quality drafts pending native review** — see Risk 3. They are
committed so the layout can be tested against realistic lengths, and every one of them carries
`"@@x-review": "native-speaker-pending"` in the `@key` metadata of `app_fa.arb` / `app_ckb.arb`.

**Tests first (TDD).**
- `test/l10n/stroop_strings_test.dart`:
  `every stroop key exists in all four locales with identical placeholders` — drives the same
  comparison `check_arb_parity.sh` does, so `flutter test` alone catches it.
  `stroop_stimulus_value uses both placeholders in every locale` — `{word}` and `{ink}`; word order
  differs per locale and that is the point of the placeholder.
  `no stroop string is produced by toUpperCase` — source grep over `lib/games/stroop_rush/` for
  `toUpperCase(`/`toLowerCase(`, expecting zero hits.
  `hud_streak_value takes a String, not an int` — the placeholder type is `String`, because the
  notifier formats through `LocaleNumbers.of(locale)`; a `format: decimalPattern` `int` placeholder
  would send `ckb` through `intl`'s missing symbol data and silently emit Latin digits (D2/D3).
- `test/games/stroop_rush/ui/stroop_answer_key_fit_test.dart` — one `testWidgets` per
  (device, locale, palette) tuple over `Device.all` × `LocaleCase.all` × `{default, colourBlind}`
  = 3 × 4 × 2 = 24 cases, `setUpAll(loadAppFonts)`. Each pumps the key with **that locale's longest
  label** (`en` Yellow, `de` Orange, `fa` نارنجی, `ckb` پرتەقاڵی — recomputed in the test from the
  loaded ARB, never hardcoded, so a retranslation cannot silently invalidate it) and asserts:
  `takeException(), isNull`; the label's `getRect` sits inside the key's label box with no overflow;
  the key's fill box is still ≥ `kPopMinTarget`; and **no `FittedBox`, `TextOverflow.ellipsis` or
  clamped scaler appears in the subtree**.
- `test/games/stroop_rush/ui/stroop_label_style_test.dart`:
  `the label takes buttonCompact only when button does not fit` — asserts the resolved `TextStyle` is
  `type.button` for `de`/`en` at scale 1.0 and `type.buttonCompact` for `ckb` at 320px × scale 2.0.
  The step is a **smaller base style**, per `accessibility-as-code` rule 5 and
  `sunburst-game-surfaces` rule 9 — never a shrink.
  `no Arabic-script style carries letterSpacing` — for `fa` and `ckb`, the resolved `stimulus`,
  `stimulusCompact`, `button`, `buttonCompact` and prompt styles all have `letterSpacing == null || 0`.
  Flutter's `letterSpacing` inserts advance after every glyph, which visually severs the cursive
  joins; the `.15em` tracking `app.html` puts on the uppercase prompt is a Latin-only decision.

**Implementation.**
- `lib/l10n/app_en.arb` (template, keys + `@metadata` first), then `app_de.arb`, `app_fa.arb`,
  `app_ckb.arb` with the same keys and the same placeholder names.
- `lib/theme/sunburst_type.dart` (changed) — add `buttonCompact` (**DERIVED**, ~18 against `button`'s
  22) so a long label takes a smaller base style. Four places plus the const instance, per
  `sunburst-tokens` rule 12. The Arabic-script `fontFamilyFallback` cascade and the zero-tracking rule
  are E04's; this task only consumes them and asserts them.
- `lib/games/stroop_rush/application/stroop_answer_labels.dart` (changed) — `stimulusWord` reads the
  `stroop_word_*` group, `answerLabel` reads the `play_answer_*` group.

**Files.** `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`,
`lib/l10n/app_ckb.arb`, `lib/theme/sunburst_type.dart`,
`lib/games/stroop_rush/application/stroop_answer_labels.dart`,
`test/l10n/stroop_strings_test.dart`,
`test/games/stroop_rush/ui/stroop_answer_key_fit_test.dart`,
`test/games/stroop_rush/ui/stroop_label_style_test.dart`, `test/theme/sunburst_type_test.dart`.

**Skills.** `i18n-rtl-l10n`, `sunburst-tokens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `sunburst-game-surfaces`.

**Screenshot check.** `design/sunburst-pop/screens/04-stroop-rush.png` for the `en` label rendering
(Fredoka 700 at 22, title case, paper on all but yellow) and
`design/sunburst-pop/screens/rtl/04-stroop-rush.png` for the `fa` rendering (the Arabic-script display
face at the same optical size, label on the **end** side of the key, pattern panel on the start side).

**Done when.**
- [ ] All 22 keys present in all four ARBs; `check_arb_parity.sh lib/l10n` green.
- [ ] The 24-case fit matrix green with real fonts loaded.
- [ ] `grep -rn 'toUpperCase(\|toLowerCase(' lib/games/stroop_rush/` returns nothing.
- [ ] `grep -rn 'letterSpacing' lib/games/stroop_rush/` returns nothing — tracking is a theme
      decision, not a board decision.
- [ ] Every `fa` and `ckb` message carries the `native-speaker-pending` review marker.

**Commits.**
1. `test(l10n): stroop string parity, placeholder shape and the toUpperCase ban` (red)
2. `feat(l10n): Stroop colour words, prompt and HUD labels in en, de, fa and ckb`
3. `feat(theme): buttonCompact type step for long answer labels`
4. `test(stroop): longest-label fit per locale across devices and palettes`

---

### T09.6 — `StroopBoardNotifier` and the `BoardSnapshot`
**Goal.** One family-keyed notifier that owns the deck, the score, the key states and the latches,
and publishes exactly one `BoardSnapshot` — three HUD slots, a progress value, and an outcome — with
every number formatted once, in the notifier, for the active locale.

**Tests first (TDD).** `test/games/stroop_rush/application/stroop_board_notifier_test.dart`, driven
headlessly with `ProviderContainer` and E05's `FakeFeedbackService` from
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
- `the board never reads the run phase` — asserted statically in T09.10's policy test; here, assert
  that overriding `runNotifierProvider` with a throwing stub does not break the notifier.
- **`the score is formatted once, in the notifier, per locale`** — for 1240, `slotB.value` is
  `'1,240'` under `en`, `'1.240'` under `de`, `'۱٬۲۴۰'` under `fa`, and `'۱٬۲۴۰'` under `ckb`. The
  `ckb` row is the one that fails if the formatter was resolved implicitly instead of pinned through
  `LocaleNumbers` — `intl` has no `ckb` number symbols and falls back to Latin silently.
- **`the streak value is localized and bidi-isolated`** — for a streak of 7, `slotC.value` is `'x7'`
  under `en` and `'×۷'` under `fa`/`ckb`, and the rendered string is wrapped by `Bidi.isolateLtr` so the
  multiplier sign and the numeral do not reorder inside the RTL pill. The test asserts the isolate
  characters are present in the **display** string and absent from anything the notifier would persist.
- **`the outcome carries an integer, not a display string`** — `RunOutcome`'s score field is an `int`;
  the shell formats it for Results. Persisting `'۱٬۲۴۰'` would make the Stats table unsortable and
  unparseable, which is `i18n-rtl-l10n` rule 6.

**Implementation.**
- `lib/games/stroop_rush/domain/stroop_board_state.dart` — `final class StroopBoardState`
  (`rounds`, `index`, `score`, `keyStates: List<AnswerKeyState>`, `wrongKeyIndex`, `wrongTapId`,
  `lastMilestone`, `isColourBlindPalette`) with value equality and `copyWith`; `enum AnswerKeyState
  { idle, accepted, rejected, locked }`.
- `lib/games/stroop_rush/application/stroop_board_notifier.dart` —
  `final class StroopBoardNotifier extends Notifier<StroopBoardState>` behind
  `stroopBoardNotifierProvider = NotifierProvider.autoDispose.family<...>` keyed by `RunConfig`;
  intent method `void submit(int optionIndex)`; a derived `BoardSnapshot get snapshot` exposed
  through `stroopBoardSnapshotProvider(config)` so `GameDefinition.snapshotOf` has a
  `ProviderListenable<BoardSnapshot>` to hand the shell. Haptics go through
  `ref.read(feedbackServiceProvider).fire(...)` on the commit frame, once, with the milestone
  **replacing** the correct-answer tick rather than stacking on it.
- HUD slots: A = Time (label localized, value `''` — the shell composes it from its own clock),
  B = Score (`ref.watch(localeNumbersProvider)`, formatted in the notifier),
  C = Streak (`hud_streak_value` with the already-formatted count as a `String` placeholder, wrapped
  in `Bidi.isolateLtr`; `HudTone.highlight` when the multiplier is above 1, i.e. streak ≥ 5; **DERIVED**,
  matching screen 04's sunshine STREAK pill).
- The notifier watches `localeProvider` (E04) so a live language switch re-formats the pills without a
  restart, and re-reads nothing else — the deck is already generated and must not regenerate.

**Files.** `lib/games/stroop_rush/domain/stroop_board_state.dart`,
`lib/games/stroop_rush/application/stroop_board_notifier.dart`,
`test/games/stroop_rush/application/stroop_board_notifier_test.dart`,
`test/support/fake_feedback_service.dart` (E05's file — imported, not re-created),
`test/support/harness.dart` (E03's file, extended by E04 T04.10 with `LocaleCase` and `pumpLocalized` — imported, not re-created).

**Skills.** `state-management-riverpod`, `sunburst-shell-screens`, `sunburst-motion-and-haptics`,
`testing-strategy`, `i18n-rtl-l10n`.

**Screenshot check.** n/a (no visual surface — the HUD it feeds is compared in T09.11, LTR and RTL).

**Done when.**
- [ ] No `Timer`, `Ticker`, `Stopwatch`, `DateTime.now()` or `runNotifierProvider` read anywhere in
      `lib/games/stroop_rush/`.
- [ ] `NumberFormat(` is constructed nowhere under `lib/games/` — only `LocaleNumbers` is called.
- [ ] A live locale switch mid-run re-formats the pills and leaves `state.rounds` identical
      (asserted in the notifier test).
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh` green.
- [ ] The notifier holds no `BuildContext` and constructs no collaborator.

**Commits.**
1. `test(stroop): board notifier commit path, latches and snapshot shape` (red)
2. `feat(stroop): StroopBoardState and the answer key state machine`
3. `feat(stroop): StroopBoardNotifier publishing a BoardSnapshot`
4. `test(stroop): HUD values format per locale and survive a live language switch` (red)
5. `feat(stroop): pin the HUD number format per locale and isolate the streak run`

---

### T09.7 — The stimulus: the three-pass glyph and its pattern geometry
**Goal.** Paint the word as ink stroke → hue fill → ink `PlayFill` clipped to the glyph, so a yellow
stimulus reads at ink-on-cream 14.55:1 and every hue is separable in greyscale. Latin script first;
T09.8 takes the Arabic-script pass.

**Tests first (TDD).**
- `test/theme/sunburst_shape_test.dart` (extended): the new pattern-geometry slots survive
  `copyWith` and interpolate in `lerp` — the classic slot-added-but-forgotten-in-`lerp` rot.
- `test/games/stroop_rush/ui/stroop_word_painter_test.dart`:
  `shouldRepaint is false for an identical scene and true for each changed field` — one case per
  field of the scene value type, **including `textDirection`**; `paint allocates no Paint` — the
  painter's `Paint` fields are `final` and the **identical instances** are used across two `paint()`
  calls on a recording canvas, matching E08 T08.2's `halftone_dots_test.dart`.
  (`Picture.approximateBytesUsed` measures recorded ops, not Dart allocations, and would pass over a
  painter that allocates a fresh `Paint` per frame — the structural gate is `check_painter_hygiene.sh`.)
  `the outline pass is drawn before the fill pass` — verified with a recording `Canvas` fake that logs
  draw calls in order.
  `the scene carries a pre-formatted word and no locale` — `StroopWordScene` has a `String word` and a
  `TextDirection`, and no `Locale`, no `AppLocalizations` and no `NumberFormat`, per
  `custom-canvas-and-gestures` rule 9.
- `test/games/stroop_rush/ui/stimulus_glyph_golden_test.dart` (`@Tags(['golden'])`,
  `setUpAll(loadAppFonts)`): one golden per answer × palette at scale 1.0 in `en`, and one
  **greyscale** golden (a `ColorFiltered` matrix wrapper) of all four default answers side by side.
  The greyscale acceptance question, recorded in the test's doc comment: *from this image alone, can
  each glyph be told from the others?*
- `test/games/stroop_rush/ui/stimulus_text_scale_test.dart`: one `testWidgets` per
  (device, scale) tuple over `Device.all` × `[1.0, 1.3, 1.5, 2.0, 3.0]` in `en` — never a loop inside
  one test, because overflow reports once per `RenderObject`. Asserts `takeException(), isNull`
  **and** that the painted glyph's measured height fits inside the stimulus card's inner box.

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
  Exhaustive switch over `PlayFill`, no `default:`. The pattern lattice is a fixed coordinate space —
  it is **not** mirrored for RTL (`custom-canvas-and-gestures` rule 11: geometry is
  direction-agnostic, only chrome mirrors), and a stripe at 45° looks identical under either reading
  direction anyway.
- `lib/games/stroop_rush/ui/board/stroop_word_painter.dart` — `final class StroopWordScene`
  (immutable, value equality, fields: `word`, `fill`, `ink`, `playFill`, `style`, `textDirection`) and
  `StroopWordPainter extends CustomPainter` whose `shouldRepaint` is `old.scene != scene`. Three
  `TextPainter`s built in the constructor, each taking `scene.textDirection` — **never a hardcoded
  `TextDirection.ltr`**, because this painter draws *text*, not a coordinate grid. `paint()` allocates
  nothing.
- `lib/games/stroop_rush/ui/board/stimulus_glyph.dart` — the View: reads
  `Directionality.of(context)`, measures with `MediaQuery.textScalerOf`, picks `type.stimulus` or
  `type.stimulusCompact` by measured fit (unconstrained `TextPainter.layout()`, per
  `references/text-and-shapes.md` — a constrained layout reports the constraint and the fitter
  silently disappears), wraps the `CustomPaint` in `RepaintBoundary` and `ExcludeSemantics`.
- `lib/games/stroop_rush/ui/board/stimulus_card.dart` — the `PopSurface` slab: `surfaceRaised`,
  `radiusXl`, `PopElevation.e3`, the 14% ink dot layer, the 12px `textSecondary` prompt read from
  `stroop_prompt`, and the sibling `Semantics(label: prompt, value: l10n.stroopStimulusValue(word,
  inkLabel))`. Announcing the ink is the only way the board is operable with a screen reader; that it
  makes the task trivial is a recorded product decision, restated in a comment at the node. The card
  cross-fades between rounds with `AnimatedSwitcher` at `durState`/`easeOut` — no slide, no scale, no
  stagger, because a directional slide would also have to mirror and an entrance adds to reaction time.
  All padding is `EdgeInsetsDirectional`; the prompt is `TextAlign.start`.

**Files.** `lib/theme/sunburst_shape.dart`, `lib/theme/sunburst_type.dart`,
`lib/games/stroop_rush/ui/board/play_fill.dart`,
`lib/games/stroop_rush/ui/board/stroop_word_painter.dart`,
`lib/games/stroop_rush/ui/board/stimulus_glyph.dart`,
`lib/games/stroop_rush/ui/board/stimulus_card.dart`, plus the four test files above,
`test/theme/sunburst_shape_test.dart` and **`test/theme/sunburst_type_test.dart`** — whose named
step-name list literal gains `stimulusCompact` in this task's commit 2, taking the scale to twenty
(T09.5 already added `buttonCompact`). E03 T03.8's count test derives the count from the source file,
so the literal is the only edit and it is a reviewed one-liner.

**Skills.** `custom-canvas-and-gestures`, `sunburst-tokens`, `sunburst-game-surfaces`,
`widget-golden-and-a11y-testing`, `accessibility-as-code`, `sunburst-motion-and-haptics`,
`i18n-rtl-l10n`.

**Screenshot check.** `design/sunburst-pop/screens/04-stroop-rush.png`, the stimulus card region
only. Compare in order: **structure** (prompt line, then the word, card ends flush with the 20pt
gutter) → **spacing rhythm** (52 top / 18 between prompt and word / 58 bottom padding from
`app.html .stim`) → **surface construction** (3px ink border, `radiusXl` 28, e3 (8,8) hard shadow at
zero blur, the 14% dot layer) → **type role** (Fredoka 700 at 78, prompt Fredoka 600 at 12 uppercase
with .15em tracking) → **sampled hex** (`surfaceRaised`, `border` `#2B1B4D`, `playRed` `#D81E2C`, and
the 5px/4px stripe pitch measured on the glyph). The RTL counterpart is T09.8's, once the Arabic-script
pass is settled.

**Done when.**
- [ ] `.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib` reports no
      hard violations, and every `WARN` line is either resolved or answered in the PR body.
- [ ] `.claude/skills/sunburst-tokens/scripts/check_raw_values.sh lib` green — no raw geometry left
      in the painter.
- [ ] `.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh lib/theme/sunburst_colors.dart` green.
- [ ] `grep -rn 'TextDirection.ltr' lib/games/stroop_rush/` returns nothing.
- [ ] The greyscale golden is committed and a human has answered the acceptance question in the PR.
- [ ] No `FittedBox`, `TextOverflow.ellipsis`, `withClampedTextScaling` or `textScaleFactor` anywhere
      in the epic's diff.

**Commits.**
1. `test(theme): pattern geometry and stimulusCompact slots round-trip lerp` (red)
2. `feat(theme): pattern geometry slots and the compact stimulus type step`
3. `test(stroop): word painter scene equality, direction and draw order` (red)
4. `feat(stroop): three-pass stimulus glyph with the PlayFill pattern pass`
5. `feat(stroop): stimulus card, prompt and screen-reader value`
6. `test(stroop): greyscale and text-scale coverage for the stimulus`

---

### T09.8 — The three-pass glyph on joined Arabic script
**Goal.** Prove the stimulus is legible and pattern-separable in `fa` and `ckb`, where letters **join**,
and fix the passes that are not — with measured values, not guesses.

**Why it is its own task, and why it is the riskiest one.** The three passes were designed against
Latin capitals: isolated, thick, generously counter-spaced letterforms. Arabic script is cursive. Three
specific things can break, and none of them is visible in an English screenshot:

1. **Pass 1 closes the counters.** A 6px ink stroke (`glyphStrokeWidth`) grown outward from every
   contour will bleed across the thin joining strokes and fill in the small counters of ه, ع, ص, ط —
   and it will merge the dots (nuqta) of ب/ت/ث/ن and the Sorani marks on ڕ ڵ ۆ ێ ھ into their base
   letters. A ڕ whose mark has fused into the letter body is a different letter.
2. **Pass 3 destroys the shape.** A 9px stripe at 45° across a connected run has far more edges per
   letter than across a Latin capital, and the pattern can read as texture on a blob instead of as a
   fill on a shape.
3. **The mask itself.** Pass 3 is "the pattern clipped to the glyph". If it is implemented by taking a
   `Path` from the text it will not work at all — Flutter exposes no glyph outline from `TextPainter`.
   The correct implementation is `Canvas.saveLayer` + draw the filled text + draw the pattern with
   `BlendMode.srcIn`, which is script-independent by construction. This task pins that choice with a
   test so nobody "optimizes" it into a path.

**Tests first (TDD).**
- `test/games/stroop_rush/ui/stroop_word_painter_rtl_test.dart`:
  `the pattern pass is composited with saveLayer + srcIn, not a path clip` — the recording `Canvas`
  fake asserts the call sequence `saveLayer → drawParagraph → drawRect(BlendMode.srcIn) → restore`,
  and that `clipPath` is never called. This is the structural guarantee that joined script cannot
  break the mask.
  `the word painter lays out RTL under a Persian scene` — `scene.textDirection == TextDirection.rtl`
  reaches all three `TextPainter`s; the measured width of `قرمز` is non-zero and differs from its LTR
  layout only by direction, not by advance.
  `the three passes share one layout` — the same `TextPainter` metrics feed all three, so the stroke,
  the fill and the mask cannot drift by a subpixel and produce a halo.
- `test/games/stroop_rush/ui/stimulus_glyph_arabic_golden_test.dart` (`@Tags(['golden'])`,
  `setUpAll(loadAppFonts)` with the Arabic-script faces): the real-font lane —
  `widget-golden-and-a11y-testing` rule 11 says this is the *only* lane that proves shaping. One
  golden per answer × palette in `fa` and in `ckb`, plus one greyscale sheet per locale. Two
  acceptance questions recorded in the doc comment and answered by a human in the PR:
  *are the counters still open and the dots still separate?* and *can each glyph be told from the
  others in greyscale?*
  The `ckb` sheet must include a word carrying each Sorani-specific letter — سەوز (ە), مۆر (ۆ),
  پەمەیی (ە + ی), پرتەقاڵی (ڵ) — plus a fixture word carrying ڕ and ێ so all five are covered.
- `test/games/stroop_rush/ui/stroop_glyph_stroke_test.dart`:
  `the glyph stroke width is script-aware` — asserts `shape.glyphStrokeWidthFor(script)` is 6 for
  Latin and the measured Arabic value for `fa`/`ckb`, and that the value came from a token, not a
  literal.
- `test/games/stroop_rush/ui/stimulus_text_scale_test.dart` (extended): the (device, scale) matrix
  from T09.7 re-run for `fa` and `ckb`. Arabic-script line boxes are taller and the ascender/descender
  metrics differ, so a card height that fits `en` at scale 2.0 is not evidence for `fa`.

**Implementation.**
- **Measure first, then write the token.** Render the seven `ckb` words and the seven `fa` words at
  `stimulus` size with `glyphStrokeWidth` 6, 5, 4, 3.5 and 3, capture the goldens, and pick the
  largest value at which every counter is open and every mark is separate. Record the measured value
  and the rejected ones in a comment at the token declaration and in the PR body. **Do not guess a
  number here and call it derived** — the whole point of the task is that it is measured.
- `lib/theme/sunburst_shape.dart` (changed) — `glyphStrokeWidthArabic` (**MEASURED**, from the step
  above) beside `glyphStrokeWidth`, and `double glyphStrokeWidthFor(ScriptFamily)` resolving between
  them. Four places plus the const instance.
- `lib/games/stroop_rush/ui/board/stroop_word_painter.dart` (changed) — pass 3 is `saveLayer` +
  `BlendMode.srcIn`, with a comment naming the reason (no glyph outline is available and a path clip
  would fail on joined script). Pass 1's stroke width comes from `glyphStrokeWidthFor`.
- `lib/games/stroop_rush/ui/board/stimulus_glyph.dart` (changed) — resolves the script family from
  `Localizations.localeOf(context)` through E04's helper (`fa`/`ckb` → Arabic, else Latin) and puts it
  in the scene. If E04 exposes no such helper, add it **there**, not here — it is not a game concern.
- If, after measuring, no stroke width keeps `ckb` legible at the `stimulus` size, the fallback is a
  **larger base size** for Arabic script (more absolute space between contours at the same relative
  stroke), never a thinner-and-illegible stroke and never a `FittedBox`. Record which lever was used.

**Files.** `lib/theme/sunburst_shape.dart`,
`lib/games/stroop_rush/ui/board/stroop_word_painter.dart`,
`lib/games/stroop_rush/ui/board/stimulus_glyph.dart`,
`test/games/stroop_rush/ui/stroop_word_painter_rtl_test.dart`,
`test/games/stroop_rush/ui/stimulus_glyph_arabic_golden_test.dart`,
`test/games/stroop_rush/ui/stroop_glyph_stroke_test.dart`,
`test/games/stroop_rush/ui/stimulus_text_scale_test.dart` (extended),
`test/theme/sunburst_shape_test.dart` (extended).

**Skills.** `custom-canvas-and-gestures`, `i18n-rtl-l10n`, `widget-golden-and-a11y-testing`,
`sunburst-tokens`, `sunburst-game-surfaces`, `accessibility-as-code`.

**Screenshot check.** `design/sunburst-pop/screens/rtl/04-stroop-rush.png`, the stimulus card region.
Compare in the same order — **structure** (prompt, then the word; card flush with the 20pt gutter,
which is now the *start* gutter on the right) → **spacing rhythm** (the same 52/18/58, mirrored only
where it is horizontal) → **surface construction** (3px ink border, `radiusXl` 28, e3 (8,8) hard shadow
**still down-and-right**, the 14% dot layer) → **type role** (the Arabic display face at the resolved
size; **no tracking**) → **sampled hex** (unchanged from LTR — hue does not localize).
If the RTL reference and the built screen disagree because the reference itself is wrong for Arabic
script, fix `app.html`'s RTL variant, re-run `capture-screens.sh`, and commit the regenerated PNG as a
deliberate design change in this PR.

**Done when.**
- [ ] `glyphStrokeWidthArabic` is a **measured** value with the rejected candidates recorded.
- [ ] The `fa` and `ckb` real-font goldens are committed and both acceptance questions are answered by
      a human in the PR body, with the greyscale sheets attached.
- [ ] All five Sorani letters ڕ ڵ ۆ ێ ھ appear in a committed golden and none has fused with its base.
- [ ] `clipPath(` appears nowhere in `lib/games/stroop_rush/ui/board/`.
- [ ] The extended text-scale matrix is green for `fa` and `ckb` up to the scale T09.10 records as the
      verified ceiling.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` green.

**Commits.**
1. `test(stroop): pin the pattern mask to saveLayer + srcIn and RTL layout` (red)
2. `chore(stroop): measure the glyph stroke against Persian and Sorani words`
3. `feat(theme): script-aware glyph stroke width`
4. `feat(stroop): render the three-pass stimulus in fa and ckb`
5. `test(stroop): Arabic-script real-font and greyscale goldens`

---

### T09.9 — Answer keys, board assembly, motion and haptics
**Goal.** Four pressable answer keys and the board that holds them, with every state separated by at
least three non-hue channels, no chrome slot anywhere inside the rectangle, and a geometry that mirrors
by construction while the hard shadow does not.

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
  **`the pattern panel sits at the start edge in both directions`** — under `en`, `getRect(panel).left
  == getRect(key).left + inset`; under `fa`, `getRect(panel).right == getRect(key).right - inset`.
  One `Row` with `EdgeInsetsDirectional`, no conditional.
  **`the hard offset shadow does not mirror`** — under `fa` and `ckb`, the resolved `BoxShadow.offset`
  is still `Offset(5, 5)` for e2. The shadow is a light-source constant, not a reading-direction
  property; a mirrored shadow would make every surface look lit from the other side in RTL while the
  LTR half of the app looks lit from this one. This is the assertion a reviewer will ask for.
  **`the ink strike bar spans the key in both directions`** — full width, `PositionedDirectional`
  with `start: 0, end: 0`, so it never becomes a half-bar under RTL.
- `test/games/stroop_rush/ui/stroop_board_test.dart`:
  `tapping a key calls submit with that option index and nothing else` — the intent is the board's
  only upward call, and the index is the **model** index, not a visual position: under `fa` the key
  that is visually top-right is still option 0.
  `the board draws no HudPill, Scaffold, AppBar, SafeArea or progress bar`.
  `every key's fill box is at least kPopMinTarget on both axes` — an explicit `getSize` loop, at
  320 / 360 / 390 / 430 px, in all four locales.
  `the 2×2 grid sets clipBehavior: Clip.none` — otherwise the e2 shadow is sheared off.
  `keys in a row share a top and keys in a column share a left` — `moreOrLessEquals(epsilon: 0.5)`.
  **`the grid mirrors under an RTL locale`** — under `en`, option 0's rect has the smallest `left`;
  under `fa`, option 0's rect has the largest `left` and its `right` is flush with the board's end
  edge. `GridView` under `Directionality.rtl` does this for free — the test exists to catch the day
  someone "fixes" the order with an index flip and double-mirrors it.
- `test/games/stroop_rush/ui/shake_wiring_test.dart`: `a wrong key is wrapped in E06's ShakeOnWrong and
  keyed on the wrong-tap id` — the widget itself is E06's and its two-cycle/dispose/reduce-motion
  behaviour is already asserted in `test/shared/motion/shake_on_wrong_test.dart`. What this epic tests
  is the **wiring**: the shake re-plays on a second wrong tap on the same key (the id changed), and
  under `disableAnimations` it is skipped while the sunk state and the ink strike bar still apply —
  driven with `pump(Duration)`, never `pumpAndSettle`. A horizontal shake is symmetric about its
  origin, so it is direction-agnostic and needs no mirroring; assert that too, once, so nobody adds a
  `Directionality` branch to it. Re-asserting E06's cycle count here would be a second copy of a test
  for a widget this epic does not own.
- `test/games/stroop_rush/ui/stroop_board_a11y_test.dart`: each key exposes
  `isSemantics(isButton: true, label: <localized answer label>, hasTapAction: true)` in all four
  locales, and traversal order is authored with `OrdinalSortKey` on the model index — not inherited
  from layout, so it does not silently reverse when the grid mirrors.

**Implementation.**
- `lib/theme/sunburst_shape.dart` (changed) — the key geometry slots, **DERIVED** from `app.html`
  `.ans`/`.ans .key`: `answerKeyHeight` 92, `answerKeyPanelWidth` 56, `answerStrikeHeight` 6. Same
  four-places-plus-const-instance procedure.
- `lib/games/stroop_rush/ui/board/play_fill_painter.dart` — the 56pt panel painter, `shouldRepaint`
  as one value compare, delegating to `paintPlayFill` from T09.7.
- `lib/games/stroop_rush/ui/board/answer_key.dart` — `StroopAnswerKey`: `PopSurface` at
  `radiusLg`, fill `colors.answerColour(answer, colourBlind: …)`, an exhaustive switch from
  `AnswerKeyState` to `(PopElevation, Offset, bool isStruck)` with no `default:`, the ink-bordered
  pattern panel at the start edge, the ink strike bar as a `PositionedDirectional(start: 0, end: 0)`,
  and `Text(label, style: labelStyle.copyWith(color: colors.answerLabel(answer)), textAlign:
  TextAlign.start)` where `labelStyle` is T09.5's measured choice between `type.button` and
  `type.buttonCompact`. Never `success`, never `danger`, never `enabled: false`, never
  `EdgeInsets.only(left:)`.
- **No `shake_on_wrong.dart` under `lib/games/`.** `ShakeOnWrong` is E06's, at
  `lib/shared/motion/shake_on_wrong.dart` — two explicit `forward(from: 0)` calls, controller disposed,
  duration from `motion.resolve(context, motion.durCelebrate)` — and E10's tile wraps the same widget.
  `StroopAnswerKey` imports it and passes `key: ValueKey(state.wrongTapId)`; a per-game copy is exactly
  the divergence `sunburst-motion-and-haptics` rule 2 exists to prevent, and E06 T06.9's policy test
  fails on a second declaration.
- `lib/games/stroop_rush/ui/stroop_board.dart` — the entry widget named by `GameDefinition.buildBoard`
  (`*_board.dart`, so the palette gate allows its slot reads): a `ConsumerWidget` reading one
  `.select` slice, a `ColoredBox(colors.surfaceSunk)` field with the 14% ink dot layer, the stimulus
  card, a 16pt gap, and a 2×2 `GridView.builder` at `crossAxisSpacing`/`mainAxisSpacing`
  `SunburstShape.space3` with `mainAxisExtent: shape.answerKeyHeight` and `clipBehavior: Clip.none`.
  All padding is `EdgeInsetsDirectional`. No `SafeArea`, no gutter of its own beyond `app.html`'s
  0/20/26 board padding, and **no `Directionality` of its own** — direction comes from the locale
  (`i18n-rtl-l10n` rule 4).

**Files.** `lib/theme/sunburst_shape.dart`, `lib/games/stroop_rush/ui/stroop_board.dart`,
`lib/games/stroop_rush/ui/board/answer_key.dart`,
`lib/games/stroop_rush/ui/board/play_fill_painter.dart`, plus the four test files above.

**Skills.** `sunburst-game-surfaces`, `sunburst-components`, `sunburst-motion-and-haptics`,
`widget-composition`, `accessibility-as-code`, `widget-golden-and-a11y-testing`, `i18n-rtl-l10n`.

**Screenshot check.** Both references, the answer grid region:
`design/sunburst-pop/screens/04-stroop-rush.png` — **structure** (2×2, key order Red / Blue / Green /
Yellow reading start-to-end) → **spacing rhythm** (12pt gap both axes, 92pt key height, card-to-grid
gap 16) → **surface construction** (3px ink border, e2 (5,5) hard shadow, `radiusLg` 22, the 56pt panel
closed by a 3px ink divider, patterns at their pitches: stripe 5/4 at 45°, dots r2.6 on a 10pt lattice,
rings 3pt bands on a 7pt period) → **type role** (Fredoka 700 at 22 for labels) → **sampled hex**
(`playRed`/`playBlue`/`playGreen`/`playYellow`, paper labels except ink on yellow).
`design/sunburst-pop/screens/rtl/04-stroop-rush.png` — the same list, with three deliberate deltas to
verify: the key order runs right-to-left starting top-right, the 56pt pattern panel is on the right of
each key, and **the shadow is unchanged**. Anything else that differs is a defect.

**Done when.**
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` green.
- [ ] `.claude/skills/sunburst-components/scripts/check_component_hygiene.sh lib` green.
- [ ] `.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib` green.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` green — zero physical-side
      geometry anywhere in the board.
- [ ] `AnimationController.repeat(` appears nowhere in the diff, and `grep -rn 'class ShakeOnWrong' lib/`
      returns exactly one line, in `lib/shared/motion/`.
- [ ] Every key's fill box ≥ 48pt at 320px in all four locales, verified by the `getSize` loop.

**Commits.**
1. `feat(theme): answer key geometry slots`
2. `test(stroop): answer key state channels and the enabled-false ban` (red)
3. `feat(stroop): Stroop answer key with its pattern panel and strike bar`
4. `test(stroop): the key mirrors, the shadow does not` (red)
5. `test(stroop): the wrong key wires E06's ShakeOnWrong and re-plays per wrong tap` (red)
6. `feat(stroop): wire ShakeOnWrong into the answer key with the ink strike residue`
7. `test(stroop): board layout, tap targets and intent wiring across four locales` (red)
8. `feat(stroop): StroopBoard field, stimulus and 2x2 answer grid`

---

### T09.10 — The tier proof, the greyscale proof, and the locale × scale × width matrix
**Goal.** Prove mechanically what no screenshot can show: no gameplay colour is chrome anywhere on
the play screen, no chrome semantic slot is inside the board, every answer is separable by pattern
alone, and nothing overflows in any locale at any scale on any width.

**Tests first (TDD).** These *are* the deliverable; the "implementation" is whatever fixes them.
- `test/policy/stroop_tier_policy_test.dart` — a source-level policy test (the class
  `ci-pipeline-and-gates` rule 7 sanctions): every file under `lib/games/stroop_rush/` that names
  `answerColour`/`answerLabel`/`play*`/`cb*` is either `*_board.dart` or under a `board/` directory;
  no file under `lib/games/` names `Color(0x`, `Colors.`, `go_router`, `Navigator.`, `Scaffold(`,
  `AppBar(`, `HudPill`, `Stopwatch(`, `Timer.periodic(` or `runNotifierProvider`; no file under
  `lib/features/` imports `games/stroop_rush/`. **Plus the localization rows**: no file under
  `lib/games/stroop_rush/domain/` imports `package:intl` or `lib/l10n/`; no file under
  `lib/games/stroop_rush/` constructs `NumberFormat(`, calls `toUpperCase(`, writes a hardcoded
  `TextDirection.`, or names `Directionality(`. It duplicates the shell and i18n scripts on purpose,
  so a `flutter test` run alone catches the regression.
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
  Run the whole file under `en` and under `fa` — the tier boundary is not a direction property, but
  the *walk* is, and an RTL run is what catches a fill that only appears in the mirrored tree.
- `test/games/stroop_rush/ui/stroop_greyscale_golden_test.dart` (`@Tags(['golden'])`) — one greyscale
  golden of the stimulus card plus the four keys, under both palettes, in `en` **and** `fa`. Acceptance
  question recorded in the doc comment: *from this image alone, can each key be matched to the word?*
  If the answer is "only by reading the labels", the pattern pass is broken — and in `fa` that answer
  is also unavailable to anyone who cannot read Persian, which is the point of the pattern.
- `test/games/stroop_rush/ui/stroop_overflow_matrix_test.dart` — the D8 matrix, one `testWidgets` per
  tuple, `setUpAll(loadAppFonts)`:
  - the scale lane: `Device.all` (320 / 360 / 412) × `[1.0, 1.3, 1.5, 2.0, 3.0]` × `LocaleCase.all`
    (`en`, `de`, `fa`, `ckb`) = **60 cases**;
  - the bold lane: `Device.all` × `LocaleCase.all` at scale 2.0 with `boldText: true` = **12 cases**.
    Bold is a weight change whose worst case is the largest scale, so it is not crossed with the whole
    scale axis; that trade is stated in the file's header comment rather than left implicit.

  Every case asserts `takeException(), isNull` **and** a fit assertion on the label box of every key
  **and** on the stimulus glyph's box. German is the length stress case; `fa` and `ckb` are the
  line-box-height stress case — Arabic-script ascenders and descenders are taller, so a card that fits
  `de` at 2.0 is not evidence for `ckb` at 2.0.

**Implementation.** A test-only slot probe in `test/support/slot_probe.dart` that maps a rendered
`Color` back to the `SunburstColors` field(s) that carry it, returning **all** matches so the
`danger`/`playRed` collision is reported rather than silently resolved. Any defect the four tests
surface is fixed in T09.5/T09.7/T09.8/T09.9's files, not worked around in the test. Where the matrix
finds a genuine ceiling — a scale above which `ckb` cannot fit without a design change — record the
number in the epic's risks and hand it to E11's `design-review-workflow` sweep as a BLOCKER. Do not
clamp.

**Files.** `test/policy/stroop_tier_policy_test.dart`,
`test/games/stroop_rush/ui/stroop_tier_test.dart`,
`test/games/stroop_rush/ui/stroop_greyscale_golden_test.dart`,
`test/games/stroop_rush/ui/stroop_overflow_matrix_test.dart`, `test/support/slot_probe.dart`.

**Skills.** `sunburst-game-surfaces`, `widget-golden-and-a11y-testing`, `testing-strategy`,
`accessibility-as-code`, `ci-pipeline-and-gates`, `i18n-rtl-l10n`.

**Screenshot check.** `design/sunburst-pop/screens/04-stroop-rush.png` (`en`, scale 1.0) and
`design/sunburst-pop/screens/rtl/04-stroop-rush.png` (`fa`, scale 1.0) as the two controls; the
`de`/`ckb` renders and every scale above 1.0 have no reference and are judged against the rules, not
the PNGs — a layout that only works at `en` × 1.0 is a defect even though the references cannot show it.

**Done when.**
- [ ] All four test files green, and each was seen red first by temporarily introducing the defect it
      guards (a `danger` fill on a wrong key, a `playRed` HUD pill, an `EdgeInsets.only(left:)` on the
      key, a `NumberFormat.decimalPattern()` with no locale) and reverting.
- [ ] The 72-case matrix runs in CI and the run time is recorded in the PR body; if it is the slowest
      file in the suite, say so rather than trimming the locale axis.
- [ ] `.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh lib` green.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh` green, and no
      `takeException()` swallow, `ignoreOverflowErrors` or `FlutterError.onError` assignment exists.
- [ ] `--update-goldens` appears in no committed script or workflow.

**Commits.**
1. `test(policy): pin the Stroop tier and localization boundaries at source level`
2. `test(stroop): no gameplay colour as chrome, no chrome slot in the board, LTR and RTL`
3. `test(stroop): greyscale golden proves pattern-only separability in en and fa`
4. `test(stroop): overflow and fit matrix across locales, scales, widths and bold`

---

### T09.11 — `GameDefinition`, the registry, artwork, and the full-screen comparison
**Goal.** Plug Stroop Rush into the engine with one appended registry line and zero edits under
`lib/features/**`, then sign the screen off against both references on the canonical simulator.

**Tests first (TDD).**
- `test/games/game_registry_test.dart` (extended): `the registry exposes stroop_rush` with
  `accent == GameAccent.stroopCoral`, `scoreFormat == ScoreFormat.points`,
  `boardBackground == BoardBackground.surfaceSunk`, `difficulties == Difficulty.values`,
  `isLocked == false`.
- `test/games/stroop_rush/stroop_rush_definition_test.dart`:
  `a mechanic game declares BoardBackground.surfaceSunk` — the one pairing no `switch` can catch, per
  `accent-contract.md`; asserted for every registry entry, so E10 inherits it.
  `buildBoard returns a StroopBoard for a RunConfig` and `snapshotOf yields a BoardSnapshot`.
  `the definition holds no English literal` — title, tagline and kicker resolve from ARB by id, in all
  four locales; the test asserts the `de`, `fa` and `ckb` renderings differ from the `en` one, which is
  what fails when a literal sneaks back in.
  `the game id is bidi-isolated wherever it is displayed` — `stroop_rush` is a strong-LTR technical
  token; if any surface shows it (a debug row, a share string), it goes through `Bidi.isolateLtr`, and no
  isolate character reaches the `GameId` value or the database.
- `test/l10n/arb_parity_test.dart` (extended): the **22 keys** this epic adds exist in all four
  locales with identical placeholder names.
- `test/features/home/home_screen_test.dart` (extended, shell-owned file): the Stroop card renders
  from registry data, in `en` and in `fa` — proof the shell was not edited to know about this game and
  that the card mirrors from the shell's own directional geometry.

**Implementation.**
- `lib/games/stroop_rush/stroop_rush_definition.dart` — `final stroopRushDefinition =
  GameDefinition(id: const GameId('stroop_rush'), accent: GameAccent.stroopCoral, scoreFormat:
  ScoreFormat.points, difficulties: Difficulty.values, boardBackground:
  BoardBackground.surfaceSunk, isTimed: true, runLimitFor: null, buildBoard: …, buildArtwork: …,
  snapshotOf: …)` — `isTimed` because screen 04 renders a TIME pill; `runLimitFor: null` because the
  board ends the run on round count, not the shell on a clock (Risk 5).
- `lib/games/game_registry.dart` (changed) — one appended entry.
- `lib/games/stroop_rush/ui/stroop_artwork.dart` — the 64pt Home-card tile: four 5pt-radius quads
  with a 2pt (`borderWidthNested`) ink edge, in the four default answer hues, per `app.html`
  `.gart .quad i`. It is decorative and `ExcludeSemantics`, and its quad layout is a fixed 2×2
  ornament with no reading order — it does **not** mirror. **See Risk 1** — this file reads the
  gameplay palette outside a board and needs the gate decision resolved before it is committed.
- ARB keys `game_stroop_rush_title`, `game_stroop_rush_tagline`, `game_stroop_rush_kicker` in all four
  locales (authored in T09.5, wired here).

**Files.** `lib/games/stroop_rush/stroop_rush_definition.dart`, `lib/games/game_registry.dart`,
`lib/games/stroop_rush/ui/stroop_artwork.dart`, plus the four test files above.

**Skills.** `sunburst-shell-screens`, `sunburst-game-surfaces`, `i18n-rtl-l10n`,
`flutter-architecture`, `scaffold-feature-module`.

**Screenshot check.** The full-screen sign-off, and the last gate before the PR. Both captures come
off the canonical simulator — boot `xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4`, run
`flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`, and capture with `xcrun simctl io … screenshot`.
No other simulator is 390×844, so no other simulator produces an honest comparison.

1. `design/sunburst-pop/screens/04-stroop-rush.png` at 390×844, locale `en` — **chrome and board
   interior together**. Order: **structure** (top bar → coral play band with rays, dots, three pills,
   track → 3px ink border → `surfaceSunk` field with the dot layer → stimulus card → 16pt gap → 2×2
   keys, optically centred in the remaining space) → **spacing rhythm** (20pt gutter, 20pt field top
   padding, 26pt field bottom padding) → **surface construction** (every raised surface: 3px ink
   border, correct hard-shadow step, zero blur, zero spread) → **type role** → **sampled hex**
   (`gameStroop` `#FF6B5A`, `gameStroopDeep` `#E8452F` rays, `surfaceSunk` `#FFEEDA` field,
   `surfaceRaised` card, the four `play*` keys).
2. `design/sunburst-pop/screens/rtl/04-stroop-rush.png` at 390×844, locale `fa` — the same list, with
   the mirrored deltas enumerated in T09.9's check, plus: the HUD pill order mirrors, the score reads
   `۱٬۲۴۰` and the streak `×۷`, the progress track fills from the **end** edge, and every hard shadow
   still falls down-and-right.
3. `design/sunburst-pop/screens/01-home.png` and `screens/rtl/01-home.png` for the Stroop card and its
   quad artwork.

A difference is an implementation defect; if a reference is genuinely wrong, edit `app.html` (or its
RTL variant), re-run `design/sunburst-pop/capture-screens.sh`, and commit the regenerated PNGs as a
deliberate design change in the same PR.

**Done when.**
- [ ] `git diff --stat main -- lib/features/` is empty.
- [ ] Four screenshots of the built app at 390×844 are attached to the PR beside their references:
      04 in `en` and `fa`, 01 in `en` and `fa`.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` and `flutter analyze --fatal-infos` is clean;
      `check_arb_parity.sh lib/l10n` green over four locales.
- [ ] `ios/Runner/Info.plist` still lists `CFBundleLocalizations` = `en, de, fa, ckb` and
      `CFBundleDevelopmentRegion` = `en` (E01/E04's work — this epic verifies it, and fails the PR if
      a locale went missing).
- [ ] A full run is played end to end on `MindForge iPhone 14` in `en` and again in `ckb`, and both
      run rows land in the database with integer scores.

**Commits.**
1. `test(stroop): definition, registry entry and colour-role parity` (red)
2. `feat(stroop): GameDefinition and Home card artwork`
3. `feat(stroop): register Stroop Rush in the game registry`
4. `fix(stroop): reference-screen differences from the 04 LTR and RTL comparisons` (only if the
   comparisons find any)

## Gates that must pass

Run from the repo root, in this order, before the PR and again after `/simplify` and `/code-review`:

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 built
bash tool/skill_gates.sh

# this epic's named spot-checks, run individually so a failure names itself
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart

.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                   lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                  lib/l10n

.claude/skills/seeded-determinism-and-golden-vectors/scripts/check-determinism-bans.sh lib/games/stroop_rush/domain
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib
.claude/skills/flutter-architecture/scripts/check_architecture.sh
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh
.claude/skills/widget-composition/scripts/check-widget-composition.sh
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh

# iOS build, on the only device that matches the references
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4 || true
flutter build ios --simulator
```

`check_game_palette.sh` is the named gate for this epic and must print
`OK: no Color declarations, stray theme imports, or tier crossings under lib/games`.

`check_arb_parity.sh` is the **second** named gate, and it is new to this epic's world: with four
locales it actually runs. E04 moved it out of `tool/skill_gates.sh`'s skip table (where it sat with a
measured "needs a sibling `app_*.arb`; verified exit 2" reason) into the run table. This epic keeps it
green — every key it adds lands in all four ARBs in the same commit as the template.

`bash tool/skill_gates.sh` is the authoritative sweep, locally and in CI — never a
`for s in .claude/skills/*/scripts/*.sh` loop, which cannot exit 0 (29 of 49 fail argument-less, five
can never pass that way). Add a `verify_feature.sh lib/games/stroop_rush` row alongside E08's
per-feature rows in the runner's run table.

Android runs no gate here and is not built. Adding it later means re-running this whole list on an
Android target and re-doing the font, numeral and RTL verification — it is not implied by an iOS pass.

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

2. **The Sorani display face is unresolved until E04 measures it, and this epic inherits the answer.**
   D4 names Vazirmatn for body and Lalezar as the closest OFL chunky display candidate for `fa`/`ckb`,
   but Lalezar's coverage of ڕ ڵ ۆ ێ ھ is **not assumed** — E04 verifies it and falls back to
   Vazirmatn Bold for display if it fails. This epic's stimulus is the single largest, most
   identity-carrying piece of type in the app, so whichever face E04 lands on is the one the Stroop
   word is set in. If E04's verdict is "Lalezar fails on Sorani", the honest consequence is that
   `fa` gets Lalezar and `ckb` gets Vazirmatn Bold and **the two RTL locales do not look identical** —
   record that in the PR rather than papering over it by demoting both.

3. **The Persian and Sorani strings are machine-quality and must not ship unreviewed.** A Stroop game
   is *entirely* colour vocabulary: if سەوز is the wrong register, or if a Sorani speaker reads
   پەمەیی as a shade rather than as "pink", the game is subtly wrong in a way no test can see. The
   drafts in T09.5 are committed so the layout can be built against real lengths, each tagged
   `native-speaker-pending` in its ARB metadata. **A native review of `fa` and `ckb` is a release
   blocker owned by E11**, not by this epic — but the marker must survive until it is done, and the
   PR body must say "the fa/ckb colour words are unreviewed" in plain words.

4. **The Fredoka personality does not survive translation, and that is not a bug to fix here.**
   Fredoka and Nunito have no Arabic-script coverage. In `fa` and `ckb` the brand is carried entirely
   by the **shape language** — the 3px ink border, the hard offset shadow at zero blur, the press-down,
   the saturated palette on cream — and not by the typeface. Do not attempt to "match" Fredoka with a
   Latin-styled Arabic face; that produces a face that is wrong in both directions. Say so in the PR.

5. **Who fills the progress track, and who ends the run.** This epic decides Stroop Rush is a **fixed
   round count**, not a fixed duration: the board owns `progress` (answered / roundCount) and ends the
   run via `BoardSnapshot.outcome`, the only end signal the contract gives a game. Screen 04's 57% track
   with 17 of 30 answered is consistent with that reading. **The seam already supports both**, because
   E07 T07.3/T07.5 moved run length off the `Difficulty` enum and onto
   `GameDefinition.runLimitFor(Difficulty)`, nullable: `stroopRushDefinition` declares
   `isTimed: true` (screen 04 renders a TIME pill at 0:23, so the shell shows its clock) with
   `runLimitFor` returning `null` (the shell does not cut the run off). Confirm the reading with Zakaria
   before T09.1; if Stroop should instead be a 60-second run, that is one `runLimitFor` closure here,
   not an E07/E08 change.

6. **Blitz's six answers versus four ink patterns.** `gameplay-palette-and-cvd.md` records the
   collision: `purple` and `blue` are both `solid`, `red` and `orange` both `stripe`. This epic
   resolves it without new tokens by drawing four options from the six-colour pool under the
   constraint that the four `PlayFill`s are distinct. The cost: `{blue, purple}` and `{red, orange}`
   are mutually exclusive within one round, so blitz never offers all six at once. If the design
   later wants six keys, that is two new ink patterns authored in `sunburst-tokens` **and** a board
   layout `app.html` does not have — a design change, not a code change.

7. **`stimulusCompact` and `buttonCompact` are derived, and the Arabic ceiling is unmeasured until
   T09.10 runs.** A six-letter word at 78pt and text scale 2.0 needs roughly 580pt against ~320pt
   available; `sunburst-tokens` owes a measured `stimulusCompact` and this epic adds ~54 as a
   derivation. Arabic-script line boxes are taller again, so the `ckb` ceiling will be lower than the
   `en` one and nobody knows by how much yet. Whatever T09.10's matrix reports is written into the PR
   as the verified scale ceiling per locale, and anything short of 3.0 is logged as a BLOCKER for
   E11's `design-review-workflow` sweep — never papered over with a clamp.

8. **The `ckb` Material/Cupertino delegate gap is E04's fix and this epic's dependency.**
   `GlobalMaterialLocalizations` almost certainly does not ship `ckb`, and a missing delegate throws
   at runtime on locale switch. E04 owns the custom `LocalizationsDelegate` that serves our ARB for
   `ckb` while delegating Material/Cupertino to `fa` (else `ar`), and owns verifying the actual
   delegate list at build time rather than assuming it. If that delegate is not in place, every `ckb`
   test in this epic throws on `pumpApp` and the failure will *look* like a Stroop bug. Verify it
   before T09.5, and if it is missing, stop and finish E04.

9. **`intl` has no `ckb` number symbols, so nothing here may resolve a formatter implicitly.**
   `LocaleNumbers` maps `ckb` → the `fa` symbol set (same Extended Arabic-Indic block, same
   separators). If a value is ever formatted by a `format: decimalPattern` ARB placeholder instead,
   gen-l10n resolves through `intl` directly, finds nothing for `ckb`, and emits Latin digits with no
   error. That is why `hud_streak_value` takes a **`String`** placeholder. This is the localization
   defect most likely to ship silently, and T09.6's per-locale assertion is the only thing standing in
   front of it.

10. **The golden vector oracle may be a re-transcription, not a second design.** The generator is a
    short specification, so an "independent" implementation risks being the same code written twice.
    Mitigation: build the oracle by full enumeration where the production path uses rejection
    sampling, and state plainly in the table's header comment which rows are regression pins ("nothing
    changed") rather than correctness proofs ("this is right").

11. **64-bit integer arithmetic assumes a native target.** SplitMix64 and FNV-1a-64 do not behave the
    same compiled to JavaScript. **MindForge currently ships iOS only**; Android is deferred and web is
    not on the roadmap. Record that as the reason the generator is allowed 64-bit ints. If a web target
    is ever added, the generator must be re-implemented in 32-bit halves and re-versioned with a
    cutover, never edited in place. Adding Android does not affect this — both are native — but it does
    require re-running the font, numeral, RTL and screenshot verification on an Android device.

12. **Announcing the ink makes the game trivial for a screen-reader user.** The stimulus `Semantics`
    value says "BLUE, printed in red" — in `fa`, «آبی، چاپ‌شده با رنگ قرمز». There is no way to make
    the board operable non-visually without it. It is a recorded product decision, restated at the
    node, and it belongs in E11's review — not something to quietly "fix" by hiding the value.

13. **`lib/games/stroop_rush/` versus the brief's `lib/games/stroop/`.** The epic brief says
    `lib/games/stroop/`; `sunburst-shell-screens/references/shell-game-boundary.md` requires the
    directory name to match the definition and the `GameId`, which is `stroop_rush` (it is also the
    route segment and the DB key). This epic follows the skill. If Zakaria prefers the shorter folder,
    the `GameId`, the route and the ARB key prefixes move with it.

## Definition of done

- [ ] Branch `epic/09-stroop-rush` cut from `main`; every task's commits landed in order, tests
      committed with the code they cover.
- [ ] All twelve tasks' "Done when" boxes ticked, T09.0 first.
- [ ] **`lib/games/placeholder/` is gone**, along with its registry entries, its ARB keys in all four
      locales and its test; `grep -rn "placeholder" lib/ test/` returns nothing.
- [ ] `lib/games/stroop_rush/` contains the definition, `application/`, `domain/` and `ui/` and
      nothing else — no `shake_on_wrong.dart`, no PRNG, no second `LocaleNumbers`, no second bidi
      helper; `git diff --stat main -- lib/features/` is empty.
- [ ] All 22 new ARB keys exist in `app_en.arb`, `app_de.arb`, `app_fa.arb` and `app_ckb.arb` with
      identical placeholder names; `check_arb_parity.sh lib/l10n` green.
- [ ] `test/` mirrors `lib/`; the golden vector table (with its four-locale invariance test), the
      greyscale goldens, the Arabic-script real-font goldens and the tier tests are committed.
- [ ] Every DERIVED value is marked as such at its declaration with a one-line reason; the **MEASURED**
      `glyphStrokeWidthArabic` carries its rejected candidates.
- [ ] Screen 04 compared at 390×844 on `MindForge iPhone 14` in **both** `en` against
      `screens/04-stroop-rush.png` and `fa` against `screens/rtl/04-stroop-rush.png`, in the order
      structure → spacing → surface construction → type → hex; both comparison screenshots are in the
      PR body. Any reference change went through `app.html` + `capture-screens.sh` and is committed here.
- [ ] Screen 01 compared in `en` and `fa` for the Stroop card and artwork.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed (or each dismissal justified in the PR).
- [ ] Every gate in "Gates that must pass" green locally, including `flutter build ios --simulator`.
- [ ] PR opened with a body stating: what changed, why, how it was verified, which screens were
      compared in which locales, the DERIVED decisions taken (round count, base points,
      `stimulusCompact`, `buttonCompact`), the MEASURED Arabic glyph stroke and what was rejected, the
      verified text-scale ceiling per locale, the plain statement that **the `fa` and `ckb` colour
      words are machine drafts pending native review**, and what was deliberately left out (six-key
      Blitz, a timed run mode, N-Back, Android).
- [ ] CI green on the PR (the pipeline E01 created).
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, `git pull` done.
- [ ] E10 can start: the `GameDefinition` seam carried a real game, in four locales and two writing
      directions, and needed no shell edit.
