> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E08-shell-screens.md`](../E08-shell-screens.md) — **E08 · Shell screens**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E07 · Shell screens

| | |
|---|---|
| **Branch** | `epic/07-shell-screens` |
| **Depends on** | E01, E02, E03, E04, E05, E06 |
| **Unblocks** | E08, E09, E10 |
| **Status** | Not started |

## The epic

Build the whole product except the board rectangle. Eight screens under `lib/features/**` — Home,
Game detail, Countdown, Play scaffold, Pause sheet, Results, Stats, Settings — plus the nine
shell-owned composites in `lib/features/shell/widgets/` (`RayHeader`, `HalftoneDots`, `PlayBand`,
`GameHeroPanel`, `DailyMixCard`, `StatBox`, `ScoreSlab`, `BestCard`, `Wordmark`), one `GoRouter` in
`lib/routing/` whose three-branch `StatefulShellRoute.indexedStack` owns the 90pt `PopBottomNav`, and
the Settings screen wired to the real `SettingsRepository` from E05.

Every game-specific fact on these screens is data read off `gameRegistryProvider` — card, BEST pill,
locked slot, difficulty list, score formatting, accent, board background. No shell file names a game.
To make that claim testable and the screens screenshot-comparable before Stroop Rush exists, this epic
ships `lib/games/placeholder/` — two unlocked placeholder definitions and one locked slot, obeying
every rule in `references/shell-game-boundary.md` — which E08 deletes in its first commit.

## Why we need it

MindForge is an engine. The engine is exactly this: the eight screens, the run lifecycle wired to
them, and the seam a game plugs into. Without E07 there is no route to anything, no `GameHud`, no
`_BoardPane`, no results hand-off — E08 and E09 would each have to invent a screen, and the second one
would inherit a copy of the first instead of the shell. That fork is the failure mode the whole
architecture exists to prevent.

It is also the epic where the design direction either ships or quietly becomes generic Material. Eight
rendered PNGs in `design/sunburst-pop/screens/` are the acceptance criteria; nothing else in the
project has that much visual surface, and nothing else can drift as far without a compile error.

## Current state

Verified by `ls` on 2026-08-19, at 4 commits on `main`:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Everything below is
  inherited from E01–E06 at branch time, not present today.
- `.claude/skills/` — 45 skills. `sunburst-shell-screens/` carries the three references this epic is
  built from (`screen-anatomy.md`, `shell-game-boundary.md`, `run-lifecycle.md`), a copyable
  `templates/screen_template.dart`, two worked examples (`examples/home_screen.dart`,
  `examples/play_scaffold.dart`) and `scripts/check_shell_boundaries.sh`.
- `design/sunburst-pop/system.html` — token values. `design/sunburst-pop/app.html` — layout and
  spacing rhythm for all eight screens. `design/sunburst-pop/screens/01-home.png` …
  `08-settings.png` — the eight rendered targets at 390×844 @2×. `screens/README.md` — the comparison
  procedure. `capture-screens.sh` — regenerates the PNGs.
- There is **no** pause-sheet PNG. It is a state of screen 4, built from the wireframe in
  `references/screen-anatomy.md` §5 and the `PopSheet` entry in `sunburst-components`.

Expected from earlier epics when this branch opens (a missing symbol is a gap in that epic, not
something to re-declare here):

| From | Symbols this epic consumes |
|---|---|
| E01 | `l10n.yaml` + `AppLocalizations` (ADR 0001: gen-l10n adopted, one locale), the bundled Fredoka/Nunito faces, `tool/skill_gates.sh` |
| E02 | `SunburstColors` / `SunburstShape` / `SunburstMotion` / `SunburstType` with asserting `of(context)`, `buildSunburstTheme()` (already wired into `lib/app.dart`), `GameAccent` in `lib/theme/game_accent.dart`, and **`test/support/harness.dart` (`Device`, `Device.all` at DPR 2, `useDevice`, `pumpApp`)** |
| E03 | `PopSurface`, `PopElevation`, `PopButton`, `PopIconButton`, `PopChip`, `PopCard`, `GameCard`, `DifficultySegmented`, `HudPill`, `TimerRing`, `PopProgressBar`, **`PopGridTile`** (not `GridTile` — Material already exports that name; E03 Risk 2), `PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`, `SunburstGlyph`, `lib/core/hud_tone.dart`, and the test support it owns: `test/support/component_harness.dart` (`pumpPopComponent`), `test/support/fake_feedback_service.dart`, `test/support/load_app_fonts.dart`, `dart_test.yaml`'s `golden` tag |
| E04 | `PressPhysics`, `FeedbackService`, `HapticGateway`, `Moment`, `MotionPreferenceScope` (mounted in `lib/app.dart`), `AppSettings` + `appSettingsProvider`, `SunburstMotion.resolve` |
| E05 | `SettingsRepository` + `settingsRepositoryProvider`, `RunRepository` + `runRepositoryProvider`, `RunCommit`, and the derived reads in `lib/data/data_providers.dart`: `settingsProvider`, `allBestsProvider`, `personalBestProvider(RunScope)`, `runStatsProvider(RunScope)`, `chartSeriesProvider(RunScope)`, `streakProvider`. **There is no `StatsRepository`** — every number these screens render is a fold over the one `runs` table, and `RunRepository` is that table's single source of truth (E05 T05.7). |
| E06 | `GameDefinition` (incl. `runLimitFor`), `GameId`, `Difficulty`, `RunScope.of`, `BoardBackground`, `BoardSnapshot`, `GameHud`, `HudSlot`, `RunConfig`, `RunPhase`, `RunState`, `RunOutcome`, `RunNotifier` + `runNotifierProvider`, `gameRegistryProvider`, `gameDefinitionProvider`, `clockProvider`, `ScoreFormatter` + `scoreFormatterProvider` |

## What we will achieve

Run `flutter run` on a 390×844 device and you can: land on Home, see three game cards (two placeholder
games, one locked "Coming soon" slot) plus the Daily Mix card and a 4-day-streak chip; tap a card into
Game detail; pick a difficulty; tap Play and watch a full-bleed grape 3-2-1 countdown; land on the play
scaffold with a live Time pill, a progress track and a stub board; tap pause and get the sheet; tap
"Leave run" and land on Results; tap Home and be back; switch to Stats and Settings on the bottom nav
and come back to Home with its scroll position intact; flip every Settings toggle and see the value
survive a cold restart.

Concretely, at the end of this epic:

- Eight screens exist under `lib/features/**` and each has been placed side by side with its PNG in
  `design/sunburst-pop/screens/` at 390×844 and signed off through the five-step order.
- `check_shell_boundaries.sh lib` is green: no game navigates, builds a `Scaffold`/`AppBar`/`SafeArea`
  or draws shell chrome, and no file under `lib/features/**` names a specific game.
- `flutter test` runs one widget test per screen over a fake registry and fake repositories, a golden
  per screen at 390×844, an overflow matrix at 320/360/390/430 × text scale 1.0/1.3/2.0, an a11y test
  per screen for the single `Semantics(header: true)` and entry focus, a routing test covering every
  deep link and the four `PopScope` rows, and a test that the run-over announcement fires exactly once.
- `grep -rn "switch (gameId)\|switch (config.gameId)" lib/features/` returns nothing.
- `lib/games/placeholder/` is the only game code in the tree and is marked for deletion by E08.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `sunburst-shell-screens` | Owns this epic. The eight wireframes with exact padding (`references/screen-anatomy.md`), the `GameDefinition`/`BoardSnapshot` seam (`references/shell-game-boundary.md`), the `RunPhase` table and announcement rules (`references/run-lifecycle.md`), and `scripts/check_shell_boundaries.sh` — the epic's named gate. |
| `sunburst-components` | Every screen is composed from its thirteen classes plus `PopIconButton`/`PopChip`; the nine shell composites must compose `PopSurface` and add no new visual vocabulary. Also fixes `PopElevation` and the ≥48px target rule. |
| `sunburst-tokens` | Gutter 20, `cardGap` 16, `e1…e4`, every hex and every type step. Rule 11 of the shell skill forbids `copyWith(fontSize:)`, so the six missing type steps (`titleBar`, `greeting`, `sectionLabel`, `heroTitle`, `countdownNumeral`, `statValue`) are **T07.0's deliverable**, added by `references/adding-a-token.md`'s four-places-plus-the-const-instance procedure before any screen asserts against them. |
| `sunburst-motion-and-haptics` | Names the moments these screens fire: `countdownBeat`, `runStart`, `runEnd`, `resultsReveal`, `personalBest`, `sheetTransition`, `routeTransition`, `toggleFlip`, `homeCardEnter`, `timerAlarm`. The shell decides *when*; this skill fixes the numbers and the reduce-motion residue. |
| `navigation-and-routing` | One `GoRouter` in `lib/routing/`, `StatefulShellRoute.indexedStack` for the three branches, identity in path params never `state.extra`, pure `redirect`, `errorBuilder`, `PopScope` mechanics, `CustomTransitionPage` under reduced motion. |
| `state-management-riverpod` | One `Notifier` per screen over an immutable ready-to-render state, `ref.watch`/`ref.read`/`ref.listen` split, `family` + `autoDispose` keying, providers-as-DI with throwing seams the tests override. |
| `scaffold-feature-module` | The fixed folder shape each of the six feature folders must take (`presentation/`, `application/`, `domain/`, `<feature>_providers.dart`), the no-cross-feature-import rule, and `scripts/verify_feature.sh`. |
| `widget-composition` | Named `const` widget classes never `Widget _buildX()`, `build()` ≤ 80 lines and ≤ 5 levels of nesting, lazy lists, `EdgeInsetsDirectional`, computed cell sizing for the results stat trio and the stats chart. |
| `accessibility-as-code` | One `Semantics(header: true)` per screen, a label on every glyph or `ExcludeSemantics`, no `FittedBox`/`ellipsis`/clamped `textScaler`, ≥48px targets, `OrdinalSortKey` traversal, `boldText` honoured. |
| `widget-golden-and-a11y-testing` | The harness contract (`useDevice` before `pumpApp`, physical-pixel sizing, MediaQuery above `MaterialApp`), one `testWidgets` per matrix tuple, the fit assertion, `isSemantics`, the two golden lanes, and `scripts/check-test-hygiene.sh`. |
| `testing-strategy` | Bare-`implements` fakes over mocktail for the repositories, `ProviderContainer.test` for notifier-only assertions, seeded determinism, the suite-time budget this epic can blow. |
| `ui-states-and-feedback` | Stats and Home render off streams that can be empty or failed: one switch over `AsyncValue`, three distinct empty/filtered/error screens, never `e.toString()`, retry via `ref.invalidate`. |
| `custom-canvas-and-gestures` | `HalftoneDots` and the stats bar chart are painters: dumb painter + immutable scene, `shouldRepaint` as one value compare, zero allocation in `paint()`, `ExcludeSemantics` plus a sibling `Semantics` that speaks the values. |
| `i18n-rtl-l10n` | Every string on eight screens goes through `AppLocalizations`; the game title/tagline/kicker keys are resolved by `GameId`, and Directional-only geometry keeps RTL correct by construction. |
| `adaptive-layout` | The 320–430 width band and the `MediaQuery.sizeOf`/`paddingOf` aspect reads; the HUD reflow and the scrolling results/stats bodies are constraint-driven, never device checks. |
| `async-safety` | `ref.listen` callbacks that route, `PauseSheet.show` awaited results, `ref.mounted` after every await before touching a `BuildContext`, and disposing every `FocusNode` the screens create. |
| `naming-conventions` | `*Screen` / `*Notifier` / `*Repository` suffixes, file name = primary declaration, `lowercase_with_underscores` paths — the shell boundary gate greps on these names. |
| `dartdoc-conventions` | Nine composites and eight screens are public API; `public_member_api_docs` is an analyzer error, so every one needs a `///` summary that says what it is for. |

## Tasks

### T07.0 — The six shell type steps

**Goal.** Add the type steps the eight screens render with, before any screen test asserts against them
— so no screen reaches for `copyWith(fontSize:)` and no task is blocked on a token that does not exist.

**Why it is a task and not a footnote.** T07.3 asserts `type.statValue` and T07.9 asserts
`type.countdownNumeral`. Neither exists after E02 (ten steps) or E03 (twelve). A shell screen that adds
a step inline fails `check_raw_values.sh`; one that uses `copyWith(fontSize:)` fails
`sunburst-shell-screens` rule 11. The steps are tokens, and tokens land in `lib/theme/`.

**Tests first (TDD).** In `test/theme/sunburst_type_test.dart`, extending the specs E02 and E03 wrote:
- one expectation per new step asserting family, weight, `fontSize`, `height` and `letterSpacing`
  against its `app.html` evidence: `titleBar` (the play/detail top-bar title), `greeting` (Nunito 800
  at 14, screen 01), `sectionLabel` (10 upper with .15em tracking — screens 01, 02, 06, 07),
  `heroTitle` (screen 02's hero), `countdownNumeral` (132, screen 03), `statValue` (the stat-box and
  results-trio value, tabular);
- `'countdownNumeral and statValue carry tabular figures'` — a digit change must not reflow;
- `'copyWith replaces each new step independently'` and `'lerp interpolates every new step'`, the same
  coverage trio E03 T03.1 used;
- the step-name list literal in E02 T02.7's count test gains all six, taking the scale from twelve to
  **eighteen**. The count still derives from `DesignSource.dartFieldNames(typeFile, 'SunburstType')`;
  only the named literal is edited, in this commit, with each addition's evidence beside it.

**Implementation.** Add the six steps to `lib/theme/sunburst_type.dart` by
`sunburst-tokens/references/adding-a-token.md`: field, constructor, `copyWith`, `lerp`, the
`const sunburstPop` instance — plus the test literal, which is the place that gets forgotten. Every step
is **DERIVED** from `app.html` and carries a `// DERIVED` comment naming the rule it was measured from,
because `system.html` §04 names ten steps and these are not among them. Update
`sunburst-tokens/references/shape-and-type.md` in the same PR so the skill and the code agree.

**Files.** `lib/theme/sunburst_type.dart`, `test/theme/sunburst_type_test.dart`,
`.claude/skills/sunburst-tokens/references/shape-and-type.md`.

**Skills.** `sunburst-tokens`, `sunburst-shell-screens`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the steps are numbers here; their *roles* are compared
screen by screen from T07.5 onward, which is step 4 of the comparison order).

**Done when.**
- [ ] Eighteen steps; the count test derives from the source file and its named literal lists all
      eighteen with evidence.
- [ ] `grep -rn 'copyWith(fontSize:\|fontSize:' lib/features/ lib/ui/` is empty.
- [ ] `check_raw_values.sh lib` green.

**Commits.**
1. `test(theme): pin the six shell type steps against app.html`
2. `feat(theme): add titleBar, greeting, sectionLabel, heroTitle, countdownNumeral and statValue`

---

### T07.1 — Test harness, fakes and the placeholder game registry

**Goal.** Give every later task a pinned 390×844 harness, fake game definitions, fake repositories, and
a runnable two-game registry so the shell is screenshot-comparable before any real game exists.

**Tests first (TDD).**
- `test/support/harness_test.dart`
  - `pins the reference device in physical pixels` — after `useDevice(Device.reference390)`,
    `tester.view.physicalSize == const Size(780, 1688)` and `tester.view.devicePixelRatio == 2.0`.
    **DPR 2, not 3**: that is what `capture-screens.sh` rendered the eight PNGs at (they are 780×1688),
    and a golden blessed at DPR 3 cannot be laid beside a DPR-2 reference. E02 pinned this; this test
    is the tripwire that stops a later epic from quietly changing it.
  - `resets the view between tests` — a second test in the file sees the default surface, proving
    `addTearDown(view.reset)` fires.
  - `layers MediaQuery above MaterialApp` — inside the app, `MediaQuery.sizeOf(context)` is
    `Size(390, 844)` *and* `MediaQuery.textScalerOf(context)` is the value passed. A bare
    `MediaQueryData()` would zero the size; this test is what catches it.
- `test/support/fakes_test.dart`
  - `an un-overridden repository seam throws` — reading `runRepositoryProvider` on a bare
    `ProviderContainer` throws `UnimplementedError`.
  - `FakeSettingsRepository.watch emits the seeded value, then each write` — expect a 3-element stream.
  - `FakeRunRepository.watchBestsByGame returns the seeded best per game id` — the all-games fold Home
    reads. There is **no** `FakeStatsRepository`, because there is no `StatsRepository` (E05 T05.7).
  - `FakeRunRepository.saveRun returns Ok(RunCommit(record, isPersonalBest))` — the flag is a field on
    the committed value, seeded per test, not a second read.
- `test/games/placeholder_registry_test.dart`
  - `the registry yields two unlocked placeholders and one locked slot, in declaration order`.
  - `a placeholder board builds without a Scaffold` — pump `buildBoard` under a bare
    `Directionality` + `ProviderScope`; `find.byType(Scaffold)` finds nothing and no exception is thrown.

**Implementation.**
- `test/support/harness.dart` is **E02 T02.1's** file, and it already ships `Device.compact320`,
  `Device.small360`, `Device.reference390`, `Device.large430` and `Device.all`, all at DPR 2. This task
  adds nothing to it and forks nothing from it: `Device.all` is the one matrix name across E03, E07,
  E08, E09 and E10, and a `Device.shellMatrix` beside it would be a second list to keep in step. If the
  file is missing, that is an E02 gap — fix it there.
- `test/support/shell_harness.dart` — `pumpShellApp({overrides, textScaler, boldText, initialLocation})`
  building `ProviderScope` → `MediaQuery(copyWith)` → `App`, seeding the router's `initialLocation`.
  It composes `useDevice` and `pumpApp` from the shared harness rather than re-implementing them.
- `test/support/fake_game_registry.dart` — `fakeAlphaDefinition` (`GameAccent.stroopCoral`,
  `ScoreFormat.points`, `BoardBackground.surfaceSunk`), `fakeBetaDefinition`
  (`GameAccent.schulteTurquoise`, `ScoreFormat.duration`, `BoardBackground.gameAccent`),
  `fakeLockedDefinition` (`isLocked: true`), and `FakeBoardSnapshotController` for pushing
  `BoardSnapshot`s upward in later tasks.
- `test/support/fake_repositories.dart` — `FakeRunRepository` and `FakeSettingsRepository`, both bare
  `implements` with public seeded fields. No mocktail, and **no `FakeStatsRepository`**.
- `test/support/load_app_fonts.dart` is **E03 T03.2's** file — E03 is the first epic with a real-font
  golden lane. Import it; do not re-create it.
- `lib/games/placeholder/placeholder_definitions.dart` and
  `lib/games/placeholder/ui/placeholder_board.dart` — `placeholderCoralDefinition`,
  `placeholderTurquoiseDefinition`, `placeholderLockedDefinition`. The board is a token-only sunken
  rectangle that never sets an outcome. File header: `// DELETE IN E08 — see epics/E08-stroop-rush.md`.
- `lib/games/game_registry.dart` — the placeholder list appended to the empty const list E06 shipped.
  E06's own `'the registry is the only file in lib/ that names a game'` test still holds; its
  emptiness assertion lives in E06's fixture-registry override and is unaffected.
- `lib/l10n/game_strings.dart` — `gameStringsProvider`, a `Map<GameId, GameStrings>` built from
  `AppLocalizations` getters, **and `appLocalizationsProvider`**, a `Provider<AppLocalizations>`
  overridden at the composition root. The second is not optional: E09's `schulteSnapshotProvider`
  needs localized HUD labels and has no `BuildContext`, and shipping `gameStringsProvider` without it
  leaves E09 to invent one. This file is the **second and last** file allowed to name every game — the
  rule is stated here, once, and `game_registry.dart`'s own header claims only that it is the sole
  file that may *enumerate the registry*, so the two do not contradict.
- ARB keys `game_placeholder_coral_title` / `_tagline` / `_kicker` and the turquoise and locked
  equivalents, appended to **`lib/l10n/app_en.arb`** — E01 T01.10's template, at
  `l10n.yaml`'s `arb-dir: lib/l10n`. Not `lib/l10n/arb/`: `check_arb_parity.sh` resolves the template
  relative to the arb dir, and E08/E09 append to this same file.

**Files.** `test/support/shell_harness.dart`,
`test/support/fake_game_registry.dart`, `test/support/fake_repositories.dart`,
`test/support/harness_test.dart`, `test/support/fakes_test.dart`,
`test/games/placeholder_registry_test.dart`, `lib/games/placeholder/placeholder_definitions.dart`,
`lib/games/placeholder/ui/placeholder_board.dart`, `lib/games/game_registry.dart`,
`lib/l10n/game_strings.dart`, `lib/l10n/app_en.arb`.

**Skills.** `testing-strategy`, `widget-golden-and-a11y-testing`, `state-management-riverpod`,
`sunburst-shell-screens`, `i18n-rtl-l10n`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/support test/games` green.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green with
      `lib/games/placeholder/` present — the placeholder board proves the gate, it does not dodge it.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` with the twelve new keys and
      `flutter analyze --fatal-infos` is clean (`nullable-getter: false` makes a missing key a compile
      error, which is the gate that matters at one locale).
- [ ] `check_arb_parity.sh lib/l10n` was run once by hand and its exit-2
      `no locale ARB files beside the template` output is pasted into the PR body — it stays in
      `tool/skill_gates.sh`'s skip table until a second locale lands (E01 T01.10, ADR 0001). Do not
      wire it into this epic's gate list expecting it to pass.
- [ ] `test/support/harness.dart` is unchanged by this epic; `grep -rn 'Device.shellMatrix\|FakeStatsRepository\|lib/l10n/arb/' .` returns nothing.
- [ ] No test file imports `lib/games/placeholder/` — shell tests use the fakes.

**Commits.**
1. `Add fake game registry and fake repositories for shell tests`
2. `Add placeholder game definitions so the shell is runnable before E08`
3. `Resolve game titles by id through gameStringsProvider and appLocalizationsProvider`

---

### T07.2 — Header and band composites

**Goal.** Ship `RayHeader`, `HalftoneDots`, `PlayBand` and `Wordmark` — the four composites that paint
a coloured region behind a screen's h1 or a HUD.

**Tests first (TDD).**
- `test/features/shell/widgets/ray_header_test.dart`
  - `paints its fill and a 3px ink bottom border only` — read the `BoxDecoration`; assert
    `border.bottom.width == shape.borderWidth`, `border.top == BorderSide.none`, colour is
    `colors.border`.
  - `insets its content 6/20/22` — `getRect` of the child versus `getRect` of the header.
  - `starts below the top inset` — pumped under `MediaQuery(padding: EdgeInsets.only(top: 47))`, the
    header's `top` equals 47.
  - `exposes no semantics of its own` — the ray and dot layers are inside `ExcludeSemantics`.
- `test/features/shell/widgets/halftone_dots_test.dart`
  - `shouldRepaint is false for an equal scene and true when opacity changes` — one value compare over
    `HalftoneScene`.
  - `allocates no Paint inside paint()` — assert the painter's `Paint` fields are `final` and
    identical across two `paint()` calls on a recording canvas.
- `test/features/shell/widgets/play_band_test.dart`
  - `fills with the accent base and carries only a bottom border` for each `GameAccent` case.
  - `lays its children out at gutter 20`.
- `test/features/shell/widgets/wordmark_test.dart`
  - `is labelled MindForge and is not a header` — `isSemantics(label: 'MindForge', isHeader: false)`.

**Implementation.** `lib/features/shell/widgets/ray_header.dart` (`RayHeader({fill, rayFill,
rayOpacity, dotOpacity, padding, child})`), `halftone_dots.dart` (`HalftoneDots` +
`_HalftoneDotsPainter` + immutable `HalftoneScene`), `play_band.dart` (`PlayBand({accent, child})`),
`wordmark.dart` (`Wordmark`). Each reads `SunburstColors.of` / `SunburstShape.of` / `SunburstType.of`
and constructs no `Color`, `Duration`, `Curve` or `BoxShadow` of its own. Ray geometry is a conic
sweep painted at the declared opacity; the dot lattice is a `HalftoneScene` value.

**Files.** `lib/features/shell/widgets/{ray_header,halftone_dots,play_band,wordmark}.dart`,
`test/features/shell/widgets/{ray_header,halftone_dots,play_band,wordmark}_test.dart`.

**Skills.** `sunburst-shell-screens`, `sunburst-components`, `sunburst-tokens`,
`custom-canvas-and-gestures`, `widget-composition`, `accessibility-as-code`, `dartdoc-conventions`.

**Screenshot check.** Run each composite in a harness page at 390 width and compare the header strip
against four references, in the order structure → spacing rhythm → surface construction → type role →
sampled hex: `01-home.png` (sunshine fill, rays .5, dots .16, pad 6/20/22), `07-stats.png` (turquoise,
**dots only, no rays**, pad 10/20/18), `08-settings.png` (grape, rays at **.3** not .55, pad 10/20/18),
and the play band of `04-stroop-rush.png` and `05-schulte-grid.png` (rays .45 + dots .16, 3px ink
bottom border). A ray opacity that is uniformly .55 across all three headers is the defect this check
exists to catch.

**Done when.**
- [ ] `flutter test test/features/shell/widgets` green.
- [ ] `check_raw_values.sh lib` and `check_component_hygiene.sh lib` green.
- [ ] Sampled hexes match `system.html`; no `blurRadius`/`spreadRadius` above 0 anywhere.

**Commits.**
1. `Add HalftoneDots painter with a value-compared scene`
2. `Add RayHeader composite`
3. `Add PlayBand and Wordmark composites`

---

### T07.3 — Card and stat composites

**Goal.** Ship `GameHeroPanel`, `DailyMixCard`, `StatBox`, `ScoreSlab` and `BestCard` — the five
composites that carry a value inside a raised surface.

**Tests first (TDD).**
- `test/features/shell/widgets/game_hero_panel_test.dart`
  - `renders at radiusXl on e3 with the accent fill` — read the `PopSurface` arguments.
  - `puts the ink label on a dot layer at .08` — the hero's kicker must clear 4.5:1 against the
    composited fill; assert the dot opacity value, and assert the label style is `type.label` with
    `colors.textPrimary`.
  - `lays four 38pt answer swatches in a row` — `getSize` per swatch.
- `test/features/shell/widgets/daily_mix_card_test.dart`
  - `renders the grape variant on Home and the paper variant on game detail` — one widget, two fills.
  - `the whole card is one ≥48px tap target labelled by its title, with a non-null onTap` — the card
    navigates (T07.5 fixes where); an inert chevron is the dead affordance E10 T10.1 forbids.
- `test/features/shell/widgets/stat_box_test.dart`
  - `prints its value at statValue with tabular figures` and `uses textPrimary on the sunshine
    variant` (never `textSecondary` on a saturated fill).
- `test/features/shell/widgets/score_slab_test.dart`
  - `draws a 5px sunshine hard text shadow behind scoreHero` — assert the shadow colour is
    `colors.accent` and its `blurRadius` is 0.
  - `does not shrink at text scale 2.0` — `getSize` of the score text grows; no `FittedBox` in the tree.
- `test/features/shell/widgets/best_card_test.dart`
  - `renders one value chip per game accent` and `formats via ScoreFormat` — `points` → `1,480`,
    `duration` → `18.6s`, asserted through the already-formatted string the widget is handed.

**Implementation.** `lib/features/shell/widgets/game_hero_panel.dart`, `daily_mix_card.dart`,
`stat_box.dart`, `score_slab.dart`, `best_card.dart`. All compose `PopSurface`; none formats a number
— each takes an already-formatted `String` (rule 5 of `widget-composition`). `StatBox` takes a
`StatBoxTone` (`accent` / `paper`) rather than a `Color`.

**Files.** the five widget files plus their five test files under
`test/features/shell/widgets/`.

**Skills.** `sunburst-shell-screens`, `sunburst-components`, `sunburst-tokens`, `widget-composition`,
`accessibility-as-code`, `dartdoc-conventions`.

**Screenshot check.** Compare each composite against its region in the reference, in the five-step
order: `GameHeroPanel` and the `StatBox` duo against `02-game-detail.png`; `DailyMixCard` grape variant
against `01-home.png` and paper variant against `02-game-detail.png`; `ScoreSlab` and the three-column
stat trio against `06-results.png`; `BestCard` against `07-stats.png`. Check the shadow step per
surface (`e1` stat boxes, `e2` cards, `e3` hero and slab) — a uniform `e2` across all of them is the
common defect.

**Done when.**
- [ ] `flutter test test/features/shell/widgets` green.
- [ ] `check_raw_values.sh lib`, `check_component_hygiene.sh lib`, `check-widget-composition.sh lib`
      all green.
- [ ] No composite constructs a `BoxShadow`, `Color`, `Duration` or `Curve`.

**Commits.**
1. `Add GameHeroPanel and StatBox composites`
2. `Add DailyMixCard composite with grape and paper variants`
3. `Add ScoreSlab and BestCard composites`

---

### T07.4 — Router, branch shell and back handling

**Goal.** One `GoRouter` in `lib/routing/`, a three-branch `StatefulShellRoute.indexedStack` that owns
`PopBottomNav`, deep links that survive a cold start, and the four `PopScope` rows from
`references/run-lifecycle.md`.

**Tests first (TDD).**
- `test/routing/app_router_test.dart`
  - `cold start at each branch location renders that screen with the matching nav index` — `/`,
    `/stats`, `/settings`.
  - `branch state survives a tab switch` — scroll Home, go to `/stats`, return, assert the scroll
    offset is preserved (this is what `indexedStack` buys and a hand-rolled shell loses).
  - `game detail reads its id from pathParameters` — cold start at `/game/placeholder_coral` with
    `state.extra == null` renders the detail screen for that definition.
  - `a run route names its whole config` — `/game/placeholder_coral/play?difficulty=classic&seed=42`
    reconstructs a `RunConfig` equal to the one built by the Play button.
  - `a cold-start deep link into a run with no live notifier redirects to game detail` — the pure
    `appRedirect` returns `/game/placeholder_coral` when the phase snapshot is `idle`.
  - `an unknown location renders NotFoundScreen, not a red box`.
  - `PopScope rows` — one test per phase: `countdown` → `abandon()`, `playing` → `pause()`, `paused` →
    `keepPlaying()`, `over` → pops. Assert the notifier method called, not the route.
  - `no bottom nav on game detail, countdown, play or results` — `find.byType(PopBottomNav)` is empty
    on each of the four.
  - `route transitions collapse under reduced motion` — pumped with `disableAnimations: true`, the
    `CustomTransitionPage` builder returns the child unwrapped.
- `test/routing/routes_test.dart` — `Routes.gameDetail(id)` and `Routes.play(config)` round-trip
  through `GoRouterState` without hand-concatenation.

**Implementation.**
- `lib/routing/routes.dart` — `abstract final class Routes` with `home = '/'`, `stats = '/stats'`,
  `settings = '/settings'`, `gameDetail(GameId)`, `countdown(RunConfig)`, `play(RunConfig)`,
  `results(RunConfig)`. Run routes carry `gameId` as a path parameter and `difficulty` + `seed` as
  query parameters, so the URL alone names the run; `state.extra` is never read.
- `lib/routing/app_router.dart` — the single `GoRouter(...)`, `initialLocation: Routes.home`,
  `refreshListenable` bridged from Riverpod, `redirect: (c, s) => appRedirect(...)` (pure),
  `errorBuilder` → `NotFoundScreen`, `StatefulShellRoute.indexedStack` over the three branches with
  `NavShellScreen` as the branch builder.
- `lib/routing/app_redirect.dart` — the pure redirect function, unit-tested with no widget.
- `lib/routing/run_routes.dart` — `RunRoutes.replaceWithResults(context, config)` and friends, so no
  screen hand-writes a location.
- `lib/features/shell/presentation/nav_shell_screen.dart` — hosts `PopBottomNav` and calls
  `navigationShell.goBranch(index)`. The nav bar lives here and nowhere else.
- `lib/features/shell/presentation/not_found_screen.dart`.
- `lib/app.dart` — switch to `MaterialApp.router(routerConfig: ref.watch(routerProvider))`, one
  `theme:`, no `darkTheme:`, no `themeMode:`.

**Files.** `lib/routing/{routes,app_router,app_redirect,run_routes}.dart`,
`lib/features/shell/presentation/{nav_shell_screen,not_found_screen}.dart`, `lib/app.dart`,
`test/routing/{app_router_test,routes_test,app_redirect_test}.dart`.

**Skills.** `navigation-and-routing`, `sunburst-shell-screens`, `state-management-riverpod`,
`async-safety`, `sunburst-components`, `testing-strategy`.

**Screenshot check.** The 90pt `PopBottomNav` strip against `01-home.png`, `07-stats.png` and
`08-settings.png`: 3px ink top border, `pad 9/14/0`, active tab as a sunshine chip at e1, and the
90pt **including** the bottom inset with the items top-aligned. Confirm the bar is absent from
`02-game-detail.png`, `03-countdown.png`, `04-stroop-rush.png`, `05-schulte-grid.png` and
`06-results.png`.

**Done when.**
- [ ] `flutter test test/routing` green.
- [ ] `.claude/skills/navigation-and-routing/scripts/check_routing.sh lib` green — exactly one
      `GoRouter`, under `routing/`, no `Navigator.pushNamed`, no `extra!`.
- [ ] Every screen is reachable by a URL typed into `initialLocation`.

**Commits.**
1. `Add typed route constants and the pure app redirect`
2. `Add the single GoRouter with the three-branch indexed stack`
3. `Host PopBottomNav in the branch shell and add the 404 screen`
4. `Wire MaterialApp.router in app.dart`

---

### T07.5 — Home screen

**Goal.** The game hub, rendering the registry as data: streak chip, greeting, h1, Daily Mix card,
section label, one `GameCard` per unlocked game and a dashed locked slot.

**Tests first (TDD).**
- `test/features/home/home_notifier_test.dart` (`ProviderContainer.test`, no widgets)
  - `greeting resolves from the injected Clock` — `Clock.fixed` at 08:00 / 14:00 / 20:00 yields
    morning / afternoon / evening keys. No `DateTime.now()` anywhere.
  - `games are in registry order and carry a formatted best` — `points` → `1,480`,
    `duration` → `18.6s`.
  - `unlockedCount counts only unlocked definitions`.
  - `a repository failure surfaces as an AsyncError, never a thrown exception`.
- `test/features/home/home_screen_test.dart` (fake registry + fake repositories)
  - `renders one card per registry entry plus the locked slot` — three cards for the fake registry.
  - `the locked slot has a dashed 3px ink border, no shadow and no tap action`.
  - `the BEST pill shows the formatted value from allBestsProvider` — `points` → `1,480`,
    `duration` → `18.6s`, and a game with no runs shows no pill rather than a zero.
  - `the Daily Mix card routes to a seeded pick from the registry` — with `clockProvider` fixed, the
    destination is deterministic; with the clock advanced a day, it may differ. No dead chevron.
  - `adding a fourth definition to the fake registry adds a fourth card with zero source changes` —
    the engine claim, asserted.
  - `exactly one Semantics(header: true), and it is "Ready to train?"`.
  - `focus on entry lands on the h1` — assert the primary focus node after one `pump`.
  - `tapping a card routes to /game/<id>` — assert the location, not a pushed widget.
- `test/features/home/home_golden_test.dart` — `@Tags(['golden'])`, `loadAppFonts()`,
  `Device.reference390`, `matchesGoldenFile('goldens/home_390.png')`.

**Implementation.** `lib/features/home/domain/home_state.dart` (`HomeState`, `HomeGameEntry` — both
immutable with value equality), `application/home_notifier.dart` (`HomeNotifier extends
StreamNotifier<HomeState>` over **`allBestsProvider`** — E05 T05.7's `watchBestsByGame()` fold, the one
read that gives every card its BEST pill without an N+1 of per-game subscriptions — plus
`streakProvider` for the chip and `gameRegistryProvider` for the cards; formats every value through
`scoreFormatterProvider` so `build()` does none), `presentation/home_screen.dart` (dumb
`ConsumerWidget`, composing `RayHeader`, `Wordmark`, `PopChip`, `DailyMixCard`, `GameCard`), and
`presentation/widgets/locked_game_slot.dart` for the dashed "Coming soon" card
(`shape.dashOn`/`dashOff` 9/7, no shadow, `textSecondary`).

**Daily Mix goes somewhere.** `app.html` draws it as a tappable card and T07.3 asserts it is one ≥48px
target, so it cannot ship as a chevron that leads nowhere — E10 T10.1's no-dead-control rule applies to
every affordance, not only the Language row. **Decision for v1:** the card routes to the game detail of
a seeded daily pick — `registry[seededRandomProvider-drawn index]` over the unlocked entries, keyed by
today's `CalendarDay` so the pick is stable for the day and reproducible in a test with a fixed clock.
That is one line of routing and no new screen. A curated multi-game mix is a product feature; record it
as deliberately left out. If the owner would rather not ship the card at all in v1, remove it from the
Home composition and record *that*, with the `app.html` reference — but do not ship it inert.

**Files.** `lib/features/home/{domain/home_state.dart,application/home_notifier.dart,
presentation/home_screen.dart,presentation/widgets/locked_game_slot.dart,home_providers.dart}`,
`test/features/home/{home_notifier_test,home_screen_test,home_golden_test}.dart`.

**Skills.** `sunburst-shell-screens`, `scaffold-feature-module`, `state-management-riverpod`,
`widget-composition`, `ui-states-and-feedback`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `i18n-rtl-l10n`.

**Screenshot check.** `design/sunburst-pop/screens/01-home.png` at 390×844. Order: structure (header /
Daily Mix / section label / three cards / nav), spacing rhythm (`pad 16/20/0`, column gap 16, card
inner padding 15/16 and Daily Mix 17/16), surface construction (Daily Mix grape at e2 r-lg, game cards
at e2, 64pt cream art frame at r-md e1, locked card dashed with **no** shadow), type role (greeting
14/800 Nunito on ink — not ink-2 — and the h1 at `displayL` 33/1.02), sampled hex.

**Done when.**
- [ ] `flutter test test/features/home` green, golden committed.
- [ ] `grep -rn "placeholder" lib/features/home/` returns nothing.
- [ ] `check_shell_boundaries.sh lib` and `verify_feature.sh lib/features/home` green.
- [ ] Compared against `01-home.png`; deltas are either fixed or committed as an `app.html` change
      plus regenerated PNGs.

**Commits.**
1. `Add HomeNotifier over the registry and the stats repository`
2. `Add HomeScreen composed from shell composites`
3. `Add the dashed locked game slot`
4. `Add the home screen golden at 390x844`

---

### T07.6 — Game detail and countdown

**Goal.** The `idle` and `countdown` phases: the hero panel, stat duo, difficulty segmented control and
Play button; then the one edge-to-edge screen in the app.

**Tests first (TDD).**
- `test/features/game_detail/game_detail_notifier_test.dart`
  - `difficulties come from the definition, in display order, with lock flags`.
  - `selecting a difficulty is in-session state and does not touch a repository`.
  - `Play builds a RunConfig with a seed drawn from seededRandomProvider` — with the seed provider
    overridden, the config is deterministic.
- `test/features/game_detail/game_detail_screen_test.dart`
  - `the hero title is the only Semantics(header: true)`.
  - `the segmented control marks exactly one item selected and is keyboard traversable in display
    order` (`OrdinalSortKey`).
  - `a locked difficulty is not tappable and states why in its label` — non-colour redundancy.
  - `Play routes to the countdown for the selected difficulty`.
  - `no PopBottomNav on this screen`.
- `test/features/play/countdown_screen_test.dart`
  - `renders three dots and fills one per beat` — pump `1000ms` three times with a fake clock; assert
    the filled-dot count 1 → 2 → 3, then a transition to `playing`.
  - `announces each numeral exactly once` — capture `SystemChannels.accessibility` announce messages;
    expect exactly `['3', '2', '1']`.
  - `sets SystemUiOverlayStyle.light and skips the top SafeArea` — under
    `MediaQuery(padding: EdgeInsets.only(top: 47))`, the grape fill's `top` is 0 while the content's
    top is ≥ 47.
  - `the close button calls abandon() and nothing is written` — `FakeRunRepository.saveCalls` is empty.
  - `under reduced motion the ring pop collapses to Duration.zero and the numerals still change`.
- Goldens: `game_detail_390.png`, `countdown_390.png`.

**Implementation.** `lib/features/game_detail/{application/game_detail_notifier.dart,
presentation/game_detail_screen.dart}` composing `PopIconButton`, `GameHeroPanel`, `StatBox`,
`DifficultySegmented`, `DailyMixCard` (paper variant) and a full-width `PopButton` at
`type.buttonLarge`. `lib/features/play/presentation/countdown_screen.dart` — the only screen with
`SystemUiOverlayStyle.light`, `SafeArea(top: false)` and its own inset; composes `TimerRing` at e4
(the one e4 on the screen) and a dot row. The 1000ms beat and the `.86 → 1.06 → 1.00` numeral pop are
`SunburstMotion` values via `Moment.countdownBeat`; the shell never writes a `Duration`.

**Files.** `lib/features/game_detail/**`, `lib/features/play/presentation/countdown_screen.dart`,
`test/features/game_detail/**`, `test/features/play/countdown_screen_test.dart`, two golden files.

**Skills.** `sunburst-shell-screens`, `sunburst-motion-and-haptics`, `sunburst-components`,
`state-management-riverpod`, `accessibility-as-code`, `widget-golden-and-a11y-testing`,
`scaffold-feature-module`.

**Screenshot check.** `02-game-detail.png`: top bar `pad 2/20/16`, hero at r-xl e3 with the dot layer
at .08, the 2-column stat row at gap 12 (sunshine + paper), the `DIFFICULTY` label at 10 upper ink-2,
the segmented track in cream-2 with the selected item translated `(-1,-1)` on a 2px shadow, and the
leaf Play button at r-xl `pad 18/20` / 21pt pinned to the bottom by a spacer.
`03-countdown.png`: full-bleed grape with status glyphs tinted cream, the 238pt sunshine ring at e4,
the 132pt numeral, `gap 26` to "Get ready" with its 4px ink hard text shadow, and the dot row with
`pad-bottom 52`. Confirm the countdown is the **only** screen whose fill reaches y=0.

**Done when.**
- [ ] `flutter test test/features/game_detail test/features/play/countdown_screen_test.dart` green.
- [ ] `check_motion_tokens.sh lib` green — no raw `Duration(`, `Curves.` or `Cubic(` outside
      `lib/theme/`.
- [ ] Both screens compared against their PNGs.

**Commits.**
1. `Add GameDetailNotifier with in-session difficulty selection`
2. `Add GameDetailScreen with the hero, stat duo and difficulty control`
3. `Add the full-bleed CountdownScreen with per-beat announcements`
4. `Add game detail and countdown goldens`

---

### T07.7 — Play scaffold, HUD and pause sheet

**Goal.** The critical screen: identical chrome for every game, a board slot holding the placeholder,
and the pause sheet with its two actions and its lifecycle triggers.

**Tests first (TDD).**
- `test/features/play/play_scaffold_screen_test.dart`
  - `the chrome is identical for two different games` — pump with `fakeAlphaDefinition` and
    `fakeBetaDefinition`; assert `getRect` of the top bar, the HUD row and the track match within
    `epsilon: 0.5`. Only the board pane's background differs. This is the epic's central claim.
  - `renders exactly three HudPills, equal flex, gap 8` — `getSize` per pill, widths equal.
  - `slot A is the shell's clock, not the game's` — the fake snapshot leaves `slotA.value` empty and
    the pill still shows the elapsed time from `Clock.fixed`.
  - `HudTone.alarm paints danger with both lines inverted` — asserted on colour values, not pixels.
  - `progress == null removes the track widget entirely` rather than drawing an empty well.
  - `the HUD reflows from a Row to a Wrap above textScaler 1.3` — at 1.3 the three pills share a
    `top`; at 2.0 the third pill's `top` is greater than the first's.
  - `there is no Semantics(header: true) on this screen` — the board is the content.
  - `the HUD is not a liveRegion` — assert `isSemantics(isLiveRegion: false)` on each pill.
  - `the board pane applies SafeArea and the 0/20/26 gutter so the board does not` — the child's rect
    is inset from the screen by exactly those values.
- `test/features/play/pause_sheet_test.dart`
  - `opens on pause() and on AppLifecycleState.inactive/paused/hidden` — three tests, driven through
    the observer, not by backgrounding an app.
  - `resuming does not dismiss it` — after `resumed`, the phase is still `paused`.
  - `Keep playing returns to countdown, not straight to playing`.
  - `Leave run sets RunOutcome.abandoned and writes nothing` — `FakeRunRepository.saveCalls` is empty.
  - `barrier tap and system back both mean Keep playing`.
  - `it has exactly two actions` — assert the count; a third is a design change.
  - `focus on open lands on "Leave the run?"`.
- Goldens: `play_scaffold_coral_390.png` and `play_scaffold_turquoise_390.png` (chrome only; the board
  is the placeholder rectangle).

**Implementation.** `lib/features/play/presentation/play_scaffold_screen.dart` — `PopScope` over
`Scaffold(backgroundColor: colors.surface)`, `SafeArea(bottom: false)`, `_PlayTopBar`, `PlayBand`
wrapping `_HudRow` + `PopProgressBar`, `Expanded(_BoardPane(...))` with
`RepaintBoundary(definition.buildBoard(context, config))` as the one seam. One `ref.listen` on
`runNotifierProvider(config).select((s) => s.phase)` owns every route change and the pause sheet.
`presentation/widgets/hud_row.dart` — the `Row` → `Wrap` reflow, driven by
`MediaQuery.textScalerOf(context).scale(1) > 1.3` (DERIVED, comment it at the point of use).
`presentation/pause_sheet.dart` — `PauseSheet.show(context, config)` over `PopSheet`, ink scrim at 55%
(DERIVED), grab handle 56×6, `Keep playing` (sunshine) and `Leave run` (paper secondary).

**Files.** `lib/features/play/presentation/{play_scaffold_screen,pause_sheet}.dart`,
`lib/features/play/presentation/widgets/{hud_row,board_pane,play_top_bar}.dart`,
`test/features/play/{play_scaffold_screen_test,pause_sheet_test,play_golden_test}.dart`.

**Skills.** `sunburst-shell-screens`, `sunburst-components`, `sunburst-motion-and-haptics`,
`state-management-riverpod`, `async-safety`, `accessibility-as-code`, `adaptive-layout`,
`widget-golden-and-a11y-testing`.

**Screenshot check.** Compare against **both** `04-stroop-rush.png` and `05-schulte-grid.png`, and
compare them to each other first: the top bar (`pad 2/20/10`, pause button, flexed title, difficulty
chip), the play band (accent fill, rays .45 + dots .16, 3px ink bottom border), the HUD row
(`pad 2/20/12`, gap 8, three paper pills at e1 r-md, `highlight` = sunshine with an ink label) and the
track (`pad 0/20/14`, height 16, pill, cream-2 well, 45°/9pt accent stripes) must be pixel-identical
between the two references; any difference in the chrome is an implementation defect. The board pane
(`pad 0/20/26`, top 20) differs only in background: `surfaceSunk` on 04, the game accent on 05.
**Board interiors are out of scope** — they are stubs here and are signed off in E08 and E09.

**Done when.**
- [ ] `flutter test test/features/play` green, both goldens committed.
- [ ] `check_shell_boundaries.sh lib` green — the placeholder board adds no `Scaffold`, `SafeArea`,
      `HudPill`, `Timer.periodic` or navigation.
- [ ] `grep -rn "FittedBox\|TextOverflow.ellipsis\|withClampedTextScaling" lib/features/play/` empty.
- [ ] The chrome is byte-identical between the two goldens except inside the board pane.

**Commits.**
1. `Add the play top bar and HUD row with the text-scale reflow`
2. `Add PlayScaffoldScreen with the board pane seam and the phase listener`
3. `Add PauseSheet with lifecycle and back-gesture triggers`
4. `Add play scaffold goldens for both board backgrounds`

---

### T07.8 — Results screen and the single run-over announcement

**Goal.** Pay off the run: header, personal-best badge, score slab, the fixed three-stat trio, and one
announcement per run — never one per stat.

**Tests first (TDD).**
- `test/features/results/results_screen_test.dart`
  - `renders the score through ScoreFormat` — `points` and `duration` variants.
  - `the trio is a fixed 3-column grid` — three cells, equal widths, gap 10; a definition supplying
    two stats is a `GameDefinition` bug, asserted as a thrown `ArgumentError` in the notifier, not a
    layout branch.
  - `the personal-best badge appears only when the committed row says so` — with `FakeRunRepository`
    returning `Ok(RunCommit(record, isPersonalBest: false))`, no badge. The flag rides on E05's commit
    value, computed inside the insert's transaction; the screen never re-reads `watchPersonalBest`,
    which would race the write it is rendering.
  - `a save failure shows the saveFailure state and no badge` — never `e.toString()` in the UI; the
    message comes from an ARB key mapped from `Failure.code`.
  - `"Nice run!" is the only Semantics(header: true) and takes focus on entry`.
  - `Play again builds a new RunConfig with a new seed at the same difficulty` — the old config is
    not reused; `over` is terminal.
  - `no PopBottomNav on this screen`.
- `test/features/results/run_over_announcement_test.dart`
  - `announces the whole outcome exactly once` — install a mock handler on
    `SystemChannels.accessibility`, drive `playing → over`, pump three extra frames and rebuild the
    screen; assert the captured announce list has **length 1** and reads
    `"Run over. Final score 1,240. New personal best."`.
  - `no per-stat announcement and no liveRegion on the trio`.
- `test/features/results/results_golden_test.dart` — `results_390.png`.

**Implementation.** `lib/features/results/{application/results_notifier.dart,
presentation/results_screen.dart}`. The notifier reads the committed `RunState` and produces a
ready-to-render `ResultsState` (already-formatted score, three `ResultStat`s, badge flag, optional
failure code). The screen composes `RayHeader` (leaf, rays .55, centred, `pad 10/20/26`), `PopBadge`
(sunshine, e2, static −2.5° tilt), `ScoreSlab`, the trio (`#1` turquoise, `#2` paper, `#3` coral, ink
labels on the saturated tiles) and two `PopButton`s. Body is a `SingleChildScrollView` +
`ConstrainedBox(minHeight: viewport)` + `Center`, so `scoreHero` 76 can grow to 200% instead of being
shrunk. `Moment.resultsReveal` (dy 12 → 0, stagger 40ms) and `Moment.personalBest` come from
`sunburst-motion-and-haptics`; the announcement fires from the notifier's single `→ over` edge, not
from `build()`.

**Files.** `lib/features/results/**`, `test/features/results/**`, `test/features/results/goldens/`.

**Skills.** `sunburst-shell-screens`, `sunburst-motion-and-haptics`, `accessibility-as-code`,
`ui-states-and-feedback`, `state-management-riverpod`, `widget-golden-and-a11y-testing`,
`i18n-rtl-l10n`.

**Screenshot check.** `06-results.png`: leaf header with leaf-deep rays at .55 and `pad 10/20/26`, the
label at 10 upper on **ink**, `displayXl` 42/700 h1, the tilted sunshine badge, body `pad 20/20/26`
centred with gap 16, `ScoreSlab` at paper r-xl e3 `pad 18/20/20` with the 5px sunshine hard text
shadow, and the three-column trio at gap 10 r-md e1 with 10-upper labels. Verify the score's shadow is
sunshine with `blurRadius` 0 — a soft drop shadow here is the most visible possible miss.

**Done when.**
- [ ] `flutter test test/features/results` green, golden committed.
- [ ] The announcement test asserts length 1, not "contains".
- [ ] `check_raw_values.sh lib` green.
- [ ] Compared against `06-results.png`.

**Commits.**
1. `Add ResultsNotifier over the committed run row`
2. `Add ResultsScreen with the score slab and stat trio`
3. `Announce the run outcome once on the over transition`
4. `Add the results golden at 390x844`

---

### T07.9 — Stats and Settings

**Goal.** The two remaining nav branches: lifetime totals with a true-zero bar chart, and the four
feel/accessibility switches wired to the real `SettingsRepository`.

**Tests first (TDD).**
- `test/features/stats/stats_notifier_test.dart`
  - `one BestCard entry per unlocked game, in registry order; locked games are hidden`.
  - `bar heights are value / max × 149, so no bar can exceed the band` — the fixed `/ 10.5` divisor
    from `app.html` clips above ~1560 and is a documented DERIVED change.
  - `an empty history yields the empty state, not a zero-height chart` — empty, filtered-empty and
    error are three states (`ui-states-and-feedback` rule 3).
- `test/features/stats/stats_screen_test.dart`
  - `"Stats" is the only Semantics(header: true)`.
  - `the chart is ExcludeSemantics with a sibling Semantics that speaks the seven values`.
  - `the axis is true zero` — assert the painter's baseline y equals the band's bottom.
  - `the body scrolls at textScaler 2.0 without overflow`.
- `test/features/settings/settings_screen_state_test.dart`
  - `state comes from settingsRepositoryProvider.watch()` and each setter writes through the
    repository — persist-before-publish, asserted by ordering the fake's `writeCalls` before the
    stream emission. Driven through **E04's `appSettingsProvider`**, not a new notifier.
  - `reduce motion is OR-ed with the platform flag` — with the platform flag true and the setting
    false, the effective value is true; asserted below E04's `MotionPreferenceScope`, and the test
    also asserts the scope appears exactly once in the tree.
- `test/features/settings/settings_screen_test.dart`
  - `the whole 62pt row is the tap target, not the 66×34 toggle` — `getSize` on the row ≥48 and the
    toggle renders with `onTap: null`.
  - `the toggle prints ON/OFF inside its track` — state survives greyscale
    (`accessibility-as-code` rule 6).
  - `the colour-blind row shows a four-swatch preview of the palette it swaps IN`.
  - `flipping reduce motion updates the root MediaQuery within the same pump` — assert
    `MediaQuery.disableAnimationsOf` on a descendant.
  - `no game-specific row exists` — `find.textContaining('Stroop')` is empty; per-game options belong
    on game detail.
- Goldens: `stats_390.png`, `settings_390.png`.

**Implementation.** `lib/features/stats/{application/stats_notifier.dart,
presentation/stats_screen.dart,presentation/widgets/run_bar_chart.dart}` — `StatsNotifier` reads E05's
`allBestsProvider`, `runStatsProvider(RunScope.of(id, null))` and `chartSeriesProvider`; there is no
`StatsRepository` to read from. The chart is a View/Painter/Scene trio with `shouldRepaint` as one value
compare and zero allocation in `paint()`.
`lib/features/settings/{presentation/settings_screen.dart,presentation/widgets/settings_row.dart,
presentation/widgets/colour_blind_preview.dart}` — the screen's four rows write through the
**existing** `appSettingsProvider` (E04's `AppSettingsNotifier`, re-pointed at
`settingsRepositoryProvider.watch()` by E05 T05.4), calling `setSoundEnabled` /
`setHapticsEnabled` / `setReduceMotion` / `setColourBlindPalette`. **There is no second
`SettingsNotifier`**: E04 built the notifier, E05 gave it durability, and this task builds the screen
over it. A third `StreamNotifier<AppSettings>` would be a third place the four toggles live.

**The reduce-motion fold is E04's and stays where E04 mounted it** — `MotionPreferenceScope`, once, in
`lib/app.dart`, above `MaterialApp`. This task adds **nothing** in `MaterialApp.router(builder:)`: a
second fold would OR the same flag twice, pass every test, and be obviously wrong to read. Because E04
already read `appSettingsProvider`, there is not even a provider to re-point — check `lib/app.dart`
before writing and confirm the scope is there.

**Files.** `lib/features/stats/**`, `lib/features/settings/**`, `lib/app.dart`,
`test/features/stats/**`, `test/features/settings/**`.

**Skills.** `sunburst-shell-screens`, `custom-canvas-and-gestures`, `state-management-riverpod`,
`ui-states-and-feedback`, `accessibility-as-code`, `sunburst-components`,
`widget-golden-and-a11y-testing`, `i18n-rtl-l10n`.

**Screenshot check.** `07-stats.png`: turquoise header with **dots only, no rays**, `pad 10/20/18`;
`BestCard` at accent fill r-lg e2 `pad 13/15` with a cream value chip at r 14 on a 2px shadow; the
`StatBox` duo at gap 12; the chart card at paper r-lg e2 `pad 14/15/12` with a 164pt band, striped
accent/accentDeep bars at r 8/8/3/3 on 2px shadows, the best bar in sunshine stripes, and a 3px ink
axis that *is* true zero. `08-settings.png`: grape header with rays at **.3**; groups at paper r-lg e2
with rows split by 3px **ink** (never cream-3); 36pt icon chips at cream-2, 2px, r 11; `PopToggle`
66×34; the footer wordmark and tagline in ink-2 at `pad 14/10/20`.

**Done when.**
- [ ] `flutter test test/features/stats test/features/settings` green, both goldens committed.
- [ ] A toggle flip survives an app restart against the real repository (manual check on device).
- [ ] `check_painter_hygiene.sh lib` and `check_raw_values.sh lib` green.
- [ ] Compared against `07-stats.png` and `08-settings.png`.

**Commits.**
1. `Add StatsNotifier with the true-zero bar scale`
2. `Add StatsScreen with the run bar chart painter`
3. `Add SettingsScreen writing through the existing appSettingsProvider`
4. `Add stats and settings goldens`

---

### T07.10 — Cross-screen matrices and the gate sweep

**Goal.** Prove the eight screens as a set: no overflow across the width and text-scale band, one
header and correct entry focus everywhere, and every gate script green.

**Tests first (TDD).** This task is tests only; any production change it forces is a defect fix in the
screen that failed, committed with the test that caught it.
- `test/layout/shell_overflow_matrix_test.dart` — one `testWidgets` per
  (screen, device, scale) tuple over the eight routes × `Device.all` (320/360/390/430) ×
  `[1.0, 1.3, 2.0]`; never a loop inside a test, because overflow reports once per `RenderObject`.
  Each asserts `tester.takeException()` is null **and** a fit assertion: the HUD pills, the results
  trio cells and the settings row labels each sit inside their computed cell via `getRect`. A bold
  pass at `Device.reference390` × `[1.0, 2.0]` follows `setUpAll(loadAppFonts)` — the bold axis is
  inert under Ahem.
- `test/a11y/shell_a11y_test.dart`
  - per screen: `exactly one Semantics(header: true)` with the copy from
    `references/screen-anatomy.md` — Home "Ready to train?", detail = the hero title, countdown "Get
    ready", pause "Leave the run?", results "Nice run!", stats "Stats", settings "Settings"; the play
    scaffold has **none**.
  - per screen: `focus on entry lands on the header` (the play scaffold's lands on the board's first
    target).
  - per screen: `traversal order matches the visual order` via `simulatedAccessibilityTraversal`.
  - `every tap target is ≥48px` — an explicit `getSize` loop, not `meetsGuideline` (which skips nodes
    flush with the view edge).
  - `every glyph is labelled or excluded` — no unlabelled `SunburstGlyph` in any screen's tree.
- `test/a11y/shell_contrast_test.dart` — pure-Dart WCAG over the composited pairs these screens
  introduce: greeting on sunshine, hero kicker on each accent, HUD `alarm` both lines on `danger`,
  results trio labels on turquoise and coral, settings header cream on grape at ray .3.
- `test/golden/shell_screens_golden_test.dart` — `@Tags(['golden'])`, collects the eight goldens
  produced in T07.5–T07.9 into one lane so CI runs them together and never with `--update-goldens`.

**Implementation.** No new production code is planned. Fix whatever the matrix reds — expected
suspects: the HUD row above 1.3, the results trio at 320, the settings two-line colour-blind label at
2.0, and the stats chart labels at 430.

**Files.** `test/layout/shell_overflow_matrix_test.dart`, `test/a11y/shell_a11y_test.dart`,
`test/a11y/shell_contrast_test.dart`, `test/golden/shell_screens_golden_test.dart`, plus fixes.

**Skills.** `widget-golden-and-a11y-testing`, `accessibility-as-code`, `adaptive-layout`,
`testing-strategy`, `sunburst-shell-screens`.

**Screenshot check.** Re-run the five-step comparison on all eight PNGs after the matrix fixes — a
layout change made to green 320pt is exactly the change that can break 390pt, and 390pt is the
reference.

**Done when.**
- [ ] `flutter test` green with no `takeException()` suppression, no `ignoreOverflowErrors`, no
      `FlutterError.onError` assignment anywhere under `test/`.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` green.
- [ ] `.claude/skills/testing-strategy/scripts/check_test_hygiene.sh` green.
- [ ] Every gate in the section below green.
- [ ] Suite wall time recorded in the PR body against the `testing-strategy` budget.

**Commits.**
1. `Add the shell overflow and fit matrix across four widths and three text scales`
2. `Add per-screen header, focus and traversal tests`
3. `Add pure-Dart contrast tests for the composited shell pairs`
4. `Fix the layout defects the matrix found`

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test

# the epic's named gate
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib

# design gates
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart

# structure, routing, state, tests
.claude/skills/navigation-and-routing/scripts/check_routing.sh            lib
.claude/skills/flutter-architecture/scripts/check_architecture.sh         lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh  lib
.claude/skills/widget-composition/scripts/check-widget-composition.sh     lib
.claude/skills/custom-canvas-and-gestures/scripts/check_painter_hygiene.sh lib
.claude/skills/error-handling-typed-results/scripts/check-swallowed-catch.sh lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                   lib

# verify_feature.sh takes ONE feature directory, not the repo root — run it per feature
for f in home game_detail play results stats settings shell; do
  .claude/skills/scaffold-feature-module/scripts/verify_feature.sh "lib/features/$f"
done
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh            lib test
.claude/skills/adaptive-layout/scripts/check_adaptive.sh                  lib
.claude/skills/dart3-idioms-and-coding-standards/scripts/check-dart3-idioms.sh lib
```

And the authoritative sweep, which also carries the `verify_feature.sh` rows this epic makes runnable:

```bash
bash tool/skill_gates.sh
```

E01 T01.8 put `verify_feature.sh` in the runner's **skip** table with the reason "takes one feature
directory; run per feature by E07/E08/E09". This epic creates the first `lib/features/<name>/`
directories, so **move it to the run table in this PR**, iterating the seven feature folders —
`test/policy/skill_gates_coverage_test.dart` asserts every script appears exactly once, which is what
makes the move deliberate rather than forgotten.

`check_arb_parity.sh` stays skipped: it needs a sibling `app_*.arb` and MindForge ships one locale
(E01 T01.10, ADR 0001). Verified — it exits 2 on a template-only directory. The gate that is meaningful
here is `nullable-getter: false`, which turns a missing key into a compile error.

Plus the manual gate that no script covers: each of the eight screens placed beside its PNG in
`design/sunburst-pop/screens/` at 390×844 and walked through structure → spacing rhythm → surface
construction → type role → sampled hex.

## Risks and open questions

1. **Screenshot comparison is manual and this epic has eight of them.** No CI job can run it. Mitigation:
   every screen task carries an explicit comparison step naming its PNG and the regions to check, and
   the PR body must list which screens were compared and what was found. A screen merged without that
   line is a review reject.
2. **The placeholder registry could outlive its purpose.** `lib/games/placeholder/` exists only so the
   shell is runnable and comparable before E08. Decision: its files carry
   `// DELETE IN E08 — see epics/E08-stroop-rush.md` in the first line, and E08's first commit removes
   the directory and the four ARB key groups. If E08 ships without removing it, that is a review reject
   on E08.
3. **How a shell screen gets a game's localized title.** `GameDefinition` deliberately has no title
   field, and gen-l10n has no dynamic key lookup. Decision: `lib/l10n/game_strings.dart` holds
   `gameStringsProvider`, a `Map<GameId, GameStrings>` assembled from `AppLocalizations` getters. It is
   the second and last file allowed to name every game; it lives outside `lib/features/**` so
   `check_shell_boundaries.sh` still passes, and E08/E09 each append one entry. If a reviewer prefers
   the map on `GameDefinition` as a `Localized Function(AppLocalizations)` field, that is a
   `sunburst-shell-screens` change, not a screen change — raise it before T07.5.
4. **A cold-start deep link into a live run cannot be reconstructed.** `/game/:id/play?difficulty=&seed=`
   names the config, but the `RunNotifier` for it does not exist after process death. Decision: the pure
   `appRedirect` sends any run route whose phase snapshot is `idle` back to `/game/:id`. Tested in
   T07.4; no `state.extra` anywhere.
5. **The HUD reflow threshold is DERIVED.** `app.html` has one text scale, so "above `textScaler` 1.3
   the HUD becomes a `Wrap` 2+1" comes from `sunburst-shell-screens`, not from the mock. Comment it as
   DERIVED at the point of use and let the matrix in T07.10 be the evidence.
6. **The stats bar divisor differs from the mock on purpose.** `app.html` hard-codes `value / 10.5`,
   which clips any score above ~1560. Ship `value / max × 149` and mark it DERIVED. If a reviewer wants
   the mock to match the code, that is an `app.html` edit plus `capture-screens.sh` plus a committed
   PNG — not a silent divergence.
7. **Suite time.** Eight screens × four widths × three scales plus a bold pass plus eight goldens is
   the largest test surface in the project. If `flutter test` exceeds the `testing-strategy` budget,
   trim the **bold** pass to the reference device first, and never the width band — width is where the
   real defects live.
8. **E04's reduce-motion fold already exists and this epic must not add a second.** E04 T04.4 mounted
   `MotionPreferenceScope` once in `lib/app.dart` over `appSettingsProvider`, and E05 T05.4 gave that
   provider durability. T07.9 therefore builds the Settings *screen* only — no second fold in
   `MaterialApp.router(builder:)`, no second `SettingsNotifier`. Two folds would OR twice and pass every
   test while being obviously wrong to read. Check `lib/app.dart` before writing.
10. **The placeholder registry's ARB keys are E08's to delete too.** E08 T08.0 removes
   `lib/games/placeholder/**`, the three registry entries, the twelve placeholder ARB keys and
   `test/games/placeholder_registry_test.dart`, and updates this epic's `home_screen_test.dart`
   fake-registry expectations. That is E08's first commit; if E08 ships without it, three placeholder
   cards remain on Home and it is a review reject on E08.
9. **`Difficulty` lock flags.** `references/screen-anatomy.md` says "`Difficulty` carries its own lock
   flag", but nothing in E06's scope commits to it. If the type lands without one, the game detail
   screen renders all difficulties unlocked and the locked-difficulty test is deleted with a one-line
   note — do not add the field from inside a shell screen.

## Definition of done

- [ ] Branch `epic/07-shell-screens` cut from `main`, granular commits, tests committed with the code
      they cover.
- [ ] The six shell type steps shipped in `lib/theme/` (T07.0) before any screen asserted against them;
      the scale is eighteen steps and the count test still derives from the source file.
- [ ] Eight screens under `lib/features/**`, nine composites in `lib/features/shell/widgets/`, one
      `GoRouter` in `lib/routing/`, Settings writing through E04's `appSettingsProvider` over E05's
      `SettingsRepository` — one notifier, one fold, one mounting point.
- [ ] No `StatsRepository` was created; Home and Stats read E05's derived providers, and Home's BEST
      pills come from `allBestsProvider`.
- [ ] Every affordance navigates — including the Daily Mix card. No dead chevron ships.
- [ ] Each of the eight screens compared against its PNG in `design/sunburst-pop/screens/` at 390×844
      through the five-step order; deltas fixed, or committed as an `app.html` change plus a re-run of
      `capture-screens.sh` plus the regenerated PNGs.
- [ ] The play scaffold compared against **both** `04-stroop-rush.png` and `05-schulte-grid.png`, with
      the chrome identical between them; board interiors explicitly deferred to E08/E09.
- [ ] Widget test per screen over the fake registry and fake repositories; golden per screen at
      390×844; overflow + fit matrix at 320/360/390/430 × 1.0/1.3/2.0; a11y test per screen for the one
      `Semantics(header: true)` and entry focus; routing test for every deep link and all four
      `PopScope` rows; the run-over announcement asserted at exactly one.
- [ ] `check_shell_boundaries.sh lib` green, and every other gate in the section above green.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] PR opened with a body stating what changed, why, how it was verified, **which screens were
      compared**, and what was deliberately left out (board interiors, the placeholder registry's
      removal in E08).
- [ ] CI green on the pipeline E01 created.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
