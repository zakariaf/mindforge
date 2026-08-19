> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E11-accessibility-qa-and-release.md`](../E11-accessibility-qa-and-release.md) — **E11 · Accessibility, QA and release**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E10 · Accessibility, QA and release

| | |
|---|---|
| **Branch** | `epic/10-accessibility-qa-and-release` |
| **Depends on** | E01, E05, E07, E08, E09 |
| **Unblocks** | nothing — this is the last epic in the v1 sequence |
| **Status** | Not started |

## The epic

The end-of-build sweep and the first shippable build. Every screen exists, both games run, CI is
green — this epic is where we find out whether the thing is actually usable by someone with a 200%
system font, a colour-vision deficiency, reduce-motion on, and a four-year-old Android phone. It
runs the one structured design/QA pass `design-review-workflow` specifies: a deterministic
screenshot sweep matrix compared against `design/sunburst-pop/screens/*.png`, an on-device pass on
real floor hardware, findings graded BLOCKER/FIX/NOTE with every accessibility-floor violation a
mandatory BLOCKER, exactly one scoped fix round, and a dated sign-off artifact that gates the
release.

Then it ships: a profile-mode performance and size measurement on that same floor device, an app
icon and a native launch screen, `version: 1.0.0+1` in `pubspec.yaml` as the single source of
`versionName`/`versionCode`, signing material kept out of the repo, an obfuscated build with
`--split-debug-info` symbols archived, a permission audit asserting the MERGED Android manifest
requests **nothing** (INTERNET stripped with `tools:node="remove"`), store Data Safety and
`PrivacyInfo.xcprivacy` declarations proved from the repo rather than written from memory, and a
recorded size/cold-start budget that later releases are measured against. It also closes the one
loose control in the design: the Settings "Language — English" row, which the mock draws with a
chevron and which nothing has yet given a destination.

**The localisation posture is not decided here.** E01 T01.10 decided it — adopt gen-l10n, ship one
locale — and recorded it as `docs/decisions/0001-localisation-v1.md`, because E07, E08 and E09 all ship
strings and a posture settled after them is a posture three epics guessed at. This epic **verifies**
that decision holds and builds the Language screen the chevron needs.

## Why we need it

Nine epics of green CI prove the Dart compiled and the widget tree matched an assertion. They prove
none of the things that get an app rejected, uninstalled or unusable: real font rendering at the
largest system text scale, haptics, whether a Schulte tile is still identifiable in greyscale, first
frame time on cheap silicon, whether a transitive plugin quietly added `android.permission.INTERNET`
to an app whose entire product promise is that it has no network. `ci-pipeline-and-gates` rule 10
requires the pipeline to state what it cannot prove; this epic is the load-bearing manual pass that
covers exactly that gap, and the sign-off artifact is what makes it a release blocker rather than a
chore someone remembers doing.

Without it: the app ships with an unaudited permission set and a Data Safety declaration nobody can
defend from the repo; the "Language" row is a dead chevron a reviewer will tap; the release is built
without `--split-debug-info`, so the first crash report from a real user is permanently unreadable;
and there is no recorded baseline, so the v1.1 size and cold-start numbers can regress with nothing
to regress *against*.

## Current state

Verified with `ls` on 2026-08-19, before E01–E09 have run:

- **No Flutter app.** No `pubspec.yaml`, no `lib/`, no `test/`, no `android/`, no `ios/`, no
  `.github/`. Four commits on `main` (`cb1c3e2`, `4e7e988`, `e8e0f3a`, `2b6fff1`).
- `.claude/skills/` — 45 skills. 49 gate scripts under `.claude/skills/*/scripts/*.sh`, including
  `release-and-store-shipping/scripts/check-release-hygiene.sh` (usage: `[PROJECT_DIR]`, default
  `.`) and `release-and-store-shipping/scripts/check-ipa-slices.sh` (usage: `[IPA_PATH]`, default
  the newest under `build/ios/ipa/`). `design-review-workflow` and `accessibility-as-code` ship
  **no** scripts — their halves are manual by construction.
- `design/sunburst-pop/` — `system.html`, `app.html`, `README.md`, `capture-screens.sh`,
  `screens/01-home.png` … `screens/08-settings.png`, `screens/README.md`, `screens/contact-sheet.html`.
  All eight PNGs are 390×844 @2×. `screens/README.md` carries the comparison procedure and states
  the limit plainly: these are **end states only**.
- `design/sunburst-pop/app.html:1366` is the Settings "Language / English" row: an `.srow` with a
  label, an `.sv` value of `English` and a chevron glyph — i.e. the mock draws it as a **navigable**
  row, not a static line. Nothing in the repo decides what it navigates to.
- No `design/review/`, no `docs/`, no `store/`, no ADRs.

By the time this epic starts, E01–E09 will have delivered: `pubspec.yaml` + `analysis_options.yaml`
+ `.github/workflows/ci.yml` + `tool/skill_gates.sh` + `l10n.yaml`/`AppLocalizations` +
`docs/decisions/0001-localisation-v1.md` (E01), `lib/theme/` with `SunburstColors`/`SunburstShape`/
`SunburstMotion`/`SunburstType` and `game_accent.dart` (E02), `lib/ui/components/` on `PopSurface`
(E03), `lib/shared/` with `HapticGateway`/`FeedbackService`/`Moment`/`PressPhysics`/`ShakeOnWrong`
(E04), `lib/data/` drift (E05),
`RunNotifier`/`RunPhase`/`GameDefinition`/`BoardSnapshot`/`gameRegistryProvider` (E06), the eight shell
screens under `lib/features/` (E07), and `lib/games/stroop_rush/` + `lib/games/schulte_grid/` (E08,
E09). `test/support/harness.dart` with `Device`, `Device.all` (four presets at DPR 2) and `pumpApp`
exists from **E02**; `test/support/load_app_fonts.dart` and `dart_test.yaml`'s `golden` tag from **E03**.
Verify each of these before starting — do not assume.

## What we will achieve

A reader can tell this epic is done by checking, in order:

1. The Settings Language row is a live control with a real destination — tapping it opens a Language
   screen — and `flutter test` has a test that fails if the row's `onTap` is null.
   `docs/decisions/0001-localisation-v1.md` (written in E01) still describes the shipped tree, proven by
   `test/policy/l10n_posture_test.dart`.
2. `design/review/<date>/` holds **36** stills named `NN-<surface>--scale<one|max>--cvd<off|on>.png`
   plus the motion recordings, and `dart run tool/verify_review_folder.dart design/review/<date>`
   exits 0.
3. `docs/review/design-review-<date>.md` exists: date, reviewer, commit sha, build mode, the 36-row
   matrix inventory, the on-device checklist result, a findings table where every row carries a
   grade and a resolution, and a final line matching `^VERDICT: SIGNED OFF$`. No BLOCKER row is
   unresolved.
4. `docs/release/budgets.md` records, for a named floor device and OS version on a named date:
   cold-start first-frame ms, Schulte-grid p95 UI-thread and raster-thread frame ms, Stroop stimulus
   swap p95 frame ms, download size, and install size. No metric reads `TBD`.
5. `flutter build appbundle --release` produces a merged manifest whose `uses-permission` set is
   **empty**, and `flutter test` proves it.
6. `store/data-safety.md`, `store/listing.md` and `ios/Runner/PrivacyInfo.xcprivacy` exist, agree
   with each other, and contain no absolute privacy claim — a grep test enforces that.
7. `git ls-files` returns no `.jks`, `.p12`, `.p8`, `key.properties` or service-account JSON, and
   `.claude/skills/release-and-store-shipping/scripts/check-release-hygiene.sh .` exits 0.
8. A release `.aab` built with `--obfuscate --split-debug-info=build/symbols/1.0.0+1` is installed
   on the floor device, launched, force-stopped and relaunched, and `build/symbols/1.0.0+1/` is
   archived off-machine.
9. The commit is tagged `v1.0.0+1`.

Explicitly **not** in scope: uploading to Play or TestFlight, the store record, the privacy
questionnaire, the Paid Applications Agreement, and the staged rollout. Those are account-holder
actions with no API (`release-and-store-shipping` rule 14); the epic produces the artifact and the
evidence, a human ships it.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `design-review-workflow` | Owns the whole pass: the matrix, the four grading lenses, BLOCKER/FIX/NOTE, the exactly-one-fix-round rule, the destructive-steps-last ordering, and the dated sign-off artifact's required fields. |
| `release-and-store-shipping` | Owns `version: x.y.z+N` as the only version source, no signing material in git, `--obfuscate --split-debug-info` + archived symbols, the merged-manifest permission assertion, Data Safety / `PrivacyInfo.xcprivacy`, the ban on absolute privacy claims, and the size/cold-start budget rule. Supplies both gate scripts. |
| `accessibility-as-code` | Defines the floor every BLOCKER enforces: `Semantics(button/label)`, a11y flags read from `MediaQuery`, the ban on `withClampedTextScaling`/`textScaleFactor`/`FittedBox`/`ellipsis`, never-colour-alone, 4.5:1 / 3:1 against the composited background, 44px single-tap targets, `OrdinalSortKey`. |
| `widget-golden-and-a11y-testing` | Owns the machine-checkable half: the `Device`/`pumpApp` harness, one `testWidgets` per (device, scale, bold) tuple, the fit assertion `takeException` cannot make, the explicit `getSize` tap-target loop, `isSemantics`, and pure-Dart WCAG/APCA contrast instead of the false-passing `textContrastGuideline`. |
| `flutter-performance` | Owns the measurement discipline for T10.7: profile mode on a real floor device, DevTools, UI **and** raster thread, and the rule that a frame-budget number must be measured, never asserted. |
| `ci-pipeline-and-gates` | Owns wiring `check-release-hygiene.sh`, the permission test and the banned-import test into `.github/workflows/ci.yml` as named contracts, the three-criteria bar for a grep gate, and the requirement that the workflow state what it cannot prove. |
| `dependency-hygiene` | `scripts/audit-deps.sh` walking the resolved transitive tree is the evidence behind the Data Safety declaration; it also separates dev-only tooling (icon/splash generators, `integration_test`) from what reaches the binary. |
| `i18n-rtl-l10n` | The decision task's other option. Supplies the real cost of adopting gen-l10n (template `app_en.arb`, `nullable-getter: false`, ICU plurals, `check_arb_parity.sh`) and the Directional-geometry discipline that must hold either way so the retrofit stays cheap. |
| `sunburst-shell-screens` | Names the eight surfaces, the pause sheet as a state of the play scaffold, and rule 13's comparison order (structure → spacing rhythm → surface construction → type role → sampled hex). |
| `sunburst-game-surfaces` | The colour-blind axis: the flag is captured at round start and drives GENERATION, red→`cbPink`, green→`cbOrange`; and the ≥3-non-hue-channel rule the greyscale check tests. |
| `sunburst-motion-and-haptics` | The eighteen moments, each with a reduce-motion residue, are the checklist for the motion recordings and the on-device Sound-off + Haptics-off + Reduce-motion-on pass. Rule 3's split (transform dropped, fill and shadow kept) is the subtle thing the sweep is looking for. |
| `sunburst-tokens` | Rule 11 (light theme only) is why the sweep matrix has **no** light/dark axis — say so rather than silently omitting it. `check_palette_contrast.sh` recomputes every `// @contrast` pair from the shipped hexes. |
| `app-startup-and-bootstrap` | The cold-start half of T10.7: what `main()` may block on, why the native launch screen is the platform's window background and never a Dart route, and why micro-optimising past "don't block the first frame" is wasted effort. |
| `sunburst-components` | T10.6's fix round is the only place this epic edits `lib/ui/components/`. Any fix there must keep `PopSurface` the one surface constructor, the press law (hit area still, transform moves), the ≥48px floor on the fill box and the hard-shadow-with-zero-blur rule — a "quick" a11y fix that hand-rolls a decoration undoes E03. Also supplies `check_component_hygiene.sh`, which this epic's gate list runs. |

## Tasks

### T10.1 — Verify the localisation posture and make the Language row real

**Goal.** Prove ADR 0001 still describes the shipped tree, and give the Settings "Language" row a real
destination so no chevron leads nowhere.

**Tests first (TDD).**
- `test/features/settings/language_row_test.dart`
  - `isSemantics(label: 'Language', value: 'English', isButton: true, hasEnabledState: true, isEnabled: true, hasTapAction: true)` on the row — a row exposed as static text fails here.
  - Tapping it routes to `/settings/language`; asserted through the router, not `find.byType`.
  - The row's `onTap` is non-null (the explicit no-dead-control assertion).
- `test/features/settings/language_screen_test.dart`
  - The screen renders exactly one option, `English`, and its selected state carries a non-colour channel: a check glyph **and** `Semantics.value` reading `Selected` (`accessibility-as-code` rule 6).
  - `getSize` on the option row is ≥ `kPopMinTarget` (48).
- `test/policy/l10n_posture_test.dart` — **E01 T01.10's file**, extended here rather than re-authored.
  It already pins the adopted posture (`l10n.yaml` present with `nullable-getter: false` and
  `arb-dir: lib/l10n`; `flutter: generate: true`; `lib/l10n/app_en.arb` present; the delegates wired in
  `lib/app.dart`). This task adds the assertions that only make sense once the whole app exists:
  - **no user-facing literal survives outside the ARB** — walk `lib/features/**` and `lib/ui/**`, strip
    comments, and fail on a `Text('…')` or a `semanticLabel: '…'` whose argument is a string literal
    rather than an `AppLocalizations` getter. Accumulate, fail once. This is the assertion that would
    have caught a screen quietly hardcoding a label in E07–E09.
  - **`check_i18n_bans.sh lib` is a CI step** — the Directional-geometry gate is what makes locale two
    a string-extraction job rather than a layout rewrite, and it is meaningful at one locale.
  - the reason string on every expectation cites `docs/decisions/0001-localisation-v1.md`, so re-opening
    the decision reds this test instead of drifting.

**Implementation.** Read `docs/decisions/0001-localisation-v1.md` and confirm it still describes the
tree; if E07–E09 diverged from it, that divergence is a finding for T10.4's table, not a quiet ADR
rewrite. Then build the screen:

- `lib/features/settings/presentation/language_screen.dart` — one option, `English`, selected. That is
  an honest one-option control: `app.html:1366` draws a value plus a chevron, so the row navigates, and
  a row that renders a destination-shaped affordance with no destination is the dead control this task
  exists to remove. Not a fake picker either — there is exactly one locale, and the screen says so.
- The `/settings/language` route on the one `GoRouter` in `lib/routing/`.
- The row wired in `lib/features/settings/presentation/settings_screen.dart`.

**What this task does not do.** It does not re-decide the posture, does not delete ARB files, and does
not add `check_arb_parity.sh` to any gate list — that script needs a sibling `app_*.arb` and exits 2 on
a template-only directory, which is why E01 T01.8 keeps it in `tool/skill_gates.sh`'s skip table with a
measured reason. The one-locale gate that does bite is `nullable-getter: false`: a missing key is a
compile error.

**Files.** `lib/features/settings/presentation/language_screen.dart`,
`lib/features/settings/presentation/settings_screen.dart`, `lib/routing/app_router.dart`,
`lib/l10n/app_en.arb` (the Language screen's two keys),
`test/features/settings/language_row_test.dart`,
`test/features/settings/language_screen_test.dart`,
`test/policy/l10n_posture_test.dart` (extend E01's), `.github/workflows/ci.yml`.

**Skills.** `i18n-rtl-l10n`, `sunburst-shell-screens`, `accessibility-as-code`,
`widget-golden-and-a11y-testing`, `ci-pipeline-and-gates`.

**Screenshot check.** `design/sunburst-pop/screens/08-settings.png` — the Language row must keep the
mock's `.srow` construction: glyph, label, `.sv` value in `textSecondary`, chevron in `ink-3`, and
the group's card gap of 16. The Language screen has **no** reference PNG; it composes existing
`PopSurface` rows only, so any new visual vocabulary there is out of scope and belongs in `app.html`
first.

**Done when.**
- [ ] `docs/decisions/0001-localisation-v1.md` (E01's) still describes the shipped tree; any divergence
      is a graded finding in T10.4, not an ADR edit.
- [ ] Three test files above are green; `l10n_posture_test.dart` fails if a user-facing literal appears
      outside the ARB.
- [ ] The row navigates; **no chevron or card in the app leads nowhere** — the same rule that gave the
      Daily Mix card its destination in E07 T07.5.
- [ ] `check_i18n_bans.sh lib` runs in CI and is clean.

**Commits.**
1. `Add failing tests for a live Settings Language row`
2. `Add LanguageScreen and route the Settings Language row to it`
3. `Extend the l10n posture test to ban user-facing literals outside the ARB`

---

### T10.2 — Complete the app-wide accessibility floor test matrix

**Goal.** Get every machine-checkable part of the a11y floor asserted across all nine surfaces
before a human looks at a single pixel, so the review pass spends its time on what only a human can
see.

**Tests first (TDD).** This task is nothing but tests.
- `test/support/sweep_surfaces.dart` — a `SweepSurface` enum with the nine cases (`home`,
  `gameDetail`, `countdown`, `stroopRush`, `schulteGrid`, `pauseSheet`, `results`, `stats`,
  `settings`) and `pumpSurface(SweepSurface, {TextScaler, bool boldText, bool colourBlind})` built on
  the existing `pumpApp`. One enum, consumed by both this task and T10.3 — two lists of screens
  drift.
- `test/a11y/overflow_matrix_test.dart` — `setUpAll(loadAppFonts)`, then one `testWidgets` per
  (`Device`, scale, bold) tuple over `Device.all` × `[1.0, 1.3, 1.5, 2.0, 3.0]` × `[false, true]`,
  per surface. Never a loop inside a test — overflow reports once per `RenderObject`. Each asserts
  `tester.takeException()` is null **and** a `getRect` fit assertion: the three `HudSlot` values sit
  inside their pills, `scoreHero` sits inside the results pane, and each Settings row label sits
  inside its row.
- `test/a11y/tap_targets_test.dart` — an explicit `getSize` loop over every interactive node on each
  surface, each ≥ `kPopMinTarget` 48. Not `meetsGuideline` — it skips nodes flush with the view edge,
  which is exactly where `PopBottomNav` lives.
- `test/a11y/semantics_test.dart` — exactly one `Semantics(header: true)` per surface with the seven
  h1 strings `sunburst-shell-screens` rule 9 fixes (the play scaffold has none); `isSemantics(...)`
  on every nav tab, toggle, answer key and button; traversal from `simulatedAccessibilityTraversal`
  equals authored `OrdinalSortKey` order, not layout order; the HUD is **not** a `liveRegion`; the
  run-over announcement fires exactly once.
- `test/theme/contrast_test.dart` — pure-Dart WCAG + APCA over every `// @contrast` pair declared on
  `SunburstColors`, plus the chroma-only board-state pairs (`gameSchulte` vs `gameSchulteDeep`,
  `accent` vs `surfaceRaised`) asserted directly.
- `test/a11y/board_state_channels_test.dart` — for every Schulte tile state and every Stroop answer
  key state, assert ≥3 differing non-hue channels by comparing the resolved state descriptor's
  `PopElevation`, translate, ring, border slot and glyph fields. A value comparison, not a pixel one
  — a greyscale golden cannot fail loudly.
- `test/policy/a11y_bans_test.dart` — comment-stripped, structure-anchored grep over `lib/` for
  `withClampedTextScaling`, `textScaleFactor`, `FittedBox`, `TextOverflow.ellipsis`, and
  `copyWith(fontSize:`. Accumulate every offender, fail once, with a reason a stranger understands.

**Implementation.** Only what the tests need: `test/support/sweep_surfaces.dart`, and any missing
`Semantics`/`sortKey`/target-size fix the new tests turn red. A fix that reaches for a clamp, a
`FittedBox` or an ellipsis is the defect, not the fix — change the layout.

**Files.** `test/support/sweep_surfaces.dart`, `test/a11y/overflow_matrix_test.dart`,
`test/a11y/tap_targets_test.dart`, `test/a11y/semantics_test.dart`, `test/theme/contrast_test.dart`,
`test/a11y/board_state_channels_test.dart`, `test/policy/a11y_bans_test.dart`, plus whichever files
under `lib/features/**`, `lib/ui/**` and `lib/games/**` the failures name.

**Skills.** `widget-golden-and-a11y-testing`, `accessibility-as-code`, `sunburst-game-surfaces`,
`sunburst-shell-screens`, `sunburst-tokens`.

**Screenshot check.** n/a (no visual surface — this task adds tests and a11y fixes only; any layout
change it forces is re-compared in T10.3's sweep).

**Done when.**
- [ ] `flutter test --test-randomize-ordering-seed random` green with all seven files present.
- [ ] `.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh` clean — no `takeException()` in a `tearDown`, no `ignoreOverflowErrors`, no assigned `FlutterError.onError` in `test/`.
- [ ] `check_palette_contrast.sh lib/theme/sunburst_colors.dart` clean.
- [ ] The honest-limits paragraph is added to `.github/workflows/ci.yml` as a comment block: CI cannot prove real-font rendering on device, haptics, audio, screen-reader behaviour, or frame timing.

**Commits.**
1. `Add SweepSurface enum and pumpSurface harness for the nine review surfaces`
2. `Add the app-wide overflow, fit and text-scale matrix`
3. `Add explicit tap-target, semantics and traversal assertions`
4. `Add pure-Dart contrast and board-state channel assertions`
5. `Add the a11y banned-construct policy test`
6. `Fix the a11y floor violations the matrix exposed`
7. `State in ci.yml what CI cannot prove`

---

### T10.3 — Build the deterministic review-sweep capture harness

**Goal.** One command produces the whole stills matrix into `design/review/<date>/`, reproducibly,
with a machine-checkable inventory — so the review compares evidence rather than someone's memory of
tapping around.

**Tests first (TDD).**
- `test/policy/review_matrix_test.dart` — pure, no device needed. Asserts `reviewMatrix` in
  `tool/review_matrix.dart` has exactly 36 `ReviewCell(surface, scale, colourBlind)` entries
  (9 surfaces × `{one, max}` × `{off, on}`); every `cell.fileName` is unique and matches
  `^\d\d-[a-z-]+--scale(one|max)--cvd(off|on)\.png$`; the surface list equals `SweepSurface.values`
  from T10.2 (one list, two consumers); and **the eight surfaces that have a reference PNG carry that
  PNG's numeric prefix** — `01-home` … `08-settings`. `pauseSheet` is the ninth and has **no** reference
  (it is a state of the play scaffold, not a screen `capture-screens.sh` renders), so it takes the
  reserved prefix `09-pause-sheet`, and the assertion is scoped to the eight with the `reason:` string
  recording why the ninth is exempt. Asserting all nine against `screens/` would be unsatisfiable.
- `test/policy/review_matrix_test.dart` also asserts the matrix declares **no** theme axis and
  **no** direction axis, each with the reason in the test's `reason:` string — light-theme-only is
  `sunburst-tokens` rule 11, LTR-only is ADR 0001. An omitted axis with no recorded reason is how a
  sweep quietly stops covering something.

**Implementation.**
- `tool/review_matrix.dart` — the `ReviewCell` value type and the `reviewMatrix` const list.
- `integration_test/review_sweep_test.dart` — walks `reviewMatrix`, pumps each cell via
  `pumpSurface` under an `IntegrationTestWidgetsFlutterBinding`, and writes each still with
  `binding.takeScreenshot(cell.fileName)`. Text scale `max` is `TextScaler.linear(2.0)` plus
  `boldText: true`; `colourBlind` is seeded into the in-memory `AppDatabase` before the surface is
  pumped, so it is captured at round start exactly as `sunburst-game-surfaces` rule 4 requires — not
  toggled at paint time.
- `test_driver/review_sweep.dart` — writes the returned bytes to `design/review/<date>/`.
- Run: `flutter drive --driver=test_driver/review_sweep.dart --target=integration_test/review_sweep_test.dart -d <deviceId> --profile`, on a 390×844 logical device.
- `tool/verify_review_folder.dart <dir>` — asserts all 36 files exist and are non-empty, and asserts
  the six surfaces where the gameplay palette never appears (`home`, `gameDetail`, `countdown`,
  `pauseSheet`, `results`, `stats`) render **identically** with the colour-blind palette off and on.
  A difference there means a `play*`/`cb*` slot leaked into chrome — `sunburst-tokens` rule 5 — and is
  a BLOCKER.
  **Compare decoded pixels, not bytes.** The stills come from two separate `flutter drive` passes over
  surfaces that animate (halftone layers, press chrome, the countdown ring), so byte-identity across
  runs is not a property the capture method has — PNG encoding alone can differ. Decode both images and
  assert a **maximum per-pixel channel delta of 0**, with the sweep run under `disableAnimations: true`
  and each surface pumped to a settled frame before capture. That is the same guarantee, stated in
  terms the method can actually deliver; a byte comparison would fail for reasons that are not tier
  violations and get relaxed away.
- `docs/review/sweep-procedure.md` — the exact command, the device, and the two honest limits below.

**Two limits to write down, not paper over.** (a) `flutter drive` needs a VM service, so the stills
are captured in **profile** mode, not release. Profile and release render identically and profile has
no debug banner, but R8/shrinking/obfuscation only exist in release — so the release build is
verified in T10.5 and T10.10 instead, on device, and the sign-off says so. (b) Motion, press physics
and haptics are not stills. They are captured as one screen recording per moment group and judged by
eye; `design/sunburst-pop/screens/README.md` already states screenshots are end states only.

**Files.** `tool/review_matrix.dart`, `tool/verify_review_folder.dart`,
`integration_test/review_sweep_test.dart`, `test_driver/review_sweep.dart`,
`test/policy/review_matrix_test.dart`, `docs/review/sweep-procedure.md`, `pubspec.yaml`
(`integration_test` from the Flutter SDK as a `dev_dependency`).

**Skills.** `design-review-workflow`, `widget-golden-and-a11y-testing`, `sunburst-game-surfaces`,
`sunburst-tokens`, `dependency-hygiene`.

**Screenshot check.** This task *produces* the shots; the comparison happens in T10.4. Verify here
only that a spot-check cell (`01-home--scaleone--cvdoff.png`) is 390×844 at the device's DPR and
sits beside `design/sunburst-pop/screens/01-home.png` at the same size — a capture at the wrong
logical size invalidates all 36.

**Done when.**
- [ ] `flutter test test/policy/review_matrix_test.dart` green.
- [ ] The drive command produces 36 files; `dart run tool/verify_review_folder.dart design/review/<date>` exits 0.
- [ ] `audit-deps.sh` confirms `integration_test` is dev-only and reaches no shipped binary.
- [ ] `docs/review/sweep-procedure.md` names the device, the command and both limits.

**Commits.**
1. `Add the review matrix value type and its 36-cell inventory test`
2. `Add the integration_test sweep harness and driver`
3. `Add tool/verify_review_folder.dart with the cvd pixel-identity assertion`
4. `Document the sweep procedure and its two limits`

---

### T10.4 — Run the sweep and grade every finding

**Goal.** Produce the deduped, graded findings table that the fix round and the sign-off both read
from.

**Tests first (TDD).** Not possible for this task, and saying so is the point: grading is human
judgement over rendered pixels, and no assertion can express "the spacing rhythm is wrong here".
The machine-checkable half already ran — T10.2's suite and every `.claude/skills/*/scripts/*.sh`
gate are a **precondition** for starting this task, per `design-review-workflow` rule 2, never part
of its rubric. Do not re-litigate lint, determinism or layer gates in the findings table.

**Implementation.**
1. Confirm the trigger: E09 merged, CI green on the sweep commit, all gate scripts clean.
2. Capture the 36 stills (T10.3) and one recording per motion moment group: press
   (`buttonPress`/`buttonCommit`), countdown (`countdownBeat`/`runStart`), answers
   (`answerCorrect`/`answerWrong`/`tileFound`/`tileNextCue`), boundaries
   (`streakMilestone`/`timerAlarm`/`runEnd`), results (`resultsReveal`/`personalBest`), chrome
   (`toggleFlip`/`sheetTransition`/`routeTransition`/`difficultySelect`/`homeCardEnter`). Record
   each with reduce-motion **off** and **on**.
3. Compare each of the eight screen cells at scale `one`, cvd `off`, against its reference PNG in
   `design/sunburst-pop/screens/`, in this order: **structure** → **spacing rhythm** → **surface
   construction** (3px ink border, correct hard-shadow step, `blurRadius`/`spreadRadius` 0) → **type
   role** → **sampled hex**. The pause sheet has no reference — judge it against `system.html` §10's
   two-action specification and the `PopSheet` component.
4. Apply the four lenses per surface — floor compliance, identity fidelity, parity-or-better, motion
   moments — and grade every finding BLOCKER / FIX / NOTE. **Every accessibility-floor violation is a
   BLOCKER regardless of how good the screen looks.** Check the reduce-motion recordings against the
   residue column of `sunburst-motion-and-haptics`' catalog: a moment whose residue is "nothing" is a
   BLOCKER; the press keeping its `(1,1)` shadow and deep fill while dropping its transform is the
   specific thing to look for.
5. Consolidate into one deduped table in `docs/review/design-review-<date>.md`: id, surface, cell,
   grade, what is wrong, expected source (`system.html` §, `app.html` line, or reference PNG).

**Files.** `docs/review/design-review-<date>.md`, `design/review/<date>/` (36 stills + recordings).

**Skills.** `design-review-workflow`, `accessibility-as-code`, `sunburst-shell-screens`,
`sunburst-game-surfaces`, `sunburst-motion-and-haptics`, `sunburst-tokens`.

**Screenshot check.** All eight: `01-home.png`, `02-game-detail.png`, `03-countdown.png`,
`04-stroop-rush.png`, `05-schulte-grid.png`, `06-results.png`, `07-stats.png`, `08-settings.png`.
A difference is an implementation defect. If a reference is genuinely wrong, edit
`design/sunburst-pop/app.html`, re-run `design/sunburst-pop/capture-screens.sh`, and commit the
regenerated PNGs as a deliberate design change in its own commit — never let code and reference
drift silently.

**Done when.**
- [ ] All 36 stills and every motion recording exist under `design/review/<date>/`.
- [ ] Each of the eight screens has a written comparison result against its PNG, in the five-step order.
- [ ] Every finding has an id, a grade and a source; no finding is ungraded.
- [ ] Every floor violation is graded BLOCKER; no aesthetic argument downgrades one.
- [ ] Any reference change is a separate commit containing both the `app.html` edit and the regenerated PNGs.

**Commits.**
1. `Capture the 36-cell review sweep and the motion recordings`
2. `Add the graded findings table for the <date> design review`
3. *(only if a reference is genuinely wrong)* `Correct app.html <screen> and regenerate the reference screens`

---

### T10.5 — On-device pass on real floor hardware

**Goal.** Prove the things a simulator cannot: real fonts, haptics, screen reader traversal, system
font + bold + display zoom, and the data-safety behaviours — on cheap target-class hardware in its
real state, with the destructive steps last.

**Tests first (TDD).** The pass itself is manual — no test can drive TalkBack or feel a haptic. What
*is* testable is the artifact's completeness, and that is written first:
- `test/policy/on_device_checklist_test.dart` — asserts `docs/review/on-device-checklist.md`
  contains every required section heading (device header, reader traversal, switch access, text
  scale + bold + display zoom, feedback-channels matrix, colour-blind runs, fresh-install persistence,
  crash-log line of sight), and that the executed copy at `design/review/<date>/on-device.md` has a
  filled device/OS/date/build header and **zero** unticked `- [ ]` boxes. It fails while the pass is
  incomplete, which is the behaviour we want. There is **no export/import section**: v1 ships no
  export path (see below), and a checklist heading for a feature that does not exist is a box someone
  ticks without doing anything.

**Implementation.** Run on the release build where possible (install the `.aab` via Play internal
app sharing or `bundletool`); note in the header which build mode each section was run in.
Non-destructive first:
1. **Screen reader traversal** — TalkBack (Android) and VoiceOver (iOS) over Home → Game detail →
   Countdown → both boards → Pause → Results → Stats → Settings → Language. Every interactive
   element reachable and correctly labelled; no focus trap; the run-over announcement speaks the
   whole outcome sentence once, and the HUD does not re-read every tick.
2. **Switch access / Switch Control** — the same walk. `accessibility-as-code` is explicit that
   Flutter publishes no support statement and no API simulates scanning, so a device pass is the
   only evidence that exists.
3. **Largest system font + bold text + display zoom** on the smallest device — nothing clipped,
   the HUD reflows 3-across → 2+1 above scale 1.3, Results and Stats scroll.
4. **The feedback-channel matrix** — all eight combinations of Sound / Haptics / Reduce motion.
   `sunburst-motion-and-haptics` rule 8 says all-three-off is a supported configuration: walk one
   full Stroop run and one full Schulte run in it and confirm every moment still lands. Confirm
   `heavyImpact` fires exactly once, on `personalBest`, and that no boundary haptic (`timerAlarm`,
   `streakMilestone`) buzzes continuously — the unlatched-boundary bug is invisible on a simulator.
5. **Colour-blind palette on** — a full run of each game, confirming the answer set is generated
   from the four-colour live set and no two live keys share a `PlayFill`.
Destructive, last:
6. **Fresh install → create data → force-stop → relaunch → data intact**, then clear app data and
   confirm a clean first run. There is **no previous release** to upgrade from, so the
   upgrade-over-previous-version rehearsal has nothing to rehearse; record that plainly in the header
   and note that the real migration rehearsal is a v1.1 precondition (E05 built the harness for it).
7. **Crash-log line of sight** — trigger a known crash on the obfuscated build, capture the trace from
   the platform log (`adb logcat` / Console.app — v1 has no in-app crash sink and no export path, so
   the device log *is* the channel), symbolize with
   `flutter symbolize -i crash.txt -d build/symbols/1.0.0+1/app.android-arm64.symbols`, and confirm
   readable frames and that the trace carries no user content.
   *(Depends on T10.8's symbols existing — run this step after T10.8 if the ordering demands it.)*

**Two things this pass deliberately does not exercise, because v1 does not ship them.** Export → wipe →
import: E05's Definition of done lists "any backup/export path" under deliberately-left-out, E07's
Settings screen has four toggles and a Language row and no export control, and `data-export-and-restore`
is out of scope for v1. A durable on-device crash sink: E01 T01.7 deferred it (there was nowhere to
write until E05 opened the database) and E05 did not pick it up. Both are recorded in this epic's
"deliberately left out" and in `docs/release/notes-1.0.0.md` as v1.1 candidates. Testing a feature the
app does not have is how a checklist starts lying.

**Files.** `docs/review/on-device-checklist.md` (the template),
`design/review/<date>/on-device.md` (the executed copy),
`test/policy/on_device_checklist_test.dart`.

**Skills.** `design-review-workflow`, `accessibility-as-code`, `sunburst-motion-and-haptics`,
`sunburst-game-surfaces`, `release-and-store-shipping`.

**Screenshot check.** n/a (no visual surface — device photos of any failure go into
`design/review/<date>/` alongside the finding, but there is nothing to compare against a reference
PNG here).

**Done when.**
- [ ] `design/review/<date>/on-device.md` names device model, OS version, build mode and date, and has zero unticked boxes.
- [ ] `test/policy/on_device_checklist_test.dart` green.
- [ ] Every failure found is appended to T10.4's findings table with a grade.
- [ ] The missing-previous-release substitution is recorded, not silently skipped.
- [ ] Export/import and the durable crash sink are recorded as **not shipped in v1**, in this epic's
      "deliberately left out" and in the release notes — not as unticked boxes.

**Commits.**
1. `Add the on-device pass checklist template and its completeness test`
2. `Record the <date> on-device pass results`
3. `Append on-device findings to the design review table`

---

### T10.6 — The single scoped fix round

**Goal.** Fix every BLOCKER and every FIX as one unit, prove each fix, re-shoot only the affected
cells, and open no new critique.

**Tests first (TDD).** Per finding, before its fix:
- Machine-observable findings (contrast, tap target, overflow at scale, missing `Semantics`, a
  colour-only state, a permission, a raw token value) get a **failing** assertion added to the file
  that owns that class — `test/a11y/*`, `test/theme/contrast_test.dart`, `test/policy/*` — named
  after the finding id, e.g. `test('F-07: schulte next-tile ring survives greyscale', …)`.
- Purely optical findings (spacing rhythm, a wrong shadow step, a type role) cannot be asserted;
  their proof is the re-shot cell placed beside the reference. Say which findings fall in this class
  in the review doc rather than inventing a test that asserts nothing.

**Implementation.** One round. Fix BLOCKERs and FIXes together; NOTEs go to a backlog list at the
bottom of the review doc and are not touched. Re-run `flutter test` and every gate script. Re-shoot
**only** the affected cells by running the drive command and overwriting those files — the review
folder stays one truth. Verify each finding against its new shot and mark it resolved in the table.
Any new observation made during verification becomes a NOTE, never a new FIX. A BLOCKER that
survives the round means **no sign-off** and an escalation written into the verdict line — not a
second round.

**Files.** Whatever `lib/**` files the findings name; the affected files under
`design/review/<date>/`; `docs/review/design-review-<date>.md` (resolutions column);
`test/a11y/*`, `test/theme/contrast_test.dart`, `test/policy/*`.

**Skills.** `design-review-workflow`, `accessibility-as-code`, `widget-golden-and-a11y-testing`,
`sunburst-components` (a fix that reaches into `lib/ui/components/` must keep `PopSurface` the only
surface constructor and the press law intact), `sunburst-shell-screens`, `sunburst-game-surfaces`.

**Screenshot check.** Only the re-shot cells, each against its reference PNG in
`design/sunburst-pop/screens/`, in the same five-step order. `dart run tool/verify_review_folder.dart
design/review/<date>` must still exit 0 afterwards — including the cvd pixel-identity assertion, which
a careless fix can break.

**Done when.**
- [ ] Every BLOCKER and FIX has a resolution in the table; every NOTE is in the backlog list untouched.
- [ ] Every machine-observable finding has a test that failed before the fix and passes after.
- [ ] Affected cells re-shot and overwritten; `verify_review_folder.dart` exits 0.
- [ ] `flutter test`, `flutter analyze --fatal-infos --fatal-warnings`, `dart format --set-exit-if-changed .` and every gate script green.
- [ ] No second round opened; any surviving BLOCKER is escalated in writing.

**Commits.** One per finding or per tight group of findings, each carrying its test:
1. `Add failing test for <finding id> and fix it` (repeat)
2. `Re-shoot the review cells affected by the fix round`
3. `Mark fix-round findings resolved in the design review`

---

### T10.7 — Performance and size budgets on the floor device

**Goal.** Measure cold start, the two frame-time hot paths and the artifact size in profile/release
on real low-end hardware, and record the numbers as v1's baseline.

**Tests first (TDD).**
- `test/policy/budgets_test.dart` — parses `docs/release/budgets.md` and asserts: a header naming
  device model, OS version, build mode and date; exactly six named metrics present
  (`cold_start_first_frame_ms`, `schulte_ui_p95_ms`, `schulte_raster_p95_ms`,
  `stroop_stimulus_p95_ms`, `download_size_bytes`, `install_size_bytes`); each has a numeric value
  and a unit; no value is `TBD`; and every metric carries a `budget` alongside its `measured`.
  This test cannot verify the numbers are *true* — only that a release cannot proceed with the file
  half-filled. Say that in the test's `reason:`.

**Implementation.**
```bash
flutter run --profile --trace-startup -d <floorDeviceId>   # build/start_up_info.json
flutter build appbundle --release --analyze-size
```
- Cold start: read `timeToFirstFrameMicros` from `build/start_up_info.json`, three runs after a
  force-stop, record the median. `app-startup-and-bootstrap`'s anti-pattern list applies: the only
  lever we own is not blocking the first frame — zygote fork and VM snapshot load are the
  platform's. If the number is bad, look for an `await` that crept into `main()` past `bootstrap()`,
  not for a micro-optimisation.
- Frame times: DevTools → Performance, profile mode, recording a full Schulte run and a full Stroop
  run. Record **UI thread and raster thread** p95 separately — the play band's ray layers and the
  three-pass stimulus paint cost shows on raster, not in Dart. Confirm the board sits under a
  `RepaintBoundary` (`sunburst-shell-screens` puts one around `buildBoard`) so a HUD tick does not
  re-raster it.
- Size: `--analyze-size` output by library and asset; record download and install size. Fonts
  (Fredoka + Nunito, four faces) are the largest asset line — confirm no unused weight ships.
- Write `docs/release/budgets.md`. There is no previous release, so **v1's measured numbers are the
  budget**: record `measured` and set `budget` to measured + 10% headroom, and state that a v1.1
  regression past it is a release blocker, not a note.

**Files.** `docs/release/budgets.md`, `test/policy/budgets_test.dart`, and any `lib/**` change a
measurement forces (each with its own commit and its own before/after number — never an
optimisation without a measurement).

**Skills.** `flutter-performance`, `release-and-store-shipping`, `app-startup-and-bootstrap`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `docs/release/budgets.md` complete; `test/policy/budgets_test.dart` green.
- [ ] Cold start is a median of three force-stopped runs on the named floor device, in profile mode.
- [ ] Frame p95 recorded for UI **and** raster on both game surfaces; the recording is saved beside the numbers.
- [ ] Any optimisation commit names its before and after number.
- [ ] The floor device model and OS version are named in the file, not "a cheap Android".

**Commits.**
1. `Add the release budget file schema test`
2. `Record v1 cold-start, frame-time and size measurements on the floor device`
3. *(optional)* `Reduce <specific cost> on the Schulte board — raster p95 <before> to <after>`

---

### T10.8 — Icon, launch screen, version, signing material and obfuscated symbols

**Goal.** Make the artifact identifiable and reproducible: a real app icon, a native launch screen
in the app's own cream, `version: 1.0.0+1` as the single version source, no signing material
anywhere in git, and an obfuscated build whose symbols are archived.

**Tests first (TDD).**
- `test/policy/release_assets_test.dart`
  - Every Android launcher density exists and is non-empty: `android/app/src/main/res/mipmap-mdpi|hdpi|xhdpi|xxhdpi|xxxhdpi/ic_launcher.png`.
  - Every image entry in `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` names a file
    that exists on disk — a missing size blocks upload with a message that names a device class, not
    a file.
  - The native launch background is `#FFF8EC` (`surface`) in both
    `android/app/src/main/res/values/styles.xml` and
    `ios/Runner/Base.lproj/LaunchScreen.storyboard` — so the platform window, the first Flutter
    frame and every screen are one continuous colour with no flash.
  - No Dart splash: `lib/` contains no route path `/splash` and no widget class matching
    `Splash|Onboarding` (`app-startup-and-bootstrap` anti-pattern — a launch screen is the
    platform's window background, never a route on the critical path).
- `test/policy/version_and_secrets_test.dart`
  - `pubspec.yaml` `version:` matches `^version:\s*\d+\.\d+\.\d+\+\d+\s*$`.
  - No version literal in `android/app/build.gradle(.kts)` or `ios/Runner/Info.plist` — both must
    read the Flutter-generated values.
  - `.gitignore` contains `android/key.properties`, `*.jks`, `*.keystore`, `*.p12`, `*.p8`, and
    `**/*service-account*.json`.
  - `git ls-files` matches none of those patterns. (This duplicates `check-release-hygiene.sh` rule
    1 on purpose — a tracked keystore is unrecoverable, and one of the two gates will always be
    running.)

**Implementation.**
- Design the icon from the Sunburst Pop vocabulary: the wordmark glyph on `accent` `#FFC53D` with
  the 3px ink `#2B1B4D` border read as a die-cut edge. No emoji, no icon font. Generate the
  densities with `flutter_launcher_icons` and the launch screens with `flutter_native_splash`, both
  as **dev_dependencies** — confirm with `audit-deps.sh` that neither reaches the shipped binary.
