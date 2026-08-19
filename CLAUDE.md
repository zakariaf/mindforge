# MindForge

Offline brain-training app in Flutter. It is an **engine**, not one game: a single codebase ships
many small games. Everything except the board rectangle — home, game detail, difficulty select,
countdown, play scaffold, pause, results, stats, settings — is written once and shared. A new game
supplies its rules, one board widget and one accent colour, and inherits every screen.

First two games: **Stroop Rush** (tap the colour the word is *printed* in) and **Schulte Grid**
(tap 1..25 ascending, fast). Schulte is the proof: it must ship without editing `lib/features/**`.

## Hard product constraints

These are the easiest thing to break by adding one package. Check them before `dart pub add`.

| Constraint | In code |
|---|---|
| Fully offline | No `http`/`dio`/`web_socket`/remote config/`google_fonts`. **No network code at all.** |
| No accounts | No auth, no identity, no cloud sync. Ids are local. |
| No ads, no IAP | Nothing to monetize. `ads-and-iap-monetization` exists in the library and is out of scope. |
| No analytics, no crash reporting | Zero telemetry packages. No user data leaves the device, ever. |
| On-device storage only | drift/SQLite under `lib/data/`. The only exit path is a user-initiated export/share. |
| Bundled fonts | Fredoka + Nunito ship as assets. Runtime font fetching is a network call. |

If a feature appears to require the network, it is the wrong feature.

## Current state (as of 2026-08-19)

**The Flutter app is not scaffolded yet.** There is no `pubspec.yaml`, no `lib/`, no `test/`.
Three commits so far: convention skills, three candidate design systems, Sunburst Pop screenshots.

```
.claude/skills/                   45 skills — 40 general Flutter/Dart conventions + 5 sunburst-*
design/index.html                 the three-direction picker
design/sunburst-pop/              CHOSEN — system.html, app.html, README.md, screens/*.png, capture-screens.sh
design/cotton-cloud/              rejected alternative, kept for reference
design/paper-crayon/              rejected alternative, kept for reference
50-apps-challenge-slides.html     episode slides
```

**Next step:** scaffold the app — `flutter create`, a pinned `pubspec.yaml`, `analysis_options.yaml`
on `very_good_analysis` — then build `lib/theme/` by transcribing `design/sunburst-pop/system.html`
per `sunburst-tokens`. The theme layer comes before any screen, because every screen reads it.

## Architecture we are building toward

**One Flutter package.** Do not create `packages/` until a body of pure logic earns the compile wall
(`project-structure-and-packages` rule 1).

```
lib/
  main.dart          thin; calls bootstrap()
  theme/             SunburstColors / SunburstShape / SunburstMotion / SunburstType + game_accent.dart
                     — the ONLY directory where a raw aesthetic value may appear
  ui/components/     PopSurface and the chunky component catalog built on it
  ui/glyphs/         inline stroke icons (2.6 and 3.0 weights). No emoji, no icon font
  features/          the 8 shell screens
  games/             one folder per game: rules + board widget, nothing else
  data/              drift database, DAOs, repositories
  shared/feedback/   HapticGateway + FeedbackService — the only HapticFeedback call sites
  routing/           one GoRouter
test/                mirrors lib/
```

Decisions, not a tutorial:

- **The shell owns every pixel outside the board.** A game contributes a `GameDefinition`
  (`id`, `accent`, `scoreFormat`, `difficulties`, `boardBackground`, `buildBoard`, `buildArtwork`,
  `snapshotOf`) plus a board widget and a `BoardSnapshot`. Home cards, BEST pills, difficulty lists
  and score formatting are **data read off the registry**, never a `switch (gameId)` in a shell file.
- **`lib/games/**` is fenced.** No `go_router` import, no `Navigator`, no `Scaffold`/`AppBar`/`HudPill`,
  no `Color(0x…)`, no run timer of its own.
- **`RunNotifier` owns the run**: the `RunPhase` machine (`idle → countdown → playing → paused → over`)
  and the single injected `Clock`. Boards report outcomes into a snapshot; only the shell navigates.
- **Riverpod 3.x is both state and DI.** `Notifier`/`AsyncNotifier`/`StreamNotifier` over immutable
  state; no `get_it`, no `package:provider`, no legacy providers.
