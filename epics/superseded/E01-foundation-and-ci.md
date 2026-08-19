> **SUPERSEDED — do not build from this file.** It plans the old ten-epic sequence, written
> before the four-locale/two-direction and iOS-only requirements landed. It is superseded by
> [`../E01-foundation-ci-and-ios.md`](../E01-foundation-ci-and-ios.md) — **E01 · Foundation, CI and iOS target**. Kept for the record only; the live set is the
> eleven files in `epics/`, indexed by [`../README.md`](../README.md).

# E01 · Foundation and CI

| | |
|---|---|
| **Branch** | `epic/01-foundation-and-ci` |
| **Depends on** | nothing |
| **Unblocks** | E02, E03, E04, E05, E06, E07, E08, E09, E10 |
| **Status** | Not started |

## The epic

Turn a repository that holds only skills and design HTML into a Flutter app that builds, boots, and is
guarded by a pipeline. `flutter create` for iOS, Android and macOS (macOS as a **development and
screenshot-comparison target only** — it is not a shipped platform; E10's release scope is iOS and
Android), a pinned `pubspec.yaml` with the dependency set the architecture in `CLAUDE.md` actually
needs, a committed `pubspec.lock`, an `analysis_options.yaml` on a version-pinned `very_good_analysis`
with the silence-producing bug classes promoted to `error`, the `lib/` skeleton from `CLAUDE.md`
(amended once here to the real target layout), Fredoka and Nunito bundled as assets with their SIL OFL
texts registered through `LicenseRegistry`, the gen-l10n toolchain and ADR 0001 recording the
localisation posture, a thin `main.dart` that calls `bootstrap()` with the two error handlers installed
in the right order, a smoke widget test, and `.github/workflows/ci.yml`.

Nothing aesthetic ships here. No token, no component, no screen, no colour. The app ends this epic
booting to an empty, theme-less `Scaffold`. What ships is the machinery every later epic stands on: a
green `flutter test`, a green `flutter analyze --fatal-infos --fatal-warnings`, and a workflow that runs
the toolchain pin, format, codegen freshness, analyze, test, a compile, and every skill gate script that
is a gate.

## Why we need it

Every other epic assumes a package that exists. E02 cannot transcribe `system.html` into `lib/theme/`
without `lib/`. E05 cannot open a drift database without a `pubspec.yaml`. E07 cannot compare a screen
against `01-home.png` without an app to run. And no epic can honour the delivery loop's step 6 — "wait
for CI to pass" — because there is no CI: E01 is the first PR whose own pipeline can be waited on.

Without the pinned parts specifically: an unpinned Flutter version silently re-renders goldens and
perturbs determinism between the laptop and the runner; an uncommitted `pubspec.lock` means a fresh
clone resolves a graph nobody tested; a bare `very_good_analysis` include silently disables the whole
ruleset on the next `pub upgrade`; and a font fetched at runtime is a network call in an app whose
central promise is that it has none.

## Current state

Verified in `/Users/zakariafatahi/50-apps-challenge/E04` on 2026-08-19.

- **No Flutter package at all.** No `pubspec.yaml`, no `pubspec.lock`, no `lib/`, no `test/`, no
  `analysis_options.yaml`, no `ios/`, `android/`, `macos/`, no `.gitignore`, no `.github/`.
- Repository root holds exactly: `.claude/`, `.git/`, `CLAUDE.md`, `design/`,
  `50-apps-challenge-slides.html`, and `epics/` (this file).
- 4 commits on `main`, latest `cb1c3e2 Add five Sunburst Pop design skills and CLAUDE.md`.
- Remote `origin` is `git@github.com:zakariaf/mindforge.git`; `gh` is authenticated as `zakariaf`.
- `.claude/skills/` holds 45 skills and **49 shell scripts** under `.claude/skills/*/scripts/`.
- `design/sunburst-pop/` holds `system.html`, `app.html`, `README.md`, `capture-screens.sh` and
  `screens/` with the eight PNGs plus `README.md` and `contact-sheet.html`.
- Local toolchain, verified: **Flutter 3.44.6, channel stable, framework revision `ee80f08bbf`,
  Dart 3.12.2**, at `/Users/zakariafatahi/development/flutter/bin/flutter`.
- Local shell is **GNU bash 3.2.57** (macOS system bash). This matters: at least one skill script
  (`local-notifications-scheduler/scripts/check-scheduler-purity.sh`) uses `mapfile` and exits 127 on
  bash 3.2. It will work on the Ubuntu runner (bash 5).
- `CLAUDE.md` working agreement 10 claims the gate scripts "exit 0 cleanly when [the target dir] is
  absent". **Measured today, that is false for 29 of the 49.** Running every script with no argument:
  20 exit 0 (the five `sunburst-*` scripts, the `persistence-drift` pair, the
  `error-handling-typed-results` pair, `check_font_bundling.sh`, `check_painter_hygiene.sh`,
  `check-release-ad-ids.sh`, the `widget-golden-and-a11y-testing` and `testing-strategy` hygiene checks
  and three of the four `local-notifications-scheduler` scripts); 21 exit 2 (`check_architecture.sh`,
  `check_import_boundaries.sh`, `check_structure.sh`, `ban-legacy-providers.sh`,
  `check-widget-composition.sh`, `check-dart3-idioms.sh`, `check-determinism-bans.sh`,
  `check-service-boundaries.sh`, `check_adaptive.sh`, `check_routing.sh`, `check_i18n_bans.sh`,
  `check_arb_parity.sh`, `check_forms.sh`, `verify_feature.sh`, `scaffold_feature.sh`,
  `check-codegen-hygiene.sh`, `check-flavor-graph.sh`, `check-ipa-slices.sh`,
  `check-release-hygiene.sh`, `verify-core.sh`, `check-money-violations.sh`); 7 exit 1
  (`banned-strings.sh`, `ci-gates.sh`, `audit-deps.sh`, `verify-include-pin.sh`, `regen.sh`,
  `run_tests.sh`, `analyze.sh`); and `check-scheduler-purity.sh` exits **127** on macOS system bash 3.2
  because it uses `mapfile`. Most become runnable the moment T01.2 and T01.5 land; a handful stay
  unrunnable for structural reasons and are dealt with explicitly in T01.8. **T01.5 corrects working
  agreement 10 in `CLAUDE.md` to say this instead** — E02, E05 and E06 quote the corrected wording.

## What we will achieve

A reader can verify the epic is done by doing all of this:

1. `git clone` the repo, `flutter pub get`, `flutter run -d macos` — a window opens showing a blank
   white screen, no exception in the console, no framework error overlay.
2. `dart format --output=none --set-exit-if-changed .` exits 0.
3. `flutter analyze --fatal-infos --fatal-warnings` reports no issues.
4. `flutter test` is green and includes: a smoke widget test that pumps `MindForgeApp`, a bootstrap test
   that proves both error handlers are installed and `PlatformDispatcher.onError` returns `true`, font
   asset and licence tests, and policy tests for repo layout, dependencies, lint config, banned imports,
   skill-gate coverage, the l10n posture and the CI workflow.
5. `tool/skill_gates.sh` exits 0 and prints one `RUN`/`SKIP` line per script under
   `.claude/skills/*/scripts/`, every `SKIP` carrying a reason. **This runner is the single gate
   entrypoint every later epic calls**; a raw `for s in .claude/skills/*/scripts/*.sh` loop can never
   exit 0 and must not appear in any epic.