- Set `version: 1.0.0+1` in `pubspec.yaml`, in its own commit (`release-and-store-shipping` step 2).
- Create `android/key.properties` **outside** the repo and reference it from
  `android/app/build.gradle.kts`; enroll in Play App Signing and keep the upload key separate. Note
  the recovery asymmetry in `docs/release/signing.md`: a lost upload key is recoverable through Play
  support, a lost *app signing* key on an unenrolled app is a permanently dead listing.
- Build with obfuscation and per-build symbols:
  ```bash
  flutter build appbundle --release --obfuscate --split-debug-info=build/symbols/1.0.0+1
  flutter build ipa --release --obfuscate --split-debug-info=build/symbols/1.0.0+1 \
    --export-options-plist=ios/ExportOptions.plist
  ```
  Archive `build/symbols/1.0.0+1/` off-machine **before** anything else happens to it. Run
  `check-ipa-slices.sh` on the IPA before it is ever uploaded.
- Wire `check-release-hygiene.sh .` into `.github/workflows/ci.yml` as a named gate: "no
  unrecoverable release mistake is tracked in the repo".

**Files.** `pubspec.yaml`, `android/app/build.gradle.kts`, `android/app/src/main/res/mipmap-*/`,
`android/app/src/main/res/values/styles.xml`, `ios/Runner/Assets.xcassets/AppIcon.appiconset/`,
`ios/Runner/Base.lproj/LaunchScreen.storyboard`, `ios/ExportOptions.plist`, `.gitignore`,
`docs/release/signing.md`, `test/policy/release_assets_test.dart`,
`test/policy/version_and_secrets_test.dart`, `.github/workflows/ci.yml`.

