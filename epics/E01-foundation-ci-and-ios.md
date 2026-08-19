# E01 · Foundation, CI and iOS target

| | |
|---|---|
| **Branch** | `epic/01-foundation-ci-and-ios` |
| **Depends on** | nothing |
| **Unblocks** | E02, E03 |
| **Status** | Not started |

## The epic

Turn a repository that holds only skills and design HTML into a Flutter app that builds, boots on the
canonical iOS simulator, and is guarded by a pipeline. `flutter create --platforms=ios` — **iOS is the
only target; Android is deferred by decision, not by oversight, and macOS is dropped** — a pinned
`pubspec.yaml` with the dependency set the architecture in `CLAUDE.md` actually needs plus
`flutter_localizations` and `intl`, a committed `pubspec.lock` and `ios/Podfile.lock`, the iOS bundle
identifier and an `Info.plist` declaring `CFBundleDevelopmentRegion` = `en` and `CFBundleLocalizations`
= `en, de, fa, ckb`, an `analysis_options.yaml` on a version-pinned `very_good_analysis` with the
silence-producing bug classes promoted to `error`, the `lib/` skeleton from `CLAUDE.md` (amended once
here to the real target layout), Fredoka and Nunito bundled as assets with their SIL OFL texts
registered through `LicenseRegistry`, the gen-l10n toolchain with a seeded English ARB template and
ADR 0001 recording the four-locale posture, a thin `main.dart` that calls `bootstrap()` with the two
error handlers installed in the right order, a smoke widget test, a run on the canonical simulator that
ends in a launch screenshot, and `.github/workflows/ci.yml` on a **macOS runner**.

Nothing aesthetic ships here. No token, no component, no screen, no colour. The app ends this epic
booting to an empty, theme-less `Scaffold` on `MindForge iPhone 14`. What ships is the machinery every
later epic stands on: a green `flutter test`, a green `flutter analyze --fatal-infos --fatal-warnings`,
a green `flutter build ios --no-codesign`, and a workflow that runs the toolchain pin, gen-l10n,
format, codegen freshness, analyze, test, an unsigned iOS compile, and every skill gate script that is
a gate — including `check_i18n_bans.sh`, which is what keeps E04's RTL work a string job rather than a
layout rewrite.

## Why we need it

Every other epic assumes a package that exists. E03 cannot transcribe `system.html` into `lib/theme/`
without `lib/`. E02 cannot open a drift database without a `pubspec.yaml`. E04 cannot add
`app_de.arb`, `app_fa.arb` and `app_ckb.arb` without a template and an `l10n.yaml` to add them to.
E08 cannot compare a screen against `01-home.png` without an app that runs on a 390×844 device. And no
epic can honour the delivery loop's step 7 — "wait for CI to pass" — because there is no CI: E01 is
the first PR whose own pipeline can be waited on.

Without the pinned parts specifically: an unpinned Flutter version silently re-renders goldens and
perturbs determinism between the laptop and the runner; an uncommitted `pubspec.lock` or
`ios/Podfile.lock` means a fresh clone resolves a graph nobody tested; a bare `very_good_analysis`
include silently disables the whole ruleset on the next `pub upgrade`; a font fetched at runtime is a
network call in an app whose central promise is that it has none; and an `Info.plist` without
`CFBundleLocalizations` means iOS never offers the locale at all, no matter how complete the ARB files
are — the failure `i18n-rtl-l10n`'s pitfall list names by hand because nothing in Dart catches it.

Without the iOS decisions specifically: a screenshot taken on any simulator other than
`MindForge iPhone 14` is not a comparison against `design/sunburst-pop/screens/*.png`, it is a
comparison against a different canvas. iPhone 16 is 393×852 and 16 Pro is 402×874; only the iPhone
14 class is exactly 390×844.

## Current state

Verified in `/Users/zakariafatahi/50-apps-challenge/E04` on 2026-08-19.

- **No Flutter package at all.** No `pubspec.yaml`, no `pubspec.lock`, no `lib/`, no `test/`, no
  `analysis_options.yaml`, no `ios/`, no `.gitignore`, no `.github/`.
- Repository root holds exactly: `.claude/`, `.git/`, `CLAUDE.md`, `design/`,
  `50-apps-challenge-slides.html`, and `epics/`.
- 5 commits on `main`, latest `ddcb79d Add ten epic plans and correct the gate-script claim in CLAUDE.md`.
  Those ten plans are superseded by the eleven-epic sequence this file belongs to.
- Remote `origin` is `git@github.com:zakariaf/mindforge.git`; `gh` is authenticated as `zakariaf`.
- `.claude/skills/` holds 45 skills and **49 shell scripts** under `.claude/skills/*/scripts/`.
- `design/sunburst-pop/` holds `system.html`, `app.html`, `README.md`, `capture-screens.sh` and
  `screens/` with the eight PNGs plus `README.md` and `contact-sheet.html`. Every PNG is **780×1688
  pixels** — 390×844 logical points at 2× — and every one is **English LTR**. E04 produces the RTL
  counterpart set under `design/sunburst-pop/screens/rtl/`; this epic produces none.
- `design/sunburst-pop/screens/README.md` step 1 currently says to compare on "iPhone 14 simulator, or
  `flutter run -d macos` with the window sized to match". The macOS half becomes false in T01.2 and is
  corrected in T01.10.

**Toolchain, verified on this machine — pinned, not discovered.** These are facts, not a task:

| Tool | Version |
|---|---|
| Flutter | **3.44.6**, channel stable, framework revision `ee80f08bbf` |
| Dart | **3.12.2** (DevTools 2.57.0) |
| Xcode | **26.6**, build `17F113` |
| CocoaPods | **1.15.2** |
| Simulator runtimes installed | iOS 18.0, iOS 18.6, iOS 26.5 |

**The canonical device already exists.** `MindForge iPhone 14`, UDID
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6, currently `Shutdown`. It was created for this
project because the iPhone 14 class is **exactly 390×844 logical points**, matching every reference
PNG. Boot it with `xcrun simctl boot C13DDC02-375D-4E1B-8F81-44EB407D09A4`, run on it with
`flutter run -d C13DDC02-375D-4E1B-8F81-44EB407D09A4`.

- Local shell is **GNU bash 3.2.57** (macOS system bash). At least one skill script
  (`local-notifications-scheduler/scripts/check-scheduler-purity.sh`) uses `mapfile` and exits 127 on
  bash 3.2. **CI no longer solves this for us**: moving the pipeline to a macOS runner means the
  runner's `/bin/bash` is 3.2 as well, so T01.11 and T01.12 handle it explicitly instead of inheriting
  Ubuntu's bash 5.
- `flutter gen-l10n --help` on 3.44.6, read today: `--synthetic-package` is marked
  **"DEPRECATED. This flag cannot be enabled and should be removed."** The option must not appear in
  `l10n.yaml`. `--nullable-getter` defaults to **on**, so `nullable-getter: false` is load-bearing.
  `--format`, `--required-resource-attributes`, `--use-escaping`, `--suppress-warnings` and
  `--untranslated-messages-file` all exist and are decided in T01.9.
- `CLAUDE.md` working agreement 10 claims the gate scripts "exit 0 cleanly when [the target dir] is
  absent". **Measured, that is false for 29 of the 49.** Running every script with no argument:
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
  `run_tests.sh`, `analyze.sh`); and `check-scheduler-purity.sh` exits **127** on bash 3.2. Most become
  runnable the moment T01.2 and T01.6 land; a handful stay unrunnable for structural reasons and are
  dealt with explicitly in T01.11. **T01.6 corrects working agreement 10 in `CLAUDE.md` to say this
  instead** — E02, E04 and E06 quote the corrected wording.
- `check_arb_parity.sh` read today: after finding `app_en.arb` it collects every other `app_*.arb`, and
  `if [[ ${#LOCALE_FILES[@]} -eq 0 ]]; then echo "FAIL: no locale ARB files (app_*.arb) beside the
  template"; exit 2; fi`. It therefore **cannot pass in this epic**, which ships the template alone.
  E04 is the epic that lands `app_de.arb`, `app_fa.arb` and `app_ckb.arb` and moves its row from the
  skip table to the run table.

## What we will achieve

A reader can verify the epic is done by doing all of this:

1. `git clone` the repo, `flutter pub get`, `bash tool/ios_simulator.sh run` — the canonical simulator
   boots and MindForge launches to a blank white screen, no exception in the console, no framework
   error overlay.
2. `dart format --output=none --set-exit-if-changed .` exits 0, including the committed generated
   localizations.
3. `flutter analyze --fatal-infos --fatal-warnings` reports no issues.
4. `flutter test` is green and includes: a smoke widget test that pumps `MindForgeApp`, a bootstrap test
   that proves both error handlers are installed and `PlatformDispatcher.onError` returns `true`, font
   asset and licence tests, an `AppLocalizations` resolution test, the measured
   `GlobalMaterialLocalizations` support characterization for `en`/`de`/`fa`/`ckb`, and policy tests for
   repo layout, the iOS target, dependencies, lint config, banned imports, skill-gate coverage, the l10n
   posture and the CI workflow.
5. `tool/skill_gates.sh` exits 0 under bash 4+ and prints one `RUN`/`SKIP` line per script under
   `.claude/skills/*/scripts/`, every `SKIP` carrying a reason. **This runner is the single gate
   entrypoint every later epic calls**; a raw `for s in .claude/skills/*/scripts/*.sh` loop can never
   exit 0 and must not appear in any epic.
6. `flutter build ios --no-codesign` succeeds — the tree compiles for the shipping platform, not merely
   analyzes.
7. `test/theme/font_licence_test.dart` drains `LicenseRegistry.licenses` and finds one entry for
   Fredoka and one for Nunito, each carrying `SIL OPEN FONT LICENSE`; no `google_fonts` anywhere in the
   tree. (There is no Settings screen and no route until E08, so the in-app licences page cannot be
   checked here — the registry is the checkable surface.)
8. `flutter gen-l10n` succeeds against `l10n.yaml` and the six-key `lib/l10n/app_en.arb`,
   `AppLocalizations` is reachable from `lib/app.dart`, and `docs/decisions/0001-localisation.md`
   records the four-locale posture with the two `ckb` measurements pasted into it.
9. `plutil -p ios/Runner/Info.plist` shows `CFBundleDevelopmentRegion` = `en` and `CFBundleLocalizations`
   = `["en", "de", "fa", "ckb"]`.
10. `docs/verification/e01-simulator-launch.png` exists, was captured with
    `xcrun simctl io C13DDC02-375D-4E1B-8F81-44EB407D09A4 screenshot`, and is 1170×2532 pixels.
11. A PR against `main` runs `.github/workflows/ci.yml` on a pinned macOS runner with Flutter pinned to
    the same version as `.toolchain.json`, both jobs green, and the PR body follows
    `.github/PULL_REQUEST_TEMPLATE.md`.

What will still be absent, deliberately: any colour, radius, shadow, duration or type step; any
component; any screen; any drift table; any route; **any locale beyond `en`**; any Arabic-script font;
any RTL screenshot; any directional-geometry work beyond the ban gate that prevents the wrong kind;
and **any Android directory** — see the decision in T01.2.