6. `flutter build apk --debug` succeeds — the tree compiles, not merely analyzes.
7. `test/theme/font_licence_test.dart` drains `LicenseRegistry.licenses` and finds one entry for
   Fredoka and one for Nunito, each carrying `SIL OPEN FONT LICENSE`; no `google_fonts` anywhere in the
   tree. (There is no Settings screen and no route until E07, so the in-app licences page cannot be
   checked here — the registry is the checkable surface.)
8. `flutter gen-l10n` succeeds against `l10n.yaml` and `lib/l10n/app_en.arb`, `AppLocalizations` is
   reachable from `lib/app.dart`, and `docs/decisions/0001-localisation-v1.md` records the posture.
9. A PR against `main` runs `.github/workflows/ci.yml` on `ubuntu-24.04` with Flutter pinned to the same
   version as `.fvmrc`, all steps green, and the PR body follows `.github/PULL_REQUEST_TEMPLATE.md`.

What will still be absent, deliberately: any colour, radius, shadow, duration or type step; any
component; any screen; any drift table; any route; any localized user-facing string beyond the one
template key that proves the pipeline.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Rule 14 (strict lint floor + `dart format`), rule 4 (Riverpod 3.x as the only DI), rule 11 (role-carrying names) all bind decisions made in this epic. Open before anything else. |
| `project-structure-and-packages` | Owns the physical tree. Single package by default (no `packages/`), `main.dart` thin over `bootstrap.dart`, `test/` mirrors `lib/` 1:1, no barrels or `lib/src/` in an app package, `always_use_package_imports`. Supplies `check_structure.sh` and `check_import_boundaries.sh`. |
| `dependency-hygiene` | Caret ranges in `pubspec.yaml`, exact pins only in a **committed** `pubspec.lock`, the SDK version recorded separately from the tool, the transitive-tree audit before adding a package, and the refuse-by-policy list (network / telemetry / crash / ads) that enforces the offline promise. Supplies `audit-deps.sh`. |
| `lint-and-style-config` | Owns `analysis_options.yaml`: the version-pinned VGA include and the trap where a missing include filename disables every rule; `errors:` re-ranks but cannot enable; the bug-class promotions; generated-file excludes mirrored to coverage; "CI must build, not merely analyze". Supplies `verify-include-pin.sh`. |
| `codegen-and-toolchain` | Fixes the commit-vs-gitignore decision for generated code and the CI gate that decision requires, and the ordering rule codegen-before-analyze that the workflow must encode even while no generator exists yet. |
| `app-startup-and-bootstrap` | The exact `main()` order: binding → error handlers → `bootstrap()` → `runApp`. Exactly two handlers, no `runZonedGuarded`, `PlatformDispatcher.onError` returns `true` unconditionally and cannot itself throw, `ProviderScope` retry tuned for local-only failure. |
| `design-system-structure` | Rule 10 and `references/typography-and-fonts.md`: bundle fonts in `pubspec.yaml`, ship and register the licence text via `LicenseRegistry`, drive weight with `FontWeight` not a redundant `FontVariation`. Supplies `check_font_bundling.sh`. |
| `sunburst-tokens` | Only for `references/shape-and-type.md`'s font-bundling table — the exact four (family, weight) pairs Fredoka 600/700 and Nunito 700/800 that E02 will spend. No token value is transcribed in this epic. |
| `ci-pipeline-and-gates` | The workflow itself: pinned runner and toolchain, one contract per gate, freshness gates as generate-then-`git diff`, randomized test ordering, `# VERIFY:` on unconfirmed action versions, gates never bless or mutate, and the honest statement of what CI cannot prove. |
| `testing-strategy` | Test at the cheapest tier that can assert the behaviour; bare-`implements` fakes over mocks; `test/policy/` is the sanctioned home for cross-cutting assertions that belong to no single file. |
| `state-management-riverpod` | The `ProviderScope`-as-DI decision, the throwing-placeholder seam pattern E05 will use, and the legacy-provider ban `ban-legacy-providers.sh` enforces from day one. |
| `naming-conventions` | File = primary declaration in `snake_case`; role suffixes; `lowercase_with_underscores` for files and folders; grouped and sorted directives. Applies to every file created here. |
| `dartdoc-conventions` | Backs the `public_member_api_docs: error` decision made in T01.4 — a `///` on every public declaration, first line a standalone sentence, never a restatement of the name. |
| `i18n-rtl-l10n` | T01.10 wires the gen-l10n contract every later epic ships strings against: `l10n.yaml` with `nullable-getter: false` so a missing key is a compile error, `flutter: generate: true`, the template `app_en.arb`, `localizationsDelegates`/`supportedLocales`, and the Directional-geometry bans `check_i18n_bans.sh` enforces. |

## Tasks

### T01.1 — Verify the local toolchain and pin it as one record

**Goal.** Prove the toolchain exists and works, then encode its exact version in one file that both the
developer and CI read, so a version drift is a failing check rather than a mystery.

**Tests first (TDD).** `tool/check_toolchain.sh` is written before `.fvmrc` exists and is driven through
three states by hand, each observed:
- no `.fvmrc` → exits 2, message names the missing file;
- `.fvmrc` containing a deliberately wrong version (`3.0.0`) → exits 1, message prints expected vs actual;
- `.fvmrc` containing `3.44.6` → exits 0.
No Dart test is possible at this point: there is no Dart package yet. The script's own three observed
states are the red-green-green.

**Implementation.** `tool/check_toolchain.sh` reads `flutter --version --machine`, extracts
`frameworkVersion` and `channel`, compares against the `flutter` key in `.fvmrc`, and fails with both
values printed. `.fvmrc` is `{"flutter": "3.44.6"}` — a plain JSON record; FVM itself is not required or
installed. **If `flutter --version` fails or Flutter is not on `PATH`, stop the epic and raise it. Do not
install a different version, do not switch channels, do not work around it.**

**Files.** `tool/check_toolchain.sh` (new), `.fvmrc` (new).

**Skills.** `dependency-hygiene` (rule 4: record the SDK version separately from the tool),
`ci-pipeline-and-gates` (rule 2: pin the toolchain on every job).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter --version` prints 3.44.6 / stable / Dart 3.12.2 and the output is pasted into the PR body.
- [ ] `bash tool/check_toolchain.sh` exits 0.
- [ ] The three failure states above were each observed once and are described in the script header.

**Commits.**
1. `Add a toolchain version check script`
2. `Pin Flutter 3.44.6 in .fvmrc`

---

### T01.2 — Scaffold the Flutter app for iOS, Android and macOS

**Goal.** Create the package with exactly three platforms and no template cruft, and confirm it runs.

**Tests first (TDD).** Author `test/policy/repo_layout_test.dart` on disk **before** running
`flutter create` (it cannot execute yet — the runner arrives with the package; it is committed with the
scaffold in one commit, per the delivery loop's "tests committed with the code they cover"). It asserts,
with `dart:io`:
- `pubspec.yaml` exists and its `name:` is `mindforge`;
- `ios/`, `android/`, `macos/` exist, with a `reason:` recording that **macOS is a development and
  screenshot-comparison target only, not a shipped platform** — E06's "the app ships iOS/Android only"
  comment and E10's iOS/Android-only release scope both depend on that being written down here;
- `web/`, `linux/`, `windows/` do **not** exist — an unused platform is an unmaintained platform;
- `lib/main.dart` exists;
- `.gitignore` exists and `git check-ignore -v pubspec.lock` exits non-zero, i.e. the lock is **not**
  ignored (`dependency-hygiene` rule 2 — the Dart template ignores it, an app must not).

**Implementation.**
```
flutter create --project-name mindforge --org com.mindforge \
  --platforms=ios,android,macos \
  --description "Offline brain-training games. No network, no accounts, no telemetry." .