**Skills.** `release-and-store-shipping`, `app-startup-and-bootstrap`, `sunburst-tokens`,
`dependency-hygiene`, `ci-pipeline-and-gates`.

**Screenshot check.** n/a (no visual surface — the icon and launch screen have no reference PNG in
`design/sunburst-pop/screens/`). Sanity-check by eye instead: the launch screen colour must be
indistinguishable from the first painted frame of `01-home.png`; a visible flash means the two
values disagree.

**Done when.**
- [ ] Both policy tests green; `check-release-hygiene.sh .` exits 0 and runs in CI.
- [ ] Icon renders correctly on both platforms at every density; launch screen shows no colour flash on the floor device.
- [ ] `version: 1.0.0+1` is the only version literal in the repo.
- [ ] `build/symbols/1.0.0+1/` archived off-machine; `check-ipa-slices.sh` exits 0 on the IPA.
- [ ] `audit-deps.sh` exits 0 with the icon/splash generators confirmed dev-only.

**Commits.**
1. `Add release asset, version and secret-handling policy tests`
2. `Add the MindForge app icon at every launcher density`
3. `Set the native launch screen to surface #FFF8EC on both platforms`
4. `Set version to 1.0.0+1`
5. `Ignore signing material and document the Play App Signing posture`
6. `Wire check-release-hygiene.sh into CI`