## Skills to load

| Skill | Why, for this epic |
|---|---|
| `flutter-conventions-index` | The front door. Rule 14 (strict lint floor + `dart format`), rule 4 (Riverpod 3.x as the only DI), rule 11 (role-carrying names) and rule 12 (RTL and a11y by construction, every string from an ARB) all bind decisions made here. Open before anything else. |
| `project-structure-and-packages` | Owns the physical tree. Single package by default (no `packages/`), `main.dart` thin over `bootstrap.dart`, `test/` mirrors `lib/` 1:1, `l10n/` is a named top-level foundation folder, no barrels or `lib/src/` in an app package, `always_use_package_imports`. Supplies `check_structure.sh` and `check_import_boundaries.sh`. |
| `dependency-hygiene` | Caret ranges in `pubspec.yaml`, exact pins only in a **committed** `pubspec.lock`, the SDK version recorded separately from the tool, the transitive-tree audit before adding a package, and the refuse-by-policy list (network / telemetry / crash / ads) that enforces the offline promise. Supplies `audit-deps.sh`. |
| `lint-and-style-config` | Owns `analysis_options.yaml`: the version-pinned VGA include and the trap where a missing include filename disables every rule; `errors:` re-ranks but cannot enable; the bug-class promotions; generated-file excludes mirrored to coverage; "CI must build, not merely analyze". Supplies `verify-include-pin.sh`. |
| `codegen-and-toolchain` | Fixes the commit-vs-gitignore decision for generated code and the CI gate that decision requires, and the ordering rule codegen-before-analyze — which now covers `flutter gen-l10n`, whose output is committed and freshness-gated from this epic on. |
| `app-startup-and-bootstrap` | The exact `main()` order: binding → error handlers → `bootstrap()` → `runApp`. Exactly two handlers, no `runZonedGuarded`, `PlatformDispatcher.onError` returns `true` unconditionally and cannot itself throw, `ProviderScope` retry tuned for local-only failure. Rule 5 (read locale before `runApp` so frame one paints correct) is what E04 will build the locale override on. |
| `i18n-rtl-l10n` | The whole gen-l10n contract this epic wires: template `app_en.arb` first, `nullable-getter: false` so a missing key is a compile error, `localizationsDelegates`/`supportedLocales`, the iOS `CFBundleLocalizations` pitfall, the `ckb`-is-not-in-`GlobalMaterialLocalizations` warning in `references/arb-and-icu.md`, and the two gate scripts `check_i18n_bans.sh` and `check_arb_parity.sh`. |
| `design-system-structure` | Rule 10 and `references/typography-and-fonts.md`: bundle fonts in `pubspec.yaml`, ship and register the licence text via `LicenseRegistry`, drive weight with `FontWeight` not a redundant `FontVariation`, and declare a per-script `fontFamilyFallback` cascade that ends in a face covering every script the app localizes into — the reason E01 bundling only Latin faces has to be stated as incomplete rather than done. |
| `sunburst-tokens` | Only for `references/shape-and-type.md`'s font-bundling table — the exact four (family, weight) pairs Fredoka 600/700 and Nunito 700/800 that E03 will spend. No token value is transcribed in this epic. |
| `ci-pipeline-and-gates` | The workflow itself: pinned runner and toolchain (rule 2 — never `-latest`), one contract per gate, freshness gates as generate-then-`git diff`, randomized test ordering, `# VERIFY:` on unconfirmed action versions and runner labels (rule 3), gates never bless or mutate (rule 9), and the honest statement of what CI cannot prove (rule 10). |
| `release-and-store-shipping` | Read only for `references/ios-app-store.md`'s `Info.plist` section and the bundle-identifier permanence warning. Nothing is built, signed or uploaded here — E11 owns the release. Supplies `check-release-hygiene.sh`, whose row in the gate runner is decided by running it. |
| `testing-strategy` | Test at the cheapest tier that can assert the behaviour; bare-`implements` fakes over mocks; `test/policy/` is the sanctioned home for cross-cutting assertions that belong to no single file. |
| `state-management-riverpod` | The `ProviderScope`-as-DI decision, the throwing-placeholder seam pattern E02 will use, and the legacy-provider ban `ban-legacy-providers.sh` enforces from day one. |
| `naming-conventions` | File = primary declaration in `snake_case`; role suffixes; `lowercase_with_underscores` for files and folders; grouped and sorted directives. Applies to every file created here, including the ARB key convention. |
| `dartdoc-conventions` | Backs the `public_member_api_docs: error` decision made in T01.5 — a `///` on every public declaration, first line a standalone sentence, never a restatement of the name. |

## Tasks

### T01.1 — Pin the verified toolchain as one record

**Goal.** Encode the already-verified toolchain in one file that both the developer and CI read, so a
version drift is a failing check rather than a mystery. **This is not a discovery task** — Flutter
3.44.6, Dart 3.12.2, Xcode 26.6 and CocoaPods 1.15.2 were measured on this machine and are recorded in
*Current state*. The task writes them down and builds the check that keeps them true.

**Tests first (TDD).** `tool/check_toolchain.sh` is written before `.toolchain.json` exists and is
driven through four states by hand, each observed and described in the script header:
- no `.toolchain.json` → exits 2, message names the missing file;
- `.toolchain.json` with a deliberately wrong `flutter` (`3.0.0`) → exits 1, message prints expected vs
  actual;
- `.toolchain.json` with a deliberately wrong `xcode` (`1.0`) and `TOOLCHAIN_HOST_TOOLS` unset → exits 1;
- the same wrong `xcode` with `TOOLCHAIN_HOST_TOOLS=warn` → exits 0 and prints a `WARN` line;
- the true values → exits 0.
No Dart test is possible at this point: there is no Dart package yet. The script's own observed states
are the red-green.

**Implementation.** `.toolchain.json` at the repo root is the single record:

```json
{
  "flutter": "3.44.6",
  "dart": "3.12.2",
  "xcode": "26.6",
  "cocoapods": "1.15.2",
  "simulator": {
    "name": "MindForge iPhone 14",
    "udid": "C13DDC02-375D-4E1B-8F81-44EB407D09A4",
    "runtime": "iOS 18.6",
    "logicalSize": "390x844"
  }
}
```

One file, not two. `.fvmrc` is deliberately **not** used: FVM is not installed, a `.fvmrc` no tool reads
is a decoy, and the iOS half of the toolchain plus the canonical simulator have nowhere to live in it.
The cost is that `subosito/flutter-action`'s `flutter-version-file` cannot point at it, so T01.12 pins
`flutter-version: '3.44.6'` literally in the workflow and `ci_workflow_test.dart` asserts that literal
equals `.toolchain.json`'s `flutter` key — the drift is caught by a test instead of by the action.

`tool/check_toolchain.sh` parses the JSON with `python3` (present via the Xcode command line tools and on
the GitHub macOS images; the script fails with a named message if it is not), then:
- reads `flutter --version --machine`, compares `frameworkVersion` and `dartSdkVersion`, and **fails
  hard** on a mismatch — this is the version that re-renders goldens and perturbs determinism;
- reads `xcodebuild -version` and `pod --version` and compares them, failing hard by default and
  emitting `WARN` instead when `TOOLCHAIN_HOST_TOOLS=warn` is set. CI sets it, with a comment naming
  the reason: the GitHub runner image's Xcode is not ours to pin to 26.6, and pretending otherwise
  would make the workflow red for a fact we do not control.

**If `flutter --version` fails or Flutter is not on `PATH`, stop the epic and raise it. Do not install a
different version, do not switch channels, do not work around it.**

**Files.** `.toolchain.json` (new), `tool/check_toolchain.sh` (new).

**Skills.** `dependency-hygiene` (rule 4: record the SDK version separately from the tool),
`ci-pipeline-and-gates` (rule 2: pin the toolchain on every job).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] `flutter --version`, `xcodebuild -version` and `pod --version` outputs are pasted into the PR body
      and match `.toolchain.json` exactly.
- [ ] `bash tool/check_toolchain.sh` exits 0.
- [ ] All five states above were observed once and are described in the script header.

**Commits.**
1. `Add a toolchain version check script`
2. `Pin Flutter, Xcode, CocoaPods and the canonical simulator in .toolchain.json`

---

### T01.2 — Scaffold the Flutter app for iOS only

**Goal.** Create the package with exactly one platform and no template cruft, and record **why** that
platform set is a decision rather than an omission.

**The platform decision, recorded in the PR body and in `README.md`.**
- **iOS ships.** It is the only target for now.
- **Android is deferred.** Not unsupported — deferred. Nothing in `lib/` may assume iOS: the
  architecture in `CLAUDE.md` is platform-neutral Dart over Riverpod, drift and go_router, and the one
  platform-touching seam (`HapticGateway`, E06) is an injected interface. Adding Android later is
  `flutter create --platforms=android .` plus one PR to re-add the build job. Generating an `android/`
  directory nobody builds, tests or opens costs a Gradle upgrade treadmill for zero shipped value.
- **macOS is dropped**, reversing the old plan's "development and screenshot-comparison target". It
  earned its place only as a place to eyeball the app; the canonical simulator does that job **better
  and honestly**, because it is exactly 390×844 and a macOS window is whatever the developer dragged it
  to. Keeping macOS would mean a second compile surface, a second Podfile and a second `flutter build`
  in CI for a comparison we no longer make.
- `web/`, `linux/`, `windows/` were never in scope.

