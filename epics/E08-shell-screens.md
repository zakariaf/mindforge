# E08 · Shell screens

| | |
|---|---|
| **Branch** | `epic/08-shell-screens` |
| **Depends on** | E05, E06, E07 |
| **Unblocks** | E09, E10, E11 |
| **Status** | Not started |

## The epic

Build the whole product except the board rectangle, in four locales, two of them right-to-left. Eight
screens under `lib/features/**` — Home, Game detail, Countdown, Play scaffold, Pause sheet, Results,
Stats, Settings — plus the nine shell-owned composites in `lib/features/shell/widgets/` (`RayHeader`,
`HalftoneDots`, `PlayBand`, `GameHeroPanel`, `DailyMixCard`, `StatBox`, `ScoreSlab`, `BestCard`,
`Wordmark`), one `GoRouter` in `lib/routing/` whose three-branch `StatefulShellRoute.indexedStack`
owns the 90pt `PopBottomNav`, and the Settings screen wired to the real `SettingsRepository` from E02
— including the **Language row**, which drives E04's `localeProvider` and is the first control in the
app that changes the direction of every other screen.

Every game-specific fact on these screens is data read off `gameRegistryProvider` — card, BEST pill,
locked slot, difficulty list, score formatting, accent, board background. No shell file names a game.
To make that claim testable and the screens screenshot-comparable before Stroop Rush exists, this epic
ships `lib/games/placeholder/` — two unlocked placeholder definitions and one locked slot, obeying
every rule in `references/shell-game-boundary.md` — which E09 deletes in its first commit.

Every screen is signed off against **two** references: its LTR PNG in
`design/sunburst-pop/screens/NN-*.png` and its Persian RTL counterpart in
`design/sunburst-pop/screens/rtl/NN-*.png`, both rendered by E04, both compared on the canonical
simulator `MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6) — the only
simulator on this machine that is exactly 390×844 logical points.

**iOS is the only target.** Android is deferred: nothing in this epic is built, run or verified on
it, and no task claims parity.

## Why we need it

MindForge is an engine. The engine is exactly this: the eight screens, the run lifecycle wired to
them, and the seam a game plugs into. Without E08 there is no route to anything, no `GameHud`, no
`_BoardPane`, no results hand-off — E09 and E10 would each have to invent a screen, and the second one
would inherit a copy of the first instead of the shell. That fork is the failure mode the whole
architecture exists to prevent.

It is also the epic where the design direction either ships or quietly becomes generic Material.
Sixteen rendered PNGs are the acceptance criteria; nothing else in the project has that much visual
surface, and nothing else can drift as far without a compile error.

And it is where localization stops being infrastructure and becomes product. E04 built the machinery
— four ARBs, the `ckb` delegate, the Arabic-script font cascade, the per-locale `NumberFormat`, the
bidi helper, the RTL reference screenshots. Every one of those is unproven until eight real screens
render through it in `de`, `fa` and `ckb`. The German expansion, the mirrored nav, the Eastern Arabic
digits in a HUD pill that ticks every frame: those defects only exist on a built screen.

## Current state

Verified by `ls` on 2026-08-19, at 4 commits on `main`:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `.github/`. Everything below is
  inherited from E01–E07 at branch time, not present today.
- `.claude/skills/` — 45 skills. `sunburst-shell-screens/` carries the three references this epic is
  built from (`screen-anatomy.md`, `shell-game-boundary.md`, `run-lifecycle.md`), a copyable
  `templates/screen_template.dart`, two worked examples (`examples/home_screen.dart`,
  `examples/play_scaffold.dart`) and `scripts/check_shell_boundaries.sh`. `i18n-rtl-l10n/` carries
  `references/rtl-and-bidi.md`, `references/numerals-and-calendars.md`, `references/arb-and-icu.md`
  and the two gate scripts this epic runs, `scripts/check_i18n_bans.sh` and
  `scripts/check_arb_parity.sh`.
- `design/sunburst-pop/system.html` — token values. `design/sunburst-pop/app.html` — layout and
  spacing rhythm for all eight screens. `design/sunburst-pop/screens/01-home.png` …
  `08-settings.png` — the eight rendered LTR targets at 390×844 @2× (780×1688 px).
  `screens/README.md` — the comparison procedure. `capture-screens.sh` — regenerates them.
- There is **no** pause-sheet PNG in either set. It is a state of screen 4, built from the wireframe
  in `references/screen-anatomy.md` §5 and the `PopSheet` entry in `sunburst-components`.

### Toolchain (verified on this machine — do not re-derive)

| | |
|---|---|
| Flutter | 3.44.6 stable · Dart 3.12.2 · DevTools 2.57.0 |
| Xcode | 26.6 (17F113) · CocoaPods 1.15.2 |
| Simulator runtimes | iOS 18.0, 18.6, 26.5 |
| **Canonical device** | `MindForge iPhone 14` · `C13DDC02-375D-4E1B-8F81-44EB407D09A4` · iOS 18.6 · **390×844** |

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
xcrun simctl io C13DDC02-375D-4E1B-8F81-44EB407D09A4 screenshot /tmp/home-en.png   # 780x1688
```

No iPhone 16-class simulator matches the references (iPhone 16 is 393×852, 16 Pro is 402×874). A
screenshot taken on one of those is not a comparison; it is a different layout that happens to look
similar. Every screenshot check in this epic names this UDID.

### Expected from earlier epics when this branch opens

A missing symbol is a gap in that epic, not something to re-declare here.