---

### T10.9 — Permission audit from the merged manifest, and store declarations proved from the repo

**Goal.** Assert, mechanically, that the shipped app requests nothing — and that every sentence in
the store declarations is checkable against this repository.

**Tests first (TDD).**
- `test/policy/permissions_test.dart` — the whole-set assertion, not a forbidden-list one, because
  only a whole-set assertion catches a *newly added* permission from a plugin bump.
  - Android: parse `build/app/intermediates/merged_manifests/release/AndroidManifest.xml`, collect
    every `uses-permission android:name="…"`, and expect the set to equal `<empty>`. Same for
    `uses-feature`. If the merged manifest is absent, fail with "run `flutter build appbundle
    --release` first" — never skip.
  - iOS: parse `ios/Runner/Info.plist` and expect **zero** keys matching `NS.*UsageDescription`.
  - `ios/Runner/PrivacyInfo.xcprivacy`: `NSPrivacyTracking` is `false`, the
    `NSPrivacyTrackingDomains` key is **absent** (present-with-`true` is ITMS-91064; present-at-all
    has a runtime cost), and `NSPrivacyCollectedDataTypes` is an empty array.
- `test/policy/banned_imports_test.dart` — **E01 T01.5's file, extended here, not re-authored.** E01
  already walks `lib/`, strips comments and matches import URIs against the no-network set; this task
  widens the list with `package:grpc/`, `package:device_info_plus/` and anything matching
  `analytics|crashlytics|amplitude|mixpanel`, and sharpens the reason string to name what now depends on
  it: "these break the no-network, no-telemetry promise the Data Safety declaration is built on." Two
  files with two overlapping ban lists is how one of them stops being maintained.
- `test/policy/privacy_claims_test.dart` — grep `store/listing.md`, `store/data-safety.md` and the
  About screen copy for banned absolutes: `nothing ever leaves your device`, `completely private`,
  `100% (private|secure|offline)`, `we can't see anything`, `we never see`. Note that the mock's own
  footer copy, "Train your brain. No wifi needed." (`app.html`), is a *mechanism* statement and
  passes — the test must not flag it, which is the test for the test.