- **Repository is the single write path** — persist first, then republish through a watched stream.
- **Typed errors**: recoverable I/O returns a sealed `Result<T, F extends Failure>`, switched
  exhaustively. Nothing recoverable throws.

## Design direction — Sunburst Pop

Arcade-cabinet joy. Chunky, physical, high-energy; everything looks pressable. The signature
construction rule: **every raised surface is a fill, a 3px solid ink (`#2B1B4D`) border, and one hard
offset shadow with `blurRadius` and `spreadRadius` at 0** — and it translates down on press while its
hit area holds still. Saturated pop colours on cream, Fredoka for display, Nunito for body. Light
theme only; there is no dark mode and adding one is a new design direction, not a token flip.

| Source | Authoritative over |
|---|---|
| `design/sunburst-pop/system.html` | **Token values.** Every hex, radius, shadow offset, duration, curve and type step. |
| `design/sunburst-pop/app.html` | Layout, spacing rhythm and component usage across the 8 screens. |
| `design/sunburst-pop/screens/*.png` | Implementation targets, rendered at 390×844 @2x. |
| `design/sunburst-pop/README.md` | Rationale, palette table, and the known risks. |

Read `system.html` before changing a value. Do not use a colour from memory and do not "improve" one.
A value it does not contain is **DERIVED** and must be marked as such at the point of use.

## Skill routing

`flutter-conventions-index` is the front door: it carries the 14 cross-cutting house rules and routes
to all 45 skills. **Open it first for anything non-trivial**; this table is only the traffic MindForge
actually generates.

| When you are… | Load |
|---|---|
| Unsure which skill governs the task | `flutter-conventions-index` |
| Touching a colour, radius, shadow, duration, curve or type step; editing `lib/theme/**` | `sunburst-tokens` |
| Building a button, card, tile, HUD pill, toggle, sheet, nav bar; press chrome; focus ring | `sunburst-components` |
| Building one of the 8 shell screens, the HUD, or the run lifecycle | `sunburst-shell-screens` |
| Adding a game; board/tile/stimulus states; picking an accent; the colour-blind palette | `sunburst-game-surfaces` |
| Adding an animation, haptic, countdown, correct/wrong response or celebration | `sunburst-motion-and-haptics` |
| Deciding which layer or folder a file belongs in | `flutter-architecture`, `project-structure-and-packages` |
| Standing up a new feature folder end to end | `scaffold-feature-module` |
| Writing a Notifier/provider, wiring DI, the single write path | `state-management-riverpod` |
| Writing `build()`, splitting widgets, grid/list layout | `widget-composition` |
| Routes, the bottom-nav shell, back handling | `navigation-and-routing` |
| Drift tables, DAOs, `.watch` streams / a schema migration | `persistence-drift` / `run-migration` |
| Modeling `Result`/`Failure`, never-lose-data flows | `error-handling-typed-results` |
| Writing `main()`/`bootstrap()`, error handlers, lifecycle flush | `app-startup-and-bootstrap` |
| Semantics, tap targets, contrast, text scaling | `accessibility-as-code` |
| Golden, layout, RTL or a11y widget tests / re-baselining goldens | `widget-golden-and-a11y-testing` / `run-goldens-rebaseline` |
| Unit tests, fakes, invariants | `testing-strategy` |
| Generating a round from a seed every device must reproduce | `seeded-determinism-and-golden-vectors` |
| Injecting the `Clock` or any platform side effect | `service-boundary-and-native` |
| Painting a board on a canvas with custom hit-testing | `custom-canvas-and-gestures` |
| Editing `pubspec.yaml`, auditing a new dependency | `dependency-hygiene` |
| `build.yaml`, generated code / running codegen | `codegen-and-toolchain` / `run-codegen` |
| `analysis_options.yaml`, lint severity | `lint-and-style-config` |
| GitHub Actions gates | `ci-pipeline-and-gates` |
| The end-of-build design/QA sweep, then shipping | `design-review-workflow`, `release-and-store-shipping` |