| From | Symbols this epic consumes |
|---|---|
| E01 | `l10n.yaml` (`arb-dir: lib/l10n`, `template-arb-file: app_en.arb`, `nullable-getter: false`), `tool/skill_gates.sh`, the iOS runner with `CFBundleLocalizations = [en, de, fa, ckb]` and `CFBundleDevelopmentRegion = en` |
| E02 | `SupportedLocale`, `AppSettings` (four booleans + `SupportedLocale? localeOverride`), `HudTone`, `SettingsRepository` + `settingsRepositoryProvider` (incl. the persisted locale override, and **the single write path — there is no `AppSettingsNotifier`**), `RunRepository` + `runRepositoryProvider`, `RunCommit`, and the derived reads in `lib/data/data_providers.dart`: `settingsProvider`, `allBestsProvider`, `personalBestProvider(RunScope)`, `runStatsProvider(RunScope)`, `chartSeriesProvider(RunScope)`, `streakProvider`. **There is no `StatsRepository`** — every number these screens render is a fold over the one `runs` table, and `RunRepository` is that table's single source of truth (E02 T02.7). |
| E03 | `SunburstColors` / `SunburstShape` / `SunburstMotion` / `SunburstType` with asserting `of(context)`, `buildSunburstTheme()` (already wired into `lib/app.dart`), `GameAccent` in `lib/theme/game_accent.dart`, `SunburstScript` / `scriptOf` / `forScript` / `arabicLineFactor`, **all four bundled faces** (Fredoka + Nunito from E01, Vazirmatn + the selected display face from T03.7) with their OFL texts registered through `registerSunburstFontLicences()`, and the test support: **`test/support/harness.dart` (`Device`, `Device.all` at DPR 2, `useDevice`, `pumpApp`)**, `test/support/load_app_fonts.dart` and `dart_test.yaml`'s `golden` tag |
| E04 | `AppLocalizations` over `app_en.arb` / `app_de.arb` / `app_fa.arb` / `app_ckb.arb`; `lib/l10n/supported_locales.dart`'s `supportedLocales`, derived from E02's `SupportedLocale`; the `ckb` `LocalizationsDelegate` pair that serves our ARB strings while delegating Material/Cupertino to the nearest supported script neighbour; `localeProvider` (a manual `Notifier<Locale>` derived from `settingsProvider`, persisted through E02's `SettingsRepository`) and `appLocalizationsProvider`; `LocaleNumbers` (`of(context)` / `forLocale(locale)` / `localeNumbersProvider`) with the numbering system pinned per locale; `AsciiNumerals.normalize`; the FSI/PDI helpers `Bidi.isolate` / `Bidi.isolateLtr` / `Bidi.isolateRtl`; and **`design/sunburst-pop/screens/rtl/01-home.png` … `08-settings.png`**, the Persian RTL references produced by the extended `capture-screens.sh` |
| E05 | `PopSurface`, `PopElevation`, `PopButton`, `PopIconButton`, `PopChip`, `PopCard`, `GameCard`, `DifficultySegmented`, `HudPill`, `TimerRing`, `PopProgressBar`, **`PopGridTile`** (not `GridTile` — Material already exports that name; E05 Risk 2), `PopToggle`, `PopBadge`, `PopSheet`, `PopBottomNav`, `SunburstGlyph`, and the test support it owns: `test/support/component_harness.dart` (`pumpPopComponent`, taking a `LocaleCase` and delegating to `pumpLocalized`), `test/support/fake_feedback_service.dart` |
| E06 | `PressPhysics`, `FeedbackService`, `HapticGateway`, `Moment`, `MotionPreferenceScope` (mounted in `lib/app.dart`, reading E02's `settingsProvider`), `SunburstMotion.resolve` |
| E07 | `GameDefinition` (incl. `runLimitFor`), `GameId`, `Difficulty`, `RunScope.of`, `BoardBackground`, `BoardSnapshot`, `GameHud`, `HudSlot`, `RunConfig`, `RunPhase`, `RunState`, `RunOutcome`, `RunNotifier` + `runNotifierProvider`, `gameRegistryProvider`, `gameDefinitionProvider`, `clockProvider`, `ScoreFormatter` + `scoreFormatterProvider` (locale-aware: it is handed E04's `NumberFormat`, and the shell never formats a number itself) |

`test/support/load_app_fonts.dart` must register **all four** faces — Fredoka, Nunito, Vazirmatn and
the selected Arabic-script display face. **E03 T03.7 created it**, beside the faces themselves; this
epic imports it and does not fork it. If it registers only the Latin pair, the `fa`/`ckb` goldens
render tofu and that is an E03 gap, fixed there.

## What we will achieve

Boot `MindForge iPhone 14`, `flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`, and you can: land
on Home, see three game cards (two placeholder games, one locked "Coming soon" slot) plus the Daily
Mix card and a 4-day-streak chip; tap a card into Game detail; pick a difficulty; tap Play and watch a
full-bleed grape 3-2-1 countdown; land on the play scaffold with a live Time pill, a progress track
and a stub board; tap pause and get the sheet; tap "Leave run" and land on Results; tap Home and be
back; switch to Stats and Settings on the bottom nav and come back to Home with its scroll position
intact; flip every Settings toggle and see the value survive a cold restart. Then open the Language
row, tap **فارسی**, and watch every one of those screens flip to right-to-left with Eastern Arabic
numerals, in place, without a restart and without losing the run you left mid-flight.

Concretely, at the end of this epic:

- Eight screens exist under `lib/features/**` and each has been placed side by side with **both** its
  LTR PNG and its RTL PNG at 390×844 on the canonical simulator, and signed off through the five-step
  order.
- `check_shell_boundaries.sh lib` is green: no game navigates, builds a `Scaffold`/`AppBar`/`SafeArea`
  or draws shell chrome, and no file under `lib/features/**` names a specific game.
- `check_i18n_bans.sh lib` and `check_arb_parity.sh lib/l10n` are green. Every user-facing string on
  eight screens comes from `AppLocalizations`; every number comes from `ScoreFormatter` or
  `LocaleNumbers.of(locale)`; every inset, alignment, radius and text alignment is directional.
- `flutter test` runs one widget test per screen over a fake registry and fake repositories, **four
  goldens per screen** (en/de/fa/ckb) at 390×844, an overflow matrix at locale × text scale
  (1.0/1.3/2.0) × width (320/360/390/430), an a11y test per screen per locale for the single
  `Semantics(header: true)` and entry focus, a routing test covering every deep link and the four
  `PopScope` rows, and a test that the run-over announcement fires exactly once **in each locale**.
- Switching locale from the Settings row does not restart the app, does not rebuild the `GoRouter`,
  does not reset branch scroll state and does not disturb a live `RunNotifier`.
- `grep -rn "switch (gameId)\|switch (config.gameId)" lib/features/` returns nothing.
- `lib/games/placeholder/` is the only game code in the tree and is marked for deletion by E09.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `sunburst-shell-screens` | Owns this epic. The eight wireframes with exact padding (`references/screen-anatomy.md`), the `GameDefinition`/`BoardSnapshot` seam (`references/shell-game-boundary.md`), the `RunPhase` table and announcement rules (`references/run-lifecycle.md`), and `scripts/check_shell_boundaries.sh` — the epic's named gate. |
| `i18n-rtl-l10n` | The second owner. Rule 5's directional-only geometry is what makes the RTL sweep a comparison instead of a rewrite; rule 7's normalize-before-parse guards the one place the shell reads a number back; the numerals section pins `fa`/`ckb` to the `fa` symbol data; `references/rtl-and-bidi.md` supplies the mirror/never-mirror table for the chevrons and the manual-flip recipe; `scripts/check_i18n_bans.sh` and `scripts/check_arb_parity.sh` are gates in this epic's run table. |
| `sunburst-components` | Every screen is composed from its thirteen classes plus `PopIconButton`/`PopChip`; the nine shell composites must compose `PopSurface` and add no new visual vocabulary. Also fixes `PopElevation` and the ≥48px target rule. |
| `sunburst-tokens` | Gutter 20, `cardGap` 16, `e1…e4`, every hex and every type step. Rule 11 of the shell skill forbids `copyWith(fontSize:)`, so the six missing type steps (`titleBar`, `greeting`, `sectionLabel`, `heroTitle`, `countdownNumeral`, `statValue`) are **T08.0's deliverable**, added by `references/adding-a-token.md`'s four-places-plus-the-const-instance procedure before any screen asserts against them — each carrying E04's per-locale fallback cascade. |
| `sunburst-motion-and-haptics` | Names the moments these screens fire: `countdownBeat`, `runStart`, `runEnd`, `resultsReveal`, `personalBest`, `sheetTransition`, `routeTransition`, `toggleFlip`, `homeCardEnter`, `timerAlarm`. The shell decides *when*; this skill fixes the numbers and the reduce-motion residue. |
| `navigation-and-routing` | One `GoRouter` in `lib/routing/`, `StatefulShellRoute.indexedStack` for the three branches, identity in path params never `state.extra`, pure `redirect`, `errorBuilder`, `PopScope` mechanics, `CustomTransitionPage` under reduced motion — and the rule that the router is built once and is not a function of the locale. |
| `state-management-riverpod` | One `Notifier` per screen over an immutable ready-to-render state, `ref.watch`/`ref.read`/`ref.listen` split, `family` + `autoDispose` keying, providers-as-DI with throwing seams the tests override. The Language row writes through E04's `localeProvider`, not a new notifier. |
| `scaffold-feature-module` | The fixed folder shape each of the six feature folders must take (`presentation/`, `application/`, `domain/`, `<feature>_providers.dart`), the no-cross-feature-import rule, and `scripts/verify_feature.sh`. |
| `widget-composition` | Named `const` widget classes never `Widget _buildX()`, `build()` ≤ 80 lines and ≤ 5 levels of nesting, lazy lists, directional insets, computed cell sizing for the results stat trio and the stats chart. |
| `accessibility-as-code` | One `Semantics(header: true)` per screen, a label on every glyph or `ExcludeSemantics`, no `FittedBox`/`ellipsis`/clamped `textScaler`, ≥48px targets, `OrdinalSortKey` traversal, `boldText` honoured — and the same in a locale whose labels are 30% longer. |
| `widget-golden-and-a11y-testing` | The harness contract (`useDevice` before `pumpApp`, physical-pixel sizing, MediaQuery above `MaterialApp`), one `testWidgets` per matrix tuple, the fit assertion, `isSemantics`, the two golden lanes, RTL goldens on **real** fonts (Ahem exercises neither Persian digits nor Arabic shaping), and `scripts/check-test-hygiene.sh`. |
| `testing-strategy` | Bare-`implements` fakes over mocktail for the repositories, `ProviderContainer.test` for notifier-only assertions, seeded determinism, the suite-time budget this epic can blow — and it is now four times the size. |
| `ui-states-and-feedback` | Stats and Home render off streams that can be empty or failed: one switch over `AsyncValue`, three distinct empty/filtered/error screens, never `e.toString()`, retry via `ref.invalidate`. |
| `custom-canvas-and-gestures` | `HalftoneDots` and the stats bar chart are painters: dumb painter + immutable scene, `shouldRepaint` as one value compare, zero allocation in `paint()`, `ExcludeSemantics` plus a sibling `Semantics` that speaks the values — and a painter is fed the same `NumberFormat` as the chrome, never auto-mirrored. |
| `adaptive-layout` | The 320–430 width band and the `MediaQuery.sizeOf`/`paddingOf` aspect reads; the HUD reflow and the scrolling results/stats bodies are constraint-driven, never device checks — and never locale checks either. |
| `async-safety` | `ref.listen` callbacks that route, `PauseSheet.show` awaited results, `ref.mounted` after every await before touching a `BuildContext`, and disposing every `FocusNode` the screens create. |
| `seeded-determinism-and-golden-vectors` | The Daily Mix pick is derived from a `CalendarDay` key: it must be identical in all four locales, because localisation happens at render and never inside a generator. |
| `naming-conventions` | `*Screen` / `*Notifier` / `*Repository` suffixes, file name = primary declaration, `lowercase_with_underscores` paths — the shell boundary gate greps on these names. |
| `dartdoc-conventions` | Nine composites and eight screens are public API; `public_member_api_docs` is an analyzer error, so every one needs a `///` summary that says what it is for. |

## Tasks

### T08.0 — The six shell type steps, in four scripts

**Goal.** Add the type steps the eight screens render with, before any screen test asserts against
them — so no screen reaches for `copyWith(fontSize:)`, no task is blocked on a token that does not
exist, and no step ships a Latin-only typographic device that breaks Arabic script.

**Why it is a task and not a footnote.** T08.3 asserts `type.statValue` and T08.6 asserts
`type.countdownNumeral`. Neither exists after E03 (ten steps) or E05 (twelve). A shell screen that
adds a step inline fails `check_raw_values.sh`; one that uses `copyWith(fontSize:)` fails
`sunburst-shell-screens` rule 11. The steps are tokens, and tokens land in `lib/theme/` — with the
per-locale `fontFamilyFallback` cascade E04 attached to every other step.

**Tests first (TDD).** In `test/theme/sunburst_type_test.dart`, extending the specs E03 and E05 wrote:
- one expectation per new step asserting family, weight, `fontSize`, `height` and `letterSpacing`
  against its `app.html` evidence: `titleBar` (the play/detail top-bar title), `greeting` (Nunito 800
  at 14, screen 01), `sectionLabel` (10 upper with .15em tracking — screens 01, 02, 06, 07),
  `heroTitle` (screen 02's hero), `countdownNumeral` (132, screen 03), `statValue` (the stat-box and
  results-trio value, tabular);
- `'every new step carries the same fontFamilyFallback cascade as displayXl'` — for each of the six,
  `step.fontFamilyFallback` equals `type.displayXl.fontFamilyFallback` (display steps) or
  `type.body.fontFamilyFallback` (body steps). A step that omits the cascade renders tofu in `fa` and
  `ckb`, and it renders it only in a golden nobody looks at twice;
- `'sectionLabel drops its tracking under Arabic script'` — resolved for `fa` and `ckb`,
  `sectionLabel.letterSpacing == 0`. Positive tracking on a cursive script breaks the joins; .15em on
  `کۆ` is not a style choice, it is broken text. The resolution lives in `SunburstType`, keyed on the
  locale's script, so no screen conditionalises;
- `'no shell string is cased in Dart'` — the uppercase in `sectionLabel` is authored into the ARB
  value for `en` and `de` and absent from `fa`/`ckb` (neither script has case). Gate:
  `grep -rn 'toUpperCase()\|toLowerCase()' lib/features/ lib/ui/` is empty;
- `'countdownNumeral and statValue carry tabular figures'` — a digit change must not reflow. Asserted
  in all four locales through a `TextPainter`: the laid-out width of `111`/`888` is equal, and so is
  the width of `۱۱۱`/`۸۸۸`. If the Arabic-script face has no `tnum`, this test is what discovers it
  (see Risk 5);
- `'copyWith replaces each new step independently'` and `'lerp interpolates every new step'`, the same
  coverage trio E05 T05.1 used;
- the step-name list literal in E03 T03.8's count test gains all six, taking the scale from twelve to
  **eighteen**. The count still derives from `DesignSource.dartFieldNames(typeFile, 'SunburstType')`;
  only the named literal is edited, in this commit, with each addition's evidence beside it.

**Implementation.** Add the six steps to `lib/theme/sunburst_type.dart` by
`sunburst-tokens/references/adding-a-token.md`: field, constructor, `copyWith`, `lerp`, the
`const sunburstPop` instance — plus the test literal, which is the place that gets forgotten. Route
each through E04's per-locale resolution so the cascade and the script-dependent tracking are applied
in one place. Every step is **DERIVED** from `app.html` and carries a `// DERIVED` comment naming the
rule it was measured from, because `system.html` §04 names ten steps and these are not among them.
Update `sunburst-tokens/references/shape-and-type.md` in the same PR so the skill and the code agree.

**Files.** `lib/theme/sunburst_type.dart`, `test/theme/sunburst_type_test.dart`,
`.claude/skills/sunburst-tokens/references/shape-and-type.md`.

**Skills.** `sunburst-tokens`, `sunburst-shell-screens`, `i18n-rtl-l10n`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the steps are numbers here; their *roles* are compared
screen by screen from T08.5 onward, which is step 4 of the comparison order).

**Done when.**
- [ ] Eighteen steps; the count test derives from the source file and its named literal lists all
      eighteen with evidence.
- [ ] All six carry the Arabic-script fallback; `sectionLabel` has zero tracking under `fa`/`ckb`.
- [ ] `grep -rn 'copyWith(fontSize:\|fontSize:' lib/features/ lib/ui/` is empty, and so is the
      `toUpperCase()` grep.
- [ ] `check_raw_values.sh lib` green.

**Commits.**
1. `test(theme): pin the six shell type steps against app.html in four locales`
2. `feat(theme): add titleBar, greeting, sectionLabel, heroTitle, countdownNumeral and statValue`
3. `feat(theme): drop sectionLabel tracking under Arabic script`

---

### T08.1 — Test harness, fakes, locale matrix and the placeholder game registry

**Goal.** Give every later task a pinned 390×844 harness that takes a locale, fake game definitions,
fake repositories, and a runnable two-game registry so the shell is screenshot-comparable in four
locales before any real game exists.

**Tests first (TDD).**
- `test/support/harness_test.dart`
  - `pins the reference device in physical pixels` — after `useDevice(Device.reference390)`,
    `tester.view.physicalSize == const Size(780, 1688)` and `tester.view.devicePixelRatio == 2.0`.
    **DPR 2, not 3**: that is what `capture-screens.sh` rendered both PNG sets at, and a golden
    blessed at DPR 3 cannot be laid beside a DPR-2 reference. E03 pinned this; this test is the
    tripwire that stops a later epic from quietly changing it.
  - `resets the view between tests` — a second test in the file sees the default surface, proving
    `addTearDown(view.reset)` fires.
  - `layers MediaQuery above MaterialApp` — inside the app, `MediaQuery.sizeOf(context)` is
    `Size(390, 844)` *and* `MediaQuery.textScalerOf(context)` is the value passed. A bare
    `MediaQueryData()` would zero the size; this test is what catches it.
  - `pumpShellApp resolves the requested locale and its direction` — four tests: `en` and `de` give
    `Directionality.of(context) == TextDirection.ltr`, `fa` and `ckb` give `TextDirection.rtl`, and
    `Localizations.localeOf(context).toLanguageTag()` is the requested tag in each.
  - `pumpShellApp('ckb') does not throw` — the sharp one. Pumping the whole app under `ckb` exercises
    E04's custom delegate; a missing `GlobalMaterialLocalizations` entry throws on the first
    Material widget that asks for a tooltip string. `tester.takeException()` is null. If this reds,
    stop: it is an E04 defect, not something a shell screen patches.
- `test/support/fakes_test.dart`
  - `an un-overridden repository seam throws` — reading `runRepositoryProvider` on a bare
    `ProviderContainer` throws `UnimplementedError`.
  - `FakeSettingsRepository.watch emits the seeded value, then each write` — expect a 3-element stream.
  - `FakeRunRepository.watchBestsByGame returns the seeded best per game id` — the all-games fold Home
    reads. There is **no** `FakeStatsRepository`, because there is no `StatsRepository` (E02 T02.7).
  - `FakeRunRepository.saveRun returns Ok(RunCommit(record, isPersonalBest))` — the flag is a field on
    the committed value, seeded per test, not a second read.
  - `FakeSettingsRepository round-trips the locale override` — writing `ckb` then reading emits `ckb`;
    the Language row in T08.9 writes through this same seam.
- `test/games/placeholder_registry_test.dart`
  - `the registry yields two unlocked placeholders and one locked slot, in declaration order`.
  - `a placeholder board builds without a Scaffold` — pump `buildBoard` under a bare
    `Directionality` + `ProviderScope`; `find.byType(Scaffold)` finds nothing and no exception is
    thrown.
  - `the registry is identical in all four locales` — `gameRegistryProvider` read under `en` and under
    `ckb` yields the same ids, accents, score formats and lock flags. A `GameDefinition` is semantic
    data; nothing on it is a string a translator touches.

**Implementation.**
- `test/support/harness.dart` is **E03 T03.1's** file, and it already ships `Device.compact320`,
  `Device.small360`, `Device.reference390`, `Device.large430` and `Device.all`, all at DPR 2. This
  task adds nothing to it and forks nothing from it: `Device.all` is the one matrix name across E05,
  E08, E09 and E10, and a `Device.shellMatrix` beside it would be a second list to keep in step. If
  the file is missing, that is an E03 gap — fix it there.
- `test/support/shell_harness.dart` — `pumpShellApp({overrides, LocaleCase localeCase = LocaleCase.en,
  textScaler, boldText, initialLocation})`, seeding the router's `initialLocation` and overriding
  `localeProvider` with the case's locale. **It takes a `LocaleCase`, not a bare `Locale`, and it
  delegates to E04 T04.10's `pumpLocalized` rather than building its own `ProviderScope` →
  `MaterialApp` chain** — `pumpLocalized` asserts the resolved `Directionality` matches the case's
  declared direction, and a hand-rolled chain would skip that assertion silently. It composes
  `useDevice` from the shared harness rather than re-implementing it, and iterates **`LocaleCase.all`**,
  which is the one locale list in `test/`; it declares no `shellLocales` and no second list. It never
  wraps the tree in a hand-written `Directionality`: direction is a consequence of the resolved locale
  (`i18n-rtl-l10n` rule 4), and a
  hardcoded root would hide every physical-side bug this epic exists to prevent.
- `test/support/fake_game_registry.dart` — `fakeAlphaDefinition` (`GameAccent.stroopCoral`,
  `ScoreFormat.points`, `BoardBackground.surfaceSunk`), `fakeBetaDefinition`
  (`GameAccent.schulteTurquoise`, `ScoreFormat.duration`, `BoardBackground.gameAccent`),
  `fakeLockedDefinition` (`isLocked: true`), and `FakeBoardSnapshotController` for pushing
  `BoardSnapshot`s upward in later tasks.
- `test/support/fake_repositories.dart` — `FakeRunRepository` and `FakeSettingsRepository`, both bare
  `implements` with public seeded fields. No mocktail, and **no `FakeStatsRepository`**.
- `test/support/load_app_fonts.dart` is E03 T03.7's file — created beside the Arabic faces, because
  T03.9's metric measurements are meaningless under Ahem. Import it; do not re-create it. It must
  register Vazirmatn and the display face alongside Fredoka and Nunito — see the Current state note.
- `lib/games/placeholder/placeholder_definitions.dart` and
  `lib/games/placeholder/ui/placeholder_board.dart` — `placeholderCoralDefinition`,
  `placeholderTurquoiseDefinition`, `placeholderLockedDefinition`. The board is a token-only sunken
  rectangle that never sets an outcome. File header: `// DELETE IN E09 — see epics/E09-stroop-rush.md`.
- `lib/games/game_registry.dart` — the placeholder list appended to the empty const list E07 shipped.
  E07's own `'the registry is the only file in lib/ that names a game'` test still holds; its
  emptiness assertion lives in E07's fixture-registry override and is unaffected.
- `lib/l10n/game_strings.dart` — `gameStringsProvider`, a `Map<GameId, GameStrings>` built from
  `AppLocalizations` getters, **and `appLocalizationsProvider`**, a `Provider<AppLocalizations>`
  overridden at the composition root. The second is not optional: E10's `schulteSnapshotProvider`
  needs localized HUD labels and has no `BuildContext`, and shipping `gameStringsProvider` without it
  leaves E10 to invent one. This file is the **second and last** file allowed to name every game — the
  rule is stated here, once, and `game_registry.dart`'s own header claims only that it is the sole
  file that may *enumerate the registry*, so the two do not contradict.
- ARB keys `game_placeholder_coral_title` / `_tagline` / `_kicker` and the turquoise and locked
  equivalents — twelve keys, appended to **all four** files under `lib/l10n/`: `app_en.arb` (the
  template, with `@description` and typed placeholders), `app_de.arb`, `app_fa.arb`, `app_ckb.arb`.
  `check_arb_parity.sh` now runs green in this repo and stays green; a key added to the template
  alone fails it. These twelve strings are the **one group in the app that does not need a native
  review**: they name games that do not exist and E09 deletes them.

**Files.** `test/support/shell_harness.dart`,
`test/support/fake_game_registry.dart`, `test/support/fake_repositories.dart`,
`test/support/harness_test.dart`, `test/support/fakes_test.dart`,
`test/games/placeholder_registry_test.dart`, `lib/games/placeholder/placeholder_definitions.dart`,
`lib/games/placeholder/ui/placeholder_board.dart`, `lib/games/game_registry.dart`,
`lib/l10n/game_strings.dart`, `lib/l10n/app_en.arb`, `lib/l10n/app_de.arb`, `lib/l10n/app_fa.arb`,
`lib/l10n/app_ckb.arb`.

**Skills.** `testing-strategy`, `widget-golden-and-a11y-testing`, `state-management-riverpod`,
`sunburst-shell-screens`, `i18n-rtl-l10n`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter test test/support test/games` green.
- [ ] `pumpShellApp` under `ckb` renders the app with no exception — the E04 delegate is proven from
      this epic's own suite, not assumed.
- [ ] `.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh lib` green with
      `lib/games/placeholder/` present — the placeholder board proves the gate, it does not dodge it.
- [ ] `flutter gen-l10n` regenerates `AppLocalizations` with the twelve new keys in four locales and
      `flutter analyze --fatal-infos` is clean (`nullable-getter: false` makes a missing key a compile
      error).
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh lib/l10n` exits 0.
- [ ] `test/support/harness.dart` is unchanged by this epic;
      `grep -rn 'Device.shellMatrix\|FakeStatsRepository\|lib/l10n/arb/' .` returns nothing.
- [ ] No test file imports `lib/games/placeholder/` — shell tests use the fakes.

**Commits.**
1. `Add fake game registry and fake repositories for shell tests`
2. `Add the locale-aware shell harness and the four-locale matrix constant`
3. `Add placeholder game definitions so the shell is runnable before E09`
4. `Resolve game titles by id through gameStringsProvider and appLocalizationsProvider`

---

### T08.2 — Header and band composites

**Goal.** Ship `RayHeader`, `HalftoneDots`, `PlayBand` and `Wordmark` — the four composites that paint
a coloured region behind a screen's h1 or a HUD — and settle, once and in a test, which parts of the
Sunburst construction mirror under RTL and which do not.

**Tests first (TDD).**
- `test/features/shell/widgets/ray_header_test.dart`
  - `paints its fill and a 3px ink bottom border only` — read the `BoxDecoration`; assert
    `border.bottom.width == shape.borderWidth`, `border.top == BorderSide.none`, colour is
    `colors.border`.
  - `insets its content 6/20/22` — `getRect` of the child versus `getRect` of the header, asserted in
    `en` and in `fa`: the inset is `EdgeInsetsDirectional`, so the *values* are identical and the
    *sides* swap.
  - `starts below the top inset` — pumped under `MediaQuery(padding: EdgeInsets.only(top: 47))`, the
    header's `top` equals 47.
  - `the ray sweep and the dot lattice do not mirror` — the `HalftoneScene` and the ray origin are
    byte-identical under `en` and `fa`. **Decision:** rays and dots are a light source, not a reading
    direction. They stay put, exactly like the hard shadow below.
  - `exposes no semantics of its own` — the ray and dot layers are inside `ExcludeSemantics`.
- `test/features/shell/widgets/halftone_dots_test.dart`
  - `shouldRepaint is false for an equal scene and true when opacity changes` — one value compare over
    `HalftoneScene`.
  - `allocates no Paint inside paint()` — assert the painter's `Paint` fields are `final` and
    identical across two `paint()` calls on a recording canvas.
- `test/features/shell/widgets/play_band_test.dart`
  - `fills with the accent base and carries only a bottom border` for each `GameAccent` case.
  - `lays its children out at gutter 20` in `en` and in `ckb`.
- `test/features/shell/widgets/wordmark_test.dart`
  - `is labelled MindForge and is not a header` — `isSemantics(label: 'MindForge', isHeader: false)`.
  - `pins itself LTR inside an RTL page` — under `fa`, the wordmark's own `Text` carries
    `textDirection: TextDirection.ltr`; inside a localized sentence it is passed through
    `Bidi.isolateLtr` as an ARB placeholder, never spliced. Assert the rendered string of the settings
    footer line contains `U+2066` and `U+2069` around `MindForge` under `fa`, and that no isolate
    character reaches any value written to `FakeSettingsRepository`.
- `test/features/shell/widgets/hard_shadow_direction_test.dart`
  - `the hard offset shadow does not mirror` — a `PopSurface` at e2 has `boxShadow.first.offset ==
    Offset(5, 5)` under `en`, `de`, `fa` **and** `ckb`. This is the assertion a reviewer will look
    for: the shadow is a light-source constant, not a reading-direction property, and an RTL build
    that flipped it to `(-5, 5)` would light the whole app from the wrong side while every RTL
    checklist stayed green.

**Implementation.** `lib/features/shell/widgets/ray_header.dart` (`RayHeader({fill, rayFill,
rayOpacity, dotOpacity, padding, child})`), `halftone_dots.dart` (`HalftoneDots` +
`_HalftoneDotsPainter` + immutable `HalftoneScene`), `play_band.dart` (`PlayBand({accent, child})`),
`wordmark.dart` (`Wordmark`). Each reads `SunburstColors.of` / `SunburstShape.of` / `SunburstType.of`
and constructs no `Color`, `Duration`, `Curve` or `BoxShadow` of its own. Ray geometry is a conic
sweep painted at the declared opacity; the dot lattice is a `HalftoneScene` value. The painters are
**not** auto-mirrored: per `i18n-rtl-l10n`'s CustomPainter section, the decorative subtree is pinned
so ambient RTL cannot flip its geometry, while the chrome around it mirrors through logical insets.

**Files.** `lib/features/shell/widgets/{ray_header,halftone_dots,play_band,wordmark}.dart`,
`test/features/shell/widgets/{ray_header,halftone_dots,play_band,wordmark}_test.dart`,
`test/features/shell/widgets/hard_shadow_direction_test.dart`.

**Skills.** `sunburst-shell-screens`, `sunburst-components`, `sunburst-tokens`, `i18n-rtl-l10n`,
`custom-canvas-and-gestures`, `widget-composition`, `accessibility-as-code`, `dartdoc-conventions`.

**Screenshot check.** Run each composite in a harness page at 390 width and compare the header strip
against four LTR references and their RTL counterparts, in the order structure → spacing rhythm →
surface construction → type role → sampled hex: `01-home.png` / `rtl/01-home.png` (sunshine fill,
rays .5, dots .16, pad 6/20/22), `07-stats.png` / `rtl/07-stats.png` (turquoise, **dots only, no
rays**, pad 10/20/18), `08-settings.png` / `rtl/08-settings.png` (grape, rays at **.3** not .55, pad
10/20/18), and the play band of `04-stroop-rush.png` and `05-schulte-grid.png` plus their RTL twins
(rays .45 + dots .16, 3px ink bottom border). A ray opacity that is uniformly .55 across all three
headers is the defect this check exists to catch; a ray burst that swapped corners between the LTR
and RTL captures is the second.

**Done when.**
- [ ] `flutter test test/features/shell/widgets` green.
- [ ] `check_raw_values.sh lib`, `check_component_hygiene.sh lib` and `check_i18n_bans.sh lib` green.
- [ ] Sampled hexes match `system.html`; no `blurRadius`/`spreadRadius` above 0 anywhere.
- [ ] The shadow-direction test exists and covers all four locales.

**Commits.**
1. `Add HalftoneDots painter with a value-compared scene`
2. `Add RayHeader composite with a non-mirroring ray sweep`
3. `Add PlayBand and Wordmark composites with LTR-pinned wordmark`
4. `Pin the hard shadow offset as direction-independent`

---

### T08.3 — Card and stat composites

**Goal.** Ship `GameHeroPanel`, `DailyMixCard`, `StatBox`, `ScoreSlab` and `BestCard` — the five
composites that carry a value inside a raised surface, in four numeral systems.

**Tests first (TDD).**
- `test/features/shell/widgets/game_hero_panel_test.dart`
  - `renders at radiusXl on e3 with the accent fill` — read the `PopSurface` arguments.
  - `puts the ink label on a dot layer at .08` — the hero's kicker must clear 4.5:1 against the
    composited fill; assert the dot opacity value, and assert the label style is `type.label` with
    `colors.textPrimary`.
  - `lays four 38pt answer swatches in a row` — `getSize` per swatch, in `en` and `fa`; the swatches
    are geometry, so their size must not move with the locale.
- `test/features/shell/widgets/daily_mix_card_test.dart`
  - `renders the grape variant on Home and the paper variant on game detail` — one widget, two fills.
  - `the whole card is one ≥48px tap target labelled by its title, with a non-null onTap` — the card
    navigates (T08.5 fixes where); an inert chevron is the dead affordance E11 T11.1 forbids.
  - `its chevron mirrors` — under `fa` the chevron glyph is rendered with the RTL form (via
    `Icons.adaptive.*` where a Material icon is used, or the `Matrix4.rotationY(pi)` recipe from
    `i18n-rtl-l10n/references/rtl-and-bidi.md` where `SunburstGlyph` has no directional flag). The
    clock and check glyphs in the same file do **not** mirror; assert both halves.
- `test/features/shell/widgets/stat_box_test.dart`
  - `prints its value at statValue with tabular figures` and `uses textPrimary on the sunshine
    variant` (never `textSecondary` on a saturated fill).
  - `its value is passed in already formatted` — handed `'۱٬۴۸۰'` it renders exactly that; the widget
    contains no `NumberFormat`, no `toString()` on a num and no digit literal.
- `test/features/shell/widgets/score_slab_test.dart`
  - `draws a 5px sunshine hard text shadow behind scoreHero` — assert the shadow colour is
    `colors.accent` and its `blurRadius` is 0, in `en` and `fa` (the shadow offset does not mirror).
  - `does not shrink at text scale 2.0` — `getSize` of the score text grows; no `FittedBox` in the
    tree; asserted at `de` 2.0, the longest-label worst case.
- `test/features/shell/widgets/best_card_test.dart`
  - `renders one value chip per game accent`.
  - `formats via ScoreFormat, per locale` — the widget receives the already-formatted string from
    `ScoreFormatter`, and the formatter test pins: `points` 1480 → `en` `1,480`, `de` `1.480`,
    `fa`/`ckb` `۱٬۴۸۰` (digits in U+06F0–U+06F9, grouping separator U+066C); `duration` 18.6s → `en`
    `18.6s`, `de` `18,6 s`, `fa`/`ckb` digits in U+06F0–U+06F9 with the decimal separator U+066B and
    the unit taken from the ARB, asserted against `AppLocalizations.durationSeconds` for that locale
    rather than a literal invented here. `fa` and `ckb` must **not** emit `١٤٨٠` (U+066x, the Arabic
    block) — that is a different script's digits and the most likely silent regression.

**Implementation.** `lib/features/shell/widgets/game_hero_panel.dart`, `daily_mix_card.dart`,
`stat_box.dart`, `score_slab.dart`, `best_card.dart`. All compose `PopSurface`; none formats a number
— each takes an already-formatted `String` (rule 5 of `widget-composition`, and the reason the
numeral system is a single decision in E04 instead of five). `StatBox` takes a `StatBoxTone`
(`accent` / `paper`) rather than a `Color`. Every inset is `EdgeInsetsDirectional`; every alignment is
`AlignmentDirectional`; every value `Text` is `TextAlign.start` or explicitly centred.

**Files.** the five widget files plus their five test files under `test/features/shell/widgets/`.

**Skills.** `sunburst-shell-screens`, `sunburst-components`, `sunburst-tokens`, `i18n-rtl-l10n`,
`widget-composition`, `accessibility-as-code`, `dartdoc-conventions`.

**Screenshot check.** Compare each composite against its region in both reference sets, in the
five-step order: `GameHeroPanel` and the `StatBox` duo against `02-game-detail.png` and
`rtl/02-game-detail.png`; `DailyMixCard` grape variant against `01-home.png` / `rtl/01-home.png` and
paper variant against `02-game-detail.png` / `rtl/02-game-detail.png`; `ScoreSlab` and the
three-column stat trio against `06-results.png` / `rtl/06-results.png`; `BestCard` against
`07-stats.png` / `rtl/07-stats.png`. Check the shadow step per surface (`e1` stat boxes, `e2` cards,
`e3` hero and slab) — a uniform `e2` across all of them is the common defect — and check that the RTL
capture differs from the LTR one **only** in the start/end sides of content, never in the shadow
corner.

**Done when.**
- [ ] `flutter test test/features/shell/widgets` green.
- [ ] `check_raw_values.sh lib`, `check_component_hygiene.sh lib`, `check-widget-composition.sh lib`
      and `check_i18n_bans.sh lib` all green.
- [ ] No composite constructs a `BoxShadow`, `Color`, `Duration`, `Curve` or `NumberFormat`.

**Commits.**
1. `Add GameHeroPanel and StatBox composites`
2. `Add DailyMixCard composite with grape and paper variants and a mirroring chevron`
3. `Add ScoreSlab and BestCard composites over pre-formatted values`

---

### T08.4 — Router, branch shell and back handling

**Goal.** One `GoRouter` in `lib/routing/`, a three-branch `StatefulShellRoute.indexedStack` that owns
`PopBottomNav`, deep links that survive a cold start, the four `PopScope` rows from
`references/run-lifecycle.md`, and a router that is **not** a function of the locale.

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
  - `locations are ASCII in every locale` — the same tap under `fa` produces the same location string;
    the seed in the query is `42`, never `۴۲`. Localisation happens at render; a URL is canonical
    data. Assert the built location character-by-character under all four locales.
  - `the router is built once and does not rebuild on a locale change` — read `routerProvider` from a
    container, flip `localeProvider` to `fa`, read again: the same `GoRouter` instance. A router that
    watched the locale would tear down the branch stack on every language switch and silently make
    T08.9's "does not restart" claim false.
  - `a cold-start deep link into a run with no live notifier redirects to game detail` — the pure
    `appRedirect` returns `/game/placeholder_coral` when the phase snapshot is `idle`.
  - `an unknown location renders NotFoundScreen, not a red box`.
  - `PopScope rows` — one test per phase: `countdown` → `abandon()`, `playing` → `pause()`, `paused` →
    `keepPlaying()`, `over` → pops. Assert the notifier method called, not the route.
  - `no bottom nav on game detail, countdown, play or results` — `find.byType(PopBottomNav)` is empty
    on each of the four.
  - `route transitions collapse under reduced motion` — pumped with `disableAnimations: true`, the
    `CustomTransitionPage` builder returns the child unwrapped.
- `test/routing/nav_shell_direction_test.dart`
  - `the bottom nav order mirrors` — under `en` and `de`, `getRect(Play).left < getRect(Stats).left <
    getRect(Settings).left`; under `fa` and `ckb` the inequality reverses. The tab order in the
    `StatefulShellRoute` branch list is unchanged: it is a `Row` of directional children, so the
    mirror is free and the *index* semantics never move.
  - `the nav labels do not overflow at de` — `Einstellungen` is 11 glyphs against `Settings`'s 8; a
    fit assertion on each tab's label rect inside its tab cell, at scale 1.0 and 1.3.
  - `back and next chevrons mirror; the pause glyph does not` — one assertion per glyph class.
- `test/routing/routes_test.dart` — `Routes.gameDetail(id)` and `Routes.play(config)` round-trip
  through `GoRouterState` without hand-concatenation.

**Implementation.**
- `lib/routing/routes.dart` — `abstract final class Routes` with `home = '/'`, `stats = '/stats'`,
  `settings = '/settings'`, `gameDetail(GameId)`, `countdown(RunConfig)`, `play(RunConfig)`,
  `results(RunConfig)`. Run routes carry `gameId` as a path parameter and `difficulty` + `seed` as
  query parameters, so the URL alone names the run; `state.extra` is never read. Seeds are written
  with `int.toString()` on the canonical value — never through a localized `NumberFormat` — and read
  back through `AsciiNumerals.normalize` before `int.parse`, per `i18n-rtl-l10n` rule 7, so a hand-typed
  Persian digit in a deep link cannot crash the parse.
- `lib/routing/app_router.dart` — the single `GoRouter(...)`, `initialLocation: Routes.home`,
  `refreshListenable` bridged from Riverpod, `redirect: (c, s) => appRedirect(...)` (pure),
  `errorBuilder` → `NotFoundScreen`, `StatefulShellRoute.indexedStack` over the three branches with
  `NavShellScreen` as the branch builder. `routerProvider` **does not** `ref.watch(localeProvider)`.
- `lib/routing/app_redirect.dart` — the pure redirect function, unit-tested with no widget.
- `lib/routing/run_routes.dart` — `RunRoutes.replaceWithResults(context, config)` and friends, so no
  screen hand-writes a location.
- `lib/features/shell/presentation/nav_shell_screen.dart` — hosts `PopBottomNav` and calls
  `navigationShell.goBranch(index)`. The nav bar lives here and nowhere else.
- `lib/features/shell/presentation/not_found_screen.dart`.
- `lib/app.dart` — `MaterialApp.router(routerConfig: ref.watch(routerProvider))` with
  `locale: ref.watch(localeProvider)`, `supportedLocales: supportedLocales`,
  `localizationsDelegates` including E04's `ckb` pair, one `theme:`, no `darkTheme:`, no `themeMode:`.

**Files.** `lib/routing/{routes,app_router,app_redirect,run_routes}.dart`,
`lib/features/shell/presentation/{nav_shell_screen,not_found_screen}.dart`, `lib/app.dart`,
`test/routing/{app_router_test,routes_test,app_redirect_test,nav_shell_direction_test}.dart`.

**Skills.** `navigation-and-routing`, `sunburst-shell-screens`, `i18n-rtl-l10n`,
`state-management-riverpod`, `async-safety`, `sunburst-components`, `testing-strategy`.

**Screenshot check.** The 90pt `PopBottomNav` strip against `01-home.png`, `07-stats.png`,
`08-settings.png` and their three RTL counterparts: 3px ink top border, `pad 9/14/0`, active tab as a
sunshine chip at e1, and the 90pt **including** the bottom inset with the items top-aligned. In the
RTL captures the three tabs read right-to-left with the active chip in the same logical position.
Confirm the bar is absent from `02-game-detail.png`, `03-countdown.png`, `04-stroop-rush.png`,
`05-schulte-grid.png` and `06-results.png` in both sets.

**Done when.**
- [ ] `flutter test test/routing` green.
- [ ] `.claude/skills/navigation-and-routing/scripts/check_routing.sh lib` green — exactly one
      `GoRouter`, under `routing/`, no `Navigator.pushNamed`, no `extra!`.
- [ ] Every screen is reachable by a URL typed into `initialLocation`, and the URL is identical in all
      four locales.
- [ ] The router-identity-across-locale test exists; it is what makes T08.9's claim testable.

**Commits.**
1. `Add typed route constants and the pure app redirect`
2. `Add the single GoRouter with the three-branch indexed stack`
3. `Host PopBottomNav in the branch shell and add the 404 screen`
4. `Wire MaterialApp.router with the four supported locales`
5. `Pin route locations as locale-independent ASCII`

---

### T08.5 — Home screen

**Goal.** The game hub, rendering the registry as data: streak chip, greeting, h1, Daily Mix card,
section label, one `GameCard` per unlocked game and a dashed locked slot — in four locales.

**Tests first (TDD).**
- `test/features/home/home_notifier_test.dart` (`ProviderContainer.test`, no widgets)
  - `greeting resolves from the injected Clock` — `Clock.fixed` at 08:00 / 14:00 / 20:00 yields
    morning / afternoon / evening **keys**, not strings. The notifier produces keys; the screen
    resolves them through `AppLocalizations`. Asserting a key is what keeps this test alive through a
    translation change.
  - `games are in registry order and carry a formatted best` — the formatted value comes from
    `scoreFormatterProvider`; with the `en` formatter, `points` → `1,480` and `duration` → `18.6s`;
    with the `fa` formatter, the same run yields `۱٬۴۸۰` and a U+06Fx duration.
  - `the daily pick is locale-independent` — with `clockProvider` fixed to one `CalendarDay`, the
    picked `GameId` is identical under `en`, `de`, `fa` and `ckb`. The generator consumes a civil date
    and emits a semantic token; a golden vector that moved because the language changed would mean
    localisation had leaked into generation (`seeded-determinism-and-golden-vectors` rule 1).
  - `unlockedCount counts only unlocked definitions`.
  - `a repository failure surfaces as an AsyncError, never a thrown exception`.
- `test/features/home/home_screen_test.dart` (fake registry + fake repositories)
  - `renders one card per registry entry plus the locked slot` — three cards for the fake registry.
  - `the locked slot has a dashed 3px ink border, no shadow and no tap action`.
  - `the BEST pill shows the formatted value from allBestsProvider` — `en` `1,480` / `18.6s`, `de`
    `1.480` / `18,6 s`, `fa` and `ckb` in Eastern Arabic digits; a game with no runs shows no pill
    rather than a zero in any locale.
  - `the streak chip is an ICU plural` — the count-bearing string is `{count, plural, ...}` in every
    ARB, not `'x' + count`; assert the rendered chip for counts 0, 1, 2 and 4 in `en` and `de`, and
    that the `fa`/`ckb` chips carry U+06Fx digits.
  - `the Daily Mix card routes to a seeded pick from the registry` — with `clockProvider` fixed, the
    destination is deterministic; with the clock advanced a day, it may differ. No dead chevron.
  - `adding a fourth definition to the fake registry adds a fourth card with zero source changes` —
    the engine claim, asserted.
  - `exactly one Semantics(header: true)` — under `en` it is the string behind
    `l10n.homeHeadline` ("Ready to train?"); under each other locale it is that locale's rendering of
    the same key, asserted by resolving the key rather than by a literal.
  - `focus on entry lands on the h1` — assert the primary focus node after one `pump`, in `en` and
    `ckb`.
  - `card content is start-aligned in every locale` — the art frame leads and the title follows under
    `en`; under `fa` the same `getRect` relation holds with `left`/`right` swapped, with no widget
    reading `Directionality` to make it happen.
  - `tapping a card routes to /game/<id>` — assert the location, not a pushed widget.
- `test/features/home/home_golden_test.dart` — `@Tags(['golden'])`, `loadAppFonts()`,
  `Device.reference390`, four goldens: `goldens/home_en_390.png`, `home_de_390.png`,
  `home_fa_390.png`, `home_ckb_390.png`.

**Implementation.** `lib/features/home/domain/home_state.dart` (`HomeState`, `HomeGameEntry` — both
immutable with value equality), `application/home_notifier.dart` (`HomeNotifier extends
StreamNotifier<HomeState>` over **`allBestsProvider`** — E02 T02.7's `watchBestsByGame()` fold, the one
read that gives every card its BEST pill without an N+1 of per-game subscriptions — plus
`streakProvider` for the chip and `gameRegistryProvider` for the cards; formats every value through
`scoreFormatterProvider` so `build()` does none), `presentation/home_screen.dart` (dumb
`ConsumerWidget`, composing `RayHeader`, `Wordmark`, `PopChip`, `DailyMixCard`, `GameCard`), and
`presentation/widgets/locked_game_slot.dart` for the dashed "Coming soon" card
(`shape.dashOn`/`dashOff` 9/7, no shadow, `textSecondary`).

**Daily Mix goes somewhere.** `app.html` draws it as a tappable card and T08.3 asserts it is one ≥48px
target, so it cannot ship as a chevron that leads nowhere — E11 T11.1's no-dead-control rule applies to
every affordance, not only the Language row. **Decision for v1:** the card routes to the game detail of
a seeded daily pick — `registry[seededRandomProvider-drawn index]` over the unlocked entries, keyed by
today's `CalendarDay` so the pick is stable for the day, reproducible in a test with a fixed clock, and
identical in every locale. That is one line of routing and no new screen. A curated multi-game mix is a
product feature; record it as deliberately left out. If the owner would rather not ship the card at all
in v1, remove it from the Home composition and record *that*, with the `app.html` reference — but do
not ship it inert.

**Files.** `lib/features/home/{domain/home_state.dart,application/home_notifier.dart,
presentation/home_screen.dart,presentation/widgets/locked_game_slot.dart,home_providers.dart}`,
`test/features/home/{home_notifier_test,home_screen_test,home_golden_test}.dart`,
`test/features/home/goldens/home_{en,de,fa,ckb}_390.png`.

**Skills.** `sunburst-shell-screens`, `scaffold-feature-module`, `state-management-riverpod`,
`widget-composition`, `ui-states-and-feedback`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `i18n-rtl-l10n`, `seeded-determinism-and-golden-vectors`.

**Screenshot check.** `design/sunburst-pop/screens/01-home.png` **and**
`design/sunburst-pop/screens/rtl/01-home.png`, both at 390×844, both captured from
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`. Order: structure (header / Daily Mix / section label / three
cards / nav), spacing rhythm (`pad 16/20/0`, column gap 16, card inner padding 15/16 and Daily Mix
17/16), surface construction (Daily Mix grape at e2 r-lg, game cards at e2, 64pt cream art frame at
r-md e1, locked card dashed with **no** shadow), type role (greeting 14/800 Nunito on ink — not ink-2
— and the h1 at `displayL` 33/1.02; in `fa`/`ckb` the display face is whichever T04 selected, and the
Fredoka personality is carried by the border, shadow and palette, not the letterforms), sampled hex.
`de` and `ckb` have no reference PNG: run them on the simulator and check for overflow, clipping and
line-count changes only.

**Done when.**
- [ ] `flutter test test/features/home` green, four goldens committed.
- [ ] `grep -rn "placeholder" lib/features/home/` returns nothing.
- [ ] `check_shell_boundaries.sh lib`, `verify_feature.sh lib/features/home` and
      `check_i18n_bans.sh lib` green.
- [ ] Compared against `01-home.png` and `rtl/01-home.png`; deltas are either fixed or committed as an
      `app.html` change plus regenerated PNGs in **both** sets.

**Commits.**
1. `Add HomeNotifier over the registry and the derived run reads`
2. `Add HomeScreen composed from shell composites`
3. `Add the dashed locked game slot`
4. `Add the home screen goldens for en, de, fa and ckb`

---

### T08.6 — Game detail and countdown

**Goal.** The `idle` and `countdown` phases: the hero panel, stat duo, difficulty segmented control and
Play button; then the one edge-to-edge screen in the app, counting down in the player's own numerals.

**Tests first (TDD).**
- `test/features/game_detail/game_detail_notifier_test.dart`
  - `difficulties come from the definition, in display order, with lock flags`.
  - `selecting a difficulty is in-session state and does not touch a repository`.
  - `Play builds a RunConfig with a seed drawn from seededRandomProvider` — with the seed provider
    overridden, the config is deterministic and identical in all four locales.
- `test/features/game_detail/game_detail_screen_test.dart`
  - `the hero title is the only Semantics(header: true)`.
  - `the segmented control marks exactly one item selected and is keyboard traversable in display
    order` (`OrdinalSortKey`), in `en` and in `fa` — traversal follows the logical order in both, so
    the visual sweep reverses while the sequence does not.
  - `the segmented control fits its three labels at de` — a fit assertion per item at scale 1.0 and
    1.3; German is the length stress case and this control has the least slack on the screen.
  - `a locked difficulty is not tappable and states why in its label` — non-colour redundancy, in
    every locale (the reason is an ARB string, not an icon alone).
  - `Play routes to the countdown for the selected difficulty`.
  - `no PopBottomNav on this screen`.
- `test/features/play/countdown_screen_test.dart`
  - `renders three dots and fills one per beat` — pump `1000ms` three times with a fake clock; assert
    the filled-dot count 1 → 2 → 3, then a transition to `playing`.
  - `the numerals are the locale's own` — the rendered numeral sequence is `['3','2','1']` under `en`
    and `de`, and `['۳','۲','۱']` (U+06F3, U+06F2, U+06F1) under `fa` and `ckb`.
  - `announces each numeral exactly once, in the locale's numerals` — capture
    `SystemChannels.accessibility` announce messages; expect exactly `['3','2','1']` under `en`/`de`
    and exactly `['۳','۲','۱']` under `fa`/`ckb`. Four tests, not one test with a loop.
  - `the numeral fits inside the 238pt ring in every locale` — a `getRect` containment assertion.
    Eastern Arabic digits have different vertical metrics and a different face; 132pt that fits
    Fredoka's `3` is not proof about Vazirmatn's `۳`.
  - `sets SystemUiOverlayStyle.light and skips the top SafeArea` — under
    `MediaQuery(padding: EdgeInsets.only(top: 47))`, the grape fill's `top` is 0 while the content's
    top is ≥ 47.
  - `the close button calls abandon() and nothing is written` — `FakeRunRepository.saveCalls` is empty.
  - `under reduced motion the ring pop collapses to Duration.zero and the numerals still change`.
- Goldens: `game_detail_{en,de,fa,ckb}_390.png`, `countdown_{en,de,fa,ckb}_390.png`.

**Implementation.** `lib/features/game_detail/{application/game_detail_notifier.dart,
presentation/game_detail_screen.dart}` composing `PopIconButton`, `GameHeroPanel`, `StatBox`,
`DifficultySegmented`, `DailyMixCard` (paper variant) and a full-width `PopButton` at
`type.buttonLarge`. The top-bar back control uses the mirroring chevron from T08.3.
`lib/features/play/presentation/countdown_screen.dart` — the only screen with
`SystemUiOverlayStyle.light`, `SafeArea(top: false)` and its own inset; composes `TimerRing` at e4
(the one e4 on the screen) and a dot row. The numeral is formatted once through
`LocaleNumbers.of(locale)` and handed down as a `String`; the screen writes no digit. The 1000ms beat
and the `.86 → 1.06 → 1.00` numeral pop are `SunburstMotion` values via `Moment.countdownBeat`; the
shell never writes a `Duration`.

**Files.** `lib/features/game_detail/**`, `lib/features/play/presentation/countdown_screen.dart`,
`test/features/game_detail/**`, `test/features/play/countdown_screen_test.dart`, eight golden files.

**Skills.** `sunburst-shell-screens`, `sunburst-motion-and-haptics`, `sunburst-components`,
`state-management-riverpod`, `accessibility-as-code`, `widget-golden-and-a11y-testing`,
`i18n-rtl-l10n`, `scaffold-feature-module`.

**Screenshot check.** `02-game-detail.png` and `rtl/02-game-detail.png`: top bar `pad 2/20/16` (the
back chevron leads in both — pointing left under LTR, right under RTL), hero at r-xl e3 with the dot
layer at .08, the 2-column stat row at gap 12 (sunshine + paper), the `DIFFICULTY` label at 10 upper
ink-2 in `en`/`de` and in normal case with zero tracking under `fa`/`ckb`, the segmented track in
cream-2 with the selected item translated `(-1,-1)` on a 2px shadow (**the same corner in both
directions**), and the leaf Play button at r-xl `pad 18/20` / 21pt pinned to the bottom by a spacer.
`03-countdown.png` and `rtl/03-countdown.png`: full-bleed grape with status glyphs tinted cream, the
238pt sunshine ring at e4, the 132pt numeral (`3` / `۳`), `gap 26` to the "Get ready" line with its
4px ink hard text shadow, and the dot row with `pad-bottom 52`. Confirm the countdown is the **only**
screen whose fill reaches y=0, in both sets.

**Done when.**
- [ ] `flutter test test/features/game_detail test/features/play/countdown_screen_test.dart` green.
- [ ] `check_motion_tokens.sh lib` green — no raw `Duration(`, `Curves.` or `Cubic(` outside
      `lib/theme/`.
- [ ] Both screens compared against their LTR and RTL PNGs; `de` and `ckb` checked on the simulator
      for fit.

**Commits.**
1. `Add GameDetailNotifier with in-session difficulty selection`
2. `Add GameDetailScreen with the hero, stat duo and difficulty control`
3. `Add the full-bleed CountdownScreen with per-locale numerals and announcements`
4. `Add game detail and countdown goldens for four locales`

---

### T08.7 — Play scaffold, HUD and pause sheet

**Goal.** The critical screen: identical chrome for every game, a board slot holding the placeholder,
a HUD that ticks in the player's numerals, a progress band that fills from the start edge, and the
pause sheet with its two actions and its lifecycle triggers.

**Tests first (TDD).**
- `test/features/play/play_scaffold_screen_test.dart`
  - `the chrome is identical for two different games` — pump with `fakeAlphaDefinition` and
    `fakeBetaDefinition` at the same locale; assert `getRect` of the top bar, the HUD row and the
    track match within `epsilon: 0.5`. Only the board pane's background differs. This is the epic's
    central claim, and it is a per-locale claim: the chrome is identical between two *games*, not
    between two *languages* — label widths legitimately differ across locales.
  - `renders exactly three HudPills, equal flex, gap 8` — `getSize` per pill, widths equal, in `en`
    and `de` (the pills are equal-flex, so a longer German label must not widen one pill).
  - `slot A is the shell's clock, not the game's` — the fake snapshot leaves `slotA.value` empty and
    the pill still shows the elapsed time from `Clock.fixed`.
  - `the time pill uses the locale's numerals` — `en`/`de` Latin, `fa`/`ckb` U+06Fx, formatted through
    the injected `NumberFormat` and never by string interpolation of an `int`.
  - `the HUD pill order mirrors` — under `en`, Time leads and Streak trails; under `fa` the same
    logical order renders with Time at the end edge. Assert by `getRect`, not by index.
  - `HudTone.alarm paints danger with both lines inverted` — asserted on colour values, not pixels.
  - `progress == null removes the track widget entirely` rather than drawing an empty well.
  - `the progress band fills from the start edge` — at 30%, under `en` the filled sub-rect's `left`
    equals the track's `left`; under `fa` its `right` equals the track's `right`. A track that always
    fills from the physical left reads as *emptying* in RTL, and it is invisible in a static
    screenshot.
  - `the HUD reflows from a Row to a Wrap above textScaler 1.3` — at 1.3 the three pills share a
    `top`; at 2.0 the third pill's `top` is greater than the first's. Run at `de` as well as `en`:
    German is where the reflow may be needed below the threshold, and if it is, the fix is the
    threshold, not a locale branch.
  - `there is no Semantics(header: true) on this screen` — the board is the content.
  - `the HUD is not a liveRegion` — assert `isSemantics(isLiveRegion: false)` on each pill.
  - `the board pane applies SafeArea and the 0/20/26 gutter so the board does not` — the child's rect
    is inset from the screen by exactly those values in every locale.
- `test/features/play/pause_sheet_test.dart`
  - `opens on pause() and on AppLifecycleState.inactive/paused/hidden` — three tests, driven through
    the observer, not by backgrounding an app.
  - `resuming does not dismiss it` — after `resumed`, the phase is still `paused`.
  - `Keep playing returns to countdown, not straight to playing`.
  - `Leave run sets RunOutcome.abandoned and writes nothing` — `FakeRunRepository.saveCalls` is empty.
  - `barrier tap and system back both mean Keep playing`.
  - `it has exactly two actions` — assert the count; a third is a design change.
  - `the two actions fit side by side at de and ckb` — a fit assertion at scale 1.0 and 1.3.
  - `focus on open lands on the sheet's header` — the string behind `l10n.pauseHeadline` ("Leave the
    run?" in `en`), resolved per locale.
- Goldens: `play_scaffold_coral_{en,de,fa,ckb}_390.png` and
  `play_scaffold_turquoise_{en,de,fa,ckb}_390.png` (chrome only; the board is the placeholder
  rectangle).

**Implementation.** `lib/features/play/presentation/play_scaffold_screen.dart` — `PopScope` over
`Scaffold(backgroundColor: colors.surface)`, `SafeArea(bottom: false)`, `_PlayTopBar`, `PlayBand`
wrapping `_HudRow` + `PopProgressBar`, `Expanded(_BoardPane(...))` with
`RepaintBoundary(definition.buildBoard(context, config))` as the one seam. One `ref.listen` on
`runNotifierProvider(config).select((s) => s.phase)` owns every route change and the pause sheet.
`presentation/widgets/hud_row.dart` — the `Row` → `Wrap` reflow, driven by
`MediaQuery.textScalerOf(context).scale(1) > 1.3` (DERIVED, comment it at the point of use) and never
by a locale check. `presentation/pause_sheet.dart` — `PauseSheet.show(context, config)` over
`PopSheet`, ink scrim at 55% (DERIVED), grab handle 56×6, `Keep playing` (sunshine) and `Leave run`
(paper secondary).

**Files.** `lib/features/play/presentation/{play_scaffold_screen,pause_sheet}.dart`,
`lib/features/play/presentation/widgets/{hud_row,board_pane,play_top_bar}.dart`,
`test/features/play/{play_scaffold_screen_test,pause_sheet_test,play_golden_test}.dart`.

**Skills.** `sunburst-shell-screens`, `sunburst-components`, `sunburst-motion-and-haptics`,
`state-management-riverpod`, `async-safety`, `accessibility-as-code`, `adaptive-layout`,
`i18n-rtl-l10n`, `widget-golden-and-a11y-testing`.

**Screenshot check.** Compare against **all four** of `04-stroop-rush.png`, `05-schulte-grid.png`,
`rtl/04-stroop-rush.png` and `rtl/05-schulte-grid.png`, and compare the two LTR references to each
other first: the top bar (`pad 2/20/10`, pause button, flexed title, difficulty chip), the play band
(accent fill, rays .45 + dots .16, 3px ink bottom border), the HUD row (`pad 2/20/12`, gap 8, three
paper pills at e1 r-md, `highlight` = sunshine with an ink label) and the track (`pad 0/20/14`, height
16, pill, cream-2 well, 45°/9pt accent stripes) must be pixel-identical between the two references;
any difference in the chrome is an implementation defect. Then do the same for the RTL pair. The board
pane (`pad 0/20/26`, top 20) differs only in background: `surfaceSunk` on 04, the game accent on 05.
The stripe angle in the track is a texture, not a direction — it does not mirror; the fill does.
**Board interiors are out of scope** — they are stubs here and are signed off in E09 and E10.

**Done when.**
- [ ] `flutter test test/features/play` green, eight goldens committed.
- [ ] `check_shell_boundaries.sh lib` green — the placeholder board adds no `Scaffold`, `SafeArea`,
      `HudPill`, `Timer.periodic` or navigation.
- [ ] `grep -rn "FittedBox\|TextOverflow.ellipsis\|withClampedTextScaling" lib/features/play/` empty.
- [ ] The chrome is byte-identical between the two board-background goldens at each locale, except
      inside the board pane.

**Commits.**
1. `Add the play top bar and HUD row with the text-scale reflow`
2. `Add PlayScaffoldScreen with the board pane seam and the phase listener`
3. `Fill the progress band from the start edge`
4. `Add PauseSheet with lifecycle and back-gesture triggers`
5. `Add play scaffold goldens for both board backgrounds in four locales`

---

### T08.8 — Results screen and the single run-over announcement

**Goal.** Pay off the run: header, personal-best badge, score slab, the fixed three-stat trio, and one
announcement per run in every locale — never one per stat, never one per language.

**Tests first (TDD).**
- `test/features/results/results_screen_test.dart`
  - `renders the score through ScoreFormat` — `points` and `duration` variants, asserted per locale:
    `en` `1,480` / `18.6s`, `de` `1.480` / `18,6 s`, `fa` and `ckb` in U+06Fx with U+066C grouping and
    U+066B decimal.
  - `the trio is a fixed 3-column grid` — three cells, equal widths, gap 10; a definition supplying
    two stats is a `GameDefinition` bug, asserted as a thrown `ArgumentError` in the notifier, not a
    layout branch.
  - `the trio labels fit their cells at de and ckb, scale 1.3` — three fit assertions per locale.
    German is the length case; Sorani has the taller line box. Nothing shrinks: if a label stops
    fitting, the fix is a smaller **base** step in `lib/theme/`, never a `FittedBox` and never an
    ellipsis on a value.
  - `the personal-best badge appears only when the committed row says so` — with `FakeRunRepository`
    returning `Ok(RunCommit(record, isPersonalBest: false))`, no badge. The flag rides on E02's commit
    value, computed inside the insert's transaction; the screen never re-reads `watchPersonalBest`,
    which would race the write it is rendering.
  - `a save failure shows the saveFailure state and no badge` — never `e.toString()` in the UI; the
    message comes from an ARB key mapped from `Failure.code`, and the mapping is exhaustive in all
    four locales (a missing key is a compile error under `nullable-getter: false`).
  - `the headline is the only Semantics(header: true) and takes focus on entry` — `l10n.resultsHeadline`
    ("Nice run!" in `en`), resolved per locale.
  - `Play again builds a new RunConfig with a new seed at the same difficulty` — the old config is
    not reused; `over` is terminal.
  - `no PopBottomNav on this screen`.
- `test/features/results/run_over_announcement_test.dart` — four tests, one per locale, no loop.
  - `announces the whole outcome exactly once` — install a mock handler on
    `SystemChannels.accessibility`, drive `playing → over`, pump three extra frames and rebuild the
    screen; assert the captured announce list has **length 1**. Under `en` it reads exactly
    `"Run over. Final score 1,480. New personal best."` — the template string, authored here. Under
    `de`, `fa` and `ckb` it equals `AppLocalizations` rendering of the same key with the same
    arguments, so a translation correction never reds this test; additionally assert the `fa` and
    `ckb` announcements contain U+06Fx digits and no ASCII digit, which is the failure this catches
    (a score spliced into a translated sentence with `'$score'`).
  - `the announcement is direction-safe` — under `fa`, the score is an ARB placeholder passed through
    `Bidi.isolateLtr`, and the stored/emitted value written to `FakeRunRepository` contains no character in
    U+2066–U+2069.
  - `no per-stat announcement and no liveRegion on the trio`.
- `test/features/results/results_golden_test.dart` — `results_{en,de,fa,ckb}_390.png`.

**Implementation.** `lib/features/results/{application/results_notifier.dart,
presentation/results_screen.dart}`. The notifier reads the committed `RunState` and produces a
ready-to-render `ResultsState` (already-formatted score, three `ResultStat`s, badge flag, optional
failure code). The screen composes `RayHeader` (leaf, rays .55, centred, `pad 10/20/26`), `PopBadge`
(sunshine, e2, static −2.5° tilt — a fixed rotation, not a directional one; it is identical in RTL),
`ScoreSlab`, the trio (`#1` turquoise, `#2` paper, `#3` coral, ink labels on the saturated tiles) and
two `PopButton`s. Body is a `SingleChildScrollView` + `ConstrainedBox(minHeight: viewport)` +
`Center`, so `scoreHero` 76 can grow to 200% instead of being shrunk. `Moment.resultsReveal` (dy 12 →
0, stagger 40ms) and `Moment.personalBest` come from `sunburst-motion-and-haptics`; the announcement
fires from the notifier's single `→ over` edge, not from `build()`.

**Files.** `lib/features/results/**`, `test/features/results/**`, `test/features/results/goldens/`.

**Skills.** `sunburst-shell-screens`, `sunburst-motion-and-haptics`, `accessibility-as-code`,
`ui-states-and-feedback`, `state-management-riverpod`, `widget-golden-and-a11y-testing`,
`i18n-rtl-l10n`.

**Screenshot check.** `06-results.png` and `rtl/06-results.png`: leaf header with leaf-deep rays at
.55 and `pad 10/20/26`, the label at 10 upper on **ink** (normal case, zero tracking under `fa`/`ckb`),
`displayXl` 42/700 h1, the tilted sunshine badge at the same tilt in both directions, body
`pad 20/20/26` centred with gap 16, `ScoreSlab` at paper r-xl e3 `pad 18/20/20` with the 5px sunshine
hard text shadow, and the three-column trio at gap 10 r-md e1 with 10-upper labels. Verify the score's
shadow is sunshine with `blurRadius` 0 and offset `(5,5)` in **both** directions — a soft drop shadow
here is the most visible possible miss, and a mirrored one is the second.

**Done when.**
- [ ] `flutter test test/features/results` green, four goldens committed.
- [ ] The announcement test asserts length 1 in each of the four locales, not "contains".
- [ ] `check_raw_values.sh lib` and `check_i18n_bans.sh lib` green.
- [ ] Compared against `06-results.png` and `rtl/06-results.png`.

**Commits.**
1. `Add ResultsNotifier over the committed run row`
2. `Add ResultsScreen with the score slab and stat trio`
3. `Announce the run outcome once on the over transition, in every locale`
4. `Add the results goldens for four locales`

---

### T08.9 — Stats and Settings, including the Language row

**Goal.** The two remaining nav branches: lifetime totals with a true-zero bar chart, the four
feel/accessibility switches wired to the real `SettingsRepository`, and a Language row that actually
changes the language.

**Tests first (TDD).**
- `test/features/stats/stats_notifier_test.dart`
  - `one BestCard entry per unlocked game, in registry order; locked games are hidden`.
  - `bar heights are value / max × 149, so no bar can exceed the band` — the fixed `/ 10.5` divisor
    from `app.html` clips above ~1560 and is a documented DERIVED change.
  - `an empty history yields the empty state, not a zero-height chart` — empty, filtered-empty and
    error are three states (`ui-states-and-feedback` rule 3).
  - `bar geometry is locale-independent` — the same series under `en` and `ckb` produces an identical
    `ChartScene`; only the axis labels differ.
- `test/features/stats/stats_screen_test.dart`
  - `the headline is the only Semantics(header: true)` — `l10n.statsHeadline`, resolved per locale.
  - `the chart is ExcludeSemantics with a sibling Semantics that speaks the seven values` — and it
    speaks them in the locale's numerals, from the same `NumberFormat` the painter is fed.
  - `the axis is true zero` — assert the painter's baseline y equals the band's bottom.
  - `the chart does not mirror but its chrome does` — under `fa` the plotted series keeps its
    left-to-right time order (a chart that reversed would say the player got worse), while the card,
    the labels and the legend mirror. This is `i18n-rtl-l10n`'s LTR-pinned-painter island, applied to
    exactly one subtree.
  - `the body scrolls at textScaler 2.0 without overflow`, in `de` and `ckb`.
- `test/features/settings/settings_screen_state_test.dart`
  - `state comes from settingsRepositoryProvider.watch()` and each setter writes through the
    repository — persist-before-publish, asserted by ordering the fake's `writeCalls` before the
    stream emission. Driven through **E02's `settingsProvider` + `settingsRepositoryProvider.update(...)`**,
    not a new notifier — E02 T02.4 states there is no `AppSettingsNotifier` and no in-memory settings
    state anywhere in the app.
  - `reduce motion is OR-ed with the platform flag` — with the platform flag true and the setting
    false, the effective value is true; asserted below E06's `MotionPreferenceScope`, and the test
    also asserts the scope appears exactly once in the tree.
- `test/features/settings/settings_screen_test.dart`
  - `the whole 62pt row is the tap target, not the 66×34 toggle` — `getSize` on the row ≥48 and the
    toggle renders with `onTap: null`.
  - `the toggle prints ON/OFF inside its track` — state survives greyscale
    (`accessibility-as-code` rule 6); the two words come from the ARB, so `de` renders EIN/AUS and the
    track fits both — a fit assertion at scale 1.0 and 1.3 in all four locales.
  - `the colour-blind row shows a four-swatch preview of the palette it swaps IN`.
  - `flipping reduce motion updates the root MediaQuery within the same pump` — assert
    `MediaQuery.disableAnimationsOf` on a descendant.
  - `no game-specific row exists` — `find.textContaining('Stroop')` is empty; per-game options belong
    on game detail.
  - `every row label fits at de` — `Einstellungen`-class expansion is the reason this screen is the
    first to break; a fit assertion per row at 1.0, 1.3 and 2.0.
- `test/features/settings/language_row_test.dart` — the new control.
  - `the row shows the active locale's name in its own language` — `en` → `English`, `de` →
    `Deutsch`, `fa` → `فارسی`, `ckb` → `کوردیی ناوەندی`. The four names are ARB keys that are
    **identical in all four ARB files** (a language list is not translated), and each is rendered in
    its own `Directionality` island, which `i18n-rtl-l10n` sanctions explicitly for a language picker.
  - `tapping opens the LanguageSheet` — the destination is a `PopSheet`, **not a route**: four
    mutually-exclusive options do not earn a navigation stack entry, and E11 T11.1 asserts the same
    sheet rather than a `/settings/language` route.
- `test/features/settings/language_sheet_test.dart` — the destination, extended by E11 T11.1.
  - `the sheet holds exactly four options in a mutually exclusive group` — assert
    `isSemantics(inMutuallyExclusiveGroup: true)` per option and exactly one `selected: true`.
  - `selecting fa flips Directionality to rtl within the same pump` — no restart, no navigation, no
    frame of the old direction.
  - `selecting ckb does not throw` — the ckb delegate tripwire again, this time through the real
    control the user touches. `tester.takeException()` is null and the Material back tooltip resolves.
  - `the choice persists before it publishes` — `FakeSettingsRepository.writeCalls` records the locale
    write before `localeProvider` emits, same ordering rule as every other setting.
  - `switching locale does not restart the app and does not lose state` — three assertions in one
    scenario: the `GoRouter` instance is identical before and after (T08.4's provider identity),
    Home's scroll offset is unchanged after switching and returning to the Home branch, and a live
    `runNotifierProvider(config)` seeded to `playing` with 12s elapsed still reports 12s elapsed and
    phase `playing` after the switch. A `ProviderScope` rebuilt from scratch fails all three.
  - `the row is not a dead control` — it has a non-null `onTap` and its `Semantics` announces the
    current value, not just the label (E11 T11.1).
- Goldens: `stats_{en,de,fa,ckb}_390.png`, `settings_{en,de,fa,ckb}_390.png`.

**Implementation.** `lib/features/stats/{application/stats_notifier.dart,
presentation/stats_screen.dart,presentation/widgets/run_bar_chart.dart}` — `StatsNotifier` reads E02's
`allBestsProvider`, `runStatsProvider(RunScope.of(id, null))` and `chartSeriesProvider`; there is no
`StatsRepository` to read from. The chart is a View/Painter/Scene trio with `shouldRepaint` as one
value compare, zero allocation in `paint()`, and the injected `NumberFormat` for its labels.
`lib/features/settings/{presentation/settings_screen.dart,presentation/widgets/settings_row.dart,
presentation/widgets/colour_blind_preview.dart,presentation/widgets/language_row.dart,
presentation/language_sheet.dart}` — the four toggle rows read `ref.watch(settingsProvider)` and write
through `ref.read(settingsRepositoryProvider).update(settings.copyWith(...))`, switching the returned
`Result<AppSettings, DataFailure>` exhaustively. **There is no `SettingsNotifier` and no
`appSettingsProvider`**: E02 T02.4 decided the single write path is the repository and
`settingsProvider` is a stream over `watch()`, so persist-before-publish is structural rather than a
convention. The Language row writes through **E04's `localeProvider`**, which is the same pattern one
layer up — it derives from `settingsProvider` and its `select(...)` writes through the same
repository. A fifth setting living in a sixth place is how a settings screen rots.

`LanguageSheet` is a `PopSheet` of four rows, each rendered in its own `Directionality` island with
its own script's font cascade, each an ≥48px target, each carrying `selected:` semantics. It closes on
selection and writes once.

**The reduce-motion fold is E06's and stays where E06 mounted it** — `MotionPreferenceScope`, once, in
`lib/app.dart`, above `MaterialApp`. This task adds **nothing** in `MaterialApp.router(builder:)`: a
second fold would OR the same flag twice, pass every test, and be obviously wrong to read. Because E06
already reads `settingsProvider`, there is not even a provider to re-point — check `lib/app.dart`
before writing and confirm the scope is there.

**Files.** `lib/features/stats/**`, `lib/features/settings/**`, `lib/app.dart`,
`test/features/stats/**`, `test/features/settings/**`.

**Skills.** `sunburst-shell-screens`, `custom-canvas-and-gestures`, `state-management-riverpod`,
`ui-states-and-feedback`, `accessibility-as-code`, `sunburst-components`, `i18n-rtl-l10n`,
`widget-golden-and-a11y-testing`.

**Screenshot check.** `07-stats.png` / `rtl/07-stats.png`: turquoise header with **dots only, no
rays**, `pad 10/20/18`; `BestCard` at accent fill r-lg e2 `pad 13/15` with a cream value chip at r 14
on a 2px shadow; the `StatBox` duo at gap 12; the chart card at paper r-lg e2 `pad 14/15/12` with a
164pt band, striped accent/accentDeep bars at r 8/8/3/3 on 2px shadows, the best bar in sunshine
stripes, and a 3px ink axis that *is* true zero — with the bars in the same time order in both
captures. `08-settings.png` / `rtl/08-settings.png`: grape header with rays at **.3**; groups at paper
r-lg e2 with rows split by 3px **ink** (never cream-3); 36pt icon chips at cream-2, 2px, r 11;
`PopToggle` 66×34 with the toggle at the end edge in both directions; the Language row above the
group footer; the footer wordmark and tagline in ink-2 at `pad 14/10/20`, with `MindForge` pinned LTR
inside the Persian line.

**Done when.**
- [ ] `flutter test test/features/stats test/features/settings` green, eight goldens committed.
- [ ] A toggle flip and a language change both survive an app restart against the real repository —
      manual check on `C13DDC02-375D-4E1B-8F81-44EB407D09A4`.
- [ ] Switching to `ckb` from the Language row on the simulator does not throw and every Material
      chrome string (back tooltip, scrollbar, text-selection menu) resolves.
- [ ] `check_painter_hygiene.sh lib`, `check_raw_values.sh lib` and `check_i18n_bans.sh lib` green.
- [ ] Compared against `07-stats.png`, `08-settings.png` and both RTL counterparts.

**Commits.**
1. `Add StatsNotifier with the true-zero bar scale`
2. `Add StatsScreen with the LTR-pinned run bar chart painter`
3. `Add SettingsScreen writing through settingsRepositoryProvider`
4. `Add the Language row and sheet over localeProvider`
5. `Add stats and settings goldens for four locales`

---

### T08.10 — Cross-screen matrices and the gate sweep

**Goal.** Prove the eight screens as a set: no overflow across the locale, width and text-scale band,
one header and correct entry focus everywhere in every language, and every gate script green.

**Tests first (TDD).** This task is tests only; any production change it forces is a defect fix in the
screen that failed, committed with the test that caught it.
- `test/layout/shell_overflow_matrix_test.dart` — one `testWidgets` per
  (screen, locale, scale, width) tuple: eight routes × `LocaleCase.all` (en/de/fa/ckb) × `[1.0, 1.3,
  2.0]` × `Device.all` (320/360/390/430) = **384 tests**; never a loop inside a test, because overflow
  reports once per `RenderObject`. Each asserts `tester.takeException()` is null **and** a fit
  assertion: the HUD pills, the results trio cells, the difficulty segments and the settings row
  labels each sit inside their computed cell via `getRect`. A bold pass at `Device.reference390` ×
  four locales × `2.0` follows `setUpAll(loadAppFonts)` — the bold axis is inert under Ahem, and the
  Arabic-script bold is a **different font file**, so it is the one that can actually change metrics.
- `test/a11y/shell_a11y_test.dart` — per screen × per locale:
  - `exactly one Semantics(header: true)`, resolved from the ARB key named in
    `references/screen-anatomy.md` — Home `homeHeadline`, detail = the hero title, countdown
    `countdownHeadline`, pause `pauseHeadline`, results `resultsHeadline`, stats `statsHeadline`,
    settings `settingsHeadline`; the play scaffold has **none**. Assert against the resolved key, not
    an English literal, so a translation fix is not a test failure.
  - `focus on entry lands on the header` (the play scaffold's lands on the board's first target).
  - `traversal order matches the visual order` via `simulatedAccessibilityTraversal` — the same
    logical sequence in LTR and RTL, which under RTL means right-to-left on screen. A traversal that
    reversed under RTL is a defect in a hand-built `OrdinalSortKey`.
  - `every tap target is ≥48px` — an explicit `getSize` loop, not `meetsGuideline` (which skips nodes
    flush with the view edge).
  - `every glyph is labelled or excluded` — no unlabelled `SunburstGlyph` in any screen's tree, in any
    locale.
- `test/a11y/shell_contrast_test.dart` — pure-Dart WCAG over the composited pairs these screens
  introduce: greeting on sunshine, hero kicker on each accent, HUD `alarm` both lines on `danger`,
  results trio labels on turquoise and coral, settings header cream on grape at ray .3. **Colour is
  locale-independent** and this file is not multiplied by four; that is stated in a comment so the next
  reader does not "fix" it.
- `test/golden/shell_screens_golden_test.dart` — `@Tags(['golden'])`, collects the **32** goldens
  produced in T08.5–T08.9 (eight screens plus the second board background, × four locales) into one
  lane so CI runs them together and never with `--update-goldens`.

**Implementation.** No new production code is planned. Fix whatever the matrix reds — expected
suspects: the HUD row at `de` below 1.3, the results trio at 320 in `de`, the settings two-line
colour-blind label at 2.0, the difficulty segmented control at `de`, the stats chart labels at 430,
and any `ckb` line box that clips at 2.0 because its ascenders exceed Nunito's. Every fix is a
directional-geometry or **base type step** change, never a `FittedBox`, never a clamped `textScaler`,
never an ellipsis on a value.

**Files.** `test/layout/shell_overflow_matrix_test.dart`, `test/a11y/shell_a11y_test.dart`,
`test/a11y/shell_contrast_test.dart`, `test/golden/shell_screens_golden_test.dart`, plus fixes.

**Skills.** `widget-golden-and-a11y-testing`, `accessibility-as-code`, `adaptive-layout`,
`i18n-rtl-l10n`, `testing-strategy`, `sunburst-shell-screens`.

**Screenshot check.** Re-run the five-step comparison on all eight LTR PNGs and all eight RTL PNGs
after the matrix fixes — a layout change made to green 320pt in German is exactly the change that can
break 390pt in English, and 390pt English and 390pt Persian are the two references.

**Done when.**
- [ ] `flutter test` green with no `takeException()` suppression, no `ignoreOverflowErrors`, no
      `FlutterError.onError` assignment anywhere under `test/`.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh lib test` green.
- [ ] `.claude/skills/testing-strategy/scripts/check_test_hygiene.sh` green.
- [ ] Every gate in the section below green.
- [ ] Suite wall time recorded in the PR body against the `testing-strategy` budget, with the trim
      order from Risk 7 applied if it was exceeded and the trim recorded.

**Commits.**
1. `Add the shell overflow and fit matrix across four locales, four widths and three text scales`
2. `Add per-screen, per-locale header, focus and traversal tests`
3. `Add pure-Dart contrast tests for the composited shell pairs`
4. `Collect the 32 shell goldens into one lane`
5. `Fix the layout defects the matrix found`

---

### T08.11 — Simulator sign-off against both reference sets

**Goal.** The manual gate no script can run: every screen, on the canonical simulator, beside its LTR
and RTL reference, in the five-step order — plus the `de` and `ckb` passes that have no reference and
are checked for fit and script correctness instead.

**Tests first (TDD).** n/a — this task is a manual verification pass. Anything it finds is a defect
fixed in the owning task's file, with a regression test added there and committed with the fix. A
finding that cannot be expressed as a test (a sampled hex, a spacing rhythm) is recorded in the PR
body with the two screenshots.

**Implementation.**
```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
# per screen, per locale, switching language from the in-app Settings row — never iOS Settings,
# because the in-app override is what ships:
xcrun simctl io C13DDC02-375D-4E1B-8F81-44EB407D09A4 screenshot /tmp/mf/<nn>-<screen>-<locale>.png
```
Each capture is 780×1688 px, the same as the references. Compare in the order structure → spacing
rhythm → surface construction → type role → sampled hex:

| Capture | Compare against |
|---|---|
| `en` × 8 screens | `design/sunburst-pop/screens/NN-*.png` |
| `fa` × 8 screens | `design/sunburst-pop/screens/rtl/NN-*.png` |
| `de` × 8 screens | no reference — fit, line count, clipping and nav-label width only |
| `ckb` × 8 screens | the `fa` reference structurally — same direction and script; differences are letterforms and the Sorani-specific letters ڕ ڵ ۆ ێ ھ, which must render as glyphs and never as tofu or a fallback box |

There is no `ckb` reference PNG and there will not be one: it would differ from the `fa` capture only
in letterforms, and a second RTL reference set would double the re-render cost of every `app.html`
change for no additional signal. This is a deliberate choice, recorded here.

Also verify, on device and not in a test:
- The pause sheet in all four locales (it has no PNG in either set — the wireframe in
  `references/screen-anatomy.md` §5 is its reference).
- The run-over announcement fires once, in the active language, with VoiceOver on. Use Xcode's
  Accessibility Inspector speech log against the booted simulator. If the log cannot be captured, say
  so and hand the check to E11's device pass rather than marking it done.
- A cold restart preserves the chosen locale (kill the app from the simulator, relaunch, confirm the
  UI comes back in `ckb`).

**Files.** No source files. The PR body gains the comparison table with a row per screen per locale
and a finding column.

**Skills.** `sunburst-shell-screens`, `i18n-rtl-l10n`, `widget-golden-and-a11y-testing`,
`accessibility-as-code`.

**Screenshot check.** This task *is* the screenshot check — 32 captures against 16 references.

**Done when.**
- [ ] All 32 captures taken on `C13DDC02-375D-4E1B-8F81-44EB407D09A4` at 780×1688.
- [ ] Every `en` and `fa` screen signed off against its PNG, or the delta committed as an `app.html`
      change plus a re-run of `capture-screens.sh` regenerating **both** sets.
- [ ] No tofu, no fallback box and no clipped ascender in any `fa` or `ckb` capture; the Sorani letters
      ڕ ڵ ۆ ێ ھ render in the shipped display and body faces, and which display face was used is
      recorded in the PR body.
- [ ] The locale survives a cold restart.
- [ ] The comparison table is in the PR body. A screen without a row is a review reject.

**Commits.**
1. `Fix the defects the simulator sweep found`   *(only if it found any; otherwise this task adds no commit and the PR body carries the table)*

## Gates that must pass

```bash
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test

# the epic's named gates
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                   lib
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                  lib/l10n

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

E01 T01.11 put `verify_feature.sh` in the runner's **skip** table with the reason "takes one feature
directory; run per feature by E08/E09/E10". This epic creates the first `lib/features/<name>/`
directories, so **move it to the run table in this PR**, iterating the seven feature folders —
`test/policy/skill_gates_coverage_test.dart` asserts every script appears exactly once, which is what
makes the move deliberate rather than forgotten.

`check_arb_parity.sh` is **no longer skipped**: E04 moved it to the run table when `app_de.arb`,
`app_fa.arb` and `app_ckb.arb` landed beside the template. This epic appends twelve placeholder keys
to all four files and keeps it green; a key added to `app_en.arb` alone fails the build. The second
gate that matters is still `nullable-getter: false`, which turns a missing key into a compile error.

Plus the manual gate that no script covers, and which is T08.11 in full: each of the eight screens
placed beside its LTR PNG and its RTL PNG at 390×844 on
`MindForge iPhone 14` (`C13DDC02-375D-4E1B-8F81-44EB407D09A4`) and walked through structure → spacing
rhythm → surface construction → type role → sampled hex.

## Risks and open questions

1. **Screenshot comparison is manual and this epic now has sixteen references and thirty-two
   captures.** No CI job can run it. Mitigation: every screen task carries an explicit comparison step
   naming both PNGs, T08.11 does the sweep on one named simulator, and the PR body must carry the
   per-screen per-locale table. A screen merged without its row is a review reject.
2. **Kurdish Sorani is the sharp technical risk and it is E04's fix, not this epic's.**
   `flutter_localizations` very likely ships no `GlobalMaterialLocalizations` for `ckb`, and a missing
   delegate throws at runtime on the first Material chrome string after the switch. E04 owns the custom
   delegate that serves our ARB strings while delegating Material/Cupertino to the nearest supported
   script neighbour (`fa`, else `ar`). This epic carries two tripwires — `pumpShellApp('ckb')` in T08.1
   and the real Language row in T08.9 — and **if either reds, the fix goes in E04**; a shell screen
   that catches the throw or hides the locale is a review reject. Also unverified until E04 lands:
   whether `intl` has date/number symbol data for `ckb`; the plan of record is that it does not and
   that `ckb` is pinned to the `fa` formatter.
3. **Sorani glyph coverage in the display face is unresolved.** Vazirmatn covers Persian and Sorani for
   body text. The chunky display face that echoes Fredoka — Lalezar is the closest OFL candidate — is
   **not** assumed to cover ڕ ڵ ۆ ێ ھ. E04's coverage check decides; if it fails, display falls back to
   Vazirmatn Bold and the `ckb` headings look different from the `fa` headings. T08.11 records which
   face shipped. Until then, every `ckb` golden is provisional.
4. **The Fredoka personality does not survive translation, and the epic does not pretend otherwise.**
   In `fa` and `ckb` the identity is carried by the shape language — the 3px ink border, the hard
   offset shadow, the press-down, the palette — not by the typeface. A reviewer comparing an `fa`
   capture to an `en` capture and asking why the letters look different is asking the wrong question;
   the right one is whether the borders, shadow offsets and colours are identical. They are, and the
   shadow-direction test in T08.2 is the proof.
5. **Tabular figures for Eastern Arabic numerals are not guaranteed.** The HUD time pill and the
   countdown numeral must not reflow as digits change. Fredoka and Nunito have `tnum`; Vazirmatn's
   coverage is unverified. T08.0's width test discovers it. If it fails, the mitigation is a
   fixed-width slot sized to the widest numeral at that step — a token change in `lib/theme/`, not a
   `FittedBox` and not a monospace substitute.
6. **German is the length case and it has no reference PNG.** `de` sign-off is fit-only. The overflow
   matrix is the real gate, and the fix for a label that stops fitting is a smaller **base** step, per
   D8 — never a shrink-to-fit. Expect the settings rows, the difficulty segments and the nav labels to
   be the three that move.
7. **Suite time.** 384 overflow tuples, 32 goldens, four-locale a11y passes and a bold pass make this
   by far the largest test surface in the project — four times E07's. If `flutter test` exceeds the
   `testing-strategy` budget, trim in this order and record the trim: (a) drop text scale 1.3 at the
   two non-reference widths, (b) drop the bold pass to `de` and `ckb` only, (c) run the golden lane as
   a separate CI job. **Never** drop a locale and **never** drop 320 — width and language are where the
   real defects live.
8. **A font-file swap re-baselines 32 goldens.** If E04's display-face decision changes after this
   epic merges, every `fa` and `ckb` golden must be re-blessed through the reviewed rebaseline command
   — never with `--update-goldens` in CI. Land the font decision before T08.5, or accept the churn.
9. **The non-mirroring decisions are deliberate and a reviewer will query them.** The hard offset
   shadow, the ray sweep, the halftone lattice, the results badge tilt and the progress-track stripe
   angle do **not** mirror: they are light-source and texture constants, not reading-direction
   properties. The progress *fill*, the nav order, the chevrons, every inset and every text alignment
   **do**. Both halves are asserted in tests so the decision is readable from the suite, not from a
   comment.
10. **Translation quality is not done and must not be presented as done.** The `de`, `fa` and `ckb`
    strings this epic renders are machine-quality until a native speaker reviews them — Sorani most of
    all, where the pool of reviewers is smallest and the risk of a fluent-looking wrong register is
    highest. The twelve placeholder-game keys are exempt because E09 deletes them. Everything else
    needs a native pass, and that pass is an E11 release gate, not a nice-to-have. Do not ship on
    machine Persian.
11. **The placeholder registry could outlive its purpose.** `lib/games/placeholder/` exists only so the
    shell is runnable and comparable before E09. Decision: its files carry
    `// DELETE IN E09 — see epics/E09-stroop-rush.md` in the first line, and E09's first commit removes
    the directory, the three registry entries, `test/games/placeholder_registry_test.dart`, and the
    twelve ARB key groups **from all four locale files**. If E09 ships without that, three placeholder
    cards remain on Home and it is a review reject on E09.
12. **How a shell screen gets a game's localized title.** `GameDefinition` deliberately has no title
    field, and gen-l10n has no dynamic key lookup. Decision: `lib/l10n/game_strings.dart` holds
    `gameStringsProvider`, a `Map<GameId, GameStrings>` assembled from `AppLocalizations` getters. It
    is the second and last file allowed to name every game; it lives outside `lib/features/**` so
    `check_shell_boundaries.sh` still passes, and E09/E10 each append one entry. A game title that
    stays Latin in a Persian sentence (e.g. "Stroop Rush") must be isolated through `Bidi.isolateLtr` at
    the ARB placeholder, never spliced.
13. **A cold-start deep link into a live run cannot be reconstructed.** `/game/:id/play?difficulty=&seed=`
    names the config, but the `RunNotifier` for it does not exist after process death. Decision: the
    pure `appRedirect` sends any run route whose phase snapshot is `idle` back to `/game/:id`. Tested
    in T08.4; no `state.extra` anywhere; the location is ASCII in every locale.
14. **The HUD reflow threshold is DERIVED and German may move it.** `app.html` has one text scale and
    one language, so "above `textScaler` 1.3 the HUD becomes a `Wrap` 2+1" comes from
    `sunburst-shell-screens`, not from the mock. If `de` needs the reflow at 1.0, change the
    **threshold**, not the locale — a `if (locale == 'de')` in a layout is the defect `adaptive-layout`
    rule 1 exists to prevent. Let the matrix in T08.10 be the evidence.
15. **The stats bar divisor differs from the mock on purpose.** `app.html` hard-codes `value / 10.5`,
    which clips any score above ~1560. Ship `value / max × 149` and mark it DERIVED. If a reviewer
    wants the mock to match the code, that is an `app.html` edit plus `capture-screens.sh` plus
    committed PNGs in **both** sets — not a silent divergence.
16. **E06's reduce-motion fold already exists and this epic must not add a second.** E06 T06.4 mounted
    `MotionPreferenceScope` once in `lib/app.dart` over **E02's `settingsProvider`** — E02 landed four
    epics earlier and owns both the value and its durability, so there was never a notifier to
    re-point. T08.9 therefore builds the Settings *screen* only — no second fold in
    `MaterialApp.router(builder:)`, no `SettingsNotifier`, and no third notifier for the locale.
    Check `lib/app.dart` before writing.
17. **`Difficulty` lock flags.** `references/screen-anatomy.md` says "`Difficulty` carries its own lock
    flag", but nothing in E07's scope commits to it. If the type lands without one, the game detail
    screen renders all difficulties unlocked and the locked-difficulty test is deleted with a one-line
    note — do not add the field from inside a shell screen.
18. **Android is not verified by anything in this epic.** iOS is the shipping target; no Android build
    is produced, no Android device or emulator is used, and no claim of parity is made. The directional
    geometry and the ARB contract are platform-independent by construction, but "should work" is not
    "verified" — when Android becomes a target it gets its own sweep.

## Definition of done

- [ ] Branch `epic/08-shell-screens` cut from `main`, granular commits, tests committed with the code
      they cover.
- [ ] The six shell type steps shipped in `lib/theme/` (T08.0) before any screen asserted against them;
      the scale is eighteen steps, the count test still derives from the source file, every new step
      carries the Arabic-script fallback cascade, and `sectionLabel` drops its tracking under Arabic
      script.
- [ ] Eight screens under `lib/features/**`, nine composites in `lib/features/shell/widgets/`, one
      `GoRouter` in `lib/routing/`, Settings reading `settingsProvider` and writing through
      `settingsRepositoryProvider.update(...)`, and the Language row through E04's `localeProvider` —
      one write path, one fold, one mounting point, and no `AppSettingsNotifier` anywhere
      (`grep -rn 'AppSettingsNotifier\|appSettingsProvider' lib/` is empty).
- [ ] No `StatsRepository` was created; Home and Stats read E02's derived providers, and Home's BEST
      pills come from `allBestsProvider`.
- [ ] Every affordance navigates — including the Daily Mix card and the Language row. No dead chevron
      ships.
- [ ] Every user-facing string on eight screens resolves through `AppLocalizations` in `en`, `de`, `fa`
      and `ckb`; `check_arb_parity.sh lib/l10n` and `check_i18n_bans.sh lib` are green; no shell file
      constructs a `NumberFormat`, cases a string, or writes a physical-side inset.
- [ ] Switching locale from the Settings row changes direction and numerals in place: no restart, the
      same `GoRouter` instance, branch scroll preserved, a live `RunNotifier` undisturbed, and `ckb`
      does not throw.
- [ ] Each of the eight screens compared against its PNG in `design/sunburst-pop/screens/` **and** its
      counterpart in `design/sunburst-pop/screens/rtl/` at 390×844 on
      `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, through the five-step order; `de` and `ckb` checked for
      fit and script correctness; deltas fixed, or committed as an `app.html` change plus a re-run of
      `capture-screens.sh` plus the regenerated PNGs in both sets.
- [ ] The play scaffold compared against **both** `04-stroop-rush.png` and `05-schulte-grid.png` and
      both RTL counterparts, with the chrome identical between the two games at each locale; board
      interiors explicitly deferred to E09/E10.
- [ ] Widget test per screen over the fake registry and fake repositories; four goldens per screen at
      390×844 (32 in one lane); overflow + fit matrix at 8 screens × 4 locales × 3 text scales × 4
      widths; a11y test per screen per locale for the one `Semantics(header: true)` and entry focus;
      routing test for every deep link and all four `PopScope` rows; the run-over announcement asserted
      at exactly one **per locale**.
- [ ] The hard shadow, ray sweep, halftone lattice, badge tilt and stripe angle are asserted not to
      mirror; the nav order, progress fill, chevrons, insets and alignments are asserted to mirror.
- [ ] `check_shell_boundaries.sh lib` green, and every other gate in the section above green, including
      `verify_feature.sh` moved into `tool/skill_gates.sh`'s run table for the seven feature folders.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] PR opened with a body stating what changed, why, how it was verified, **the per-screen
      per-locale comparison table**, the display face that shipped for `ckb`, the suite wall time, and
      what was deliberately left out (board interiors, a `ckb` reference PNG set, native translation
      review, Android, the placeholder registry's removal in E09).
- [ ] CI green on the pipeline E01 created.
- [ ] Merged preserving the granular commits, branch deleted, back on `main`, pulled.
