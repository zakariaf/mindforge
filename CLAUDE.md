# MindForge

Offline brain-training app in Flutter. It is an **engine**, not one game: a single codebase ships
many small games. Everything except the board rectangle — home, game detail, difficulty select,
countdown, play scaffold, pause, results, stats, settings — is written once and shared. A new game
supplies its rules, one board widget and one accent colour, and inherits every screen.

First two games: **Stroop Rush** (tap the colour the word is *printed* in) and **Schulte Grid**
(tap 1..25 ascending, fast). Schulte is the proof: it must ship without editing `lib/features/**`.

It ships in **four locales, two of them right-to-left** — English, German, Persian and Kurdish Sorani —
on **iOS only**. Neither is a bolt-on: RTL reaches every component's geometry and Eastern Arabic
numerals reach the Schulte tiles, which *are* the numbers 1..25.

## Hard product constraints

These are the easiest thing to break by adding one package. Check them before `dart pub add`.

| Constraint | In code |
|---|---|
| Fully offline | No `http`/`dio`/`web_socket`/remote config/`google_fonts`. **No network code at all.** |
| No accounts | No auth, no identity, no cloud sync. Ids are local. |
| No ads, no IAP | Nothing to monetize. `ads-and-iap-monetization` exists in the library and is out of scope. |
| No analytics, no crash reporting | Zero telemetry packages. No user data leaves the device, ever. |
| On-device storage only | drift/SQLite under `lib/data/`. The only exit path is a user-initiated export/share. |
| Bundled fonts | Fredoka + Nunito (Latin) **and Vazirmatn + one Arabic-script display face** ship as assets, each with its SIL OFL text registered through `registerSunburstFontLicences()`. Runtime font fetching is a network call. |
| Four locales, two RTL | `en` (template, and the fallback), `de`, `fa`, `ckb`. System locale if supported, else `en`; the user's override persists in `settings.locale_tag`. `lib/core/supported_locale.dart` is the only list of shipped locales in the repo. |
| iOS only | Android is **deferred by decision, not oversight** — no `android/` target, no `values-*` resources, no claim of parity. Build and run on the canonical simulator `MindForge iPhone 14`, UDID `C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, which is **exactly 390x844** and therefore the only device a reference screenshot can honestly be compared on (iPhone 16 is 393x852, 16 Pro is 402x874). |

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

**Verified toolchain on this machine (2026-08-19). Do not re-derive; do re-assert in a test.**

| Fact | Value |
|---|---|
| Flutter / Dart / DevTools | 3.44.6 stable · Dart 3.12.2 · DevTools 2.57.0 |
| Xcode / CocoaPods | 26.6 (build 17F113) · 1.15.2 |
| Simulator runtimes | iOS 18.0, 18.6, 26.5 |
| Canonical device | `MindForge iPhone 14` · `C13DDC02-375D-4E1B-8F81-44EB407D09A4` · iOS 18.6 · 390x844 |
| `intl` | `0.20.2` — an **exact** pin inside `flutter_localizations`, not a range |
| `ckb` in `GlobalMaterialLocalizations` | **absent** (82 codes; `en` `de` `fa` `ar` present). A custom delegate trio is required or a switch to Sorani throws — and silently renders LTR. |

**Next step:** scaffold the app — `flutter create --platforms=ios`, a pinned `pubspec.yaml`,
`analysis_options.yaml` on `very_good_analysis` — then build `lib/theme/` by transcribing
`design/sunburst-pop/system.html` per `sunburst-tokens`. The theme layer comes before any screen,
because every screen reads it, and localization comes before any component, because directional
geometry cannot be retrofitted.

## Architecture we are building toward

**One Flutter package.** Do not create `packages/` until a body of pure logic earns the compile wall
(`project-structure-and-packages` rule 1).

```
lib/
  main.dart          thin; calls bootstrap()
  core/              pure, Flutter-free foundation: Result/Failure, ScoreFormat, SupportedLocale,
                     CalendarDay, SeededGenerator, HudTone. No intl, no NumberFormat, ever
  theme/             SunburstColors / SunburstShape / SunburstMotion / SunburstType + game_accent.dart
                     — the ONLY directory where a raw aesthetic value or a font family may appear
  l10n/              the four ARBs + generated AppLocalizations, the ckb delegates, the locale
                     resolver and providers, LocaleNumbers and AsciiNumerals, the bidi helper
  ui/components/     PopSurface and the chunky component catalog built on it
  ui/glyphs/         inline stroke icons (2.6 and 3.0 weights). No emoji, no icon font
  features/          the 8 shell screens
  games/             one folder per game: rules + board widget, nothing else
  data/              drift database, DAOs, repositories
  shared/feedback/   HapticGateway + FeedbackService — the only HapticFeedback call sites
  shared/motion/     PressPhysics, PopCelebration, ShakeOnWrong — a separate fence from feedback/
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
hit area holds still. Saturated pop colours on cream, Fredoka for display, Nunito for body — and in
`fa`/`ckb`, an Arabic-script pair in their place. Light theme only; there is no dark mode and adding
one is a new design direction, not a token flip.