**Tests first (TDD).** Author `test/policy/repo_layout_test.dart` on disk **before** running
`flutter create` (it cannot execute yet — the runner arrives with the package; it is committed with the
scaffold in one commit, per the delivery loop's "tests committed with the code they cover"). It asserts,
with `dart:io`:
- `pubspec.yaml` exists and its `name:` is `mindforge`;
- `ios/` exists;
- `android/`, `macos/`, `web/`, `linux/`, `windows/` do **not** exist, each with a `reason:` naming the
  decision above — Android's reason says *deferred*, macOS's says *superseded by the canonical
  simulator*;
- `lib/main.dart` exists;
- `.gitignore` exists and `git check-ignore -v pubspec.lock` exits non-zero, i.e. the lock is **not**
  ignored (`dependency-hygiene` rule 2 — the Dart template ignores it, an app must not).

**Implementation.**
```
flutter create --project-name mindforge --org com.mindforge \
  --platforms=ios \
  --description "Offline brain-training games. No network, no accounts, no telemetry." .
```
`--project-name` is mandatory: the working directory is `E04`, which is not a legal Dart package name.
`--org com.mindforge` combined with `--project-name mindforge` yields the bundle identifier
**`com.mindforge.mindforge`** — write that resulting string into the PR body, because the `--org` flag
alone does not read as what it produces, and a bundle identifier is permanent once the app is published
(risk 8).

Then delete the template's `test/widget_test.dart` (T01.8 writes the real smoke test), delete the
template `README.md` body and replace it with a short pointer to `CLAUDE.md` plus the platform decision
above, and leave the template `analysis_options.yaml` in place until T01.5 replaces it wholesale.

**Files.** `pubspec.yaml`, `pubspec.lock`, `.gitignore`, `.metadata`, `README.md`, `lib/main.dart`,
`ios/**`, `test/policy/repo_layout_test.dart`.

**Skills.** `project-structure-and-packages`, `dependency-hygiene`, `naming-conventions`.

**Screenshot check.** n/a (no visual surface — the template counter app is not a MindForge screen and has
no reference PNG; the first comparison is E03's theme harness).

**Done when.**
- [ ] `flutter test` runs `repo_layout_test.dart` green.
- [ ] `ls` shows `ios/` and no other platform directory.
- [ ] `git status` shows `pubspec.lock` as a tracked file.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_structure.sh lib` exits 0.
- [ ] The resolved bundle identifier `com.mindforge.mindforge` is written into the PR body.

**Commits.**
1. `Scaffold the Flutter app for ios with its layout policy test`
2. `Remove the template widget test and counter README`
3. `Record the ios-only platform decision in README`

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
  a review fails here. E02 and E11 **extend** this file rather than re-authoring it;
- `pubspec.lock` exists and is non-empty;
- no name in the **resolved lock** matches the banned set: `http`, `dio`, `web_socket_channel`,
  `google_fonts`, `firebase_`, `sentry`, `google_mobile_ads`, `in_app_purchase`, `posthog`, `mixpanel`,
  `amplitude`, `device_info_plus`. The reason string quotes the `CLAUDE.md` constraint each one breaks;
- `cupertino_icons` is absent — MindForge draws inline stroke glyphs (`CLAUDE.md`, `lib/ui/glyphs/`).

**Implementation.** Add each package with `dart pub add --dry-run <name>` first, read what the second hop
drags in, then `dart pub add`. **Never hand-write a version number from memory** — record whatever caret
range `pub` writes.

Runtime: `flutter_riverpod` (state + DI, `CLAUDE.md`), `drift` + `sqlite3_flutter_libs` +
`path_provider` (the on-device store, E02), `go_router` (the single router, E08), `clock` (the injected
`Clock`; `DateTime.now()` in domain code is a defect), `flutter_localizations` (sdk) and `intl`. The last
two are **required, not optional, and this epic is where they land**: `flutter gen-l10n` and T01.9's
`AppLocalizations` delegate need `flutter_localizations`, and `intl` is what E04's `LocaleNumbers`
pins Eastern Arabic numerals with — the **one** `NumberFormat` construction site in the app, which
E07's `ScoreFormatter` and E09/E10's HUD values are all fed from rather than each building their own.
An epic that discovers it needs them mid-sequence is the failure this line prevents.
Dev: `very_good_analysis` (T01.5), `build_runner` + `drift_dev` (E02 codegen), `flutter_test` (sdk).

Two deliberate exclusions, both recorded in the PR body:
- **No `golden_toolkit`.** Goldens use the built-in `matchesGoldenFile`; the package adds a dependency to
  wrap what the framework already ships.
- **No `riverpod_generator` / `riverpod_annotation`.** `CLAUDE.md` specifies hand-written
  `Notifier`/`AsyncNotifier` classes over immutable state; the generator buys nothing here and adds a
  builder to every codegen pass.

A third is deliberately **deferred, not excluded**: no Arabic-script font package and no `shamsi_date`
or `hijri`. MindForge shows durations and scores, not calendar dates, and E04 decides whether any
calendar projection is needed at all. If it is, that dependency lands in E04 and extends the frozen
allow-set there.

Remove `cupertino_icons` and `flutter_lints` from the template pubspec. Set `environment: sdk: ^3.12.0`
— a real range, never an exact pin.

**Files.** `pubspec.yaml`, `pubspec.lock`, `test/policy/dependency_policy_test.dart`.

**Skills.** `dependency-hygiene`, `state-management-riverpod`, `testing-strategy`, `i18n-rtl-l10n`
(why `intl` is not optional).

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
3. `Add flutter_localizations and intl for gen-l10n and numeral formatting`
4. `Add build_runner and drift_dev for the codegen path`
5. `Drop cupertino_icons and flutter_lints from the template pubspec`

---

### T01.4 — Configure the iOS target: bundle, localizations and CocoaPods

**Goal.** The iOS target declares the four locales it will ship, names its development region
explicitly, and pins its native dependency graph — before any of that becomes archaeology.

**Why the four locales are declared now, before three of them have a single translated string.** iOS
reads `CFBundleLocalizations` to decide which languages the app is *offered* in. A locale absent from
that array is unreachable no matter how complete `app_fa.arb` is — the pitfall
`i18n-rtl-l10n/references/arb-and-icu.md` names by hand, because nothing in Dart catches it. The
temporary consequence is stated plainly: between E01 and E04 the bundle claims four languages and
resolves all of them to English. **Nothing ships between E01 and E04**, so no user sees the mismatch,
and E04's `check_arb_parity.sh` run is what makes the claim true. The alternative — extend the array in
E04 — puts a plist edit in the middle of a translation epic where it is easy to forget and impossible
to test from Dart.

**Tests first (TDD).** `test/policy/ios_target_test.dart`, written first, red against the template
plist. It reads `ios/Runner/Info.plist` as text and asserts:
- `CFBundleDevelopmentRegion` is the **literal** `en`, not `$(DEVELOPMENT_LANGUAGE)`. The template ships
  the build-setting indirection; the reason string says why the literal wins — a build setting is a
  second place the answer can live, and a policy test that has to resolve `project.pbxproj` to read a
  plist value is a test nobody trusts;
- `CFBundleLocalizations` is an array whose entries are exactly `en`, `de`, `fa`, `ckb`, in that order;
- that list is compared against a single constant also asserted by `test/policy/l10n_posture_test.dart`
  (T01.9), so the plist, the ADR and the ARB directory cannot drift apart;
- the bundle identifier resolves to `com.mindforge.mindforge` (read from `project.pbxproj`'s
  `PRODUCT_BUNDLE_IDENTIFIER`);
- `ios/Podfile` and `ios/Podfile.lock` exist, and `git check-ignore -v ios/Podfile.lock` exits non-zero
  — the lock is tracked, same rule and same reason as `pubspec.lock`;
- `IPHONEOS_DEPLOYMENT_TARGET` in `project.pbxproj` equals the `platform :ios, '<v>'` line in
  `ios/Podfile`. The value itself is **read from what `flutter create` generated, never guessed or
  lowered** — the test pins whatever it is so a later accidental change is a red test.

**Implementation.**
- Edit `ios/Runner/Info.plist`: set `CFBundleDevelopmentRegion` to `en`, add the `CFBundleLocalizations`
  array with `en`, `de`, `fa`, `ckb`.
- Run `flutter build ios --no-codesign` once. This is what materialises `ios/Podfile` (Flutter generates
  it on the first build that has plugins, and T01.3 added `path_provider` and `sqlite3_flutter_libs`),
  runs `pod install`, and writes `ios/Podfile.lock`. Commit both.
- Record the generated `IPHONEOS_DEPLOYMENT_TARGET` in the PR body next to the CocoaPods version, and
  do not change it. Raising it is a product decision; lowering it is a bug.
- **Not done here, and named so the owner is unambiguous:** `ITSAppUsesNonExemptEncryption`, the privacy
  manifest (`PrivacyInfo.xcprivacy`), signing, and any store-facing plist claim. Those are E11's, per
  `release-and-store-shipping`; a claim written now would be a claim nobody re-reads before submission.
  `ckb` may render in the iOS language list under its code rather than a localized language name —
  **unverified**, and verified on device in E11's sweep (risk 12).

**Files.** `ios/Runner/Info.plist`, `ios/Podfile`, `ios/Podfile.lock`, `ios/.gitignore` (only if it
ignores `Podfile.lock`), `test/policy/ios_target_test.dart`.

**Skills.** `i18n-rtl-l10n` (the `CFBundleLocalizations` pitfall), `release-and-store-shipping`
(`references/ios-app-store.md`, the `Info.plist` section and bundle-id permanence),
`dependency-hygiene` (rule 2 applied to `Podfile.lock`), `testing-strategy`.

**Screenshot check.** n/a (no visual surface — the plist has no pixels; T01.10 is where the iOS target
first renders).

**Done when.**
- [ ] `ios_target_test.dart` was seen red, then green.
- [ ] `plutil -p ios/Runner/Info.plist` prints `CFBundleDevelopmentRegion = "en"` and the four-entry
      `CFBundleLocalizations` array; the output is pasted into the PR body.
- [ ] `flutter build ios --no-codesign` succeeds locally.
- [ ] `ios/Podfile.lock` is tracked, and the CocoaPods version that wrote it (1.15.2) is in the PR body.
- [ ] The generated `IPHONEOS_DEPLOYMENT_TARGET` is recorded and unchanged.

**Commits.**
1. `Add the iOS target policy test`
2. `Declare en, de, fa and ckb in CFBundleLocalizations`
3. `Pin the development region to en`
4. `Commit the generated Podfile and Podfile.lock`

---

### T01.5 — Replace the analyzer config with pinned very_good_analysis

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
- the `exclude:` globs cover `**/*.g.dart`, `**/*.freezed.dart`, `**/*.drift.dart` and
  `**/l10n/app_localizations*.dart` — the generated localizations are committed source and must not be
  analyzed as hand-written code;
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

### T01.6 — Create the lib/ skeleton and fence the offline promise

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

**`CLAUDE.md` is already current — this task pins it, it does not rewrite it.** The document was
brought up to date with both new requirements when the eleven-epic plan landed, so all seven of the
edits earlier drafts of this task proposed are **already in the file**:

1. `core/`, `l10n/` and `shared/motion/` in the layout block.
2. Working agreement 10's measured gate-script accounting.
3. Working agreement **11** — directional geometry, with the hard-offset-shadow exception.
4. Working agreement **12** — the numeral policy and the ASCII-before-parse rule.
5. The `Four locales, two RTL` hard-constraint row.
6. The `Bundled fonts` row naming the Arabic-script pair, and the `iOS only` row with the canonical
   simulator UDID.
7. Build order reading **eleven** epics.

**What this task actually ships is the gate that keeps them true.**
`test/policy/project_structure_test.dart` parses `CLAUDE.md`'s layout block and asserts every named
directory exists under `lib/` and that no directory exists under `lib/` that the block does not name —
so the document and the tree cannot drift in either direction. Read the file first and **only edit it
if something above is genuinely missing**; if you find yourself proposing an amendment, check
`git log -- CLAUDE.md` before writing it. **E02, E03, E04 and E06 must not propose any of these
either** — their risk entries point here.

**Files.** `lib/core/.gitkeep`, `lib/theme/.gitkeep`, `lib/ui/components/.gitkeep`,
`lib/ui/glyphs/.gitkeep`, `lib/features/.gitkeep`, `lib/games/.gitkeep`, `lib/data/.gitkeep`,
`lib/l10n/.gitkeep`, `lib/shared/feedback/.gitkeep`, `lib/shared/motion/.gitkeep`,
`lib/routing/.gitkeep`, the matching `test/**/.gitkeep`,
`test/policy/project_structure_test.dart`, `test/policy/banned_imports_test.dart`, and `CLAUDE.md`
**only if the check above finds a genuine gap**.

**Skills.** `project-structure-and-packages`, `testing-strategy`, `ci-pipeline-and-gates`
(`references/policy-grep-gate.md` — the three-criteria bar and accumulate-and-fail-once shape),
`naming-conventions`.

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] Both policy tests were seen red, then green.
- [ ] `CLAUDE.md` was read and confirmed current: layout block lists `core/`, `l10n/` and
      `shared/motion/`; working agreements 10, 11 and 12 are present; the `Four locales, two RTL`,
      `Bundled fonts` and `iOS only` constraint rows are present; Build order says eleven epics. Any
      edit made here is listed in the PR body with what was missing.
- [ ] `.claude/skills/project-structure-and-packages/scripts/check_structure.sh lib` and
      `check_import_boundaries.sh lib` both exit 0.
- [ ] `.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh lib` exits 0.

**Commits.**
1. `Add project structure and banned-import policy tests`
2. `Pin the CLAUDE.md layout block with a structure policy test`
3. `Add the lib and test directory skeleton from CLAUDE.md`

---

### T01.7 — Bundle Fredoka and Nunito with their OFL texts

**Goal.** The two Latin type families ship inside the binary, licensed correctly, with no runtime fetch —
the one place the offline promise touches a design decision.

**Ownership, and the honest limit of it.** The **Latin pair is bundled here and only here.** E01 owns
`pubspec.yaml` and creates `lib/theme/font_licences.dart` with the single
`registerSunburstFontLicences()` every later face is registered through. There is never a second
registration function.

**Fredoka and Nunito have no Arabic-script coverage.** After this task the app can render `en` and `de`
and nothing else; `fa` and `ckb` would tofu. **E03 is the only other epic permitted to touch
`flutter: fonts:`**: E03 T03.7 bundles Vazirmatn for body (OFL, full Persian and Sorani coverage),
decides between Lalezar and Vazirmatn's heaviest bundled weight for display **from the font's own
`cmap` and `GSUB`/`GPOS` tables** rather than from a foundry page, and E03 T03.9 declares the
per-script `fontFamilyFallback` cascade `design-system-structure` rule 10 requires. E03 owns the
Arabic faces because its own T03.9 has to *measure* Arabic line boxes to ship `arabicLineFactor`, and
it cannot measure a face that is not on disk. **E04 bundles no font at all**; it verifies E03's cascade
against the translated corpus once the ARBs exist. This task must not pretend to be the whole font
story, and `font_declaration_test.dart` below is written so **E03** extends its expected set rather
than rewriting it.

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
- `test/theme/font_licence_test.dart` — after calling `registerSunburstFontLicences()`, draining
  `LicenseRegistry.licenses` yields an entry whose `packages` contains `Fredoka` and another whose
  `packages` contains `Nunito`, and each entry's text contains `SIL OPEN FONT LICENSE`.
- `test/policy/font_declaration_test.dart` — `pubspec.yaml` declares exactly the four (family, weight)
  pairs `sunburst-tokens/references/shape-and-type.md` names: Fredoka 600, Fredoka 700, Nunito 700,
  Nunito 800. The expected set is a named `const` list with a comment stating that **E03 T03.7 appends
  the Arabic-script faces to this list and to nothing else**; a fifth weight added without editing the
  list fails.

**Implementation.** Prefer static instances (`Fredoka-SemiBold.ttf`, `Fredoka-Bold.ttf`,
`Nunito-Bold.ttf`, `Nunito-ExtraBold.ttf`). If upstream ships only a variable font for a family, bundle
the single variable TTF, declare the family once without per-weight `asset:` entries, and drive weight
with `FontWeight` alone — never a redundant `FontVariation('wght', …)`; record which shape was used.

Declare under `flutter: fonts:` in `pubspec.yaml`. Ship **two** licence files,
`assets/fonts/OFL-Fredoka.txt` and `assets/fonts/OFL-Nunito.txt` — the skill's example names one
`OFL.txt`, but the two families carry different copyright holders and a single file would misattribute
one of them. E03 T03.7 adds a third (and possibly fourth) beside them under the same convention.
`lib/theme/font_licences.dart` holds `void registerSunburstFontLicences()`, which calls
`LicenseRegistry.addLicense` once per family with `LicenseEntryWithLineBreaks`. It sits in `lib/theme/`
because that is the only directory where a font-family string may appear.

**Files.** `assets/fonts/*.ttf`, `assets/fonts/OFL-Fredoka.txt`, `assets/fonts/OFL-Nunito.txt`,
`pubspec.yaml`, `lib/theme/font_licences.dart`, `test/theme/font_assets_test.dart`,
`test/theme/font_licence_test.dart`, `test/policy/font_declaration_test.dart`.

**Skills.** `design-system-structure` (`references/typography-and-fonts.md`, including the
per-script fallback rule this epic can only half-satisfy), `sunburst-tokens`
(`references/shape-and-type.md`, the four weight pairs only), `i18n-rtl-l10n` (rule 9: bundle fonts
covering every shipped script — the reason the incompleteness is stated rather than left implicit),
`dartdoc-conventions` (`///` on `registerSunburstFontLicences`).

**Screenshot check.** n/a (no visual surface yet — nothing renders these faces until E03 builds
`SunburstType`; the first type comparison is against `design/sunburst-pop/screens/01-home.png` in E03,
and the first Arabic-script type comparison is against the RTL set E04 produces).

**Done when.**
- [ ] All three tests were seen red, then green.
- [ ] `.claude/skills/design-system-structure/scripts/check_font_bundling.sh lib` exits 0.
- [ ] `grep -rn "google_fonts" .` finds nothing outside `.claude/skills/` and this epic file.
- [ ] The font file byte sizes are plausible (tens to hundreds of KB, not bytes) and are noted in the PR.
- [ ] The PR body states in one line that the bundle covers Latin only and names E04 as the epic that
      adds Arabic-script coverage.

**Commits.**
1. `Add the font asset, licence and declaration tests`
2. `Bundle Fredoka and Nunito TTFs with their OFL texts`
3. `Declare the Fredoka and Nunito families in pubspec`
4. `Register the bundled font licences with LicenseRegistry`

---

### T01.8 — Write bootstrap(), the thin entrypoint, and the smoke test

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
  `WidgetsFlutterBinding.ensureInitialized()`, `installErrorHandlers()`, `registerSunburstFontLicences()`,
  `runApp(ProviderScope(retry: (count, error) => null, child: const MindForgeApp()))`.
  `installErrorHandlers()` lives in the same file as the composition root it serves: `FlutterError.onError`
  calls `FlutterError.presentError` then `debugPrint` under `kDebugMode`, wrapped in a bare `try/catch (_)`
  with the load-bearing comment; `PlatformDispatcher.instance.onError` does the same and returns `true`
  unconditionally.
- `lib/app.dart`: `class MindForgeApp extends StatelessWidget` building
  `MaterialApp(title: 'MindForge', home: Scaffold())`. **No `theme:`, no `darkTheme:`, no `themeMode:`** —
  E03 owns the theme, and a placeholder theme here would be a token value this epic promised not to ship.
  No `locale:` either: the app follows the device in v1 and E04 adds the persisted override, reading it
  before `runApp` per `app-startup-and-bootstrap` rule 5.

Three things `app-startup-and-bootstrap` describes that are deliberately **not** built yet, each named in
the PR body so the owning epic is unambiguous: a durable on-device crash sink (there is nowhere to write
it until E02 opens the database — the handlers report to the console for now), the root
`WidgetsBindingObserver` that flushes on background (there is no durable state to flush until E02), and
the read-locale-before-first-frame step (there is no persisted locale until E02 and no locale controller
until E04).

**Files.** `lib/main.dart`, `lib/bootstrap.dart`, `lib/app.dart`, `test/bootstrap_test.dart`,
`test/app_test.dart`, `test/policy/startup_policy_test.dart`.

**Skills.** `app-startup-and-bootstrap`, `state-management-riverpod` (the `ProviderScope` retry policy),
`testing-strategy`, `naming-conventions`, `dartdoc-conventions`.

**Screenshot check.** n/a (no visual surface — the app boots to an empty `Scaffold`; there is no reference
PNG for a theme-less screen, and none should be created. T01.10 captures a launch *proof*, not a screen
comparison; the first screenshot comparison in the project is E03's theme harness against
`design/sunburst-pop/screens/`).

**Done when.**
- [ ] All three tests were seen red, then green.
- [ ] `grep -rn "runZonedGuarded" lib/` is empty.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` is clean, including `public_member_api_docs` on
      every new public declaration.

**Commits.**
1. `Add bootstrap, smoke and startup policy tests`
2. `Add bootstrap with the two error handlers`
3. `Add the thin main entrypoint and MindForgeApp`

---

### T01.9 — Wire gen-l10n, seed the English ARB, and record ADR 0001

**Goal.** Settle the localisation posture **once, before any epic ships a string**, wire the toolchain
that decision implies, seed a template with real keys so gen-l10n has something to build, and take the
two cheap measurements that de-risk E04's hardest task — so E04's translations, E08's Settings rows and
E09/E10's HUD labels all build against a contract that already exists.

**Why here and not in E04.** E04 is the localization epic, but the *toolchain* has to exist before the
first string does, and E08, E09 and E10 each ship strings. A posture decided after them is a posture
three epics have already guessed at. E04's job is to fill the contract with three more locales, the
`ckb` delegate, the numeral formatter, the bidi helper and the RTL geometry sweep — not to invent the
contract.

**The decision, recorded in `docs/decisions/0001-localisation.md`.**

- **Four locales.** `en` is the template and the source of truth for keys. Supported set: `en`, `de`,
  `fa`, `ckb`. Resolution: the system locale if it is supported, otherwise `en`. The user can override
  it in Settings and the choice persists — the override lands in E04 on top of E02's persistence, which
  is exactly why persistence sits ahead of localization in the epic order.

  | Locale | Code | Direction | Role |
  |---|---|---|---|
  | English | `en` | LTR | template ARB, source of truth for keys |
  | German | `de` | LTR | longest strings — the text-expansion stress case (~30% longer) |
  | Persian | `fa` | RTL | Arabic script, Eastern Arabic numerals |
  | Kurdish Sorani | `ckb` | RTL | Arabic script plus the Sorani letters ڕ ڵ ۆ ێ ھ |

- **gen-l10n now, one locale shipped in this epic.** Every user-facing string lives in an ARB and is read
  through `AppLocalizations`. `nullable-getter: false` turns a missing key into a compile error, which is
  a stronger guarantee than any grep over hardcoded literals.
- **`intl` is a dependency regardless** (T01.3), so the marginal cost of gen-l10n is `l10n.yaml`, one
  `flutter: generate: true` line and one delegate list.
- **Seeded generation stays locale-independent** — stated here so E07 and E10 inherit it rather than
  discovering it: generators produce integers and semantic tokens, and localisation happens at render.
  A golden vector must not change because the locale changed. E07 owns the test that proves it.
- **The honest cost, measured:** `check_arb_parity.sh` exits 2 on a directory holding only the template
  (`FAIL: no locale ARB files (app_*.arb) beside the template`). It stays in `tool/skill_gates.sh`'s skip
  table with that measured reason until E04 lands `app_de.arb`, `app_fa.arb` and `app_ckb.arb`.
  `check_i18n_bans.sh lib` is the half that *is* meaningful at one locale, and it runs from this epic
  onward — it is the gate that keeps E04 a string job instead of a layout rewrite.
- **The alternative considered and rejected** — English-only with a `const` string map — and the trigger
  that would reverse the four-locale decision (no native reviewer is ever found for `ckb`, and shipping
  machine-quality Sorani is judged worse than shipping three locales).
- **The two measurements below are pasted into the ADR verbatim**, so E04 plans against facts.

**The two measurements — verify, do not assume.** Both are one-line facts about *this* Flutter and
*this* `intl`, and both are the reason E04's `ckb` delegate task exists:
1. `GlobalMaterialLocalizations.delegate.isSupported(...)` for `en`, `de`, `fa`, `ckb`. Run it, read it,
   assert what it returned. `i18n-rtl-l10n/references/arb-and-icu.md` says `ckb` is not in the built-in
   list; this epic **confirms it on 3.44.6** rather than quoting the reference.
2. Whether `intl`'s `numberFormatSymbols` contains a `ckb` entry. The skill says it does not and that the
   fix is pinning `ckb` to `fa`. Confirm it, and record the exact `intl` version from `pubspec.lock` next
   to the result.

If either measurement comes out the other way, say so in the PR body and in the ADR: E04's delegate task
becomes a verification instead of a build, and the epic is corrected rather than silently over-built.

**Tests first (TDD).**
- `test/policy/l10n_posture_test.dart`, written first, red against the empty tree. It pins the ADR so
  the posture cannot rot half-adopted:
  - `l10n.yaml` exists and declares `arb-dir: lib/l10n`, `template-arb-file: app_en.arb`,
    `output-dir: lib/l10n`, `output-localization-file: app_localizations.dart`,
    `output-class: AppLocalizations`, `nullable-getter: false`, `required-resource-attributes: true`,
    `format: true`;
  - the string `synthetic-package` appears **nowhere** in `l10n.yaml`. Measured on 3.44.6:
    `flutter gen-l10n --help` prints "DEPRECATED. This flag cannot be enabled and should be removed."
    The old plan's `synthetic-package: false` is now wrong;
  - `suppress-warnings` appears nowhere — the untranslated-message warning is the signal E04 depends on;
  - `pubspec.yaml` contains `generate: true` under its `flutter:` key, and lists both
    `flutter_localizations` (sdk) and `intl`;
  - `lib/l10n/app_en.arb` exists, parses as JSON, has `"@@locale": "en"`, every non-`@` key matches
    `^[a-z][a-zA-Z0-9_]*$`, and **every** message key has a matching `@key` object with a non-empty
    `description` (the contract `required-resource-attributes: true` enforces at generation time and this
    test enforces at review time — a translator working into Sorani cannot guess context);
  - the supported-locale constant is exactly `['en', 'de', 'fa', 'ckb']` and equals the list
    `test/policy/ios_target_test.dart` asserts in `CFBundleLocalizations`. One constant, two assertions,
    no drift;
  - `lib/app.dart` names `AppLocalizations.localizationsDelegates` and `AppLocalizations.supportedLocales`;
  - the reason string on each expectation cites `docs/decisions/0001-localisation.md`, so re-opening
    the decision reds this test rather than silently drifting.
- `test/l10n/app_localizations_test.dart` — pump a `MaterialApp` with the delegates under
  `Locale('en')` and assert all six seeded keys resolve to their exact English strings:
  `appTitle` → `MindForge`, `homeTagline` → `Train your brain. No wifi needed.`,
  `homeYourGames` → `Your games`, `actionPlay` → `Play`, `labelBest` → `BEST`,
  `settingsLanguage` → `Language`. It is red until `flutter gen-l10n` has run.
- `test/l10n/material_delegate_support_test.dart` — a characterization test carrying measurement 1.
  It asserts `GlobalMaterialLocalizations.delegate.isSupported(...)` for each of the four locales, with
  the expected value **written from the observed run**, and a comment stating that this is a measured
  fact about `flutter_localizations` at Flutter 3.44.6 and that E04's custom `LocalizationsDelegate`
  exists because of whatever it returned for `ckb`.

**Implementation.**
- `l10n.yaml` at the repo root with exactly the keys the test asserts. `output-dir: lib/l10n` puts the
  generated `AppLocalizations` in `lib/l10n/` as real, greppable source rather than inside `.dart_tool/`,
  which keeps `check_import_boundaries.sh` and every policy grep honest. `format: true` is load-bearing,
  not cosmetic: the generated files are committed and CI runs `dart format --set-exit-if-changed .`, so
  unformatted generated output would fail the format gate on a file no human wrote.
- **`use-escaping` is deliberately left unset and named as E04's call**, with the reason written into the
  ADR: turning it on changes how existing messages parse, so it must be decided *before* three locales of
  copy exist, not after. None of the six seeded keys contains a `{`, `}` or an apostrophe, so E01 is
  unaffected either way. `untranslated-messages-file` is likewise E04's — it has nothing to report at one
  locale.
- `lib/l10n/app_en.arb` with six real keys, each with its `@key` description. They are real strings read
  off `design/sunburst-pop/app.html`, not placeholders, so gen-l10n exercises a genuine template and E04
  has something true to translate on day one:

  | Key | English value | Where it renders |
  |---|---|---|
  | `appTitle` | `MindForge` | app title; the wordmark on Home |
  | `homeTagline` | `Train your brain. No wifi needed.` | Home subtitle (`01-home.png`) |
  | `homeYourGames` | `Your games` | Home section heading (`01-home.png`) |
  | `actionPlay` | `Play` | the primary button (`02-game-detail.png`) |
  | `labelBest` | `BEST` | the best-score pill (`01-home.png`) |
  | `settingsLanguage` | `Language` | Settings row label (`08-settings.png`) |

  No ICU plural or select key is seeded. E04 authors the first one, because the plural-category contract
  (`fa` and `ckb` categories, and German's own) is a translation decision, not a scaffolding one.
  `appTitle` and `homeTagline` are the two that will need bidi isolation once `fa` lands —
  "MindForge" is a Latin run inside RTL copy — and E04's helper is what does it.
- `pubspec.yaml`: `generate: true` under `flutter:`.
- `lib/app.dart` (edit): `localizationsDelegates: AppLocalizations.localizationsDelegates`,
  `supportedLocales: AppLocalizations.supportedLocales`. Still **no `theme:`** — E03 owns that.
- The generated `lib/l10n/app_localizations*.dart` are **committed**, consistent with T01.12's
  generated-code decision, and covered by the same `git diff --exit-code` freshness gate.
- `tool/skill_gates.sh` does not exist yet; T01.11 places `check_i18n_bans.sh` in its run table and
  `check_arb_parity.sh` in its skip table with the measured reason from this task.

**Files.** `docs/decisions/0001-localisation.md`, `l10n.yaml`, `lib/l10n/app_en.arb`,
`lib/l10n/app_localizations.dart` + `lib/l10n/app_localizations_en.dart` (generated, committed),
`pubspec.yaml`, `lib/app.dart`, `test/policy/l10n_posture_test.dart`,
`test/l10n/app_localizations_test.dart`, `test/l10n/material_delegate_support_test.dart`.

**Skills.** `i18n-rtl-l10n` (the whole gen-l10n contract, the ARB workflow, the `ckb` delegate warning,
the `ckb`-has-no-`intl`-symbols warning), `codegen-and-toolchain` (generated output is committed and
freshness-gated; codegen runs before analyze), `dependency-hygiene`, `testing-strategy`.

**Screenshot check.** n/a (no visual surface — none of the six keys renders on a screen until E08, which
compares `01-home.png` and its RTL counterpart from `design/sunburst-pop/screens/rtl/`).

**Done when.**
- [ ] All three tests were seen red, then green.
- [ ] `flutter gen-l10n` exits 0 and the generated files are committed, formatted and diff-clean.
- [ ] `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` exits 0.
- [ ] `check_arb_parity.sh lib/l10n` was run once by hand and its exit-2 output is pasted into the PR
      body beside its skip-table reason — the skip is measured, not assumed.
- [ ] Both `ckb` measurements were run and their results are pasted verbatim into ADR 0001 and the PR
      body, each with the version of the package measured.
- [ ] ADR 0001 names the four locales, the fallback rule, the rejected alternative, the measured costs,
      the `use-escaping` deferral and the reversal trigger.

**Commits.**
1. `Record the four-locale localisation decision as ADR 0001`
2. `Add the l10n posture policy test`
3. `Add l10n.yaml and the seeded English ARB template`
4. `Commit the generated AppLocalizations`
5. `Wire AppLocalizations delegates into MindForgeApp`
6. `Record the measured ckb delegate and intl symbol gaps`

---

### T01.10 — Boot the canonical simulator and run MindForge on it

**Goal.** Prove the app launches on the exact device every screenshot comparison in this project will be
made on, and make that device a scripted constant rather than a note in a file nobody reads.

**Why this device and no other.** Every reference PNG under `design/sunburst-pop/screens/` is 780×1688
pixels — **390×844 logical points at 2×**. `MindForge iPhone 14` (UDID
`C13DDC02-375D-4E1B-8F81-44EB407D09A4`, iOS 18.6) is exactly 390×844 logical points. **No iPhone
16-class simulator matches**: iPhone 16 is 393×852 and 16 Pro is 402×874. A screenshot taken on those
is a comparison against a different canvas, and every spacing judgement made from it is wrong by a
few points in a way that is invisible until it accumulates. The device already exists on this machine;
this task does not create it.

**The one honest caveat, written into `design/sunburst-pop/screens/README.md`.** The reference PNGs are
2× (780×1688); the iPhone 14 simulator renders at 3× (1170×2532). The **logical geometry matches
exactly** and the pixel density does not, so the comparison is the one the README already prescribes —
structure, then spacing rhythm, then surface construction, then type role, then sampled hex — and never
a pixel diff. No available simulator is 390×844 at 2×, so this is a property of the target hardware, not
a shortcut.

**Tests first (TDD).** `bash tool/ios_simulator.sh verify` is written before the runner and driven
through three observed states:
- an unknown UDID in `.toolchain.json` → exits 1, message prints the UDID it looked for and the
  `xcrun simctl list devices` line it could not find;
- the real UDID but a mismatched `runtime` → exits 1 naming both;
- the real record → exits 0, printing name, UDID, runtime and `390x844`.
Plus `test/policy/simulator_record_test.dart`: `.toolchain.json` parses as JSON, its `simulator.udid`
matches `^[0-9A-F-]{36}$`, its `logicalSize` is `390x844`, and `tool/ios_simulator.sh` contains no
hard-coded UDID of its own — it reads the record, so there is one place the device is named.

**Implementation.** `tool/ios_simulator.sh` with four subcommands, all reading `.toolchain.json`:
- `verify` — the assertions above;
- `boot` — `xcrun simctl boot <udid>` (idempotent: a `Booted` device is not an error) then
  `open -a Simulator`;
- `run` — `verify`, `boot`, then `flutter run -d <udid>`;
- `shot <path>` — `xcrun simctl io <udid> screenshot <path>`.

Run it, launch the app, and capture `docs/verification/e01-simulator-launch.png`. The screenshot shows a
blank white `Scaffold` — that is the whole point: it proves the binary built, the pods linked, the
bundle loaded, the error handlers did not fire and `MindForgeApp` mounted on a 390×844 device. It is a
**launch proof, not a screen comparison**, and it is filed under `docs/verification/` precisely so it is
never mistaken for a reference target.

Amend `design/sunburst-pop/screens/README.md` step 1: replace "iPhone 14 simulator, or `flutter run -d
macos` with the window sized to match" with the canonical device, its UDID, the `tool/ios_simulator.sh`
commands, and the 2×/3× note above. macOS is no longer a platform (T01.2), so leaving that sentence in
place would send the next agent to a target that does not exist.

**This verification is local and human-run, not a CI gate.** The canonical simulator is a machine-local
device; a GitHub runner has no `C13DDC02-…`. T01.12's `build-ios` job proves the tree compiles; it
cannot prove it launches. That is stated in `ci.yml`'s limits comment.

**Files.** `tool/ios_simulator.sh`, `test/policy/simulator_record_test.dart`,
`docs/verification/e01-simulator-launch.png`, `design/sunburst-pop/screens/README.md`.

**Skills.** `ci-pipeline-and-gates` (rule 10: state plainly what CI cannot prove, so the manual pass is
a load-bearing artifact), `testing-strategy`, `release-and-store-shipping` (device-verification posture;
nothing is built for release here).

**Screenshot check.** `docs/verification/e01-simulator-launch.png` — a launch proof at 1170×2532,
captured on `MindForge iPhone 14`. **Not** compared against any file in
`design/sunburst-pop/screens/`: there is no reference PNG for a theme-less blank screen and none should
be created. The first true comparison is E03's, against `01-home.png`; the first RTL comparison is E08's,
against the `design/sunburst-pop/screens/rtl/` set E04 produces.

**Done when.**
- [ ] The three `verify` states were each observed once.
- [ ] `bash tool/ios_simulator.sh run` boots the device and launches MindForge to a blank white screen,
      with no console exception and no framework error overlay.
- [ ] `docs/verification/e01-simulator-launch.png` is committed and is 1170×2532.
- [ ] `design/sunburst-pop/screens/README.md` names the canonical device and the 2×/3× caveat, and no
      longer mentions macOS.

**Commits.**
1. `Add the simulator record policy test`
2. `Add tool/ios_simulator.sh for the canonical device`
3. `Capture the first launch on MindForge iPhone 14`
4. `Point the screens README at the canonical simulator`

---

### T01.11 — Wrap every skill gate script in one enumerated runner

**Goal.** One command runs every skill gate that is a gate, and a newly added skill script cannot be
silently left unrun. **This runner is the project's only sanctioned way to run the skill gates.** Every
epic from E02 onward calls `bash tool/skill_gates.sh` in its Gates section; a raw
`for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done` loop is a defect, not a stricter gate —
measured, 29 of the 49 scripts exit non-zero with no argument and five of them structurally never can.

**Tests first (TDD).** `test/policy/skill_gates_coverage_test.dart`, written first, asserting that every
`*.sh` under `.claude/skills/*/scripts/` appears **exactly once** in `tool/skill_gates.sh` — either in the
run table or in the skip table with a non-empty reason. Red today: there are 49 scripts and no table. It
fails once with the full list of unlisted scripts, never one at a time.

**Implementation.** `tool/skill_gates.sh` holds two explicit tables. Read each script's header before
assigning it a row; the reason recorded must be true.

Run, with the argument each script actually takes (most default to `lib`; three are different):
- `check-determinism-bans.sh` is passed `lib` explicitly — its default is `lib/core/`, and while
  `lib/core/` exists from T01.6, the ban applies to the whole tree, not just the pure layer (E09's
  generator lives under `lib/games/stroop_rush/domain/`);
- `check_palette_contrast.sh` is passed nothing and reads its default theme **file**, which does not
  exist until E03 and exits 0 cleanly today;
- `check_i18n_bans.sh` is passed `lib` and is in the **run** table from this epic on. It is the half of
  the i18n discipline that is meaningful at one locale, and the gate that keeps E04's RTL work a string
  job rather than a layout rewrite.

**The tables are living.** A later epic that creates a script's target moves its row from skip to run in
the same PR, and `skill_gates_coverage_test.dart` — which asserts each script appears **exactly once** —
is what forces the move to be deliberate. E04 does this for `check_arb_parity.sh`; E08 does it for
`scaffold-feature-module/scripts/verify_feature.sh`.

Skip, each with the stated reason:
- `i18n-rtl-l10n/scripts/check_arb_parity.sh` — **measured: it exits 2 on a directory holding only the
  template** (`FAIL: no locale ARB files (app_*.arb) beside the template`). This epic ships `app_en.arb`
  alone, so there is nothing to compare it against. **E04 moves this row to the run table in the same PR
  that lands `app_de.arb`, `app_fa.arb` and `app_ckb.arb`**, with the argument `lib/l10n`.
- `ci-pipeline-and-gates/scripts/ci-gates.sh` — re-runs format/analyze/test/build_runner; the workflow
  runs those as named steps, and nesting them hides which one failed.
- `codegen-and-toolchain/scripts/regen.sh` — mutates the tree; a gate never blesses.
- `lint-and-style-config/scripts/lint-gates.sh` and `custom-canvas-and-gestures/scripts/analyze.sh` —
  format/analyze wrappers, duplicating named workflow steps.
- `testing-strategy/scripts/run_tests.sh` — duplicates the test step.
- `scaffold-feature-module/scripts/scaffold_feature.sh` — a generator, not a check.
- `scaffold-feature-module/scripts/verify_feature.sh` — takes one feature directory; run per feature by
  E08/E09/E10, not repo-wide.
- `service-boundary-and-native/scripts/check-flavor-graph.sh` — requires a `BANNED_REGEX` argument and a
  flavor graph; MindForge ships no flavors.
- `release-and-store-shipping/scripts/check-ipa-slices.sh` — needs a built IPA; **E11** owns it.

`release-and-store-shipping/scripts/check-release-hygiene.sh` is run first and its result decides its row.
**Re-read its output on this tree rather than assuming the old outcome**: the previous accounting was
taken against a plan with an `android/` directory, and this repository has none, so its Gradle-signing
checks may behave differently. If it passes on a pre-release iOS-only tree, it runs; if it fails only on
release-stage concerns (signing, version bump), it moves to the skip table with that reason and a pointer
to E11.

**Bash 4 is now a hard requirement of the runner, and CI no longer supplies it for free.**
`local-notifications-scheduler/scripts/check-scheduler-purity.sh` uses `mapfile` and exits 127 on bash
3.2. The old plan relied on the Ubuntu runner shipping bash 5; T01.12 moves CI to macOS, whose
`/bin/bash` is also 3.2. So `tool/skill_gates.sh` **exits 2 with a named message** when
`BASH_VERSINFO[0] < 4` instead of merely warning, and both the local instructions (`brew install bash`)
and the CI step (T01.12) provide a bash 5 explicitly. **Do not edit a skill script to work around this**
— the skill library is not this epic's to change.

**Files.** `tool/skill_gates.sh`, `test/policy/skill_gates_coverage_test.dart`.

**Skills.** `ci-pipeline-and-gates` (rule 1: one named contract per gate; rule 9: gates verify, never
mutate), `testing-strategy`, `i18n-rtl-l10n` (which of its two scripts can run at one locale).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] The coverage test was seen red (49 unlisted scripts), then green.
- [ ] `bash tool/skill_gates.sh` exits 0 under bash 4+ and prints one `RUN <script> → exit 0` or
      `SKIP <script> — <reason>` line per script.
- [ ] Running it under `/bin/bash` (3.2) exits 2 with the named message, and that was observed once.
- [ ] Every skip reason names a structural fact, never "it fails".
- [ ] `check_arb_parity.sh`'s skip row names E04 as the epic that moves it.

**Commits.**
1. `Add the skill-gate coverage policy test`
2. `Add tool/skill_gates.sh with an explicit run and skip table`
3. `Require bash 4 or newer in the gate runner`

---

### T01.12 — Add the macOS CI workflow and the pull request template

**Goal.** The pipeline exists, runs on the platform the app ships on, is pinned, blocks on every
contract, and states what it cannot prove.

**Tests first (TDD).** `test/policy/ci_workflow_test.dart`, written first, asserting over
`.github/workflows/ci.yml` as text:
- every `runs-on:` value is a pinned macOS label and `macos-latest` appears nowhere
  (`ci-pipeline-and-gates` rule 2 — image drift moves Xcode and lcov with no diff to review);
- `ubuntu-` appears nowhere — the app is iOS-only and a Linux job would prove something about a platform
  that is not shipped;
- `subosito/flutter-action@v2` appears and `channel: stable` is set;
- the pinned `flutter-version:` string equals the `flutter` value in `.toolchain.json` — the workflow
  and the record cannot drift;
- each of these substrings appears: `tool/check_toolchain.sh`, `flutter gen-l10n`,
  `dart format --output=none --set-exit-if-changed .`, `build_runner build --delete-conflicting-outputs`,
  `git diff --exit-code`, `flutter analyze --fatal-infos --fatal-warnings`,
  `--test-randomize-ordering-seed random`, `tool/skill_gates.sh`, `check_i18n_bans.sh`,
  `flutter build ios --no-codesign`;
- `continue-on-error` and `--update-goldens` appear nowhere.
And over `.github/PULL_REQUEST_TEMPLATE.md`: the five headings required by the delivery loop are present.

**Implementation.** `.github/workflows/ci.yml`, one file, `on: [push to main, pull_request]`, with
`concurrency` (cancel-in-progress) and `permissions: contents: read`.

Job `verify`, `runs-on: macos-15`  `# VERIFY: confirm this label is a current GitHub-hosted image`,
`timeout-minutes: 30`, steps in this order — the order is the contract, and codegen before analyze is
`codegen-and-toolchain` rule 1:
1. `actions/checkout@v4`  `# VERIFY: confirm current major`
2. `subosito/flutter-action@v2` with `channel: stable`, `flutter-version: '3.44.6'`, `cache: true`
3. record the host tools: `bash --version`, `xcodebuild -version`, `pod --version`, `sw_vers`. Not a
   gate — a log line, so a failure caused by an image bump is diagnosable from the run alone.
4. provide bash 5: `brew install bash` unless the image already ships one on `PATH`
   `# VERIFY: check whether the image's default bash is already 4+`. The `verify` step below runs the
   gate runner under it. This is the step that replaces what the Ubuntu runner used to give for free.
5. `flutter pub get`
6. `TOOLCHAIN_HOST_TOOLS=warn bash tool/check_toolchain.sh` — the runner's Flutter must equal
   `.toolchain.json`; its Xcode and CocoaPods are logged as `WARN`, with a comment naming the reason:
   the image's Xcode is not ours to pin to 26.6, and failing on a fact we do not control is not a gate.
7. `flutter gen-l10n`
8. codegen freshness: `dart run build_runner build --delete-conflicting-outputs` then
   `git diff --exit-code -- '*.g.dart' '*.freezed.dart' '*.drift.dart' 'lib/l10n/app_localizations*.dart'`,
   failing with an `::error::` telling the author to regenerate and commit. No `build_runner` generator
   is wired yet, so that half passes trivially today; the l10n half is live from this epic. The decision
   recorded here is **generated code is committed**, and a committed-generated-code policy without its
   freshness gate is not a policy.
9. `dart format --output=none --set-exit-if-changed .`
10. `flutter analyze --fatal-infos --fatal-warnings`
11. `flutter test --test-randomize-ordering-seed random --reporter expanded`
12. `<bash5> tool/skill_gates.sh`
13. `.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh lib` as a **named** step in addition to the
    runner, with a comment naming the contract it blocks on: geometry stays Directional so E04's RTL
    work is a string job, not a layout rewrite. Named separately because it is the one gate whose
    failure a reviewer needs to see by name in the checks list.

Job `build-ios`, `runs-on: macos-15`, `timeout-minutes: 40`, same toolchain pin, running
`flutter build ios --no-codesign`. One named contract: **the tree compiles for the shipping platform,
not merely analyzes**. Sealed-switch exhaustiveness is a compile error, not a lint, and an analyze-only
pipeline goes green over code that will not build (`lint-and-style-config` rule 7). `--no-codesign` is
what makes it runnable without a signing identity in the repository; signing belongs to E11.

Two costs, stated in the PR body rather than discovered on the invoice: GitHub bills macOS minutes at a
multiple of Linux, and `pod install` plus an iOS compile are slower than an APK. Accepted, because iOS
is the only shipping target and a Linux job would prove the wrong thing.

No `apt install sqlite3` step — that was Ubuntu's problem. macOS ships `libsqlite3`, so `flutter test`
in the Dart VM can open a database; **E02 verifies that on the runner when the first drift test lands**
and adds whatever the test host needs if it turns out not to be true.

A comment block at the top of the file names what CI cannot prove: font rendering, haptics, motion and
press physics, screenshot parity against `design/sunburst-pop/screens/`, RTL rendering and Arabic-script
shaping, **and that the app launches at all** — the canonical simulator is a machine-local device
(T01.10) and no runner has it. Those belong to the local pass and to E11's `design-review-workflow`
sweep.

`.github/PULL_REQUEST_TEMPLATE.md` **already exists** — it was added with the repository's README,
LICENSE and CONTRIBUTING.md before this epic began. Do not recreate it. This task only *verifies* it
against `test/policy/ci_workflow_test.dart` and extends it if a gate command changed, since the
template's checklist quotes `tool/skill_gates.sh`, which this epic creates. It carries exactly the
five sections the delivery loop requires:
**What changed**, **Why**, **How it was verified** (the gate commands and their output), **Screens
compared** (the PNG filenames — LTR from `design/sunburst-pop/screens/`, and from E04 on the RTL
counterpart from `design/sunburst-pop/screens/rtl/` — and the fixed comparison order: structure →
spacing rhythm → surface construction → type role → sampled hex), **Deliberately left out**.

**Files.** `.github/workflows/ci.yml`, `.github/PULL_REQUEST_TEMPLATE.md`,
`test/policy/ci_workflow_test.dart`.

**Skills.** `ci-pipeline-and-gates`, `codegen-and-toolchain`, `lint-and-style-config`,
`dependency-hygiene`, `i18n-rtl-l10n` (which gate runs and why).

**Screenshot check.** n/a (no visual surface).

**Done when.**
- [ ] The workflow policy test was seen red, then green.
- [ ] The PR opened for this epic ran the workflow and **both jobs are green** — this is the first PR in
      the project whose own pipeline can be waited on.
- [ ] `gh run view --log` shows every step executed; none skipped, none `continue-on-error`.
- [ ] The runner's `xcodebuild -version` and `bash --version` are read out of the log and pasted into the
      PR body beside the local versions, so the gap is recorded rather than assumed away.
- [ ] Every `# VERIFY:` marker was resolved before merge, or is still present with the reason it could
      not be confirmed.
- [ ] The PR body was written from the template and every section is filled.

**Commits.**
1. `Add the CI workflow policy test`
2. `Add the GitHub Actions CI workflow on a macOS runner`
3. `Run gen-l10n and check_i18n_bans.sh in CI`
4. `Add the pull request template`

## Gates that must pass

```bash
# Toolchain and device
bash tool/check_toolchain.sh
bash tool/ios_simulator.sh verify

# Package
flutter pub get
flutter gen-l10n
dart run build_runner build --delete-conflicting-outputs
git diff --exit-code -- '*.g.dart' '*.freezed.dart' '*.drift.dart' 'lib/l10n/app_localizations*.dart'
dart format --output=none --set-exit-if-changed .
flutter analyze --fatal-infos --fatal-warnings
flutter test --test-randomize-ordering-seed random --reporter expanded
flutter build ios --no-codesign

# Every skill gate that is a gate, via the enumerated runner (bash 4+ required)
bash tool/skill_gates.sh

# The gates the runner wraps, spot-checked individually during the epic
.claude/skills/dependency-hygiene/scripts/audit-deps.sh
.claude/skills/lint-and-style-config/scripts/verify-include-pin.sh
.claude/skills/project-structure-and-packages/scripts/check_structure.sh          lib
.claude/skills/project-structure-and-packages/scripts/check_import_boundaries.sh  lib
.claude/skills/design-system-structure/scripts/check_font_bundling.sh             lib
.claude/skills/state-management-riverpod/scripts/ban-legacy-providers.sh          lib
.claude/skills/codegen-and-toolchain/scripts/check-codegen-hygiene.sh
.claude/skills/i18n-rtl-l10n/scripts/check_i18n_bans.sh                           lib
.claude/skills/sunburst-tokens/scripts/check_raw_values.sh                        lib
.claude/skills/sunburst-components/scripts/check_component_hygiene.sh             lib
.claude/skills/sunburst-shell-screens/scripts/check_shell_boundaries.sh           lib
.claude/skills/sunburst-game-surfaces/scripts/check_game_palette.sh               lib
.claude/skills/sunburst-motion-and-haptics/scripts/check_motion_tokens.sh         lib

# Run once by hand and paste the output into the PR body — it is expected to FAIL with exit 2,
# and that measured failure is the skip-table reason E04 clears.
.claude/skills/i18n-rtl-l10n/scripts/check_arb_parity.sh                          lib/l10n
```

Run `tool/skill_gates.sh` under bash 4 or newer — it refuses to run otherwise. macOS system bash is 3.2
and one skill script uses `mapfile`. `brew install bash` locally; the CI job installs one explicitly,
because the macOS runner does not solve this the way the old Ubuntu runner did.

**Do not** replace the runner with `for s in .claude/skills/*/scripts/*.sh; do bash "$s"; done`. That
loop cannot exit 0: measured, it fails on 29 of 49 scripts, five of which take a required argument
and can never pass argument-less. The runner exists precisely so the skip list is explicit and reviewed.

## Risks and open questions

| # | Risk / question | Decision, or who to ask |
|---|---|---|
| 1 | **`ckb` is very likely absent from `GlobalMaterialLocalizations`/`GlobalCupertinoLocalizations`.** A missing delegate throws at runtime on locale switch — the sharpest technical risk in the whole plan. | **Verified, not assumed, in T01.9**: `isSupported` is measured for all four locales on Flutter 3.44.6 and the result is asserted in `material_delegate_support_test.dart` and pasted into ADR 0001. **E04 owns the fix** — a custom `LocalizationsDelegate` serving our own ARB strings for `ckb` while delegating Material/Cupertino strings to the nearest script neighbour (`fa`, else `ar`), with a test that switching to `ckb` does not throw. E01 does not ship `ckb` strings, so nothing can crash here; it ships the measurement E04 plans against. |
| 2 | **`intl` may have no number symbols for `ckb`,** in which case it falls back to Latin digits silently — a Latin-digit Sorani UI reads as untranslated. | Measured in T01.9 (`numberFormatSymbols` membership, with the resolved `intl` version recorded). The fix, per `i18n-rtl-l10n/references/numerals-and-calendars.md`, is pinning `ckb` to the `fa` formatter (same U+06Fx block and separators) and asserting the emitted digit block in a test. **E04 implements and tests it**; E01 records the fact. |
| 3 | **Sorani glyph coverage of a display face is unverified.** Fredoka and Nunito have no Arabic script at all; Lalezar is the closest OFL echo of Fredoka's chunk but its coverage of ڕ ڵ ۆ ێ ھ is **not assumed**. | E01 bundles the Latin pair only and says so in the PR body. **E04 verifies Lalezar's coverage of the Sorani letters and falls back to Vazirmatn Bold for display if it fails**, recording the outcome in that epic rather than guessing now. Vazirmatn is the body face for both RTL locales. `font_declaration_test.dart` is written so E04 extends its expected set. |
| 4 | **The Fredoka personality does not survive translation.** In `fa` and `ckb` the brand's typographic voice is simply not available. | Stated, not papered over. In the RTL locales the identity is carried by the **shape language** — the 3px ink border, the hard offset shadow, the press-down, the palette — not by the typeface. E04 says this in its own text too; no epic may present an Arabic-script font swap as neutral. |
| 5 | **Translation quality for `fa` and especially `ckb` is an open question needing a native speaker.** | **Open. Raise with Zakaria before E11.** Machine-quality Persian is a risk; machine-quality Sorani is a bigger one. ADR 0001 records the reversal trigger: if no native reviewer is found, shipping three locales is better than shipping a fourth badly. Nothing in E01 or E04 may present translations as done without that review. |
| 6 | **CI now runs on macOS, which reintroduces bash 3.2.** The old plan leaned on the Ubuntu runner shipping bash 5 for `check-scheduler-purity.sh`'s `mapfile`. | `tool/skill_gates.sh` exits 2 under bash < 4 (T01.11) instead of warning, and the workflow provides a bash 5 explicitly (T01.12, marked `# VERIFY:` because the image may already ship one). Do **not** edit the skill script — the skill library is not this epic's to change; if it should be fixed, ask Zakaria first. |
| 7 | **The runner's Xcode is not ours to pin.** Local is Xcode 26.6 / CocoaPods 1.15.2; the GitHub image ships whatever it ships, and a wrong `runs-on` label or an image bump changes it with no diff. | `check_toolchain.sh` fails hard on Flutter (the version that perturbs determinism and goldens) and warns on Xcode/CocoaPods under `TOOLCHAIN_HOST_TOOLS=warn`, which only CI sets. The workflow logs `xcodebuild -version` every run, the runner label carries a `# VERIFY:`, and T01.12's done-list requires the runner's versions to be pasted into the PR body beside the local ones. |
| 8 | **The bundle identifier `com.mindforge.mindforge` is permanent once published.** `--org com.mindforge` plus `--project-name mindforge` produces a doubled name that reads oddly. | Proposed default, written into the PR body in T01.2 as the resolved string rather than the flag. Alternative: `--org com.zakariaf` yields `com.zakariaf.mindforge`. **Ask Zakaria to confirm before E11** — changing it after the first store upload creates a different app. |
| 9 | **`CFBundleLocalizations` claims four languages three epics before three of them exist.** Between E01 and E04, iOS offers Persian and resolves it to English. | Accepted deliberately (T01.4). Nothing ships between E01 and E04, so no user sees it, and declaring it here is the only way the plist edit gets a policy test instead of being remembered mid-translation. The single supported-locale constant is asserted by both `ios_target_test.dart` and `l10n_posture_test.dart`, so the plist, the ADR and the ARB directory cannot drift. |
| 10 | **`check_arb_parity.sh` cannot pass at one locale** — measured exit 2, `FAIL: no locale ARB files (app_*.arb) beside the template`. | It sits in `tool/skill_gates.sh`'s skip table with that measured reason and a named mover: **E04**, in the same PR that lands `app_de.arb`, `app_fa.arb` and `app_ckb.arb`. `skill_gates_coverage_test.dart` (exactly-once) is what forces the move to be deliberate. Its sibling `check_i18n_bans.sh lib` runs from E01 onward. |
| 11 | **The reference PNGs are 2×; the canonical simulator is 3×.** 780×1688 versus 1170×2532. | Logical geometry matches exactly (390×844) and no available simulator is 390×844 at 2×, so this is a property of the target hardware. The comparison stays the one `screens/README.md` prescribes — structure → spacing rhythm → surface construction → type role → sampled hex — never a pixel diff. Written into that README in T01.10. |
| 12 | **iOS may display `ckb` by its code rather than a localized language name** in the system language list. | **Unverified.** Noted in T01.4, verified on device in E11's `design-review-workflow` sweep. If it reads badly, the in-app Language row (E04's controller, E08's Settings screen) is the surface that fixes it, not the plist. |
| 13 | **Android is deferred, and "deferred" must not decay into "broken".** | A decision, recorded in T01.2, in `README.md` and in `repo_layout_test.dart`'s reason strings. Nothing in `lib/` may assume iOS: the one platform-touching seam is E06's injected `HapticGateway`. Re-adding Android is `flutter create --platforms=android .` plus one PR for the build job. |
| 14 | **macOS CI minutes cost a multiple of Linux minutes,** and `pod install` plus an iOS compile are slow. | Accepted. iOS is the only shipping target; a Linux job would go green over a platform nobody ships. The two jobs carry `timeout-minutes` (30 and 40) and `concurrency: cancel-in-progress` so a superseded push stops burning minutes. |
| 15 | **The fonts require one network download.** Fredoka and Nunito TTFs are not in the repo and `google_fonts` is banned. | Download once from `github.com/googlefonts/fredoka` and `github.com/googlefonts/nunito` (both SIL OFL 1.1) and commit the files. If there is no network when T01.7 runs, that is a blocker to raise — never substitute a system font, never add `google_fonts` "temporarily". E04 has the same constraint for Vazirmatn and Lalezar. |
| 16 | **The dependency set is partly ahead of its use.** `dependency-hygiene` calls a speculative dependency a review reject, yet drift, `go_router` and `path_provider` are not used until E02/E08. | Accepted deliberately and recorded in the PR body: the set is fixed by the architecture in `CLAUDE.md`, every package lands within two epics, and one resolution now means one reviewed lock delta instead of five. `riverpod_generator` and `golden_toolkit` are **not** taken. Any calendar package is deferred to E04, which decides whether MindForge projects dates at all. |
| 17 | **The `very_good_analysis` include filename must match the resolved version.** A wrong filename yields one warning and a ruleset of zero rules — a green build that checks nothing. | Read the resolved version from `~/.pub-cache/hosted/pub.dev/very_good_analysis-*/lib/`, never guess it, and prove it with `verify-include-pin.sh` plus the scratch-file red-proof in T01.5. |
| 18 | **`riverpod_lint` may emit nothing on this analyzer.** A configured plugin that produces no diagnostics is a false safety signal. | T01.5 verifies it with a real `missing_provider_scope` violation. If it does not fire, remove it and say so in the PR body. |
| 19 | **`synthetic-package` is deprecated on Flutter 3.44.6** — `flutter gen-l10n --help` says the flag "cannot be enabled and should be removed". The previous plan asserted `synthetic-package: false`. | Corrected in T01.9: the option appears **nowhere** in `l10n.yaml`, and `l10n_posture_test.dart` asserts its absence. `output-dir: lib/l10n` is what keeps the generated class as real, greppable source. |
| 20 | **`use-escaping` must be decided before three locales of copy exist,** because turning it on later changes how existing messages parse. | Left unset in E01 and named as **E04's** decision in ADR 0001. None of the six seeded keys contains `{`, `}` or an apostrophe, so E01 is unaffected either way. |
| 21 | **Generated code: commit or gitignore.** | Decision: **commit** — both `build_runner` output and `lib/l10n/app_localizations*.dart` — with the freshness gate (generate, then `git diff --exit-code`) wired in T01.12. `format: true` in `l10n.yaml` is what stops committed generated output from failing the format gate. A `.gitattributes` diff-collapse for generated suffixes lands with the first `build_runner` generator in E02. |
| 22 | **`public_member_api_docs` at `error` costs a `///` on every public declaration.** | Kept at `error`. The engine seam (`GameDefinition`, `BoardSnapshot`, `RunNotifier`) is an API a second game author reads. The decision is recorded as a comment at that line in `analysis_options.yaml`; revisit only with a stated reason. |
| 23 | **CI cannot prove what this project cares most about.** Screenshot parity, font rendering, Arabic-script shaping, motion, press physics, haptics — and, now, that the app launches at all, since no runner has the canonical simulator. | Stated in a comment block at the top of `ci.yml`. The launch proof is T01.10's local artifact; the screenshot comparison is a per-task step from E03 onward; the RTL sweep is E04 and E11; the on-device pass is E11's `design-review-workflow` artifact. |
| 24 | **`CLAUDE.md` is the document every epic defers to, and nothing gates it.** It was brought current with the four-locale and iOS-only requirements alongside the eleven-epic plan — layout block, working agreements 10/11/12, the three new constraint rows, eleven epics — but a document nobody parses drifts from the tree within one epic. | **T01.6 reads it, confirms all of the above, and ships the gate**: `project_structure_test.dart` parses the layout block and asserts the tree matches it in both directions. It edits `CLAUDE.md` only if it finds a genuine gap, and says so in the PR body. **E02, E03, E04 and E06 must not propose amendments to it** — their risk entries point here. `lib/shared/feedback/` keeps its name; it has a stated responsibility and `check_structure.sh` does not flag it. |

## Definition of done

The delivery loop, restated: branch off `main` → TDD with granular commits → `/simplify` then
`/code-review` → all gates green → push → PR with the five required sections → wait for CI → merge
preserving the granular commits → next epic.

- [ ] Branch `epic/01-foundation-ci-and-ios` cut from `main`.
- [ ] All twelve tasks complete, each with its commits, each test seen red before it was seen green.
- [ ] `bash tool/ios_simulator.sh run` launches MindForge on `MindForge iPhone 14` to a blank white
      screen with no console error; `docs/verification/e01-simulator-launch.png` is committed at
      1170×2532.
- [ ] `flutter build ios --no-codesign` succeeds locally and in CI.
- [ ] `dart format --output=none --set-exit-if-changed .` exits 0.
- [ ] `flutter analyze --fatal-infos --fatal-warnings` reports no issues.
- [ ] `flutter test --test-randomize-ordering-seed random` is green.
- [ ] `bash tool/skill_gates.sh` exits 0 under bash 4+; every skip carries a structural reason;
      `check_arb_parity.sh`'s skip row names E04 as the epic that moves it.
- [ ] `pubspec.lock` and `ios/Podfile.lock` are committed and not gitignored; `audit-deps.sh` exits 0.
- [ ] `ios/Runner/Info.plist` declares `CFBundleDevelopmentRegion` = `en` and `CFBundleLocalizations` =
      `en, de, fa, ckb`, and `ios_target_test.dart` passes.
- [ ] Fredoka and Nunito are bundled, declared at the four named weights, and both OFL texts are
      reachable through `LicenseRegistry` (proven by `test/theme/font_licence_test.dart`); no
      `google_fonts` in the tree. **E03 T03.7 is the only other epic that may touch `flutter: fonts:`**,
      to add Arabic-script coverage; it extends `font_declaration_test.dart`'s expected set and calls
      the same `registerSunburstFontLicences()`. E04 bundles no font.
- [ ] `flutter gen-l10n` is green, `lib/l10n/app_en.arb` carries the six seeded keys with descriptions,
      the generated localizations are committed and diff-clean, `test/policy/l10n_posture_test.dart` and
      `test/l10n/app_localizations_test.dart` pass, and `check_i18n_bans.sh lib` runs in CI.
- [ ] ADR 0001 records the four-locale posture, the `en` fallback, the persisted-override plan, the two
      measured `ckb` gaps with their package versions, the `use-escaping` deferral and the reversal
      trigger; the native-translation-review question is written down as **open**.
- [ ] `CLAUDE.md` was verified current in T01.6 — layout block (`core/`, `l10n/`, `shared/motion/`),
      working agreements 10, 11 and 12, the `Four locales, two RTL` / `Bundled fonts` / `iOS only`
      constraint rows, and "eleven epics" in Build order — and
      `test/policy/project_structure_test.dart` reads the layout block so document and tree cannot
      drift. Any edit this PR made to it is listed with what was missing.
- [ ] `design/sunburst-pop/screens/README.md` names the canonical simulator and the 2×/3× caveat and no
      longer mentions macOS.
- [ ] `lib/` matches the amended `CLAUDE.md` target layout; `test/` mirrors it.
- [ ] `/simplify` run and its findings addressed.
- [ ] `/code-review` run and its findings addressed.
- [ ] PR opened with a body written from `.github/PULL_REQUEST_TEMPLATE.md`, stating what changed, why,
      how it was verified, that no screens were compared (none exist yet, and why — the launch proof is
      not a comparison), and what was left out.
- [ ] CI green on the PR — both `verify` and `build-ios` jobs.
- [ ] PR merged preserving the granular commits, branch deleted, back on `main`, pulled.
- [ ] E02 can start: the package resolves, `flutter test` is green, `tool/skill_gates.sh` exits 0, and
      `lib/data/` exists and is empty.
- [ ] E03 can start: `lib/theme/` exists and is empty apart from `font_licences.dart`, and the four
      Latin faces are on disk under `assets/fonts/`.
- [ ] E04 can start: `l10n.yaml` is wired, `lib/l10n/app_en.arb` has real keys to translate,
      `AppLocalizations` resolves, `CFBundleLocalizations` already lists all four locales, and the two
      `ckb` measurements are recorded in ADR 0001.