```
`--project-name` is mandatory: the working directory is `E04`, which is not a legal Dart package name.
Then delete the template's `test/widget_test.dart` (T01.7 writes the real smoke test), delete the
template `README.md` body and replace it with a two-line pointer to `CLAUDE.md`, and leave the template
`analysis_options.yaml` in place until T01.4 replaces it wholesale.

**Files.** `pubspec.yaml`, `pubspec.lock`, `.gitignore`, `.metadata`, `README.md`, `lib/main.dart`,
`ios/**`, `android/**`, `macos/**`, `test/policy/repo_layout_test.dart`.

**Skills.** `project-structure-and-packages`, `dependency-hygiene`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface — the template counter app is not a MindForge screen and has
no reference PNG; the first comparison is E02).

**Done when.**
- [ ] `flutter run -d macos` opens a window running the template app with no console error.
- [ ] `flutter test` runs `repo_layout_test.dart` green.
- [ ] `git status` shows `pubspec.lock` as a tracked file.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_structure.sh lib` exits 0.

**Commits.**
1. `Scaffold the Flutter app for ios, android and macos with its layout policy test`
2. `Remove the template widget test and counter README`

---

### T01.3 — Declare the dependency set and commit the lock

**Goal.** One resolution that carries the whole architecture, audited against the offline promise, with
the lock committed alongside it.

**Tests first (TDD).** `test/policy/dependency_policy_test.dart`, written before the pubspec is edited,
asserting by parsing `pubspec.yaml` and `pubspec.lock` as text:
- every entry under `dependencies:` and `dev_dependencies:` other than `flutter`, `flutter_test` and
  `flutter_localizations` (all three are `sdk:` entries and carry no version) uses a caret range — a
  bare exact version fails;
- the allow-set is a **frozen literal list** naming every direct dependency, so a package added without
  a review fails here. E05 and E10 **extend** this file rather than re-authoring it;
- `pubspec.lock` exists and is non-empty;
- no name in the **resolved lock** matches the banned set: `http`, `dio`, `web_socket_channel`,
  `google_fonts`, `firebase_`, `sentry`, `google_mobile_ads`, `in_app_purchase`, `posthog`, `mixpanel`,
  `amplitude`, `device_info_plus`. The reason string quotes the `CLAUDE.md` constraint each one breaks;
- `cupertino_icons` is absent — MindForge draws inline stroke glyphs (`CLAUDE.md`, `lib/ui/glyphs/`).

**Implementation.** Add each package with `dart pub add --dry-run <name>` first, read what the second hop
drags in, then `dart pub add`. **Never hand-write a version number from memory** — record whatever caret
range `pub` writes.

Runtime: `flutter_riverpod` (state + DI, `CLAUDE.md`), `drift` + `sqlite3_flutter_libs` +
`path_provider` (the on-device store, E05), `go_router` (the single router, E07), `clock` (the injected
`Clock`; `DateTime.now()` in domain code is a defect), `flutter_localizations` (sdk) and `intl` — both
required, not optional: `intl` is what E06's `ScoreFormatter` formats `1,480` and `18.6s` with, and
`flutter_localizations` is what `flutter gen-l10n` and T01.10's `AppLocalizations` delegate need. An
epic that discovers it needs them mid-sequence is the failure this line prevents.
Dev: `very_good_analysis` (T01.4), `build_runner` + `drift_dev` (E05 codegen), `flutter_test` (sdk).

Two deliberate exclusions, both recorded in the PR body:
- **No `golden_toolkit`.** Goldens use the built-in `matchesGoldenFile`; the package adds a dependency to
  wrap what the framework already ships.
- **No `riverpod_generator` / `riverpod_annotation`.** `CLAUDE.md` specifies hand-written
  `Notifier`/`AsyncNotifier` classes over immutable state; the generator buys nothing here and adds a
  builder to every codegen pass.

Remove `cupertino_icons` and `flutter_lints` from the template pubspec. Set `environment: sdk: ^3.12.0`
— a real range, never an exact pin.

**Files.** `pubspec.yaml`, `pubspec.lock`, `test/policy/dependency_policy_test.dart`.

**Skills.** `dependency-hygiene`, `state-management-riverpod`, `testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter pub get` resolves and the `pubspec.lock` delta is staged in the same commit as the
      `pubspec.yaml` change.
- [ ] `.claude/skills/dependency-hygiene/scripts/audit-deps.sh` exits 0 (it currently fails with
      "pubspec.lock is missing").
- [ ] `flutter test test/policy/dependency_policy_test.dart` is green.
- [ ] The PR body lists each dependency with the epic that first uses it.

**Commits.**
1. `Add the dependency policy test`
2. `Add the runtime dependency set with its resolved lock`
3. `Add flutter_localizations and intl for gen-l10n and number formatting`
4. `Add build_runner and drift_dev for the codegen path`
5. `Drop cupertino_icons and flutter_lints from the template pubspec`

---

### T01.4 — Replace the analyzer config with pinned very_good_analysis

**Goal.** An analyzer that fails the build on the bug classes that otherwise go silent, on a ruleset that
cannot change under a `pub upgrade`.

**Tests first (TDD).** `test/policy/lint_config_test.dart`, written first, asserting over
`analysis_options.yaml` as text:
- the `include:` line matches `package:very_good_analysis/analysis_options\.\d+\.\d+\.\d+\.yaml` — a bare
  `analysis_options.yaml` fails;
- every name in a fixed list appears under `errors:` mapped to `error`: `unawaited_futures`,
  `discarded_futures`, `empty_catches`, `avoid_catches_without_on_clauses`, `only_throw_errors`,
  `throw_in_finally`, `use_build_context_synchronously`, `cancel_subscriptions`, `close_sinks`,
  `avoid_dynamic_calls`, `always_declare_return_types`, `cast_nullable_to_non_nullable`,
  `exhaustive_cases`, `avoid_print`, `avoid_slow_async_io`;
- no `language:` block restates `strict-casts` / `strict-raw-types` (VGA already sets them);
- the `exclude:` globs cover `**/*.g.dart`, `**/*.freezed.dart`, `**/*.drift.dart`;
- there is no `linter: rules:` block mixing list form and map form.

Plus one manual red-proof, run once and described in the PR body: add a scratch file containing a
dropped `Future` in a `void` context, confirm `flutter analyze --fatal-infos` **errors**, delete the
file. A promotion that silently did nothing is the exact failure this proves against.

**Implementation.** Start from `.claude/skills/lint-and-style-config/examples/analysis_options.yaml`.
Set the include filename to the version actually resolved — read it, do not guess:
`ls ~/.pub-cache/hosted/pub.dev/very_good_analysis-*/lib/`. Keep `public_member_api_docs: error`; record
the decision in a comment at that line: MindForge's engine seam (`GameDefinition`, `BoardSnapshot`,
`RunNotifier`) is an API a second game author reads, so the docs are a contract, per
`dartdoc-conventions`.

Attempt `riverpod_lint` as an analyzer plugin with an explicit `version:` key (never `custom_lint`), then
**verify it fires**: write a `ConsumerWidget` used without a `ProviderScope` and confirm
`missing_provider_scope` appears in `flutter analyze`. If no riverpod diagnostic appears, remove the
plugin and record why in the PR body — a plugin that emits nothing is a false safety signal.

Delete the template `analysis_options.yaml` content entirely; do not merge the two.

**Files.** `analysis_options.yaml`, `test/policy/lint_config_test.dart`, `pubspec.yaml` (if
`riverpod_lint` is kept).

**Skills.** `lint-and-style-config`, `dependency-hygiene` (rule 5, the include-pin trap),
`dartdoc-conventions`, `codegen-and-toolchain` (the exclude globs).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `.claude/skills/lint-and-style-config/scripts/verify-include-pin.sh` exits 0 (it currently fails
      with "analysis_options.yaml not found").
- [ ] `flutter analyze --fatal-infos --fatal-warnings` reports no issues on the tree as it stands.
- [ ] The scratch-file red-proof was observed and is described in the PR body.
- [ ] The `riverpod_lint` outcome — kept and firing, or removed with a reason — is recorded.

**Commits.**
1. `Add the lint config policy test`
2. `Replace the template analyzer config with pinned very_good_analysis`
3. `Enable riverpod_lint as an analyzer plugin` *(only if it was verified to fire)*

---

### T01.5 — Create the lib/ skeleton and fence the offline promise

**Goal.** Every directory the target layout names exists, `test/` mirrors it, `CLAUDE.md`'s layout block
is amended **once, here**, to the real tree, and the no-network promise is a failing test rather than a
habit.

**Tests first (TDD).** Two policy tests, written first, both red against the empty tree:
- `test/policy/project_structure_test.dart` — every path in the `CLAUDE.md` target layout exists as a
  directory: `lib/core`, `lib/theme`, `lib/ui/components`, `lib/ui/glyphs`, `lib/features`, `lib/games`,
  `lib/data`, `lib/l10n`, `lib/shared/feedback`, `lib/shared/motion`, `lib/routing`; and `test/` carries
  a mirror directory for each. Also asserts no directory named `utils`, `helpers`, `common` or `misc`
  exists anywhere under `lib/`. The test reads the directory list **out of `CLAUDE.md`'s layout block**,
  so the document and the tree cannot drift.
- `test/policy/banned_imports_test.dart` — walks every `.dart` file under `lib/`, strips `//` comments,
  matches the **import URI** (not a bare substring), and accumulates every offender before failing once.
  Banned prefixes: `package:http/`, `package:dio/`, `package:web_socket_channel/`, `package:google_fonts/`,
  `package:firebase_`, `package:sentry`, `package:google_mobile_ads/`, `package:in_app_purchase/`, plus
  `dart:io`'s `HttpClient` as a symbol. The `reason:` names the `CLAUDE.md` constraint each one breaks.