**The Fredoka personality does not survive translation, and no font swap fixes that.** In Persian and
Sorani the identity is carried entirely by the shape language — the 3px ink border, the hard offset
shadow at zero blur, the press-down translate, the saturated palette on cream. That is enough; those
four things were always the direction. Say so rather than pretending a font swap is neutral.

| Source | Authoritative over |
|---|---|
| `design/sunburst-pop/system.html` | **Token values.** Every hex, radius, shadow offset, duration, curve and type step. |
| `design/sunburst-pop/app.html` | Layout, spacing rhythm and component usage across the 8 screens. |
| `design/sunburst-pop/screens/*.png` | Implementation targets — eight English LTR screens, rendered at 390×844 @2x. |
| `design/sunburst-pop/screens/rtl/*.png` | Their Persian RTL counterparts, same eight basenames, same size. **Produced by E04**; they do not exist until it merges. |
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
| **Adding or translating an ARB key; any inset, alignment or text alignment; formatting or parsing any number; the `ckb` delegate; a mixed-script run** | **`i18n-rtl-l10n`** |
| Drift tables, DAOs, `.watch` streams / a schema migration | `persistence-drift` / `run-migration` |
| Modeling `Result`/`Failure`, never-lose-data flows | `error-handling-typed-results` |
| Writing `main()`/`bootstrap()`, error handlers, lifecycle flush | `app-startup-and-bootstrap` |
| Semantics, tap targets, contrast, text scaling | `accessibility-as-code` |
| Golden, layout, RTL or a11y widget tests / re-baselining goldens | `widget-golden-and-a11y-testing` / `run-goldens-rebaseline` |
| Bundling a font, the per-script fallback cascade, `LicenseRegistry` | `design-system-structure` + `i18n-rtl-l10n` |
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
5. **Fonts are bundled, never fetched.** No `google_fonts`, no runtime HTTP for assets. Four faces
   ship: Fredoka and Nunito for Latin, Vazirmatn plus one display face for Arabic script. Every step's
   `fontFamilyFallback` must end in a face covering every shipped script — a glyph falling through to
   an OS font is a defect, not a graceful fallback, and it is invisible on the developer's device.
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
11. **All geometry is directional.** `EdgeInsetsDirectional`, `AlignmentDirectional`, `TextAlign.start`,
    `PositionedDirectional`, `BorderRadiusDirectional`, `Icons.adaptive`. `EdgeInsets.only(left:/right:)`,
    `Alignment.centerLeft`, `TextAlign.left` and `Icons.arrow_back` are gate failures
    (`check_i18n_bans.sh`), never an `// ignore:`. **The one exception is the hard offset shadow, which
    does not mirror** — it is a light-source constant, one imaginary light for the whole app, not a
    reading-direction property. Never wrap a test tree in a hardcoded `Directionality`: set the locale
    and let direction follow, because a hardcoded one is exactly what hides a physical-side bug.
12. **Numerals are localized at render and ASCII everywhere else.** `en`/`de` render Latin digits,
    `fa`/`ckb` render Eastern Arabic `۰۱۲۳۴۵۶۷۸۹` (U+06F0–U+06F9 with U+066B/U+066C — **never** the
    Arabic-Indic block U+0660–U+0669). The numbering system is pinned explicitly per locale in
    `LocaleNumbers`, the **one** `NumberFormat` construction site in `lib/`; `ckb` borrows `fa`'s symbol
    data because `intl` ships none for it and falls back to Latin silently. **Normalise to ASCII through
    `AsciiNumerals.normalize` before any parse, comparison or write.** Seeded generation produces
    integers and semantic tokens only: a golden vector must not move because the locale moved.

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

**Eleven epics**, one branch and one PR each, in `epics/`. Read `epics/README.md` for the dependency
graph, the delivery loop, the localization and iOS-first sections and the screenshot rule before
starting any of them. Persistence (E02) lands before localization (E04) because the locale override
must persist; localization lands before the component library (E05) because directional geometry
cannot be retrofitted across a built catalog. `epics/superseded/` holds the previous ten-epic plan;
nothing is built from it.

Run the app on the canonical simulator — the only one that is exactly 390×844, which is what makes a
screenshot comparison honest:

```bash
xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4
flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4
```

Regenerate the reference screenshots after editing `app.html` — **both sets**:

```bash
cd design/sunburst-pop
./capture-screens.sh          # rewrites screens/*.png; commit them with the change
./capture-screens.sh --rtl    # rewrites screens/rtl/*.png (exists from E04 on)
```