Generic siblings own the **mechanism**, the `sunburst-*` skills own the **values**:
`design-system-structure` owns how a `ThemeExtension` is built, `sunburst-tokens` fixes what it
carries; `motion-and-haptics` owns the moment-catalog discipline, `sunburst-motion-and-haptics` names
the eighteen moments. Read the generic one for the pattern, the sunburst one for the number.

## Working agreements

1. **Light theme only.** No `darkTheme:`, no `themeMode`, no `Brightness.dark` `ColorScheme`.
2. **No raw aesthetic values outside `lib/theme/`.** A missing value is a new named slot, never an
   `// ignore:`. Adding a slot touches field + constructor, `copyWith`, `lerp`, and the const instance.
3. **Gameplay colours are a separate tier from UI colours and never cross.** `danger` wires to the
   primitive, not to the `playRed` slot — the colour-blind setting re-points answer slots, and an
   alarm aliased to a gameplay slot would turn magenta for exactly the players who need it.
4. **Hue is never the only channel.** Every answer colour also carries an ink fill pattern
   (solid / stripe / dot / ring), on the key and inside the stimulus glyph.
5. **Fonts are bundled, never fetched.** No `google_fonts`, no runtime HTTP for assets.
6. **No emoji anywhere** — not in the UI, not in code, comments or commit messages. Icons are inline
   stroke glyphs at 2.6 (22px nav/status) and 3.0 (18–20px inside buttons).
7. **Reduced motion collapses durations to `Duration.zero`,** never to shorter ones. Every moment
   carries a non-motion residue that survives Sound off + Haptics off + Reduce motion on.
8. **Read "now" from the injected `Clock`.** `DateTime.now()` in domain code is a defect.
9. **Compare every built screen against `design/sunburst-pop/screens/*.png`** before calling it done.
   A difference is an implementation defect. If the reference is genuinely wrong, edit `app.html`,
   re-run `capture-screens.sh`, and commit that as a deliberate design change.
10. **The sanctioned gate set passes before a commit — via `tool/skill_gates.sh`, not a glob.**
    The six `sunburst-*` gates take an optional target dir (default `lib`) and exit 0 cleanly when it
    is absent. The wider library does **not**: of the 49 scripts under `.claude/skills/*/scripts/`,
    only 20 pass when run argument-less — five require an argument, five are runners rather than
    gates, and one uses `mapfile` and exits 127 on macOS system bash 3.2. So never write
    `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`. E01 builds `tool/skill_gates.sh`
    with an explicit run table and a skip table carrying a reason per row, plus
    `test/policy/skill_gates_coverage_test.dart` which fails if a script appears in neither.
    Until that exists, run the six sunburst gates by name.

## Commands

**Everything in this section applies once the app is scaffolded. There is no `pubspec.yaml` today.**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # ALWAYS before analyze
dart format --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test
```

Design gates — these run today and pass (nothing to scan):

```bash
# these five take a target dir (default: lib)
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh     lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh   lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh       lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh lib

# this one takes a theme FILE (default: lib/theme/sunburst_colors.dart), not a dir
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh
```

`check_palette_contrast.sh` recomputes WCAG ratios from the hexes in the source for every pair the
theme declares in a `// @contrast <fg> <bg> <min>` comment, and fails on an unresolvable name rather
than skipping it. Run it against the worked example to see it pass over 26 pairs:

```bash
.claude/skills/sunburst-tokens/scripts/check_palette_contrast.sh \
  .claude/skills/sunburst-tokens/examples/sunburst_theme.dart
```

Architecture and hygiene gates live beside them — `flutter-architecture/scripts/check_architecture.sh`,
`project-structure-and-packages/scripts/check_import_boundaries.sh`,
`state-management-riverpod/scripts/ban-legacy-providers.sh`,
`design-system-structure/scripts/check_font_bundling.sh`, and the rest under
`.claude/skills/*/scripts/`. Run them **by name**, or through `tool/skill_gates.sh` once E01 lands —
globbing the directory does not work (working agreement 10).

## Build order

Ten epics, one branch and one PR each, in `epics/`. Read `epics/README.md` for the dependency graph,
the delivery loop and the screenshot rule before starting any of them.

Regenerate the reference screenshots after editing `app.html`:

```bash
cd design/sunburst-pop && ./capture-screens.sh    # rewrites screens/*.png; commit them with the change
```