**Implementation.** Create the directories with a `.gitkeep` in each one that has no Dart file yet — a
`.gitkeep`, never a barrel: `project-structure-and-packages` rule 8 bans barrels in an app package and
`check_structure.sh` fails on one. `lib/shared/feedback/` is kept exactly as `CLAUDE.md` names it: it is
a directory with a stated responsibility (`HapticGateway` + `FeedbackService`), not the grab-bag `shared/`
that skill warns about.

**Amend `CLAUDE.md`'s layout block, once, in this task.** Three directories the architecture needs are
missing from it today, and three later epics would otherwise each propose the same one-line edit to the
same eight-line block:
- `core/` — the pure, Flutter-free foundation (`Result`/`Failure`, `ScoreFormat`, `CalendarDay`,
  `SeededGenerator`, `HudTone`). Sanctioned by `project-structure-and-packages` rule 7, and it is what
  `check-determinism-bans.sh` defaults its target to.
- `shared/motion/` — `PressPhysics`, `PopCelebration`, `ShakeOnWrong`. It must be a *separate* fence
  from `shared/feedback/`, because `check_motion_tokens.sh` confines `HapticFeedback` to `*/feedback/*`.
- `l10n/` — the ARB template and `game_strings.dart` (T01.10).
Because this task amends the block and `project_structure_test.dart` reads the block, **E04 and E05 must
not repeat the proposal**; their risk entries point here.

**Files.** `lib/core/.gitkeep`, `lib/theme/.gitkeep`, `lib/ui/components/.gitkeep`,
`lib/ui/glyphs/.gitkeep`, `lib/features/.gitkeep`, `lib/games/.gitkeep`, `lib/data/.gitkeep`,
`lib/l10n/.gitkeep`, `lib/shared/feedback/.gitkeep`, `lib/shared/motion/.gitkeep`,
`lib/routing/.gitkeep`, the matching `test/**/.gitkeep`, `CLAUDE.md` (the layout block),
`test/policy/project_structure_test.dart`, `test/policy/banned_imports_test.dart`.