**Implementation.**
- Strip INTERNET explicitly in `android/app/src/main/AndroidManifest.xml`, with the `tools` namespace
  on the root element:
  ```xml
  <uses-permission android:name="android.permission.INTERNET" tools:node="remove" />
  ```
  This is not cosmetic: with the permission gone, an accidental network call fails at runtime instead
  of shipping quietly, which turns "the app has no network access" into a testable claim.
- Read `build/app/outputs/logs/manifest-merger-blame-report.txt` after the release build to see which
  dependency contributed each node; strip anything else that appears, or drop the dependency.
- Write `store/data-safety.md` — every Play Data Safety answer with, beside it, the repo evidence
  that proves it: the empty permission set, the banned-imports test, `audit-deps.sh` output showing
  no telemetry package anywhere in the transitive tree, and the drift database being the only
  storage. "Collect" means transmitted off the device; local storage is not collection, and the
  user-initiated export via the share sheet is a hand-off, not collection — say that in the file.
- Write `store/listing.md` with mechanism copy, not absolutes. The sanctioned shape:
  > Your runs are stored in a database on this device. The app requests no permissions and has no
  > network access, so nothing is uploaded. Exports leave the app only when you tap Share, and go
  > wherever you send them.
- Write `ios/Runner/PrivacyInfo.xcprivacy` with `NSPrivacyTracking = false`, no
  `NSPrivacyTrackingDomains`, empty `NSPrivacyCollectedDataTypes`, and the required-reason API codes
  for whatever drift/`path_provider` actually use (`find ios/Pods -name 'PrivacyInfo.xcprivacy'` and
  transcribe from the SDKs' own manifests — do not reason about them).
- Wire the permission test into the CI **release-build** job (it needs the merged manifest), and the
  import and claims tests into the fast `verify` job.

**Files.** `android/app/src/main/AndroidManifest.xml`, `ios/Runner/Info.plist`,
`ios/Runner/PrivacyInfo.xcprivacy`, `store/data-safety.md`, `store/listing.md`,
`test/policy/permissions_test.dart`, `test/policy/banned_imports_test.dart`,
`test/policy/privacy_claims_test.dart`, `.github/workflows/ci.yml`.

**Skills.** `release-and-store-shipping`, `dependency-hygiene`, `ci-pipeline-and-gates`,
`i18n-rtl-l10n` (claims live as strings and must be flagged so a future translation cannot be
stronger than the source).

**Screenshot check.** n/a (no visual surface). One exception if the About screen copy changes:
re-compare `design/sunburst-pop/screens/08-settings.png` for the Settings footer block, which the
mock renders as `.setfoot` with the wordmark and tagline.

**Done when.**
- [ ] Merged-manifest `uses-permission` set is empty and the test proves it against a real release build.
- [ ] Zero `NS*UsageDescription` keys; `PrivacyInfo.xcprivacy` present and correct.
- [ ] `store/data-safety.md` maps every answer to repo evidence; `store/listing.md` contains no absolute claim.
- [ ] All three policy tests green and wired into the correct CI job.
- [ ] `manifest-merger-blame-report.txt` reviewed; nothing unexpected contributed.

**Commits.**
1. `Add permission, banned-import and privacy-claim policy tests`
2. `Strip android.permission.INTERNET from the merged manifest`
3. `Add PrivacyInfo.xcprivacy declaring no tracking and no collection`
4. `Add store Data Safety and listing copy with repo evidence for every claim`
5. `Run the permission assertion in the CI release-build job`

---

### T10.10 — Sign-off artifact, verified release build, tag

**Goal.** Produce the dated artifact that gates the release, verify the exact shipping build on the
floor device, and tag the commit that ships.

**Tests first (TDD).**
- `test/policy/signoff_test.dart` — parses `docs/review/design-review-<date>.md` and asserts:
  a header with date, reviewer, commit sha (40 hex chars), build mode and device; a matrix inventory
  of exactly 36 rows matching `reviewMatrix`; a findings table where every row has a grade in
  `{BLOCKER, FIX, NOTE}` and a non-empty resolution; **no** row graded BLOCKER whose resolution is
  not `resolved`; and a final line matching
  `^VERDICT: (SIGNED OFF|NOT SIGNED OFF — .+)$`. Release tasks read this file, so a half-written
  sign-off must fail the suite rather than pass silently.

**Implementation.** Run only when a release is explicitly requested by name — building, signing and
tagging are side-effecting and partly irreversible, and a published build number is burned forever.
1. Preconditions: working tree clean; CI green on the release commit; T10.6's fix round closed;
   `docs/release/budgets.md` complete.
2. Write `docs/review/design-review-<date>.md`'s header, inventory, resolutions and verdict line.
3. Rebuild the artifacts with obfuscation and the same `build/symbols/1.0.0+1/` directory (T10.8),
   confirm the symbol archive is off-machine, and run `check-ipa-slices.sh` on the IPA.
4. Install the exact `.aab` on the floor device via `bundletool` (not a local debug/profile build —
   R8, shrinking and stripped asserts only exist here). Walk both games end to end, force-stop,
   relaunch, confirm data intact. Confirm no debug affordance is reachable.
5. Reconcile: merged permission set (T10.9), Data Safety / `PrivacyInfo.xcprivacy` / listing copy
   against the current `pubspec.lock`, and the budgets against the measurements.
6. Tag `v1.0.0+1` on the exact commit and publish release notes.

**Files.** `docs/review/design-review-<date>.md`, `test/policy/signoff_test.dart`,
`docs/release/notes-1.0.0.md`, `build/symbols/1.0.0+1/` (archived off-machine, not committed).

**Skills.** `design-review-workflow`, `release-and-store-shipping`, `ci-pipeline-and-gates`.

**Screenshot check.** n/a (no visual surface — the sweep's comparisons are already recorded in the
inventory this artifact carries).

**Done when.**
- [ ] `test/policy/signoff_test.dart` green; verdict line reads `VERDICT: SIGNED OFF`.
- [ ] No unresolved BLOCKER; NOTEs listed in the backlog section.
- [ ] The exact release `.aab` was installed on the floor device, walked, force-stopped and relaunched.
- [ ] Symbols archived off-machine before any upload; `flutter symbolize` verified against a real crash log (T10.5 step 7).
- [ ] Commit tagged `v1.0.0+1`; release notes published.
- [ ] Upload, store record, privacy questionnaire and staged rollout explicitly recorded as out of scope and pending a human account holder.

**Commits.**
1. `Add the sign-off artifact schema test`
2. `Write the <date> design review sign-off`
3. `Add v1.0.0 release notes`
4. *(on explicit request)* `Tag v1.0.0+1`

## Gates that must pass

```bash
# codegen BEFORE analyze — never after
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random

# every skill gate, through the one runner E01 T01.8 built
bash tool/skill_gates.sh
```

**Not** `for s in .claude/skills/*/scripts/*.sh; do bash "$s" || exit 1; done`. Measured against this
repository, that loop fails on 29 of the 49 scripts: five take a required argument and can never pass
argument-less (`scaffold_feature.sh`, `verify_feature.sh`, `check-ipa-slices.sh`,
`check-flavor-graph.sh`, plus `check_arb_parity.sh` at one locale), five are runners rather than gates
(`regen.sh`, `run_tests.sh`, `ci-gates.sh`, `lint-gates.sh`, `analyze.sh`), and
`check-scheduler-purity.sh` exits 127 on macOS bash 3.2. `tool/skill_gates.sh` carries the run table,
the skip table and a reason per skipped row, and `test/policy/skill_gates_coverage_test.dart` fails if
a script is in neither — which is what makes the sweep a gate instead of noise.

The ones this epic depends on directly, with their real arguments:

```bash
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh          lib/theme/sunburst_colors.dart
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib
.claude/skills/widget-golden-and-a11y-testing/scripts/check-test-hygiene.sh
.claude/skills/testing-strategy/scripts/check_test_hygiene.sh
.claude/skills/dependency-hygiene/scripts/audit-deps.sh                   .
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh
.claude/skills/ci-pipeline-and-gates/scripts/ci-gates.sh
.claude/skills/ci-pipeline-and-gates/scripts/banned-strings.sh
.claude/skills/release-and-store-shipping/scripts/check-release-hygiene.sh .
.claude/skills/release-and-store-shipping/scripts/check-ipa-slices.sh     build/ios/ipa/mindforge.ipa
```

Epic-specific:

```bash
dart run tool/verify_review_folder.dart design/review/<date>   # 36 files, cvd pairs identical
flutter build appbundle --release --analyze-size               # produces the merged manifest + size
flutter run --profile --trace-startup -d <floorDeviceId>       # build/start_up_info.json
```

`check_arb_parity.sh` is **not** in the list, and that is deliberate rather than an oversight: ADR 0001
adopts gen-l10n but ships **one** locale, and the script exits 2 on a directory holding only the
template (`FAIL: no locale ARB files (app_*.arb) beside the template` — verified). It sits in
`tool/skill_gates.sh`'s skip table with that measured reason and moves to the run table the day a second
`app_*.arb` lands. The one-locale gates that *do* run are `check_i18n_bans.sh lib` (Directional geometry)
and `nullable-getter: false` (a missing key is a compile error).

## Risks and open questions

- **No physical floor device.** `design-review-workflow` rule and `flutter-performance` rule 11 both
  require real cheap target-class hardware; an emulator hides memory pressure, real fonts, haptics
  and the budget-silicon frame cost this epic exists to measure. *Decision needed from Zakaria before
  T10.5:* which physical Android (4GB-class, Android 11+, 60Hz) and which older iPhone. If neither
  exists, the honest outcome is `VERDICT: NOT SIGNED OFF — no on-device pass`, not a sign-off with a
  simulator note.
- **Profile-mode stills vs a release-build review.** `flutter drive` needs a VM service, so the 36
  stills are profile, not release. Mitigation: T10.5 and T10.10 both run on the installed release
  `.aab`, and the sign-off states which evidence came from which build mode. Do not describe the
  sweep as a release-build review.
- **`applicationId` / bundle id is forever.** Whatever E01's `flutter create --org` set is fixed for
  the life of the listing; changing it later creates a *new* app and strands every user. *Confirm the
  value with Zakaria before the first upload* — after the first upload it is unfixable.
- **Account-holder-only store gates have no API.** The app record, the privacy questionnaire and the
  Paid Applications Agreement block submission and need a human. Raise them on day one of this epic,
  not at the end; they are why "upload" is out of scope here.
- **`flutter_launcher_icons` / `flutter_native_splash` are third-party build tooling.** Dev-only, so
  they never reach the binary, but they write into `android/` and `ios/`. Decision: run them once,
  commit the *generated assets*, and treat the generators as reproducible tooling — not as something
  the build depends on. `audit-deps.sh` must confirm dev-only placement.
- **The 36-cell matrix omits a dark-theme axis and an RTL axis.** Both omissions are deliberate and
  recorded (`sunburst-tokens` rule 11; ADR 0001's one-locale, LTR posture) and asserted in
  `test/policy/review_matrix_test.dart`. Risk: a future dark mode or locale silently inherits a sweep
  that never covered it. Mitigation: the test's `reason:` string names the ADR, so re-opening either
  decision reds the matrix test.
- **Two v1 omissions the checklist must not pretend to cover.** There is no export/import path (E05's
  Definition of done lists it as left out; E07's Settings screen has no export row) and no durable
  on-device crash sink (E01 T01.7 deferred it; E05 did not pick it up). T10.5 tests neither and records
  both, and `docs/release/notes-1.0.0.md` carries them as v1.1 candidates. If either should ship in v1,
  that is two new tasks in E05 and E07 — raise it before T10.5, not during it.
- **The colour-blind identity assertion is deliberately strict, and deliberately not a byte compare.**
  If any chrome surface legitimately reads a gameplay slot — it should not, per `sunburst-tokens` rule
  5 — it fails on six surfaces at once. Treat a failure as a tier violation to fix, not a test to relax;
  a genuinely legitimate exception is recorded in the review doc with its reason, never silently removed
  from `verify_review_folder.dart`. The comparison is max-per-pixel-delta-0 on **decoded** images with
  animations disabled and each surface settled, because two `flutter drive` passes over animated
  surfaces cannot promise identical PNG bytes and a strictness nobody can satisfy gets deleted rather
  than honoured.
- **No previous release to upgrade from.** The data-safety rehearsal loses its most valuable step.
  Recorded in T10.5; the real migration rehearsal becomes a v1.1 precondition, written into
  `docs/release/notes-1.0.0.md` so it is not forgotten.

## Definition of done

- [ ] Branch `epic/10-accessibility-qa-and-release` cut off `main`; granular commits, tests committed with the code they cover.
- [ ] ADR 0001 (E01's) verified against the shipped tree; the Settings Language row navigates to a real
      destination; no dead control ships anywhere, including Home's Daily Mix card.
- [ ] T10.2's a11y floor suite green across all nine surfaces at every (device, scale, bold) tuple.
- [ ] 36 stills + motion recordings captured; `verify_review_folder.dart` exits 0.
- [ ] All eight screens compared against `design/sunburst-pop/screens/*.png` in the five-step order; every reference change is a committed `app.html` edit plus regenerated PNGs.
- [ ] On-device pass executed on named floor hardware with zero unticked boxes; destructive steps ran last.
- [ ] Every finding graded; every floor violation graded BLOCKER; exactly one fix round; no surviving BLOCKER.
- [ ] `docs/release/budgets.md` complete with measured values and budgets on named hardware.
- [ ] Merged Android manifest requests nothing; zero `NS*UsageDescription`; `PrivacyInfo.xcprivacy` declares no tracking and no collection — all three asserted by tests.
- [ ] `store/data-safety.md` and `store/listing.md` written, every claim backed by repo evidence, no absolute privacy claim.
- [ ] No signing material tracked; `check-release-hygiene.sh .` and `check-ipa-slices.sh` exit 0.
- [ ] Release built `--obfuscate --split-debug-info=build/symbols/1.0.0+1`; symbols archived off-machine; a real crash log symbolized successfully.
- [ ] `docs/review/design-review-<date>.md` signed off; `test/policy/signoff_test.dart` green.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] All gates green: `dart format --set-exit-if-changed .`, `flutter analyze --fatal-infos`,
      `flutter test`, `bash tool/skill_gates.sh`.
- [ ] PR opened explaining what changed, why, how it was verified, which screens were compared, and what
      was deliberately left out: store upload, staged rollout, a second locale, dark mode, the migration
      rehearsal, **export/import and the durable crash sink**.
- [ ] CI green on the PR; merged preserving the granular commits; branch deleted; back on `main` and pulled.
- [ ] Commit tagged `v1.0.0+1` on explicit request.