**Skills.** `project-structure-and-packages`, `testing-strategy`, `ci-pipeline-and-gates`
(`references/policy-grep-gate.md` — the three-criteria bar and accumulate-and-fail-once shape),
`naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Both policy tests were seen red, then green.
- [ ] `CLAUDE.md`'s layout block lists `core/`, `shared/motion/` and `l10n/`, and working agreement 10
      is corrected to the measured accounting in *Current state* — the "all gates exit 0 when the target
      is absent" sentence is false and three later epics quote it.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_structure.sh lib` and
      `check_import_boundaries.sh lib` both exit 0.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` exits 0.

**Commits.**
1. `Add project structure and banned-import policy tests`
2. `Amend the CLAUDE.md layout block with core, shared/motion and l10n`
3. `Add the lib and test directory skeleton from CLAUDE.md`

---

### T01.6 — Bundle Fredoka and Nunito with their OFL texts

**Goal.** Both type families ship inside the binary, licensed correctly, with no runtime fetch — the one
place the offline promise touches a design decision.

**Ownership.** Fonts are bundled **here and only here.** E01 owns `pubspec.yaml`, and E03's real-font
golden lane (`loadAppFonts()`) needs the faces on disk before E02's type scale exists — a golden blessed
against Ahem is a lie. E02 T02.7 ships `lib/theme/sunburst_type.dart` and nothing else: no `.ttf`, no
`OFL.txt`, no second `registerSunburst*` function.

**Note on provenance.** These TTFs must be **downloaded once, by a human or an agent with network, and
committed**. `google_fonts` is banned by `CLAUDE.md` precisely because it ships an HTTP code path.
Sources: `github.com/googlefonts/fredoka` and `github.com/googlefonts/nunito`, both SIL Open Font
License 1.1. Downloading a font at authoring time is not a network call in the app; nothing in `lib/`
gains an HTTP path. **If no network is available when this task runs, that is a blocker to raise — do not
substitute a system font, and do not add `google_fonts` "temporarily".**

**Tests first (TDD).** Three tests, written before the assets are added:
- `test/theme/font_assets_test.dart` — for each declared asset path, `rootBundle.load(path)` returns more
  than 0 bytes **and** the first four bytes are a real font magic (`0x00 0x01 0x00 0x00` for TrueType or
  `OTTO`). This is what catches a Git-LFS pointer, an HTML error page, or a 0-byte placeholder committed
  by accident — a length check alone would not.
- `test/theme/font_licence_test.dart` — after calling `registerFontLicences()`, draining
  `LicenseRegistry.licenses` yields an entry whose `packages` contains `Fredoka` and another whose
  `packages` contains `Nunito`, and each entry's text contains `SIL OPEN FONT LICENSE`.
- `test/policy/font_declaration_test.dart` — `pubspec.yaml` declares exactly the four (family, weight)
  pairs `sunburst-tokens/references/shape-and-type.md` names: Fredoka 600, Fredoka 700, Nunito 700,
  Nunito 800. A fifth weight or a missing one fails.

**Implementation.** Prefer static instances (`Fredoka-SemiBold.ttf`, `Fredoka-Bold.ttf`,
`Nunito-Bold.ttf`, `Nunito-ExtraBold.ttf`). If upstream ships only a variable font for a family, bundle
the single variable TTF, declare the family once without per-weight `asset:` entries, and drive weight
with `FontWeight` alone — never a redundant `FontVariation('wght', …)`; record which shape was used.

Declare under `flutter: fonts:` in `pubspec.yaml`. Ship **two** licence files,
`assets/fonts/OFL-Fredoka.txt` and `assets/fonts/OFL-Nunito.txt` — the skill's example names one
`OFL.txt`, but the two families carry different copyright holders and a single file would misattribute
one of them. `lib/theme/font_licences.dart` holds `void registerFontLicences()`, which calls
`LicenseRegistry.addLicense` once per family with `LicenseEntryWithLineBreaks`. It sits in `lib/theme/`
because that is the only directory where a font-family string may appear.

**Files.** `assets/fonts/*.ttf`, `assets/fonts/OFL-Fredoka.txt`, `assets/fonts/OFL-Nunito.txt`,
`pubspec.yaml`, `lib/theme/font_licences.dart`, `test/theme/font_assets_test.dart`,
`test/theme/font_licence_test.dart`, `test/policy/font_declaration_test.dart`.

**Skills.** `design-system-structure` (`references/typography-and-fonts.md`), `sunburst-tokens`
(`references/shape-and-type.md`, the four weight pairs only), `dartdoc-conventions` (`///` on
`registerFontLicences`).

**Screenshot check.** n/a (no visual surface yet — nothing renders these faces until E02 builds
`SunburstType`; the first type comparison is against `design/sunburst-pop/screens/01-home.png` in E02).

**Done when.**
- [ ] All three tests were seen red, then green.
- [ ] `.claude/skills/design-system-structure/scripts/check_font_bundling.sh lib` exits 0.
- [ ] `grep -rn "google_fonts" .` finds nothing outside `.claude/skills/` and this epic file.
- [ ] The font file byte sizes are plausible (tens to hundreds of KB, not bytes) and are noted in the PR.

**Commits.**
1. `Add the font asset, licence and declaration tests`
2. `Bundle Fredoka and Nunito TTFs with their OFL texts`
3. `Declare the Fredoka and Nunito families in pubspec`
4. `Register the bundled font licences with LicenseRegistry`

---

### T01.7 — Write bootstrap(), the thin entrypoint, and the smoke test

**Goal.** The app boots through one ordered composition root with a crash net installed before anything
that can throw.

**Tests first (TDD).** Three tests, written first:
- `test/bootstrap_test.dart` — calls `installErrorHandlers()` and asserts: `FlutterError.onError` is not
  the default; `PlatformDispatcher.instance.onError` is non-null; invoking that handler with
  `(Exception('boom'), StackTrace.empty)` returns **`true`**; invoking `FlutterError.onError` with a
  `FlutterErrorDetails` does not throw. Originals are captured in `setUp` and restored in `addTearDown`
  so the handlers do not leak into a randomized-order suite.
- `test/app_test.dart` — the smoke test:
  `await tester.pumpWidget(const ProviderScope(child: MindForgeApp()));`
  then `expect(find.byType(MaterialApp), findsOneWidget)` and `expect(tester.takeException(), isNull)`.
- `test/policy/startup_policy_test.dart` — reads `lib/` as text and asserts: `runZonedGuarded` appears
  nowhere (`app-startup-and-bootstrap` rule 2); `lib/main.dart` contains a call to `bootstrap()` and
  contains neither `runApp(` nor `WidgetsFlutterBinding` — i.e. the entrypoint stayed thin.

**Implementation.**
- `lib/main.dart`: `Future<void> main() => bootstrap();` and nothing else.
- `lib/bootstrap.dart`: `Future<void> bootstrap()` in this exact order —
  `WidgetsFlutterBinding.ensureInitialized()`, `installErrorHandlers()`, `registerFontLicences()`,
  `runApp(ProviderScope(retry: (count, error) => null, child: const MindForgeApp()))`.
  `installErrorHandlers()` lives in the same file as the composition root it serves: `FlutterError.onError`
  calls `FlutterError.presentError` then `debugPrint` under `kDebugMode`, wrapped in a bare `try/catch (_)`
  with the load-bearing comment; `PlatformDispatcher.instance.onError` does the same and returns `true`
  unconditionally.
- `lib/app.dart`: `class MindForgeApp extends StatelessWidget` building
  `MaterialApp(title: 'MindForge', home: Scaffold())`. **No `theme:`, no `darkTheme:`, no `themeMode:`** —
  E02 owns the theme, and a placeholder theme here would be a token value this epic promised not to ship.

Two things `app-startup-and-bootstrap` describes that are deliberately **not** built yet, each named in
the PR body so the owning epic is unambiguous: a durable on-device crash sink (there is nowhere to write
it until E05 opens the database — the handlers report to the console for now), and the root
`WidgetsBindingObserver` that flushes on background (there is no durable state to flush until E05).

**Files.** `lib/main.dart`, `lib/bootstrap.dart`, `lib/app.dart`, `test/bootstrap_test.dart`,
`test/app_test.dart`, `test/policy/startup_policy_test.dart`.

**Skills.** `app-startup-and-bootstrap`, `state-management-riverpod` (the `ProviderScope` retry policy),
`testing-strategy`, `naming-conventions`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the app boots to an empty `Scaffold`; there is no reference
PNG for a theme-less screen, and none should be created. The first screenshot comparison in the project
is E02's theme harness against `design/sunburst-pop/screens/`).

**Done when.**
- [ ] All three tests were seen red, then green.
- [ ] `flutter run -d macos` shows a blank white window, no error overlay, no console exception.
- [ ] `grep -rn "runZonedGuarded" lib/` is empty.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean, including `public_member_api_docs` on
      every new public declaration.

**Commits.**
1. `Add bootstrap, smoke and startup policy tests`
2. `Add bootstrap with the two error handlers`
3. `Add the thin main entrypoint and MindForgeApp`

---

### T01.8 — Wrap every skill gate script in one enumerated runner

**Goal.** One command runs every skill gate that is a gate, and a newly added skill script cannot be
silently left unrun. **This runner is the project's only sanctioned way to run the skill gates.** Every
epic from E02 onward calls `bash tool/skill_gates.sh` in its Gates section; a raw
`for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done` loop is a defect, not a stricter gate —
measured today, 29 of the 49 scripts exit non-zero with no argument and five of them structurally never
can (see the skip table below).

**Tests first (TDD).** `test/policy/skill_gates_coverage_test.dart`, written first, asserting that every
`*.sh` under `.claude/skills/*/scripts/` appears **exactly once** in `tool/skill_gates.sh` — either in the
run table or in the skip table with a non-empty reason. Red today: there are 49 scripts and no table. It
fails once with the full list of unlisted scripts, never one at a time.

**Implementation.** `tool/skill_gates.sh` holds two explicit tables. Read each script's header before
assigning it a row; the reason recorded must be true.

Run, with the argument each script actually takes (most default to `lib`; two are different):
`check-determinism-bans.sh` is passed `lib` explicitly — its default is `lib/core/`, and while `lib/core/`
does exist from T01.5, the ban applies to the whole tree, not just the pure layer (E08's generator lives
under `lib/games/stroop_rush/domain/`); `check_palette_contrast.sh` is passed nothing and reads its
default theme **file**, which does not exist until E02 and exits 0 cleanly today.

**The tables are living.** A later epic that creates a script's target moves its row from skip to run in
the same PR, and `skill_gates_coverage_test.dart` — which asserts each script appears **exactly once** —
is what forces the move to be deliberate. E07 does this for
`scaffold-feature-module/scripts/verify_feature.sh` (it becomes runnable per feature once
`lib/features/<name>/` exists).

Skip, each with the stated reason:
- `ci-pipeline-and-gates/scripts/ci-gates.sh` — re-runs format/analyze/test/build_runner; the workflow
  runs those as named steps, and nesting them hides which one failed.
- `codegen-and-toolchain/scripts/regen.sh` — mutates the tree; a gate never blesses.
- `lint-and-style-config/scripts/lint-gates.sh` and `custom-canvas-and-gestures/scripts/analyze.sh` —
  format/analyze wrappers, duplicating named workflow steps.
- `testing-strategy/scripts/run_tests.sh` — duplicates the test step.
- `scaffold-feature-module/scripts/scaffold_feature.sh` — a generator, not a check.
- `scaffold-feature-module/scripts/verify_feature.sh` — takes one feature directory; run per feature by
  E07/E08/E09, not repo-wide.
- `service-boundary-and-native/scripts/check-flavor-graph.sh` — requires a `BANNED_REGEX` argument and a
  flavor graph; MindForge ships no flavors.
- `i18n-rtl-l10n/scripts/check_arb_parity.sh` — **verified today: it exits 2 on a directory holding only
  the template.** Read the script: after finding `app_en.arb` it collects every other `app_*.arb`, and
  `if [[ ${#LOCALE_FILES[@]} -eq 0 ]]; then echo "FAIL: no locale ARB files (app_*.arb) beside the
  template"; exit 2; fi`. MindForge ships one locale in v1 (ADR 0001, T01.10), so there is nothing to
  compare the template against and the script has no parity to check. Its sibling
  `check_i18n_bans.sh lib` **is** run — that is the half that is meaningful at one locale. Move this row
  to the run table the day a second `app_*.arb` lands.
- `release-and-store-shipping/scripts/check-ipa-slices.sh` — needs a built IPA; E10 owns it.

`release-and-store-shipping/scripts/check-release-hygiene.sh` is run first and its result decides its row:
if it passes on a pre-release tree, it runs; if it fails only on release-stage concerns (signing, version
bump), it moves to the skip table with that reason and a pointer to E10.

The script also prints a warning when `BASH_VERSINFO[0] < 4`, because
`local-notifications-scheduler/scripts/check-scheduler-purity.sh` uses `mapfile` and exits 127 on macOS
system bash 3.2. **Do not edit a skill script to work around this** — the skill library is not this
epic's to change; use `brew install bash` locally, and note that the Ubuntu runner ships bash 5.

**Files.** `tool/skill_gates.sh`, `test/policy/skill_gates_coverage_test.dart`.

**Skills.** `ci-pipeline-and-gates` (rule 1: one named contract per gate; rule 9: gates verify, never
mutate), `testing-strategy`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] The coverage test was seen red (49 unlisted scripts), then green.
- [ ] `bash tool/skill_gates.sh` exits 0 and prints one `RUN <script> → exit 0` or
      `SKIP <script> — <reason>` line per script.
- [ ] Every skip reason names a structural fact, never "it fails".

**Commits.**
1. `Add the skill-gate coverage policy test`
2. `Add tool/skill_gates.sh with an explicit run and skip table`

---

### T01.9 — Add the CI workflow and the pull request template

**Goal.** The pipeline exists, is pinned, blocks on every contract, and states what it cannot prove.

**Tests first (TDD).** `test/policy/ci_workflow_test.dart`, written first, asserting over
`.github/workflows/ci.yml` as text:
- `runs-on: ubuntu-24.04` appears and `ubuntu-latest` appears nowhere;
- `subosito/flutter-action@v2` appears and `channel: stable` is set;
- the pinned `flutter-version:` string equals the `flutter` value in `.fvmrc` — the workflow and the
  record cannot drift;
- each of these substrings appears: `tool/check_toolchain.sh`, `dart format --output=none
  --set-exit-if-changed .`, `build_runner build --delete-conflicting-outputs`, `git diff --exit-code`,
  `flutter analyze --fatal-infos --fatal-warnings`, `--test-randomize-ordering-seed random`,
  `tool/skill_gates.sh`, `flutter build apk --debug`;
- `continue-on-error` and `--update-goldens` appear nowhere.
And over `.github/PULL_REQUEST_TEMPLATE.md`: the five headings required by the delivery loop are present.

**Implementation.** `.github/workflows/ci.yml`, one file, `on: [push to main, pull_request]`, with
`concurrency` (cancel-in-progress) and `permissions: contents: read`.

Job `verify`, `runs-on: ubuntu-24.04`, `timeout-minutes: 20`, steps in this order — the order is the
contract, and codegen before analyze is `codegen-and-toolchain` rule 1:
1. `actions/checkout@v4`  `# VERIFY: confirm current major`
2. `subosito/flutter-action@v2` with `channel: stable`, `flutter-version: '3.44.6'`, `cache: true`
3. `flutter pub get`
4. `bash tool/check_toolchain.sh` — the runner's Flutter equals `.fvmrc`
5. `dart format --output=none --set-exit-if-changed .`
6. codegen freshness: `dart run build_runner build --delete-conflicting-outputs` then
   `git diff --exit-code -- '*.g.dart' '*.freezed.dart' '*.drift.dart'`, failing with an
   `::error::` telling the author to regenerate and commit. No generator is wired yet, so this passes
   trivially today; it is in place before E05 adds drift, which is the point — the decision recorded here
   is **generated code is committed**, and a committed-generated-code policy without its freshness gate is
   not a policy.
7. `flutter analyze --fatal-infos --fatal-warnings`
8. `flutter test --test-randomize-ordering-seed random --reporter expanded`
9. `bash tool/skill_gates.sh`

Job `build`, `runs-on: ubuntu-24.04`, `timeout-minutes: 30`, same toolchain pin, running
`flutter build apk --debug`. This exists for one named contract: **the tree compiles, not merely
analyzes**. Sealed-switch exhaustiveness is a compile error, not a lint, and an analyze-only pipeline
goes green over code that will not build (`lint-and-style-config` rule 7).

No `apt install sqlite3` step yet — nothing opens a database until E05, and a step with no contract is
not a gate. E05 adds it.

A comment block at the top of the file names what CI cannot prove: font rendering, haptics, motion and
press physics, screenshot parity against `design/sunburst-pop/screens/`, and on-device behaviour. Those
belong to the manual pass and to E10's `design-review-workflow` sweep.

`.github/PULL_REQUEST_TEMPLATE.md` carries exactly the five sections the delivery loop requires:
**What changed**, **Why**, **How it was verified** (the gate commands and their output), **Screens
compared** (the PNG filenames, and the fixed comparison order: structure → spacing rhythm → surface
construction → type role → sampled hex), **Deliberately left out**.

**Files.** `.github/workflows/ci.yml`, `.github/PULL_REQUEST_TEMPLATE.md`,
`test/policy/ci_workflow_test.dart`.

**Skills.** `ci-pipeline-and-gates`, `codegen-and-toolchain`, `lint-and-style-config`,
`dependency-hygiene`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] The workflow policy test was seen red, then green.
- [ ] The PR opened for this epic ran the workflow and **both jobs are green** — this is the first PR in
      the project whose own pipeline can be waited on.
- [ ] `gh run view --log` shows every step executed; none skipped, none `continue-on-error`.
- [ ] The PR body was written from the template and every section is filled.

**Commits.**
1. `Add the CI workflow policy test`
2. `Add the GitHub Actions CI workflow`
3. `Add the pull request template`

---

### T01.10 — Wire gen-l10n and record the localisation posture as ADR 0001

**Goal.** Settle the localisation posture **once, before any epic ships a string**, wire the toolchain
that decision implies, and prove it with a policy test — so E07's `game_strings.dart`, E08's answer
labels and E09's HUD labels all build against a contract that already exists.

**Why here and not E10.** E07, E08 and E09 each ship user-facing strings. A posture decided after them
is a posture three epics have already guessed at; E10's job is to *verify* it and to make the Settings
Language row real, not to invent it.

**The decision, recorded in `docs/decisions/0001-localisation-v1.md`:** **adopt gen-l10n now, ship one
locale.** Every user-facing string lives in `lib/l10n/app_en.arb` and is read through `AppLocalizations`.
The reasoning to write down:
- `intl` is a dependency regardless — E06's `ScoreFormatter` needs `NumberFormat` for `1,480` and
  `18.6s`, and E08/E09 need per-locale digit formatting for the HUD. The marginal cost of gen-l10n on
  top of that is `l10n.yaml`, one `flutter: generate: true` line and one delegate list.
- Externalising strings is the *cheap* half of the retrofit and it only gets more expensive: moving
  every literal out of eight screens and two boards after they ship is the expensive half.
- `nullable-getter: false` turns a missing key into a compile error, which is a stronger guarantee than
  any grep gate over hardcoded literals.
- **The honest cost:** `check_arb_parity.sh` cannot run at one locale — verified, it exits 2 with
  `FAIL: no locale ARB files (app_*.arb) beside the template`. It stays in `tool/skill_gates.sh`'s skip
  table with that measured reason until a second `app_*.arb` lands. `check_i18n_bans.sh lib` is the
  half that *is* meaningful now, and it runs from this epic onward.
- The alternative considered and rejected — English-only with a `const` string map — and the trigger
  that would reverse this decision (v1 ships, no second locale is ever scheduled, and the ARB indirection
  is costing more than it buys).

**Tests first (TDD).**
- `test/policy/l10n_posture_test.dart`, written first, red against the empty tree. It pins the ADR so
  the posture cannot rot half-adopted:
  - `l10n.yaml` exists and declares `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`,
    `output-class: AppLocalizations`, `nullable-getter: false`, `synthetic-package: false`;
  - `pubspec.yaml` contains `generate: true` under its `flutter:` key, and lists both
    `flutter_localizations` (sdk) and `intl`;
  - `lib/l10n/app_en.arb` exists, parses as JSON, and every non-`@` key matches
    `^[a-z][a-zA-Z0-9_]*$` — the key convention E07/E08/E09 append to;
  - `lib/app.dart` names `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales`;
  - the reason string on each expectation cites `docs/decisions/0001-localisation-v1.md`, so re-opening
    the decision reds this test rather than silently drifting.
- `test/l10n/app_localizations_test.dart` — pump a `MaterialApp` with the delegates and assert
  `AppLocalizations.of(context).appTitle` returns `MindForge`. One key, one assertion: this proves the
  pipeline generates and resolves, and nothing more. It is red until `flutter gen-l10n` has run.

**Implementation.**
- `l10n.yaml` at the repo root, exactly the five keys the test asserts. `synthetic-package: false` is
  deliberate: the generated `AppLocalizations` lands in `lib/l10n/` as real, greppable source rather
  than inside `.dart_tool/`, which keeps `check_import_boundaries.sh` and every policy grep honest.
- `lib/l10n/app_en.arb` with exactly one key, `appTitle`, plus its `@appTitle` description. Later epics
  append; nothing else belongs here yet.
- `pubspec.yaml`: `generate: true` under `flutter:`.
- `lib/app.dart` (edit): `localizationsDelegates: AppLocalizations.localizationsDelegates`,
  `supportedLocales: AppLocalizations.supportedLocales`. Still **no `theme:`** — E02 owns that.
- `.gitignore`: the generated `lib/l10n/app_localizations*.dart` are **committed**, consistent with
  T01.9's generated-code decision, and covered by the same `git diff --exit-code` freshness gate.
- `.github/workflows/ci.yml` (edit): add `flutter gen-l10n` immediately before the codegen freshness
  step, extend that step's `git diff --exit-code` glob with `'lib/l10n/app_localizations*.dart'`, and
  add `check_i18n_bans.sh lib` — with a comment naming the contract it blocks on: geometry stays
  Directional so a future locale is a string job, not a layout rewrite.
- `tool/skill_gates.sh` (edit): `check_i18n_bans.sh` moves to the run table; `check_arb_parity.sh` keeps
  its skip row with the measured one-locale reason from T01.8.

**Files.** `docs/decisions/0001-localisation-v1.md`, `l10n.yaml`, `lib/l10n/app_en.arb`,
`lib/l10n/app_localizations.dart` + `app_localizations_en.dart` (generated, committed), `pubspec.yaml`,
`lib/app.dart`, `.github/workflows/ci.yml`, `tool/skill_gates.sh`,
`test/policy/l10n_posture_test.dart`, `test/l10n/app_localizations_test.dart`.

**Skills.** `i18n-rtl-l10n` (the whole gen-l10n contract), `codegen-and-toolchain` (generated output is
committed and freshness-gated), `ci-pipeline-and-gates`, `dependency-hygiene`.

**Screenshot check.** n/a (no visual surface — no string renders on a screen until E07, which compares
`01-home.png`).

**Done when.**
- [ ] Both tests were seen red, then green.
- [ ] `flutter gen-l10n` exits 0 and the generated files are committed and diff-clean.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` exits 0 and runs in CI.
- [ ] `check_arb_parity.sh` was run once by hand against `lib/l10n` and its exit-2 output is pasted into
      the PR body beside its skip-table reason — the skip is measured, not assumed.
- [ ] ADR 0001 names the decision, the rejected alternative, the cost of each and the reversal trigger.

**Commits.**
1. `Record the v1 localisation decision as ADR 0001`
2. `Add the l10n posture policy test`
3. `Add l10n.yaml, the English ARB template and the generated localisations`
4. `Wire AppLocalizations delegates into MindForgeApp`
5. `Run gen-l10n and check_i18n_bans.sh in CI`

## Gates that must pass

```bash
# Toolchain
bash tool/check_toolchain.sh

# Package
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- '*.g.dart' '*.freezed.dart' '*.drift.dart' 'lib/l10n/app_localizations*.dart'
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random --reporter expanded
flutter build apk --debug

# Every skill gate that is a gate, via the enumerated runner
bash tool/skill_gates.sh

# The gates the runner wraps, spot-checked individually during the epic
.claude/skills/dependency-hygiene/scripts/audit-deps.sh
.claude/skills/lint-and-style-config/scripts/verify-include-pin.sh
.claude/skills/project-structure-and-packages/scripts/check_structure.sh          lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh  lib
.claude/skills/design-system-structure/scripts/check_font_bundling.sh             lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh          lib
.claude/skills/codegen-and-toolchain/scripts/check-codegen-hygiene.sh
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                        lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh             lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh           lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh               lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh         lib
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                          lib
```

Local note: run `tool/skill_gates.sh` under bash 4 or newer. macOS system bash is 3.2 and one skill
script uses `mapfile`.

**Do not** replace the runner with `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`. That
loop cannot exit 0: measured today it fails on 29 of 49 scripts, five of which take a required argument
and can never pass argument-less. The runner exists precisely so the skip list is explicit and reviewed.

## Risks and open questions

| # | Risk / question | Decision, or who to ask |
|---|---|---|
| 1 | **Flutter must be installed and working.** If `flutter --version` fails, the entire sequence is blocked. | Verified today: 3.44.6 / stable / Dart 3.12.2 at `/Users/zakariafatahi/development/flutter`. If this changes, raise it immediately — do not switch channels or upgrade to work around it. |
| 2 | **The fonts require one network download.** Fredoka and Nunito TTFs are not in the repo and `google_fonts` is banned. | Download once from `github.com/googlefonts/fredoka` and `github.com/googlefonts/nunito` (both SIL OFL 1.1) and commit the files. If there is no network when T01.6 runs, that is a blocker to raise — never substitute a system font, never add `google_fonts` "temporarily". |
| 3 | **The dependency set is partly ahead of its use.** `dependency-hygiene` calls a speculative dependency a review reject, yet drift, `go_router` and `path_provider` are not used until E05/E07. | Accepted deliberately and recorded in the PR body: the set is fixed by the architecture in `CLAUDE.md`, every package lands within two epics, and one resolution now means one reviewed lock delta instead of five. `riverpod_generator` and `golden_toolkit` are **not** taken — neither is required by that architecture. |
| 4 | **The `very_good_analysis` include filename must match the resolved version.** A wrong filename yields one warning and a ruleset of zero rules — a green build that checks nothing. | Read the resolved version from `~/.pub-cache/hosted/pub.dev/very_good_analysis-*/lib/`, never guess it, and prove it with `verify-include-pin.sh` plus the scratch-file red-proof in T01.4. |
| 5 | **`riverpod_lint` may emit nothing on this analyzer.** A configured plugin that produces no diagnostics is a false safety signal. | T01.4 verifies it with a real `missing_provider_scope` violation. If it does not fire, remove it and say so in the PR body. |
| 6 | **macOS bash 3.2 cannot run `check-scheduler-purity.sh`** (`mapfile`, exit 127). | CI runs bash 5 on `ubuntu-24.04`, so the gate is real there. Locally, `brew install bash`. Do **not** edit the skill script — the skill library is not this epic's to change; if it should be fixed, ask Zakaria first. |
| 7 | **`CLAUDE.md`'s layout block is missing three directories the architecture needs** — `core/` (pure foundation, and `check-determinism-bans.sh`'s default target), `shared/motion/` (must be fenced separately from `shared/feedback/`, which `check_motion_tokens.sh` confines `HapticFeedback` to) and `l10n/`. Three later epics would each propose the same one-line edit. | Amend it **once, in T01.5**, and have `project_structure_test.dart` read the block so document and tree cannot drift. E04 and E05 must not repeat the proposal. `lib/shared/feedback/` keeps its name — it has a stated responsibility and `check_structure.sh` does not flag it. |
| 8 | **`--org com.mindforge`** fixes the bundle identifier, which is permanent once the app is published. | Proposed default `com.mindforge`. **Ask Zakaria to confirm before E10** — changing it after the first store upload creates a different app. |
| 9 | **Generated code: commit or gitignore.** | Decision: **commit**, with the freshness gate (`build_runner` then `git diff --exit-code`) wired in T01.9 before any generator exists. A `.gitattributes` diff-collapse for generated suffixes lands with the first generator in E05. |
| 10 | **`public_member_api_docs` at `error` costs a `///` on every public declaration.** | Kept at `error`. The engine seam (`GameDefinition`, `BoardSnapshot`, `RunNotifier`) is an API a second game author reads. The decision is recorded as a comment at that line in `analysis_options.yaml`; revisit only with a stated reason. |
| 11 | **CI cannot prove what this project cares most about.** Screenshot parity, font rendering, motion, press physics and haptics are all invisible to it. | Stated in a comment block at the top of `ci.yml`. The screenshot comparison is a per-task step from E03 onward; the on-device sweep is E10's `design-review-workflow` artifact. |
| 12 | **The localisation posture binds E07, E08, E09 and E10.** Deciding it late means three epics guess. | Decided in T01.10 and recorded as ADR 0001: **adopt gen-l10n, ship one locale.** `check_arb_parity.sh` cannot run at one locale (verified exit 2) and stays skipped with that measured reason; `check_i18n_bans.sh` runs from here on. E10 verifies the posture and builds the Language row; it does not re-decide. |
| 13 | **`intl` was nearly forgotten.** E06's `ScoreFormatter` needs `NumberFormat`; the original dependency list omitted it. | Added in T01.3 alongside `flutter_localizations`, both named with the epic that first spends them, so `dependency_policy_test.dart`'s frozen allow-set covers them from day one. |

## Definition of done

- [ ] Branch `epic/01-foundation-and-ci` cut from `main`.
- [ ] All ten tasks complete, each with its commits, each test seen red before it was seen green.
- [ ] `flutter run -d macos` opens a blank window with no console error; `flutter build apk --debug` succeeds.
- [ ] `dart format --output=none --set-exit-if-changed .` exits 0.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` reports no issues.
- [ ] `flutter test --test-randomize-ordering-seed random` is green.
- [ ] `bash tool/skill_gates.sh` exits 0; every skip carries a structural reason.
- [ ] `pubspec.lock` is committed and not gitignored; `audit-deps.sh` exits 0.
- [ ] Fredoka and Nunito are bundled, declared at the four named weights, and both OFL texts are
      reachable through `LicenseRegistry` (proven by `test/theme/font_licence_test.dart`); no
      `google_fonts` in the tree. **E02 must not re-bundle them** — it ships `SunburstType` only.
- [ ] `flutter gen-l10n` is green, ADR 0001 is written, `test/policy/l10n_posture_test.dart` passes, and
      `check_i18n_bans.sh lib` runs in CI.
- [ ] `CLAUDE.md`'s layout block and working agreement 10 are corrected in this PR;
      `test/policy/project_structure_test.dart` reads the layout block so they cannot drift.
- [ ] `lib/` matches the amended `CLAUDE.md` target layout; `test/` mirrors it.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] PR opened with a body written from `.github/PULL_REQUEST_TEMPLATE.md`, stating what changed, why,
      how it was verified, that no screens were compared (none exist yet, and why), and what was left out.
- [ ] CI green on the PR — both `verify` and `build` jobs.
- [ ] PR merged preserving the granular commits, branch deleted, back on `main`, pulled.
- [ ] E02 can start: `lib/theme/` exists and is empty apart from `font_licences.dart`, the four faces
      are on disk under `assets/fonts/`, and `AppLocalizations` resolves.
